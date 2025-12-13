module csr #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter BRAM_AW    = 10          // 2^10 = 1024 words in each BRAM
)(
    input  wire                  clk,
    input  wire                  rst,   // active-high synchronous reset

    // APB3 Slave Interface
    input  wire                  PSEL,
    input  wire                  PENABLE,
    input  wire                  PWRITE,
    input  wire [ADDR_WIDTH-1:0] PADDR,
    input  wire [DATA_WIDTH-1:0] PWDATA,
    output reg  [DATA_WIDTH-1:0] PRDATA,
    output wire                  PREADY,
    output wire                  PSLVERR,

    // -------- Model parameter outputs to accelerator --------
    output reg  [9:0]  img_w,
    output reg  [9:0]  img_h,
    output reg  [7:0]  win_w,
    output reg  [7:0]  win_h,
    output reg  [2:0]  stride,
    output reg  [11:0] num_clauses,
    output reg  [11:0] num_features,
    output reg  [7:0]  num_classes,
    output reg  [7:0]  ta_threshold,
    output reg  [9:0]  patch_max,
    output reg         accel_reset,
    output reg         start,

    // -------- BRAM Port-B connections to accelerator --------
    // Weights BRAM Port-B
    input  wire                  w_clkb,
    input  wire                  w_enb,
    input  wire [BRAM_AW-1:0]    w_addrb,
    output wire [DATA_WIDTH-1:0] w_doutb,

    // Clauses BRAM Port-B
    input  wire                  c_clkb,
    input  wire                  c_enb,
    input  wire [BRAM_AW-1:0]    c_addrb,
    output wire [DATA_WIDTH-1:0] c_doutb
);

    // -------------------------------
    // APB fixed responses
    // -------------------------------
    assign PREADY  = 1'b1;   // zero-wait-state slave
    assign PSLVERR = 1'b0;

    // -------------------------------
    // Address decode helpers
    // -------------------------------
    // Regions:
    // 0x0000_0000 â 0x0000_0FFF : weights BRAM (4 KB)
    // 0x0000_1000 â 0x0000_1FFF : clauses BRAM (4 KB)
    // 0x0000_2000 â ...        : configuration registers

    wire in_weights = (PADDR[15:12] == 4'h0);
    wire in_clauses = (PADDR[15:12] == 4'h1);
    wire in_regs    = (PADDR[15:12] == 4'h2);

    // Word address inside BRAM (remove 2 LSBs)
    wire [BRAM_AW-1:0] bram_addr = PADDR[BRAM_AW+1:2];

    // Register absolute addresses
    localparam [ADDR_WIDTH-1:0] IMG_CFG_ADDR     = 32'h0000_2000;
    localparam [ADDR_WIDTH-1:0] WIN_CFG_ADDR     = 32'h0000_2004;
    localparam [ADDR_WIDTH-1:0] STRIDE_CFG_ADDR  = 32'h0000_2008;
    localparam [ADDR_WIDTH-1:0] CLAUSE_CFG_ADDR  = 32'h0000_200C;
    localparam [ADDR_WIDTH-1:0] FEATURE_CFG_ADDR = 32'h0000_2010;
    localparam [ADDR_WIDTH-1:0] CLASS_CFG_ADDR   = 32'h0000_2014;
    localparam [ADDR_WIDTH-1:0] THRESH_CFG_ADDR  = 32'h0000_2018;
    localparam [ADDR_WIDTH-1:0] PATCH_CFG_ADDR   = 32'h0000_201C;
    localparam [ADDR_WIDTH-1:0] CONTROL_ADDR     = 32'h0000_2020;

    wire sel_img_cfg     = (PADDR == IMG_CFG_ADDR);
    wire sel_win_cfg     = (PADDR == WIN_CFG_ADDR);
    wire sel_stride_cfg  = (PADDR == STRIDE_CFG_ADDR);
    wire sel_clause_cfg  = (PADDR == CLAUSE_CFG_ADDR);
    wire sel_feature_cfg = (PADDR == FEATURE_CFG_ADDR);
    wire sel_class_cfg   = (PADDR == CLASS_CFG_ADDR);
    wire sel_thresh_cfg  = (PADDR == THRESH_CFG_ADDR);
    wire sel_patch_cfg   = (PADDR == PATCH_CFG_ADDR);
    wire sel_control     = (PADDR == CONTROL_ADDR);

    // -------------------------------
    // Write strobes
    // -------------------------------
    wire wr_en = PSEL && PENABLE && PWRITE;
    wire rd_en = PSEL && ~PWRITE;   // read in access phase (PENABLE==1) is enough

    // BRAM write enables
    wire weight_we  = wr_en && in_weights;
    wire clause_we  = wr_en && in_clauses;

    // BRAM enables for port A
    wire weight_ena = in_weights && PSEL;
    wire clause_ena = in_clauses && PSEL;

    // -------------------------------
    // Configuration registers
    // -------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            img_w        <= 10'd0;
            img_h        <= 10'd0;
            win_w        <= 8'd0;
            win_h        <= 8'd0;
            stride       <= 3'd1;
            num_clauses  <= 12'd0;
            num_features <= 12'd0;
            num_classes  <= 8'd0;
            ta_threshold <= 8'd0;
            patch_max    <= 10'd0;
            accel_reset  <= 1'b0;
            start        <= 1'b0;
        end else if (wr_en && in_regs) begin
            if (sel_img_cfg) begin
                img_w <= PWDATA[9:0];
                img_h <= PWDATA[19:10];
            end
            else if (sel_win_cfg) begin
                win_w <= PWDATA[7:0];
                win_h <= PWDATA[15:8];
            end
            else if (sel_stride_cfg) begin
                stride <= PWDATA[2:0];
            end
            else if (sel_clause_cfg) begin
                num_clauses <= PWDATA[11:0];
            end
            else if (sel_feature_cfg) begin
                num_features <= PWDATA[11:0];
            end
            else if (sel_class_cfg) begin
                num_classes <= PWDATA[7:0];
            end
            else if (sel_thresh_cfg) begin
                ta_threshold <= PWDATA[7:0];
            end
            else if (sel_patch_cfg) begin
                patch_max <= PWDATA[9:0];
            end
            else if (sel_control) begin
                start       <= PWDATA[0];
                accel_reset <= PWDATA[1];
            end
        end
    end

    // -------------------------------
    // APB Readback Mux (for regs)
    // -------------------------------
    always @* begin
        PRDATA = {DATA_WIDTH{1'b0}};

        if (rd_en && in_regs) begin
            case (PADDR)
                IMG_CFG_ADDR:
                    PRDATA = {12'd0, img_h, img_w};
                WIN_CFG_ADDR:
                    PRDATA = {16'd0, win_h, win_w};
                STRIDE_CFG_ADDR:
                    PRDATA = {29'd0, stride};
                CLAUSE_CFG_ADDR:
                    PRDATA = {20'd0, num_clauses};
                FEATURE_CFG_ADDR:
                    PRDATA = {20'd0, num_features};
                CLASS_CFG_ADDR:
                    PRDATA = {24'd0, num_classes};
                THRESH_CFG_ADDR:
                    PRDATA = {24'd0, ta_threshold};
                PATCH_CFG_ADDR:
                    PRDATA = {22'd0, patch_max};
                CONTROL_ADDR:
                    PRDATA = {30'd0, accel_reset, start};
                default: ;
            endcase
        end
    end

    // -------------------------------
    // Weights BRAM instance
    // -------------------------------
    blk_mem_gen_0 #(
        .ADDR_WIDTH(BRAM_AW),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_weights_bram (
        .clka  (clk),
        .reset (rst),
        .ena   (weight_ena),
        .wea   (weight_we),
        .addra (bram_addr),
        .dina  (PWDATA),

        .clkb  (w_clkb),
        .enb   (w_enb),
        .addrb (w_addrb),
        .doutb (w_doutb)
    );

    // -------------------------------
    // Clauses BRAM instance
    // -------------------------------
    blk_mem_gen_1 #(
        .ADDR_WIDTH(BRAM_AW),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_clauses_bram (
        .clka  (clk),
        .reset (rst),
        .ena   (clause_ena),
        .wea   (clause_we),
        .addra (bram_addr),
        .dina  (PWDATA),

        .clkb  (c_clkb),
        .enb   (c_enb),
        .addrb (c_addrb),
        .doutb (c_doutb)
    );

endmodule
