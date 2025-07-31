(*dont_touch = "true"*)
module basic_trng(
input iRst,
input iEntropyEn,
input iEn,
output oRandomBit
);
// Ring oscillator parameters
parameter integer FAST_RO_LENGTH = 5;
parameter integer SLOW_RO_LENGTH = 20;

// Fast ring oscillator
(*dont_touch = "true"*) wire fast_osc;
ring_oscillator #(.LENGTH(FAST_RO_LENGTH)) fast_ring_osc (
    .iEn(iEntropyEn),
    .oOsc(fast_osc)
);

// Slow ring oscillator
(*dont_touch = "true"*) wire slow_osc;
ring_oscillator #(.LENGTH(SLOW_RO_LENGTH)) slow_ring_osc (
    .iEn(iEn),
    .oOsc(slow_osc)
);

reg r_sampled_bit;
always @(posedge slow_osc) begin
    if(~iRst) begin
        r_sampled_bit <= 1'b0;
    end else if(iEn) begin
        // Sample the fast ring oscillator output
        r_sampled_bit <= fast_osc;
    end
end

assign oRandomBit = r_sampled_bit;


endmodule