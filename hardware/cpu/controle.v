module controle(
    input        clk,
    input        reset,

    // entradas da instrucao
    input  [5:0] opcode,
    input  [5:0] funct,

    // flags da ULA
    input        ula_zero,
    input        ula_igual,
    input        ula_overflow,
    input        ula_menor,

    // sinais dos modulos sequenciais
    input        mult_done,
    input        div_done,
    input        div_zero,

    // sinais de controle de saida
    output reg        pc_write,
    output reg        iord,
    output reg        mem_wr,
    output reg        ir_write,
    output reg        read_src_a,
    output reg        read_src_b,
    output reg [1:0]  reg_dst,
    output reg        reg_write,
    output reg [2:0]  mem_to_reg,
    output reg        alu_src_a,
    output reg [1:0]  alu_src_b,
    output reg [2:0]  pc_source,
    output reg        mdr_write,
    output reg        a_write,
    output reg        b_write,
    output reg        alu_out_write,
    output reg [2:0]  alu_op,
    output reg        mem_wr_src,
    output reg [2:0]  shift_code,
    output reg        mult_start,
    output reg        div_start,
    output reg        hi_write,
    output reg        lo_write,
    output reg        hilo_src,
    output reg        mfhi_sel,
    output reg        epc_write,
    output reg [1:0]  except_type
);
    // opcodes das instrucoes
    parameter OP_TIPO_R = 6'h00;
    parameter OP_ADDI   = 6'h08;
    parameter OP_BEQ    = 6'h04;
    parameter OP_BNE    = 6'h05;
    parameter OP_LB     = 6'h20;
    parameter OP_LUI    = 6'h0f;
    parameter OP_LW     = 6'h23;
    parameter OP_SB     = 6'h28;
    parameter OP_SW     = 6'h2b;
    parameter OP_J      = 6'h02;
    parameter OP_JAL    = 6'h03;

    // funcoes R-type
    parameter F_ADD  = 6'h20;
    parameter F_AND  = 6'h24;
    parameter F_DIV  = 6'h1a;
    parameter F_JR   = 6'h08;
    parameter F_MFHI = 6'h10;
    parameter F_MFLO = 6'h12;
    parameter F_MULT = 6'h18;
    parameter F_POP  = 6'h06;
    parameter F_PUSH = 6'h05;
    parameter F_SLL  = 6'h00;
    parameter F_SLT  = 6'h2a;
    parameter F_SRA  = 6'h03;
    parameter F_SUB  = 6'h22;

    // estados
    parameter ST_FETCH1  = 7'd0;
    parameter ST_FETCH2  = 7'd1;
    parameter ST_FETCH3  = 7'd2;
    parameter ST_DECODE  = 7'd3;

    // a ser implementado
    reg [6:0] estado;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            estado <= ST_FETCH1;
        end
    end

    always @(*) begin
        // zera todos os sinais por padrao
        pc_write     = 0; iord         = 0; mem_wr    = 0;
        ir_write     = 0; read_src_a   = 0; read_src_b = 0;
        reg_dst      = 0; reg_write    = 0; mem_to_reg = 0;
        alu_src_a    = 0; alu_src_b    = 0; pc_source  = 0;
        mdr_write    = 0; a_write      = 0; b_write    = 0;
        alu_out_write = 0; alu_op      = 0; mem_wr_src = 0;
        shift_code   = 0; mult_start   = 0; div_start  = 0;
        hi_write     = 0; lo_write     = 0; hilo_src   = 0;
        mfhi_sel     = 0; epc_write    = 0; except_type = 0;
    end

endmodule
