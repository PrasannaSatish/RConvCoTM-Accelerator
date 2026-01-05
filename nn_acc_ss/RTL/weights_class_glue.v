module weights_clauses_glue #(
    parameter ADDR_WIDTH        = 11,
    parameter WORD_WIDTH        = 32,
    parameter DATA_WIDTH        = 256,

    parameter WEIGHT_BASE_ADDR  = 0,
    parameter CLAUSES_BASE_ADDR   = 1024
)(
    input  wire                      i_clk,
    input  wire                      i_rst_n,

    // ====================================================
    // Inputs from APB register block
    // ====================================================
    input  wire [ADDR_WIDTH-1:0]     i_addr_reg,

    // Weight data inputs (8 x 32-bit)
    input  wire [WORD_WIDTH-1:0]     i_weight_data0,
    input  wire [WORD_WIDTH-1:0]     i_weight_data1,
    input  wire [WORD_WIDTH-1:0]     i_weight_data2,
    input  wire [WORD_WIDTH-1:0]     i_weight_data3,
    input  wire [WORD_WIDTH-1:0]     i_weight_data4,
    input  wire [WORD_WIDTH-1:0]     i_weight_data5,
    input  wire [WORD_WIDTH-1:0]     i_weight_data6,
    input  wire [WORD_WIDTH-1:0]     i_weight_data7,

    // Individual command bits
    input  wire                      i_cmd_weight_write,
    input  wire                      i_cmd_weight_read,
    input  wire                      i_cmd_Clauses_write,
    input  wire                      i_cmd_Clauses_read,

    // ====================================================
    // SRAM READ PORTS (Port-B from both RAMs)
    // ====================================================
    input  wire [DATA_WIDTH-1:0]     i_weight_sram_dout,
    input  wire [DATA_WIDTH-1:0]     i_Clauses_sram_dout,

    // ====================================================
    // OUTPUTS to WEIGHT SRAM (Port-A)
    // ====================================================
    output reg                       o_weight_sram_ena,
    output reg                       o_weight_sram_wea,
    output reg  [ADDR_WIDTH-1:0]     o_weight_sram_addra,
    output reg  [DATA_WIDTH-1:0]     o_weight_sram_dina,

    // ====================================================
    // OUTPUTS to Clauses SRAM (Port-A)
    // ====================================================
    output reg                       o_Clauses_sram_ena,
    output reg                       o_Clauses_sram_wea,
    output reg  [ADDR_WIDTH-1:0]     o_Clauses_sram_addra,
    output reg  [DATA_WIDTH-1:0]     o_Clauses_sram_dina,

    // ====================================================
    // BACK to APB (optional read/debug)
    // ====================================================
    output reg  [DATA_WIDTH-1:0]     o_read_data,
    output reg                       o_read_data_valid,
    output reg                       o_cmd_error
);

    // ====================================================
    // CONCATENATE 8 x 32 INTO 256 
    // ====================================================
    wire [DATA_WIDTH-1:0] w_weight_data_256;

    assign w_weight_data_256 = {
        i_weight_data7, i_weight_data6,
        i_weight_data5, i_weight_data4,
        i_weight_data3, i_weight_data2,
        i_weight_data1, i_weight_data0
    };

    // ====================================================
    // ADDRESS DECODE LOGIC
    // ====================================================
    wire addr_in_weight_region = (i_addr_reg < CLAUSES_BASE_ADDR[ADDR_WIDTH-1:0]);
    wire addr_in_Clauses_region  = (i_addr_reg >= CLAUSES_BASE_ADDR[ADDR_WIDTH-1:0]);

    wire [ADDR_WIDTH-1:0] weight_local_addr =
        i_addr_reg - WEIGHT_BASE_ADDR[ADDR_WIDTH-1:0];

    wire [ADDR_WIDTH-1:0] Clauses_local_addr =
        i_addr_reg - CLAUSES_BASE_ADDR[ADDR_WIDTH-1:0];

    // ====================================================
    // MUTUAL EXCLUSION CHECK 
    // ====================================================
    wire [2:0] cmd_popcount =
        i_cmd_weight_write +
        i_cmd_weight_read  +
        i_cmd_Clauses_write  +
        i_cmd_Clauses_read;

    // ====================================================
    // WRITE PATH LOGIC (COMBINATIONAL)
    // ====================================================
    always @* begin
        // Default inactive
        o_weight_sram_ena   = 1'b0;
        o_weight_sram_wea   = 1'b0;
        o_weight_sram_addra = {ADDR_WIDTH{1'b0}};
        o_weight_sram_dina  = {DATA_WIDTH{1'b0}};

        o_Clauses_sram_ena    = 1'b0;
        o_Clauses_sram_wea    = 1'b0;
        o_Clauses_sram_addra  = {ADDR_WIDTH{1'b0}};
        o_Clauses_sram_dina   = {DATA_WIDTH{1'b0}};

        // ---------------------------
        // Weight Write
        // ---------------------------
        if (i_cmd_weight_write && addr_in_weight_region) begin
            o_weight_sram_ena   = 1'b1;
            o_weight_sram_wea   = 1'b1;
            o_weight_sram_addra = weight_local_addr;
            o_weight_sram_dina  = w_weight_data_256;
        end

        // ---------------------------
        // Clauses Write
        // ---------------------------
        if (i_cmd_Clauses_write && addr_in_Clauses_region) begin
            o_Clauses_sram_ena   = 1'b1;
            o_Clauses_sram_wea   = 1'b1;
            o_Clauses_sram_addra = Clauses_local_addr;
            o_Clauses_sram_dina  = w_weight_data_256; // same packet reused
        end
    end

    // ====================================================
    // READ PATH + ERROR + VALID PULSE  (SEQUENTIAL)
    // ====================================================
    always @(posedge i_clk or negedge i_rst_n) begin
        if(!i_rst_n) begin
            o_read_data       <= {DATA_WIDTH{1'b0}};
            o_read_data_valid <= 1'b0;
            o_cmd_error       <= 1'b0;
        end
        else begin
            o_read_data_valid <= 1'b0;

            // ERROR if more than one command asserted
            o_cmd_error <= (cmd_popcount > 3'd1);

            // ---------------------------
            // Weight Read
            // ---------------------------
            if (i_cmd_weight_read && addr_in_weight_region) begin
                o_read_data       <= i_weight_sram_dout;
                o_read_data_valid <= 1'b1;
            end

            // ---------------------------
            // Clauses Read
            // ---------------------------
            else if (i_cmd_Clauses_read && addr_in_Clauses_region) begin
                o_read_data       <= i_Clauses_sram_dout;
                o_read_data_valid <= 1'b1;
            end
        end
    end

endmodule

