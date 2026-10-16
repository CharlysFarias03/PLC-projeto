// insere um byte em uma palavra sem modificar os outros bytes
// usado pelo store byte (sb): le a palavra antiga da memoria (MDR),
// substitui o byte indicado por addr[1:0] e devolve a palavra modificada
module sb_insersor(
    input  [31:0] dado_mem,
    input  [7:0]  byte_novo,
    input  [1:0]  addr,
    output reg [31:0] saida
);
    always @(*) begin
        saida = dado_mem;
        case (addr)
            2'd0: saida[7:0]   = byte_novo;
            2'd1: saida[15:8]  = byte_novo;
            2'd2: saida[23:16] = byte_novo;
            2'd3: saida[31:24] = byte_novo;
        endcase
    end
endmodule
