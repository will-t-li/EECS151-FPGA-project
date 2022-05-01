module Riscv151 #(
    parameter CPU_CLOCK_FREQ = 50_000_000,
    parameter RESET_PC       = 32'h4000_0000,
    parameter BAUD_RATE      = 115200,
    parameter BIOS_MIF_HEX   = "bios151v3.mif",
    parameter DEPTH = 32,
    parameter WIDTH = 8
) (
    input  clk,
    input  rst,
    input  FPGA_SERIAL_RX,
    output FPGA_SERIAL_TX,
    output [31:0] csr,
    output [3:0] leds
);
    assign leds = alu_out[31:28];
    // Memories
    localparam BIOS_AWIDTH = 11;
    localparam BIOS_DWIDTH = 32;
    localparam DMEM_AWIDTH = 14;
    localparam DMEM_DWIDTH = 32;
    localparam IMEM_AWIDTH = 14;
    localparam IMEM_DWIDTH = 32;

    // BIOS
    wire [BIOS_AWIDTH-1:0] bios_addra, bios_addrb;
    wire [BIOS_DWIDTH-1:0] bios_douta, bios_doutb;

    // DMEM
    wire [DMEM_AWIDTH-1:0] dmem_addra;
    wire [DMEM_DWIDTH-1:0] dmem_dina, dmem_douta;
    wire [3:0] dmem_wea;

    // IMEM
    wire [IMEM_AWIDTH-1:0] imem_addra, imem_addrb;
    wire [IMEM_DWIDTH-1:0] imem_douta, imem_doutb;
    wire [IMEM_DWIDTH-1:0] imem_dina, imem_dinb;
    wire [3:0] imem_wea, imem_web;

    // Reg File
    wire [4:0]  rf_ra1, rf_ra2, rf_wa;
    wire [31:0] rf_rd1, rf_rd2, rf_wd;


    // Control Logic
    wire [31:0] instr_if;
    wire [31:0] instr_ex;
    wire [31:0] instr_wb;
    wire branch;
    wire pc_sel;
    wire stall;
    wire jump;
    wire kill;
    wire imm_sel;
    wire [1:0] instr_sel;
    wire [2:0] instr_type_if;
    wire [2:0] instr_type_ex;
    wire [2:0] instr_type_wb;
    wire reg_wen;
    wire [1:0] fwd_a;
    wire [1:0] fwd_b;
    wire a_sel;
    wire b_sel;
    wire fwd_mem_addr;
    wire fwd_alu;
    wire fwd_store;
    wire dmem_sel;
    wire csr_wen;
    wire lx_sel;
    wire [2:0] wb_sel;
    wire [31:0] alu_reg_out;
    wire [31:0] wb_mux_value;


    // PC's
    wire [31:0] pc;
    wire [31:0] pc_next;
    wire [31:0] pc_if;
    wire [31:0] pc_ex;
    wire [31:0] pc_wb;
    wire [IMEM_AWIDTH-1:0] imem_addr = pc_if[IMEM_AWIDTH+1:2];
    wire [BIOS_AWIDTH-1:0] bios_addr = pc_if[BIOS_AWIDTH+1:2];
    assign imem_addrb = imem_addr;
    assign bios_addra = bios_addr;
    wire imem_on;
    wire IO_en;
    wire uart_control;
    wire uart_rec;
    wire uart_tran;
    wire cycle_ctr;
    wire instr_ctr;
    wire reset_ctr;
    wire dmem_off;
    wire [31:0] alu_out;

    wire [7:0] uart_tx_data_in;
    wire [7:0] uart_rx_data_out;
    wire uart_rx_data_out_valid;
    wire uart_rx_data_out_ready;
    wire uart_tx_data_in_valid;
    wire uart_tx_data_in_ready;


    control_logic #(
    ) control_logic (
        .clk(clk),
        .rst(rst),
        .pc(pc_wb), // only used for mem control
        .instr_if(instr_if),
        .instr_ex(instr_ex),
        .instr_wb(instr_wb),
        .branch(branch),
        .pc_sel(pc_sel),
        .jump(jump),
        .kill(kill),
        .instr_sel(instr_sel),
        .instr_type_if(instr_type_if),
        .instr_type_ex(instr_type_ex),
        .instr_type_wb(instr_type_wb),
        .imm_sel(imm_sel),
        .stall(stall),
        .reg_wen(reg_wen),
        .fwd_a(fwd_a),
        .fwd_b(fwd_b),
        .a_sel(a_sel),
        .b_sel(b_sel),
        .fwd_mem_addr(fwd_mem_addr),
        .fwd_alu(fwd_alu),
        .fwd_store(fwd_store),
        .dmem_sel(dmem_sel),
        .csr_wen(csr_wen),
        .lx_sel(lx_sel),
        .wb_sel(wb_sel),
        .alu(alu_reg_out),
        .uart_control(uart_control),
        .uart_rec(uart_rec),
        .cycle_ctr(cycle_ctr),
        .instr_ctr(instr_ctr)
    );
    

    // BIOS Memory
    // Synchronous read: read takes one cycle
    // Synchronous write: write takes one cycle
    SYNC_ROM_DP #(
    .AWIDTH(BIOS_AWIDTH),
    .DWIDTH(BIOS_DWIDTH),
    .MIF_HEX(BIOS_MIF_HEX)
    ) bios_mem(
        .q0(bios_douta), // output
        .addr0(bios_addra), // input
        .en0(1'b1),

        .q1(bios_doutb), // output
        .addr1(bios_addrb), // input
        .en1(1'b1),

        .clk(clk)
    );


    // Data Memory
    // Synchronous read: read takes one cycle
    // Synchronous write: write takes one cycle
    // Write-byte-enable: select which of the four bytes to write
    wire [DMEM_DWIDTH-1:0] dmem_douta_tmp;
    SYNC_RAM_WBE #(
    .AWIDTH(DMEM_AWIDTH),
    .DWIDTH(DMEM_DWIDTH)
    ) dmem (
        .q(dmem_douta_tmp), // output
        .d(dmem_dina), // input
        .addr(dmem_addra), // input
        .wbe(dmem_wea), //& {!uart_tran, !uart_tran, !uart_tran, !uart_tran}), // input
        .en(1'b1),
        .clk(clk)
    );


    wire [DMEM_AWIDTH-1:0] prev_dmem_addr;
    REGISTER_R_CE #(
        .N(DMEM_AWIDTH),
        .INIT(0)
    ) prev_dmem_addr_reg (
        .q(prev_dmem_addr),
        .d(dmem_addra),
        .rst(rst),
        .ce(1'b1),
        .clk(clk)
    );
    wire [3:0] prev_dmem_wea;
    REGISTER_R_CE #(
        .N(4),
        .INIT(0)
    ) prev_dmem_wea_reg (
        .q(prev_dmem_wea),
        .d(dmem_wea),
        .rst(rst),
        .ce(1'b1),
        .clk(clk)
    );
    wire [DMEM_DWIDTH-1:0] prev_dmem_din;
    REGISTER_R_CE #(
        .N(DMEM_DWIDTH),
        .INIT(0)
    ) prev_dmem_dout_reg (
        .q(prev_dmem_din),
        .d(dmem_dina),
        .rst(rst),
        .ce(1'b1),
        .clk(clk)
    );
    wire [31:0] merged_dmem;
    merge_dmem merge_dmem (
        .wea(prev_dmem_wea),
        .din(prev_dmem_din),
        .merge(dmem_douta_tmp),
        .dout(merged_dmem)
    );
    assign dmem_douta = prev_dmem_addr == dmem_addra && prev_dmem_wea != 0 ? merged_dmem : dmem_douta_tmp;
    

    wire rf_wen = reg_wen && rf_wa != 0;
    assign rf_wd = wb_mux_value;
    // Asynchronous read: read data is available in the same cycle
    // Synchronous write: write takes one cycle
    ASYNC_RAM_1W2R # (
    .AWIDTH(5),
    .DWIDTH(32)
    ) rf (
        .d0(rf_wd), // input
        .addr0(rf_wa), // input
        .we0(rf_wen), // input

        .q1(rf_rd1), // output
        .addr1(rf_ra1), // input

        .q2(rf_rd2), // output
        .addr2(rf_ra2), // input

        .clk(clk)
    );


    /* Instruction Fetch */
    REGISTER_R_CE #(
    .N(32),
    .INIT(RESET_PC)
    ) program_counter (
        .q(pc),
        .d(pc_next),
        .rst(rst),
        .ce(1'b1),
        .clk(clk)
    );

    // PC Connection
    assign pc_if = pc;
    REGISTER_R_CE #(
    .N(32),
    .INIT(RESET_PC)
    ) pc_if_ex_reg (
        .q(pc_ex),
        .d(pc_if),
        .rst(rst),
        .ce(1'b1),
        .clk(clk)
    );

    wire [31:0] instr_if_tmp;
    mux #(
    .N(4),
    .WIDTH(32)
    ) imem_mux (
        .select(instr_sel),
        .in0(bios_douta),
        .in1(imem_doutb),
        .in2(32'b00010011), // NOP
        .in3(32'b00010011),
        .out(instr_if_tmp)
    );

    assign instr_if = kill ? 32'b00010011 : instr_if_tmp;

  
  
  
    /* Execute */

    REGISTER_R_CE #(
    .N(32),
    .INIT(0)
    ) instr_ex_reg (
        .q(instr_ex),
        .d(instr_if),
        .rst(rst),
        .ce(1'b1),
        .clk(clk)
    );

    rf_decode rf_decode (
        .clk(clk),
        .instr(instr_ex),
        .instr_type(instr_type_ex),
        .rf_ra1(rf_ra1),
        .rf_ra2(rf_ra2),
        .rf_wa(rf_wa)
    );

    wire [31:0] imm_gen_out;
    imm_gen imm_gen (
        .instr_type(instr_type_ex),
        .instr(instr_ex),
        .imm(imm_gen_out)
    );
    

    assign pc_next = jump ? (pc_sel ? alu_out : pc_wb + imm_gen_out) : (stall ? pc : pc + 4);
    wire [31:0] ldx_out;

    wire [31:0] a_fwd_out;
    mux #(
    .N(3),
    .WIDTH(32)
    ) a_fwd (
        .select(fwd_a),
        .in0(rf_rd1),
        .in1(alu_reg_out),
        .in2(ldx_out),
        //.in2(dmem_douta),
        .in3(),
        .out(a_fwd_out)
    );

    wire [31:0] b_fwd_out;
    mux #(
    .N(3),
    .WIDTH(32)
    ) b_fwd (
        .select(fwd_b),
        .in0(rf_rd2),
        .in1(alu_reg_out),
        .in2(ldx_out),
        .in3(),
        .out(b_fwd_out)
    );
    // NOTE: NEED TO INSERT KILL WHEN INST GETS REPEATED
    branch_comparator branch_comparator (
        .rs1(a_fwd_out),
        .rs2(b_fwd_out),
        .funct3(instr_ex[14:12]),
        .branch(branch)
    );

    wire [31:0] a_sel_out;
    mux #(
    .N(2),
    .WIDTH(32)
    ) a_mux (
        .select(a_sel),
        .in0(a_fwd_out),
        .in1(pc_wb),
        .in2(),
        .in3(),
        .out(a_sel_out)
    );

    wire [31:0] b_sel_out;
    mux #(
    .N(2),
    .WIDTH(32)
    ) b_mux (
        .select(b_sel),
        .in0(b_fwd_out),
        .in1(imm_gen_out),
        .in2(),
        .in3(),
        .out(b_sel_out)
    );

    
    alu alu (
        .a(a_sel_out),
        .b(b_sel_out),
        .instr(instr_ex),
        .result(alu_out)
    );

    assign bios_addrb = alu_out[BIOS_AWIDTH+1:2];
    // assign imem_addra = alu_out[15:2];

    wire [31:0] alu_mux_value;
    mux #(
    .N(2),
    .WIDTH(32)
    ) alu_mux (
        .select(fwd_mem_addr),
        .in0(alu_out),
        .in1(rf_wd),
        .in2(0), // Unused
        .in3(0), // Unused
        .out(alu_mux_value)
    );


    wire [31:0] csr_mux_value;
    mux #(
    .N(2),
    .WIDTH(32)
    ) csr_mux (
        .select(imm_sel),
        .in0(imm_gen_out),
        .in1(alu_mux_value),
        .in2(0), // Unused
        .in3(0), // Unused
        .out(csr_mux_value)
    );


    REGISTER_R_CE #(
    .N(32),
    .INIT(0)
    ) alu_reg (
        .q(alu_reg_out),
        .d(alu_mux_value),
        .rst(rst),
        .ce(1'b1),
        .clk(clk)
    );

    wire [31:0] b_reg_out;
    REGISTER_R_CE #(
    .N(32),
    .INIT(0)
    ) b_reg (
        .q(b_reg_out),
        .d(b_fwd_out),
        .rst(rst),
        .ce(1'b1),
        .clk(clk)
    );

    wire [31:0] csr_reg_out;
    REGISTER_R_CE #(
    .N(32),
    .INIT(0)
    ) csr_reg (
        .q(csr_reg_out),
        .d(csr_mux_value),
        .rst(rst),
        .ce(1'b1),
        .clk(clk)
    );

    REGISTER_R_CE #(
    .N(32),
    .INIT(RESET_PC)
    ) pc_ex_wb_reg (
        .q(pc_wb),
        .d(pc_ex),
        .rst(rst),
        .ce(1'b1),
        .clk(clk)
    );

    REGISTER_R_CE #(
    .N(32),
    .INIT(0)
    ) instr_ex_wb_reg (
        .q(instr_wb),
        .d(instr_ex),
        .rst(rst),
        .ce(1'b1),
        .clk(clk)
    );

    wire [31:0] cycle, cycle_next;
    assign cycle_next = cycle + 1;
    REGISTER_R_CE #(
    .N(32),
    .INIT(0)
    ) cycle_ctr_reg (
        .q(cycle),
        .d(cycle_next),
        .rst(reset_ctr),
        .ce(1'b1),
        .clk(clk)
    );
    
    wire [31:0] instr_cnt, instr_cnt_next;
    assign instr_cnt_next = (rst) ? 'd0 : ((instr_type_wb != 'd7) ? instr_cnt : instr_cnt - 'd1);
    REGISTER_R_CE #(
    .N(32),
    .INIT(0)
    ) instr_ctr_reg (
        .q(instr_cnt),
        .d(instr_cnt_next),
        .rst(reset_ctr),
        .ce(1'b1),
        .clk(clk)
    );
    
    
    memory_control #(
    ) memory_control (
        .clk(clk),
        .rst(rst),
        .pc_ex(pc_ex),
        .pc_wb(pc_wb),
        .instr_wb(instr_wb),
        .instr_ex(instr_ex),
        .alu_out(alu_out),
        .alu_reg_out(alu_reg_out),
        .imem_on(imem_on),
        .dmem_off(dmem_off),
        .IO_en(IO_en),
        .uart_control(uart_control),
        .uart_rec(uart_rec),
        .uart_tran(uart_tran),
        .cycle_ctr(cycle_ctr),
        .instr_ctr(instr_ctr),
        .reset_ctr(reset_ctr)
    );


    wire [31:0] fwd_store_val;
    mux #(
    .N(2),
    .WIDTH(32)
    ) fwd_to_store (
        .select(fwd_store),
        .in0(b_reg_out),
        .in1(b_fwd_out),
        .in2(0), // Unused
        .in3(0), // Unused
        .out(fwd_store_val)
    );

    wire [31:0] store_out;
    store_extend store_extend (
        .instr(instr_ex),
        .addr(alu_out),
        .din(b_fwd_out),
        .dmem_off(dmem_off),
        .imem_on(imem_on),
        .dout(store_out),
        .uart_tx_data_in(uart_tx_data_in),
        .uart_tran(uart_tran),
        .dmem_wea(dmem_wea),
        .imem_wea(imem_wea)
    );



    /* Write Back */


    REGISTER_R_CE #(
    .N(32),
    .INIT(0)
    ) instr_wb_reg (
        .q(instr_wb),
        .d(instr_ex),
        .rst(rst),
        .ce(1'b1),
        .clk(clk)
    );

    wire [31:0] fwd_alu_mux_value;
    mux #(
    .N(2),
    .WIDTH(32)
    ) fwd_alu_mux (
        .select(fwd_alu),
        .in0(alu_reg_out),
        .in1(alu_mux_value),
        .in2(0), // Unused
        .in3(0), // Unused
        .out(fwd_alu_mux_value)
    );

    
    assign imem_addra = (uart_tran) ? alu_mux_value[IMEM_AWIDTH+1:2] : ((dmem_sel && !fwd_mem_addr) ? alu_out[IMEM_AWIDTH+1:2] : ((dmem_sel && fwd_mem_addr) ? alu_mux_value[IMEM_AWIDTH+1:2] : fwd_alu_mux_value[IMEM_AWIDTH+1:2]));
    assign dmem_addra = (uart_tran) ? alu_mux_value[DMEM_AWIDTH+1:2] : ((dmem_sel && !fwd_mem_addr) ? alu_out[DMEM_AWIDTH+1:2] : ((dmem_sel && fwd_mem_addr) ? alu_mux_value[DMEM_AWIDTH+1:2] : fwd_alu_mux_value[DMEM_AWIDTH+1:2]));


    wire [31:0] to_load;
    REGISTER_R_CE #(
    .N(32),
    .INIT(0)
    ) store_load_reg (
        .q(to_load),
        .d(store_out),
        .rst(rst),
        .ce(1'b1),
        .clk(clk)
    );


    assign imem_dina = store_out;
    assign dmem_dina = (alu_out == 'h80000008) ? alu_out : store_out;

    wire csr_addr = 0;
    wire [31:0] csr_data_w = csr_reg_out;
    wire [31:0] csr_data_r;
    assign csr = csr_data_r;

    ASYNC_RAM #(
    .AWIDTH(1),
    .DWIDTH(32)
    ) csr_ram (
        .clk(clk),
        .addr(csr_addr),
        .we(csr_wen),
        .d(csr_data_w),
        .q(csr_data_r)
    );

    wire rx_full;
    wire rx_empty;

    load_extend load_extend (
        .lx_sel(lx_sel),
        .addr(alu_reg_out[31:28]),
        .offset(alu_reg_out[1:0]),
        .instr(instr_wb),
        .din_dmem(dmem_douta),
        .din_bios(bios_doutb),
        .din_store(to_load),
        .uart_readyvalid({30'b0, !rx_empty, uart_tx_data_in_ready}),
        .uart_rdata({24'b0, uart_rx_data_out}),
        .uart_control(uart_control),
        .uart_rec(uart_rec),

        .dout(ldx_out)
    );

    mux #(
    .N(8),
    .WIDTH(32)
    ) wb_mux (
        .select(wb_sel),
        .in0(csr_data_r),
        .in1(ldx_out),
        .in2(alu_reg_out),
        .in3(pc_wb),
        .in4({30'b0, !rx_empty, uart_tx_data_in_ready}),
        .in5({24'b0, uart_rx_data_out}),
        .in6(cycle),
        .in7(instr_cnt),
        .out(wb_mux_value)
    );

    // always @(uart_control) begin
    //     if (uart_control) $display("wb_sel %d, %x", wb_sel, {30'b0, !rx_empty, uart_tx_data_in_ready});
    // end

    
    wire uart_rx_readyvalid;
    wire [31:0] rx_data_out;
    wire rx_data_out_valid;

    // wire rx_fifo_rd_en;
    //assign rx_fifo_rd_en = !rx_empty;
    wire rx_fifo_rd_en = uart_rec; // & clk;

    fifo #(
    .WIDTH(32),
    .DEPTH(32)
    ) rx_fifo (
        .clk(clk),
        .rst(rst),
        // Write side
        .wr_en(uart_rx_data_out_valid),
        .din({24'b0, uart_rx_data_out}),
        .full(rx_full),
        // Read side
        .rd_en(rx_fifo_rd_en),
        .dout(rx_data_out),
        .empty(rx_empty)
    );

    assign uart_tx_data_in = to_load; // store_out;
    uart # (
    .CLOCK_FREQ(CPU_CLOCK_FREQ),
    .BAUD_RATE(BAUD_RATE)
    ) uart (
        .clk(clk), //input
        .reset(rst), //input
        .data_in(uart_tx_data_in), //input
        .data_in_valid(uart_tran), //uart_tx_data_in_valid), //input
        .data_in_ready(uart_tx_data_in_ready), //output

        .data_out(uart_rx_data_out), // output
        .data_out_valid(uart_rx_data_out_valid), //output
        .data_out_ready(!rx_full), // uart_rx_data_out_ready), //input // needs to go high it is a load

        .serial_in(FPGA_SERIAL_RX), //input
        .serial_out(FPGA_SERIAL_TX) //output
    );

    assign imem_web = 0;
    // assign imem_wea = imem_on ? 4'b1111 : 0;

    // Instruction Memory
    // Synchronous read: read takes one cycle
    // Synchronous write: write takes one cycle
    // Write-byte-enable: select which of the four bytes to write
    SYNC_RAM_DP_WBE #(
    .AWIDTH(IMEM_AWIDTH),
    .DWIDTH(IMEM_DWIDTH)
    ) imem (
        .q0(imem_douta), // output
        .d0(imem_dina), // input
        .addr0(imem_addra), // input

        .wbe0(imem_wea), // input
        .en0(imem_on),

        .q1(imem_doutb), // output
        .d1(imem_dinb), // input
        .addr1(imem_addrb), // input -- connected to pc_if
        .wbe1(imem_web), // input
        .en1(1'b1),

        .clk(clk)
    );
endmodule