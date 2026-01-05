module blk_mem_gen_0 #(
    parameter ADDR_WIDTH = 11,
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

wire reset_n = ~reset;

blk_sram #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .INIT_FILE("clauses.txt")   // ?? BINARY FILE
) u_sram (
    .clka(clka),
    .reset_n(reset_n),
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

