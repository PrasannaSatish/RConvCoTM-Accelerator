/**
 * File              : dma_axi_wrapper.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio)
 * Modified By       : CSR Disabled Version
 */

module dma_axi_wrapper
  import amba_axi_pkg::*;
  import dma_utils_pkg::*;
#(
  parameter int DMA_ID_VAL = 0
)(
  input                 clk,
  input                 rst,

  // ================================
  // Master DMA AXI Interface
  // ================================
  output  s_axi_mosi_t   dma_m_mosi_o,
  input   s_axi_miso_t   dma_m_miso_i,

  // ================================
  // Status / IRQs
  // ================================
  output  logic          dma_done_o,
  output  logic          dma_error_o
);

  // =========================================================
  // Local parameters
  // =========================================================
  localparam AXI_DATA_WIDTH = `AXI_DATA_WIDTH;

  // =========================================================
  // DMA descriptor vectors
  // =========================================================
  logic [`DMA_NUM_DESC*$bits(desc_addr_t)-1:0]  dma_desc_src_vec;
  logic [`DMA_NUM_DESC*$bits(desc_addr_t)-1:0]  dma_desc_dst_vec;
  logic [`DMA_NUM_DESC*$bits(desc_num_t)-1:0]   dma_desc_byt_vec;
  logic [`DMA_NUM_DESC-1:0]                     dma_desc_wr_mod;
  logic [`DMA_NUM_DESC-1:0]                     dma_desc_rd_mod;
  logic [`DMA_NUM_DESC-1:0]                     dma_desc_en;

  // =========================================================
  // DMA structures
  // =========================================================
  s_dma_desc_t    [`DMA_NUM_DESC-1:0] dma_desc;
  s_dma_control_t                    dma_ctrl;
  s_dma_status_t                     dma_stats;
  s_dma_error_t                      dma_error;

  // =========================================================
  // DMA status outputs
  // =========================================================
  always_comb begin
    dma_done_o  = dma_stats.done;
    dma_error_o = dma_stats.error;
  end

  // =========================================================
  // FORCE DMA CONTROL VALUES (CSR DISABLED)
  // =========================================================
  always_comb begin
    dma_ctrl.go        = 1'b1;    // Always enable DMA
    dma_ctrl.abort_req = 1'b0;    // Never abort
    dma_ctrl.max_burst = 8'd16;   // Safe AXI burst length
  end

  // =========================================================
  // FORCE DESCRIPTOR ENABLES
  // =========================================================
  always_comb begin
    for (int i = 0; i < `DMA_NUM_DESC; i++) begin
      dma_desc_en[i] = 1'b1;      // Enable all descriptors
    end
  end

  // =========================================================
  // Hook descriptor vectors to DMA structures
  // =========================================================
  always_comb begin
    for (int i = 0; i < `DMA_NUM_DESC; i++) begin
      dma_desc[i].src_addr  =
        dma_desc_src_vec[i*`DMA_ADDR_WIDTH +: `DMA_ADDR_WIDTH];

      dma_desc[i].dst_addr  =
        dma_desc_dst_vec[i*`DMA_ADDR_WIDTH +: `DMA_ADDR_WIDTH];

      dma_desc[i].num_bytes =
        dma_desc_byt_vec[i*`DMA_ADDR_WIDTH +: `DMA_ADDR_WIDTH];

      dma_desc[i].wr_mode   =
        dma_mode_t'(dma_desc_wr_mod[i]);

      dma_desc[i].rd_mode   =
        dma_mode_t'(dma_desc_rd_mod[i]);

      dma_desc[i].enable    =
        dma_desc_en[i];
    end
  end

  // =========================================================
  // DMA FUNCTIONAL CORE (UNCHANGED)
  // =========================================================
  dma_func_wrapper #(
    .DMA_ID_VAL (DMA_ID_VAL)
  ) u_dma_func_wrapper (
    .clk         (clk),
    .rst         (rst),

    // Control / descriptors
    .dma_ctrl_i  (dma_ctrl),
    .dma_desc_i  (dma_desc),

    // Status / errors
    .dma_stats_o (dma_stats),
    .dma_error_o (dma_error),

    // AXI Master interface
    .dma_mosi_o  (dma_m_mosi_o),
    .dma_miso_i  (dma_m_miso_i)
  );

endmodule
