///////////////////////////////////////////////////////////////////////////////
// vim:set shiftwidth=4 softtabstop=4 expandtab:
// Sebastian Sole, 2020
//
// Module: ascii_2_morse.v
// Project: Nano Morse Encoder
// Description: Convert (7-bit) ASCII codes into Morse code
//
//
// Change history:
//     v01 - Implemented using lookup tables
//
///////////////////////////////////////////////////////////////////////////////

module ascii_2_morse (
    input clk_24,               // 24 MHz system clk
    input rst,                  // Reset (sets output to 0)
    input [6:0] ascii_code,     // A 7-bit ASCII code to convert
    output reg [6:0] morse_code,// Corresponding Morse code signals in little-
                                // endian order. 0 = dot, 1 = dash
    output reg [2:0] morse_len  // The number of signals used in morse_code
    );

    // Useful ASCII codes
    localparam UPPER_A = 65;
    localparam UPPER_Z = 90;
    localparam LOWER_A = 97;
    localparam LOWER_Z = 122;
    localparam ZERO = 48;
    localparam NINE = 58;

    // Lookup tables
    // [9:3] = morse_code
    // [2:0] = morse_len
    reg [9:0] letters [0:25];
    reg [9:0] numbers [0:9];
    reg [9:0] punctuation [0:18];

    initial begin
        letters[0]  = {7'b000_0010, 3'd2}; // A
        letters[1]  = {7'b000_0001, 3'd4}; // B
        letters[2]  = {7'b000_0101, 3'd4}; // C
        letters[3]  = {7'b000_0001, 3'd3}; // D
        letters[4]  = {7'b000_0000, 3'd1}; // E
        letters[5]  = {7'b000_0100, 3'd4}; // F
        letters[6]  = {7'b000_0011, 3'd3}; // G
        letters[7]  = {7'b000_0000, 3'd4}; // H
        letters[8]  = {7'b000_0000, 3'd2}; // I
        letters[9]  = {7'b000_1110, 3'd4}; // J
        letters[10] = {7'b000_0101, 3'd3}; // K
        letters[11] = {7'b000_0010, 3'd4}; // L
        letters[12] = {7'b000_0011, 3'd2}; // M
        letters[13] = {7'b000_0001, 3'd2}; // N
        letters[14] = {7'b000_0111, 3'd3}; // O
        letters[15] = {7'b000_0110, 3'd4}; // P
        letters[16] = {7'b000_1011, 3'd4}; // Q
        letters[17] = {7'b000_0010, 3'd3}; // R
        letters[18] = {7'b000_0000, 3'd3}; // S
        letters[19] = {7'b000_0001, 3'd1}; // T
        letters[20] = {7'b000_0100, 3'd3}; // U
        letters[21] = {7'b000_1000, 3'd4}; // V
        letters[22] = {7'b000_0110, 3'd3}; // W
        letters[23] = {7'b000_1001, 3'd4}; // X
        letters[24] = {7'b000_1101, 3'd4}; // Y
        letters[25] = {7'b000_0011, 3'd4}; // Z

        numbers[0] = {7'b001_1111, 3'd5}; // 0
        numbers[1] = {7'b001_1110, 3'd5}; // 1
        numbers[2] = {7'b001_1100, 3'd5}; // 2
        numbers[3] = {7'b001_1000, 3'd5}; // 3
        numbers[4] = {7'b001_0000, 3'd5}; // 4
        numbers[5] = {7'b000_0000, 3'd5}; // 5
        numbers[6] = {7'b000_0001, 3'd5}; // 6
        numbers[7] = {7'b000_0011, 3'd5}; // 7
        numbers[8] = {7'b000_0111, 3'd5}; // 8
        numbers[9] = {7'b000_1111, 3'd5}; // 9

        punctuation[0]  = {7'b000_0000, 3'd7}; // space 32
        punctuation[1]  = {7'b011_0101, 3'd6}; // ! 33
        punctuation[2]  = {7'b001_0010, 3'd6}; // " 34
        punctuation[3]  = {7'b100_1000, 3'd7}; // $ 36
        punctuation[4]  = {7'b000_0010, 3'd5}; // & 38
        punctuation[5]  = {7'b001_1110, 3'd6}; // ' 39
        punctuation[6]  = {7'b000_1101, 3'd5}; // ( 40
        punctuation[7]  = {7'b010_1101, 3'd6}; // ) 41
        punctuation[8]  = {7'b000_1010, 3'd5}; // + 43
        punctuation[9]  = {7'b011_0011, 3'd6}; // , 44
        punctuation[10] = {7'b010_0001, 3'd6}; // - 45
        punctuation[11] = {7'b010_1010, 3'd6}; // . 46
        punctuation[12] = {7'b000_1001, 3'd5}; // / 47
        punctuation[13] = {7'b000_0111, 3'd6}; // : 58
        punctuation[14] = {7'b001_0101, 3'd6}; // ; 59
        punctuation[15] = {7'b001_0001, 3'd5}; // = 61
        punctuation[16] = {7'b000_1100, 3'd6}; // ? 63
        punctuation[17] = {7'b001_0110, 3'd6}; // @ 64
        punctuation[18] = {7'b010_1100, 3'd6}; // _ 95
    end

    always @(posedge clk_24 or posedge rst) begin
        if (rst)
            {morse_code, morse_len} <= 10'b0;
        else if (ascii_code >= UPPER_A && ascii_code <= UPPER_Z)
            {morse_code, morse_len} <= letters[ascii_code - UPPER_A];
        else if (ascii_code >= LOWER_A && ascii_code <= LOWER_Z)
            {morse_code, morse_len} <= letters[ascii_code - LOWER_A];
        else if (ascii_code >= ZERO && ascii_code <= NINE)
            {morse_code, morse_len} <= letters[ascii_code - ZERO];
        else begin
            case (ascii_code)
                7'd33   : {morse_code, morse_len} <= punctuation[1];
                7'd34   : {morse_code, morse_len} <= punctuation[2];
                7'd36   : {morse_code, morse_len} <= punctuation[3];
                7'd38   : {morse_code, morse_len} <= punctuation[4];
                7'd39   : {morse_code, morse_len} <= punctuation[5];
                7'd40   : {morse_code, morse_len} <= punctuation[6];
                7'd41   : {morse_code, morse_len} <= punctuation[7];
                7'd43   : {morse_code, morse_len} <= punctuation[8];
                7'd44   : {morse_code, morse_len} <= punctuation[9];
                7'd45   : {morse_code, morse_len} <= punctuation[10];
                7'd46   : {morse_code, morse_len} <= punctuation[11];
                7'd47   : {morse_code, morse_len} <= punctuation[12];
                7'd58   : {morse_code, morse_len} <= punctuation[13];
                7'd59   : {morse_code, morse_len} <= punctuation[14];
                7'd61   : {morse_code, morse_len} <= punctuation[15];
                7'd63   : {morse_code, morse_len} <= punctuation[16];
                7'd64   : {morse_code, morse_len} <= punctuation[17];
                7'd95   : {morse_code, morse_len} <= punctuation[18];
                default : {morse_code, morse_len} <= 10'b0;
            endcase
        end
    end
endmodule
