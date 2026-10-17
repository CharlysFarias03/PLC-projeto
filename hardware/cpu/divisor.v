// Divisor sequencial com sinal - 32 ciclos
// Algoritmo de divisao restoring sobre valores absolutos
// Hi = resto, Lo = quociente (com correcao de sinal ao final)
// div_zero = 1 quando B == 0 (lancado como excecao)
module divisor(
    input         clk,
    input         reset,
    input         start,
    input  [31:0] A,      // dividendo
    input  [31:0] B,      // divisor
    output [31:0] hi,     // resto
    output [31:0] lo,     // quociente
    output        done,
    output        div_zero
);
    reg [63:0] acc;        // {resto_parcial[31:0], quociente[31:0]}
    reg [31:0] div_salvo;  // |B| salvo no inicio
    reg [5:0]  count;
    reg        rodando;
    reg        pronto;
    reg        zero_flag;
    reg        neg_quoc;   // quociente deve ser negativo
    reg        neg_resto;  // resto deve ser negativo
    reg [31:0] hi_reg;
    reg [31:0] lo_reg;

    assign hi       = hi_reg;
    assign lo       = lo_reg;
    assign done     = pronto;
    assign div_zero = zero_flag;

    // valores absolutos das entradas
    wire [31:0] abs_a = A[31] ? (~A + 32'd1) : A;
    wire [31:0] abs_b = B[31] ? (~B + 32'd1) : B;

    // um passo da divisao restoring (combinacional)
    wire [63:0] deslocado  = {acc[62:0], 1'b0};
    wire [31:0] resto_tent = deslocado[63:32];
    wire        subtrai    = (resto_tent >= div_salvo);
    wire [31:0] novo_resto = subtrai ? (resto_tent - div_salvo) : resto_tent;
    wire [63:0] novo_acc   = {novo_resto, deslocado[31:1], subtrai};

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            acc       <= 0;
            div_salvo <= 0;
            count     <= 0;
            rodando   <= 0;
            pronto    <= 0;
            zero_flag <= 0;
            neg_quoc  <= 0;
            neg_resto <= 0;
            hi_reg    <= 0;
            lo_reg    <= 0;
        end else if (start && !rodando) begin
            if (B == 32'b0) begin
                zero_flag <= 1;
                pronto    <= 1;
            end else begin
                acc       <= {32'b0, abs_a};
                div_salvo <= abs_b;
                count     <= 0;
                rodando   <= 1;
                pronto    <= 0;
                zero_flag <= 0;
                neg_quoc  <= A[31] ^ B[31];
                neg_resto <= A[31];
            end
        end else if (rodando) begin
            acc <= novo_acc;

            if (count == 6'd31) begin
                rodando <= 0;
                pronto  <= 1;
                // corrige sinal do quociente
                lo_reg <= neg_quoc ? (~novo_acc[31:0] + 32'd1) : novo_acc[31:0];
                // corrige sinal do resto (segue sinal do dividendo)
                hi_reg <= neg_resto ? (~novo_acc[63:32] + 32'd1) : novo_acc[63:32];
            end else
                count <= count + 6'd1;
        end
    end
endmodule
