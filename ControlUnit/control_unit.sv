// ============================================================
// control_unit.sv
// Control Unit Top-Level (Main Decoder + ALU Decoder)
// ============================================================
//
// Entradas:
//   op        [6:0]  - Opcode de la instrucción
//   funct3    [2:0]  - Campo funct3
//   funct7    [6:0]  - Campo funct7
//   ALUFlags  [2:0]  - Flags ALU: [0]=Zero, [1]=Carry, [2]=Overflow
//   ALUMSB           - ALUResult[31], signo del resultado (para blt/bge)
//
// Salidas:
//   PCSrc            - 0=PC+4, 1=branch/jump target
//   ResultSrc  [1:0] - 00=ALUResult, 01=ReadData, 10=PC+4, 11=UpperImm
//   MemWrite   [1:0] - Word enable: 00=word, 01=half, 10=byte
//   ALUControl [3:0] - Operación ALU (compatible con ALU.sv)
//   ALUSrc           - 0=Registro, 1=Inmediato
//   ImmSrc     [2:0] - Tipo de inmediato
//   RegWrite         - Habilitar escritura en banco de registros
//   BitSel     [2:0] - Tipo de load para BitSelector
//   Sh               - 1=dejar solo 5 LSB del registro (para shifts)
// ============================================================

`timescale 1ns/1ps
module control_unit (
    input  logic [6:0] op,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,
    input  logic [2:0] ALUFlags,
    input  logic       ALUMSB,
    output logic       PCSrc,
    output logic [1:0] ResultSrc,
    output logic [1:0] MemWrite,
    output logic       MemWriteEn,
    output logic [3:0] ALUControl,
    output logic       ALUSrc,
    output logic [2:0] ImmSrc,
    output logic       RegWrite,
    output logic [2:0] BitSel,
    output logic       Sh
);

    // Señales internas
    logic [1:0] ALUOp;
    logic       Branch;
    logic       Jump;
    logic       BranchTaken;
    logic       Zero;

    assign Zero = ALUFlags[0];

    // ----------------------------------------------------------
    // Main Decoder
    // ----------------------------------------------------------
    main_decoder u_main_decoder (
        .op        (op),
        .funct3    (funct3),
        .RegWrite  (RegWrite),
        .ImmSrc    (ImmSrc),
        .ALUSrc    (ALUSrc),
        .MemWrite  (MemWrite),
        .MemWriteEn(MemWriteEn),
        .ResultSrc (ResultSrc),
        .Branch    (Branch),
        .Jump      (Jump),
        .BitSel    (BitSel),
        .Sh        (Sh),
        .ALUOp     (ALUOp)
    );

    // ----------------------------------------------------------
    // ALU Decoder
    // ----------------------------------------------------------
    alu_decoder u_alu_decoder (
        .ALUOp      (ALUOp),
        .funct3     (funct3),
        .funct7     (funct7),
        .ALUControl (ALUControl)
    );

    // ----------------------------------------------------------
    // Branch Taken logic
    // La ALU hace SUB para todas las branches
    //   beq:  Zero=1
    //   bne:  Zero=0
    //   blt:  ALUMSB=1 AND Zero=0  (resultado negativo → a < b)
    //   bge:  ALUMSB=0 OR  Zero=1  (resultado positivo o cero → a >= b)
    // ----------------------------------------------------------
    always_comb begin
        BranchTaken = 1'b0;
        if (Branch) begin
            case (funct3)
                3'b000: BranchTaken =  Zero;             // beq
                3'b001: BranchTaken = ~Zero;             // bne
                3'b100: BranchTaken =  ALUFlags[1];     // blt (Less)
                3'b101: BranchTaken = ~ALUFlags[1];     // bge (~Less)
                default: BranchTaken = 1'b0;
            endcase
        end
    end

    assign PCSrc = BranchTaken | Jump;

endmodule
