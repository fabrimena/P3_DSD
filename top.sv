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

    // Señales de control de hazards (vienen de hazard_unit)
    logic        stall;
    logic        flush_ID_EX;
    logic        PCSrc_EX;     // salto resuelto en etapa EX
    logic [31:0] PCTarget_EX;  // dirección de salto calculada en EX

    logic [31:0] PC_IF;
    logic [31:0] PCplus4_IF;

    // El PC se frena si hay stall
    // pc_increment maneja el mux PCsrc internamente,
    // pero necesitamos poder congelarlo → usamos una versión
    // con enable de stall.
    logic [31:0] PCnext;
    logic [31:0] PC_reg;
    logic [31:0] PC;           // Alias para compatibilidad con testbenches

    // Adder PC+4
    adder #(32) pc_adder_if (
        .a   (PC_reg),
        .b   (32'd4),
        .cin (1'b0),
        .y   (PCplus4_IF)
    );

    // Mux: PC+4 o target de salto
    mux2to1_Nbits #(32) pc_mux_if (
        .sel (PCSrc_EX),
        .a   (PCplus4_IF),
        .b   (PCTarget_EX),
        .y   (PCnext)
    );

    // Registro PC con enable (stall lo congela)
    always_ff @(posedge clk) begin
        if (rst)
            PC_reg <= 32'b0;
        else if (!stall)
            PC_reg <= PCnext;
    end

    assign PC_IF = PC_reg;

    // Memoria de instrucciones
    logic [31:0] instr_IF;
    instructionMemory instr_mem (
        .PC   (PC_IF[6:2]),
        .instr(instr_IF)
    );

// ============================================================
// *** Registro IF/ID ***
// ============================================================

    logic [31:0] PC_ID, PCplus4_ID, instr_ID;

    reg_IF_ID u_IF_ID (
        .clk       (clk),
        .rst       (rst),
        .stall     (stall),
        .flush     (PCSrc_EX),   // si hay salto, vaciar instrucción fetched
        .PC_in     (PC_IF),
        .PCplus4_in(PCplus4_IF),
        .instr_in  (instr_IF),
        .PC_out    (PC_ID),
        .PCplus4_out(PCplus4_ID),
        .instr_out (instr_ID)
    );

