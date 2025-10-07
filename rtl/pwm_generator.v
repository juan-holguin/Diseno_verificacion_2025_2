// ====================================================
// PWM Generator
// Generates a PWM signal with configurable duty cycle
// Frequency is controlled by POW2 and POW5 divisors
// ====================================================
module pwm_generator(
    input clk,             // 50 MHz clock
    input rst_n,           // active-low reset
    input [1:0] pow2,      // 0-3
    input [1:0] pow5,      // 0-3
    input [6:0] duty_cycle, // 0-99%
    output reg pwm_out
);

    // Internal counter
    reg [31:0] counter;
    reg [31:0] pwm_period;
    reg [31:0] compare_value;

    // Calculate PWM period based on POW2 and POW5
    always @(*) begin
        pwm_period = 50000 / ((2 ** pow2) * (5 ** pow5)); // 50 kHz base
        compare_value = (pwm_period * duty_cycle) / 100;
    end

    // PWM counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            counter <= 0;
        else if (counter >= pwm_period - 1)
            counter <= 0;
        else
            counter <= counter + 1;
    end

    // PWM output centered
    always @(posedge clk) begin
        pwm_out <= (counter < compare_value) ? 1'b1 : 1'b0;
    end

endmodule
