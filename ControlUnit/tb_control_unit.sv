// ============================================================
// tb_control_unit.sv
// ============================================================

`timescale 1ns/1ps

module tb_control_unit;

    // --------------------------------------------------------
    // DUT signals
    // --------------------------------------------------------
    logic [6:0] op;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic [2:0] ALUFlags;
    logic       ALUMSB;

    logic       PCSrc;
    logic [1:0] ResultSrc;
    logic [1:0] MemWrite;
    logic [3:0] ALUControl;
    logic       ALUSrc;
    logic [2:0] ImmSrc;
    logic       RegWrite;
    logic [2:0] BitSel;
    logic       Sh;

    // --------------------------------------------------------
    // DUT
    // --------------------------------------------------------
    control_unit dut (
        .op         (op),
        .funct3     (funct3),
        .funct7     (funct7),
        .ALUFlags   (ALUFlags),
        .ALUMSB     (ALUMSB),
        .PCSrc      (PCSrc),
        .ResultSrc  (ResultSrc),
        .MemWrite   (MemWrite),
        .ALUControl (ALUControl),
        .ALUSrc     (ALUSrc),
        .ImmSrc     (ImmSrc),
        .RegWrite   (RegWrite),
        .BitSel     (BitSel),
        .Sh         (Sh)
    );

    // --------------------------------------------------------
    // Contadores
    // --------------------------------------------------------
    int pass_count = 0;
    int fail_count = 0;

    task automatic check(
        input string      test_name,
        input logic       exp_RegWrite,
        input logic [2:0] exp_ImmSrc,
        input logic       exp_ALUSrc,
        input logic [1:0] exp_MemWrite,
        input logic [1:0] exp_ResultSrc,
        input logic       exp_PCSrc,
        input logic [3:0] exp_ALUControl,
        input logic [2:0] exp_BitSel,
        input logic       exp_Sh
    );
        #1;
        if (RegWrite    !== exp_RegWrite   ||
            ImmSrc      !== exp_ImmSrc     ||
            ALUSrc      !== exp_ALUSrc     ||
            MemWrite    !== exp_MemWrite   ||
            ResultSrc   !== exp_ResultSrc  ||
            PCSrc       !== exp_PCSrc      ||
            ALUControl  !== exp_ALUControl ||
            BitSel      !== exp_BitSel     ||
            Sh          !== exp_Sh) begin
            $display("FAIL [%s]", test_name);
            $display("  RegWrite:   got %b exp %b", RegWrite,   exp_RegWrite);
            $display("  ImmSrc:     got %b exp %b", ImmSrc,     exp_ImmSrc);
            $display("  ALUSrc:     got %b exp %b", ALUSrc,     exp_ALUSrc);
            $display("  MemWrite:   got %b exp %b", MemWrite,   exp_MemWrite);
            $display("  ResultSrc:  got %b exp %b", ResultSrc,  exp_ResultSrc);
            $display("  PCSrc:      got %b exp %b", PCSrc,      exp_PCSrc);
            $display("  ALUControl: got %b exp %b", ALUControl, exp_ALUControl);
            $display("  BitSel:     got %b exp %b", BitSel,     exp_BitSel);
            $display("  Sh:         got %b exp %b", Sh,         exp_Sh);
            fail_count++;
        end else begin
            $display("PASS [%s]", test_name);
            pass_count++;
        end
    endtask

    initial begin
        $display("========================================");
        $display("  TB Control Unit - RV32I");
        $display("========================================");

        ALUFlags = 3'b000;
        ALUMSB   = 0;

        // ---- LOADS ----
        op=7'b0000011; funct3=3'b010; funct7=7'b0;
        check("lw",  1, 3'b000, 1, 2'b00, 2'b01, 0, 4'b0000, 3'b000, 0);

        op=7'b0000011; funct3=3'b001; funct7=7'b0;
        check("lh",  1, 3'b000, 1, 2'b00, 2'b01, 0, 4'b0000, 3'b001, 0);

        op=7'b0000011; funct3=3'b000; funct7=7'b0;
        check("lb",  1, 3'b000, 1, 2'b00, 2'b01, 0, 4'b0000, 3'b010, 0);

        op=7'b0000011; funct3=3'b101; funct7=7'b0;
        check("lhu", 1, 3'b000, 1, 2'b00, 2'b01, 0, 4'b0000, 3'b011, 0);

        op=7'b0000011; funct3=3'b100; funct7=7'b0;
        check("lbu", 1, 3'b000, 1, 2'b00, 2'b01, 0, 4'b0000, 3'b100, 0);

        // ---- STORES ----
        op=7'b0100011; funct3=3'b010; funct7=7'b0;
        check("sw", 0, 3'b001, 1, 2'b00, 2'b00, 0, 4'b0000, 3'b000, 0);

        op=7'b0100011; funct3=3'b001; funct7=7'b0;
        check("sh", 0, 3'b001, 1, 2'b01, 2'b00, 0, 4'b0000, 3'b000, 0);

        op=7'b0100011; funct3=3'b000; funct7=7'b0;
        check("sb", 0, 3'b001, 1, 2'b10, 2'b00, 0, 4'b0000, 3'b000, 0);

        // ---- R-TYPE ----
        op=7'b0110011; funct3=3'b000; funct7=7'b0000000;
        check("add",  1, 3'b000, 0, 2'b00, 2'b00, 0, 4'b0000, 3'b000, 0);

        op=7'b0110011; funct3=3'b000; funct7=7'b0100000;
        check("sub",  1, 3'b000, 0, 2'b00, 2'b00, 0, 4'b1000, 3'b000, 0);

        op=7'b0110011; funct3=3'b111; funct7=7'b0;
        check("and",  1, 3'b000, 0, 2'b00, 2'b00, 0, 4'b0111, 3'b000, 0);

        op=7'b0110011; funct3=3'b110; funct7=7'b0;
        check("or",   1, 3'b000, 0, 2'b00, 2'b00, 0, 4'b0110, 3'b000, 0);

        op=7'b0110011; funct3=3'b100; funct7=7'b0;
        check("xor",  1, 3'b000, 0, 2'b00, 2'b00, 0, 4'b0100, 3'b000, 0);

        // Sh=1 para shifts R-type
        op=7'b0110011; funct3=3'b001; funct7=7'b0;
        check("sll",  1, 3'b000, 0, 2'b00, 2'b00, 0, 4'b0001, 3'b000, 1);

        op=7'b0110011; funct3=3'b101; funct7=7'b0000000;
        check("srl",  1, 3'b000, 0, 2'b00, 2'b00, 0, 4'b0101, 3'b000, 1);

        op=7'b0110011; funct3=3'b101; funct7=7'b0100000;
        check("sra",  1, 3'b000, 0, 2'b00, 2'b00, 0, 4'b1101, 3'b000, 1);

        op=7'b0110011; funct3=3'b010; funct7=7'b0;
        check("slt",  1, 3'b000, 0, 2'b00, 2'b00, 0, 4'b0010, 3'b000, 0);

        op=7'b0110011; funct3=3'b011; funct7=7'b0;
        check("sltu", 1, 3'b000, 0, 2'b00, 2'b00, 0, 4'b0011, 3'b000, 0);

        // ---- I-TYPE ALU ----
        op=7'b0010011; funct3=3'b000; funct7=7'b0;
        check("addi",  1, 3'b000, 1, 2'b00, 2'b00, 0, 4'b0000, 3'b000, 0);

        op=7'b0010011; funct3=3'b111; funct7=7'b0;
        check("andi",  1, 3'b000, 1, 2'b00, 2'b00, 0, 4'b0111, 3'b000, 0);

        op=7'b0010011; funct3=3'b110; funct7=7'b0;
        check("ori",   1, 3'b000, 1, 2'b00, 2'b00, 0, 4'b0110, 3'b000, 0);

        op=7'b0010011; funct3=3'b100; funct7=7'b0;
        check("xori",  1, 3'b000, 1, 2'b00, 2'b00, 0, 4'b0100, 3'b000, 0);

        // Sh=1 para shifts I-type
        op=7'b0010011; funct3=3'b001; funct7=7'b0000000;
        check("slli",  1, 3'b000, 1, 2'b00, 2'b00, 0, 4'b0001, 3'b000, 1);

        op=7'b0010011; funct3=3'b101; funct7=7'b0000000;
        check("srli",  1, 3'b000, 1, 2'b00, 2'b00, 0, 4'b0101, 3'b000, 1);

        op=7'b0010011; funct3=3'b101; funct7=7'b0100000;
        check("srai",  1, 3'b000, 1, 2'b00, 2'b00, 0, 4'b1101, 3'b000, 1);

        op=7'b0010011; funct3=3'b010; funct7=7'b0;
        check("slti",  1, 3'b000, 1, 2'b00, 2'b00, 0, 4'b0010, 3'b000, 0);

        op=7'b0010011; funct3=3'b011; funct7=7'b0;
        check("sltiu", 1, 3'b000, 1, 2'b00, 2'b00, 0, 4'b0011, 3'b000, 0);

        // ---- BRANCH ----
        op=7'b1100011; funct3=3'b000; funct7=7'b0; ALUFlags=3'b001; ALUMSB=0;
        check("beq taken",     0, 3'b010, 0, 2'b00, 2'b00, 1, 4'b1000, 3'b000, 0);

        op=7'b1100011; funct3=3'b000; funct7=7'b0; ALUFlags=3'b000; ALUMSB=0;
        check("beq not taken", 0, 3'b010, 0, 2'b00, 2'b00, 0, 4'b1000, 3'b000, 0);

        op=7'b1100011; funct3=3'b001; funct7=7'b0; ALUFlags=3'b000; ALUMSB=0;
        check("bne taken",     0, 3'b010, 0, 2'b00, 2'b00, 1, 4'b1000, 3'b000, 0);

        op=7'b1100011; funct3=3'b100; funct7=7'b0; ALUFlags=3'b010; ALUMSB=0;
        check("blt taken",     0, 3'b010, 0, 2'b00, 2'b00, 1, 4'b1000, 3'b000, 0);

        op=7'b1100011; funct3=3'b100; funct7=7'b0; ALUFlags=3'b000; ALUMSB=1;
        check("blt not taken", 0, 3'b010, 0, 2'b00, 2'b00, 0, 4'b1000, 3'b000, 0);

        op=7'b1100011; funct3=3'b101; funct7=7'b0; ALUFlags=3'b000; ALUMSB=0;
        check("bge taken",     0, 3'b010, 0, 2'b00, 2'b00, 1, 4'b1000, 3'b000, 0);

        op=7'b1100011; funct3=3'b101; funct7=7'b0; ALUFlags=3'b010; ALUMSB=1;
        check("bge not taken", 0, 3'b010, 0, 2'b00, 2'b00, 0, 4'b1000, 3'b000, 0);

        // ---- JAL ----
        op=7'b1101111; funct3=3'b000; funct7=7'b0; ALUFlags=3'b000; ALUMSB=0;
        check("jal",  1, 3'b011, 0, 2'b00, 2'b10, 1, 4'b0000, 3'b000, 0);

        // ---- JALR ----
        op=7'b1100111; funct3=3'b000; funct7=7'b0; ALUFlags=3'b000; ALUMSB=0;
        check("jalr", 1, 3'b000, 1, 2'b00, 2'b10, 1, 4'b0000, 3'b000, 0);

        // ---- LUI ----
        op=7'b0110111; funct3=3'b000; funct7=7'b0; ALUFlags=3'b000; ALUMSB=0;
        check("lui",  1, 3'b100, 1, 2'b00, 2'b11, 0, 4'b0000, 3'b000, 0);

        // --- PRUEBAS LIMITE / NEGATIVAS ---
        $display("\n--- PRUEBAS NEGATIVAS Y DE ROBUSTEZ ---");
        
        // 1. Instruccion totalmente desconocida / Basura (Opcode = 7'b1111111)
        // Debe de-seleccionar escrituras en memoria y en registro (Seguridad pasiva de estado)
        op=7'b1111111; funct3=3'b111; funct7=7'b1111111; ALUFlags=3'b000; ALUMSB=0; 
        #1;
        $display("[TEST NEGATIVO] Opcode desconocido (1111111) | RegWrite=%b MemWrite=%b", RegWrite, MemWrite);
        if (RegWrite != 0 || MemWrite != 0) begin
            $display("ERROR CRITICO: La CU permitio escrituras bajo ruido basura.");
            fail_count++;
        end else begin
            pass_count++;
        end

        // 2. Ruido en comparador de salto (Branch no tomado por fallar Less)
        // Con la logica de Flags[1] (Less), un BLT con Flag[1]=0 no debe saltar
        op=7'b1100011; funct3=3'b100; funct7=7'b0; ALUFlags=3'b000; ALUMSB=0; // blt falso
        #1;
        $display("[TEST NEGATIVO] BLT con condicion en falso (Flag_Less=0) | PCSrc=%b", PCSrc);
        if (PCSrc == 1) begin
            $display("ERROR CRITICO: Salto tomado injustificadamente");
            fail_count++;
        end else begin
            pass_count++;
        end

        // ---- RESUMEN ----
        $display("========================================");
        $display("  Resultados: %0d PASS / %0d FAIL", pass_count, fail_count);
        $display("========================================");
        if (fail_count == 0)
            $display("  *** TODOS LOS TESTS PASARON ***");
        else
            $display("  *** HAY FALLOS - REVISAR LOGICA ***");

        $finish;
    end

endmodule
