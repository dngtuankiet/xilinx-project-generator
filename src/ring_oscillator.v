(* KEEP = "TRUE", DONT_TOUCH = "TRUE" *)
module ring_oscillator #(
    parameter integer LENGTH = 5
) (
    input iEn,
    output oOsc
);
    // Force each stage to use a separate LUT with KEEP and DONT_TOUCH
    (* KEEP = "TRUE", DONT_TOUCH = "TRUE" *) wire [LENGTH-1:0] n;
    genvar i;
    
    // First stage: NAND gate with enable
    (* KEEP = "TRUE", DONT_TOUCH = "TRUE" *) 
    assign n[0] = ~(n[LENGTH-1] & iEn);
    
    generate
        for (i = 1; i < LENGTH; i = i + 1) begin : ring
            (* KEEP = "TRUE", DONT_TOUCH = "TRUE" *) 
            assign n[i] = ~n[i-1];
        end
    endgenerate
    
    assign oOsc = n[LENGTH-1];
endmodule
