module APB_FSM_Controller (
    input  wire        Hclk,
    input  wire        Hresetn,

    // From AHB slave interface
    input  wire        valid,
    input  wire        Hwrite,
    input  wire        Hwritereg,
    input  wire [31:0] Haddr,
    input  wire [31:0] Haddr1,
    input  wire [31:0] Haddr2,
    input  wire [31:0] Hwdata1,
    input  wire [31:0] Hwdata2,
    input  wire [2:0]  tempselx,

    // APB outputs
    output reg         Pwrite,
    output reg         Penable,
    output reg [2:0]   Pselx,
    output reg [31:0]  Paddr,
    output reg [31:0]  Pwdata,

    // Back to AHB
    output reg         Hreadyout
);

    // ------------------------------------------------
    // FSM state encoding
    // ------------------------------------------------
    localparam ST_IDLE     = 3'b000;
    localparam ST_WWAIT    = 3'b001;
    localparam ST_READ     = 3'b010;
    localparam ST_WRITE    = 3'b011;
    localparam ST_WRITEP   = 3'b100;
    localparam ST_RENABLE  = 3'b101;
    localparam ST_WENABLE  = 3'b110;
    localparam ST_WENABLEP = 3'b111;

    reg [2:0] PRESENT_STATE, NEXT_STATE;

    // ------------------------------------------------
    // Present state logic
    // ------------------------------------------------
    always @(posedge Hclk) begin
        if (!Hresetn)
            PRESENT_STATE <= ST_IDLE;
        else
            PRESENT_STATE <= NEXT_STATE;
    end

    // ------------------------------------------------
    // Next state logic
    // ------------------------------------------------
    always @(*) begin
        case (PRESENT_STATE)

            ST_IDLE:
                if (!valid)
                    NEXT_STATE = ST_IDLE;
                else if (valid && Hwrite)
                    NEXT_STATE = ST_WWAIT;
                else
                    NEXT_STATE = ST_READ;

            ST_WWAIT:
                if (!valid)
                    NEXT_STATE = ST_WRITE;
                else
                    NEXT_STATE = ST_WRITEP;

            ST_READ:
                NEXT_STATE = ST_RENABLE;

            ST_WRITE:
                if (!valid)
                    NEXT_STATE = ST_WENABLE;
                else
                    NEXT_STATE = ST_WENABLEP;

            ST_WRITEP:
                NEXT_STATE = ST_WENABLEP;

            ST_RENABLE:
                if (!valid)
                    NEXT_STATE = ST_IDLE;
                else if (valid && Hwrite)
                    NEXT_STATE = ST_WWAIT;
                else
                    NEXT_STATE = ST_READ;

            ST_WENABLE:
                if (!valid)
                    NEXT_STATE = ST_IDLE;
                else if (valid && Hwrite)
                    NEXT_STATE = ST_WWAIT;
                else
                    NEXT_STATE = ST_READ;

            ST_WENABLEP:
                if (!valid && Hwritereg)
                    NEXT_STATE = ST_WRITE;
                else if (valid && Hwritereg)
                    NEXT_STATE = ST_WRITEP;
                else
                    NEXT_STATE = ST_READ;

            default:
                NEXT_STATE = ST_IDLE;
        endcase
    end

    // ------------------------------------------------
    // Output combinational logic (LATCH-FREE)
    // ------------------------------------------------
    reg        Pwrite_temp, Penable_temp, Hreadyout_temp;
    reg [2:0]  Pselx_temp;
    reg [31:0] Paddr_temp, Pwdata_temp;

    always @(*) begin
        // ---------- DEFAULTS (CRITICAL) ----------
        Paddr_temp     = Paddr;
        Pwdata_temp    = Pwdata;
        Pwrite_temp    = 1'b0;
        Pselx_temp     = 3'b000;
        Penable_temp   = 1'b0;
        Hreadyout_temp = 1'b1;

        case (PRESENT_STATE)

            ST_IDLE: begin
                if (valid && !Hwrite) begin
                    Paddr_temp     = Haddr1;
                    Pwrite_temp    = 1'b0;
                    Pselx_temp     = tempselx;
                    Hreadyout_temp = 1'b0;
                end
                else if (valid && Hwrite) begin
                    Hreadyout_temp = 1'b1;
                end
            end

            ST_WWAIT: begin
                Paddr_temp     = Haddr1;
                Pwdata_temp    = Hwdata1;
                Pwrite_temp    = 1'b1;
                Pselx_temp     = tempselx;
                Hreadyout_temp = 1'b0;
            end

            ST_READ: begin
                Penable_temp   = 1'b1;
                Hreadyout_temp = 1'b1;
            end

            ST_WRITE: begin
                Penable_temp   = 1'b1;
                Hreadyout_temp = 1'b1;
            end

            ST_WRITEP: begin
                Penable_temp   = 1'b1;
                Hreadyout_temp = 1'b1;
            end

            ST_RENABLE: begin
                if (valid && !Hwrite) begin
                    Paddr_temp     = Haddr1;
                    Pwrite_temp    = 1'b0;
                    Pselx_temp     = tempselx;
                    Hreadyout_temp = 1'b0;
                end
                else if (valid && Hwrite) begin
                    Hreadyout_temp = 1'b1;
                end
            end

            ST_WENABLE: begin
                Hreadyout_temp = 1'b1;
            end

            ST_WENABLEP: begin
                Paddr_temp     = Haddr2;
                Pwdata_temp    = Hwdata2;
                Pwrite_temp    = 1'b1;
                Pselx_temp     = tempselx;
                Hreadyout_temp = 1'b0;
            end

        endcase
    end

    // ------------------------------------------------
    // Output registers
    // ------------------------------------------------
    always @(posedge Hclk) begin
        if (!Hresetn) begin
            Paddr     <= 32'b0;
            Pwdata    <= 32'b0;
            Pwrite    <= 1'b0;
            Pselx     <= 3'b000;
            Penable   <= 1'b0;
            Hreadyout <= 1'b1;
        end
        else begin
            Paddr     <= Paddr_temp;
            Pwdata    <= Pwdata_temp;
            Pwrite    <= Pwrite_temp;
            Pselx     <= Pselx_temp;
            Penable   <= Penable_temp;
            Hreadyout <= Hreadyout_temp;
        end
    end

endmodule
