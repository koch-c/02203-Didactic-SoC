`timescale 1ns / 1ps

module edge_detector_timing_top (
    input  logic        rst,
    input  logic        clk,
    input  logic        en,
    input  logic [31:0] in,
    output logic [31:0] out
);

    logic [31:0] sobel_out;

    edge_detector_top u_edge_detector (
        .rst(rst),
        .clk(clk),
        .en(en),
        .in(in),
        .out(sobel_out)
    );

    // Register the four Sobel results.
    always_ff @(posedge clk) begin
        if (rst)
            out <= 32'd0;
        else if (en)
            out <= sobel_out;
    end

endmodule