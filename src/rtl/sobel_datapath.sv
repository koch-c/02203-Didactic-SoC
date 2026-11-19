`timescale 1ns / 1ps

module sobel_datapath #(
    parameter int IMG_W = 352,
    parameter int IMG_H = 288
)(
    input  logic        rst_n,
    input  logic        clear,
    input  logic        clk,
    input  logic        en,
    input  logic [31:0] in,
    output logic [31:0] out
);

    // The leftmost pixel is in bits [7:0].
    localparam int ROW_WORDS = IMG_W / 4;
    localparam int DEPTH = 2 * ROW_WORDS + 3;
    // The first output row needs only rows 0 and 1; its top is replicated.
    localparam int WARMUP = ROW_WORDS + 2;

    localparam int FILL_W = $clog2(WARMUP + 1);
    localparam int COL_W = $clog2(ROW_WORDS);
    localparam int ROW_W = $clog2(IMG_H + 1);

    logic [FILL_W - 1 : 0] fill_count;
    logic [COL_W  - 1 : 0] center_col;
    logic [ROW_W  - 1 : 0] center_row;

    // ----------------------------------------
    // Shift register
    // ----------------------------------------

    logic [DEPTH * 32 - 1:0] history;

    shift_register #(
        .DEPTH(DEPTH)
    ) u_shift (
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),
        .en(en),
        .in(in),
        .out(history)
    );

    // ----------------------------------------
    // Three adjacent words from each row
    // ----------------------------------------
    
    logic [31:0] top_left, top_center, top_right;
    logic [31:0] mid_left, mid_center, mid_right;
    logic [31:0] bot_left, bot_center, bot_right;

    assign top_left   = history[0 * 32 +: 32];
    assign top_center = history[1 * 32 +: 32];
    assign top_right  = history[2 * 32 +: 32];
    
    assign mid_left   = history[ROW_WORDS * 32 +: 32];
    assign mid_center = history[(ROW_WORDS + 1) * 32 +: 32];
    assign mid_right  = history[(ROW_WORDS + 2) * 32 +: 32];
    
    assign bot_left   = history[(2 * ROW_WORDS) * 32 +: 32];
    assign bot_center = history[(2 * ROW_WORDS + 1) * 32 +: 32];
    assign bot_right  = history[(2 * ROW_WORDS + 2) * 32 +: 32];

    // ----------------------------------------
    // Six consecutive pixels from each row
    // ----------------------------------------

    logic [47:0] top_strip;
    logic [47:0] mid_strip;
    logic [47:0] bot_strip;
    logic [47:0] effective_top, effective_bot;

    // Replicate each row's edge pixel instead of using a cross-row neighbor.
    assign top_strip = {
        (center_col == ROW_WORDS - 1) ? top_center[31:24] : top_right[7:0],
        top_center,
        (center_col == 0) ? top_center[7:0] : top_left[31:24]
    };

    assign mid_strip = {
        (center_col == ROW_WORDS - 1) ? mid_center[31:24] : mid_right[7:0],
        mid_center,
        (center_col == 0) ? mid_center[7:0] : mid_left[31:24]
    };

    assign bot_strip = {
        (center_col == ROW_WORDS - 1) ? bot_center[31:24] : bot_right[7:0],
        bot_center,
        (center_col == 0) ? bot_center[7:0] : bot_left[31:24]
    };

    // Replicate the nearest row above/below the image, including its corners.
    assign effective_top = (center_row == 0) ? mid_strip : top_strip;
    assign effective_bot = (center_row == IMG_H - 1) ? mid_strip : bot_strip;

    // ----------------------------------------
    // Four parallel Sobel modules
    // ----------------------------------------

    logic [7:0] result [0:3];

    for (genvar j = 0; j < 4; j++) begin : g_sobel

        sobel_arith u_sobel (
            .s11(effective_top[(j + 0) * 8 +: 8]),
            .s12(effective_top[(j + 1) * 8 +: 8]),
            .s13(effective_top[(j + 2) * 8 +: 8]),

            .s21(mid_strip[(j + 0) * 8 +: 8]),
            .s23(mid_strip[(j + 2) * 8 +: 8]),

            .s31(effective_bot[(j + 0) * 8 +: 8]),
            .s32(effective_bot[(j + 1) * 8 +: 8]),
            .s33(effective_bot[(j + 2) * 8 +: 8]),

            .s_out(result[j])
        );

    end

    // ----------------------------------------
    // Track the current output position
    // ----------------------------------------

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            fill_count <= '0;
            center_col <= '0;
            center_row <= '0;
        end

        else if (clear) begin
            fill_count <= '0;
            center_col <= '0;
            center_row <= '0;
        end

        else if (en) begin

            if (fill_count < WARMUP) begin
                fill_count <= fill_count + 1'b1;
            end

            else if (center_col == ROW_WORDS-1) begin
                center_col <= '0;

                if (center_row < IMG_H)
                    center_row <= center_row + 1'b1;
            end

            else begin
                center_col <= center_col + 1'b1;
            end

        end

    end

    // ----------------------------------------
    // Pack four Sobel results into one word
    // ----------------------------------------

    // The FSM enables writes only when the window contains a valid result.
    assign out = {
        result[3],
        result[2],
        result[1],
        result[0]
    };

endmodule
