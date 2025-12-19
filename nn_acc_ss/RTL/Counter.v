
module counter(
    input  wire        clk,
    input  wire        rst_n,

    /* Control */
    input  wire        cnt_enable,     // FSM enables counting
    input  wire        cnt_clear,      // FSM clears counter

    /* Handshake */
    input  wire        valid,
    input  wire        ready,

    /* Outputs */
    output reg  [4:0]  cnt,            // 0 to 31
    output wire        cnt_done         // asserted at 31
);

    //========================================================
    // Counter logic
    //========================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 5'd0;
        end
        else if (cnt_clear) begin
            cnt <= 5'd0;
        end
        else if (cnt_enable && valid && ready) begin
            if (cnt != 5'd31)
                cnt <= cnt + 5'd1;
        end
    end

    //========================================================
    // Done flag
    //========================================================
    assign cnt_done = (cnt == 5'd31);

endmodule
