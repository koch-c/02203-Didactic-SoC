`timescale 1ns / 1ps

module shift_register #(
    parameter WORD_W    = 32,                    // bits per word (4 pixels x 8 bit)
    parameter ROW_WORDS = 352*8/WORD_W,          // 88 words per image row
    parameter DEPTH     = 2*ROW_WORDS + 3        // 2 full rows + 3 words of row 3
)(
    input  logic                     clk,
    input  logic                     rst_n,
    input  logic                     clear,
    input  logic                     en,
    input  logic [WORD_W-1:0]        in,          // whole new word in
    output logic [DEPTH*WORD_W-1:0]  out         // word k = out[k*WORD_W +: WORD_W]
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            out <= '0;
        else if (clear)
            out <= '0;
        else if (en)
            out <= {in, out[DEPTH*WORD_W-1 : WORD_W]};  // new word enters at top, word 0 falls out
    end

endmodule
