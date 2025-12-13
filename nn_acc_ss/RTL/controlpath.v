

// APB3 Interface (Control Path)

module apb3_if #
(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)
(
    //  clock, reset for control
    input  wire                     clk,
    input  wire                     rst_n,

    // APB3 control path signals
    input  wire [ADDR_WIDTH-1:0]    PADDR,
    input  wire                     PSEL,
    input  wire                     PENABLE,
    input  wire                     PWRITE,
    input  wire [DATA_WIDTH-1:0]    PWDATA,
    output wire [DATA_WIDTH-1:0]    PRDATA,
    output wire                     PREADY,
    output wire                     PSLVERR
);

    

endmodule
