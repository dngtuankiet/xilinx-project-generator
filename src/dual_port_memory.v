module dual_port_memory #(
    parameter BATCH_SIZE = 1000,
    parameter MEM_ADDR_WIDTH = $clog2(BATCH_SIZE),
    parameter DATA_WIDTH = 8
)(
    // Port A - Write port (for byte_collector)
    input wire clka,
    input wire wea,
    input wire [MEM_ADDR_WIDTH-1:0] addra,
    input wire [DATA_WIDTH-1:0] dina,
    
    // Port B - Read port (for uart_transmit)
    input wire clkb,
    input wire enb,
    input wire [MEM_ADDR_WIDTH-1:0] addrb,
    output reg [DATA_WIDTH-1:0] doutb
);

    // Dual-port memory array
    reg [DATA_WIDTH-1:0] memory [0:BATCH_SIZE-1];
    
    // Port A - Write operation
    always @(posedge clka) begin
        if (wea) begin
            memory[addra] <= dina;
        end
    end
    
    // Port B - Read operation
    always @(posedge clkb) begin
        if (enb) begin
            doutb <= memory[addrb];
        end
    end

endmodule
