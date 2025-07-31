// Simple Ring Oscillator for Arty-100T

(*dont_touch = "true"*)
module ring_oscillator (
    output wire osc_out
);
    (*dont_touch = "true"*) wire [4:0] n;
    assign n[0] = ~n[4];
    assign n[1] = ~n[0];
    assign n[2] = ~n[1];
    assign n[3] = ~n[2];
    assign n[4] = ~n[3];
    assign osc_out = n[4];
endmodule
