// ============================================================
// tb_hazard_unit.sv
// Testbench para la unidad de detección y resolución de hazards
// ============================================================
`timescale 1ns/1ps

module tb_hazard_unit;
    // Señales de entrada
    logic [4:0] ID_EX_rs1, ID_EX_rs2, ID_EX_rd;
    logic       ID_EX_ResultSrc1;
    logic [4:0] EX_MEM_rd, MEM_WB_rd;
    logic       EX_MEM_RegWrite, MEM_WB_RegWrite;
    logic [4:0] IF_ID_rs1, IF_ID_rs2;
    logic       PCSrc;

    // Señales de salida
    logic [1:0] ForwardA, ForwardB;
    logic       stall, flush_ID_EX;

    // Variables de prueba
    integer test_pass = 0, test_fail = 0;

    // Instancia de DUT
    hazard_unit dut (
        .ID_EX_rs1      (ID_EX_rs1),
        .ID_EX_rs2      (ID_EX_rs2),
        .ID_EX_ResultSrc1(ID_EX_ResultSrc1),
        .ID_EX_rd       (ID_EX_rd),
        .EX_MEM_rd      (EX_MEM_rd),
        .EX_MEM_RegWrite(EX_MEM_RegWrite),
        .MEM_WB_rd      (MEM_WB_rd),
        .MEM_WB_RegWrite(MEM_WB_RegWrite),
        .IF_ID_rs1      (IF_ID_rs1),
        .IF_ID_rs2      (IF_ID_rs2),
        .PCSrc          (PCSrc),
        .ForwardA       (ForwardA),
        .ForwardB       (ForwardB),
        .stall          (stall),
        .flush_ID_EX    (flush_ID_EX)
    );

    // Task para verificar resultados
    task automatic check_test(
        input string test_name,
        input logic [1:0] exp_fwdA,
        input logic [1:0] exp_fwdB,
        input logic exp_stall,
        input logic exp_flush
    );
        if ((ForwardA === exp_fwdA) && (ForwardB === exp_fwdB) && 
            (stall === exp_stall) && (flush_ID_EX === exp_flush)) begin
            $display("[PASS] %s", test_name);
            test_pass++;
        end else begin
            $display("[FAIL] %s", test_name);
            $display("       Expected: ForwardA=%b, ForwardB=%b, stall=%b, flush=%b",
                     exp_fwdA, exp_fwdB, exp_stall, exp_flush);
            $display("       Got:      ForwardA=%b, ForwardB=%b, stall=%b, flush=%b",
                     ForwardA, ForwardB, stall, flush_ID_EX);
            test_fail++;
        end
    endtask

    initial begin
        $dumpfile("tb_hazard_unit.vcd");
        $dumpvars(0, tb_hazard_unit);

        $display("============================================================");
        $display("  TESTBENCH: Hazard Unit");
        $display("============================================================\n");

        // ============================================================
        // Prueba 1: Sin hazard (estado idle)
        // ============================================================
        $display("=== Prueba 1: Sin hazard ===");
        ID_EX_rs1 = 5'b00000; ID_EX_rs2 = 5'b00000; ID_EX_rd = 5'b00000;
        ID_EX_ResultSrc1 = 1'b0;
        EX_MEM_rd = 5'b00000; EX_MEM_RegWrite = 1'b0;
        MEM_WB_rd = 5'b00000; MEM_WB_RegWrite = 1'b0;
        IF_ID_rs1 = 5'b00000; IF_ID_rs2 = 5'b00000;
        PCSrc = 1'b0;
        #1;
        check_test("No hazard", 2'b00, 2'b00, 1'b0, 1'b0);

        // ============================================================
        // Prueba 2: Forwarding desde EX/MEM para rs1
        // ============================================================
        $display("\n=== Prueba 2: Forwarding EX/MEM -> rs1 ===");
        ID_EX_rs1 = 5'd5;  // Lee de x5
        ID_EX_rs2 = 5'd6;  // Lee de x6
        ID_EX_rd = 5'd1;
        ID_EX_ResultSrc1 = 1'b0;  // No es LOAD
        EX_MEM_rd = 5'd5;  // x5 es el destino
        EX_MEM_RegWrite = 1'b1;
        MEM_WB_rd = 5'b00000;
        MEM_WB_RegWrite = 1'b0;
        IF_ID_rs1 = 5'b00000;
        IF_ID_rs2 = 5'b00000;
        PCSrc = 1'b0;
        #1;
        check_test("Forward EX/MEM to rs1", 2'b10, 2'b00, 1'b0, 1'b0);

        // ============================================================
        // Prueba 3: Forwarding desde EX/MEM para rs2
        // ============================================================
        $display("\n=== Prueba 3: Forwarding EX/MEM -> rs2 ===");
        ID_EX_rs1 = 5'd4;
        ID_EX_rs2 = 5'd5;  // Lee de x5
        ID_EX_rd = 5'd1;
        EX_MEM_rd = 5'd5;  // x5 es el destino
        EX_MEM_RegWrite = 1'b1;
        MEM_WB_rd = 5'b00000;
        MEM_WB_RegWrite = 1'b0;
        #1;
        check_test("Forward EX/MEM to rs2", 2'b00, 2'b10, 1'b0, 1'b0);

        // ============================================================
        // Prueba 4: Forwarding desde MEM/WB (cuando no hay EX/MEM)
        // ============================================================
        $display("\n=== Prueba 4: Forwarding MEM/WB ===");
        ID_EX_rs1 = 5'd3;
        ID_EX_rs2 = 5'd4;
        ID_EX_rd = 5'd1;
        EX_MEM_rd = 5'b00000;  // x0 no escribe
        EX_MEM_RegWrite = 1'b0;
        MEM_WB_rd = 5'd3;  // x3 es el destino en MEM/WB
        MEM_WB_RegWrite = 1'b1;
        #1;
        check_test("Forward MEM/WB to rs1", 2'b01, 2'b00, 1'b0, 1'b0);

        // ============================================================
        // Prueba 5: Prioridad EX/MEM > MEM/WB
        // ============================================================
        $display("\n=== Prueba 5: Prioridad EX/MEM > MEM/WB ===");
        ID_EX_rs1 = 5'd7;
        ID_EX_rs2 = 5'b00000;
        EX_MEM_rd = 5'd7;
        EX_MEM_RegWrite = 1'b1;
        MEM_WB_rd = 5'd7;  // Mismo registro en ambas etapas
        MEM_WB_RegWrite = 1'b1;
        #1;
        // Debe elegir EX/MEM (2'b10) en lugar de MEM/WB (2'b01)
        check_test("Priority EX/MEM over MEM/WB", 2'b10, 2'b00, 1'b0, 1'b0);

        // ============================================================
        // Prueba 6: Load-use hazard (stall)
        // ============================================================
        $display("\n=== Prueba 6: Load-use hazard ===");
        ID_EX_ResultSrc1 = 1'b1;  // Es LOAD
        ID_EX_rd = 5'd8;  // x8 es el destino de la LOAD
        ID_EX_rs1 = 5'b00000;
        ID_EX_rs2 = 5'b00000;
        EX_MEM_rd = 5'b00000;
        EX_MEM_RegWrite = 1'b0;
        MEM_WB_rd = 5'b00000;
        MEM_WB_RegWrite = 1'b0;
        IF_ID_rs1 = 5'd8;  // Próxima instr usa x8 (rs1)
        IF_ID_rs2 = 5'b00000;
        PCSrc = 1'b0;
        #1;
        check_test("Load-use hazard (stall)", 2'b00, 2'b00, 1'b1, 1'b1);

        // ============================================================
        // Prueba 7: Load-use hazard con rs2
        // ============================================================
        $display("\n=== Prueba 7: Load-use hazard (rs2) ===");
        IF_ID_rs1 = 5'b00000;
        IF_ID_rs2 = 5'd8;  // Próxima instr usa x8 (rs2)
        #1;
        check_test("Load-use hazard (rs2)", 2'b00, 2'b00, 1'b1, 1'b1);

        // ============================================================
        // Prueba 8: No stall si rd=x0
        // ============================================================
        $display("\n=== Prueba 8: No stall si rd=x0 ===");
        ID_EX_rd = 5'b00000;  // x0 nunca genera stall
        ID_EX_ResultSrc1 = 1'b1;  // Es LOAD
        IF_ID_rs1 = 5'b00000;
        IF_ID_rs2 = 5'b00000;
        #1;
        check_test("No stall for x0", 2'b00, 2'b00, 1'b0, 1'b0);

        // ============================================================
        // Prueba 9: Flush por branch/jump (PCSrc=1)
        // ============================================================
        $display("\n=== Prueba 9: Flush por branch ===");
        ID_EX_ResultSrc1 = 1'b0;
        ID_EX_rd = 5'd1;
        PCSrc = 1'b1;  // Branch tomado
        IF_ID_rs1 = 5'b00000;
        IF_ID_rs2 = 5'b00000;
        #1;
        check_test("Flush on branch", 2'b00, 2'b00, 1'b0, 1'b1);

        // ============================================================
        // Prueba 10: x0 no genera forwarding
        // ============================================================
        $display("\n=== Prueba 10: x0 no genera forwarding ===");
        ID_EX_rs1 = 5'b00000;
        ID_EX_rs2 = 5'b00000;
        EX_MEM_rd = 5'b00000;  // x0
        EX_MEM_RegWrite = 1'b1;
        MEM_WB_rd = 5'b00000;
        MEM_WB_RegWrite = 1'b0;
        PCSrc = 1'b0;
        #1;
        check_test("x0 never forwards", 2'b00, 2'b00, 1'b0, 1'b0);

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
