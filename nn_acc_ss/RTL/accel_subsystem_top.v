module accel_subsystem_top
(
    //---------------------------------------------------
    // Clock + Reset
    //---------------------------------------------------
    input  wire          i_clk,
    input  wire          i_rst_n,

    //---------------------------------------------------
    // APB Interface
    //---------------------------------------------------
    input  wire          i_PSEL,
    input  wire          i_PENABLE,
    input  wire          i_PWRITE,
    input  wire [11:2]   i_PADDR,
    input  wire [31:0]   i_PWDATA,
    input  wire [3:0]    i_PSTRB,
    

    output wire [31:0]   o_PRDATA,
    output wire          o_PREADY,
    output wire          o_PSLVERR
);

wire rst_h;
/////////////////////////////////////////////////////////
// RESET HANDLING
/////////////////////////////////////////////////////////



/////////////////////////////////////////////////////////
// INTERNAL SIGNALS
/////////////////////////////////////////////////////////

// ---------------- WEIGHTS REG ------------------------
wire [31:0] w_weight_data0;
wire [31:0] w_weight_data1;
wire [31:0] w_weight_data2;
wire [31:0] w_weight_data3;
wire [31:0] w_weight_data4;
wire [31:0] w_weight_data5;
wire [31:0] w_weight_data6;
wire [31:0] w_weight_data7;

wire [31:0] w_weight_addr;

wire        w_cmd_weight_write;
wire        w_cmd_weight_read;
wire        w_cmd_clauses_write;
wire        w_cmd_clauses_read;


// --------------- IMAGE REGS --------------------------
wire [31:0] w_img_data [0:31];
wire        w_img_cmd_pulse;


// ---------------- MODEL PARAMS -----------------------
wire [18:0] w_model_params;


// ---------------- RESULTS -----------------------------
wire [3:0]  w_acc_result_data;
wire [31:0] w_result_reg_to_apb;
wire        w_acc_input_done_pulse;


// ---------------- IMAGE STREAM ------------------------
wire [127:0] w_tdata;
wire         w_tvalid;
wire         w_tlast;
wire         w_tready;

// AXI doesn't come from glue ? force always valid
wire [15:0]  w_tkeep = 16'hFFFF;


// ---------------- SRAM INTERFACE ----------------------
wire         w_weight_sram_ena;
wire         w_weight_sram_wea;
wire [10:0]  w_weight_sram_addra;
wire [255:0] w_weight_sram_dina;
wire [255:0] w_weight_sram_dout;

wire         w_clauses_sram_ena;
wire         w_clauses_sram_wea;
wire [10:0]  w_clauses_sram_addra;
wire [255:0] w_clauses_sram_dina;
wire [255:0] w_clauses_sram_dout;


// accelerator BRAM address outputs
wire [31:0] bram_addr_a;
wire [31:0] bram_addr_a2;


