// ====================================================
// Top Module: PWM controlled via UART
// ====================================================
module top_module(
    input clk,
    input rst_n,
    input rx,
    output tx,
    output pwm_out
);

    wire [7:0] rx_data;
    wire rx_valid;
    wire [7:0] tx_data;
    wire tx_valid;

    // Registers for PWM
    reg [6:0] duty_cycle = 0;
    reg [1:0] pow2 = 0;
    reg [1:0] pow5 = 0;

    // UART RX
    uart_rx u_rx(
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx),
        .data_out(rx_data),
        .data_valid(rx_valid)
    );

    // Command Parser
    command_parser u_parser(
        .clk(clk),
        .rst_n(rst_n),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .duty_cycle(duty_cycle),
        .pow2(pow2),
        .pow5(pow5),
        .tx_data(tx_data),
        .tx_valid(tx_valid)
    );

    // UART TX
    uart_tx u_tx(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(tx_data),
        .send(tx_valid),
        .tx(tx)
    );

    // PWM Generator
    pwm_generator u_pwm(
        .clk(clk),
        .rst_n(rst_n),
        .pow2(pow2),
        .pow5(pow5),
        .duty_cycle(duty_cycle),
        .pwm_out(pwm_out)
    );

endmodule
