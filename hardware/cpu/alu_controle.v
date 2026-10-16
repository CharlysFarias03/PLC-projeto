// decodifica alu_op + funct -> seletor da ULA
// alu_op vem da unidade de controle:
//   000 = R-type (usa funct)
//   001 = soma  (addi, lw, sw, lb, sb, push/pop)
//   010 = sub   (beq, bne: verifica ula_zero)
//   011 = and
//   100 = passa A (nao usa resultado da ULA)
module alu_controle(
    input  [2:0] alu_op,
    input  [5:0] funct,
    output reg [2:0] seletor
);
    parameter F_ADD = 6'h20;
    parameter F_SUB = 6'h22;
    parameter F_AND = 6'h24;
    parameter F_SLT = 6'h2a;

    always @(*) begin
        case (alu_op)
            3'b000: begin
                case (funct)
                    F_ADD:   seletor = 3'b001;
                    F_SUB:   seletor = 3'b010;
                    F_AND:   seletor = 3'b011;
                    F_SLT:   seletor = 3'b010;
                    default: seletor = 3'b001;
                endcase
            end
            3'b001: seletor = 3'b001;
            3'b010: seletor = 3'b010;
            3'b011: seletor = 3'b011;
            3'b100: seletor = 3'b000;
            default: seletor = 3'b001;
        endcase
    end
endmodule
