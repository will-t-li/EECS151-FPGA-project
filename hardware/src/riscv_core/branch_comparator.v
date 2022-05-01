`include "Opcode.vh"

module branch_comparator (
    input [31:0] rs1,
    input [31:0] rs2,
    input [2:0] funct3,
    
    output branch
);
    reg branch_reg;
    assign branch = branch_reg;
    always @(*) begin
        case (funct3)
            `FNC_BEQ: branch_reg = rs1 == rs2;
            `FNC_BNE: branch_reg = rs1 != rs2;
            `FNC_BLT: branch_reg = $signed(rs1) < $signed(rs2);
            `FNC_BGE: branch_reg = $signed(rs1) >= $signed(rs2);
            `FNC_BLTU: branch_reg = rs1 < rs2;
            `FNC_BGEU: branch_reg = rs1 >= rs2;
            default: branch_reg = 0;
        endcase
    end
endmodule