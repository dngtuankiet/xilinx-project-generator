module uart_transmit #(
    parameter CLK_FREQ = 50000000,
    parameter BAUD_RATE = 115200,
    parameter BATCH_SIZE = 1000,
    parameter MEM_ADDR_WIDTH = $clog2(BATCH_SIZE)
)(
    input wire clk,
    input wire rst,
    input wire start,

    output reg [MEM_ADDR_WIDTH-1:0] mem_addr,
    input wire [7:0] mem_dout,
    output reg mem_we,
    output reg mem_oe,

    output wire uart_tx,
    output reg tx_done
);

    localparam IDLE = 0, BOOT = 1, LOAD = 2, SEND = 3, DONE = 4;
    reg [2:0] state;
    reg [MEM_ADDR_WIDTH-1:0] addr;
    reg [7:0] tx_byte;

    reg start_uart;
    wire uart_busy;
	 
    reg [2:0] boot_cnt; //sending 4 header bytes

    uart_tx_core #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) uart (
        .clk(clk),
        .rst(rst),
        .tx_start(start_uart),
        .tx_data(tx_byte),
        .tx_line(uart_tx),
        .tx_busy(uart_busy)
    );

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            addr <= 0;
				mem_we <= 0;
				mem_oe <= 0;
            tx_done <= 0;
				tx_byte <= 8'h00;
            start_uart <= 0;
				boot_cnt <= 0;
        end else begin
            case (state)
                IDLE: begin
                    tx_done <= 0;
                    if (start) begin
                        addr <= 0;
								boot_cnt <= 0;
                        state <= BOOT;
                    end
                end
					 
                BOOT: begin
                    if (!uart_busy) begin
                        case (boot_cnt)
                            3'd0: tx_byte <= 8'h52; // 'R'
                            3'd1: tx_byte <= 8'h44; // 'D'
                            3'd2: tx_byte <= 8'h59; // 'Y'
                            3'd3: tx_byte <= 8'h0A; // '\n'
                        endcase
                        start_uart <= 1;
                        boot_cnt <= boot_cnt + 1;
                        if(boot_cnt == 3'd3) begin
                            state <= LOAD;
                            addr <= 0;
                        end else begin
                            state <= BOOT;
                        end
                    end
                end
					 
                LOAD: begin
                    mem_addr <= addr;
                    mem_we <= 0;
                    mem_oe <= 1;
                    state <= SEND;
                end

                SEND: begin
                    if (!uart_busy) begin
                            tx_byte <= mem_dout;
                            start_uart <= 1;
                            addr <= addr + 1;

                        if (addr == (BATCH_SIZE - 1)) begin
                            tx_done <= 1;
                            state <= DONE;
                        end else begin
                            state <= LOAD;
                        end
								
                    end else begin
                        start_uart <= 0;
                    end
                end

                DONE: begin
                    tx_done <= 1;
                        start_uart <= 0;
                        mem_we <= 0;
                        mem_oe <= 0;
                    state <= DONE;
                end
            endcase
        end
    end
endmodule