/////////////////////////////////////////////////////////
// 1) APB REGISTER BLOCK
/////////////////////////////////////////////////////////
apb_accel_regs u_apb_regs
(
    .PCLK       (i_clk),
    .PRESETn    (i_rst_n),

    .PSEL       (i_PSEL),
    .PENABLE    (i_PENABLE),
    .PWRITE     (i_PWRITE),
    .PADDR      (i_PADDR),
    .PWDATA     (i_PWDATA),
    .PSTRB      (i_PSTRB),

    .PRDATA     (o_PRDATA),
    .PREADY     (o_PREADY),
    .PSLVERR    (o_PSLVERR),

    .i_result_reg_in (w_result_reg_to_apb),

    // weight regs
    .o_weight_data0 (w_weight_data0),
    .o_weight_data1 (w_weight_data1),
    .o_weight_data2 (w_weight_data2),
    .o_weight_data3 (w_weight_data3),
    .o_weight_data4 (w_weight_data4),
    .o_weight_data5 (w_weight_data5),
    .o_weight_data6 (w_weight_data6),
    .o_weight_data7 (w_weight_data7),

    .o_weight_addr  (w_weight_addr),

    .o_cmd_weight_write  (w_cmd_weight_write),
    .o_cmd_weight_read   (w_cmd_weight_read),
    .o_cmd_clauses_write (w_cmd_clauses_write),
    .o_cmd_clauses_read  (w_cmd_clauses_read),

    // image regs
    .o_img_data0  (w_img_data[0]),
    .o_img_data1  (w_img_data[1]),
    .o_img_data2  (w_img_data[2]),
    .o_img_data3  (w_img_data[3]),
    .o_img_data4  (w_img_data[4]),
    .o_img_data5  (w_img_data[5]),
    .o_img_data6  (w_img_data[6]),
    .o_img_data7  (w_img_data[7]),
    .o_img_data8  (w_img_data[8]),
    .o_img_data9  (w_img_data[9]),
    .o_img_data10 (w_img_data[10]),
    .o_img_data11 (w_img_data[11]),
    .o_img_data12 (w_img_data[12]),
    .o_img_data13 (w_img_data[13]),
    .o_img_data14 (w_img_data[14]),
    .o_img_data15 (w_img_data[15]),
    .o_img_data16 (w_img_data[16]),
    .o_img_data17 (w_img_data[17]),
    .o_img_data18 (w_img_data[18]),
    .o_img_data19 (w_img_data[19]),
    .o_img_data20 (w_img_data[20]),
    .o_img_data21 (w_img_data[21]),
    .o_img_data22 (w_img_data[22]),
    .o_img_data23 (w_img_data[23]),
    .o_img_data24 (w_img_data[24]),
    .o_img_data25 (w_img_data[25]),
    .o_img_data26 (w_img_data[26]),
    .o_img_data27 (w_img_data[27]),
    .o_img_data28 (w_img_data[28]),
    .o_img_data29 (w_img_data[29]),
    .o_img_data30 (w_img_data[30]),
    .o_img_data31 (w_img_data[31]),

    .o_img_cmd_pulse (w_img_cmd_pulse),

    .o_model_params  (w_model_params)
);


/////////////////////////////////////////////////////////
// 2) IMAGE GLUE LOGIC
/////////////////////////////////////////////////////////
image_glue_logic u_image_glue (
    .i_clk   (i_clk),
    .i_rst_n (i_rst_n),

    .i_img_data0  (w_img_data[0]),
    .i_img_data1  (w_img_data[1]),
    .i_img_data2  (w_img_data[2]),
    .i_img_data3  (w_img_data[3]),
    .i_img_data4  (w_img_data[4]),
    .i_img_data5  (w_img_data[5]),
    .i_img_data6  (w_img_data[6]),
    .i_img_data7  (w_img_data[7]),
    .i_img_data8  (w_img_data[8]),
    .i_img_data9  (w_img_data[9]),
    .i_img_data10 (w_img_data[10]),
    .i_img_data11 (w_img_data[11]),
    .i_img_data12 (w_img_data[12]),
    .i_img_data13 (w_img_data[13]),
    .i_img_data14 (w_img_data[14]),
    .i_img_data15 (w_img_data[15]),
    .i_img_data16 (w_img_data[16]),
    .i_img_data17 (w_img_data[17]),
    .i_img_data18 (w_img_data[18]),
    .i_img_data19 (w_img_data[19]),
    .i_img_data20 (w_img_data[20]),
    .i_img_data21 (w_img_data[21]),
    .i_img_data22 (w_img_data[22]),
    .i_img_data23 (w_img_data[23]),
    .i_img_data24 (w_img_data[24]),
    .i_img_data25 (w_img_data[25]),
    .i_img_data26 (w_img_data[26]),
    .i_img_data27 (w_img_data[27]),
    .i_img_data28 (w_img_data[28]),
    .i_img_data29 (w_img_data[29]),
    .i_img_data30 (w_img_data[30]),
    .i_img_data31 (w_img_data[31]),

    .i_img_cmd_pulse (w_img_cmd_pulse),

    .i_tready (w_tready),
    .o_tdata  (w_tdata),
    .o_tvalid (w_tvalid),
    .o_tlast  (w_tlast),

    .o_image_done_pulse (w_acc_input_done_pulse),

   .o_image_data_1024 (),
   .o_image_valid_1024()
);


