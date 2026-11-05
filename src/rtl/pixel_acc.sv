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
  // BRAM has 1-cycle read latency, so:
  //   cycle 0: read ibuf[0] issued  (rd_data not yet valid)
  //   cycle 1: read ibuf[1] issued, ibuf[0] data valid -> write obuf[0]
  //   ...
  //   cycle N: read ibuf[N] issued (last), write obuf[N-1]
  //   cycle N+1: no new read, write obuf[N], assert finish
  //
  // ============================================================

  typedef enum logic [2:0] {
    IDLE     = 3'b000,
    LOAD     = 3'b001,
    COMPUTE  = 3'b010,
    NEXT_ROW = 3'b011,
    FINISH   = 3'b100
  } state_t;

  state_t state;
  state_t state_next;
  logic [BUF_AW-1:0] rd_addr, rd_addr_next;
  logic [BUF_AW-1:0] wr_addr, wr_addr_next;
  logic [6:0] count;
  logic       count_reset;

  always_comb begin
    // default values
    state_next   = state;
    rd_addr_next = rd_addr;
    wr_addr_next = wr_addr;
    ibuf_rd_en   = 1'b0;
    obuf_wr_en   = 1'b0;
    // obuf_wr_data = '0; <---------- this has to be connected to the computer
    finish       = 1'b0;
    count_reset  = 1'b0;

    case (state)
      IDLE: begin
        if (start) begin
          state_next   = LOAD;
          rd_addr_next = '0;
          wr_addr_next = IMG_WIDTH + 1;  // skip the first row and first column of the output
        end
      end
      LOAD: begin
        ibuf_rd_en   = 1'b1;
        rd_addr_next = rd_addr + 1'b1;
        if (rd_addr == IMG_WIDTH * 2 + 2) begin  // I think it is
          count_reset = 1'b1;
          state_next  = COMPUTE;
        end
      end
      COMPUTE: begin
        ibuf_rd_en   = 1'b1;
        obuf_wr_en   = 1'b1;
        rd_addr_next = rd_addr + 1'b1;
        wr_addr_next = wr_addr + 1'b1;
        if (wr_addr == BUF_DEPTH - IMG_WIDTH - 2) begin // to second last row and second last column of the output
          state_next = FINISH;
        end else begin
          if (rd_addr == BUF_DEPTH) begin
            rd_addr_next = 0;
          end
          if (count == IMG_WIDTH - 3) begin  // equivalent to 85
            count_reset = 1'b1;
            state_next  = NEXT_ROW;
          end
        end
      end
      NEXT_ROW: begin
        ibuf_rd_en   = 1'b1;
        rd_addr_next = rd_addr + 1'b1;
        if (count == 1) begin
          count_reset  = 1'b1;
          state_next   = COMPUTE;
          wr_addr_next = wr_addr + BUF_AW'(3);  // skip the first column of the output
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
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state   <= IDLE;
      rd_addr <= '0;
      wr_addr <= '0;
    end else begin
      state   <= state_next;
      rd_addr <= rd_addr_next;
      wr_addr <= wr_addr_next;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) count <= 7'd0;
    else if (count_reset) count <= 7'd0;
    else count <= count + 7'd1;
  end


endmodule
