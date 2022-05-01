`timescale 1ns/1ns

module synchronizer #(parameter WIDTH = 1) (
    input [WIDTH-1:0] async_signal,
    input clk,
    output [WIDTH-1:0] sync_signal
);

    reg [WIDTH-1:0] ff1 = 0;
    reg [WIDTH-1:0] ff2 = 0;
    assign sync_signal = ff2;
    always @(posedge clk)
        ff1 <= async_signal;
    always @(posedge clk)
        ff2 <= ff1;

endmodule

