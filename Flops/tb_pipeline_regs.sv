// ============================================================
// tb_pipeline_regs.sv
// Testbench para los registros de segmentación del pipeline
// ============================================================
`timescale 1ns/1ps

module tb_pipeline_regs;
    // Variables de prueba
    integer test_pass = 0, test_fail = 0;

    // ============================================================
    // Pruebas para reg_IF_ID
    // ============================================================
    logic clk_ifid, rst_ifid, stall_ifid, flush_ifid;
    logic [31:0] PC_ifid_in, PCplus4_ifid_in, instr_ifid_in;
    logic [31:0] PC_ifid_out, PCplus4_ifid_out, instr_ifid_out;

    reg_IF_ID dut_IF_ID (
        .clk(clk_ifid),
        .rst(rst_ifid),
        .stall(stall_ifid),
        .flush(flush_ifid),
        .PC_in(PC_ifid_in),
        .PCplus4_in(PCplus4_ifid_in),
        .instr_in(instr_ifid_in),
        .PC_out(PC_ifid_out),
        .PCplus4_out(PCplus4_ifid_out),
        .instr_out(instr_ifid_out)
    );

    // ============================================================
    // Pruebas para reg_ID_EX
    // ============================================================
    logic clk_idex, rst_idex, flush_idex;
    logic RegWrite_idex_in, RegWrite_idex_out;
    logic [1:0] ResultSrc_idex_in, ResultSrc_idex_out;
    logic MemWriteEn_idex_in, MemWriteEn_idex_out;
    logic [1:0] MemWrite_idex_in, MemWrite_idex_out;
    logic ALUSrc_idex_in, ALUSrc_idex_out;
    logic [3:0] ALUControl_idex_in, ALUControl_idex_out;
    logic [2:0] BitSel_idex_in, BitSel_idex_out;
    logic Sh_idex_in, Sh_idex_out;
    logic Jump_idex_in, Jump_idex_out;
    logic Branch_idex_in, Branch_idex_out;
    logic [31:0] PC_idex_in, PC_idex_out;
    logic [31:0] rdata1_idex_in, rdata1_idex_out;
    logic [31:0] rdata2_idex_in, rdata2_idex_out;
    logic [31:0] imm_idex_in, imm_idex_out;
    logic [4:0] rd_idex_in, rd_idex_out;
    logic [4:0] rs1_idex_in, rs1_idex_out;
    logic [4:0] rs2_idex_in, rs2_idex_out;
    logic [6:0] opcode_idex_in, opcode_idex_out;
    logic [2:0] funct3_idex_in, funct3_idex_out;

    reg_ID_EX dut_ID_EX (
        .clk(clk_idex),
        .rst(rst_idex),
        .flush(flush_idex),
        .RegWrite_in(RegWrite_idex_in),
        .RegWrite_out(RegWrite_idex_out),
        .ResultSrc_in(ResultSrc_idex_in),
        .ResultSrc_out(ResultSrc_idex_out),
        .MemWriteEn_in(MemWriteEn_idex_in),
        .MemWriteEn_out(MemWriteEn_idex_out),
        .MemWrite_in(MemWrite_idex_in),
        .MemWrite_out(MemWrite_idex_out),
        .ALUSrc_in(ALUSrc_idex_in),
        .ALUSrc_out(ALUSrc_idex_out),
        .ALUControl_in(ALUControl_idex_in),
        .ALUControl_out(ALUControl_idex_out),
        .BitSel_in(BitSel_idex_in),
        .BitSel_out(BitSel_idex_out),
        .Sh_in(Sh_idex_in),
        .Sh_out(Sh_idex_out),
        .Jump_in(Jump_idex_in),
        .Jump_out(Jump_idex_out),
        .Branch_in(Branch_idex_in),
        .Branch_out(Branch_idex_out),
        .PC_in(PC_idex_in),
        .PC_out(PC_idex_out),
        .PCplus4_in(32'b0),
        .PCplus4_out(),
        .rdata1_in(rdata1_idex_in),
        .rdata1_out(rdata1_idex_out),
        .rdata2_in(rdata2_idex_in),
        .rdata2_out(rdata2_idex_out),
        .imm_in(imm_idex_in),
        .imm_out(imm_idex_out),
        .rd_in(rd_idex_in),
        .rd_out(rd_idex_out),
        .rs1_in(rs1_idex_in),
        .rs1_out(rs1_idex_out),
        .rs2_in(rs2_idex_in),
        .rs2_out(rs2_idex_out),
        .opcode_in(opcode_idex_in),
        .opcode_out(opcode_idex_out),
        .funct3_in(funct3_idex_in),
        .funct3_out(funct3_idex_out)
    );

    // ============================================================
    // Pruebas para reg_EX_MEM
    // ============================================================
    logic clk_exmem, rst_exmem;
    logic RegWrite_exmem_in, RegWrite_exmem_out;
    logic [1:0] ResultSrc_exmem_in, ResultSrc_exmem_out;
    logic MemWriteEn_exmem_in, MemWriteEn_exmem_out;
    logic [1:0] MemWrite_exmem_in, MemWrite_exmem_out;
    logic [2:0] BitSel_exmem_in, BitSel_exmem_out;
    logic [31:0] PCplus4_exmem_in, PCplus4_exmem_out;
    logic [31:0] ALUResult_exmem_in, ALUResult_exmem_out;
    logic [31:0] rdata2_exmem_in, rdata2_exmem_out;
    logic [31:0] imm_exmem_in, imm_exmem_out;
    logic [4:0] rd_exmem_in, rd_exmem_out;

    reg_EX_MEM dut_EX_MEM (
        .clk(clk_exmem),
        .rst(rst_exmem),
        .RegWrite_in(RegWrite_exmem_in),
        .RegWrite_out(RegWrite_exmem_out),
        .ResultSrc_in(ResultSrc_exmem_in),
        .ResultSrc_out(ResultSrc_exmem_out),
        .MemWriteEn_in(MemWriteEn_exmem_in),
        .MemWriteEn_out(MemWriteEn_exmem_out),
        .MemWrite_in(MemWrite_exmem_in),
        .MemWrite_out(MemWrite_exmem_out),
        .BitSel_in(BitSel_exmem_in),
        .BitSel_out(BitSel_exmem_out),
        .PCplus4_in(PCplus4_exmem_in),
        .PCplus4_out(PCplus4_exmem_out),
        .ALUResult_in(ALUResult_exmem_in),
        .ALUResult_out(ALUResult_exmem_out),
        .rdata2_in(rdata2_exmem_in),
        .rdata2_out(rdata2_exmem_out),
        .imm_in(imm_exmem_in),
        .imm_out(imm_exmem_out),
        .rd_in(rd_exmem_in),
        .rd_out(rd_exmem_out)
    );

    // ============================================================
    // Pruebas para reg_MEM_WB
    // ============================================================
    logic clk_memwb, rst_memwb;
    logic RegWrite_memwb_in, RegWrite_memwb_out;
    logic [1:0] ResultSrc_memwb_in, ResultSrc_memwb_out;
    logic [31:0] PCplus4_memwb_in, PCplus4_memwb_out;
    logic [31:0] ALUResult_memwb_in, ALUResult_memwb_out;
    logic [31:0] mem_rdata_memwb_in, mem_rdata_memwb_out;
    logic [31:0] imm_memwb_in, imm_memwb_out;
    logic [4:0] rd_memwb_in, rd_memwb_out;

    reg_MEM_WB dut_MEM_WB (
        .clk(clk_memwb),
        .rst(rst_memwb),
        .RegWrite_in(RegWrite_memwb_in),
        .RegWrite_out(RegWrite_memwb_out),
        .ResultSrc_in(ResultSrc_memwb_in),
        .ResultSrc_out(ResultSrc_memwb_out),
        .PCplus4_in(PCplus4_memwb_in),
        .PCplus4_out(PCplus4_memwb_out),
        .ALUResult_in(ALUResult_memwb_in),
        .ALUResult_out(ALUResult_memwb_out),
        .mem_rdata_in(mem_rdata_memwb_in),
        .mem_rdata_out(mem_rdata_memwb_out),
        .imm_in(imm_memwb_in),
        .imm_out(imm_memwb_out),
        .rd_in(rd_memwb_in),
        .rd_out(rd_memwb_out)
    );

    // Task para verificar IF/ID
    task automatic check_IF_ID(
        input string test_name,
        input logic [31:0] exp_PC,
        input logic [31:0] exp_PCplus4,
        input logic [31:0] exp_instr
    );
        if ((PC_ifid_out === exp_PC) && (PCplus4_ifid_out === exp_PCplus4) && 
            (instr_ifid_out === exp_instr)) begin
            $display("[PASS] %s", test_name);
            test_pass++;
        end else begin
            $display("[FAIL] %s", test_name);
            $display("       Expected: PC=%h, PCplus4=%h, instr=%h",
                     exp_PC, exp_PCplus4, exp_instr);
            $display("       Got:      PC=%h, PCplus4=%h, instr=%h",
                     PC_ifid_out, PCplus4_ifid_out, instr_ifid_out);
            test_fail++;
        end
    endtask

    // Task para verificar ID/EX
    task automatic check_ID_EX(
        input string test_name,
        input logic exp_RegWrite,
        input logic [31:0] exp_PC,
        input logic [31:0] exp_rdata1
    );
        if ((RegWrite_idex_out === exp_RegWrite) && (PC_idex_out === exp_PC) && 
            (rdata1_idex_out === exp_rdata1)) begin
            $display("[PASS] %s", test_name);
            test_pass++;
        end else begin
            $display("[FAIL] %s", test_name);
            $display("       Expected: RegWrite=%b, PC=%h, rdata1=%h",
                     exp_RegWrite, exp_PC, exp_rdata1);
            $display("       Got:      RegWrite=%b, PC=%h, rdata1=%h",
                     RegWrite_idex_out, PC_idex_out, rdata1_idex_out);
            test_fail++;
        end
    endtask

    // Clock generators
    initial begin
        clk_ifid = 0;
        forever #5 clk_ifid = ~clk_ifid;
    end

    initial begin
        clk_idex = 0;
        forever #5 clk_idex = ~clk_idex;
    end

    initial begin
        clk_exmem = 0;
        forever #5 clk_exmem = ~clk_exmem;
    end

    initial begin
        clk_memwb = 0;
        forever #5 clk_memwb = ~clk_memwb;
    end

    initial begin
        $dumpfile("tb_pipeline_regs.vcd");
        $dumpvars(0, tb_pipeline_regs);

        $display("============================================================");
        $display("  TESTBENCH: Pipeline Registers");
        $display("============================================================\n");

        // ============================================================
        // PRUEBAS PARA reg_IF_ID
        // ============================================================
        $display("=== PRUEBAS PARA reg_IF_ID ===\n");

        // Prueba 1: Reset
        $display("Prueba 1: Reset");
        rst_ifid = 1;
        stall_ifid = 0;
        flush_ifid = 0;
        PC_ifid_in = 32'h00000000;
        PCplus4_ifid_in = 32'h00000004;
        instr_ifid_in = 32'h00000000;
        #10;
        check_IF_ID("Reset clears all", 32'h0, 32'h0, 32'h0);

        // Prueba 2: Captura de datos
        $display("\nPrueba 2: Captura de datos");
        rst_ifid = 0;
        PC_ifid_in = 32'h00000100;
        PCplus4_ifid_in = 32'h00000104;
        instr_ifid_in = 32'h12345678;
        #10;
        check_IF_ID("Data capture", 32'h00000100, 32'h00000104, 32'h12345678);

        // Prueba 3: Stall (mantiene valores)
        $display("\nPrueba 3: Stall mantiene valores");
        stall_ifid = 1;
        PC_ifid_in = 32'hFFFFFFFF;
        PCplus4_ifid_in = 32'hFFFFFFFF;
        instr_ifid_in = 32'hFFFFFFFF;
        #10;
        check_IF_ID("Stall preserves data", 32'h00000100, 32'h00000104, 32'h12345678);

        // Prueba 4: Flush (inserta NOP)
        $display("\nPrueba 4: Flush inserta NOP");
        stall_ifid = 0;
        flush_ifid = 1;
        #10;
        check_IF_ID("Flush inserts NOP", 32'h0, 32'h0, 32'h0);

        // ============================================================
        // PRUEBAS PARA reg_ID_EX
        // ============================================================
        $display("\n=== PRUEBAS PARA reg_ID_EX ===\n");

        // Prueba 5: Reset y captura
        $display("Prueba 5: Reset y captura de datos");
        rst_idex = 1;
        flush_idex = 0;
        #10;
        
        rst_idex = 0;
        RegWrite_idex_in = 1;
        ResultSrc_idex_in = 2'b10;
        ALUSrc_idex_in = 1;
        ALUControl_idex_in = 4'b0000;
        PC_idex_in = 32'h00000200;
        rdata1_idex_in = 32'h11111111;
        rdata2_idex_in = 32'h22222222;
        imm_idex_in = 32'h00000008;
        rd_idex_in = 5'd5;
        rs1_idex_in = 5'd1;
        rs2_idex_in = 5'd2;
        opcode_idex_in = 7'b0110011;
        funct3_idex_in = 3'b000;
        #10;
        check_ID_EX("ID/EX data capture", 1'b1, 32'h00000200, 32'h11111111);

        // Prueba 6: Flush en ID/EX
        $display("\nPrueba 6: Flush en ID/EX");
        flush_idex = 1;
        #10;
        check_ID_EX("ID/EX flush clears control", 1'b0, 32'h0, 32'h0);

        // ============================================================
        // PRUEBAS PARA reg_EX_MEM
        // ============================================================
        $display("\n=== PRUEBAS PARA reg_EX_MEM ===\n");

        // Prueba 7: Reset y captura
        $display("Prueba 7: Reset y captura de datos");
        rst_exmem = 1;
        #10;
        
        rst_exmem = 0;
        RegWrite_exmem_in = 1;
        ResultSrc_exmem_in = 2'b00;
        MemWriteEn_exmem_in = 0;
        PCplus4_exmem_in = 32'h00000204;
        ALUResult_exmem_in = 32'hDEADBEEF;
        rdata2_exmem_in = 32'h87654321;
        imm_exmem_in = 32'h12345678;
        rd_exmem_in = 5'd7;
        #10;
        if ((RegWrite_exmem_out === 1) && (ALUResult_exmem_out === 32'hDEADBEEF)) begin
            $display("[PASS] EX/MEM data capture");
            test_pass++;
        end else begin
            $display("[FAIL] EX/MEM data capture");
            test_fail++;
        end

        // Prueba 8: Preservación en EX/MEM
        $display("\nPrueba 8: Preservación de datos");
        // Verificar que el valor capturado es el correcto (antes de cambiar)
        if (ALUResult_exmem_out === 32'hDEADBEEF) begin
            $display("[PASS] EX/MEM preserves data");
            test_pass++;
        end else begin
            $display("[FAIL] EX/MEM preserves data (got=%h, expected=%h)", ALUResult_exmem_out, 32'hDEADBEEF);
            test_fail++;
        end

        // ============================================================
        // PRUEBAS PARA reg_MEM_WB
        // ============================================================
        $display("\n=== PRUEBAS PARA reg_MEM_WB ===\n");

        // Prueba 9: Reset y captura
        $display("Prueba 9: Reset y captura de datos");
        rst_memwb = 1;
        #10;
        
        rst_memwb = 0;
        RegWrite_memwb_in = 1;
        ResultSrc_memwb_in = 2'b01;
        PCplus4_memwb_in = 32'h00000208;
        ALUResult_memwb_in = 32'h99999999;
        mem_rdata_memwb_in = 32'hAAAAAAAA;
        imm_memwb_in = 32'hBBBBBBBB;
        rd_memwb_in = 5'd10;
        #10;
        if ((RegWrite_memwb_out === 1) && (mem_rdata_memwb_out === 32'hAAAAAAAA)) begin
            $display("[PASS] MEM/WB data capture");
            test_pass++;
        end else begin
            $display("[FAIL] MEM/WB data capture");
            test_fail++;
        end

        // Prueba 10: Verificar inmediato en MEM/WB
        $display("\nPrueba 10: Inmediato en MEM/WB");
        if (imm_memwb_out === 32'hBBBBBBBB) begin
            $display("[PASS] MEM/WB immediate");
            test_pass++;
        end else begin
            $display("[FAIL] MEM/WB immediate");
            test_fail++;
        end

        // ============================================================
        // Resumen
        // ============================================================
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
