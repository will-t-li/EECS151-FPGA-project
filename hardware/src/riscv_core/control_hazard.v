`include "Opcode.vh"

module control_hazard (
    input clk,
    input rst,
    input [31:0] instr_if,
    input [31:0] instr_ex,
    input [31:0] instr_wb,
    input branch,

    output stall,
    output kill
);
    wire [6:0] opcode_if = instr_if[6:0];
    wire [6:0] opcode_ex = instr_ex[6:0];
    wire [6:0] opcode_wb = instr_wb[6:0];

    wire branch_wb;
    REGISTER_R_CE #(
        .N(1),
        .INIT(0)
    ) branch_reg (
        .q(branch_wb),
        .d(branch),
        .rst(rst),
        .ce(1'b1),
        .clk(clk)
    );

    wire stall_if = opcode_if == `OPC_JAL || opcode_if == `OPC_JALR || opcode_if == `OPC_BRANCH;
    wire stall_ex = opcode_ex == `OPC_JAL || opcode_ex == `OPC_JALR || (opcode_ex == `OPC_BRANCH && branch);
    wire stall_wb = opcode_wb == `OPC_JAL || opcode_wb == `OPC_JALR || (opcode_wb == `OPC_BRANCH && branch_wb);

    assign stall = stall_ex || stall_wb;

    wire prev_stall;
    REGISTER_R_CE #(
        .N(1),
        .INIT(0)
    ) stall_cleanup (
        .q(prev_stall),
        .d(stall),
        .rst(rst),
        .ce(1'b1),
        .clk(clk)
    );

    wire prev_prev_stall;
    REGISTER_R_CE #(
        .N(1),
        .INIT(0)
    ) stall_cleanup2 (
        .q(prev_prev_stall),
        .d(prev_stall),
        .rst(rst),
        .ce(1'b1),
        .clk(clk)
    );

    assign kill = prev_prev_stall && prev_stall; // && stall_wb;
endmodule