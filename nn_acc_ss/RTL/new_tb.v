`timescale 1ns/1ps

module new_tb;

// =========================================================
// CLOCK + RESET
// =========================================================
reg clk_tb;
reg rst_n_tb;

initial begin
    clk_tb = 0;
    forever #5 clk_tb = ~clk_tb;
end

initial begin
    rst_n_tb = 0;
    repeat (50) @(posedge clk_tb);
    rst_n_tb = 1;
    $display("[%0t] Reset released", $time);
end

// =========================================================
// APB SIGNALS
// =========================================================
reg         psel_tb;
reg         penable_tb;
reg         pwrite_tb;
reg  [11:2] paddr_tb;
reg  [31:0] pwdata_tb;
reg  [3:0]  pstrb_tb;

wire [31:0] prdata_tb;
wire        pready_tb;
wire        pslverr_tb;

// =========================================================
// DUT
// =========================================================
accel_subsystem_top DUT (
    .i_clk      (clk_tb),
    .i_rst_n    (rst_n_tb),
    .i_PSEL     (psel_tb),
    .i_PENABLE  (penable_tb),
    .i_PWRITE   (pwrite_tb),
    .i_PADDR    (paddr_tb),
    .i_PWDATA   (pwdata_tb),
    .i_PSTRB    (pstrb_tb),
    .o_PRDATA   (prdata_tb),
    .o_PREADY   (pready_tb),
    .o_PSLVERR  (pslverr_tb)
);

// =========================================================
// DEFAULTS
// =========================================================
initial begin
    psel_tb    = 0;
    penable_tb = 0;
    pwrite_tb  = 0;
    paddr_tb   = 0;
    pwdata_tb  = 0;
    pstrb_tb   = 4'hF;
end

// =========================================================
// CONSTANTS
// =========================================================
localparam integer IMG_BASE_ADDR     = 10;
localparam integer IMG_CMD_ADDR      = 42;
localparam integer RESULT_ADDR       = 43;
localparam integer MODEL_PARAMS_ADDR = 44;

localparam [18:0] MODEL_PARAMS = 19'b1010_010001100_001_101;

// =========================================================
// APB TASKS
// =========================================================
task apb_write_idx(input [9:0] word_index, input [31:0] data);
begin
    @(posedge clk_tb);
    psel_tb    <= 1;
    pwrite_tb  <= 1;
    penable_tb <= 0;
    paddr_tb   <= word_index;
    pwdata_tb  <= data;
    pstrb_tb   <= 4'hF;

    @(posedge clk_tb);
    penable_tb <= 1;
    while (!pready_tb) @(posedge clk_tb);

    @(posedge clk_tb);
    psel_tb    <= 0;
    penable_tb <= 0;
    pwrite_tb  <= 0;
end
endtask

task apb_read_idx(input [9:0] word_index, output [31:0] data);
begin
    @(posedge clk_tb);
    psel_tb    <= 1;
    pwrite_tb  <= 0;
    penable_tb <= 0;
    paddr_tb   <= word_index;

    @(posedge clk_tb);
    penable_tb <= 1;
    while (!pready_tb) @(posedge clk_tb);
    data = prdata_tb;

    @(posedge clk_tb);
    psel_tb    <= 0;
    penable_tb <= 0;
end
endtask

// =========================================================
// IMAGE STORAGE
// =========================================================
reg [127:0] image_mem [0:15];

// =========================================================
// IMAGE FILE READER
// =========================================================
task read_image;
begin
    $display("=== READING IMAGE ===");
    $readmemb("image.txt", image_mem);
    $display("  Line 0: %h", image_mem[0]);
    $display("  Line 1: %h", image_mem[1]);
end
endtask

// =========================================================
// IMAGE LOAD
// =========================================================
task load_image(input integer base_index);
    integer line;
    reg [127:0] line_bits;
begin
    $display("\n=== LOADING IMAGE from line %0d ===", base_index);
    
    // Show what we're about to load
    $display("Image data from file:");
    for(line = 0; line < 8; line = line + 1) begin
        $display("  [%0d] %h", base_index + line, image_mem[base_index + line]);
    end
    
    // Write to APB
    for(line = 0; line < 8; line = line + 1) begin
        line_bits = image_mem[base_index + line];
        apb_write_idx(IMG_BASE_ADDR + (line*4 + 0), line_bits[ 31:  0]);
        apb_write_idx(IMG_BASE_ADDR + (line*4 + 1), line_bits[ 63: 32]);
        apb_write_idx(IMG_BASE_ADDR + (line*4 + 2), line_bits[ 95: 64]);
        apb_write_idx(IMG_BASE_ADDR + (line*4 + 3), line_bits[127: 96]);
    end
    
    // Verify what's in APB registers after writing
    $display("Verification - APB registers after loading:");
    $display("  img_data[0-3]   = %h %h %h %h", 
             DUT.u_apb_regs.o_img_data0, DUT.u_apb_regs.o_img_data1,
             DUT.u_apb_regs.o_img_data2, DUT.u_apb_regs.o_img_data3);
    $display("  img_data[4-7]   = %h %h %h %h", 
             DUT.u_apb_regs.o_img_data4, DUT.u_apb_regs.o_img_data5,
             DUT.u_apb_regs.o_img_data6, DUT.u_apb_regs.o_img_data7);
    $display("  img_data[8-11]  = %h %h %h %h", 
             DUT.u_apb_regs.o_img_data8, DUT.u_apb_regs.o_img_data9,
             DUT.u_apb_regs.o_img_data10, DUT.u_apb_regs.o_img_data11);
    
    $display("Image written to APB registers");
end
endtask

// =========================================================
// RUN INFERENCE - FIXED VERSION!
// =========================================================
task run_inference_and_read(output [31:0] res_out);
    reg [31:0] res;
    reg [3:0] saved_result;
    integer wait_count;
begin
    $display("\n=== TRIGGERING INFERENCE ===");
    apb_write_idx(IMG_CMD_ADDR, 32'h1);
    
    // Wait for AXI streaming
    $display("Waiting for image transfer...");
    wait (DUT.u_image_glue.o_image_done_pulse);
    @(posedge clk_tb);
    $display("[%0t] Image transfer complete", $time);
    
    // Wait for class_top to load
    wait (DUT.u_class_top.img_load_done);
    @(posedge clk_tb);
    $display("[%0t] Image loaded into class_top", $time);
    
    // CRITICAL FIX: Wait for img_done_wire to go LOW first
    $display("Waiting for img_done_wire to clear...");
    wait_count = 0;
    while (DUT.u_class_top.img_done_wire && wait_count < 10000) begin
        @(posedge clk_tb);
        wait_count = wait_count + 1;
    end
    
    if (wait_count >= 10000) begin
        $display("WARNING: img_done_wire stuck high!");
    end else begin
        $display("[%0t] img_done_wire cleared (processing started)", $time);
    end
    
    // NOW wait for processing to complete
    $display("Waiting for processing to complete...");
    wait (DUT.u_class_top.img_done_wire);
    @(posedge clk_tb);
    $display("[%0t] Processing complete!", $time);
    
    // Wait for output_params to update
    repeat (5) @(posedge clk_tb);
    saved_result = DUT.u_class_top.output_params;
    
    $display("[%0t] output_params = %0d", $time, saved_result);
    
    res_out = {28'h0, saved_result};
    $display("=== RESULT: Class %0d ===", saved_result);
    
    repeat (100) @(posedge clk_tb);
end
endtask

// =========================================================
// MAIN
// =========================================================
reg [31:0] result1, result2;

initial begin
    $dumpfile("new_tb.vcd");
    $dumpvars(0, new_tb);

    wait(rst_n_tb);
    repeat (10) @(posedge clk_tb);

    $display("\n=== TESTBENCH START ===\n");

    // Read image file only
    read_image();
    
    // Weights & Clauses are auto-loaded by SRAM modules!
    $display("\n(Weights & Clauses auto-loaded from files by SRAMs)");

    // Program model parameters
    $display("\n=== PROGRAMMING MODEL ===");
    apb_write_idx(MODEL_PARAMS_ADDR, {13'b0, MODEL_PARAMS});
    $display("Params: Classes=%0d Patch=%0d Stride=%0d Clauses=%0d",
             MODEL_PARAMS[18:15], MODEL_PARAMS[2:0],
             MODEL_PARAMS[5:3], MODEL_PARAMS[14:6]);

    // IMAGE 1
    $display("\n====== IMAGE #1 ======");
    load_image(0);
    run_inference_and_read(result1);

    // IMAGE 2
    $display("\n====== IMAGE #2 ======");
    load_image(8);
    run_inference_and_read(result2);

    // Results
    $display("\n========== RESULTS ==========");
    $display("Image #1: Class %0d %s", result1[3:0], (result1[3:0] == 3) ? "?" : "? (expected 3)");
    $display("Image #2: Class %0d %s", result2[3:0], (result2[3:0] == 0) ? "?" : "? (expected 0)");
    $display("============================\n");

    if (result1[3:0] == 3 && result2[3:0] == 0) begin
        $display("*** ALL TESTS PASSED! ***\n");
    end else begin
        $display("*** TESTS FAILED ***\n");
    end

    $display("=== TESTBENCH COMPLETE ===");
    repeat(100) @(posedge clk_tb);
    $finish;
end

initial begin
    #50_000_000;
    $display("\n!!! TIMEOUT !!!");
    $finish;
end

endmodule
