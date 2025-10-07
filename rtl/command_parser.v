// ====================================================
// Command Parser
// Parses HELP, STATUS, DC, POW2, POW5 commands
// Maintains 32-byte RX buffer
// Sends responses via UART TX
// ====================================================
module command_parser(
    input clk,
    input rst_n,
    input [7:0] rx_data,
    input rx_valid,
    output reg [6:0] duty_cycle,   // 0-99%
    output reg [1:0] pow2,         // 0-3
    output reg [1:0] pow5,         // 0-3
    output reg [7:0] tx_data,
    output reg tx_valid
);

    // ========================
    // Parameters
    // ========================
    parameter BUFFER_SIZE = 32;
    reg [7:0] rx_buffer [0:BUFFER_SIZE-1];
    reg [5:0] buffer_ptr = 0;  // 0-31

    reg end_of_string_flag = 0;

    // ========================
    // Receive bytes into buffer
    // ========================
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            buffer_ptr <= 0;
            end_of_string_flag <= 0;
        end else begin
            if(rx_valid) begin
                if(buffer_ptr < BUFFER_SIZE) begin
                    rx_buffer[buffer_ptr] <= rx_data;
                    buffer_ptr <= buffer_ptr + 1;
                end
                // Detect end of string
                if(rx_data == 8'h0A || rx_data == 8'h0D) begin // LF or CR
                    end_of_string_flag <= 1;
                end
            end
            // Reset pointer on end-of-string
            if(end_of_string_flag) begin
                buffer_ptr <= 0;
            end
        end
    end

    // ========================
    // Command FSM
    // ========================
    typedef enum logic [1:0] {IDLE, PARSE, SEND} state_t;
    state_t state = IDLE;

    reg [7:0] tx_reg;
    reg send_flag;

    integer i;
    reg valid_cmd;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state <= IDLE;
            tx_data <= 8'd0;
            tx_valid <= 0;
            send_flag <= 0;
        end else begin
            case(state)
                IDLE: begin
                    tx_valid <= 0;
                    if(end_of_string_flag) begin
                        state <= PARSE;
                    end
                end
                PARSE: begin
                    valid_cmd = 0;
                    // Convert first chars for comparison
                    if(rx_buffer[0] == "H" && rx_buffer[1] == "E" && rx_buffer[2] == "L" && rx_buffer[3] == "P") begin
                        tx_reg <= "H"; // Placeholder: enviar HELP completo byte a byte
                        valid_cmd = 1;
                    end else if(rx_buffer[0] == "S" && rx_buffer[1] == "T" && rx_buffer[2] == "A" && rx_buffer[3] == "T" && rx_buffer[4] == "U" && rx_buffer[5] == "S") begin
                        tx_reg <= duty_cycle + 8'd48; // ASCII número
                        valid_cmd = 1;
                    end else if(rx_buffer[0] == "D" && rx_buffer[1] == "C") begin
                        // Parse duty cycle
                        if(rx_buffer[2] >= "0" && rx_buffer[2] <= "9") begin
                            duty_cycle <= (rx_buffer[2]-"0")*10 + (rx_buffer[3]-"0");
                            if(duty_cycle <= 99)
                                tx_reg <= "O"; // OK
                            else
                                tx_reg <= "F"; // FAIL
                            valid_cmd = 1;
                        end
                    end else if(rx_buffer[0] == "P" && rx_buffer[1] == "O" && rx_buffer[2] == "W") begin
                        if(rx_buffer[3] == "2") begin
                            if(rx_buffer[4] >= "0" && rx_buffer[4] <= "3") begin
                                pow2 <= rx_buffer[4] - "0";
                                tx_reg <= "O"; // OK
                            end else begin
                                tx_reg <= "F"; // FAIL
                            end
                            valid_cmd = 1;
                        end else if(rx_buffer[3] == "5") begin
                            if(rx_buffer[4] >= "0" && rx_buffer[4] <= "3") begin
                                pow5 <= rx_buffer[4] - "0";
                                tx_reg <= "O"; // OK
                            end else begin
                                tx_reg <= "F"; // FAIL
                            end
                            valid_cmd = 1;
                        end
                    end
                    if(valid_cmd == 0) tx_reg <= "F"; // FAIL unknown
                    state <= SEND;
                end
                SEND: begin
                    tx_data <= tx_reg;
                    tx_valid <= 1;
                    state <= IDLE;
                    end_of_string_flag <= 0; // Clear EOS flag
                end
            endcase
        end
    end

endmodule
