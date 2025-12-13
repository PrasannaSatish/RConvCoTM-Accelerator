module blk_mem_gen_1 #(
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
    output [DATA_WIDTH-1:0] doutb
);

    blk_sram #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_sram (
        .clka(clka),
        .reset(reset),
        .ena(ena),
        .wea(wea),
        .addra(addra),
        .dina(dina),

        .clkb(clkb),
        .enb(enb),
        .addrb(addrb),
        .doutb(doutb)
    );

endmodule
