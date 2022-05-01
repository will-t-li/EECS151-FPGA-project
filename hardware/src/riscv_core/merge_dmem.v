module merge_dmem (
    input [3:0] wea,
    input [31:0] din,
    input [31:0] merge,

    output [31:0] dout
);

    wire [7:0] a = wea[0] ? 0 : merge[7:0];
    wire [7:0] b = wea[1] ? 0 : merge[15:8];
    wire [7:0] c = wea[2] ? 0 : merge[23:16];
    wire [7:0] d = wea[3] ? 0 : merge[31:24];
    wire [31:0] mask = {d, c, b, a};
    assign dout = mask | din;

endmodule