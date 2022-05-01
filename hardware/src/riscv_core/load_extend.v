`include "Opcode.vh"

module load_extend (
    input lx_sel,
    input [3:0] addr,
    input [1:0] offset,
    input [31:0] instr,
    input [31:0] din_dmem,
    input [31:0] din_bios,
    input [31:0] din_store,
    input uart_control,
    input uart_rec,
    input [31:0] uart_readyvalid,
    input [31:0] uart_rdata,
  
    output [31:0] dout
);
    wire [2:0] fnc = instr[14:12];
    wire [6:0] opcode = instr[6:0];
    wire [31:0] din;
    
    reg [31:0] dout_reg, din_reg;
    assign dout = dout_reg;
    
    assign din = din_reg;
    
    always @(*) begin
        if (lx_sel && opcode == `OPC_LOAD) begin

            if (addr[2]) din_reg = din_bios;
            else if (uart_control) din_reg = uart_readyvalid;
            else if (uart_rec) din_reg = uart_rdata;
            else din_reg = din_dmem;
            case (fnc)
                `FNC_LB: begin
                    if (offset == 'b00) dout_reg = $signed(din[7:0]);
                    else if (offset == 'b01) dout_reg = $signed(din[15:8]);
                    else if (offset == 'b10) dout_reg = $signed(din[23:16]);
                    else if (offset == 'b11) dout_reg = $signed(din[31:24]);
                end
                `FNC_LH: begin
                    if (offset == 'b00 || offset == 'b01) dout_reg = $signed(din[15:0]);
                    else if (offset == 'b10 || offset == 'b11) dout_reg = $signed(din[31:16]);
                end
                `FNC_LW:dout_reg = din[31:0];
                `FNC_LBU: begin
                    if (offset == 'b00) dout_reg = {24'b0,din[7:0]};
                    else if (offset == 'b01) dout_reg = {24'b0,din[15:8]};
                    else if (offset == 'b10) dout_reg = {24'b0,din[23:16]};
                    else if (offset == 'b11) dout_reg = {24'b0,din[31:24]};
                end
                `FNC_LHU: begin
                    if (offset == 'b00 || offset == 'b01) dout_reg = {16'b0, din[15:0]};
                    else if (offset == 'b10 || offset == 'b11) dout_reg = {16'b0, din[31:16]};
                end
                default: dout_reg = 0;
            endcase
        end else begin
            dout_reg = din;
        end
    end

endmodule