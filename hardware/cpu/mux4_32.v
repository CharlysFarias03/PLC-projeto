module mux4_32(
    input  [1:0]  sel,
    input  [31:0] d0, d1, d2, d3,
    output [31:0] saida
);
    assign saida = sel[1] ? (sel[0] ? d3 : d2)
                          : (sel[0] ? d1 : d0);
endmodule
