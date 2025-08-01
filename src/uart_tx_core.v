`timescale 1ns / 1ps
module uart_tx_core #(
    parameter CLK_FREQ = 50000000,
    parameter BAUD_RATE = 115200
)(
    input wire clk,
    input wire rst,
    input wire tx_start,
    input wire [7:0] tx_data,
    output reg tx_line,
    output reg tx_busy
);

    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam IDLE = 0, START = 1, DATA = 2, STOP = 3;

    reg [1:0] state = IDLE;
    reg [15:0] clk_cnt = 0;
    reg [2:0] bit_index = 0;
    reg [7:0] data_buf = 8'd0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            tx_line <= 1'b1;
            tx_busy <= 0;
            clk_cnt <= 0;
            bit_index <= 0;
        end else begin
            case (state)
                IDLE: begin
                    tx_line <= 1'b1;
                    tx_busy <= 0;
                    clk_cnt <= 0;
                    bit_index <= 0;

                    if (tx_start) begin
                        data_buf <= tx_data;
                        state <= START;
                        tx_busy <= 1;
                    end
                end

                START: begin
                    tx_line <= 1'b0;
                    if (clk_cnt < CLKS_PER_BIT - 1) begin
                        clk_cnt <= clk_cnt + 1;
                    end else begin
                        clk_cnt <= 0;
                        state <= DATA;
                    end
                end

                DATA: begin
                    tx_line <= data_buf[bit_index];
                    if (clk_cnt < CLKS_PER_BIT - 1) begin
                        clk_cnt <= clk_cnt + 1;
                    end else begin
                        clk_cnt <= 0;
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            bit_index <= 0;
                            state <= STOP;
                        end
                    end
                end

                STOP: begin
                    tx_line <= 1'b1;
                    if (clk_cnt < CLKS_PER_BIT - 1) begin
                        clk_cnt <= clk_cnt + 1;
                    end else begin
                        clk_cnt <= 0;
                        state <= IDLE;
                        tx_busy <= 0;
                    end
                end
            endcase
        end
    end
endmodule