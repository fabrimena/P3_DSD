// ============================================================
// Procesador RV32I Segmentado de 5 etapas
//   IF → ID → EX → MEM → WB
//
// Módulos sin cambios: ALU, control_unit, extend, reg_file,
//   single_port_ram, BitSelector, instructionMemory, pc_increment
// Módulos nuevos: pipeline_regs.sv, hazard_unit.sv
// ============================================================
`timescale 1ns / 1ps

module top (
    input logic clk,
    input logic rst
);

// ============================================================
// *** ETAPA IF: Instruction Fetch ***
// ============================================================

    logic        stall;
    logic        flush_ID_EX;
    logic        PCSrc_EX;
    logic [31:0] PCTarget_EX;

    logic        misprediction;

    logic [31:0] PC_IF;
    logic [31:0] PCplus4_IF;
    logic [31:0] PCnext;
    logic [31:0] PC_reg;
    logic [31:0] PC;

    // Detección rápida de instrucción de salto en IF
    // Necesaria para consultar el predictor antes de pasar a ID.
    // Usa solo el opcode (bits[6:0]) sin decodificación completa.
    logic [31:0] instr_IF;
    logic        is_branch_IF;

    localparam BRANCH_OP = 7'b1100011;
    localparam JAL_OP    = 7'b1101111;
    localparam JALR_OP   = 7'b1100111;

    assign is_branch_IF = (instr_IF[6:0] == BRANCH_OP) ||
                          (instr_IF[6:0] == JAL_OP)    ||
                          (instr_IF[6:0] == JALR_OP);

    // Salidas del predictor
    logic        bp_taken;
    logic [31:0] bp_target;

    // ── Adder PC+4 ──────────────────────────────────────────
    adder #(32) pc_adder_if (
        .a   (PC_reg),
        .b   (32'd4),
        .cin (1'b0),
        .y   (PCplus4_IF)
    );

    // ── Mux del PC: 3 prioridades ───────────────────────────
    //   Prioridad 1 (más alta): corrección EX  (misprediction)
    //   Prioridad 2: predicción del predictor  (bp_taken)
    //   Prioridad 3: PC+4 normal
    always_comb begin
        if (PCSrc_EX)           // corrección desde EX (misprediction o jump)
            PCnext = PCTarget_EX;
        else if (bp_taken)      // predicción temprana en IF
            PCnext = bp_target;
        else
            PCnext = PCplus4_IF;
    end

    // Registro PC con enable (stall lo congela)
    always_ff @(posedge clk) begin
        if (rst)
            PC_reg <= 32'b0;
        else if (!stall)
            PC_reg <= PCnext;
    end

    assign PC_IF = PC_reg;

    // Memoria de instrucciones
    instructionMemory instr_mem (
        .PC   (PC_IF[6:2]),
        .instr(instr_IF)
    );

    // ── Instancia del predictor ──────────────────────────────
    branch_predictor #(.ENTRIES(64)) u_bp (
        .clk            (clk),
        .rst            (rst),
        // Consulta desde IF
        .pc_if          (PC_IF),
        .is_branch_if   (is_branch_IF),
        // Predicción → mux PCnext
        .bp_taken       (bp_taken),
        .bp_target      (bp_target),
        // Actualización desde EX (resultado real)
        .update_en      (Branch_EX | Jump_EX),   // actualizar si era branch/jump
        .branch_taken_ex(PCSrc_EX),              // 1 = salto realmente tomado
        .pc_ex          (PC_EX),
        .pc_target_ex   (PCTarget_EX)
    );

    // ── Lógica de misprediction ──────────────────────────────
    // Hay misprediction cuando:
    //   a) El predictor dijo TOMADO pero el salto NO se tomó (bp_taken_EX & !PCSrc_EX)
    //   b) El predictor dijo NO TOMADO pero el salto SÍ se tomó (!bp_taken_EX & PCSrc_EX)
    // Se necesita propagar bp_taken a través del registro ID/EX.
    // (Ver sección ID/EX más abajo para la señal bp_taken_ID_EX)
    logic bp_taken_ID;    // valor predicho para la instrucción que ahora está en ID
    logic bp_taken_EX;    // valor predicho para la instrucción que ahora está en EX

    assign misprediction = (Branch_EX | Jump_EX) &
                           (bp_taken_EX ^ PCSrc_EX);

// ============================================================
// *** Registro IF/ID ***
// flush ahora usa misprediction en lugar de PCSrc_EX.
// Si el predictor acertó y el salto se tomó, IF/ID ya tiene la
// instrucción correcta (no hay burbuja). Solo se flushea si
// hubo error de predicción.
// ============================================================

    logic [31:0] PC_ID, PCplus4_ID, instr_ID;

    reg_IF_ID u_IF_ID (
        .clk        (clk),
        .rst        (rst),
        .stall      (stall),
        .flush      (misprediction),
        .PC_in      (PC_IF),
        .PCplus4_in (PCplus4_IF),
        .instr_in   (instr_IF),
        .PC_out     (PC_ID),
        .PCplus4_out(PCplus4_ID),
        .instr_out  (instr_ID)
    );

    // Propagación de bp_taken a través de IF/ID
    // (registro simple 1-bit, sin stall/flush propio porque si
    //  la instrucción se flushea, el valor no importa)
    always_ff @(posedge clk) begin
        if (rst || misprediction)
            bp_taken_ID <= 1'b0;
        else if (!stall)
            bp_taken_ID <= bp_taken;
    end

// ============================================================
// *** ETAPA ID: Instruction Decode ***
// (sin cambios en la lógica; solo se añade propagación de bp_taken)
// ============================================================

    logic [6:0] opcode_ID;
    logic [4:0] rd_ID, rs1_ID, rs2_ID;
    logic [2:0] funct3_ID;

    assign opcode_ID = instr_ID[6:0];
    assign funct3_ID = instr_ID[14:12];
    assign rd_ID     = instr_ID[11:7];

    always_comb begin
        rs1_ID = instr_ID[19:15];
        case(opcode_ID)
            7'b0110011,
            7'b0100011,
            7'b1100011:
                rs2_ID = instr_ID[24:20];
            default:
                rs2_ID = 5'b00000;
        endcase
    end

    logic       RegWrite_ID;
    logic [1:0] ResultSrc_ID;
    logic [1:0] MemWrite_ID;
    logic       MemWriteEn_ID;
    logic [3:0] ALUControl_ID;
    logic       ALUSrc_ID;
    logic [2:0] ImmSrc_ID;
    logic [2:0] BitSel_ID;
    logic       Sh_ID;
    logic       Jump_ID;
    logic       Branch_ID;
    logic [2:0] ALUFlags_ID;
    logic       PCSrc_ID_dummy;

    control_unit u_control (
        .op        (opcode_ID),
        .funct3    (funct3_ID),
        .funct7    (instr_ID[31:25]),
        .ALUFlags  (3'b000),
        .ALUMSB    (1'b0),
        .PCSrc     (PCSrc_ID_dummy),
        .ResultSrc (ResultSrc_ID),
        .MemWrite  (MemWrite_ID),
        .MemWriteEn(MemWriteEn_ID),
        .ALUControl(ALUControl_ID),
        .ALUSrc    (ALUSrc_ID),
        .ImmSrc    (ImmSrc_ID),
        .RegWrite  (RegWrite_ID),
        .BitSel    (BitSel_ID),
        .Sh        (Sh_ID)
    );

    assign Branch_ID = (opcode_ID == BRANCH_OP);
    assign Jump_ID   = (opcode_ID == JAL_OP) || (opcode_ID == JALR_OP);

    logic [31:0] imm_ID;
    extend u_imm_ext (
        .instr  (instr_ID),
        .ImmSrc (ImmSrc_ID),
        .ImmExt (imm_ID)
    );

    logic [31:0] rdata1_ID, rdata2_ID;
    logic [31:0] writeback_data_WB;
    logic        RegWrite_WB;
    logic [4:0]  rd_WB;

    reg_file #(32, 32) regs (
        .clk    (clk),
        .rst    (rst),
        .wr_en  (RegWrite_WB),
        .w_addr (rd_WB),
        .r0_addr(rs1_ID),
        .r1_addr(rs2_ID),
        .w_data (writeback_data_WB),
        .r0_data(rdata1_ID),
        .r1_data(rdata2_ID)
    );

// ============================================================
// *** Registro ID/EX ***
// flush ahora usa misprediction.
// Se añade propagación de bp_taken_ID → bp_taken_EX.
// ============================================================

    logic        RegWrite_EX;
    logic [1:0]  ResultSrc_EX;
    logic        MemWriteEn_EX;
    logic [1:0]  MemWrite_EX;
    logic        ALUSrc_EX;
    logic [3:0]  ALUControl_EX;
    logic [2:0]  BitSel_EX;
    logic        Sh_EX;
    logic        Jump_EX;
    logic        Branch_EX;
    logic [31:0] PC_EX, PCplus4_EX;
    logic [31:0] rdata1_EX, rdata2_EX;
    logic [31:0] imm_EX;
    logic [4:0]  rd_EX, rs1_EX, rs2_EX;
    logic [6:0]  opcode_EX;
    logic [2:0]  funct3_EX;

    reg_ID_EX u_ID_EX (
        .clk           (clk),           .rst          (rst),
        .flush         (flush_ID_EX),   // flush_ID_EX viene de hazard_unit (sin cambio)
        .RegWrite_in   (RegWrite_ID),   .RegWrite_out   (RegWrite_EX),
        .ResultSrc_in  (ResultSrc_ID),  .ResultSrc_out  (ResultSrc_EX),
        .MemWriteEn_in (MemWriteEn_ID), .MemWriteEn_out (MemWriteEn_EX),
        .MemWrite_in   (MemWrite_ID),   .MemWrite_out   (MemWrite_EX),
        .ALUSrc_in     (ALUSrc_ID),     .ALUSrc_out     (ALUSrc_EX),
        .ALUControl_in (ALUControl_ID), .ALUControl_out (ALUControl_EX),
        .BitSel_in     (BitSel_ID),     .BitSel_out     (BitSel_EX),
        .Sh_in         (Sh_ID),         .Sh_out         (Sh_EX),
        .Jump_in       (Jump_ID),       .Jump_out       (Jump_EX),
        .Branch_in     (Branch_ID),     .Branch_out     (Branch_EX),
        .PC_in         (PC_ID),         .PC_out         (PC_EX),
        .PCplus4_in    (PCplus4_ID),    .PCplus4_out    (PCplus4_EX),
        .rdata1_in     (rdata1_ID),     .rdata1_out     (rdata1_EX),
        .rdata2_in     (rdata2_ID),     .rdata2_out     (rdata2_EX),
        .imm_in        (imm_ID),        .imm_out        (imm_EX),
        .rd_in         (rd_ID),         .rd_out         (rd_EX),
        .rs1_in        (rs1_ID),        .rs1_out        (rs1_EX),
        .rs2_in        (rs2_ID),        .rs2_out        (rs2_EX),
        .opcode_in     (opcode_ID),     .opcode_out     (opcode_EX),
        .funct3_in     (funct3_ID),     .funct3_out     (funct3_EX)
    );

    // Propagación bp_taken: ID → EX (1 FF más, 1 bit)
    always_ff @(posedge clk) begin
        if (rst || flush_ID_EX)
            bp_taken_EX <= 1'b0;
        else
            bp_taken_EX <= bp_taken_ID;
    end

// ============================================================
// *** ETAPA EX: Execute ***
// (sin cambios internos; misprediction se calcula en IF)
// ============================================================

    logic [1:0] ForwardA, ForwardB;
    logic [31:0] ALUResult_MEM;

    logic [31:0] ALUin0_pre, ALUin1_pre;
    logic [31:0] ALUin0, ALUin1_reg;

    always_comb begin
        case (ForwardA)
            2'b00: ALUin0_pre = rdata1_EX;
            2'b10: ALUin0_pre = ALUResult_MEM;
            2'b01: ALUin0_pre = writeback_data_WB;
            default: ALUin0_pre = rdata1_EX;
        endcase
    end

    always_comb begin
        case (ForwardB)
            2'b00: ALUin1_pre = rdata2_EX;
            2'b10: ALUin1_pre = ALUResult_MEM;
            2'b01: ALUin1_pre = writeback_data_WB;
            default: ALUin1_pre = rdata2_EX;
        endcase
    end

    logic [31:0] ALUin0_sh, ALUin1_sh;
    assign ALUin0_sh = ALUin0_pre;
    assign ALUin1_sh = Sh_EX ? {27'b0, ALUin1_pre[4:0]} : ALUin1_pre;

    assign ALUin0      = ALUin0_sh;
    assign ALUin1_reg  = ALUSrc_EX ? imm_EX : ALUin1_sh;

    logic [31:0] ALUResult_EX;
    logic [2:0]  ALUFlags_EX;

    ALU #(32) u_alu (
        .a         (ALUin0),
        .b         (ALUin1_reg),
        .ALUControl(ALUControl_EX),
        .ALUResult (ALUResult_EX),
        .ALUFlags  (ALUFlags_EX)
    );

    logic BranchTaken_EX;
    always_comb begin
        BranchTaken_EX = 1'b0;
        if (Branch_EX) begin
            case (funct3_EX)
                3'b000: BranchTaken_EX =  ALUFlags_EX[0];
                3'b001: BranchTaken_EX = ~ALUFlags_EX[0];
                3'b100: BranchTaken_EX =  ALUFlags_EX[1];
                3'b101: BranchTaken_EX = ~ALUFlags_EX[1];
                default: BranchTaken_EX = 1'b0;
            endcase
        end
    end

    assign PCSrc_EX = BranchTaken_EX | Jump_EX;

    assign PCTarget_EX = (opcode_EX == JALR_OP) ?
                         (ALUResult_EX & ~32'd1) :
                         (PC_EX + imm_EX);

    logic [31:0] rdata2_fwd_EX;
    always_comb begin
        case (ForwardB)
            2'b00: rdata2_fwd_EX = rdata2_EX;
            2'b10: rdata2_fwd_EX = ALUResult_MEM;
            2'b01: rdata2_fwd_EX = writeback_data_WB;
            default: rdata2_fwd_EX = rdata2_EX;
        endcase
    end

// ============================================================
// *** Registro EX/MEM  —  sin cambios *** 
// ============================================================

    logic        RegWrite_MEM;
    logic [1:0]  ResultSrc_MEM;
    logic        MemWriteEn_MEM;
    logic [1:0]  MemWrite_MEM;
    logic [2:0]  BitSel_MEM;
    logic [31:0] PCplus4_MEM;
    logic [31:0] rdata2_MEM;
    logic [31:0] imm_MEM;
    logic [4:0]  rd_MEM;

    reg_EX_MEM u_EX_MEM (
        .clk           (clk),             .rst          (rst),
        .RegWrite_in   (RegWrite_EX),     .RegWrite_out   (RegWrite_MEM),
        .ResultSrc_in  (ResultSrc_EX),    .ResultSrc_out  (ResultSrc_MEM),
        .MemWriteEn_in (MemWriteEn_EX),   .MemWriteEn_out (MemWriteEn_MEM),
        .MemWrite_in   (MemWrite_EX),     .MemWrite_out   (MemWrite_MEM),
        .BitSel_in     (BitSel_EX),       .BitSel_out     (BitSel_MEM),
        .PCplus4_in    (PCplus4_EX),      .PCplus4_out    (PCplus4_MEM),
        .ALUResult_in  (ALUResult_EX),    .ALUResult_out  (ALUResult_MEM),
        .rdata2_in     (rdata2_fwd_EX),   .rdata2_out     (rdata2_MEM),
        .imm_in        (imm_EX),          .imm_out        (imm_MEM),
        .rd_in         (rd_EX),           .rd_out         (rd_MEM)
    );

// ============================================================
// *** ETAPA MEM  —  sin cambios ***
// ============================================================

    logic [3:0] ram_we;
    always_comb begin
        ram_we = 4'b0000;
        if (MemWriteEn_MEM) begin
            case (MemWrite_MEM)
                2'b00: ram_we = 4'b1111;
                2'b01: ram_we = (ALUResult_MEM[1] == 1'b0) ? 4'b0011 : 4'b1100;
                2'b10: begin
                    case (ALUResult_MEM[1:0])
                        2'b00: ram_we = 4'b0001;
                        2'b01: ram_we = 4'b0010;
                        2'b10: ram_we = 4'b0100;
                        2'b11: ram_we = 4'b1000;
                    endcase
                end
                default: ram_we = 4'b0000;
            endcase
        end
    end

    logic [31:0] w_data_shifted_MEM;
    assign w_data_shifted_MEM =
        (MemWrite_MEM == 2'b10) ? (rdata2_MEM << {ALUResult_MEM[1:0], 3'b000}) :
        (MemWrite_MEM == 2'b01) ? (rdata2_MEM << {ALUResult_MEM[1],   4'b0000}) :
        rdata2_MEM;

    logic [31:0] mem_rdata_MEM;
    single_port_ram #(.DATA_N(32), .SIZE(1024)) data_mem (
        .clk   (clk),
        .wr_en (ram_we),
        .addr  (ALUResult_MEM[11:2]),
        .w_data(w_data_shifted_MEM),
        .r_data(mem_rdata_MEM)
    );

// ============================================================
// *** Registro MEM/WB  —  sin cambios ***
// ============================================================

    logic [1:0]  ResultSrc_WB;
    logic [31:0] PCplus4_WB;
    logic [31:0] ALUResult_WB;
    logic [31:0] mem_rdata_WB_raw;
    logic [31:0] imm_WB;

    logic [2:0] BitSel_WB;
    logic [1:0] ALUResultLSB_WB;

    always_ff @(posedge clk) begin
        if (rst) begin
            BitSel_WB       <= 0;
            ALUResultLSB_WB <= 0;
        end else begin
            BitSel_WB       <= BitSel_MEM;
            ALUResultLSB_WB <= ALUResult_MEM[1:0];
        end
    end

    reg_MEM_WB u_MEM_WB (
        .clk          (clk),             .rst          (rst),
        .RegWrite_in  (RegWrite_MEM),    .RegWrite_out   (RegWrite_WB),
        .ResultSrc_in (ResultSrc_MEM),   .ResultSrc_out  (ResultSrc_WB),
        .PCplus4_in   (PCplus4_MEM),     .PCplus4_out    (PCplus4_WB),
        .ALUResult_in (ALUResult_MEM),   .ALUResult_out  (ALUResult_WB),
        .mem_rdata_in (mem_rdata_MEM),   .mem_rdata_out  (mem_rdata_WB_raw),
        .imm_in       (imm_MEM),         .imm_out        (imm_WB),
        .rd_in        (rd_MEM),          .rd_out         (rd_WB)
    );

// ============================================================
// *** ETAPA WB  —  sin cambios ***
// ============================================================

    logic [31:0] mem_rdata_shifted_WB;
    logic [31:0] mem_rdata_formatted_WB;

    assign mem_rdata_shifted_WB = mem_rdata_WB_raw >> {ALUResultLSB_WB, 3'b000};

    BitSelector #(32) bit_sel (
        .in    (mem_rdata_shifted_WB),
        .BitSel(BitSel_WB),
        .out   (mem_rdata_formatted_WB)
    );

    always_comb begin
        case (ResultSrc_WB)
            2'b00: writeback_data_WB = ALUResult_WB;
            2'b01: writeback_data_WB = mem_rdata_formatted_WB;
            2'b10: writeback_data_WB = PCplus4_WB;
            2'b11: writeback_data_WB = imm_WB;
            default: writeback_data_WB = ALUResult_WB;
        endcase
    end

// ============================================================
// *** HAZARD UNIT ***
// PCSrc se reemplaza por misprediction:
//   flush_IF_ID = misprediction (no PCSrc_EX)
//   flush_ID_EX = load_use_hazard || misprediction
// ============================================================

    hazard_unit u_hazard (
        .ID_EX_rs1       (rs1_EX),
        .ID_EX_rs2       (rs2_EX),
        .ID_EX_ResultSrc1(ResultSrc_EX[0]),
        .ID_EX_rd        (rd_EX),
        .EX_MEM_rd       (rd_MEM),
        .EX_MEM_RegWrite (RegWrite_MEM),
        .MEM_WB_rd       (rd_WB),
        .MEM_WB_RegWrite (RegWrite_WB),
        .IF_ID_rs1       (rs1_ID),
        .IF_ID_rs2       (rs2_ID),
        .PCSrc           (misprediction),
        .ForwardA        (ForwardA),
        .ForwardB        (ForwardB),
        .stall           (stall),
        .flush_ID_EX     (flush_ID_EX)
    );

    assign PC = PC_reg;

endmodule