`include "Opcode.vh"

module imm_gen (
    input [2:0] instr_type,
    input [31:0] instr,
    output [31:0] imm
);
    // immediate generator
    localparam R = 3'd0, I = 3'd1, S = 3'd2, SB = 3'd3, U = 3'd4, UJ = 3'd5, CSR = 3'd6;
    wire [6:0] opcode = instr[6:0];
    reg [31:0] imm_reg;
    assign imm = imm_reg;
    always @(*) begin
        if (opcode == `OPC_LUI) begin
            imm_reg = {instr[31:12], 12'b0};
        end else begin
            case(instr_type)
                R: begin
                    imm_reg = 32'b0;
                end
                I: begin
                    imm_reg = {{20{instr[31]}}, instr[31:20]};
                end
                S: begin
                    imm_reg = {{20{instr[31]}}, instr[31:25], instr[11:7]};
                end
                SB: begin
                    imm_reg = {{20{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
                end
                U: begin
                    imm_reg = {instr[31:12], 12'd0};
                end
                UJ: begin
                    imm_reg = {{12{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
                end
                CSR: begin
                    imm_reg = {{27'b0}, instr[19:15]};
                end
                default: imm_reg = 32'b0;
            endcase
        end
    end
endmodule