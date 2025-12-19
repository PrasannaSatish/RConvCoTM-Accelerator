module APB_Interface (
    input  wire        Pwrite,
    input  wire        Penable,
    input  wire [2:0]  Pselx,
    input  wire [31:0] Paddr,
    input  wire [31:0] Pwdata,

    output wire        Pwriteout,
    output wire        Penableout,
    output wire [2:0]  Pselxout,
    output wire [31:0] Paddrout,
    output wire [31:0] Pwdataout,

    output reg  [31:0] Prdata
);

    // ------------------------------------------------
    // Pass-through APB signals
    // ------------------------------------------------
    assign Pwriteout  = Pwrite;
    assign Penableout = Penable;
    assign Pselxout   = Pselx;
    assign Paddrout   = Paddr;
    assign Pwdataout  = Pwdata;

    // ------------------------------------------------
    // Simple APB read data logic
    // ------------------------------------------------
    always @(*) begin
        if (!Pwrite && Penable && (Pselx != 3'b000))
            Prdata = {24'b0, Paddr[7:0]};  // example readable data
        else
            Prdata = 32'b0;
    end

endmodule
