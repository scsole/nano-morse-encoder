///////////////////////////////////////////////////////////////////////////////
// vim:set shiftwidth=4 softtabstop=4 expandtab:
// Sebastian Sole, 2020
//
// Module: top.v
// Project: Nano Morse Encoder
// Description: Generate Morse code on the Sipeed Tang Nano
//
//
// Change history:
//      v01 -  Initial attempt to receive data using wbuart32 modules
//
///////////////////////////////////////////////////////////////////////////////
`define ASCII_SPACE 8'd32
`define SYMBOL_SPACE 2'd1
`define LETTER_SPACE 2'd3
`define DOT_DELAY 2'd1
`define DASH_DELAY 2'd3

module top (
    input clk_24,           // 24 MHz system clk
    input rst,              // System reset
    input uart_rx,          // UART recieve port
    output uart_tx,         // UART transmit port, only used to transmit the
                            // recieved value back to the connected device for 
                            // debugging purposes
    output [2:0] rgb_led,   // RGB led used to show signal state,
    output signal           // Modulated output signal, produces 440 Hz tone
);

    wire rx_ready;      // Data (rx_data) is available
    wire [7:0] rx_data; // Recieved data

    wire rxbuff_not_empty;  // HI if there is at least one item to be read, else LO
    wire [7:0] rxbuff_data; // The next item to be read from the buffer
    reg rxbuff_read = 0;    // Pulse HI to read an item from the buffer, and update rxbuff_data

    reg tx_ready;      // Data (tx_data) is ready to transmit
    reg [7:0] tx_data; // Data to transmit
    wire tx_busy;      // Data (tx_data) is being sent, must be LO before strobing tx_ready

    wire [6:0] morse_code;      // Morse code signals for the current ascii_code
    wire [2:0] morse_len;       // The total number of signals in morse_code
    reg  [2:0] morse_index = 0; // The current signal to generate in morse_code

    reg signal_state = 0;     // The Morse code output state used to modulate signals
    reg [1:0] delay_time = 0; // The number of units to wait before changing state

    reg [23:0] counter = 0; // 24-bit counter, gives roughtly 700 ms @ 24 MHz

    localparam PERIOD = 50;                   // Duration of a dot in ms
    localparam CLK_DIVIDER = 24_000 * PERIOD; // 20 Hz clk for 50 ms period

    always @(posedge clk_24) begin
        if (rxbuff_read)
            rxbuff_read <= 0;

        if (counter == CLK_DIVIDER) begin
            counter <= 0;

            // Wait for a dot or dash to complete, or untill a new character is recieved
            if (delay_time == 0 && rxbuff_not_empty) begin

                if (morse_index == morse_len) begin
                    // Move to the next caracter if the last signal was processed
                    signal_state <= 0;
                    delay_time <= `LETTER_SPACE;
                    morse_index <= 0;
                    rxbuff_read <= 1; // Remove the first item from the FIFO buffer,
                                      // we've finished transmitting it

                end else begin
                    // Continue processing existing character
                    if (signal_state) begin
                        // Finished signal/pulse, move to the next
                        signal_state <= 0;
                        delay_time <= `SYMBOL_SPACE;
                    end else begin
                        // Begin a signal/pulse
                        delay_time <= morse_code[morse_index] ? `DASH_DELAY : `DOT_DELAY;
                        morse_index <= morse_index + 1;
                        signal_state <= (rxbuff_data != `ASCII_SPACE) ? 1 : 0; // Space is held LO
                    end
                end
            end else begin
                delay_time <= delay_time - 1;
            end
        end else
            counter <= counter + 1;

        if (~rst) begin
            counter <= 0;
            delay_time <= 0;
            signal_state <= 0;
            morse_index <= 0;
            tx_ready <= 0;
            tx_data <= 0;
            rxbuff_read <= 0;
        end
    end

    // Defines 8-bit word, one stop bit, no parity and 9600 baud over a 24 MHz clock
    reg [30:0] setup = {7'b100000,24'd2500}; // Setup register for UART modules

    rxuart rx0(
        .i_clk(clk_24),
        .i_reset(~rst),
        .i_setup(setup),
        .i_uart_rx(uart_rx),
        .o_wr(rx_ready),
        .o_data(rx_data),
        .o_break(),
		.o_parity_err(),
        .o_frame_err(),
        .o_ck_uart()
    );

    txuart tx0(
        .i_clk(clk_24),
        .i_reset(~rst),
        .i_setup(setup),
        .i_break(1'b0),
        .i_wr(tx_ready),
        .i_data(tx_data),
		.i_cts_n(1'b0),
        .o_uart_tx(uart_tx),
        .o_busy(tx_busy)
    );

    // Synchronous data FIFO for rx0
    ufifo rx0_fifo(
        .i_clk(clk_24),
        .i_reset(~rst),
        .i_wr(rx_ready),
        .i_data(rx_data),
        .o_empty_n(rxbuff_not_empty),
        .i_rd(rxbuff_read),
        .o_data(rxbuff_data),
        .o_status(),
        .o_err()
    );

    // Use a (white) LED to show the signal output
    // LEDs are active low so require an inverted signal
    assign rgb_led = {~signal_state, ~signal_state, ~signal_state};

    // Decode an ASCII code into Morse code signals
    ascii_2_morse m0(
        .clk_24(clk_24),
        .rst(~sys_rst),
        .ascii_code(rxbuff_data[6:0]),
        .morse_code(morse_code),
        .morse_len(morse_len)
    );

    // Drive the 440 Hz tone output
    morse_key s0(
        .clk_24(clk_24),
        .rst(rst),
        .key(signal_state),
        .signal(signal)
    );
endmodule
