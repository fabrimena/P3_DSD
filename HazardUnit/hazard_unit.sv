// ============================================================
// Detecta y resuelve hazards en el pipeline RV32I de 5 etapas
//
// FORWARDING (EX hazard y MEM hazard):
//   ForwardA/B = 00 : usar dato del banco de registros (ID/EX)
//              = 10 : forwarding desde EX/MEM (resultado ALU)
//              = 01 : forwarding desde MEM/WB (writeback)
//
// STALL (load-use hazard):
//   Cuando la instrucción en EX es LOAD y su rd coincide con
//   rs1 o rs2 de la instrucción en ID → stall 1 ciclo
//
// FLUSH:
//   Cuando se toma un salto (PCSrc=1 resuelto en EX) →
//   vaciar IF/ID e ID/EX (insertar 2 NOPs)
// ============================================================
`timescale 1ns/1ps

module hazard_unit (
    // Fuentes de la instrucción en ID/EX
    input  logic [4:0] ID_EX_rs1,
    input  logic [4:0] ID_EX_rs2,
    input  logic       ID_EX_ResultSrc1,   // bit[0] de ResultSrc; 1 = LOAD
    input  logic [4:0] ID_EX_rd,

    // Destinos de EX/MEM y MEM/WB (para forwarding)
    input  logic [4:0] EX_MEM_rd,
    input  logic       EX_MEM_RegWrite,
    input  logic [4:0] MEM_WB_rd,
    input  logic       MEM_WB_RegWrite,

    // Rs de la instrucción en IF/ID (para stall)
    input  logic [4:0] IF_ID_rs1,
    input  logic [4:0] IF_ID_rs2,

    // Indicador de salto tomado (viene de la etapa EX)
    input  logic       PCSrc,

    // Salidas de forwarding
    output logic [1:0] ForwardA,  // mux para ALU entrada A
    output logic [1:0] ForwardB,  // mux para ALU entrada B

    // Control de stall / flush
    output logic       stall,      // congela IF/ID y PC
    output logic       flush_ID_EX // vacía ID/EX (burbuja por stall o salto)
);

    // ----------------------------------------------------------
    // Forwarding: prioridad EX/MEM > MEM/WB
    // ----------------------------------------------------------
    always_comb begin
        // Forward A
        if (EX_MEM_RegWrite && (EX_MEM_rd != 5'b0) && (EX_MEM_rd == ID_EX_rs1))
            ForwardA = 2'b10;   // desde EX/MEM
        else if (MEM_WB_RegWrite && (MEM_WB_rd != 5'b0) && (MEM_WB_rd == ID_EX_rs1))
            ForwardA = 2'b01;   // desde MEM/WB
        else
            ForwardA = 2'b00;   // sin forwarding

        // Forward B
        if (EX_MEM_RegWrite && (EX_MEM_rd != 5'b0) && (EX_MEM_rd == ID_EX_rs2))
            ForwardB = 2'b10;
        else if (MEM_WB_RegWrite && (MEM_WB_rd != 5'b0) && (MEM_WB_rd == ID_EX_rs2))
            ForwardB = 2'b01;
        else
            ForwardB = 2'b00;
    end

    // ----------------------------------------------------------
    // Detección de load-use hazard
    // LOAD: ResultSrc[0] == 1 (2'b01)
    // ----------------------------------------------------------
    logic load_use_hazard;
    assign load_use_hazard = ID_EX_ResultSrc1 &&
                             ((ID_EX_rd == IF_ID_rs1) || (ID_EX_rd == IF_ID_rs2)) &&
                             (ID_EX_rd != 5'b0);

    // ----------------------------------------------------------
    // Stall: congelar PC e IF/ID, insertar burbuja en ID/EX
    // Flush: cuando el salto se resuelve en EX (PCSrc=1)
    //        se vacían IF/ID e ID/EX (2 instrucciones fetched de más)
    // ----------------------------------------------------------
    assign stall      = load_use_hazard;
    assign flush_ID_EX = load_use_hazard || PCSrc;

endmodule