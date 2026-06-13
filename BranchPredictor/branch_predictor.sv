// ============================================================
// Contiene dos tablas indexadas por PC[7:2] (64 entradas):
//   BHT — Branch History Table: estado FSM de 2 bits
//   BTB — Branch Target Buffer:  dirección destino de 32 bits
//
// Interfaz:
//   ETAPA IF  → consulta (pc_if, is_branch_if)
//              ← predicción (bp_taken, bp_target)
//   ETAPA EX  → actualización (update_en, branch_taken_ex,
//                              pc_ex, pc_target_ex)
//
// La FSM se sintetiza como máquina de estados registrada
// (always_ff). Cada entrada de la BHT tiene su propio estado.
// ============================================================
`timescale 1ns/1ps

module branch_predictor #(
    parameter int ENTRIES = 64   // potencia de 2; usa PC[log2(ENTRIES)+1 : 2]
)(
    input  logic        clk,
    input  logic        rst,

    // ── Consulta desde etapa IF ──────────────────────────────
    input  logic [31:0] pc_if,          // PC de la instrucción en IF
    input  logic        is_branch_if,   // 1 si la instrucción es B/JAL/JALR

    // ── Salidas de predicción hacia el mux del PC ────────────
    output logic        bp_taken,       // 1 = predecir salto tomado
    output logic [31:0] bp_target,      // dirección predicha

    // ── Actualización desde etapa EX ────────────────────────
    input  logic        update_en,      // 1 cuando resuelve un branch/jump
    input  logic        branch_taken_ex,// resultado real del salto
    input  logic [31:0] pc_ex,          // PC de la instrucción que generó el salto
    input  logic [31:0] pc_target_ex    // dirección real calculada en EX
);

    // ── Parámetros internos ──────────────────────────────────
    localparam int IDX_BITS = $clog2(ENTRIES);   // = 6 para 64 entradas

    // ── Definición de la FSM (2-bit saturating counter) ─────
    // Representada como tipo enumerado para síntesis clara
    typedef enum logic [1:0] {
        STRONGLY_NOT_TAKEN = 2'b00,
        NOT_TAKEN          = 2'b01,
        TAKEN              = 2'b10,
        STRONGLY_TAKEN     = 2'b11
    } state_t;

    // ── Tablas de predicción ─────────────────────────────────
    state_t bht [0:ENTRIES-1];   // Branch History Table
    logic [31:0] btb [0:ENTRIES-1];   // Branch Target Buffer

    // ── Índices de acceso ────────────────────────────────────
    logic [IDX_BITS-1:0] idx_if;
    logic [IDX_BITS-1:0] idx_ex;

    assign idx_if = pc_if[IDX_BITS+1 : 2];
    assign idx_ex = pc_ex[IDX_BITS+1 : 2];

    // ── Reset e inicialización de tablas ─────────────────────
    // Quartus infiere BRAM si se usa un loop en always_ff con
    // reset síncrono. Para FPGAs con inicialización en BRAM
    // puede usarse también initial, pero always_ff es más seguro.
    integer i;
    always_ff @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < ENTRIES; i++) begin
                bht[i] <= NOT_TAKEN;   // estado inicial conservador
                btb[i] <= 32'b0;
            end
        end else if (update_en) begin
            // ── Actualización del BTB ──────────────────────
            btb[idx_ex] <= pc_target_ex;

            // ── Transición de la FSM (una instancia por entrada) ──
            case (bht[idx_ex])
                STRONGLY_NOT_TAKEN:
                    bht[idx_ex] <= branch_taken_ex ? NOT_TAKEN
                                                   : STRONGLY_NOT_TAKEN; // saturación

                NOT_TAKEN:
                    bht[idx_ex] <= branch_taken_ex ? TAKEN
                                                   : STRONGLY_NOT_TAKEN;

                TAKEN:
                    bht[idx_ex] <= branch_taken_ex ? STRONGLY_TAKEN
                                                   : NOT_TAKEN;

                STRONGLY_TAKEN:
                    bht[idx_ex] <= branch_taken_ex ? STRONGLY_TAKEN       // saturación
                                                   : TAKEN;

                default:
                    bht[idx_ex] <= NOT_TAKEN;
            endcase
        end
    end

    // ── Lógica de predicción (combinacional, lee BHT/BTB) ───
    // Solo predice si la instrucción actual ES un branch/jump
    always_comb begin
        if (is_branch_if) begin
            // predice "tomado" cuando el estado es TAKEN o STRONGLY_TAKEN
            bp_taken  = bht[idx_if][1];   // bit[1] == 1 ↔ {TAKEN, STRONGLY_TAKEN}
            bp_target = btb[idx_if];
        end else begin
            bp_taken  = 1'b0;
            bp_target = 32'b0;
        end
    end

endmodule