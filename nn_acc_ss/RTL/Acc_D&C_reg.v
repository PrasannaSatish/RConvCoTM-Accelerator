module acc_datapath_regs #(
    parameter IN_WIDTH  = 1024,
    parameter OUT_WIDTH = 4
)(
    input  wire                  clk,
    input  wire                  rst_n,

    /* Control register write interface */
    input  wire                  ctrl_wr_en,
    input  wire                  ctrl_start_wr,
    input  wire                  ctrl_stop_wr,

    /* Input data register write interface */
    input  wire                  in_data_wr_en,
    input  wire [IN_WIDTH-1:0]   in_data_wr,

    /* Output capture from accelerator */
    input  wire                  out_data_cap_en,
    input  wire [OUT_WIDTH-1:0]  acc_out_data,

    /* Control register outputs */
    output reg                   start,
    output reg                   stop,

    /* Data register outputs */
    output reg [IN_WIDTH-1:0]    in_data_reg,
    output reg [OUT_WIDTH-1:0]   out_data_reg,

    /* Status outputs */
    output reg                   busy,
    output reg                   done
);

    //========================================================
    // Control Register (START / STOP)
    //========================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start <= 1'b0;
            stop  <= 1'b0;
        end
        else if (ctrl_wr_en) begin
            start <= ctrl_start_wr;
            stop  <= ctrl_stop_wr;
        end
    end

    //========================================================
    // 1024-bit Input Data Register
    //========================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_data_reg <= {IN_WIDTH{1'b0}};
        end
        else if (in_data_wr_en) begin
            in_data_reg <= in_data_wr;
        end
    end

    //========================================================
    // 4-bit Output Data Register
    //========================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_data_reg <= {OUT_WIDTH{1'b0}};
        end
        else if (out_data_cap_en) begin
            out_data_reg <= acc_out_data;
        end
    end

    //========================================================
    // Status Register (BUSY / DONE)
    //========================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy <= 1'b0;
            done <= 1'b0;
        end
        else begin
            if (start)
                busy <= 1'b1;

            if (out_data_cap_en) begin
                busy <= 1'b0;
                done <= 1'b1;
            end

            if (stop) begin
                busy <= 1'b0;
                done <= 1'b0;
            end
        end
    end

endmodule
