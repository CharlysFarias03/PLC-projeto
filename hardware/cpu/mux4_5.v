// usado pelo MUX_Reg (RegDst): seleciona qual registrador vai ser escrito
// 0=rt, 1=rd, 2=R31 (jal), 3=R29 (pop)
module mux4_5(
    input  [1:0] sel,
    input  [4:0] d0, d1, d2, d3,
    output [4:0] saida
);
    assign saida = sel[1] ? (sel[0] ? d3 : d2)
                          : (sel[0] ? d1 : d0);
endmodule
