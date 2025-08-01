`timescale 1ns / 1ps
module top(
    input  iClk_100MHz,
    input  iRst,
    input  iEntropyEn,
    input  iEn,
    output TX_line,
    output [3:0] led
);

    //==========================================================================
    // Clock Generation
    //==========================================================================
    (*dont_touch = "true"*) wire w_sample_clk;
    // clk_wiz_0 clk_wiz_inst (
    //     .clk_in1(iClk_100MHz),
    //     .clk_out1(w_sample_clk)
    // );

    // Slow ring oscillator
    parameter integer SLOW_RO_LENGTH = 91;
    ring_oscillator #(.LENGTH(SLOW_RO_LENGTH)) slow_ring_osc (
        .iEn(iEn),
        .oOsc(w_sample_clk)
    );

    //==========================================================================
    // True Random Number Generator
    //==========================================================================
    wire random_bit;
    basic_trng basic_trng_inst (
        .iClk(w_sample_clk),
        .iRst(iRst),
        .iEntropyEn(iEntropyEn),
        .iEn(iEn),
        .oRandomBit(random_bit)
    );

    //==========================================================================
    // Collector with Dual-Port Memory
    //==========================================================================
    
    localparam BATCH_SIZE = 32'd1000;
    
    wire        collector_done;
    wire [31:0] collector_bytes_collected;
    wire [7:0]  memory_read_data;
    reg         memory_read_enable;
    reg  [31:0] memory_read_addr;
    
    collector #(
        .BATCH_SIZE(BATCH_SIZE)
    ) collector_inst (
        .clk_collect(w_sample_clk),      // Collection clock
        .rst(iRst),
        .start(iEn),
        .random_bit(random_bit),
        .done(collector_done),
        .bytes_collected(collector_bytes_collected),
        
        .clk_uart(iClk_100MHz),          // UART read clock
        .read_enable(memory_read_enable),
        .read_addr(memory_read_addr),
        .read_data(memory_read_data)
    );

    //==========================================================================
    // UART Transmitter (runs on stable 100MHz clock)
    //==========================================================================
    reg         uart_tx_start;
    wire        uart_tx_busy;
    
    uart_tx_core #(
        .CLK_FREQ(100000000),  // 100MHz clock frequency
        .BAUD_RATE(115200)
    ) uart_tx (
        .clk(iClk_100MHz),     // Use stable 100MHz clock
        .rst(iRst),
        .tx_start(uart_tx_start),
        .tx_data(memory_read_data), // Read directly from dual-port memory
        .tx_line(TX_line),
        .tx_busy(uart_tx_busy)
    );

    //==========================================================================
    // UART Controller (runs on 100MHz clock)
    //==========================================================================
    
    // Synchronize collector_done to 100MHz domain
    reg [2:0] done_sync;
    reg       prev_done_sync;
    wire      done_edge;
    
    always @(posedge iClk_100MHz) begin
        if (iRst) begin
            done_sync <= 3'b0;
            prev_done_sync <= 1'b0;
        end else begin
            done_sync <= {done_sync[1:0], collector_done};
            prev_done_sync <= done_sync[2];
        end
    end
    
    assign done_edge = done_sync[2] && !prev_done_sync;
    
    // UART transmission FSM
    localparam UART_IDLE = 2'b00,
               UART_READ = 2'b01,
               UART_SEND = 2'b10,
               UART_WAIT = 2'b11;
    
    reg [1:0]  uart_state;
    reg [31:0] tx_addr;
    reg [31:0] bytes_to_send;
    
    always @(posedge iClk_100MHz) begin
        if (iRst) begin
            uart_state       <= UART_IDLE;
            uart_tx_start    <= 1'b0;
            memory_read_enable <= 1'b0;
            memory_read_addr <= 32'b0;
            tx_addr          <= 32'b0;
            bytes_to_send    <= 32'b0;
        end else begin
            uart_tx_start    <= 1'b0;
            memory_read_enable <= 1'b0;
            
            case (uart_state)
                UART_IDLE: begin
                    tx_addr <= 32'b0;
                    
                    // Start transmission when collection is done
                    if (done_edge) begin
                        bytes_to_send <= BATCH_SIZE;
                        uart_state    <= UART_READ;
                    end
                end
                
                UART_READ: begin
                    // Read from memory
                    memory_read_addr   <= tx_addr;
                    memory_read_enable <= 1'b1;
                    uart_state         <= UART_SEND;
                end
                
                UART_SEND: begin
                    // Start UART transmission (data is already available)
                    uart_tx_start <= 1'b1;
                    uart_state    <= UART_WAIT;
                end
                
                UART_WAIT: begin
                    // Wait for UART transmission to complete
                    if (!uart_tx_busy) begin
                        tx_addr <= tx_addr + 1;
                        
                        if (tx_addr >= bytes_to_send - 1) begin
                            uart_state <= UART_IDLE; // All bytes sent
                        end else begin
                            uart_state <= UART_READ; // Send next byte
                        end
                    end
                end
                
                default: begin
                    uart_state <= UART_IDLE;
                end
            endcase
        end
    end

    //==========================================================================
    // Debug LEDs
    //==========================================================================
    
    // LED[0]: UART transmission active
    // LED[1]: UART transmission finished (stays on after completion)
    // LED[2]: Batch collection complete
    // LED[3]: Clock heartbeat (shows ring oscillator is running)
    
    // Track UART transmission completion
    reg uart_tx_finished;
    
    always @(posedge iClk_100MHz) begin
        if (iRst) begin
            uart_tx_finished <= 1'b0;
        end else begin
            // Set when UART finishes sending all bytes
            if (uart_state == UART_WAIT && !uart_tx_busy && tx_addr >= bytes_to_send - 1) begin
                uart_tx_finished <= 1'b1;
            end
            // Clear when new collection starts
            if (done_edge) begin
                uart_tx_finished <= 1'b0;
            end
        end
    end
    
    // Synchronize UART busy to sample clock domain for LED consistency
    reg [2:0] uart_busy_sync;
    always @(posedge w_sample_clk) begin
        if (iRst) begin
            uart_busy_sync <= 3'b0;
        end else begin
            uart_busy_sync <= {uart_busy_sync[1:0], uart_tx_busy};
        end
    end
    
    assign led[0] = uart_busy_sync[2] || (uart_state != UART_IDLE);
    assign led[1] = uart_tx_finished;  // LED on when UART transmission is finished
    assign led[2] = collector_done;

    // Clock heartbeat generator - shows ring oscillator activity
    reg [23:0] blink_counter = 24'b0;
    reg        blink = 1'b0;

    always @(posedge w_sample_clk) begin
        if (iRst) begin
            blink_counter <= 24'b0;
            blink         <= 1'b0;
        end else begin
            blink_counter <= blink_counter + 1;
            // Adjust counter based on ring oscillator frequency
            // This will blink at different rates depending on RO frequency
            if (blink_counter == 24'd50000) begin // Approximate blink rate
                blink         <= ~blink;
                blink_counter <= 24'b0;
            end
        end
    end
    
    assign led[3] = blink;

endmodule