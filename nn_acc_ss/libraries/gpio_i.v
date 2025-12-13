module axi_gpio_i (
    // AXI clock & reset 
    input  wire   s_axi_aclk,
    input  wire   s_axi_aresetn,

    // 4-bit GPIO input port 
    input  wire [3:0]  gpio_io_i
);

endmodule