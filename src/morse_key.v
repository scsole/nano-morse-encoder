///////////////////////////////////////////////////////////////////////////////
// vim:set shiftwidth=4 softtabstop=4 expandtab:
//
// Module: morse_key.v
// Project: Nano Morse Encoder
// Description: Generate a 440 Hz tone when key is HI
//
// Author: Sebastian Sole, 2020
//
// Change history:
//      v01 - AM Morse transmitter with a rather crude 440 Hz square wave
//      v02 - Added synchronous reset
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

module morse_key #(
    TONE_FREQ = 440 // Frequency of the generated tone, default 440 (Hz)
    )(
    input clk_24,           // 24 MHz system clk
    input rst,              // Synchronous reset, active HI
    input key,              // Signal to be transmitted, active HI
    output reg signal = 0   // Single bit output tone
    );

    localparam COUNTER_MAX = 12_000_000 / TONE_FREQ;

    // 24-bit counter, gives roughly 0.7s
    reg [23:0] counter = 0;

    always @(posedge clk_24) begin
        if (counter == COUNTER_MAX) begin
            // Modulate the carrier signal using key
            signal <= ~signal * key;
            counter <= 0;
        end
        else
            counter <= counter + 1;

        if (rst) begin
            counter <= 0;
            signal <= 0;
        end
    end
endmodule