// ============================================================
// main_decoder.sv
// ============================================================
//
// Señales de control generadas:
//   RegWrite        - Habilitar escritura en banco de registros
//   ImmSrc  [2:0]  - Tipo de inmediato (000=I, 001=S, 010=B, 011=J, 100=U)
//   ALUSrc          - 0=Registro, 1=Inmediato
//   MemWrite [1:0]  - Word enable memoria (00=word, 01=half, 10=byte)
//   ResultSrc[1:0]  - 00=ALUResult, 01=ReadData, 10=PC+4, 11=UpperImm
//   Branch          - Habilitar lógica de branch
//   Jump            - Jump incondicional (jal/jalr)
//   BitSel  [2:0]  - Tipo de load (000=lw,001=lh,010=lb,011=lhu,100=lbu)
//   Sh              - 1=apagar 27 MSB (dejar 5 LSB) para shifts
//   ALUOp   [1:0]  - Para ALU Decoder
// ============================================================
`timescale 1ns/1ps
module main_decoder (
    input  logic [6:0] op,
    input  logic [2:0] funct3,
    output logic       RegWrite,
    output logic [2:0] ImmSrc,
    output logic       ALUSrc,
    output logic [1:0] MemWrite,
    output logic       MemWriteEn,
    output logic [1:0] ResultSrc,
    output logic       Branch,
    output logic       Jump,
    output logic [2:0] BitSel,
    output logic       Sh,
    output logic [1:0] ALUOp
);

    // Opcodes RV32I
    localparam LOAD   = 7'b0000011;
    localparam STORE  = 7'b0100011;
    localparam RTYPE  = 7'b0110011;
    localparam ITYPE  = 7'b0010011;
    localparam BRANCH = 7'b1100011;
    localparam JAL    = 7'b1101111;
    localparam JALR   = 7'b1100111;
    localparam LUI    = 7'b0110111;

    always_comb begin
        // Defaults seguros
        RegWrite  = 1'b0;
        ImmSrc    = 3'b000;
        ALUSrc    = 1'b0;
        MemWrite = 2'b00; MemWriteEn = 0;
        ResultSrc = 2'b00;
        Branch    = 1'b0;
        Jump      = 1'b0;
        BitSel    = 3'b000;
        Sh        = 1'b0;
        ALUOp     = 2'b00;

        case (op)

            // --------------------------------------------------
            // LOAD: lw, lh, lb, lhu, lbu
            // --------------------------------------------------
            LOAD: begin
                RegWrite  = 1'b1;
                ImmSrc    = 3'b000;
                ALUSrc    = 1'b1;
                MemWrite = 2'b00; MemWriteEn = 0;
                ResultSrc = 2'b01;
                Branch    = 1'b0;
                Jump      = 1'b0;
                Sh        = 1'b0;
                ALUOp     = 2'b00;  // ADD para dirección
                case (funct3)
                    3'b010: BitSel = 3'b000; // lw
                    3'b001: BitSel = 3'b001; // lh
                    3'b000: BitSel = 3'b010; // lb
                    3'b101: BitSel = 3'b011; // lhu
                    3'b100: BitSel = 3'b100; // lbu
                    default: BitSel = 3'b000;
                endcase
            end

            // --------------------------------------------------
            // STORE: sw, sh, sb
            // --------------------------------------------------
            STORE: begin
                RegWrite  = 1'b0;
                ImmSrc    = 3'b001;
                ALUSrc    = 1'b1;
                ResultSrc = 2'b00;
                Branch    = 1'b0;
                Jump      = 1'b0;
                BitSel    = 3'b000;
                Sh        = 1'b0;
                ALUOp     = 2'b00;  // ADD para dirección
                case (funct3)
                    3'b010: begin MemWrite = 2'b00; MemWriteEn = 1; end // sw
                    3'b001: begin MemWrite = 2'b01; MemWriteEn = 1; end // sh
                    3'b000: begin MemWrite = 2'b10; MemWriteEn = 1; end // sb
                    default: MemWrite = 2'b00;
                endcase
            end

            // --------------------------------------------------
            // R-TYPE: add, sub, and, or, xor, sll, srl, sra, slt, sltu
            // Sh=1 solo para shifts (funct3=001 o funct3=101)
            // --------------------------------------------------
            RTYPE: begin
                RegWrite  = 1'b1;
                ImmSrc    = 3'b000;
                ALUSrc    = 1'b0;
                MemWrite = 2'b00; MemWriteEn = 0;
                ResultSrc = 2'b00;
                Branch    = 1'b0;
                Jump      = 1'b0;
                BitSel    = 3'b000;
                ALUOp     = 2'b10;
                // Sh activo solo en instrucciones de shift
                Sh = (funct3 == 3'b001 || funct3 == 3'b101) ? 1'b1 : 1'b0;
            end

            // --------------------------------------------------
            // I-TYPE ALU: addi, andi, ori, xori, slli, srli, srai, slti, sltiu
            // Sh=1 solo para shifts (funct3=001 o funct3=101)
            // --------------------------------------------------
            ITYPE: begin
                RegWrite  = 1'b1;
                ImmSrc    = 3'b000;
                ALUSrc    = 1'b1;
                MemWrite = 2'b00; MemWriteEn = 0;
                ResultSrc = 2'b00;
                Branch    = 1'b0;
                Jump      = 1'b0;
                BitSel    = 3'b000;
                ALUOp     = 2'b11;
                // Sh activo solo en instrucciones de shift
                Sh = (funct3 == 3'b001 || funct3 == 3'b101) ? 1'b1 : 1'b0;
            end

            // --------------------------------------------------
            // BRANCH: beq, bne, blt, bge
            // --------------------------------------------------
            BRANCH: begin
                RegWrite  = 1'b0;
                ImmSrc    = 3'b010;
                ALUSrc    = 1'b0;
                MemWrite = 2'b00; MemWriteEn = 0;
                ResultSrc = 2'b00;
                Branch    = 1'b1;
                Jump      = 1'b0;
                BitSel    = 3'b000;
                Sh        = 1'b0;
                ALUOp     = 2'b01;
            end

            // --------------------------------------------------
            // JAL
            // --------------------------------------------------
            JAL: begin
                RegWrite  = 1'b1;
                ImmSrc    = 3'b011;
                ALUSrc    = 1'b0;
                MemWrite = 2'b00; MemWriteEn = 0;
                ResultSrc = 2'b10;
                Branch    = 1'b0;
                Jump      = 1'b1;
                BitSel    = 3'b000;
                Sh        = 1'b0;
                ALUOp     = 2'b00;
            end

            // --------------------------------------------------
            // JALR
            // --------------------------------------------------
            JALR: begin
                RegWrite  = 1'b1;
                ImmSrc    = 3'b000;
                ALUSrc    = 1'b1;
                MemWrite = 2'b00; MemWriteEn = 0;
                ResultSrc = 2'b10;
                Branch    = 1'b0;
                Jump      = 1'b1;
                BitSel    = 3'b000;
                Sh        = 1'b0;
                ALUOp     = 2'b00;
            end

            // --------------------------------------------------
            // LUI
            // --------------------------------------------------
            LUI: begin
                RegWrite  = 1'b1;
                ImmSrc    = 3'b100;
                ALUSrc    = 1'b1;
                MemWrite = 2'b00; MemWriteEn = 0;
                ResultSrc = 2'b11;
                Branch    = 1'b0;
                Jump      = 1'b0;
                BitSel    = 3'b000;
                Sh        = 1'b0;
                ALUOp     = 2'b00;
            end

            default: begin
                RegWrite  = 1'b0;
                ImmSrc    = 3'b000;
                ALUSrc    = 1'b0;
                MemWrite = 2'b00; MemWriteEn = 0;
                ResultSrc = 2'b00;
                Branch    = 1'b0;
                Jump      = 1'b0;
                BitSel    = 3'b000;
                Sh        = 1'b0;
                ALUOp     = 2'b00;
            end
        endcase
    end

endmodule
