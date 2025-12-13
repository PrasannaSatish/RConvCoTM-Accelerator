module blk_sram #(
	parameter ADDR_WIDTH = 10,
	parameter DATA_WIDTH = 256
	)(
	input clka,
	input reset,
	input ena,
	input wea,
	input [ADDR_WIDTH-1:0] addra,
	input [DATA_WIDTH-1:0] dina,
	
	input clkb,
	input enb,
	input [ADDR_WIDTH-1:0] addrb,
	output reg [DATA_WIDTH-1:0] doutb
	);
	
	
	reg [DATA_WIDTH - 1:0] mem [0:(1<<ADDR_WIDTH)-1];
	
	//write port A
	
	integer i;
	
	always@(posedge clka) 
	begin
	if(reset) begin
		for(i = 0; i < (1<<ADDR_WIDTH); i = i+1)
		  mem[i] <= 0;
	end
	else if(ena && wea)
		 mem[addra] <= dina;
	end

	
	//Read port B
	
	always@(posedge clkb)
	begin
	if(enb)
		doutb <= mem[addrb];
	end
		
endmodule
		 
		
	
	
	
