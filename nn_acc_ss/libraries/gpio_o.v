module axi_gpio_o (
    // AXI clock & reset 
    input  wire   s_axi_aclk,
    input  wire   s_axi_aresetn,

    // GPIO output 
    output wire [18:0]  gpio_io_o
);

endmodule