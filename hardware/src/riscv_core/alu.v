`include "Opcode.vh"

`define FNC7_0  7'b0000000 // ADD, SRL
`define FNC7_1  7'b0100000 // SUB, SRA
`define OPC_CSR 7'b1110011

module alu (
    input [31:0] a,
    input [31:0] b,
    input [31:0] instr,

    output [31:0] result
);
    wire [6:0] opcode = instr[6:0];
    wire [2:0] fnc = instr[14:12];
    wire [6:0] fnc7 = instr[31:25];

    wire fnc2 = instr[30];
    reg [31:0] result_reg;
    assign result = (result_reg);
    always @(*) begin
        if (opcode == `OPC_LOAD || opcode == `OPC_STORE || opcode == `OPC_JALR) begin
            result_reg = $signed(a) + $signed(b);
        end else if (opcode == `OPC_LUI) begin
            result_reg = b;
        end else if (opcode == `OPC_AUIPC) begin
            result_reg = a + b;
        end else if (opcode == `OPC_CSR) begin
            result_reg = a + b;
        end else begin
            case (fnc)
                `FNC_ADD_SUB: begin
                    if (opcode == `OPC_ARI_ITYPE || fnc2 == `FNC2_ADD) begin
                        result_reg = $signed(a) + $signed(b);
                    end else begin
                        result_reg = $signed(a) - $signed(b);
                    end
                end
                `FNC_SLL: result_reg = (a) << b[4:0];
                `FNC_SLT: result_reg = ($signed(a) < $signed(b)) ? 1 : 0;
                `FNC_SLTU: result_reg = (a < b) ? 1 : 0;
                `FNC_XOR: result_reg = a ^ b;
                `FNC_OR: result_reg = a | b;
                `FNC_AND: result_reg = a & b;
                `FNC_SRL_SRA: begin
                    if (fnc7 == `FNC7_1) begin
                        result_reg = $signed(a) >>> b[4:0];
                    end else result_reg = a >> b[4:0];
                end
                //`FNC_SRL_SRA: result_reg = $signed(a) >>> b[4:0];
                default: result_reg = 0;
            endcase
        end
    end

endmodule