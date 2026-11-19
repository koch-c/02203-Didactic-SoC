`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Course : 02203 Design of Digital Systems
// Group : 3
// Date : 22/10/2026
//////////////////////////////////////////////////////////////////////////////////


module sobel_arith(
    input  logic [7:0] s11,
    input  logic [7:0] s12,
    input  logic [7:0] s13,
    input  logic [7:0] s21,
    input  logic [7:0] s23,
    input  logic [7:0] s31,
    input  logic [7:0] s32,
    input  logic [7:0] s33,
    output logic [7:0] s_out
    );
    
    // 11 bit for calculations
    logic signed [10:0] dx;
    logic signed [10:0] dy;
    logic signed [10:0] corner_a, corner_b;
    logic        [10:0] abs_d;
    
    logic signed [10:0] p11, p12, p13;
    logic signed [10:0] p21, p23;
    logic signed [10:0] p31, p32, p33;
    
    // Increase bitwidth by 3 bits for calculations
    
    assign p11 = $signed({3'b000, s11});
    assign p12 = $signed({3'b000, s12});
    assign p13 = $signed({3'b000, s13});
    
    assign p21 = $signed({3'b000, s21});
    assign p23 = $signed({3'b000, s23});
    
    assign p31 = $signed({3'b000, s31});
    assign p32 = $signed({3'b000, s32});
    assign p33 = $signed({3'b000, s33});
    
    // logic [20:0] x, t, scaled;
    
    always_comb begin
        // Both gradients reuse the same two corner differences.
        corner_a = p13 - p31;
        corner_b = p11 - p33;
        dx = corner_a - corner_b + ((p23 - p21) << 1);
        dy = corner_a + corner_b + ((p12 - p32) << 1);
    
        abs_d = (dx < 0 ? -dx : dx) + (dy < 0 ? -dy : dy); // abs(d) = abs(dx) + abs(dy)
    
        s_out = abs_d / 6; // Scaling. Vivado is good at optimizing division by constants.
        
        // s_out = magnitude > 255 ? 255 : magnitude; // Cap
        
        
        // Below is the "optimized" version of division by six,
        // but actually uses more LUTs (12 more) and is slower in terms of logic.
        // It also uses 6 more logic slices (19 vs 12)
        /*x = {10'b0, abs_d};

        t = (x << 3) + (x << 1) + x;  // 11*x
        t = (t << 5) - t;             // 341*x Double check order of bitshifts and subtraction
        scaled = (t << 1) + x;        // 683*x
    
        s_out = scaled[19:12];*/        // x / 6
    end
    
endmodule