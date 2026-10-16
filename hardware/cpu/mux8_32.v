// MUX_Data (MemtoReg): escolhe o dado escrito no banco de registradores
// 0=MDR(lw)  1=PC+4(jal)  2=ALUOut  3=LB  4=shift(sll/sra)  5=lui  6=Hi/Lo  7=slt
module mux8_32(
    input  [2:0]  sel,
    input  [31:0] d0, d1, d2, d3, d4, d5, d6, d7,
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
            3'd6: saida = d6;
            3'd7: saida = d7;
        endcase
    end
endmodule
