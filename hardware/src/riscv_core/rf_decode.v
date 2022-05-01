module rf_decode (
    input clk,
    input [31:0] instr,
    input [2:0] instr_type,
    output [4:0] rf_ra1,
    output [4:0] rf_ra2,
    output [4:0] rf_wa
);
    localparam R = 3'd0, I = 3'd1, S = 3'd2, SB = 3'd3, U = 3'd4, UJ = 3'd5, CSR = 3'd6;
    reg [4:0] rf_ra1_reg;
    reg [4:0] rf_ra2_reg;
    reg [4:0] rf_wa_reg;
    assign rf_ra1 = rf_ra1_reg;
    assign rf_ra2 = rf_ra2_reg;
    assign rf_wa = rf_wa_reg;

    always @(*) begin
        case(instr_type)
            R: begin
                rf_ra1_reg = instr[19:15];
                rf_ra2_reg = instr[24:20];
                //rf_wa_reg = instr[11:7];
            end
            I: begin
                rf_ra1_reg = instr[19:15];
                rf_ra2_reg = 0;
                //rf_wa_reg = instr[11:7];
            end
            S: begin
                rf_ra1_reg = instr[19:15];
                rf_ra2_reg = instr[24:20];
                //rf_wa_reg = 0;
            end
            SB: begin
                rf_ra1_reg = instr[19:15];
                rf_ra2_reg = instr[24:20];
                //rf_wa_reg = 0;
            end
            U: begin
                rf_ra1_reg = 0;
                rf_ra2_reg = 0;
                //rf_wa_reg = instr[11:7];
            end
            UJ: begin
                rf_ra1_reg = 0;
                rf_ra2_reg = 0;
                //rf_wa_reg = instr[11:7];
            end
            CSR: begin
                rf_ra1_reg = instr[19:15];
                rf_ra2_reg = 0;
                //rf_wa_reg = instr[11:7];
            end
            default: begin
                rf_ra1_reg = 0;
                rf_ra2_reg = 0;
                //rf_wa_reg = instr[11:7];
            end
        endcase
    end
    
    always @(posedge clk) begin
        case(instr_type)
            R: begin
                rf_wa_reg <= instr[11:7];
            end
            I: begin
                rf_wa_reg <= instr[11:7];
            end
            S: begin
                rf_wa_reg <= 0;
            end
            SB: begin
                rf_wa_reg <= 0;
            end
            U: begin
                rf_wa_reg <= instr[11:7];
            end
            UJ: begin
                rf_wa_reg <= instr[11:7];
            end
            CSR: begin
                rf_wa_reg <= instr[11:7];
            end
            default: begin
                rf_wa_reg <= instr[11:7];
            end
        endcase
    end
    
endmodule