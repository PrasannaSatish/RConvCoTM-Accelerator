`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.10.2025 15:27:29
// Design Name: 
// Module Name: weight_adder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module weight_adder#(
    parameter CLAUSEN = 10
)(  input clk,
    input rst,
    input valid,
    input [255:0]weight_write,
    input [31:0]offset,
    input [$clog2(CLAUSEN):0]clauses,
    input [$clog2(CLAUSEN):0]clause_no,
    output reg [8:0]weight
    );
    reg [1279:0] dout; 
    reg [8:0] w;
    reg [8:0] tcomp;
    always @(posedge clk)begin
        if(rst)dout <= 0;
        else if(valid && offset == 0)dout[255:0] <= weight_write;
        else if(valid && offset == 1)dout[511:256] <= weight_write;
        else if(valid && offset == 2)dout[767:512] <= weight_write;
        else if(valid && offset == 3)dout[1023:768] <= weight_write;
        else if(valid && offset == 4)dout[1279:1024] <= weight_write;
    end
    always @(posedge clk)begin
        w = dout[(clauses - clause_no - 1)*9 +: 9];
            if (w[8]) begin
                tcomp = ~w + 1'b1;
                weight <= -tcomp;  //cng
            end
            else begin
                weight <= w;    //cng
            end
    end
    
endmodule
