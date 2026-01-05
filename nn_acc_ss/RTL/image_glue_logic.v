module image_glue_logic #(
    parameter WORD_WIDTH      = 32,
    parameter IMG_WORDS       = 32,
    parameter IMG_DATA_WIDTH  = WORD_WIDTH * IMG_WORDS,  // 1024
    parameter STREAM_WIDTH    = 128,
    parameter IMAGE_MODE      = 1
)(
    input  wire                       i_clk,
    input  wire                       i_rst_n,

    // ====================================================
    // Inputs from APB register block (32 x 32-bit words)
    // ====================================================
    input  wire [WORD_WIDTH-1:0]      i_img_data0,
    input  wire [WORD_WIDTH-1:0]      i_img_data1,
    input  wire [WORD_WIDTH-1:0]      i_img_data2,
    input  wire [WORD_WIDTH-1:0]      i_img_data3,
    input  wire [WORD_WIDTH-1:0]      i_img_data4,
    input  wire [WORD_WIDTH-1:0]      i_img_data5,
    input  wire [WORD_WIDTH-1:0]      i_img_data6,
    input  wire [WORD_WIDTH-1:0]      i_img_data7,
    input  wire [WORD_WIDTH-1:0]      i_img_data8,
    input  wire [WORD_WIDTH-1:0]      i_img_data9,
    input  wire [WORD_WIDTH-1:0]      i_img_data10,
    input  wire [WORD_WIDTH-1:0]      i_img_data11,
    input  wire [WORD_WIDTH-1:0]      i_img_data12,
    input  wire [WORD_WIDTH-1:0]      i_img_data13,
    input  wire [WORD_WIDTH-1:0]      i_img_data14,
    input  wire [WORD_WIDTH-1:0]      i_img_data15,
    input  wire [WORD_WIDTH-1:0]      i_img_data16,
    input  wire [WORD_WIDTH-1:0]      i_img_data17,
    input  wire [WORD_WIDTH-1:0]      i_img_data18,
    input  wire [WORD_WIDTH-1:0]      i_img_data19,
    input  wire [WORD_WIDTH-1:0]      i_img_data20,
    input  wire [WORD_WIDTH-1:0]      i_img_data21,
    input  wire [WORD_WIDTH-1:0]      i_img_data22,
    input  wire [WORD_WIDTH-1:0]      i_img_data23,
    input  wire [WORD_WIDTH-1:0]      i_img_data24,
    input  wire [WORD_WIDTH-1:0]      i_img_data25,
    input  wire [WORD_WIDTH-1:0]      i_img_data26,
    input  wire [WORD_WIDTH-1:0]      i_img_data27,
    input  wire [WORD_WIDTH-1:0]      i_img_data28,
    input  wire [WORD_WIDTH-1:0]      i_img_data29,
    input  wire [WORD_WIDTH-1:0]      i_img_data30,
    input  wire [WORD_WIDTH-1:0]      i_img_data31,

    input  wire                       i_img_cmd_pulse,

    // ====================================================
    // MODE 0 output
    // ====================================================
    output reg  [IMG_DATA_WIDTH-1:0]  o_image_data_1024,
    output reg                        o_image_valid_1024,

    // ====================================================
    // AXI-Stream (MODE 1)
    // ====================================================
    input  wire                       i_tready,
    output reg  [STREAM_WIDTH-1:0]    o_tdata,
    output reg                        o_tvalid,
    output reg                        o_tlast,

    output reg                        o_image_done_pulse
);

    // ====================================================
    // Pack image
    // ====================================================
    wire [IMG_DATA_WIDTH-1:0] w_image_1024;

    assign w_image_1024 = {
        i_img_data31,i_img_data30,i_img_data29,i_img_data28,
        i_img_data27,i_img_data26,i_img_data25,i_img_data24,
        i_img_data23,i_img_data22,i_img_data21,i_img_data20,
        i_img_data19,i_img_data18,i_img_data17,i_img_data16,
        i_img_data15,i_img_data14,i_img_data13,i_img_data12,
        i_img_data11,i_img_data10,i_img_data9, i_img_data8,
        i_img_data7, i_img_data6, i_img_data5, i_img_data4,
        i_img_data3, i_img_data2, i_img_data1, i_img_data0
    };

generate

// =======================================================
// MODE 0 — direct 1024-bit push
// =======================================================
if (IMAGE_MODE == 0) begin : GEN_DIRECT

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_image_data_1024  <= '0;
            o_image_valid_1024 <= 1'b0;
            o_image_done_pulse <= 1'b0;
            o_tvalid           <= 1'b0;
            o_tlast            <= 1'b0;
        end else begin
            o_image_valid_1024 <= 1'b0;
            o_image_done_pulse <= 1'b0;

            if (i_img_cmd_pulse) begin
                o_image_data_1024  <= w_image_1024;
                o_image_valid_1024 <= 1'b1;
                o_image_done_pulse <= 1'b1;
            end
        end
    end

end
// =======================================================
// MODE 1 — streaming 8 × 128-bit beats (FIXED)
// =======================================================
else begin : GEN_STREAM

    reg [IMG_DATA_WIDTH-1:0] r_image_buf;
    reg [2:0]                r_chunk;
    reg                      r_busy;

    wire last_beat = (r_chunk == 3'd6);

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            r_image_buf        <= '0;
            r_chunk            <= 3'd0;
            r_busy             <= 1'b0;

            o_tdata            <= '0;
            o_tvalid           <= 1'b0;
            o_tlast            <= 1'b0;
            o_image_done_pulse <= 1'b0;

            o_image_data_1024  <= '0;
            o_image_valid_1024 <= 1'b0;
        end
        else begin
            o_image_done_pulse <= 1'b0;

            // -------------------------------
            // START
            // -------------------------------
            if (i_img_cmd_pulse && !r_busy) begin
                r_image_buf <= w_image_1024;
                r_chunk     <= 3'd0;
                r_busy      <= 1'b1;
                o_tvalid    <= 1'b1;
                o_tlast     <= 1'b0;
            end

            // -------------------------------
            // STREAM
            // -------------------------------
           else if (r_busy) begin
              o_tvalid <= 1'b1;

   		 // TLAST must be asserted on the cycle
    		// where the LAST data beat is transferred
    	      o_tlast <= (last_beat && i_tready);

   	      if (i_tready) begin
      		  if (last_beat) begin
          	  // This transfer completes the image
          		  r_chunk            <= 3'd0;
          		  r_busy             <= 1'b0;
           		 o_image_done_pulse <= 1'b1;
      		  end
        	else begin
          	  r_chunk <= r_chunk + 3'd1;
        	end
    		end
	end

            // -------------------------------
            // IDLE
            // -------------------------------
            else begin
                o_tvalid <= 1'b0;
                o_tlast  <= 1'b0;
            end

            // -------------------------------
            // DATA MUX
            // -------------------------------
            case (r_chunk)
                3'd0: o_tdata <= r_image_buf[127:0];
                3'd1: o_tdata <= r_image_buf[255:128];
                3'd2: o_tdata <= r_image_buf[383:256];
                3'd3: o_tdata <= r_image_buf[511:384];
                3'd4: o_tdata <= r_image_buf[639:512];
                3'd5: o_tdata <= r_image_buf[767:640];
                3'd6: o_tdata <= r_image_buf[895:768];
                3'd7: o_tdata <= r_image_buf[1023:896];
                default: o_tdata <= '0;
            endcase
        end
    end

end
endgenerate

endmodule

