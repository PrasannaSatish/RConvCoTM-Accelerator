module nn_acc_ss ();

class_top #(
    .CLAUSEN(140),
    .CLASSN(10),
    .HEIGHT(28),
    .WIDTH(28),
    .CLAUSE_WIDTH((35 + HEIGHT + WIDTH)*2)
) u_class_top (
    .clk            (clk),
    .rst            (rst),

    .model_params   (model_params),     // [18:0]
    .total_img      (total_img),        // [127:0]
    .clause_write   (clause_write),     // [255:0]
    .weight_write   (weight_write),     // [255:0]

    .tvalid         (tvalid),
    .tkeep          (tkeep),            // [15:0]
    .tlast          (tlast),

    .bram_addr_a    (bram_addr_a),      // [31:0]
    .bram_addr_a2   (bram_addr_a2),     // [31:0]
    .tready         (tready),
    .enb            (enb),

    .output_params  (output_params),    // [3:0]
    .web            (web),              // [31:0]
    .dinb           (dinb)              // [255:0]
);

//Clauses RAM

blk_mem_gen_0 #(
    .ADDR_WIDTH(10),
    .DATA_WIDTH(256)
) u_blk_mem (

    // Write Port A 
    .clka      (clka),
    .reset     (reset),
    .ena       (ena),
    .wea       (wea),
    .addra     (addra),
    .dina      (dina),

    // Read Port B 
    .clkb      (clkb),
    .enb       (enb),
    .addrb     (bram_addr_a),
    .doutb     (clause_write)
);


//Weights RAM

blk_mem_gen_1 #(
    .ADDR_WIDTH(10),
    .DATA_WIDTH(256)
) u_blk_mem_1 (
    
    // Write Port A
    .clka      (clka),
    .reset     (reset),
    .ena       (ena),
    .wea       (wea),
    .addra     (addra),
    .dina      (dina),

    // Read Port B
    .clkb      (clkb),
    .enb       (enb),
    .addrb     (bram_addr_a2),
    .doutb     (weight_write)
);


src #(
    .ADDR_WIDTH(32),
    .DATA_WIDTH(32)
) u_src (
    .clk          (clk),
    .rst          (rst),

    .PADDR        (PADDR),        // [ADDR_WIDTH-1:0]
    .PSEL         (PSEL),
    .PENABLE      (PENABLE),
    .PWRITE       (PWRITE),
    .PWDATA       (PWDATA),       // [DATA_WIDTH-1:0]

    .output_params(output_params),// [3:0]

    .PRDATA       (PRDATA),       // [DATA_WIDTH-1:0]
    .PREADY       (PREADY),
    .PSLVERR      (PSLVERR),

    .model_params (model_params), // [18:0]
    .start        (start)
);


dma u_dma (
    .m_tready   (tready),   // input

    .m_tdata    (tdata),    // output [127:0]
    .m_tkeep    (tkeep),    // output [15:0]
    .m_tlast    (tlast),    // output
    .m_tvalid   (tvalid)    // output
);





endmodule
