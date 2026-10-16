// Multiplicador de Booth - a ser implementado
module multiplicador(
    input         clk,
    input         reset,
    input         start,
    input  [31:0] A,
    input  [31:0] B,
    output [63:0] resultado,
    output        done
);
    assign resultado = 64'b0;
    assign done      = 1'b0;
endmodule
