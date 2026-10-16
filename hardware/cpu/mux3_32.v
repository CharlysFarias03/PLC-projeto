// seleciona o endereco do vetor de excecao: 253=opcode, 254=overflow, 255=divzero
module mux3_32(
    input  [1:0]  sel,
    input  [31:0] d0, d1, d2,
    output reg [31:0] saida
);
    always @(*) begin
        case (sel)
            2'd0: saida = d0;
            2'd1: saida = d1;
            2'd2: saida = d2;
            default: saida = d0;
        endcase
    end
endmodule
