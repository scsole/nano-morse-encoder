///////////////////////////////////////////////////////////////////////////////
// vim:set shiftwidth=4 softtabstop=4 expandtab:
// Sebastian Sole, 2020
//
// Module: morse_key.v
// Project: Nano Morse Encoder
// Description: Generate a 440 Hz tone when key is HI
//
//
// Change history:
//     v01 - AM Morse transmitter with a rather crude 440 Hz square wave
//
///////////////////////////////////////////////////////////////////////////////

module morse_key #(
    TONE_FREQ = 440 // Frequency of the generated tone, default 440 (Hz)
    )(
    input clk_24,           // 24 MHz system clk
    input key,              // Signal to be transmitted, active HI
    output reg signal = 0   // Single bit output tone
    );

    localparam COUNTER_MAX = 12_000_000 / TONE_FREQ;

    // 24-bit counter, gives roughtly 0.7s
    reg [23:0] counter = 0;

    always @(posedge clk_24) begin
        if (counter == COUNTER_MAX) begin
            // Modulate the carrier signal using key
            signal <= ~signal * key;
            counter <= 0;
        end
        else
            counter <= counter + 1;
    end
endmodule
