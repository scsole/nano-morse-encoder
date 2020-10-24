///////////////////////////////////////////////////////////////////////////////
// vim:set shiftwidth=4 softtabstop=4 expandtab:
//
// Module: buffer.v
// Project: Nano Morse Encoder
// Description: Memory buffer for UART communication. Used as a FIFO data buffer
//              Every i_rw HI signal saves data and outputs the location of the
//              next address to be used. Data can be read from anywhere so
//              i_rd_addr must be kept track of for proper FIFO function.
//
// Author: Sebastian Sole, 2020
//
// Change history:
//      v01 - Initial buffer implementation
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

module buffer (
    input i_clk_24,                 // 24 MHz system clk
    input i_rst,                    // Synchronous reset, active HI
    input i_rw,                     // Pulse HI to write i_data at o_rw_addr
    input [10:0] i_rd_addr,         // Read address
    input [7:0] i_data,              // Data to store when at o_rw_addr
    output reg [10:0] o_wr_addr,    // The next address that will be written to
    output [6:0] o_rd_data         // Data located at i_rd_addr
);

    wire [31:0] d_out;      // Data retrieved from memory
    reg [31:0] d_in = 0;    // Data to store in memory
    reg [31:0] d_buf = 0;   // Last retrieved data from memory
    reg [10:0] d_addr = 0;  // Memory address of data to rd/rw
    reg d_wre = 0;          // 1 to write to memory, else 0 to read from memory

    assign o_rd_data = d_buf[6:0]; // Always allow data to be read

    always @(posedge i_clk_24)
    begin
        if (i_rw) begin
            // Write data to memory
            d_addr <= o_wr_addr;
            o_wr_addr <= o_wr_addr + 1;
            d_in <= {24'b0, i_data};
            d_wre <= 1;
        end else begin
            // Keep the read buffer up to date
            d_addr <= i_rd_addr;
            d_buf <= d_out;
            d_wre <= 0;
        end

        if (i_rst) begin
            o_wr_addr <= 11'b0;
            d_in <= 31'b0;
            d_buf <= 31'b0;
            d_addr <= 11'b0;
        end
    end

    // Memory configuration
    wire gw_gnd;
    assign gw_gnd = 1'b0;

    SP sp_inst_0 (
        .DO(d_out),
        .CLK(i_clk_24),
        .OCE(0),
        .CE(1),
        .RESET(i_rst),
        .WRE(d_wre),
        .BLKSEL({gw_gnd,gw_gnd,gw_gnd}),
        .AD({d_addr,gw_gnd,gw_gnd,gw_gnd}),
        .DI(d_in)
    );

    defparam sp_inst_0.READ_MODE = 1'b0;
    defparam sp_inst_0.WRITE_MODE = 2'b00;
    defparam sp_inst_0.BIT_WIDTH = 8;
    defparam sp_inst_0.BLK_SEL = 3'b000;
    defparam sp_inst_0.RESET_MODE = "SYNC";

endmodule
