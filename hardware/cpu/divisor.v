// Divisor sequencial - a ser implementado
// hi = resto, lo = quociente
module divisor(
    input         clk,
    input         reset,
    input         start,
    input  [31:0] A,
    input  [31:0] B,
    output [31:0] hi,
    output [31:0] lo,
    output        done,
    output        div_zero
);
    assign hi       = 32'b0;
    assign lo       = 32'b0;
    assign done     = 1'b0;
    assign div_zero = 1'b0;
endmodule
