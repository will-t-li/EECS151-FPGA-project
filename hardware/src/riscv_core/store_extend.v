`include "Opcode.vh"

module store_extend (
    input [31:0] instr,
    input [31:0] addr,
    input [31:0] din,
    input dmem_off,
    input imem_on,
    input uart_tran, //todo
    input [7:0] uart_tx_data_in,


    output [31:0] dout,
    output [3:0] dmem_wea,
    output [3:0] imem_wea
);
    wire [2:0] fnc = instr[14:12];
    wire [6:0] opcode;
    assign opcode = instr[6:0];

    reg [31:0] dout_reg;
    reg [31:0] din_reg;
    reg [3:0] dmem_wea_reg;
    reg [3:0] imem_wea_reg;
    assign dout = dout_reg;
    assign dmem_wea = dmem_wea_reg;
    assign imem_wea = imem_wea_reg;

    wire offset = addr[1:0];

    always @(*) begin
        dout_reg = 0;
        dmem_wea_reg = 0;
        din_reg = 0;
        if (opcode == `OPC_STORE) begin
            if (uart_tran) din_reg = {24'b0, uart_tx_data_in};
            else din_reg = din;
            case (fnc)
                `FNC_SB: begin
                    case (addr[1:0]) 
                        'b00: begin
                            dout_reg = {24'b0, din[7:0]};
                            dmem_wea_reg = dmem_off ? 4'b0000 : 4'b0001;
                            imem_wea_reg = !imem_on ? 4'b0000 : 4'b0001;
                        end
                        'b01: begin
                            dout_reg = {16'b0, din[7:0], 8'b0};
                            dmem_wea_reg = dmem_off ? 4'b0000 : 4'b0010;
                            imem_wea_reg = !imem_on ? 4'b0000 : 4'b0010;
                        end
                        'b10: begin
                            dout_reg = {8'b0, din[7:0], 16'b0};
                            dmem_wea_reg = dmem_off ? 4'b0000 : 4'b0100;
                            imem_wea_reg = !imem_on ? 4'b0000 : 4'b0100;
                        end
                        'b11: begin
                            dout_reg = {din[7:0], 24'b0};
                            dmem_wea_reg = dmem_off ? 4'b0000 : 4'b1000;
                            imem_wea_reg = !imem_on ? 4'b0000 : 4'b1000;
                        end
                    endcase
                end
                `FNC_SH: begin
                    case (addr[1:0])
                        'b00, 'b01: begin
                            dout_reg = {16'b0, din[15:0]};
                            dmem_wea_reg = dmem_off ? 4'b0000 : 4'b0011;
                            imem_wea_reg = !imem_on ? 4'b0000 : 4'b0011;
                        end
                        'b10, 'b11: begin
                            dout_reg = {din[15:0], 16'b0};
                           dmem_wea_reg = dmem_off ? 4'b0000 : 4'b1100;
                           imem_wea_reg = !imem_on ? 4'b0000 : 4'b1100;
                        end
                    endcase
                    
                end
                `FNC_SW: begin
                    dout_reg = din;
                    dmem_wea_reg = dmem_off ? 4'b0000 : 4'b1111;
                    imem_wea_reg = !imem_on ? 4'b0000 : 4'b1111;
                end
            endcase
        end else begin
            dout_reg = din;
            dmem_wea_reg = 0;
            imem_wea_reg = 0;
        end
    end

endmodule