/////////////////////////////////////////////////////////
// 3) WEIGHTS + CLAUSES GLUE
/////////////////////////////////////////////////////////
weights_clauses_glue u_wcg (
    .i_clk   (i_clk),
    .i_rst_n (i_rst_n),

    .i_addr_reg (w_weight_addr[10:0]),

    .i_weight_data0 (w_weight_data0),
    .i_weight_data1 (w_weight_data1),
    .i_weight_data2 (w_weight_data2),
    .i_weight_data3 (w_weight_data3),
    .i_weight_data4 (w_weight_data4),
    .i_weight_data5 (w_weight_data5),
    .i_weight_data6 (w_weight_data6),
    .i_weight_data7 (w_weight_data7),

    .i_cmd_weight_write  (w_cmd_weight_write),
    .i_cmd_weight_read   (w_cmd_weight_read),
    .i_cmd_Clauses_write (w_cmd_clauses_write),
    .i_cmd_Clauses_read  (w_cmd_clauses_read),

    .i_weight_sram_dout  (w_weight_sram_dout),
    .i_Clauses_sram_dout (w_clauses_sram_dout),

    .o_weight_sram_ena   (w_weight_sram_ena),
    .o_weight_sram_wea   (w_weight_sram_wea),
    .o_weight_sram_addra (w_weight_sram_addra),
    .o_weight_sram_dina  (w_weight_sram_dina),

    .o_Clauses_sram_ena   (w_clauses_sram_ena),
    .o_Clauses_sram_wea   (w_clauses_sram_wea),
    .o_Clauses_sram_addra (w_clauses_sram_addra),
    .o_Clauses_sram_dina  (w_clauses_sram_dina)
);

assign rst_h = ~i_rst_n;

/////////////////////////////////////////////////////////
// 4) WEIGHT SRAM
/////////////////////////////////////////////////////////
blk_mem_gen_1 u_weight_sram (
    .clka  (i_clk),
    .ena   (w_weight_sram_ena),
    .wea   (w_weight_sram_wea),
    .addra (w_weight_sram_addra),
    .dina  (w_weight_sram_dina),

    .clkb  (i_clk),
    .enb   (1'b1),
    .addrb (bram_addr_a2[10:0]),
    .doutb (w_weight_sram_dout),

    .reset (rst_h)
);


/////////////////////////////////////////////////////////
// 5) CLAUSES SRAM
/////////////////////////////////////////////////////////
blk_mem_gen_0 u_clauses_sram (
    .clka  (i_clk),
    .ena   (w_clauses_sram_ena),
    .wea   (w_clauses_sram_wea),
    .addra (w_clauses_sram_addra),
    .dina  (w_clauses_sram_dina),

    .clkb  (i_clk),
    .enb   (1'b1),
    .addrb (bram_addr_a[10:0]),
    .doutb (w_clauses_sram_dout),

    .reset (rst_h)
);


/////////////////////////////////////////////////////////
// 6) ACCELERATOR
/////////////////////////////////////////////////////////

class_top u_class_top (
    .clk          (i_clk),
    .rst          (rst_h),

    .model_params (w_model_params),

    .tdata        (w_tdata),
    .tvalid       (w_tvalid),
    .tkeep        (w_tkeep),
    .tlast        (w_tlast),
    .tready       (w_tready),

    .clause_write (w_clauses_sram_dout),
    .weight_write (w_weight_sram_dout),

    .output_params(w_acc_result_data),

    .bram_addr_a  (bram_addr_a),
    .bram_addr_a2 (bram_addr_a2)
);


/////////////////////////////////////////////////////////
// 7) RESULT GLUE
/////////////////////////////////////////////////////////
result_glue_logic u_result_glue (
    .i_clk                  (i_clk),
    .i_rst_n                (i_rst_n),

    // From CLASS TOP
    .i_acc_result_data      (w_acc_result_data),

    // From IMAGE GLUE (pulse when full image sent)
    .i_image_valid_pulse    (w_acc_input_done_pulse),

    // To APB
    .o_result_reg_out       (w_result_reg_to_apb)
    
);

endmodule

