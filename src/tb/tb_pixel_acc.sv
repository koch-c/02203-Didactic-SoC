`timescale 1ns/1ps

// Standalone address/handshake test (output pixel data is not checked).
// Run from the repository root:
//   $ verilator --binary --timing -Wno-fatal --top-module tb_pixel_acc \
//     --Mdir build/pixel_acc_tb src/rtl/pixel_acc.sv src/tb/tb_pixel_acc.sv
//   build/pixel_acc_tb/Vtb_pixel_acc
module tb_pixel_acc;
  localparam int BUF_AW = 15;
  localparam int BUF_DEPTH = 25344;
  localparam int IMG_WIDTH = 88;
  localparam int IMG_HEIGHT = BUF_DEPTH / IMG_WIDTH;
  localparam int EXPECTED_WRITES = (IMG_HEIGHT - 2) * (IMG_WIDTH - 2);
  localparam int MAX_CYCLES = BUF_DEPTH * 4;

  logic clk = 1'b0;
  logic rst_n = 1'b0;
  logic start = 1'b0;
  logic finish;
  logic ibuf_rd_en;
  logic [BUF_AW-1:0] ibuf_rd_addr;
  logic [31:0] ibuf_rd_data = '0;
  logic obuf_wr_en;
  logic [BUF_AW-1:0] obuf_wr_addr;
  logic [31:0] obuf_wr_data;
  logic [31:0] ibuf [0:BUF_DEPTH-1];

  int expected_rd_addr = 0;
  int expected_wr_addr = IMG_WIDTH + 1;
  int read_count = 0;
  int write_count = 0;
  bit active = 1'b0;
  bit finish_seen = 1'b0;
  bit previous_finish = 1'b0;

  always #5 clk = ~clk;

  pixel_acc #(
      .BUF_AW(BUF_AW),
      .BUF_DEPTH(BUF_DEPTH),
      .IMG_WIDTH(IMG_WIDTH)
  ) dut (
      .clk(clk),
      .rst_n(rst_n),
      .ibuf_rd_en(ibuf_rd_en),
      .ibuf_rd_addr(ibuf_rd_addr),
      .ibuf_rd_data(ibuf_rd_data),
      .obuf_wr_en(obuf_wr_en),
      .obuf_wr_addr(obuf_wr_addr),
      .obuf_wr_data(obuf_wr_data),
      .start(start),
      .finish(finish)
  );

  // Synchronous BRAM: data updates after the requesting rising edge
  // and is available to the DUT during the following cycle.
  always @(posedge clk) begin
    if (rst_n && ibuf_rd_en === 1'b1) begin
      if ($isunknown(ibuf_rd_addr) || int'(ibuf_rd_addr) >= BUF_DEPTH)
        $fatal(1, "Invalid ibuf read address: %0d", ibuf_rd_addr);
      ibuf_rd_data <= ibuf[ibuf_rd_addr];
    end
  end

  // Sample the same signals the memories sample, before NBA updates.
  always @(posedge clk) begin
    if (rst_n) begin
      if ($isunknown({ibuf_rd_en, obuf_wr_en, finish}))
        $fatal(1, "Unknown read/write enable or finish");

      if (start) active = 1'b1;
      if (!active && (ibuf_rd_en || obuf_wr_en || finish))
        $fatal(1, "Unexpected transaction or finish while idle");

      if (ibuf_rd_en) begin
        if (ibuf_rd_addr !== BUF_AW'(expected_rd_addr))
          $fatal(1, "Read #%0d: expected address %0d, got %0d",
                 read_count, expected_rd_addr, ibuf_rd_addr);
        read_count++;
        if (expected_rd_addr == BUF_DEPTH - 1) expected_rd_addr = 0;
        else expected_rd_addr++;
      end

      if (obuf_wr_en) begin
        if (write_count >= EXPECTED_WRITES)
          $fatal(1, "Too many output writes");
        if (obuf_wr_addr !== BUF_AW'(expected_wr_addr))
          $fatal(1, "Write #%0d: expected address %0d, got %0d",
                 write_count, expected_wr_addr, obuf_wr_addr);
        write_count++;
        // Last interior column: skip the right border and next left border.
        if (expected_wr_addr % IMG_WIDTH == IMG_WIDTH - 2)
          expected_wr_addr += 3;
        else expected_wr_addr++;
      end

      if (finish && previous_finish)
        $fatal(1, "finish must be a one-cycle pulse");
      previous_finish = finish;
      if (finish) begin
        if (write_count != EXPECTED_WRITES)
          $fatal(1, "finish after %0d writes; expected %0d",
                 write_count, EXPECTED_WRITES);
        if (read_count <= BUF_DEPTH)
          $fatal(1, "Read wraparound was not exercised (%0d reads)", read_count);
        finish_seen = 1'b1;
        active = 1'b0;
      end
    end
  end

  initial begin
    for (int i = 0; i < BUF_DEPTH; i++) ibuf[i] = 32'(i);
    repeat (4) @(negedge clk);
    rst_n = 1'b1;
    repeat (2) @(negedge clk);
    start = 1'b1;
    @(negedge clk);
    start = 1'b0;

    // Wait on falling edges to avoid racing the rising-edge checker.
    for (int cycle = 0; cycle < MAX_CYCLES; cycle++) begin
      @(negedge clk);
      if (finish_seen) begin
        repeat (4) @(negedge clk);
        $display("PASS: %0d reads (including wraparound), %0d interior writes",
                 read_count, write_count);
        $finish;
      end
    end
    $fatal(1, "Timeout: %0d reads, %0d/%0d writes, no finish",
           read_count, write_count, EXPECTED_WRITES);
  end
endmodule
