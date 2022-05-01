module mux #(
    parameter N = 2,
    parameter WIDTH = 32
) (
    input [$clog2(N)-1:0] select,
    input [WIDTH-1:0] in0, 
    input [WIDTH-1:0] in1, 
    input [WIDTH-1:0] in2,
    input [WIDTH-1:0] in3,
    input [WIDTH-1:0] in4, 
    input [WIDTH-1:0] in5, 
    input [WIDTH-1:0] in6,
    input [WIDTH-1:0] in7,
    output [WIDTH-1:0] out
    );
    // Multi-input multiplexer
    reg [WIDTH-1:0] out_reg;
    assign out = out_reg;
    
    always @(*) begin
        case(select)
            'd0: out_reg = in0;
            'd1: out_reg = in1;
            'd2: out_reg = in2;
            'd3: out_reg = in3;
            'd4: out_reg = in4;
            'd5: out_reg = in5;
            'd6: out_reg = in6;
            'd7: out_reg = in7;
        endcase
    end
endmodule