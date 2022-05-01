module reg_file (
    input clk,
    input we,
    input [4:0] addrA, addrB, addrD,
    input [31:0] dataD,
    output [31:0] dataA, dataB
);

    wire [31:0] d0, q1, q2;
    assign d0 = (addrD == 0) ? 0 : dataD;
    assign dataA = (addrA == 0) ? 0 : q1;
    assign dataB = (addrB == 0) ? 0 : q2;

    ASYNC_RAM_1W2R #(
        .DWIDTH(32),
        .AWIDTH(5),
        .DEPTH(0)
    ) ASYNC_RAM_1W2R (
        .clk(clk),
        .d0(d0),
        .addr0(addrD),
        .we0(we),
        .addr1(addrA),
        .q1(q1),
        .addr2(addrB),
        .q2(q2)
    );

    
endmodule