`timescale 1ns / 1ps

module collector #(
    parameter BATCH_SIZE = 1000
)(
    // Collection interface (w_sample_clk domain)
    input  wire        clk_collect,    // Collection clock (w_sample_clk)
    input  wire        rst,
    input  wire        start,          // Start collection trigger
    input  wire        random_bit,     // Random bit input from TRNG
    output reg         done,           // Collection complete flag
    output reg  [31:0] bytes_collected, // Status: number of bytes collected
    
    // UART read interface (iClk_100MHz domain)
    input  wire        clk_uart,       // UART clock (iClk_100MHz)
    input  wire        read_enable,    // Read enable from UART controller
    input  wire [31:0] read_addr,      // Read address
    output wire [7:0]  read_data       // Read data output
);

    // Dual-port memory: Port A for collection, Port B for UART read
    reg [7:0] memory [0:BATCH_SIZE-1];
    
    // Port B (read port for UART)
    reg [7:0] read_data_reg;
    always @(posedge clk_uart) begin
        if (read_enable && read_addr < BATCH_SIZE) begin
            read_data_reg <= memory[read_addr];
        end
    end
    assign read_data = read_data_reg;
    
    // Collection FSM states
    localparam IDLE       = 2'b00,
               COLLECTING = 2'b01,
               DONE_STATE = 2'b10;
    
    // Collection FSM registers
    reg [1:0]  state;
    reg [2:0]  bit_count;
    reg [7:0]  current_byte;
    reg [31:0] byte_index;
    reg        prev_start;
    
    always @(posedge clk_collect) begin
        if (rst) begin
            // Reset all registers
            state           <= IDLE;
            done            <= 1'b0;
            bytes_collected <= 32'b0;
            bit_count       <= 3'b0;
            current_byte    <= 8'b0;
            byte_index      <= 32'b0;
            prev_start      <= 1'b0;
        end else begin
            prev_start <= start;
            
            case (state)
                IDLE: begin
                    done            <= 1'b0;
                    bytes_collected <= 32'b0;
                    bit_count       <= 3'b0;
                    current_byte    <= 8'b0;
                    byte_index      <= 32'b0;
                    
                    // Detect rising edge of start signal
                    if (start && !prev_start) begin
                        state <= COLLECTING;
                    end
                end
                
                COLLECTING: begin
                    // Collect one bit per clock cycle
                    current_byte <= {current_byte[6:0], random_bit};
                    bit_count    <= bit_count + 1;
                    
                    // When 8 bits collected, store in memory
                    if (bit_count == 3'b111) begin
                        memory[byte_index] <= {current_byte[6:0], random_bit};
                        byte_index         <= byte_index + 1;
                        bytes_collected    <= bytes_collected + 1;
                        bit_count          <= 3'b0;
                        current_byte       <= 8'b0;
                        
                        // Check if batch is complete
                        if (byte_index >= BATCH_SIZE - 1) begin
                            state <= DONE_STATE;
                            done  <= 1'b1;
                        end
                    end
                    
                    // Early exit if start signal deasserted
                    if (!start) begin
                        state <= IDLE;
                    end
                end
                
                DONE_STATE: begin
                    // Collection complete, memory ready for reading
                    done <= 1'b1;
                    
                    // Return to IDLE when start goes low
                    if (!start) begin
                        state <= IDLE;
                    end
                end
                
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
    
endmodule
