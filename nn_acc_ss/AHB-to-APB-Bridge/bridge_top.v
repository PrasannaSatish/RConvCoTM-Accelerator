module Bridge_Top (
    input  wire        Hclk,
    input  wire        Hresetn,

    // AHB side
    input  wire        Hwrite,
    input  wire        Hreadyin,
    input  wire [1:0]  Htrans,
    input  wire [31:0] Haddr,
    input  wire [31:0] Hwdata,

    output wire        Hreadyout,
    output wire [1:0]  Hresp,
    output wire [31:0] Hrdata,

    // APB side
    output wire        Pwrite,
    output wire        Penable,
    output wire [2:0]  Pselx,
    output wire [31:0] Paddr,
    output wire [31:0] Pwdata
);

    // ------------------------------------------------
    // Internal wires
    // ------------------------------------------------
    wire        valid;
    wire [31:0] Haddr1, Haddr2;
    wire [31:0] Hwdata1, Hwdata2;
    wire        Hwritereg;
    wire [2:0]  tempselx;
    wire [31:0] Prdata;

    // ------------------------------------------------
    // AHB Slave Interface
    // ------------------------------------------------
    AHB_slave_interface u_ahb_slave (
        .Hclk      (Hclk),
        .Hresetn   (Hresetn),
        .Hwrite    (Hwrite),
        .Hreadyin  (Hreadyin),
        .Htrans    (Htrans),
        .Haddr     (Haddr),
        .Hwdata    (Hwdata),
        .Prdata    (Prdata),
        .valid     (valid),
        .Haddr1    (Haddr1),
        .Haddr2    (Haddr2),
        .Hwdata1   (Hwdata1),
        .Hwdata2   (Hwdata2),
        .Hrdata    (Hrdata),
        .Hwritereg (Hwritereg),
        .tempselx  (tempselx),
        .Hresp     (Hresp)
    );

    // ------------------------------------------------
    // APB FSM Controller
    // ------------------------------------------------
    APB_FSM_Controller u_apb_fsm (
        .Hclk      (Hclk),
        .Hresetn   (Hresetn),
        .valid     (valid),
        .Hwrite    (Hwrite),
        .Hwritereg (Hwritereg),
        .Haddr     (Haddr),
        .Haddr1    (Haddr1),
        .Haddr2    (Haddr2),
        .Hwdata1   (Hwdata1),
        .Hwdata2   (Hwdata2),
        .tempselx  (tempselx),
        .Pwrite    (Pwrite),
        .Penable   (Penable),
        .Pselx     (Pselx),
        .Paddr     (Paddr),
        .Pwdata    (Pwdata),
        .Hreadyout (Hreadyout)
    );

    // ------------------------------------------------
    // APB Peripheral Interface
    // ------------------------------------------------
    APB_Interface u_apb_if (
        .Pwrite    (Pwrite),
        .Penable   (Penable),
        .Pselx     (Pselx),
        .Paddr     (Paddr),
        .Pwdata    (Pwdata),
        .Pwriteout (),
        .Penableout(),
        .Pselxout  (),
        .Paddrout  (),
        .Pwdataout (),
        .Prdata    (Prdata)
    );

endmodule
