// ============================================================
// Registros de segmentación del pipeline RV32I de 5 etapas:
//   IF/ID  →  ID/EX  →  EX/MEM  →  MEM/WB
// ============================================================
`timescale 1ns/1ps

// ----------------------------------------------------------
// Registro IF/ID
// Captura instrucción y PC al final de la etapa IF
// ----------------------------------------------------------
module reg_IF_ID (
    input  logic        clk, rst,
    input  logic        stall,   // 1 = congelar (load-use hazard)
    input  logic        flush,   // 1 = insertar NOP (branch taken)
    input  logic [31:0] PC_in,
    input  logic [31:0] PCplus4_in,
    input  logic [31:0] instr_in,
    output logic [31:0] PC_out,
    output logic [31:0] PCplus4_out,
    output logic [31:0] instr_out
);
    always_ff @(posedge clk) begin
        if (rst || flush) begin
            PC_out      <= 32'b0;
            PCplus4_out <= 32'b0;
            instr_out   <= 32'b0;   // NOP = 0x00000000
        end else if (!stall) begin
            PC_out      <= PC_in;
            PCplus4_out <= PCplus4_in;
            instr_out   <= instr_in;
        end
        // Si stall: mantiene los valores actuales
    end
endmodule

// ----------------------------------------------------------
// Registro ID/EX
// Captura señales de control y datos de la etapa ID
// ----------------------------------------------------------
module reg_ID_EX (
    input  logic        clk, rst,
    input  logic        flush,       // flush por branch/jump resuelto en EX
    // Señales de control
    input  logic        RegWrite_in,
    input  logic [1:0]  ResultSrc_in,
    input  logic        MemWriteEn_in,
    input  logic [1:0]  MemWrite_in,
    input  logic        ALUSrc_in,
    input  logic [3:0]  ALUControl_in,
    input  logic [2:0]  BitSel_in,
    input  logic        Sh_in,
    input  logic        Jump_in,
    input  logic        Branch_in,
    // Datos
    input  logic [31:0] PC_in,
    input  logic [31:0] PCplus4_in,
    input  logic [31:0] rdata1_in,
    input  logic [31:0] rdata2_in,
    input  logic [31:0] imm_in,
    input  logic [4:0]  rd_in,
    input  logic [4:0]  rs1_in,
    input  logic [4:0]  rs2_in,
    input  logic [6:0]  opcode_in,
    input  logic [2:0]  funct3_in,
    // Salidas
    output logic        RegWrite_out,
    output logic [1:0]  ResultSrc_out,
    output logic        MemWriteEn_out,
    output logic [1:0]  MemWrite_out,
    output logic        ALUSrc_out,
    output logic [3:0]  ALUControl_out,
    output logic [2:0]  BitSel_out,
    output logic        Sh_out,
    output logic        Jump_out,
    output logic        Branch_out,
    output logic [31:0] PC_out,
    output logic [31:0] PCplus4_out,
    output logic [31:0] rdata1_out,
    output logic [31:0] rdata2_out,
    output logic [31:0] imm_out,
    output logic [4:0]  rd_out,
    output logic [4:0]  rs1_out,
    output logic [4:0]  rs2_out,
    output logic [6:0]  opcode_out,
    output logic [2:0]  funct3_out
);
    always_ff @(posedge clk) begin
        if (rst || flush) begin
            RegWrite_out    <= 0; ResultSrc_out <= 0;
            MemWriteEn_out  <= 0; MemWrite_out  <= 0;
            ALUSrc_out      <= 0; ALUControl_out <= 0;
            BitSel_out      <= 0; Sh_out         <= 0;
            Jump_out        <= 0; Branch_out     <= 0;
            PC_out          <= 0; PCplus4_out    <= 0;
            rdata1_out      <= 0; rdata2_out     <= 0;
            imm_out         <= 0; rd_out         <= 0;
            rs1_out         <= 0; rs2_out        <= 0;
            opcode_out      <= 0; funct3_out     <= 0;
        end else begin
            RegWrite_out    <= RegWrite_in;   ResultSrc_out  <= ResultSrc_in;
            MemWriteEn_out  <= MemWriteEn_in; MemWrite_out   <= MemWrite_in;
            ALUSrc_out      <= ALUSrc_in;     ALUControl_out <= ALUControl_in;
            BitSel_out      <= BitSel_in;     Sh_out         <= Sh_in;
            Jump_out        <= Jump_in;       Branch_out     <= Branch_in;
            PC_out          <= PC_in;         PCplus4_out    <= PCplus4_in;
            rdata1_out      <= rdata1_in;     rdata2_out     <= rdata2_in;
            imm_out         <= imm_in;        rd_out         <= rd_in;
            rs1_out         <= rs1_in;        rs2_out        <= rs2_in;
            opcode_out      <= opcode_in;     funct3_out     <= funct3_in;
        end
    end
endmodule

// ----------------------------------------------------------
// Registro EX/MEM
// ----------------------------------------------------------
module reg_EX_MEM (
    input  logic        clk, rst,
    // Control
    input  logic        RegWrite_in,
    input  logic [1:0]  ResultSrc_in,
    input  logic        MemWriteEn_in,
    input  logic [1:0]  MemWrite_in,
    input  logic [2:0]  BitSel_in,
    // Datos
    input  logic [31:0] PCplus4_in,
    input  logic [31:0] ALUResult_in,
    input  logic [31:0] rdata2_in,
    input  logic [31:0] imm_in,
    input  logic [4:0]  rd_in,
    // Salidas
    output logic        RegWrite_out,
    output logic [1:0]  ResultSrc_out,
    output logic        MemWriteEn_out,
    output logic [1:0]  MemWrite_out,
    output logic [2:0]  BitSel_out,
    output logic [31:0] PCplus4_out,
    output logic [31:0] ALUResult_out,
    output logic [31:0] rdata2_out,
    output logic [31:0] imm_out,
    output logic [4:0]  rd_out
);
    always_ff @(posedge clk) begin
        if (rst) begin
            RegWrite_out   <= 0; ResultSrc_out  <= 0;
            MemWriteEn_out <= 0; MemWrite_out   <= 0;
            BitSel_out     <= 0; PCplus4_out    <= 0;
            ALUResult_out  <= 0; rdata2_out     <= 0;
            imm_out        <= 0; rd_out         <= 0;
        end else begin
            RegWrite_out   <= RegWrite_in;   ResultSrc_out  <= ResultSrc_in;
            MemWriteEn_out <= MemWriteEn_in; MemWrite_out   <= MemWrite_in;
            BitSel_out     <= BitSel_in;     PCplus4_out    <= PCplus4_in;
            ALUResult_out  <= ALUResult_in;  rdata2_out     <= rdata2_in;
            imm_out        <= imm_in;        rd_out         <= rd_in;
        end
    end
endmodule

// ----------------------------------------------------------
// Registro MEM/WB
// ----------------------------------------------------------
module reg_MEM_WB (
    input  logic        clk, rst,
    // Control
    input  logic        RegWrite_in,
    input  logic [1:0]  ResultSrc_in,
    // Datos
    input  logic [31:0] PCplus4_in,
    input  logic [31:0] ALUResult_in,
    input  logic [31:0] mem_rdata_in,
    input  logic [31:0] imm_in,
    input  logic [4:0]  rd_in,
    // Salidas
    output logic        RegWrite_out,
    output logic [1:0]  ResultSrc_out,
    output logic [31:0] PCplus4_out,
    output logic [31:0] ALUResult_out,
    output logic [31:0] mem_rdata_out,
    output logic [31:0] imm_out,
    output logic [4:0]  rd_out
);
    always_ff @(posedge clk) begin
        if (rst) begin
            RegWrite_out  <= 0; ResultSrc_out <= 0;
            PCplus4_out   <= 0; ALUResult_out <= 0;
            mem_rdata_out <= 0; imm_out       <= 0;
            rd_out        <= 0;
        end else begin
            RegWrite_out  <= RegWrite_in;   ResultSrc_out <= ResultSrc_in;
            PCplus4_out   <= PCplus4_in;    ALUResult_out <= ALUResult_in;
            mem_rdata_out <= mem_rdata_in;  imm_out       <= imm_in;
            rd_out        <= rd_in;
        end
    end
endmodule