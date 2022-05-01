`include "Opcode.vh"

module data_hazard (
    input [31:0] instr_if,
    input [31:0] instr_ex,
    input [31:0] instr_wb,

    output [1:0] fwd_a,
    output [1:0] fwd_b,
    output fwd_mem_addr,
    output fwd_mem_data,
    output fwd_alu,
    output fwd_store,
    output storetoload
);
    // || FETCH || EXECUTE || WB ||
    // || IF    || EX      || WB ||

    wire [6:0] opcode_ex;
    wire [6:0] opcode_wb;
    wire [4:0] rs1_ex;
    wire [4:0] rs2_ex;
    wire [4:0] rd_ex;
    wire [4:0] rd_wb;

    assign opcode_ex = instr_ex[6:0];
    assign rs1_ex = instr_ex[19:15];
    assign rs2_ex = instr_ex[24:20];
    assign rd_ex = instr_ex[11:7];
    
    assign opcode_wb = instr_wb[6:0];
    // assign rs1_wb = instr_ex[19:15];
    // assign rs2_wb = instr_ex[24:20];
    assign rd_wb = instr_wb[11:7];
    wire fsig1 = (opcode_ex == `OPC_LOAD) && (opcode_wb == `OPC_STORE);
    wire fsig2 = (rs1_ex == rs1_ex);
    assign storetoload = fsig1 && fsig2;

    reg [1:0] fwd_a_reg;
    reg [1:0] fwd_b_reg;
    reg fwd_mem_addr_reg;
    reg fwd_mem_data_reg;
    reg fwd_alu_reg;
    reg fwd_store_reg;

    assign fwd_a = fwd_a_reg;
    assign fwd_b = fwd_b_reg;
    assign fwd_mem_addr = fwd_mem_addr_reg;
    assign fwd_mem_data = fwd_mem_data_reg;
    assign fwd_alu = fwd_alu_reg;
    assign fwd_store = fwd_store_reg;

    // 10000010:	00002517          	auipc	x10,0x2 (wb)
    // 10000014:	71c50513          	addi	x10,x10,1820 # 1000272c <_end+0x172c> (ex)

    // COMMENTS
    // I went for opcodes instead of register matching in the if conditions because matching based on registers had too many overlaps
    // The register version (buggy) is way down below
    // There are special cases for immediates because I didn't want to complicate the ternary too much
    // We don't handle UJ or SB instructions here (yet?).
    always @(*) begin
        if (opcode_wb == `OPC_LOAD && opcode_ex == `OPC_STORE) begin
            // MEM -> MEM
            // [Case 1]
            // lw x1, 0(x2) (wb)
            // sw x3, 0(x1) (ex)
            // [Case 2]
            // lw x1, 0(x2) (wb)
            // sw x1, 0(x3) (ex)
            fwd_a_reg = 0;
            fwd_b_reg = (rs2_ex == rd_wb && rd_wb != 0) ? 2'b10 : 2'b00;
            fwd_mem_addr_reg = rs1_ex == rd_wb && rd_wb != 0; // 0;
            fwd_mem_data_reg = 0; //rs2_ex == rd_wb;  // Case 2 
            fwd_alu_reg = 0;
            fwd_store_reg = 0;
        end
        else if (opcode_wb == `OPC_LOAD && opcode_ex == `OPC_LOAD) begin
            // LOAD/LOAD
            // lw x1, 0(x0) (wb)
            // lw x2, 0(x1) (ex)
            fwd_a_reg = (rs1_ex == rd_wb && rd_wb != 0) ? 2'b10 : 2'b00; 
            fwd_b_reg = 2'b00; 
            fwd_mem_addr_reg = 0;
            fwd_mem_data_reg = 0;
            fwd_alu_reg = 0;
            fwd_store_reg = 0;
        end
        else if (opcode_wb == `OPC_LOAD && (opcode_ex == `OPC_ARI_RTYPE || opcode_ex == `OPC_CSR || opcode_ex == `OPC_BRANCH || opcode_ex == `OPC_JALR)) begin
            // MEM -> ALU
            // lw x1, 0(x3) (wb)
            // add x1, x1, x1 (ex)
            fwd_a_reg = (rs1_ex == rd_wb && rd_wb != 0) ? 2'b10 : 2'b00; 
            fwd_b_reg = (rs2_ex == rd_wb && rd_wb != 0) ? 2'b10 : 2'b00; 
            fwd_mem_addr_reg = 0;
            fwd_mem_data_reg = 0;
            fwd_alu_reg = 0;
            fwd_store_reg = 0;
        end
        else if (opcode_wb == `OPC_LOAD && (opcode_ex == `OPC_ARI_ITYPE || opcode_ex == `OPC_LUI)) begin
            // MEM -> ALU
            // lw x1, 0(x3) (wb)
            // addi x1, x1, 100 (ex)
            fwd_a_reg = (rs1_ex == rd_wb && rd_wb != 0) ? 2'b10 : 2'b00; 
            fwd_b_reg = 0; 
            fwd_mem_addr_reg = 0;
            fwd_mem_data_reg = 0;
            fwd_alu_reg = 0;
            fwd_store_reg = 0;
        end
        else if ((opcode_wb == `OPC_ARI_RTYPE || opcode_wb == `OPC_ARI_ITYPE || opcode_wb == `OPC_LUI || opcode_wb == `OPC_AUIPC || opcode_wb == `OPC_JALR) && opcode_ex == `OPC_STORE) begin
            // ALU -> MEM
            // addi x1, x0, 100 (wb) 
            // sw x1, 0(x1) (ex)

            // addi x2, x2, 170
            // sw x2, 0(x1)

            fwd_a_reg = (rs1_ex == rd_wb && rd_wb != 0) ? 2'b01 : 2'b00;; 
            fwd_b_reg = (rs2_ex == rd_wb && rd_wb != 0) ? 2'b01 : 2'b00; 
            fwd_mem_addr_reg = 0; // rs2_ex == rd_wb;
            fwd_mem_data_reg = 0;
            fwd_alu_reg = 0; //rs1_ex == rd_wb;
            fwd_store_reg = rs2_ex == rd_wb;
        end
        else if ((opcode_wb == `OPC_ARI_RTYPE || opcode_wb == `OPC_ARI_ITYPE || opcode_wb == `OPC_LUI || opcode_wb == `OPC_AUIPC || opcode_wb == `OPC_JALR) && (opcode_ex == `OPC_ARI_RTYPE || opcode_ex == `OPC_CSR || opcode_ex == `OPC_BRANCH || opcode_ex == `OPC_JALR)) begin
            // ALU -> ALU
            // addi x1, x2, 100 (wb) 
            // add x2, x1, x1 (ex)
            fwd_a_reg = (rs1_ex == rd_wb && rd_wb != 0) ? 2'b01 : 2'b00; 
            fwd_b_reg = (rs2_ex == rd_wb && rd_wb != 0) ? 2'b01 : 2'b00; 
            fwd_mem_addr_reg = 0;
            fwd_mem_data_reg = 0;
            fwd_alu_reg = 0;
            fwd_store_reg = 0;
        end
        else if ((opcode_wb == `OPC_ARI_RTYPE || opcode_wb == `OPC_ARI_ITYPE || opcode_wb == `OPC_CSR || opcode_wb == `OPC_LUI || opcode_wb == `OPC_AUIPC) && (opcode_ex == `OPC_ARI_ITYPE || opcode_ex == `OPC_LUI)) begin
            // ALU -> ALU
            // addi x1, x2, 100 (wb) 
            // addi x2, x1, 100 (ex)
            fwd_a_reg = (rs1_ex == rd_wb && rd_wb != 0) ? 2'b01 : 2'b00; 
            fwd_b_reg = 0; 
            fwd_mem_addr_reg = 0;
            fwd_mem_data_reg = 0;
            fwd_alu_reg = 0;
            fwd_store_reg = 0;
        end
        else if ((opcode_wb == `OPC_ARI_RTYPE || opcode_wb == `OPC_ARI_ITYPE || opcode_wb == `OPC_CSR || opcode_wb == `OPC_LUI || opcode_wb == `OPC_AUIPC || opcode_ex == `OPC_JALR) && opcode_ex == `OPC_LOAD) begin
            fwd_a_reg = (rs1_ex == rd_wb && rd_wb != 0) ? 2'b01 : 2'b00; 
            fwd_b_reg = 0; 
            fwd_mem_addr_reg = 0;
            fwd_mem_data_reg = 0;
            fwd_alu_reg = 0;
            fwd_store_reg = 0;
        end
        else if (opcode_wb == `OPC_JAL) begin
            // UJ type JAL
            fwd_a_reg = 1;
            fwd_b_reg = 1; 
            fwd_mem_addr_reg = 0;
            fwd_mem_data_reg = 0;
            fwd_alu_reg = 0;
            fwd_store_reg = 0;
        end
        else begin
            fwd_a_reg = 0; 
            fwd_b_reg = 0; 
            fwd_mem_addr_reg = 0;
            fwd_mem_data_reg = 0;
            fwd_alu_reg = 0;
            fwd_store_reg = 0;
        end
    end
    






    ///// CUTOFF ///////
    /*
    // rd_ex == rd_wb
    if (rs1_ex == wb_rd) begin
        if (opcode_wb == `OPC_LOAD && opcode_ex == `OPC_STORE) begin
            // MEM -> MEM
            // lw x1, 0(x2) (wb)
            // sw x3, 0(x1) (ex)
            assign fwd_a = 0;
            assign fwd_mem_addr = 0;
            assign fwd_mem_data = 1;
        end
        else if (opcode_ex == `OPC_STORE) begin
            // ALU -> MEM
            // addi x1, x2, 100 (wb)
            // sw x1, 0(x2) (ex)
            assign fwd_a = 0;
            assign fwd_mem_addr = 1;
            assign fwd_mem_data = 0;
        end
        else if (opcode_wb == `OPC_LOAD && (opcode_ex == `OPC_ARI_RTYPE || opcode_ex == `OPC_ARI_ITYPE)) begin
            // MEM -> ALU
            // lw x1, 0(x3) (wb)
            // addi x1, x1, 100 (ex)
            assign fwd_a = 2'b10; // 2
            assign fwd_mem_addr = 0;
            assign fwd_mem_data = 0;
        end
        else if (opcode_wb == `OPC_ARI_RTYPE || opcode_wb == `OPC_ARI_ITYPE) begin
            // ALU -> ALU
            // addi x1, x2, 100 (wb) 
            // addi x2, x1, 100 (ex)
            assign fwd_a = 2'b01;
            assign fwd_mem_addr = 0;
            assign fwd_mem_data = 0;
        end else begin
            assign fwd_a = 0;
        end
    end

    if (rs2_ex == rd_wb) begin
        if (opcode_wb == `OPC_LOAD && opcode_ex == `OPC_STORE) begin
            // MEM -> MEM (actually MEM -> ALU)
            // lw x1, 0(x2) (wb)
            // sw x1, 4(x1) (ex)
            assign fwd_b = 2'b10; // 2
            assign fwd_mem_data = 1;
        end
        else if (opcode_wb == `OPC_LOAD && (opcode_ex == `OPC_ARI_RTYPE || opcode_ex == `OPC_ARI_ITYPE)) begin
            // MEM -> ALU
            // lw x1, 0(x3) (wb)
            // addi x1, x1, x1 (ex)
            assign fwd_b = 2'b10; // 2
            assign fwd_mem_data = 0;
        end
        else if (opcode_wb == `OPC_ARI_RTYPE || opcode_wb == `OPC_ARI_ITYPE) begin
            // ALU -> ALU
            // addi x1, x2, 100 (wb) 
            // add x2, x0, x1 (ex)
            assign fwd_b = 2'b01;
            assign fwd_mem_data = 0;
        end 
        else begin
            assign fwd_b = 0;
        end
    end

    if (rd_ex == rd_wb) begin
        else if (opcode_ex == `OPC_STORE) begin
            // ALU -> MEM
            // addi x1, x2, 100 (wb)
            // sw x1, 0(x1) (ex)
            assign fwd_mem_addr = 0;
            assign fwd_mem_data = 1;
        end
        else begin
            assign fwd_mem_addr = 0;
            assign fwd_mem_data = 0;
        end
    end
    */
endmodule