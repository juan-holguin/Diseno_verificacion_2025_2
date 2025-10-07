// ====================================================
// UART Transmitter
// 115200 baud, 1 start, 1 stop, no parity
// ====================================================
module uart_tx(
    input clk,
    input rst_n,
    input [7:0] data_in,
    input send,
    output reg tx,
    output reg busy
);

    parameter BAUD_RATE = 115200;
    parameter CLOCK_FREQ = 50_000_000;
    localparam integer BAUD_TICKS = CLOCK_FREQ / BAUD_RATE;

    // TX FSM
    typedef enum logic [1:0] {IDLE, START, DATA, STOP} state_t;
    state_t state = IDLE;

    reg [15:0] baud_counter = 0;
    reg [2:0] bit_index = 0;
    reg [7:0] tx_shift = 0;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            tx <= 1;
            state <= IDLE;
            busy <= 0;
            baud_counter <= 0;
            bit_index <= 0;
            tx_shift <= 0;
        end else begin
            case(state)
                IDLE: begin
                    tx <= 1;
                    busy <= 0;
                    if(send) begin
                        tx_shift <= data_in;
                        state <= START;
                        baud_counter <= BAUD_TICKS - 1;
                        busy <= 1;
                    end
                end
                START: begin
                    tx <= 0;
                    if(baud_counter == 0) begin
                        state <= DATA;
                        bit_index <= 0;
                        baud_counter <= BAUD_TICKS - 1;
                    end else begin
                        baud_counter <= baud_counter - 1;
                    end
                end
                DATA: begin
                    tx <= tx_shift[bit_index];
                    if(baud_counter == 0) begin
                        if(bit_index == 7) begin
                            state <= STOP;
                        end else begin
                            bit_index <= bit_index + 1;
                        end
                        baud_counter <= BAUD_TICKS - 1;
                    end else begin
                        baud_counter <= baud_counter - 1;
                    end
                end
                STOP: begin
                    tx <= 1;
                    if(baud_counter == 0) begin
                        state <= IDLE;
                        busy <= 0;
                    end else begin
                        baud_counter <= baud_counter - 1;
                    end
                end
            endcase
        end
    end

endmodule
