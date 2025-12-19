module AHB_slave_interface (
    input  wire        Hclk,
    input  wire        Hresetn,

    // AHB inputs
    input  wire        Hwrite,
    input  wire        Hreadyin,
    input  wire [1:0]  Htrans,
    input  wire [31:0] Haddr,
    input  wire [31:0] Hwdata,

    // Peripheral read data
    input  wire [31:0] Prdata,

    // Outputs
    output reg         valid,
    output reg [31:0]  Haddr1,
    output reg [31:0]  Haddr2,
    output reg [31:0]  Hwdata1,
    output reg [31:0]  Hwdata2,
    output wire [31:0] Hrdata,
    output reg         Hwritereg,
    output reg [2:0]   tempselx,
    output wire [1:0]  Hresp
);

    // ------------------------------------------------
    // Address pipeline
    // ------------------------------------------------
    always @(posedge Hclk) begin
        if (!Hresetn) begin
            Haddr1 <= 32'b0;
            Haddr2 <= 32'b0;
        end else begin
            Haddr1 <= Haddr;
            Haddr2 <= Haddr1;
        end
    end

    // ------------------------------------------------
    // Write data pipeline
    // ------------------------------------------------
    always @(posedge Hclk) begin
        if (!Hresetn) begin
            Hwdata1 <= 32'b0;
            Hwdata2 <= 32'b0;
        end else begin
            Hwdata1 <= Hwdata;
            Hwdata2 <= Hwdata1;
        end
    end

    // ------------------------------------------------
    // Write control pipeline
    // ------------------------------------------------
    always @(posedge Hclk) begin
        if (!Hresetn)
            Hwritereg <= 1'b0;
        else
            Hwritereg <= Hwrite;
    end

    // ------------------------------------------------
    // VALID generation (registered  AHB correct)
    // ------------------------------------------------
    always @(posedge Hclk) begin
        if (!Hresetn)
            valid <= 1'b0;
        else
            valid <= Hreadyin &&
                     (Haddr >= 32'h8000_0000 && Haddr < 32'h8C00_0000) &&
                     (Htrans == 2'b10 || Htrans == 2'b11);
    end

    // ------------------------------------------------
    // Slave select decode
    // ------------------------------------------------
    always @(*) begin
        tempselx = 3'b000;

        if (Haddr >= 32'h8000_0000 && Haddr < 32'h8400_0000)
            tempselx = 3'b001;
        else if (Haddr >= 32'h8400_0000 && Haddr < 32'h8800_0000)
            tempselx = 3'b010;
        else if (Haddr >= 32'h8800_0000 && Haddr < 32'h8C00_0000)
            tempselx = 3'b100;
    end

    // ------------------------------------------------
    // Read data & response
    // ------------------------------------------------
    assign Hrdata = Prdata;   // AHB read data
    assign Hresp  = 2'b00;    // OKAY response

endmodule
