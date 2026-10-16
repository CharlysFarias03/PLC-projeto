// extrai o byte correto do MDR e estende o sinal para 32 bits
// addr[1:0] indica qual byte da palavra (little-endian)
module lb_extrator(
    input  [31:0] dado,
    input  [1:0]  addr,
    output reg [31:0] saida
);
    reg [7:0] byte_sel;

    always @(*) begin
        case (addr)
            2'd0: byte_sel = dado[7:0];
            2'd1: byte_sel = dado[15:8];
            2'd2: byte_sel = dado[23:16];
            2'd3: byte_sel = dado[31:24];
        endcase
        saida = {{24{byte_sel[7]}}, byte_sel};
    end
endmodule
