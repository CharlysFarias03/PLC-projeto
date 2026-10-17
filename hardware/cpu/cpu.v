module cpu(
    input clk,
    input reset
);

    // --------------------------------------------------------
    // Fios de dados
    // --------------------------------------------------------
    wire [31:0] pc_out;
    wire [31:0] mem_out;
    wire [31:0] mdr_out;
    wire [31:0] banco_rd1, banco_rd2;
    wire [31:0] a_out, b_out;
    wire [31:0] ula_saida, alu_out;
    wire [31:0] sign_ext_out, shift2_branch, jump_addr, lui_out;
    wire [31:0] reg_desloc_out;
    wire [31:0] hi_out, lo_out, hilo_reg_out;
    wire [31:0] epc_out;
    wire [31:0] lb_out, sb_out, mem_write_data;
    wire [31:0] exc_addr_out, exc_vec_out;
    wire [31:0] slt_result;
    wire [63:0] mult_result;
    wire [31:0] div_hi, div_lo;
    wire        mult_done, div_done, div_zero;

    // --------------------------------------------------------
    // Campos da instrucao (saem do IR)
    // --------------------------------------------------------
    wire [5:0] ir_opcode;
    wire [4:0] ir_rs, ir_rt;
    wire [15:0] ir_imm;

    wire [4:0] ir_rd    = ir_imm[15:11];
    wire [4:0] ir_shamt = ir_imm[10:6];
    wire [5:0] ir_funct = ir_imm[5:0];

    // --------------------------------------------------------
    // Saidas dos MUXes
    // --------------------------------------------------------
    wire [31:0] mux_iord_out;
    wire [4:0]  mux_read1_out, mux_read2_out, mux_reg_out;
    wire [31:0] mux_alu1_out, mux_alu2_out;
    wire [31:0] mux_data_out;
    wire [31:0] mux_pc_out;

    // --------------------------------------------------------
    // Flags da ULA
    // --------------------------------------------------------
    wire ula_overflow, ula_neg, ula_zero, ula_igual, ula_maior, ula_menor;

    // --------------------------------------------------------
    // Sinais de controle (gerados por controle.v)
    // --------------------------------------------------------
    wire        pc_write;
    wire [1:0]  iord;          // 00=PC 01=ALUOut 10=excecao
    wire [31:0] exc_vec_addr;  // 253/254/255 selecionado por except_type
    wire        mem_wr;
    wire        ir_write;
    wire        read_src_a;        // MUX_Read1: 0=rs, 1=R29
    wire        read_src_b;        // MUX_Read2: 0=rt, 1=rs
    wire [1:0]  reg_dst;           // MUX_Reg:   0=rt, 1=rd, 2=R31, 3=R29
    wire        reg_write;
    wire [2:0]  mem_to_reg;        // MUX_Data
    wire        alu_src_a;         // MUX_ALU1:  0=PC, 1=A
    wire [1:0]  alu_src_b;         // MUX_ALU2:  0=B, 1=4, 2=signext, 3=shift2
    wire [2:0]  pc_source;         // MUX_PC
    wire        mdr_write;
    wire        a_write, b_write;
    wire        alu_out_write;
    wire [2:0]  alu_op;
    wire        mem_wr_src;        // 0=sw(b_out direto), 1=sb(byte inserido)
    wire [2:0]  shift_code;        // Shift do RegDesloc: 001=load, 010=sll, 100=sra
    wire        mult_start, div_start;
    wire        hi_write, lo_write;
    wire        hilo_src;          // 0=mult, 1=div
    wire        mfhi_sel;          // 0=mflo(lo_out), 1=mfhi(hi_out)
    wire        epc_write;
    wire [1:0]  except_type;       // MUX excecao: 0=opcode, 1=overflow, 2=divzero
    wire        sp_init_sel;       // 1 = inicializa SP=227 apos reset

    // saida do alu_controle
    wire [2:0] ula_seletor;

    // --------------------------------------------------------
    // Logica combinacional de suporte
    // --------------------------------------------------------
    assign shift2_branch  = {sign_ext_out[29:0], 2'b00};
    assign jump_addr      = {pc_out[31:28], ir_rs, ir_rt, ir_imm, 2'b00};
    assign lui_out        = {ir_imm, 16'b0};
    assign hilo_reg_out   = mfhi_sel ? hi_out : lo_out;
    assign slt_result     = {31'b0, ula_menor};
    assign mem_write_data = mem_wr_src ? sb_out : b_out;

    // d7 do MUX_Data: normalmente slt; no estado de init vira SP=227
    wire [31:0] mux_data_d7 = sp_init_sel ? 32'd227 : slt_result;

    // vetor de excecao: byte zero-extended (FSM coloca 253/254/255 no endereco)
    assign exc_vec_out = {24'b0, mdr_out[7:0]};

    // --------------------------------------------------------
    // Componentes VHDL fornecidos pela cadeira
    // --------------------------------------------------------

    Registrador PC(
        .Clk(clk), .Reset(reset),
        .Load(pc_write),
        .Entrada(mux_pc_out),
        .Saida(pc_out)
    );

    Memoria MEM(
        .Address(mux_iord_out), .Clock(clk),
        .Wr(mem_wr),
        .Datain(mem_write_data),
        .Dataout(mem_out)
    );

    Instr_Reg IR(
        .Clk(clk), .Reset(reset),
        .Load_ir(ir_write),
        .Entrada(mem_out),
        .Instr31_26(ir_opcode),
        .Instr25_21(ir_rs),
        .Instr20_16(ir_rt),
        .Instr15_0(ir_imm)
    );

    Banco_reg BANCO(
        .Clk(clk), .Reset(reset),
        .RegWrite(reg_write),
        .ReadReg1(mux_read1_out),
        .ReadReg2(mux_read2_out),
        .WriteReg(mux_reg_out),
        .WriteData(mux_data_out),
        .ReadData1(banco_rd1),
        .ReadData2(banco_rd2)
    );

    Ula32 ULA(
        .A(mux_alu1_out), .B(mux_alu2_out),
        .Seletor(ula_seletor),
        .S(ula_saida),
        .Overflow(ula_overflow), .Negativo(ula_neg),
        .z(ula_zero),
        .Igual(ula_igual), .Maior(ula_maior), .Menor(ula_menor)
    );

    Registrador A(
        .Clk(clk), .Reset(reset),
        .Load(a_write),
        .Entrada(banco_rd1),
        .Saida(a_out)
    );

    Registrador B(
        .Clk(clk), .Reset(reset),
        .Load(b_write),
        .Entrada(banco_rd2),
        .Saida(b_out)
    );

    Registrador ALU_OUT(
        .Clk(clk), .Reset(reset),
        .Load(alu_out_write),
        .Entrada(ula_saida),
        .Saida(alu_out)
    );

    Registrador MDR(
        .Clk(clk), .Reset(reset),
        .Load(mdr_write),
        .Entrada(mem_out),
        .Saida(mdr_out)
    );

    Registrador HI(
        .Clk(clk), .Reset(reset),
        .Load(hi_write),
        .Entrada(hilo_src ? div_hi : mult_result[63:32]),
        .Saida(hi_out)
    );

    Registrador LO(
        .Clk(clk), .Reset(reset),
        .Load(lo_write),
        .Entrada(hilo_src ? div_lo : mult_result[31:0]),
        .Saida(lo_out)
    );

    Registrador EPC(
        .Clk(clk), .Reset(reset),
        .Load(epc_write),
        .Entrada(pc_out),
        .Saida(epc_out)
    );

    RegDesloc DESLOC(
        .Clk(clk), .Reset(reset),
        .Shift(shift_code),
        .N(ir_shamt),
        .Entrada(b_out),
        .Saida(reg_desloc_out)
    );

    // --------------------------------------------------------
    // MUXes
    // --------------------------------------------------------

    // endereco de excecao: 253=opcode 254=overflow 255=divzero
    mux3_32 MUX_EXC_ADDR(
        .sel(except_type),
        .d0(32'd253), .d1(32'd254), .d2(32'd255),
        .saida(exc_vec_addr)
    );

    mux3_32 MUX_IORD(
        .sel(iord),
        .d0(pc_out), .d1(alu_out), .d2(exc_vec_addr),
        .saida(mux_iord_out)
    );

    mux2_5 MUX_READ1(
        .sel(read_src_a),
        .d0(ir_rs), .d1(5'd29),
        .saida(mux_read1_out)
    );

    mux2_5 MUX_READ2(
        .sel(read_src_b),
        .d0(ir_rt), .d1(ir_rs),
        .saida(mux_read2_out)
    );

    mux4_5 MUX_REG(
        .sel(reg_dst),
        .d0(ir_rt), .d1(ir_rd),
        .d2(5'd31), .d3(5'd29),
        .saida(mux_reg_out)
    );

    mux2_32 MUX_ALU1(
        .sel(alu_src_a),
        .d0(pc_out), .d1(a_out),
        .saida(mux_alu1_out)
    );

    mux4_32 MUX_ALU2(
        .sel(alu_src_b),
        .d0(b_out), .d1(32'd4),
        .d2(sign_ext_out), .d3(shift2_branch),
        .saida(mux_alu2_out)
    );

    mux8_32 MUX_DATA(
        .sel(mem_to_reg),
        .d0(mdr_out),        // lw
        .d1(ula_saida),      // jal: PC+4 saindo direto da ULA
        .d2(alu_out),        // add, sub, addi, and
        .d3(lb_out),         // lb
        .d4(reg_desloc_out), // sll, sra
        .d5(lui_out),        // lui
        .d6(hilo_reg_out),   // mfhi, mflo
        .d7(mux_data_d7),    // slt ou sp_init=227
        .saida(mux_data_out)
    );

    mux6_32 MUX_PC(
        .sel(pc_source),
        .d0(ula_saida),   // PC+4 (direto da ULA no fetch)
        .d1(jump_addr),   // j, jal
        .d2(alu_out),     // branch target
        .d3(a_out),       // jr
        .d4(epc_out),     // rte
        .d5(exc_vec_out), // excecao
        .saida(mux_pc_out)
    );

    // --------------------------------------------------------
    // Modulos combinacionais
    // --------------------------------------------------------

    sign_extend SEXT(
        .entrada(ir_imm),
        .saida(sign_ext_out)
    );

    alu_controle ALU_CTRL(
        .alu_op(alu_op),
        .funct(ir_funct),
        .seletor(ula_seletor)
    );

    lb_extrator LB(
        .dado(mdr_out),
        .addr(alu_out[1:0]),
        .saida(lb_out)
    );

    sb_insersor SB(
        .dado_mem(mdr_out),
        .byte_novo(b_out[7:0]),
        .addr(alu_out[1:0]),
        .saida(sb_out)
    );

    // --------------------------------------------------------
    // Unidade de controle
    // --------------------------------------------------------

    controle CTRL(
        .clk(clk), .reset(reset),
        .opcode(ir_opcode), .funct(ir_funct),
        .ula_zero(ula_zero), .ula_igual(ula_igual),
        .ula_overflow(ula_overflow), .ula_menor(ula_menor),
        .mult_done(mult_done), .div_done(div_done), .div_zero(div_zero),
        .pc_write(pc_write),
        .iord(iord),
        .mem_wr(mem_wr),
        .ir_write(ir_write),
        .read_src_a(read_src_a), .read_src_b(read_src_b),
        .reg_dst(reg_dst),
        .reg_write(reg_write),
        .mem_to_reg(mem_to_reg),
        .alu_src_a(alu_src_a), .alu_src_b(alu_src_b),
        .pc_source(pc_source),
        .mdr_write(mdr_write),
        .a_write(a_write), .b_write(b_write),
        .alu_out_write(alu_out_write),
        .alu_op(alu_op),
        .mem_wr_src(mem_wr_src),
        .shift_code(shift_code),
        .mult_start(mult_start), .div_start(div_start),
        .hi_write(hi_write), .lo_write(lo_write),
        .hilo_src(hilo_src), .mfhi_sel(mfhi_sel),
        .epc_write(epc_write), .except_type(except_type),
        .sp_init_sel(sp_init_sel)
    );

    // --------------------------------------------------------
    // Multiplicador e divisor
    // --------------------------------------------------------

    multiplicador MULT(
        .clk(clk), .reset(reset),
        .start(mult_start),
        .A(a_out), .B(b_out),
        .resultado(mult_result),
        .done(mult_done)
    );

    divisor DIV(
        .clk(clk), .reset(reset),
        .start(div_start),
        .A(a_out), .B(b_out),
        .hi(div_hi), .lo(div_lo),
        .done(div_done), .div_zero(div_zero)
    );

endmodule
