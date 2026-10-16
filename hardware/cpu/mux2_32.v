module mux2_32(
    input        sel,
    input  [31:0] d0,
    input  [31:0] d1,
    output [31:0] saida
);
    assign saida = sel ? d1 : d0;
endmodule
