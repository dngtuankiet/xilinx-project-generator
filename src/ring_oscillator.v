// Simple Ring Oscillator for Arty-100T

(*dont_touch = "true"*)
module ring_oscillator #(
    parameter integer LENGTH = 5
) (
    input iEn,
    output oOsc,
);
    (*dont_touch = "true"*) wire [LENGTH-1:0] n;
    integer i;
    assign n[0] = ~(n[LENGTH-1] & iEn);
    generate
        for (i = 1; i < LENGTH; i = i + 1) begin : ring
            assign n[i] = ~n[i-1];
        end
    endgenerate
    assign oOsc = n[LENGTH-1];
endmodule
