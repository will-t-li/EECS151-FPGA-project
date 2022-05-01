`include "Opcode.vh"

module mem_control (
    input clk,
    input rst,
    input [31:0] pc_ex,
    input [31:0] pc_wb,
    input [31:0] instr_ex,
    input [31:0] instr_wb,
    input [31:0] alu_out,
    input [31:0] alu_reg_out,


    // control to DMEM
    //output reg [3:0] dmem_wea,
    output dmem_off,

    // control to IMEM
    //output reg [3:0] imem_wea,
    output reg imem_on,

    // control to BIOS
    // output reg bios_addr_type, // both data types at once idk

    // control to I/O
    output reg IO_en,
    
    output reg uart_control,
    output reg uart_rec,
    output reg uart_tran,
    output reg cycle_ctr,
    output reg instr_ctr,
    output reg reset_ctr

);
    wire tx_send;
    reg dmem_off_reg;
    wire [6:0] opcode_wb = instr_wb[6:0];
    wire [6:0] opcode_ex = instr_ex[6:0];
    wire read = (opcode_wb == `OPC_LOAD);
    wire will_write = (opcode_ex == `OPC_STORE);
    wire write = (opcode_wb == `OPC_STORE);
    reg imem_rw; // 1 is write, 0 is read
    assign tx_send = will_write && (alu_out == 32'h80000008);
    assign dmem_off = tx_send || dmem_off_reg;
    

    always @(*) begin
        if (rst) begin
            imem_on = 0; // imem is read only, addr is PC
            dmem_off_reg = 1;
            uart_control = 0;
            uart_rec = 0;
            uart_tran = 0;
            cycle_ctr = 0;
            instr_ctr = 0;
            reset_ctr = 0;
            IO_en = 0;
        end
        if ((!alu_reg_out[30] && !alu_reg_out[31] && write) || (!alu_reg_out[30] && !alu_reg_out[31] && read)) begin
            dmem_off_reg = 0; // dmem is read and write, addr is data
            if (alu_out[31:28] == 4'b0001) begin
                imem_on = 0; // imem is read only, addr is PC
                dmem_off_reg = 0;
                uart_control = 0;
                uart_rec = 0;
                uart_tran = 0;
                cycle_ctr = 0;
                instr_ctr = 0;
                reset_ctr = 0;
                IO_en = 0;
            end else if (pc_wb[30]) begin
                imem_on = alu_out[31:29] == 3'b001; // imem is write only, addr is data;
                dmem_off_reg = alu_out[28];
                uart_control = 0;
                uart_rec = 0;
                uart_tran = 0;
                cycle_ctr = 0;
                instr_ctr = 0;
                reset_ctr = 0;
                IO_en = 0;
            end else begin
                dmem_off_reg = 0;
                imem_on = 0;
                uart_control = 0;
                uart_rec = 0;
                uart_tran = 0;
                cycle_ctr = 0;
                instr_ctr = 0;
                reset_ctr = 0;
                IO_en = 0;
            end
        end else if (alu_reg_out[31] && read) begin
            IO_en = 1;
            case (alu_reg_out)
                32'h80000000: begin
                    uart_control = 1; // Read {30'b0, uart_rx_data_out_valid, uart_tx_data_in_ready}
                    // $display("Read {30'b0, uart_rx_data_out_valid, uart_tx_data_in_ready}");
                end
                32'h80000004: begin
                    uart_rec = 1; // Read {24'b0, uart_rx_data_out}
                    // $display("Read {24'b0, uart_rx_data_out}, %x", instr_wb);
                end
                32'h80000010: begin
                    cycle_ctr = 1; // clock cylces elapsed
                end
                32'h80000014: begin
                    instr_ctr = 1; // read num of instr executed
                end
                default: begin
                    dmem_off_reg = 0;
                    imem_on = 0;
                    uart_control = 0;
                    uart_rec = 0;
                    uart_tran = 0;
                    cycle_ctr = 0;
                    instr_ctr = 0;
                    reset_ctr = 0;
                end
            endcase
        end else if (alu_reg_out[31] && write) begin
            IO_en = 1;
            case (alu_reg_out)
                32'h80000008: begin
                    uart_tran = 1; // Write {24'b0, uart_tx_data_in}
                end
                32'h80000018: begin
                    reset_ctr = 1; // reset counters to 0
                end
                default: begin
                    uart_control = 0;
                    uart_rec = 0;
                    uart_tran = 0;
                    cycle_ctr = 0;
                    instr_ctr = 0;
                    reset_ctr = 0;
                end
            endcase
        end else begin
            dmem_off_reg = 0;
            imem_on = 0;
            IO_en = 0;
            uart_control = 0;
            uart_rec = 0;
            uart_tran = 0;
            cycle_ctr = 0;
            instr_ctr = 0;
            reset_ctr = 0;
        end
    end

endmodule