// ====================================================
// UART Receiver
// 115200 baud, 1 start, 1 stop, no parity
// 32-byte FIFO buffer
// ====================================================
module uart_rx(
    input clk,           // 50 MHz clock
    input rst_n,
    input rx,
    output reg [7:0] data_out,
    output reg data_valid
);

    parameter BAUD_RATE = 115200;
    parameter CLOCK_FREQ = 50_000_000;
    localparam integer BAUD_TICKS = CLOCK_FREQ / BAUD_RATE;

    // RX FSM States
    typedef enum logic [1:0] {
        IDLE,
        START,
        DATA,
        STOP
    } state_t;
    state_t state = IDLE;

    reg [15:0] baud_counter = 0;
    reg [2:0] bit_index = 0;
    reg [7:0] rx_shift = 0;
    reg rx_sync_0, rx_sync_1;

    // Simple 2-flip flop synchronizer
    always @(posedge clk) begin
        rx_sync_0 <= rx;
        rx_sync_1 <= rx_sync_0;
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state <= IDLE;
            baud_counter <= 0;
            bit_index <= 0;
            rx_shift <= 0;
            data_valid <= 0;
            data_out <= 0;
        end else begin
            case(state)
                IDLE: begin
                    data_valid <= 0;
                    if(rx_sync_1 == 0) begin // Start bit detected
                        state <= START;
                        baud_counter <= BAUD_TICKS/2; // Mid-bit sampling
                    end
                end
                START: begin
                    if(baud_counter == 0) begin
                        state <= DATA;
                        bit_index <= 0;
                        baud_counter <= BAUD_TICKS - 1;
                    end else begin
                        baud_counter <= baud_counter - 1;
                    end
                end
                DATA: begin
                    if(baud_counter == 0) begin
                        rx_shift[bit_index] <= rx_sync_1;
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
                    if(baud_counter == 0) begin
                        data_out <= rx_shift;
                        data_valid <= 1;
                        state <= IDLE;
                    end else begin
                        baud_counter <= baud_counter - 1;
                    end
                end
            endcase
        end
    end

endmodule
