
// AXI-Stream Interface Skeleton (Data Path Only)

module axis_if #
(
    parameter DATA_WIDTH = 128
)
(
    input  wire  clk,
    input  wire  rst_n,


	input m_tready
	output [DATA_WIDTH:0] m_tdata,
	output [15:0] m_tkeep,
	output m_tlast,
	output m_tvalid 
);


  

endmodule