// MUX_PC (PCSource): escolhe o proximo valor do PC
// 0=PC+4, 1=jump, 2=branch, 3=jr(rs), 4=RTE(EPC), 5=excecao
module mux6_32(
    input  [2:0]  sel,
    input  [31:0] d0, d1, d2, d3, d4, d5,
    output reg [31:0] saida
);
    always @(*) begin
        case (sel)
            3'd0: saida = d0;
            3'd1: saida = d1;
            3'd2: saida = d2;
            3'd3: saida = d3;
            3'd4: saida = d4;
            3'd5: saida = d5;
            default: saida = d0;
        endcase
    end
endmodule
