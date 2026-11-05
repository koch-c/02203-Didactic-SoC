`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Course : 02203 Design of Digital Systems
// Group : 3
// Date : 29/10/2026
//////////////////////////////////////////////////////////////////////////////////


module mem_async6r_sync1w #(
    parameter int DEPTH = 7,
    localparam int ADDR_WIDTH = $clog2(DEPTH)
    )(
    input         clk,
    input         wr_en,
    input  [ADDR_WIDTH-1:0] wr_address,
    input  [31:0] wr_data,
    input  [ADDR_WIDTH-1:0] rd_address0,
    input  [ADDR_WIDTH-1:0] rd_address1,
    input  [ADDR_WIDTH-1:0] rd_address2,
    input  [ADDR_WIDTH-1:0] rd_address3,
    input  [ADDR_WIDTH-1:0] rd_address4,
    input  [ADDR_WIDTH-1:0] rd_address5,
    output [31:0] rd_data0,
    output [31:0] rd_data1,
    output [31:0] rd_data2,
    output [31:0] rd_data3,
    output [31:0] rd_data4,
    output [31:0] rd_data5
    );
    
    logic [31:0] memory[0:DEPTH-1];
    
    assign rd_data0 = memory[rd_address0];
    assign rd_data1 = memory[rd_address1];
    assign rd_data2 = memory[rd_address2];
    assign rd_data3 = memory[rd_address3];
    assign rd_data4 = memory[rd_address4];
    assign rd_data5 = memory[rd_address5];
    
    always_ff @(posedge clk) begin // Synchronous write
        if (wr_en)
            memory[wr_address] <= wr_data;
    end
    
endmodule
