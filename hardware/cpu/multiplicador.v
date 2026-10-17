// Multiplicador de Booth - algoritmo radix-2, 32 ciclos
// Entradas A (multiplicando) e B (multiplicador), 32 bits com sinal
// Resultado de 64 bits: {acc[31:0], b_reg} → Hi = alto, Lo = baixo
module multiplicador(
    input         clk,
    input         reset,
    input         start,
    input  [31:0] A,
    input  [31:0] B,
    output [63:0] resultado,
    output        done
);
    reg [32:0] acc;       // acumulador de 33 bits (1 bit extra de sinal)
    reg [31:0] b_reg;     // registrador do multiplicador
    reg        q_prev;    // bit anterior do multiplicador (Q[-1])
    reg [5:0]  count;
    reg        rodando;
    reg        pronto;

    assign resultado = {acc[31:0], b_reg};
    assign done      = pronto;

    // sinal estendido de A para 33 bits
    wire [32:0] M = {A[31], A};

    // valor de acc apos a operacao (antes do deslocamento)
    // calculado combinacionalmente para poder ser deslocado no mesmo ciclo
    reg [32:0] acc_op;
    always @(*) begin
        case ({b_reg[0], q_prev})
            2'b01:   acc_op = acc + M;
            2'b10:   acc_op = acc - M;
            default: acc_op = acc;
        endcase
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            acc     <= 0;
            b_reg   <= 0;
            q_prev  <= 0;
            count   <= 0;
            rodando <= 0;
            pronto  <= 0;
        end else if (start && !rodando) begin
            acc     <= 33'b0;
            b_reg   <= B;
            q_prev  <= 1'b0;
            count   <= 0;
            rodando <= 1;
            pronto  <= 0;
        end else if (rodando) begin
            // deslocamento aritmetico direito de {acc_op, b_reg, q_prev}
            q_prev <= b_reg[0];
            b_reg  <= {acc_op[0], b_reg[31:1]};
            acc    <= {acc_op[32], acc_op[32:1]};

            if (count == 6'd31) begin
                rodando <= 0;
                pronto  <= 1;
            end else
                count <= count + 6'd1;
        end
    end
endmodule
