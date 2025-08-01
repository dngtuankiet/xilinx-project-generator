`timescale 1ns / 1ps
(*dont_touch = "true"*)
module basic_trng(
input iClk,
input iRst,
input iEntropyEn,
input iEn,
output oRandomBit
);
// Ring oscillator parameters
parameter integer FAST_RO_LENGTH = 5;

// Fast ring oscillator
(*dont_touch = "true"*) wire fast_osc;
ring_oscillator #(.LENGTH(FAST_RO_LENGTH)) fast_ring_osc (
    .iEn(iEntropyEn),
    .oOsc(fast_osc)
);

reg r_sampled_bit;
always @(posedge iClk) begin
    if(iRst) begin
        r_sampled_bit <= 1'b0;
    end else if(iEn) begin
        // Sample the fast ring oscillator output
        r_sampled_bit <= fast_osc;
    end
end

assign oRandomBit = r_sampled_bit;


endmodule