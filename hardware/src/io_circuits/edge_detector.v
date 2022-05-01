`timescale 1ns/1ns

module edge_detector #(
    parameter WIDTH = 1
)(
    input clk,
    input [WIDTH-1:0] signal_in,
    output [WIDTH-1:0] edge_detect_pulse
);
    // TODO: implement a multi-bit edge detector that detects a rising edge of 'signal_in[x]'
    // and outputs a one-cycle pulse 'edge_detect_pulse[x]' at the next clock edge
    // Feel free to use as many number of registers you like

    // Remove this line once you create your edge detector
    reg [WIDTH-1:0] next_state = 0;
    reg [WIDTH-1:0] prev_state = 0;
    reg [WIDTH-1:0] out = 0;

    always @(posedge clk) begin
        next_state <= signal_in;
        out <= (next_state & ~prev_state);
        prev_state <= next_state;
    end
    assign edge_detect_pulse = out;
endmodule
