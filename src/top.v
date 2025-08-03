module top(
    input  iClk_100MHz,
    input  iRst,
    input  iEnOsc,
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
    parameter integer SLOW_RO_LENGTH = 501;
    ring_oscillator #(.LENGTH(SLOW_RO_LENGTH)) slow_ring_osc (
        .iEn(iEnOsc),
        .oOsc(w_sample_clk)
    );

    //==========================================================================
    // True Random Number Generator
    //==========================================================================
    wire random_bit;
    basic_trng basic_trng_inst (
        .iClk(w_sample_clk),
        .iRst(iRst),
        .iEntropyEn(iEnOsc),
        .iEn(iEn),
        .oRandomBit(random_bit)
    );

    //==========================================================================
    // Collector with Dual-Port Memory
    //==========================================================================
    
    localparam BATCH_SIZE = 32'd1000;
    localparam MEM_ADDR_WIDTH = $clog2(BATCH_SIZE);
    
    // Byte collector signals
    wire        collector_done;
    wire        collector_mem_we;
    wire        collector_mem_oe;
    wire [MEM_ADDR_WIDTH-1:0] collector_mem_addr;
    wire [7:0]  collector_mem_din;
    
    // UART transmit signals
    reg         uart_start;
    wire        uart_done;
    wire        uart_mem_we;
    wire        uart_mem_oe;
    wire [MEM_ADDR_WIDTH-1:0] uart_mem_addr;
    wire [7:0]  uart_mem_dout;
    
    // Dual-port memory instance
    dual_port_memory #(
        .BATCH_SIZE(BATCH_SIZE),
        .MEM_ADDR_WIDTH(MEM_ADDR_WIDTH),
        .DATA_WIDTH(8)
    ) memory_inst (
        // Port A - Write port (for byte_collector)
        .clka(w_sample_clk),
        .wea(collector_mem_we),
        .addra(collector_mem_addr),
        .dina(collector_mem_din),
        
        // Port B - Read port (for uart_transmit)
        .clkb(iClk_100MHz),
        .enb(uart_mem_oe),
        .addrb(uart_mem_addr),
        .doutb(uart_mem_dout)
    );
    
    // Byte collector instance
    byte_collector #(
        .BATCH_SIZE(BATCH_SIZE),
        .MEM_ADDR_WIDTH(MEM_ADDR_WIDTH)
    ) collector_inst (
        .clk(w_sample_clk),
        .rst(iRst),
        .start(iEn),
        .bit_in(random_bit),
        
        .mem_we(collector_mem_we),
        .mem_oe(collector_mem_oe),
        .mem_addr(collector_mem_addr),
        .mem_din(collector_mem_din),
        .done(collector_done)
    );

    //==========================================================================
    // UART Transmitter (runs on stable 100MHz clock)
    //==========================================================================
    
    // Synchronize collector_done to 100MHz domain for UART trigger
    reg [2:0] done_sync;
    reg       prev_done_sync;
    wire      done_edge;
    
    always @(posedge iClk_100MHz) begin
        if (iRst) begin
            done_sync <= 3'b0;
            prev_done_sync <= 1'b0;
            uart_start <= 1'b0;
        end else begin
            done_sync <= {done_sync[1:0], collector_done};
            prev_done_sync <= done_sync[2];
            
            // Generate start pulse for UART when collection is done
            uart_start <= done_sync[2] && !prev_done_sync;
        end
    end
    
    assign done_edge = done_sync[2] && !prev_done_sync;
    
    // UART transmit instance
    uart_transmit #(
        .CLK_FREQ(100000000),  // 100MHz clock frequency
        .BAUD_RATE(115200),
        .BATCH_SIZE(BATCH_SIZE),
        .MEM_ADDR_WIDTH(MEM_ADDR_WIDTH)
    ) uart_inst (
        .clk(iClk_100MHz),
        .rst(iRst),
        .start(uart_start),
        
        .mem_addr(uart_mem_addr),
        .mem_dout(uart_mem_dout),
        .mem_we(uart_mem_we),
        .mem_oe(uart_mem_oe),
        
        .uart_tx(TX_line),
        .tx_done(uart_done)
    );

    //==========================================================================
    // Debug LEDs
    //==========================================================================
    
    // LED[0]: UART transmission active
    // LED[1]: UART transmission finished (stays on after completion)
    // LED[2]: Batch collection complete
    // LED[3]: Clock heartbeat (shows ring oscillator is running)
    
    assign led[0] = !uart_done && uart_start;  // UART active (between start and done)
    assign led[1] = uart_done;                 // UART transmission finished
    assign led[2] = collector_done;            // Collection complete

    // Clock heartbeat generator - shows ring oscillator activity
    reg [31:0] blink_counter = 32'b0;
    reg        blink = 1'b0;

    always @(posedge w_sample_clk) begin
        if (iRst) begin
            blink_counter <= 32'b0;
            blink         <= 1'b0;
        end else begin
            blink_counter <= blink_counter + 1;
            // Adjust counter based on ring oscillator frequency
            // This will blink at different rates depending on RO frequency
            if (blink_counter == 32'd500000) begin // Approximate blink rate
                blink         <= ~blink;
                blink_counter <= 32'b0;
            end
        end
    end
    
    assign led[3] = blink;

endmodule