// ============================================================
//  pixel_acc - STUDENT MODULE
//
//  You are given direct read access to ibuf and write access
//  to obuf. Both are synchronous BRAMs with 1-cycle read latency.
//
//  Interface:
//    start  - pulsed high for 1 cycle to begin processing
//    finish - assert high for 1 cycle when all output words
//             have been written to obuf
//
//  ibuf read port:
//    Set ibuf_rd_en=1 and ibuf_rd_addr to the word you want.
//    ibuf_rd_data is valid on the NEXT clock cycle.
//
//  obuf write port:
//    Set obuf_wr_en=1, obuf_wr_addr, obuf_wr_data on the same cycle.
//    The word is written on the rising edge.
//
//  Parameters:
//    BUF_AW    - address width (ibuf/obuf have 2^BUF_AW words)
//    BUF_DEPTH - total number of words in each buffer
//    IMG_WIDTH - frame width in words (= pixels per row / 4)
// ============================================================
module pixel_acc #(
    parameter int BUF_AW    = 15,
    parameter int BUF_DEPTH = 25344,
    parameter int IMG_WIDTH = 88      // 352 pixels / 4 pixels-per-word
) (
    input logic clk,
    input logic rst_n,

    // ibuf read port
    output logic              ibuf_rd_en,
    output logic [BUF_AW-1:0] ibuf_rd_addr,
    input  logic [      31:0] ibuf_rd_data,

    // obuf write port
    output logic              obuf_wr_en,
    output logic [BUF_AW-1:0] obuf_wr_addr,
    output logic [      31:0] obuf_wr_data,

    // handshake
    input  logic start,
    output logic finish
);

  // ============================================================
  // BRAM data is consumed one cycle after each read request.
  // LOAD waits until the datapath has captured the complete first window.
  // In COMPUTE, the combinational Sobel result is written directly on the
  // next rising edge, before that edge advances the datapath window.
  // ============================================================

  typedef enum logic [2:0] {
    IDLE     = 3'b000,
    LOAD     = 3'b001,
    COMPUTE  = 3'b010,
    FINISH   = 3'b100
  } state_t;

  state_t state;
  state_t state_next;
  logic [BUF_AW-1:0] rd_addr, rd_addr_next;
  logic [BUF_AW-1:0] wr_addr, wr_addr_next;
  logic               ibuf_data_valid;
  logic               datapath_clear;

  sobel_datapath #(
      .IMG_W(IMG_WIDTH * 4),
      .IMG_H(BUF_DEPTH / IMG_WIDTH)
  ) u_sobel_datapath (
      .clk(clk),
      .rst_n(rst_n),
      .clear(datapath_clear),
      .en(ibuf_data_valid),
      .in(ibuf_rd_data),
      .out(obuf_wr_data)
  );

  always_comb begin
    // default values
    state_next     = state;
    rd_addr_next   = rd_addr;
    wr_addr_next   = wr_addr;
    ibuf_rd_en     = 1'b0;
    obuf_wr_en     = 1'b0;
    finish         = 1'b0;
    datapath_clear = 1'b0;
    ibuf_rd_addr   = rd_addr;
    obuf_wr_addr   = wr_addr;


    case (state)
      IDLE: begin
        if (start) begin
          state_next = LOAD;
          rd_addr_next = '0;
          wr_addr_next = BUF_AW'(IMG_WIDTH);  // skip only the first row
          datapath_clear = 1'b1;
        end
      end
      LOAD: begin
        ibuf_rd_en = 1'b1;
        if (rd_addr == BUF_AW'(IMG_WIDTH * 2 + 2)) begin
          state_next  = COMPUTE;
        end
      end
      COMPUTE: begin
        ibuf_rd_en   = 1'b1;
        obuf_wr_en   = 1'b1;
        wr_addr_next = wr_addr + 1'b1;
        if (wr_addr == BUF_AW'(BUF_DEPTH - IMG_WIDTH - 1)) begin
          state_next = FINISH;
        end
      end
      FINISH: begin
        finish = 1'b1;
        state_next = IDLE;
      end
      default: begin
        // Should not happen
      end
    endcase

    // All reading states share the same sequential, wrapping address stream.
    if (ibuf_rd_en) begin
      if (rd_addr == BUF_AW'(BUF_DEPTH - 1)) rd_addr_next = '0;
      else rd_addr_next = rd_addr + 1'b1;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state           <= IDLE;
      rd_addr         <= '0;
      wr_addr         <= '0;
      ibuf_data_valid <= 1'b0;
    end else begin
      state           <= state_next;
      rd_addr         <= rd_addr_next;
      wr_addr         <= wr_addr_next;
      ibuf_data_valid <= datapath_clear ? 1'b0 : ibuf_rd_en;
    end
  end


endmodule
