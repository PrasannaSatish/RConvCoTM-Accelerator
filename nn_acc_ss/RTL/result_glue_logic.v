module result_glue_logic #(
    parameter integer LATENCY_CYCLES = 10000,
    parameter integer COUNTER_WIDTH  = $clog2(LATENCY_CYCLES + 1)
)(
    input  wire                     i_clk,
    input  wire                     i_rst_n,

    // From CLASS TOP
    input  wire [3:0]               i_acc_result_data,

    // Pulse from IMAGE GLUE after FULL 1024b transfer
    input  wire                     i_image_valid_pulse,

    // Output to APB
    output reg  [31:0]              o_result_reg_out
);

    reg [COUNTER_WIDTH-1:0]         r_wait_count;
    reg                             r_waiting;

    // edge detect safety
    reg r_prev_img;
    wire w_img_pulse = (i_image_valid_pulse & ~r_prev_img);

    always @(posedge i_clk or negedge i_rst_n) begin
        if(!i_rst_n) begin
            r_prev_img         <= 1'b0;
            r_waiting          <= 1'b0;
            r_wait_count       <= {COUNTER_WIDTH{1'b0}};
            o_result_reg_out   <= 32'd0;
        end
        else begin
            r_prev_img <= i_image_valid_pulse;

            //------------------------------------------------
            // Start wait window when final image pulse arrives
            //------------------------------------------------
            if(w_img_pulse && !r_waiting) begin
                r_waiting    <= 1'b1;
                r_wait_count <= LATENCY_CYCLES[COUNTER_WIDTH-1:0];
            end

            //------------------------------------------------
            // Wait state
            //------------------------------------------------
            else if(r_waiting) begin
                if(r_wait_count != 0)
                    r_wait_count <= r_wait_count - 1;
                else begin
                    r_waiting        <= 1'b0;
                    o_result_reg_out <= {28'h0, i_acc_result_data};
                end
            end
        end
    end

endmodule

