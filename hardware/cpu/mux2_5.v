// mux de 2 entradas para selecao de numero de registrador (5 bits)
// usado por MUX_Read1 (rs ou R29) e MUX_Read2 (rt ou rs)
module mux2_5(
    input        sel,
    input  [4:0] d0,
    input  [4:0] d1,
    output [4:0] saida
);
    assign saida = sel ? d1 : d0;
endmodule
