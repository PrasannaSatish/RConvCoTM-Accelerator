`timescale 1ns/1ps

module tb_bridge_top;

    reg         Hclk;
    reg         Hresetn;
    reg         Hwrite;
    reg         Hreadyin;
    reg [1:0]   Htrans;
    reg [31:0]  Haddr;
    reg [31:0]  Hwdata;

    wire        Hreadyout;
    wire [1:0]  Hresp;
    wire [31:0] Hrdata;

    wire        Pwrite;
    wire        Penable;
    wire [2:0]  Pselx;
    wire [31:0] Paddr;
    wire [31:0] Pwdata;

    // ----------------------------------------
    // DUT
    // ----------------------------------------
    Bridge_Top dut (
        .Hclk      (Hclk),
        .Hresetn   (Hresetn),
        .Hwrite    (Hwrite),
        .Hreadyin  (Hreadyin),
        .Htrans    (Htrans),
        .Haddr     (Haddr),
        .Hwdata    (Hwdata),
        .Hreadyout (Hreadyout),
        .Hresp     (Hresp),
        .Hrdata    (Hrdata),
        .Pwrite    (Pwrite),
        .Penable   (Penable),
        .Pselx     (Pselx),
        .Paddr     (Paddr),
        .Pwdata    (Pwdata)
    );

    // ----------------------------------------
    // Clock generation
    // ----------------------------------------
    always #5 Hclk = ~Hclk;

    // ----------------------------------------
    // Stimulus
    // ----------------------------------------
    initial begin
        // init
        Hclk     = 0;
        Hresetn  = 0;
        Hwrite   = 0;
        Hreadyin = 1;
        Htrans   = 2'b00;
        Haddr    = 0;
        Hwdata   = 0;

        // reset
        #20;
        Hresetn = 1;

        // -------------------------------
        // AHB WRITE
        // -------------------------------
        @(posedge Hclk);
        Hwrite = 1;
        Htrans = 2'b10;               // NONSEQ
        Haddr  = 32'h8000_0004;
        Hwdata = 32'hDEADBEEF;

        @(posedge Hclk);
        Htrans = 2'b00;               // IDLE

        // -------------------------------
        // AHB READ
        // -------------------------------
        repeat(2) @(posedge Hclk);

        Hwrite = 0;
        Htrans = 2'b10;               // NONSEQ
        Haddr  = 32'h8000_0004;

        @(posedge Hclk);
        Htrans = 2'b00;

        // let it run
        repeat(10) @(posedge Hclk);

        $finish;
    end
    initial begin
    $dumpfile("bridge.vcd");
    $dumpvars(0, tb_bridge_top);
end

endmodule