// ============================================================
// *** ETAPA ID: Instruction Decode ***
// ============================================================

    // Decodificación de campos de la instrucción
    logic [6:0] opcode_ID;
    logic [4:0] rd_ID, rs1_ID, rs2_ID;
    logic [2:0] funct3_ID;

    assign opcode_ID = instr_ID[6:0];
    assign funct3_ID = instr_ID[14:12];
    assign rd_ID     = instr_ID[11:7];

    always_comb begin
        rs1_ID = instr_ID[19:15];
        case(opcode_ID)
            7'b0110011,   // R-type
            7'b0100011,   // S-type
            7'b1100011:   // B-type
                rs2_ID = instr_ID[24:20];
            default:
                rs2_ID = 5'b00000;
        endcase
    end

    // Señales de control generadas por la unidad de control
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
    logic       Branch_ID; // no se usa en esta etapa, pasa a EX
    logic [2:0] ALUFlags_ID;  // dummy; las flags reales se generan en EX
    logic       PCSrc_ID_dummy;

    control_unit u_control (
        .op        (opcode_ID),
        .funct3    (funct3_ID),
        .funct7    (instr_ID[31:25]),
        .ALUFlags  (3'b000),      // no afecta a señales de decodificación
        .ALUMSB    (1'b0),
        .PCSrc     (PCSrc_ID_dummy), // no se usa aquí; PCSrc se recalcula en EX
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

    // Jump/Branch: los extrae main_decoder internamente a través de control_unit.
    // Para el pipeline necesitamos Branch y Jump; los re-derivamos aquí
    // de forma puramente combinacional a partir del opcode.
    localparam BRANCH_OP = 7'b1100011;
    localparam JAL_OP    = 7'b1101111;
    localparam JALR_OP   = 7'b1100111;

    assign Branch_ID = (opcode_ID == BRANCH_OP);
    assign Jump_ID   = (opcode_ID == JAL_OP) || (opcode_ID == JALR_OP);

    // Extensión de inmediato
    logic [31:0] imm_ID;
    extend u_imm_ext (
        .instr  (instr_ID),
        .ImmSrc (ImmSrc_ID),
        .ImmExt (imm_ID)
    );

    // Banco de registros (escritura desde etapa WB)
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
        .flush         (flush_ID_EX),
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

// ============================================================
// *** ETAPA EX: Execute ***
// ============================================================

    // Señales de forwarding
    logic [1:0] ForwardA, ForwardB;

    // Writeback data desde MEM/WB (para forwarding)
    // (declarado abajo, se usa también en ID)

    // Resultado de ALU desde EX/MEM (para forwarding)
    logic [31:0] ALUResult_MEM;

    // Muxes de forwarding para entradas de la ALU
    logic [31:0] ALUin0_pre, ALUin1_pre;
    logic [31:0] ALUin0, ALUin1_reg;

    // Forward A
    always_comb begin
        case (ForwardA)
            2'b00: ALUin0_pre = rdata1_EX;
            2'b10: ALUin0_pre = ALUResult_MEM;
            2'b01: ALUin0_pre = writeback_data_WB;
            default: ALUin0_pre = rdata1_EX;
        endcase
    end

    // Forward B (antes del mux ALUSrc)
    always_comb begin
        case (ForwardB)
            2'b00: ALUin1_pre = rdata2_EX;
            2'b10: ALUin1_pre = ALUResult_MEM;
            2'b01: ALUin1_pre = writeback_data_WB;
            default: ALUin1_pre = rdata2_EX;
        endcase
    end

    // Sh: mascara 5 bits LSB del shift amount (rs2 o imm)
    logic [31:0] ALUin0_sh, ALUin1_sh;
    assign ALUin0_sh = ALUin0_pre;                               // rs1 nunca se enmascara
    assign ALUin1_sh = Sh_EX ? {27'b0, ALUin1_pre[4:0]} : ALUin1_pre;

    // Mux ALUSrc
    assign ALUin0      = ALUin0_sh;
    assign ALUin1_reg  = ALUSrc_EX ? imm_EX : ALUin1_sh;

    // ALU
    logic [31:0] ALUResult_EX;
    logic [2:0]  ALUFlags_EX;

    ALU #(32) u_alu (
        .a         (ALUin0),
        .b         (ALUin1_reg),
        .ALUControl(ALUControl_EX),
        .ALUResult (ALUResult_EX),
        .ALUFlags  (ALUFlags_EX)
    );

    // Lógica de branch/jump (replicada de control_unit pero con flags reales)
    logic BranchTaken_EX;
    always_comb begin
        BranchTaken_EX = 1'b0;
        if (Branch_EX) begin
            case (funct3_EX)
                3'b000: BranchTaken_EX =  ALUFlags_EX[0];   // beq
                3'b001: BranchTaken_EX = ~ALUFlags_EX[0];   // bne
                3'b100: BranchTaken_EX =  ALUFlags_EX[1];   // blt
                3'b101: BranchTaken_EX = ~ALUFlags_EX[1];   // bge
                default: BranchTaken_EX = 1'b0;
            endcase
        end
    end

    assign PCSrc_EX = BranchTaken_EX | Jump_EX;

    // Cálculo del PC destino
    assign PCTarget_EX = (opcode_EX == JALR_OP) ?
                         (ALUResult_EX & ~32'd1) :
                         (PC_EX + imm_EX);

    // rdata2 con forwarding (para stores)
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
// *** Registro EX/MEM ***
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
// *** ETAPA MEM: Memory Access ***
// ============================================================

    // Generación de byte enables (igual que en top.sv)
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
// *** Registro MEM/WB ***
// ============================================================

    logic [1:0]  ResultSrc_WB;
    logic [31:0] PCplus4_WB;
    logic [31:0] ALUResult_WB;
    logic [31:0] mem_rdata_WB_raw;
    logic [31:0] imm_WB;

    // Pasamos BitSel y ALUResult[1:0] a WB para shift/format de datos leidos
    // Los agrupamos con imm para aprovechar el campo imm_in del registro MEM/WB
    // Solución simple: agregar señales extra al registro MEM/WB
    // En lugar de modificar el módulo paramétrico, usamos registros FF locales
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
// *** ETAPA WB: Write Back ***
// ============================================================

    // Shift y format de datos leidos de memoria
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
            2'b11: writeback_data_WB = imm_WB;   // LUI
            default: writeback_data_WB = ALUResult_WB;
        endcase
    end

// ============================================================
// *** HAZARD UNIT ***
// ============================================================

    hazard_unit u_hazard (
        .ID_EX_rs1      (rs1_EX),
        .ID_EX_rs2      (rs2_EX),
        .ID_EX_ResultSrc1(ResultSrc_EX[0]),  // bit 0 = 1 para LOAD
        .ID_EX_rd       (rd_EX),
        .EX_MEM_rd      (rd_MEM),
        .EX_MEM_RegWrite(RegWrite_MEM),
        .MEM_WB_rd      (rd_WB),
        .MEM_WB_RegWrite(RegWrite_WB),
        .IF_ID_rs1      (rs1_ID),
        .IF_ID_rs2      (rs2_ID),
        .PCSrc          (PCSrc_EX),
        .ForwardA       (ForwardA),
        .ForwardB       (ForwardB),
        .stall          (stall),
        .flush_ID_EX    (flush_ID_EX)
    );

    // Alias para compatibilidad con testbenches
    assign PC = PC_reg;

endmodule