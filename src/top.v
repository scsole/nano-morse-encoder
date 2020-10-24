///////////////////////////////////////////////////////////////////////////////
// vim:set shiftwidth=4 softtabstop=4 expandtab:
//
// Module: top.v
// Project: Nano Morse Encoder
// Description: Generate Morse code on the Sipeed Tang Nano
//
// Author: Sebastian Sole, 2020
//
// Change history:
//      v01 - Initial attempt to receive data using wbuart32 modules
//      v02 - Switch to own buffer module
//      v03 - Transmit ASCII over serial when decoded for debugging
//
///////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2020  Sebastian Sole
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program; if not, write to the Free Software Foundation, Inc.,
// 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
///////////////////////////////////////////////////////////////////////////////

`define ASCII_SPACE 8'd32
`define SYMBOL_SPACE 2'd1
`define LETTER_SPACE 2'd3
`define DOT_DELAY 2'd1
`define DASH_DELAY 2'd3

module top (
    input clk_24,               // 24 MHz system clk
    input rst_n,                // System reset
    input uart_rx,              // UART receive port
    output uart_tx,             // UART transmit port, only used to transmit the
                                // rx_ready value back to the connected device 
                                // for debugging purposes
    output [2:0] led,           // RGB LED used to show signal state
    output signal,              // Modulated output signal, produces 440 Hz tone
    output [10:0] mem_rw_addr   // The next memory address to write to. We must
                                // stop reading if we reach this address as the
                                // buffer will be empty.
);

    wire rx_ready;      // Data received successfully
    wire [7:0] rx_data; // Actual data received

    reg tx_ready;       // Data is ready to be transmitted
    reg [7:0] tx_data;  // Actual data to be transmitted

    reg [10:0] mem_rd_addr = 0; // The memory address to read from
    wire [6:0] mem_rd_data;     // The 7-bit ASCII value read from memory

    wire [6:0] morse_code;     // Decoded Morse code signals for the current ASCII
                               // code in mem_rd_data
    wire [2:0] morse_len;      // The total number of signals in morse_code
    reg [2:0] morse_index = 0; // The current Morse code signal to generate

    reg signal_state = 0;    // The Morse code output state used to modulate signals
    reg[1:0] delay_time = 0; // The number of units to wait before changing state

    reg [23:0] counter = 0; // 24-bit counter, gives roughly 700 ms @ 24 MHz

    localparam PERIOD = 50;                   // Duration of a dot in ms
    localparam CLK_DIVIDER = 24_000 * PERIOD; // 20 Hz clk for 50 ms period

    
    always @(posedge clk_24) begin
        if (counter == CLK_DIVIDER) begin
            counter <= 0;

            // Wait for a dot or dash to complete, or until the buffer has new data
            if (delay_time == 0 && mem_rw_addr != mem_rd_addr) begin

                if (morse_index == morse_len) begin
                    // The last signal was processed - move to the next character
                    signal_state <= 0;
                    delay_time <= `LETTER_SPACE;
                    morse_index <= 0;
                    mem_rd_addr <= mem_rd_addr + 1; // 'Consume' the processed character

                end else begin
                    // Still more signals - continue with the current character
                    if (signal_state) begin // Finished signal/pulse - move to the next one
                        signal_state <= 0;
                        delay_time <= `SYMBOL_SPACE;

                    end else begin // Begin a new signal/pulse
                        delay_time <= morse_code[morse_index] ? `DASH_DELAY : `DOT_DELAY;
                        morse_index <= morse_index + 1;
                        signal_state <= (mem_rd_data == `ASCII_SPACE) ? 0 : 1;

                        // Transmit the processing character over serial once
                        if (morse_index == 0) begin
                            tx_data <= mem_rd_data;
                            tx_ready <= 1;
                        end
                    end
                end
            end else begin
                delay_time <= delay_time - 1;
            end

        end else begin
            counter <= counter + 1;
            tx_ready <= 0; // Reset tx_ready (as the character would have started or finished transmitting)
        end

        if (~rst_n) begin
            counter <= 0;
            delay_time <= 0;
            signal_state <= 0;
            morse_index <= 0;
            mem_rd_addr <= 0;
            tx_data <= 0;
            tx_ready <= 8'b0;
        end
    end


    // Setup register for UART modules
    // 8-bit word, one stop bit, no parity and 9600 baud over a 24 MHz clock
    reg [30:0] setup = {7'b1000000, 24'd2500};

    // Connect UART modules without worrying about error handling, simple but not robust
    rxuart rx0(
        .i_clk(clk_24),
        .i_reset(~rst_n),
        .i_setup(setup),
        .i_uart_rx(uart_rx),
        .o_wr(rx_ready),
        .o_data(rx_data)
    );

    txuart tx0(
        .i_clk(clk_24),
        .i_reset(~rst_n),
        .i_setup(setup),
        .i_break(1'b0),
        .i_wr(tx_ready),
        .i_data(tx_data),
        .i_cts_n(1'b0),
        .o_uart_tx(uart_tx)
    );

    // Buffer for RX UART module. We can receive characters much faster than we
    // transmit them as Morse code. Hence we need a FIFO data buffer. Since we
    // transmit far slower than the UART module can handle, we can use it
    // without one.
    buffer rx_buff0(
        .i_clk_24(clk_24),
        .i_rst(~rst_n),
        .i_rw(rx_ready),
        .i_rd_addr(mem_rd_addr),
        .i_data(rx_data),
        .o_wr_addr(mem_rw_addr),
        .o_rd_data(mem_rd_data)
    );

    // Use a (white) LED to show the signal output
    // LEDs are active low so require an inverted signal
    assign led = {~signal_state, ~signal_state, ~signal_state};


    // Decode an ASCII code into Morse code signals
    ascii_2_morse m0(
        .clk_24(clk_24),
        .rst(~rst_n),
        .ascii_code(mem_rd_data),
        .morse_code(morse_code),
        .morse_len(morse_len)
    );

    // Drive the 440 Hz tone output
    morse_key s0(
        .clk_24(clk_24),
        .rst(rst_n),
        .key(signal_state),
        .signal(signal)
    );

endmodule
