`include "Opcode.vh"

module control_logic (
    input clk,
    input rst,
    input [31:0] pc,
    input [31:0] instr_if,
    input [31:0] instr_ex,
    input [31:0] instr_wb,
    input branch,
    input [31:0] alu,
    input uart_control,
    input uart_rec,
    input uart_tran,
    input cycle_ctr,
    input instr_ctr,
    input reset_ctr,

    // General control signals

    /* Intruction fetch signals */
    output pc_sel,
    output stall,
    output jump,
    output kill,
    output [2:0] instr_type_if,
    output [1:0] instr_sel,
    output [31:0] pc_next,

    /* Execute signals */
    output a_sel,
    output b_sel,
    output imm_sel,
    output [2:0] instr_type_ex,

    output [1:0] fwd_a,
    output [1:0] fwd_b,
    output fwd_mem_addr,
    output fwd_mem_data,
    output fwd_alu,
    output fwd_store,
    output storetoload,

    /* Writeback signals */
    output reg_wen, // For execute stage
    output [3:0] dmem_wen,
    output dmem_sel,
    output csr_wen,
    output lx_sel,
    output [2:0] wb_sel,

    output [2:0] instr_type_wb
    
    // writing to IMEM

   
);
    localparam R = 3'd0, I = 3'd1, S = 3'd2, SB = 3'd3, U = 3'd4, UJ = 3'd5, CSR = 3'd6;

    wire [6:0] opcode_if = instr_if[6:0];
    wire [2:0] funct3_if = instr_if[14:12];
    wire [6:0] opcode_ex = instr_ex[6:0];
    wire [2:0] funct3_ex = instr_ex[14:12];
    wire [6:0] opcode_wb = instr_wb[6:0];
    wire [2:0] funct3_wb = instr_wb[14:12];

    reg pc_sel_reg;
    reg [1:0] instr_sel_reg;
    reg [2:0] instr_type_if_reg;
    reg [2:0] instr_type_ex_reg;
    reg [2:0] instr_type_wb_reg;
    reg imm_sel_reg;
    reg reg_wen_reg;
    reg a_sel_reg;
    reg b_sel_reg;
    reg [3:0] dmem_wen_reg;
    reg csr_wen_reg;
    reg lx_sel_reg;
    reg [1:0] wb_sel_reg;

    assign pc_sel = (opcode_ex == `OPC_JALR);
    // assign pc_sel = pc_sel_reg;
    // assign instr_sel = ;
    assign instr_type_if = instr_type_if_reg;
    assign instr_type_ex = instr_type_ex_reg;
    assign instr_type_wb = instr_type_wb_reg;
    assign imm_sel = imm_sel_reg;
    assign reg_wen = reg_wen_reg;
    assign a_sel = a_sel_reg;
    assign b_sel = b_sel_reg;
    assign dmem_wen = dmem_wen_reg;
    assign csr_wen = csr_wen_reg;
    assign lx_sel = lx_sel_reg;
    assign wb_sel = wb_sel_reg;
    // not working with risc v testbench for some reason
    assign instr_sel = {stall, !pc[30]};

    assign jump = ((opcode_ex == `OPC_BRANCH && branch) || opcode_ex == `OPC_JAL || opcode_ex == `OPC_JALR);
    assign dmem_sel = (opcode_ex == `OPC_LOAD) || (opcode_ex == `OPC_STORE);


    control_hazard control_hazard (
        .clk(clk),
        .rst(rst),
        .instr_if(instr_if),
        .instr_ex(instr_ex),
        .instr_wb(instr_wb),
        .branch(branch),
        .stall(stall),
        .kill(kill)
    );

    data_hazard data_hazard (
        .instr_if(instr_if),
        .instr_ex(instr_ex),
        .instr_wb(instr_wb),
        .fwd_a(fwd_a),
        .fwd_b(fwd_b),
        .fwd_mem_addr(fwd_mem_addr),
        .fwd_mem_data(fwd_mem_data),
        .fwd_alu(fwd_alu),
        .fwd_store(fwd_store),
        .storetoload(storetoload)
    );

    always @(*) begin
        case (opcode_if)
            `OPC_ARI_RTYPE: instr_type_if_reg = R;
            `OPC_LOAD: instr_type_if_reg = I;
            `OPC_ARI_ITYPE: instr_type_if_reg = I;
            `OPC_JALR: instr_type_if_reg = I;
            `OPC_STORE: instr_type_if_reg = S;
            `OPC_BRANCH: instr_type_if_reg = SB;
            `OPC_AUIPC: instr_type_if_reg = U;
            `OPC_LUI: instr_type_if_reg = U;
            `OPC_JAL: instr_type_if_reg = UJ;
            `OPC_CSR: instr_type_if_reg = CSR;
            default: instr_type_if_reg = 7;
        endcase
        case (opcode_ex)
            `OPC_ARI_RTYPE: instr_type_ex_reg = R;
            `OPC_LOAD: instr_type_ex_reg = I;
            `OPC_ARI_ITYPE: instr_type_ex_reg = I;
            `OPC_JALR: instr_type_ex_reg = I;
            `OPC_STORE: instr_type_ex_reg = S;
            `OPC_BRANCH: instr_type_ex_reg = SB;
            `OPC_AUIPC: instr_type_ex_reg = U;
            `OPC_LUI: instr_type_ex_reg = U;
            `OPC_JAL: instr_type_ex_reg = UJ;
            `OPC_CSR: instr_type_ex_reg = CSR;
            default: instr_type_ex_reg = 7;
        endcase
        case (opcode_wb)
            `OPC_ARI_RTYPE: instr_type_wb_reg = R;
            `OPC_LOAD: instr_type_wb_reg = I;
            `OPC_ARI_ITYPE: instr_type_wb_reg = I;
            `OPC_JALR: instr_type_wb_reg = I;
            `OPC_STORE: instr_type_wb_reg = S;
            `OPC_BRANCH: instr_type_wb_reg = SB;
            `OPC_AUIPC: instr_type_wb_reg = U;
            `OPC_LUI: instr_type_wb_reg = U;
            `OPC_JAL: instr_type_wb_reg = UJ;
            `OPC_CSR: instr_type_wb_reg = CSR;
            default: instr_type_wb_reg = 7;
        endcase
    end

    always @(*) begin
        if (rst) begin
            pc_sel_reg = 0;
            a_sel_reg = 0;
            b_sel_reg = 0;
            imm_sel_reg = 0;
            reg_wen_reg = 1;
            // dmem_wen_reg = 0;
            csr_wen_reg = 0;
            lx_sel_reg = 0;
            wb_sel_reg = 'd2;
        end
        case(instr_type_if)
            R: begin
                pc_sel_reg = 0;
            end
            I: begin
                pc_sel_reg = 0;
            end
            S: begin
                pc_sel_reg = 0;
            end
            SB: begin
                pc_sel_reg = 0;
            end
            U: begin
                pc_sel_reg = 0;
            end
            UJ: begin
                pc_sel_reg = 0;
            end
            CSR: begin
                pc_sel_reg = 0;
            end
            default: begin
                pc_sel_reg = 0;
            end
        endcase

        case(instr_type_ex)
            R: begin
                a_sel_reg = 0;
                b_sel_reg = 0;
                imm_sel_reg = 0;
            end
            I: begin
                a_sel_reg = 0;
                b_sel_reg = 1;
                imm_sel_reg = 0;
            end
            S: begin
                a_sel_reg = 0;
                b_sel_reg = 1;
                imm_sel_reg = 1;
            end
            SB: begin
                a_sel_reg = 0;
                b_sel_reg = 0;
                imm_sel_reg = 0; // useless?
            end
            U: begin
                a_sel_reg = `OPC_AUIPC ? 1 : 0;
                b_sel_reg = 1;
                imm_sel_reg = 1;
            end
            UJ: begin
                a_sel_reg = 0;
                b_sel_reg = 0;
                imm_sel_reg = 0;
            end
            CSR: begin
                a_sel_reg = 0;
                b_sel_reg = 0;
                imm_sel_reg = !instr_ex[14];
            end
            default: begin
                a_sel_reg = 0;
                b_sel_reg = 0;
                imm_sel_reg = 0;
            end
        endcase

        case(instr_type_wb)
            R: begin
                reg_wen_reg = 1;
                // dmem_wen_reg = 0;
                csr_wen_reg = 0;
                lx_sel_reg = 0;
                wb_sel_reg = 'd2;
            end
            I: begin
                reg_wen_reg = 1;
                // dmem_wen_reg = 0;
                csr_wen_reg = 0;
                lx_sel_reg = opcode_wb == `OPC_LOAD;
                if ((opcode_wb == `OPC_JALR) || (opcode_wb == `OPC_JAL)) begin
                    wb_sel_reg = 'd3;
                end else if (opcode_wb == `OPC_LOAD) begin
                    if (alu[31] && uart_control) begin 
                        wb_sel_reg = 'd4;
                        // $display("HERE");
                    end
                    else if (alu[31] && uart_rec) begin
                        wb_sel_reg = 'd5;
                        //$display("TRYNA LOAD FROM UART");
                    end
                    else if (alu[31] && cycle_ctr) wb_sel_reg = 'd6;
                    else if (alu[31] && instr_ctr) wb_sel_reg = 'd7;
                    else wb_sel_reg = 'd1;
                end else begin
                    wb_sel_reg = 'd2;
                end
            end
            S: begin
                reg_wen_reg = 1;
                csr_wen_reg = 0;
                lx_sel_reg = 0;
                wb_sel_reg = 'd0;
                // logic for writing bits to dmem
                // case (funct3_wb) 
                //     `FNC_SB: dmem_wen_reg = 4'b0001;
                //     `FNC_SH: dmem_wen_reg = 4'b0011;
                //     `FNC_SW: dmem_wen_reg = 4'b1111;
                //     default: dmem_wen_reg = 0;
                // endcase
            end
            SB: begin
                reg_wen_reg = 0;
                // dmem_wen_reg = 0;
                csr_wen_reg = 0;
                lx_sel_reg = 0;
                wb_sel_reg = 'd0;
            end
            U: begin
                reg_wen_reg = 1;
                // dmem_wen_reg = 0;
                csr_wen_reg = 0;
                lx_sel_reg = 0;
                wb_sel_reg = 'd2;
            end
            UJ: begin
                reg_wen_reg = 1;
                // dmem_wen_reg = 0;
                csr_wen_reg = 0;
                lx_sel_reg = 0;
                wb_sel_reg = 'd3;
            end
            CSR: begin
                reg_wen_reg = 1;
                // dmem_wen_reg = 0;
                csr_wen_reg = 'd1;
                lx_sel_reg = 0;
                wb_sel_reg = 'd0;
            end
            default: begin
                reg_wen_reg = 0;
                // dmem_wen_reg = 0;
                csr_wen_reg = 0;
                lx_sel_reg = 0;
                wb_sel_reg = 'd0;
            end
        endcase
    end
endmodule