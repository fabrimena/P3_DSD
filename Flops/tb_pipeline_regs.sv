// ============================================================
// tb_pipeline_regs.sv
// Testbench para los registros de segmentación del pipeline
//
// Estrategia: verificar que entrada == salida tras un flanco,
// mostrando los valores reales que fluyen (sin constantes mágicas).
// Se prueban los 4 comportamientos de cada registro:
//   1. Reset/flush  → todos los campos a cero
//   2. Captura normal → salida = entrada tras posedge
//   3. Stall (solo IF/ID) → salida se congela, entrada nueva ignorada
//   4. Flush (ID/EX)     → limpia señales de control
// ============================================================
`timescale 1ns/1ps

module tb_pipeline_regs;

    // -------------------------------------------------------
    // Contadores globales de pass/fail
    // -------------------------------------------------------
    integer test_pass = 0, test_fail = 0;

    // -------------------------------------------------------
    // Clock único compartido (todos los registros son síncronos)
    // -------------------------------------------------------
    logic clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // -------------------------------------------------------
    // Tarea genérica de comparación de 1 campo de 32 bits
    //   Imprime entrada, salida obtenida y resultado.
    // -------------------------------------------------------
    task automatic check32(
        input string  label,
        input logic [31:0] got,
        input logic [31:0] exp
    );
        if (got === exp) begin
            $display("  [PASS] %-35s  entrada=%h  salida=%h", label, exp, got);
            test_pass++;
        end else begin
            $display("  [FAIL] %-35s  esperado=%h  obtenido=%h", label, exp, got);
            test_fail++;
        end
    endtask

    task automatic check5(
        input string  label,
        input logic [4:0] got,
        input logic [4:0] exp
    );
        if (got === exp) begin
            $display("  [PASS] %-35s  entrada=%0d  salida=%0d", label, exp, got);
            test_pass++;
        end else begin
            $display("  [FAIL] %-35s  esperado=%0d  obtenido=%0d", label, exp, got);
            test_fail++;
        end
    endtask

    task automatic check1(
        input string  label,
        input logic got,
        input logic exp
    );
        if (got === exp) begin
            $display("  [PASS] %-35s  entrada=%b  salida=%b", label, exp, got);
            test_pass++;
        end else begin
            $display("  [FAIL] %-35s  esperado=%b  obtenido=%b", label, exp, got);
            test_fail++;
        end
    endtask

    // ===========================================================
    // ----  Registro IF/ID  -------------------------------------
    // ===========================================================
    logic        rst_ifid, stall_ifid, flush_ifid;
    logic [31:0] PC_ifid_in, PCp4_ifid_in, instr_ifid_in;
    logic [31:0] PC_ifid_out, PCp4_ifid_out, instr_ifid_out;

    reg_IF_ID dut_ifid (
        .clk        (clk),
        .rst        (rst_ifid),
        .stall      (stall_ifid),
        .flush      (flush_ifid),
        .PC_in      (PC_ifid_in),
        .PCplus4_in (PCp4_ifid_in),
        .instr_in   (instr_ifid_in),
        .PC_out     (PC_ifid_out),
        .PCplus4_out(PCp4_ifid_out),
        .instr_out  (instr_ifid_out)
    );

    // ===========================================================
    // ----  Registro ID/EX  -------------------------------------
    // ===========================================================
    logic        rst_idex, flush_idex;
    logic        RW_idex_in,  RW_idex_out;
    logic [1:0]  RS_idex_in,  RS_idex_out;
    logic        MWE_idex_in, MWE_idex_out;
    logic [1:0]  MW_idex_in,  MW_idex_out;
    logic        AS_idex_in,  AS_idex_out;
    logic [3:0]  AC_idex_in,  AC_idex_out;
    logic [2:0]  BS_idex_in,  BS_idex_out;
    logic        Sh_idex_in,  Sh_idex_out;
    logic        Jmp_idex_in, Jmp_idex_out;
    logic        Br_idex_in,  Br_idex_out;
    logic [31:0] PC_idex_in,  PC_idex_out;
    logic [31:0] PCp4_idex_in,PCp4_idex_out;
    logic [31:0] rd1_idex_in, rd1_idex_out;
    logic [31:0] rd2_idex_in, rd2_idex_out;
    logic [31:0] imm_idex_in, imm_idex_out;
    logic [4:0]  rd_idex_in,  rd_idex_out;
    logic [4:0]  rs1_idex_in, rs1_idex_out;
    logic [4:0]  rs2_idex_in, rs2_idex_out;
    logic [6:0]  op_idex_in,  op_idex_out;
    logic [2:0]  f3_idex_in,  f3_idex_out;

    reg_ID_EX dut_idex (
        .clk(clk), .rst(rst_idex), .flush(flush_idex),
        .RegWrite_in(RW_idex_in),   .RegWrite_out(RW_idex_out),
        .ResultSrc_in(RS_idex_in),  .ResultSrc_out(RS_idex_out),
        .MemWriteEn_in(MWE_idex_in),.MemWriteEn_out(MWE_idex_out),
        .MemWrite_in(MW_idex_in),   .MemWrite_out(MW_idex_out),
        .ALUSrc_in(AS_idex_in),     .ALUSrc_out(AS_idex_out),
        .ALUControl_in(AC_idex_in), .ALUControl_out(AC_idex_out),
        .BitSel_in(BS_idex_in),     .BitSel_out(BS_idex_out),
        .Sh_in(Sh_idex_in),         .Sh_out(Sh_idex_out),
        .Jump_in(Jmp_idex_in),      .Jump_out(Jmp_idex_out),
        .Branch_in(Br_idex_in),     .Branch_out(Br_idex_out),
        .PC_in(PC_idex_in),         .PC_out(PC_idex_out),
        .PCplus4_in(PCp4_idex_in),  .PCplus4_out(PCp4_idex_out),
        .rdata1_in(rd1_idex_in),    .rdata1_out(rd1_idex_out),
        .rdata2_in(rd2_idex_in),    .rdata2_out(rd2_idex_out),
        .imm_in(imm_idex_in),       .imm_out(imm_idex_out),
        .rd_in(rd_idex_in),         .rd_out(rd_idex_out),
        .rs1_in(rs1_idex_in),       .rs1_out(rs1_idex_out),
        .rs2_in(rs2_idex_in),       .rs2_out(rs2_idex_out),
        .opcode_in(op_idex_in),     .opcode_out(op_idex_out),
        .funct3_in(f3_idex_in),     .funct3_out(f3_idex_out)
    );

    // ===========================================================
    // ----  Registro EX/MEM  ------------------------------------
    // ===========================================================
    logic        rst_exmem;
    logic        RW_exmem_in,  RW_exmem_out;
    logic [1:0]  RS_exmem_in,  RS_exmem_out;
    logic        MWE_exmem_in, MWE_exmem_out;
    logic [1:0]  MW_exmem_in,  MW_exmem_out;
    logic [2:0]  BS_exmem_in,  BS_exmem_out;
    logic [31:0] PCp4_exmem_in,PCp4_exmem_out;
    logic [31:0] ALU_exmem_in, ALU_exmem_out;
    logic [31:0] rd2_exmem_in, rd2_exmem_out;
    logic [31:0] imm_exmem_in, imm_exmem_out;
    logic [4:0]  rd_exmem_in,  rd_exmem_out;

    reg_EX_MEM dut_exmem (
        .clk(clk), .rst(rst_exmem),
        .RegWrite_in(RW_exmem_in),   .RegWrite_out(RW_exmem_out),
        .ResultSrc_in(RS_exmem_in),  .ResultSrc_out(RS_exmem_out),
        .MemWriteEn_in(MWE_exmem_in),.MemWriteEn_out(MWE_exmem_out),
        .MemWrite_in(MW_exmem_in),   .MemWrite_out(MW_exmem_out),
        .BitSel_in(BS_exmem_in),     .BitSel_out(BS_exmem_out),
        .PCplus4_in(PCp4_exmem_in),  .PCplus4_out(PCp4_exmem_out),
        .ALUResult_in(ALU_exmem_in), .ALUResult_out(ALU_exmem_out),
        .rdata2_in(rd2_exmem_in),    .rdata2_out(rd2_exmem_out),
        .imm_in(imm_exmem_in),       .imm_out(imm_exmem_out),
        .rd_in(rd_exmem_in),         .rd_out(rd_exmem_out)
    );

    // ===========================================================
    // ----  Registro MEM/WB  ------------------------------------
    // ===========================================================
    logic        rst_memwb;
    logic        RW_memwb_in,  RW_memwb_out;
    logic [1:0]  RS_memwb_in,  RS_memwb_out;
    logic [31:0] PCp4_memwb_in,PCp4_memwb_out;
    logic [31:0] ALU_memwb_in, ALU_memwb_out;
    logic [31:0] mrd_memwb_in, mrd_memwb_out;
    logic [31:0] imm_memwb_in, imm_memwb_out;
    logic [4:0]  rd_memwb_in,  rd_memwb_out;

    reg_MEM_WB dut_memwb (
        .clk(clk), .rst(rst_memwb),
        .RegWrite_in(RW_memwb_in),     .RegWrite_out(RW_memwb_out),
        .ResultSrc_in(RS_memwb_in),    .ResultSrc_out(RS_memwb_out),
        .PCplus4_in(PCp4_memwb_in),    .PCplus4_out(PCp4_memwb_out),
        .ALUResult_in(ALU_memwb_in),   .ALUResult_out(ALU_memwb_out),
        .mem_rdata_in(mrd_memwb_in),   .mem_rdata_out(mrd_memwb_out),
        .imm_in(imm_memwb_in),         .imm_out(imm_memwb_out),
        .rd_in(rd_memwb_in),           .rd_out(rd_memwb_out)
    );

    // ===========================================================
    // Estímulos principales
    // ===========================================================
    initial begin
        $dumpfile("tb_pipeline_regs.vcd");
        $dumpvars(0, tb_pipeline_regs);

        $display("============================================================");
        $display("  TESTBENCH: Registros de Segmentacion del Pipeline");
        $display("  Muestra: campo | valor de entrada | valor capturado");
        $display("============================================================\n");

        // -----------------------------------------------------------
        // ===  reg_IF_ID  ===
        // -----------------------------------------------------------
        $display("=== reg_IF_ID ===\n");

        // -- 1. Reset ---
        $display("-- Prueba 1: Reset activo --");
        rst_ifid = 1; stall_ifid = 0; flush_ifid = 0;
        PC_ifid_in    = 32'hABCD_1234;
        PCp4_ifid_in  = 32'hABCD_1238;
        instr_ifid_in = 32'hFACE_CAFE;
        @(posedge clk); #1;
        check32("IF/ID PC_out    (rst=1)", PC_ifid_out,    32'h0);
        check32("IF/ID PCplus4_out(rst=1)", PCp4_ifid_out,  32'h0);
        check32("IF/ID instr_out (rst=1)", instr_ifid_out, 32'h0);

        // -- 2. Captura normal ---
        $display("\n-- Prueba 2: Captura normal --");
        rst_ifid = 0;
        PC_ifid_in    = 32'h0000_0100;
        PCp4_ifid_in  = 32'h0000_0104;
        instr_ifid_in = 32'h0062_8233;   // add x4, x5, x6 (RV32I)
        @(posedge clk); #1;
        check32("IF/ID PC_out",     PC_ifid_out,    PC_ifid_in);
        check32("IF/ID PCplus4_out",PCp4_ifid_out,  PCp4_ifid_in);
        check32("IF/ID instr_out",  instr_ifid_out, instr_ifid_in);

        // -- 3. Stall: salida debe congelarse ---
        $display("\n-- Prueba 3: Stall (salida debe permanecer igual) --");
        stall_ifid = 1;
        PC_ifid_in    = 32'hFFFF_FFFF;   // nueva entrada que NO debe capturarse
        PCp4_ifid_in  = 32'hFFFF_FFFF;
        instr_ifid_in = 32'hFFFF_FFFF;
        @(posedge clk); #1;
        check32("IF/ID PC_out    (stall)", PC_ifid_out,    32'h0000_0100);
        check32("IF/ID PCplus4_out(stall)",PCp4_ifid_out,  32'h0000_0104);
        check32("IF/ID instr_out (stall)", instr_ifid_out, 32'h0062_8233);

        // -- 4. Flush: debe insertar NOP ---
        $display("\n-- Prueba 4: Flush (NOP = todos en cero) --");
        stall_ifid = 0; flush_ifid = 1;
        @(posedge clk); #1;
        check32("IF/ID PC_out    (flush)", PC_ifid_out,    32'h0);
        check32("IF/ID PCplus4_out(flush)",PCp4_ifid_out,  32'h0);
        check32("IF/ID instr_out (flush)", instr_ifid_out, 32'h0);
        flush_ifid = 0;

        // -----------------------------------------------------------
        // ===  reg_ID_EX  ===
        // -----------------------------------------------------------
        $display("\n=== reg_ID_EX ===\n");

        // -- 5. Reset ---
        $display("-- Prueba 5: Reset activo --");
        rst_idex = 1; flush_idex = 0;
        RW_idex_in  = 1;  RS_idex_in  = 2'b10; MWE_idex_in = 1;
        MW_idex_in  = 2'b01; AS_idex_in = 1; AC_idex_in = 4'b1000;
        BS_idex_in  = 3'b010; Sh_idex_in = 1; Jmp_idex_in = 1; Br_idex_in = 1;
        PC_idex_in  = 32'h0000_0200; PCp4_idex_in = 32'h0000_0204;
        rd1_idex_in = 32'h1111_1111; rd2_idex_in  = 32'h2222_2222;
        imm_idex_in = 32'h0000_0010; rd_idex_in   = 5'd5;
        rs1_idex_in = 5'd1; rs2_idex_in = 5'd2;
        op_idex_in  = 7'b011_0011; f3_idex_in = 3'b000;
        @(posedge clk); #1;
        check1 ("ID/EX RegWrite_out  (rst=1)", RW_idex_out,  1'b0);
        check32("ID/EX PC_out        (rst=1)", PC_idex_out,  32'h0);
        check32("ID/EX rdata1_out    (rst=1)", rd1_idex_out, 32'h0);
        check32("ID/EX imm_out       (rst=1)", imm_idex_out, 32'h0);

        // -- 6. Captura normal ---
        $display("\n-- Prueba 6: Captura normal --");
        rst_idex = 0;
        @(posedge clk); #1;
        check1 ("ID/EX RegWrite_out",  RW_idex_out,   RW_idex_in);
        check1 ("ID/EX ALUSrc_out",    AS_idex_out,   AS_idex_in);
        check32("ID/EX PC_out",        PC_idex_out,   PC_idex_in);
        check32("ID/EX PCplus4_out",   PCp4_idex_out, PCp4_idex_in);
        check32("ID/EX rdata1_out",    rd1_idex_out,  rd1_idex_in);
        check32("ID/EX rdata2_out",    rd2_idex_out,  rd2_idex_in);
        check32("ID/EX imm_out",       imm_idex_out,  imm_idex_in);
        check5 ("ID/EX rd_out",        rd_idex_out,   rd_idex_in);
        check5 ("ID/EX rs1_out",       rs1_idex_out,  rs1_idex_in);
        check5 ("ID/EX rs2_out",       rs2_idex_out,  rs2_idex_in);

        // -- 7. Flush: solo señales de control deben ir a 0, datos pueden permanecer ---
        $display("\n-- Prueba 7: Flush (bubble: control = 0) --");
        flush_idex = 1;
        @(posedge clk); #1;
        check1 ("ID/EX RegWrite_out  (flush)", RW_idex_out,  1'b0);
        check1 ("ID/EX Jump_out      (flush)", Jmp_idex_out, 1'b0);
        check1 ("ID/EX Branch_out    (flush)", Br_idex_out,  1'b0);
        check1 ("ID/EX MemWriteEn_out(flush)", MWE_idex_out, 1'b0);
        flush_idex = 0;

        // -----------------------------------------------------------
        // ===  reg_EX_MEM  ===
        // -----------------------------------------------------------
        $display("\n=== reg_EX_MEM ===\n");

        // -- 8. Reset ---
        $display("-- Prueba 8: Reset activo --");
        rst_exmem = 1;
        RW_exmem_in  = 1;   RS_exmem_in  = 2'b00;
        MWE_exmem_in = 0;   MW_exmem_in  = 2'b00;
        BS_exmem_in  = 3'b001;
        PCp4_exmem_in = 32'h0000_0204;
        ALU_exmem_in  = 32'h0000_0080;   // resultado típico de una ADD
        rd2_exmem_in  = 32'h0000_00FF;
        imm_exmem_in  = 32'h0000_0010;
        rd_exmem_in   = 5'd7;
        @(posedge clk); #1;
        check32("EX/MEM ALUResult_out (rst=1)", ALU_exmem_out,  32'h0);
        check32("EX/MEM PCplus4_out   (rst=1)", PCp4_exmem_out, 32'h0);
        check5 ("EX/MEM rd_out        (rst=1)", rd_exmem_out,   5'd0);

        // -- 9. Captura normal ---
        $display("\n-- Prueba 9: Captura normal --");
        rst_exmem = 0;
        @(posedge clk); #1;
        check1 ("EX/MEM RegWrite_out",  RW_exmem_out,   RW_exmem_in);
        check32("EX/MEM ALUResult_out", ALU_exmem_out,  ALU_exmem_in);
        check32("EX/MEM rdata2_out",    rd2_exmem_out,  rd2_exmem_in);
        check32("EX/MEM PCplus4_out",   PCp4_exmem_out, PCp4_exmem_in);
        check32("EX/MEM imm_out",       imm_exmem_out,  imm_exmem_in);
        check5 ("EX/MEM rd_out",        rd_exmem_out,   rd_exmem_in);

        // -- 10. Segunda captura: nuevos datos distintos ---
        $display("\n-- Prueba 10: Segunda captura (nuevos valores) --");
        ALU_exmem_in  = 32'h0000_0300;   // nueva dirección de memoria
        rd2_exmem_in  = 32'hCCCC_CCCC;   // dato a escribir en memoria
        rd_exmem_in   = 5'd12;
        @(posedge clk); #1;
        check32("EX/MEM ALUResult_out (2da)", ALU_exmem_out, 32'h0000_0300);
        check32("EX/MEM rdata2_out    (2da)", rd2_exmem_out, 32'hCCCC_CCCC);
        check5 ("EX/MEM rd_out        (2da)", rd_exmem_out,  5'd12);

        // -----------------------------------------------------------
        // ===  reg_MEM_WB  ===
        // -----------------------------------------------------------
        $display("\n=== reg_MEM_WB ===\n");

        // -- 11. Reset ---
        $display("-- Prueba 11: Reset activo --");
        rst_memwb = 1;
        RW_memwb_in  = 1;   RS_memwb_in  = 2'b01;
        PCp4_memwb_in = 32'h0000_0208;
        ALU_memwb_in  = 32'h0000_0080;
        mrd_memwb_in  = 32'h0000_00AB;   // dato leído de memoria
        imm_memwb_in  = 32'h0000_0020;
        rd_memwb_in   = 5'd10;
        @(posedge clk); #1;
        check32("MEM/WB ALUResult_out  (rst=1)", ALU_memwb_out, 32'h0);
        check32("MEM/WB mem_rdata_out  (rst=1)", mrd_memwb_out, 32'h0);
        check5 ("MEM/WB rd_out         (rst=1)", rd_memwb_out,  5'd0);

        // -- 12. Captura normal ---
        $display("\n-- Prueba 12: Captura normal --");
        rst_memwb = 0;
        @(posedge clk); #1;
        check1 ("MEM/WB RegWrite_out",  RW_memwb_out,   RW_memwb_in);
        check32("MEM/WB PCplus4_out",   PCp4_memwb_out, PCp4_memwb_in);
        check32("MEM/WB ALUResult_out", ALU_memwb_out,  ALU_memwb_in);
        check32("MEM/WB mem_rdata_out", mrd_memwb_out,  mrd_memwb_in);
        check32("MEM/WB imm_out",       imm_memwb_out,  imm_memwb_in);
        check5 ("MEM/WB rd_out",        rd_memwb_out,   rd_memwb_in);

        // -- 13. ResultSrc propagado correctamente ---
        $display("\n-- Prueba 13: ResultSrc propagado --");
        RS_memwb_in = 2'b10;   // fuente = imm (U-type)
        imm_memwb_in = 32'h0001_2000;
        @(posedge clk); #1;
        // ResultSrc[1:0] controla qué se escribe en el destino:
        //   00=ALU  01=mem  10=PCplus4  11=imm
        // Aquí entraron 2'b10, verificamos que se capturó
        if (RS_memwb_out === 2'b10) begin
            $display("  [PASS] %-35s  entrada=%b  salida=%b",
                     "MEM/WB ResultSrc_out", RS_memwb_in, RS_memwb_out);
            test_pass++;
        end else begin
            $display("  [FAIL] %-35s  esperado=%b  obtenido=%b",
                     "MEM/WB ResultSrc_out", RS_memwb_in, RS_memwb_out);
            test_fail++;
        end
        check32("MEM/WB imm_out (U-type)", imm_memwb_out, imm_memwb_in);

        // -----------------------------------------------------------
        // Resumen final
        // -----------------------------------------------------------
        $display("\n============================================================");
        $display("  RESUMEN");
        $display("============================================================");
        $display("  Tests PASS: %0d", test_pass);
        $display("  Tests FAIL: %0d", test_fail);
        if (test_fail == 0)
            $display("  RESULTADO: EXITO TOTAL");
        else
            $display("  RESULTADO: HAY ERRORES");
        $display("============================================================\n");
        $finish;
    end

endmodule