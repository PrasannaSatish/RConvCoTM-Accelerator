module AHB_Master (
    input  wire        Hclk,
    input  wire        Hresetn,
    input  wire        Hreadyout,
    input  wire [1:0]  Hresp,
    input  wire [31:0] Hrdata,

    output reg         Hwrite,
    output reg         Hreadyin,
    output reg [1:0]   Htrans,
    output reg [31:0]  Haddr,
    output reg [31:0]  Hwdata,
    output reg [2:0]   Hsize,
    output reg [2:0]   Hburst
);

    // FSM states
    localparam IDLE = 2'd0,
               ADDR = 2'd1,
               DATA = 2'd2;

    reg [1:0] state, next_state;

    // Example control: 1 = write, 0 = read
    reg rw_sel;

    // -------------------------
    // State register
    // -------------------------
    always @(posedge Hclk or negedge Hresetn) 
    begin
        if (!Hresetn)
            state <= IDLE;
        else
            state <= next_state;
    end

    // -------------------------
    // Next state logic
    // -------------------------
    always @(*) 
    begin
        case (state)
            IDLE: next_state = ADDR;
            ADDR: next_state = (Hreadyout) ? DATA : ADDR;
            DATA: next_state = (Hreadyout) ? IDLE : DATA;
            default: next_state = IDLE;
        endcase
    end

    // -------------------------
    // Output logic
    // -------------------------
    always @(posedge Hclk or negedge Hresetn) 
    begin
        if (!Hresetn) 
        begin
            Hwrite    <= 1'b0;
            Htrans    <= 2'b00;
            Haddr     <= 32'b0;
            Hwdata    <= 32'b0;
            Hreadyin  <= 1'b1;
            Hsize     <= 3'b000;   // byte
            Hburst    <= 3'b000;   // single
            rw_sel    <= 1'b1;     // default write
        end
        else 
        begin
            case (state)

                IDLE: 
                begin
                    Htrans   <= 2'b00;   // IDLE
                    Hreadyin <= 1'b1;
                    rw_sel   <= ~rw_sel; // alternate read/write
                end

                ADDR: 
                begin
                    Htrans   <= 2'b10;   // NONSEQ
                    Hsize    <= 3'b000;
                    Hburst  <= 3'b000;
                    Hreadyin <= 1'b1;

                    if (rw_sel) 
                    begin
                        Hwrite <= 1'b1;
                        Haddr  <= 32'h8000_0001;
                    end
                    else 
                    begin
                        Hwrite <= 1'b0;
                        Haddr  <= 32'h8000_00A2;
                    end
                end

                DATA: 
                begin
                    Htrans <= 2'b00; // IDLE after transfer

                    if (rw_sel) 
                    begin
                        Hwdata <= 32'h0000_00A3;
                    end
                    // read data is available on Hrdata
                end

            endcase
        end
    end

endmodule
