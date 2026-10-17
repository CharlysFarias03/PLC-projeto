# ============================================================
# wave.do - Configuracao do waveform para simulacao da CPU MIPS
# Uso: no console do ModelSim, apos vsim work.cpu, execute:
#        do wave.do
#        run 2000ns
# ============================================================

onerror {resume}
quietly WaveActivateNextPane {} 0

# --------------------------------------------------------
# Clock e Reset
# --------------------------------------------------------
add wave -noupdate -divider "Clock / Reset"
add wave -noupdate                    /cpu/clk
add wave -noupdate                    /cpu/reset

# --------------------------------------------------------
# Unidade de Controle - estado da FSM
# --------------------------------------------------------
add wave -noupdate -divider "Controle (FSM)"
add wave -noupdate -radix unsigned    /cpu/CTRL/estado
add wave -noupdate -radix unsigned    /cpu/CTRL/prox_estado
add wave -noupdate -radix unsigned    /cpu/CTRL/excep_tipo

# --------------------------------------------------------
# Program Counter e registradores de proposito especial
# --------------------------------------------------------
add wave -noupdate -divider "PC / EPC / MDR / ALUOut"
add wave -noupdate -radix hexadecimal /cpu/pc_out
add wave -noupdate -radix hexadecimal /cpu/epc_out
add wave -noupdate -radix hexadecimal /cpu/mdr_out
add wave -noupdate -radix hexadecimal /cpu/alu_out

# --------------------------------------------------------
# Registrador de Instrucoes (IR)
# --------------------------------------------------------
add wave -noupdate -divider "Instrucao (IR)"
add wave -noupdate -radix hexadecimal /cpu/ir_opcode
add wave -noupdate -radix hexadecimal /cpu/ir_rs
add wave -noupdate -radix hexadecimal /cpu/ir_rt
add wave -noupdate -radix hexadecimal /cpu/ir_rd
add wave -noupdate -radix hexadecimal /cpu/ir_shamt
add wave -noupdate -radix hexadecimal /cpu/ir_funct

# --------------------------------------------------------
# Banco de Registradores - R29 (SP) e R31 (RA)
# (expanda BANCO/Cluster no Objects para ver todos)
# --------------------------------------------------------
add wave -noupdate -divider "Banco (R29=SP, R31=RA)"
add wave -noupdate -radix decimal     /cpu/BANCO/Cluster(29)
add wave -noupdate -radix decimal     /cpu/BANCO/Cluster(31)

# --------------------------------------------------------
# Registradores temporarios A e B
# --------------------------------------------------------
add wave -noupdate -divider "Reg A / B"
add wave -noupdate -radix hexadecimal /cpu/a_out
add wave -noupdate -radix hexadecimal /cpu/b_out

# --------------------------------------------------------
# ULA - resultado e flags
# --------------------------------------------------------
add wave -noupdate -divider "ULA"
add wave -noupdate -radix hexadecimal /cpu/ula_saida
add wave -noupdate                    /cpu/ula_zero
add wave -noupdate                    /cpu/ula_overflow
add wave -noupdate                    /cpu/ula_menor

# --------------------------------------------------------
# Memoria
# --------------------------------------------------------
add wave -noupdate -divider "Memoria"
add wave -noupdate -radix hexadecimal /cpu/mux_iord_out
add wave -noupdate -radix hexadecimal /cpu/mem_out

# --------------------------------------------------------
# Hi e Lo (multiplicacao / divisao)
# --------------------------------------------------------
add wave -noupdate -divider "Hi / Lo"
add wave -noupdate -radix hexadecimal /cpu/hi_out
add wave -noupdate -radix hexadecimal /cpu/lo_out

# --------------------------------------------------------
# Formatacao da janela
# --------------------------------------------------------
configure wave -namecolwidth  220
configure wave -valuecolwidth 130
configure wave -justifyvalue  left
configure wave -signalnamewidth 1
configure wave -timelineunits ns

update
WaveRestoreZoom {0 ns} {500 ns}
