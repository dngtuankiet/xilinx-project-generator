(*dont_touch = "true"*)
module ring_oscillator_explicit #(
    parameter integer LENGTH = 5
) (
    input iEn,
    output oOsc
);
    (* KEEP = "TRUE", DONT_TOUCH = "TRUE" *) wire [LENGTH-1:0] n;
    genvar i;
    
    // First stage: explicit LUT1 for NAND with enable
    LUT2 #(.INIT(4'b0111)) nand_lut (
        .O(n[0]),
        .I0(n[LENGTH-1]),
        .I1(iEn)
    );
    
    generate
        for (i = 1; i < LENGTH; i = i + 1) begin : ring
            (* KEEP = "TRUE", DONT_TOUCH = "TRUE" *)
            LUT1 #(.INIT(2'b01)) inv_lut (
                .O(n[i]),
                .I0(n[i-1])
            );
        end
    endgenerate
    
    assign oOsc = n[LENGTH-1];
endmodule
