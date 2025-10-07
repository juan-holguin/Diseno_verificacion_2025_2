`timescale 1ns/1ps
module tb_pwm_uart;

    reg clk = 0;
    reg rst_n = 0;
    reg rx = 1;

    wire tx;
    wire pwm_out;

    // Instantiate Top Module
    top_module uut (
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx),
        .tx(tx),
        .pwm_out(pwm_out)
    );

    // Clock generation
    always #10 clk = ~clk; // 50 MHz

    initial begin
        rst_n = 0;
        #100;
        rst_n = 1;
        // HELP
send_byte("H");
send_byte("E");
send_byte("L");
send_byte("P");
send_byte("\n");
        // Aquí agregaremos estímulos UART
        
    end

endmodule
