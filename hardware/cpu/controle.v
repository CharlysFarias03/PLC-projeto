module controle(
    input        clk,
    input        reset,
    input  [5:0] opcode,
    input  [5:0] funct,
    input        ula_zero,
    input        ula_igual,
    input        ula_overflow,
    input        ula_menor,
    input        mult_done,
    input        div_done,
    input        div_zero,
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
    output reg [1:0]  except_type,
    output reg        sp_init_sel
);

    // --------------------------------------------------------
    // Opcodes
    // --------------------------------------------------------
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

    // --------------------------------------------------------
    // Funcoes R-type
    // --------------------------------------------------------
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

    // --------------------------------------------------------
    // Estados — todos declarados para evitar erros de referencia
    // --------------------------------------------------------
    parameter ST_FETCH1    = 7'd0;
    parameter ST_FETCH2    = 7'd1;
    parameter ST_FETCH3    = 7'd2;
    parameter ST_DECODE    = 7'd3;

    parameter ST_RTYPE_EX  = 7'd4;
    parameter ST_RTYPE_WB  = 7'd5;
    parameter ST_SLT_EX    = 7'd6;
    parameter ST_SLT_WB    = 7'd7;
    parameter ST_ADDI_EX   = 7'd8;
    parameter ST_ADDI_WB   = 7'd9;
    parameter ST_LW_ADDR   = 7'd10;
    parameter ST_LW_MEM1   = 7'd11;
    parameter ST_LW_MEM2   = 7'd12;
    parameter ST_LW_MDR    = 7'd13;
    parameter ST_LW_WB     = 7'd14;
    parameter ST_SW_ADDR   = 7'd15;
    parameter ST_SW_MEM    = 7'd16;
    parameter ST_BEQ       = 7'd17;
    parameter ST_BNE       = 7'd18;
    parameter ST_J         = 7'd19;
    parameter ST_JAL       = 7'd20;
    parameter ST_JR        = 7'd21;
    parameter ST_LUI_WB    = 7'd22;

    // proximas entregas
    parameter ST_LB_ADDR   = 7'd23;
    parameter ST_LB_MEM1   = 7'd24;
    parameter ST_LB_MEM2   = 7'd25;
    parameter ST_LB_MDR    = 7'd26;
    parameter ST_LB_WB     = 7'd27;
    parameter ST_SB_ADDR   = 7'd28;
    parameter ST_SB_READ1  = 7'd29;
    parameter ST_SB_READ2  = 7'd30;
    parameter ST_SB_MDR    = 7'd31;
    parameter ST_SB_WRITE  = 7'd32;
    parameter ST_SLL_LOAD  = 7'd33;
    parameter ST_SLL_EXEC  = 7'd34;
    parameter ST_SLL_WB    = 7'd35;
    parameter ST_SRA_LOAD  = 7'd36;
    parameter ST_SRA_EXEC  = 7'd37;
    parameter ST_SRA_WB    = 7'd38;
    parameter ST_MFHI_WB   = 7'd39;
    parameter ST_MFLO_WB   = 7'd40;
    parameter ST_MULT_START= 7'd41;
    parameter ST_MULT_WAIT = 7'd42;
    parameter ST_MULT_WB   = 7'd43;
    parameter ST_DIV_START = 7'd44;
    parameter ST_DIV_WAIT  = 7'd45;
    parameter ST_DIV_WB    = 7'd46;
    parameter ST_PUSH_READ = 7'd47;
    parameter ST_PUSH_CALC = 7'd48;
    parameter ST_PUSH_STR  = 7'd49;
    parameter ST_PUSH_SPUP = 7'd50;
    parameter ST_POP_READ  = 7'd51;
    parameter ST_POP_ADDR  = 7'd52;
    parameter ST_POP_MEM1  = 7'd53;
    parameter ST_POP_MEM2  = 7'd54;
    parameter ST_POP_MDR   = 7'd55;
    parameter ST_POP_WB    = 7'd56;
    parameter ST_POP_SPUP  = 7'd57;
    parameter ST_EXCEP_EPC = 7'd58;
    parameter ST_EXCEP_MEM1= 7'd59;
    parameter ST_EXCEP_MEM2= 7'd60;
    parameter ST_EXCEP_MDR = 7'd61;
    parameter ST_EXCEP_PC  = 7'd62;
    parameter ST_RTE       = 7'd63;
    parameter ST_SP_INIT   = 7'd64;

    // --------------------------------------------------------
    // Registrador de estado
    // --------------------------------------------------------
    reg [6:0] estado;
    reg [6:0] prox_estado;

    always @(posedge clk or posedge reset) begin
        if (reset)
            estado <= ST_SP_INIT;
        else
            estado <= prox_estado;
    end

    // --------------------------------------------------------
    // Logica combinacional: saidas + proximo estado
    // --------------------------------------------------------
    always @(*) begin
        pc_write      = 0; iord          = 0; mem_wr        = 0;
        ir_write      = 0; read_src_a    = 0; read_src_b    = 0;
        reg_dst       = 0; reg_write     = 0; mem_to_reg    = 0;
        alu_src_a     = 0; alu_src_b     = 0; pc_source     = 0;
        mdr_write     = 0; a_write       = 0; b_write       = 0;
        alu_out_write = 0; alu_op        = 0; mem_wr_src    = 0;
        shift_code    = 0; mult_start    = 0; div_start     = 0;
        hi_write      = 0; lo_write      = 0; hilo_src      = 0;
        mfhi_sel      = 0; epc_write     = 0; except_type   = 0;
        sp_init_sel   = 0;
        prox_estado   = ST_FETCH1;

        case (estado)

            // ------------------------------------------------
            // Busca da instrucao (3 ciclos por causa do delay da memoria)
            // ------------------------------------------------
            ST_FETCH1: begin
                iord        = 0;
                prox_estado = ST_FETCH2;
            end

            ST_FETCH2: begin
                iord        = 0;
                prox_estado = ST_FETCH3;
            end

            ST_FETCH3: begin
                iord          = 0;
                ir_write      = 1;      // IR <- instrucao da memoria
                alu_src_a     = 0;      // ULA entrada A = PC
                alu_src_b     = 2'b01;  // ULA entrada B = 4
                alu_op        = 3'b001; // soma
                pc_write      = 1;      // PC <- PC + 4
                pc_source     = 3'd0;   // fonte = ula_saida
                prox_estado   = ST_DECODE;
            end

            // ------------------------------------------------
            // Decodificacao: carrega A e B, pre-calcula branch
            // ------------------------------------------------
            ST_DECODE: begin
                a_write       = 1;      // A <- banco[rs]
                b_write       = 1;      // B <- banco[rt]
                alu_src_a     = 0;      // PC+4
                alu_src_b     = 2'b11;  // sign_ext << 2
                alu_op        = 3'b001; // soma
                alu_out_write = 1;      // ALUOut <- branch target

                case (opcode)
                    OP_TIPO_R: begin
                        case (funct)
                            F_ADD,
                            F_SUB,
                            F_AND:       prox_estado = ST_RTYPE_EX;
                            F_SLT:       prox_estado = ST_SLT_EX;
                            F_JR:        prox_estado = ST_JR;
                            F_SLL:       prox_estado = ST_SLL_LOAD;
                            F_SRA:       prox_estado = ST_SRA_LOAD;
                            F_MFHI:      prox_estado = ST_MFHI_WB;
                            F_MFLO:      prox_estado = ST_MFLO_WB;
                            F_MULT:      prox_estado = ST_MULT_START;
                            F_DIV:       prox_estado = ST_DIV_START;
                            F_PUSH:      prox_estado = ST_PUSH_READ;
                            F_POP:       prox_estado = ST_POP_READ;
                            default:     prox_estado = ST_FETCH1;
                        endcase
                    end
                    OP_ADDI:  prox_estado = ST_ADDI_EX;
                    OP_LW:    prox_estado = ST_LW_ADDR;
                    OP_SW:    prox_estado = ST_SW_ADDR;
                    OP_BEQ:   prox_estado = ST_BEQ;
                    OP_BNE:   prox_estado = ST_BNE;
                    OP_J:     prox_estado = ST_J;
                    OP_JAL:   prox_estado = ST_JAL;
                    OP_LUI:   prox_estado = ST_LUI_WB;
                    OP_LB:    prox_estado = ST_LB_ADDR;
                    OP_SB:    prox_estado = ST_SB_ADDR;
                    default:  prox_estado = ST_FETCH1;
                endcase
            end

            // ------------------------------------------------
            // R-type aritmetico (add, sub, and)
            // ------------------------------------------------
            ST_RTYPE_EX: begin
                alu_src_a     = 1;      // A = rs
                alu_src_b     = 2'b00;  // B = rt
                alu_op        = 3'b000; // usa funct
                alu_out_write = 1;
                prox_estado   = ST_RTYPE_WB;
            end

            ST_RTYPE_WB: begin
                reg_write   = 1;
                reg_dst     = 2'b01;    // rd
                mem_to_reg  = 3'd2;     // ALUOut
                prox_estado = ST_FETCH1;
            end

            // ------------------------------------------------
            // SLT
            // ------------------------------------------------
            ST_SLT_EX: begin
                alu_src_a   = 1;
                alu_src_b   = 2'b00;
                alu_op      = 3'b010;   // sub (ativa flag Menor)
                prox_estado = ST_SLT_WB;
            end

            ST_SLT_WB: begin
                alu_src_a   = 1;        // mantém A-B ativo para ula_menor ser valido
                alu_src_b   = 2'b00;
                alu_op      = 3'b010;
                reg_write   = 1;
                reg_dst     = 2'b01;    // rd
                mem_to_reg  = 3'd7;     // {31'b0, ula_menor}
                prox_estado = ST_FETCH1;
            end

            // ------------------------------------------------
            // ADDI
            // ------------------------------------------------
            ST_ADDI_EX: begin
                alu_src_a     = 1;      // A = rs
                alu_src_b     = 2'b10;  // sign_ext(imm)
                alu_op        = 3'b001; // soma
                alu_out_write = 1;
                prox_estado   = ST_ADDI_WB;
            end

            ST_ADDI_WB: begin
                reg_write   = 1;
                reg_dst     = 2'b00;    // rt
                mem_to_reg  = 3'd2;     // ALUOut
                prox_estado = ST_FETCH1;
            end

            // ------------------------------------------------
            // LW
            // ------------------------------------------------
            ST_LW_ADDR: begin
                alu_src_a     = 1;      // A = rs (base)
                alu_src_b     = 2'b10;  // sign_ext(offset)
                alu_op        = 3'b001; // soma
                alu_out_write = 1;      // ALUOut = endereco
                prox_estado   = ST_LW_MEM1;
            end

            ST_LW_MEM1: begin
                iord        = 1;        // endereco = ALUOut
                prox_estado = ST_LW_MEM2;
            end

            ST_LW_MEM2: begin
                iord        = 1;
                prox_estado = ST_LW_MDR;
            end

            ST_LW_MDR: begin
                iord        = 1;
                mdr_write   = 1;        // MDR <- dado da memoria
                prox_estado = ST_LW_WB;
            end

            ST_LW_WB: begin
                reg_write   = 1;
                reg_dst     = 2'b00;    // rt
                mem_to_reg  = 3'd0;     // MDR
                prox_estado = ST_FETCH1;
            end

            // ------------------------------------------------
            // SW
            // ------------------------------------------------
            ST_SW_ADDR: begin
                alu_src_a     = 1;      // A = rs (base)
                alu_src_b     = 2'b10;  // sign_ext(offset)
                alu_op        = 3'b001; // soma
                alu_out_write = 1;      // ALUOut = endereco
                prox_estado   = ST_SW_MEM;
            end

            ST_SW_MEM: begin
                iord        = 1;        // endereco = ALUOut
                mem_wr      = 1;        // escreve
                mem_wr_src  = 0;        // dado = B (rt)
                prox_estado = ST_FETCH1;
            end

            // ------------------------------------------------
            // BEQ: branch se rs == rt
            // ------------------------------------------------
            ST_BEQ: begin
                alu_src_a = 1;
                alu_src_b = 2'b00;
                alu_op    = 3'b010;     // sub → verifica ula_zero
                if (ula_zero) begin
                    pc_write  = 1;
                    pc_source = 3'd2;   // ALUOut = branch target do decode
                end
                prox_estado = ST_FETCH1;
            end

            // ------------------------------------------------
            // BNE: branch se rs != rt
            // ------------------------------------------------
            ST_BNE: begin
                alu_src_a = 1;
                alu_src_b = 2'b00;
                alu_op    = 3'b010;
                if (!ula_zero) begin
                    pc_write  = 1;
                    pc_source = 3'd2;
                end
                prox_estado = ST_FETCH1;
            end

            // ------------------------------------------------
            // J
            // ------------------------------------------------
            ST_J: begin
                pc_write    = 1;
                pc_source   = 3'd1;     // jump_addr
                prox_estado = ST_FETCH1;
            end

            // ------------------------------------------------
            // JAL: salva PC+4 em R31 e salta
            // ------------------------------------------------
            ST_JAL: begin
                alu_src_a   = 0;        // ULA A = PC (= PC+4 apos fetch)
                alu_op      = 3'b100;   // passa A → ula_saida = PC+4
                reg_write   = 1;
                reg_dst     = 2'b10;    // R31
                mem_to_reg  = 3'd1;     // ula_saida = PC+4
                pc_write    = 1;
                pc_source   = 3'd1;     // jump_addr
                prox_estado = ST_FETCH1;
            end

            // ------------------------------------------------
            // JR
            // ------------------------------------------------
            ST_JR: begin
                pc_write    = 1;
                pc_source   = 3'd3;     // a_out = rs
                prox_estado = ST_FETCH1;
            end

            // ------------------------------------------------
            // LUI
            // ------------------------------------------------
            ST_LUI_WB: begin
                reg_write   = 1;
                reg_dst     = 2'b00;    // rt
                mem_to_reg  = 3'd5;     // {imm, 16'b0}
                prox_estado = ST_FETCH1;
            end

            // ------------------------------------------------
            // SLL (sll rd, rt, shamt)
            // RegDesloc.N = ir_shamt, Entrada = B (rt)
            // ------------------------------------------------
            ST_SLL_LOAD: begin
                shift_code  = 3'b001;   // carrega B no RegDesloc
                prox_estado = ST_SLL_EXEC;
            end

            ST_SLL_EXEC: begin
                shift_code  = 3'b010;   // desloca esquerda N vezes
                prox_estado = ST_SLL_WB;
            end

            ST_SLL_WB: begin
                reg_write   = 1;
                reg_dst     = 2'b01;    // rd
                mem_to_reg  = 3'd4;     // reg_desloc_out
                prox_estado = ST_FETCH1;
            end

            // ------------------------------------------------
            // SRA (sra rd, rt, shamt) — deslocamento aritmetico
            // ------------------------------------------------
            ST_SRA_LOAD: begin
                shift_code  = 3'b001;   // carrega B no RegDesloc
                prox_estado = ST_SRA_EXEC;
            end

            ST_SRA_EXEC: begin
                shift_code  = 3'b100;   // desloca direita aritmetico N vezes
                prox_estado = ST_SRA_WB;
            end

            ST_SRA_WB: begin
                reg_write   = 1;
                reg_dst     = 2'b01;    // rd
                mem_to_reg  = 3'd4;     // reg_desloc_out
                prox_estado = ST_FETCH1;
            end

            // ------------------------------------------------
            // LB (lb rt, offset(rs))
            // lb_extrator usa alu_out[1:0] para selecionar o byte
            // ------------------------------------------------
            ST_LB_ADDR: begin
                alu_src_a     = 1;      // A = rs
                alu_src_b     = 2'b10;  // sign_ext(offset)
                alu_op        = 3'b001; // soma
                alu_out_write = 1;      // ALUOut = endereco
                prox_estado   = ST_LB_MEM1;
            end

            ST_LB_MEM1: begin
                iord        = 1;        // endereco = ALUOut
                prox_estado = ST_LB_MEM2;
            end

            ST_LB_MEM2: begin
                iord        = 1;
                prox_estado = ST_LB_MDR;
            end

            ST_LB_MDR: begin
                iord        = 1;
                mdr_write   = 1;        // MDR <- palavra da memoria
                prox_estado = ST_LB_WB;
            end

            ST_LB_WB: begin
                reg_write   = 1;
                reg_dst     = 2'b00;    // rt
                mem_to_reg  = 3'd3;     // lb_out (byte extraido e estendido)
                prox_estado = ST_FETCH1;
            end

            // ------------------------------------------------
            // SB (sb rt, offset(rs))
            // le a palavra atual, substitui o byte e reescreve
            // sb_insersor usa alu_out[1:0] e b_out[7:0]
            // ------------------------------------------------
            ST_SB_ADDR: begin
                alu_src_a     = 1;      // A = rs
                alu_src_b     = 2'b10;  // sign_ext(offset)
                alu_op        = 3'b001; // soma
                alu_out_write = 1;      // ALUOut = endereco
                prox_estado   = ST_SB_READ1;
            end

            ST_SB_READ1: begin
                iord        = 1;        // le palavra atual da memoria
                prox_estado = ST_SB_READ2;
            end

            ST_SB_READ2: begin
                iord        = 1;
                prox_estado = ST_SB_MDR;
            end

            ST_SB_MDR: begin
                iord        = 1;
                mdr_write   = 1;        // MDR <- palavra antiga
                prox_estado = ST_SB_WRITE;
            end

            ST_SB_WRITE: begin
                iord        = 1;        // endereco = ALUOut
                mem_wr      = 1;        // escreve
                mem_wr_src  = 1;        // dado = sb_out (palavra com byte substituido)
                prox_estado = ST_FETCH1;
            end

            // ------------------------------------------------
            // MFHI (mfhi rd) — copia Hi para rd
            // ------------------------------------------------
            ST_MFHI_WB: begin
                mfhi_sel    = 1;        // seleciona hi_out
                reg_write   = 1;
                reg_dst     = 2'b01;    // rd
                mem_to_reg  = 3'd6;     // hilo_reg_out (= hi_out)
                prox_estado = ST_FETCH1;
            end

            // ------------------------------------------------
            // MFLO (mflo rd) — copia Lo para rd
            // ------------------------------------------------
            ST_MFLO_WB: begin
                mfhi_sel    = 0;        // seleciona lo_out
                reg_write   = 1;
                reg_dst     = 2'b01;    // rd
                mem_to_reg  = 3'd6;     // hilo_reg_out (= lo_out)
                prox_estado = ST_FETCH1;
            end

            // ------------------------------------------------
            // Inicializacao do SP apos reset: R29 = 227
            // ------------------------------------------------
            ST_SP_INIT: begin
                sp_init_sel = 1;        // d7 do MUX_Data = 32'd227
                reg_write   = 1;
                reg_dst     = 2'b11;    // R29
                mem_to_reg  = 3'd7;     // 227
                prox_estado = ST_FETCH1;
            end

            // ------------------------------------------------
            // PUSH (push rs): SP=SP-4; Mem[SP-4]=rs
            // ------------------------------------------------

            // Recarrega A=R29(SP) e B=rs (decode carregou A=rs e B=rt)
            ST_PUSH_READ: begin
                read_src_a  = 1;        // mux_read1 = R29
                read_src_b  = 1;        // mux_read2 = rs
                a_write     = 1;
                b_write     = 1;
                prox_estado = ST_PUSH_CALC;
            end

            // Calcula SP-4 → ALUOut (endereco de escrita)
            ST_PUSH_CALC: begin
                alu_src_a     = 1;      // A = R29 (SP)
                alu_src_b     = 2'b01;  // 4
                alu_op        = 3'b010; // sub: SP - 4
                alu_out_write = 1;
                prox_estado   = ST_PUSH_STR;
            end

            // Escreve rs em Mem[SP-4]
            ST_PUSH_STR: begin
                iord        = 1;        // endereco = ALUOut = SP-4
                mem_wr      = 1;
                mem_wr_src  = 0;        // dado = b_out = rs
                prox_estado = ST_PUSH_SPUP;
            end

            // Atualiza SP: R29 = SP-4 (ALUOut ainda tem SP-4)
            ST_PUSH_SPUP: begin
                reg_write   = 1;
                reg_dst     = 2'b11;    // R29
                mem_to_reg  = 3'd2;     // ALUOut = SP-4
                prox_estado = ST_FETCH1;
            end

            // ------------------------------------------------
            // POP (pop rd): rd=Mem[SP]; SP=SP+4
            // ------------------------------------------------

            // Recarrega A=R29(SP)
            ST_POP_READ: begin
                read_src_a  = 1;        // mux_read1 = R29
                a_write     = 1;
                prox_estado = ST_POP_ADDR;
            end

            // Coloca R29 em ALUOut para usar como endereco de leitura
            ST_POP_ADDR: begin
                alu_src_a     = 1;      // A = R29
                alu_op        = 3'b100; // passa A → ula_saida = R29
                alu_out_write = 1;      // ALUOut = R29
                prox_estado   = ST_POP_MEM1;
            end

            // Leitura de Mem[SP]: 2 ciclos de espera
            ST_POP_MEM1: begin
                iord        = 1;        // endereco = ALUOut = R29
                prox_estado = ST_POP_MEM2;
            end

            ST_POP_MEM2: begin
                iord        = 1;
                prox_estado = ST_POP_MDR;
            end

            ST_POP_MDR: begin
                iord        = 1;
                mdr_write   = 1;        // MDR = Mem[SP]
                prox_estado = ST_POP_WB;
            end

            // Escreve MDR em rd
            ST_POP_WB: begin
                reg_write   = 1;
                reg_dst     = 2'b01;    // rd
                mem_to_reg  = 3'd0;     // MDR
                prox_estado = ST_POP_SPUP;
            end

            // Atualiza SP: R29 = R29+4
            // Usa ula_saida direto (sem passar por ALUOut) para nao sobrescrever
            ST_POP_SPUP: begin
                alu_src_a   = 1;        // A = R29
                alu_src_b   = 2'b01;    // 4
                alu_op      = 3'b001;   // soma: R29+4
                reg_write   = 1;
                reg_dst     = 2'b11;    // R29
                mem_to_reg  = 3'd1;     // ula_saida = R29+4
                prox_estado = ST_FETCH1;
            end

            // ------------------------------------------------
            // MULT: start → espera → escreve Hi e Lo
            // ------------------------------------------------
            ST_MULT_START: begin
                mult_start  = 1;
                prox_estado = ST_MULT_WAIT;
            end

            ST_MULT_WAIT: begin
                if (mult_done)
                    prox_estado = ST_MULT_WB;
                else
                    prox_estado = ST_MULT_WAIT;
            end

            ST_MULT_WB: begin
                hi_write    = 1;
                lo_write    = 1;
                hilo_src    = 0;        // resultado vem do multiplicador
                prox_estado = ST_FETCH1;
            end

            // ------------------------------------------------
            // DIV: start → espera → escreve Hi e Lo
            // div_zero gera excecao (tratamento pendente)
            // ------------------------------------------------
            ST_DIV_START: begin
                div_start   = 1;
                prox_estado = ST_DIV_WAIT;
            end

            ST_DIV_WAIT: begin
                if (div_done)
                    prox_estado = ST_DIV_WB;
                else if (div_zero)
                    prox_estado = ST_EXCEP_EPC;  // excecao de divisao por zero
                else
                    prox_estado = ST_DIV_WAIT;
            end

            ST_DIV_WB: begin
                hi_write    = 1;
                lo_write    = 1;
                hilo_src    = 1;        // resultado vem do divisor
                prox_estado = ST_FETCH1;
            end

            // ------------------------------------------------
            // Estados a implementar (excecoes, rte)
            // ------------------------------------------------
            default: prox_estado = ST_FETCH1;

        endcase
    end

endmodule
