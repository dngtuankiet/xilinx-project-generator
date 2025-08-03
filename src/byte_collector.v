module byte_collector #(
    parameter integer BATCH_SIZE = 1000,
    parameter integer MEM_ADDR_WIDTH = $clog2(BATCH_SIZE)
)(
    input wire clk,
    input wire rst,
    input wire start,
    input wire bit_in,
    
    output reg mem_we,
    output reg mem_oe,
    output reg [MEM_ADDR_WIDTH-1:0] mem_addr,
    output reg [7:0] mem_din,
    output reg done
);

    reg [3:0] bit_cnt;
    reg [7:0] shift_reg;
    reg [MEM_ADDR_WIDTH-1:0] byte_addr;
    reg collecting;
	 
    reg r_delay_start;
    always @(posedge clk) begin
        r_delay_start <= start;
    end
    wire w_start_rising = ~r_delay_start && start;
    
    reg r_bit_in_delay_1;
    reg r_bit_in_delay_2;
    
    always @(posedge clk) begin
        r_bit_in_delay_1 <= bit_in;
        r_bit_in_delay_2 <= r_bit_in_delay_1;
    end
	 
    always @(posedge clk) begin
        if (rst) begin
            bit_cnt     <= 0;
            shift_reg   <= 0;
            byte_addr   <= 0;
            mem_we      <= 0;
            mem_oe      <= 0;
            mem_addr    <= 0;
            mem_din     <= 0;
            collecting  <= 0;
            done        <= 0;
        end else begin
            if (w_start_rising && !collecting) begin
                collecting <= 1;
                byte_addr  <= 0;
            end
            mem_oe <= 0;
            mem_we <= 0; // default

            if (collecting && !done) begin
                shift_reg <= {shift_reg[6:0],r_bit_in_delay_2};
                bit_cnt <= bit_cnt + 1;

                if (bit_cnt == 4'd8) begin
                    mem_din <= {shift_reg[6:0],r_bit_in_delay_2};
                    mem_addr <= byte_addr;
                    mem_we <= 1;

                    byte_addr <= byte_addr + 1;
                    bit_cnt <= 1;

                    if (byte_addr == (BATCH_SIZE - 1)) begin
                        collecting <= 0;
                        done <= 1;
                    end
                end
            end
        end
    end
endmodule
