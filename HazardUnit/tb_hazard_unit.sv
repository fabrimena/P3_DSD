// ============================================================
// tb_hazard_unit.sv
// Testbench para la unidad de detección y resolución de hazards
//
// Para cada prueba se muestra:
//   - El escenario de pipeline que se está modelando
//   - Los valores de entrada aplicados
//   - Las salidas obtenidas vs esperadas
// ============================================================
`timescale 1ns/1ps

module tb_hazard_unit;

    // -------------------------------------------------------
    // Señales
    // -------------------------------------------------------
    logic [4:0] ID_EX_rs1, ID_EX_rs2, ID_EX_rd;
    logic       ID_EX_ResultSrc1;
    logic [4:0] EX_MEM_rd,  MEM_WB_rd;
    logic       EX_MEM_RegWrite, MEM_WB_RegWrite;
    logic [4:0] IF_ID_rs1, IF_ID_rs2;
    logic       PCSrc;

    logic [1:0] ForwardA, ForwardB;
    logic       stall, flush_ID_EX;

    integer test_pass = 0, test_fail = 0;

    // -------------------------------------------------------
    // DUT
    // -------------------------------------------------------
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

    // -------------------------------------------------------
    // Tarea de verificación: imprime contexto y resultado
    // -------------------------------------------------------
    task automatic check_test(
        input string  test_name,
        input string  scenario,
        input logic [1:0] exp_fwdA,
        input logic [1:0] exp_fwdB,
        input logic exp_stall,
        input logic exp_flush
    );
        logic ok;
        ok = (ForwardA === exp_fwdA) && (ForwardB === exp_fwdB) &&
             (stall   === exp_stall) && (flush_ID_EX === exp_flush);

        $display("  Escenario : %s", scenario);
        $display("  Entradas  : ID_EX_rs1=x%0d  rs2=x%0d  rd=x%0d  ResultSrc1=%b",
                 ID_EX_rs1, ID_EX_rs2, ID_EX_rd, ID_EX_ResultSrc1);
        $display("              EX_MEM_rd=x%0d(RW=%b)  MEM_WB_rd=x%0d(RW=%b)  PCSrc=%b",
                 EX_MEM_rd, EX_MEM_RegWrite, MEM_WB_rd, MEM_WB_RegWrite, PCSrc);
        $display("              IF_ID_rs1=x%0d  IF_ID_rs2=x%0d",
                 IF_ID_rs1, IF_ID_rs2);
        $display("  Esperado  : FwdA=%b  FwdB=%b  stall=%b  flush=%b",
                 exp_fwdA, exp_fwdB, exp_stall, exp_flush);
        $display("  Obtenido  : FwdA=%b  FwdB=%b  stall=%b  flush=%b",
                 ForwardA, ForwardB, stall, flush_ID_EX);

        if (ok) begin
            $display("  [PASS] %s\n", test_name);
            test_pass++;
        end else begin
            $display("  [FAIL] %s\n", test_name);
            test_fail++;
        end
    endtask

    // -------------------------------------------------------
    // Tarea auxiliar: pone todo en estado "sin hazard"
    // -------------------------------------------------------
    task automatic set_idle();
        ID_EX_rs1      = 5'd0;  ID_EX_rs2      = 5'd0;  ID_EX_rd  = 5'd0;
        ID_EX_ResultSrc1 = 1'b0;
        EX_MEM_rd      = 5'd0;  EX_MEM_RegWrite = 1'b0;
        MEM_WB_rd      = 5'd0;  MEM_WB_RegWrite = 1'b0;
        IF_ID_rs1      = 5'd0;  IF_ID_rs2       = 5'd0;
        PCSrc          = 1'b0;
    endtask

    // -------------------------------------------------------
    // Pruebas
    // -------------------------------------------------------
    initial begin
        $dumpfile("tb_hazard_unit.vcd");
        $dumpvars(0, tb_hazard_unit);

        $display("============================================================");
        $display("  TESTBENCH: Hazard Unit");
        $display("  Muestra: escenario | entradas aplicadas | salidas");
        $display("============================================================\n");

        // ----------------------------------------------------------
        // P1: Sin ningún hazard → no forwarding, no stall, no flush
        // ----------------------------------------------------------
        $display("=== Prueba 1: Sin hazard (estado idle) ===");
        set_idle(); #1;
        check_test(
            "No hazard",
            "Instrucciones independientes, registros distintos",
            2'b00, 2'b00, 1'b0, 1'b0
        );

        // ----------------------------------------------------------
        // P2: EX hazard en rs1
        //   EX: add x5, x1, x2   → escribe x5 (en EX/MEM)
        //   ID: add x3, x5, x4   → lee x5 (rs1) → forward desde EX/MEM
        // ----------------------------------------------------------
        $display("=== Prueba 2: Forwarding EX/MEM → rs1 ===");
        set_idle();
        ID_EX_rs1 = 5'd5;   // instrucción en EX lee x5 como rs1
        ID_EX_rs2 = 5'd4;
        EX_MEM_rd = 5'd5;   EX_MEM_RegWrite = 1'b1;  // x5 está en EX/MEM
        #1;
        check_test(
            "Forward EX/MEM to rs1",
            "EX/MEM.rd==ID_EX.rs1, EX/MEM.RegWrite=1 → ForwardA=10",
            2'b10, 2'b00, 1'b0, 1'b0
        );

        // ----------------------------------------------------------
        // P3: EX hazard en rs2
        //   EX: sw x5, 0(x6)  → lee x5 como rs2
        //   MEM: add x5, ...  → x5 está en EX/MEM
        // ----------------------------------------------------------
        $display("=== Prueba 3: Forwarding EX/MEM → rs2 ===");
        set_idle();
        ID_EX_rs1 = 5'd4;
        ID_EX_rs2 = 5'd5;   // instrucción en EX lee x5 como rs2
        EX_MEM_rd = 5'd5;   EX_MEM_RegWrite = 1'b1;
        #1;
        check_test(
            "Forward EX/MEM to rs2",
            "EX/MEM.rd==ID_EX.rs2, EX/MEM.RegWrite=1 → ForwardB=10",
            2'b00, 2'b10, 1'b0, 1'b0
        );

        // ----------------------------------------------------------
        // P4: MEM hazard en rs1 (x5 ya salió de EX/MEM, está en MEM/WB)
        // ----------------------------------------------------------
        $display("=== Prueba 4: Forwarding MEM/WB → rs1 ===");
        set_idle();
        ID_EX_rs1 = 5'd3;
        EX_MEM_rd = 5'd0;   EX_MEM_RegWrite = 1'b0;  // nadie en EX/MEM sobre x3
        MEM_WB_rd = 5'd3;   MEM_WB_RegWrite = 1'b1;  // x3 está en MEM/WB
        #1;
        check_test(
            "Forward MEM/WB to rs1",
            "MEM_WB.rd==ID_EX.rs1, MEM_WB.RegWrite=1 → ForwardA=01",
            2'b01, 2'b00, 1'b0, 1'b0
        );

        // ----------------------------------------------------------
        // P5: MEM hazard en rs2
        // ----------------------------------------------------------
        $display("=== Prueba 5: Forwarding MEM/WB → rs2 ===");
        set_idle();
        ID_EX_rs2 = 5'd6;
        EX_MEM_rd = 5'd0;   EX_MEM_RegWrite = 1'b0;
        MEM_WB_rd = 5'd6;   MEM_WB_RegWrite = 1'b1;
        #1;
        check_test(
            "Forward MEM/WB to rs2",
            "MEM_WB.rd==ID_EX.rs2, MEM_WB.RegWrite=1 → ForwardB=01",
            2'b00, 2'b01, 1'b0, 1'b0
        );

        // ----------------------------------------------------------
        // P6: Prioridad EX/MEM > MEM/WB (mismo registro en ambas etapas)
        //   Ocurre si dos instrucciones consecutivas escriben el mismo rd
        // ----------------------------------------------------------
        $display("=== Prueba 6: Prioridad EX/MEM sobre MEM/WB (mismo rd) ===");
        set_idle();
        ID_EX_rs1 = 5'd7;
        EX_MEM_rd = 5'd7;   EX_MEM_RegWrite = 1'b1;  // valor más nuevo
        MEM_WB_rd = 5'd7;   MEM_WB_RegWrite = 1'b1;  // valor más viejo
        #1;
        check_test(
            "Priority EX/MEM over MEM/WB",
            "Mismo rd en EX/MEM y MEM/WB → se elige EX/MEM (ForwardA=10)",
            2'b10, 2'b00, 1'b0, 1'b0
        );

        // ----------------------------------------------------------
        // P7: Load-use hazard por rs1
        //   EX: lw x8, 0(x1)   → ID_EX_rd=x8, ResultSrc1=1
        //   ID: add x3, x8, x2 → IF_ID_rs1=x8 → stall 1 ciclo
        // ----------------------------------------------------------
        $display("=== Prueba 7: Load-use hazard (rs1) ===");
        set_idle();
        ID_EX_ResultSrc1 = 1'b1;  // instrucción en EX es LOAD
        ID_EX_rd  = 5'd8;         // LOAD escribe en x8
        IF_ID_rs1 = 5'd8;         // siguiente instrucción necesita x8
        #1;
        check_test(
            "Load-use hazard via rs1",
            "LOAD x8 en EX, siguiente instruccion lee rs1=x8 → stall+flush",
            2'b00, 2'b00, 1'b1, 1'b1
        );

        // ----------------------------------------------------------
        // P8: Load-use hazard por rs2
        //   EX: lw x8, 4(x1)   → ID_EX_rd=x8
        //   ID: sw x8, 8(x2)   → IF_ID_rs2=x8 → stall
        // ----------------------------------------------------------
        $display("=== Prueba 8: Load-use hazard (rs2) ===");
        set_idle();
        ID_EX_ResultSrc1 = 1'b1;
        ID_EX_rd  = 5'd8;
        IF_ID_rs2 = 5'd8;         // necesita x8 en rs2
        #1;
        check_test(
            "Load-use hazard via rs2",
            "LOAD x8 en EX, siguiente instruccion lee rs2=x8 → stall+flush",
            2'b00, 2'b00, 1'b1, 1'b1
        );

        // ----------------------------------------------------------
        // P9: No stall si rd == x0 aunque ResultSrc1=1
        //   x0 es siempre cero, nunca genera hazard real
        // ----------------------------------------------------------
        $display("=== Prueba 9: No stall si LOAD rd=x0 ===");
        set_idle();
        ID_EX_ResultSrc1 = 1'b1;
        ID_EX_rd  = 5'd0;         // destino x0: no importa
        IF_ID_rs1 = 5'd0;
        IF_ID_rs2 = 5'd0;
        #1;
        check_test(
            "No stall for x0 destination",
            "LOAD a x0 nunca produce stall (x0 siempre es 0)",
            2'b00, 2'b00, 1'b0, 1'b0
        );

        // ----------------------------------------------------------
        // P10: Flush por branch/jump resuelto en EX (PCSrc=1)
        //   Se deben anular las 2 instrucciones fetched de más
        // ----------------------------------------------------------
        $display("=== Prueba 10: Flush por branch tomado (PCSrc=1) ===");
        set_idle();
        PCSrc = 1'b1;   // salto resuelto → flush
        #1;
        check_test(
            "Flush on branch taken",
            "PCSrc=1 → vaciar IF/ID e ID/EX (2 NOPs)",
            2'b00, 2'b00, 1'b0, 1'b1
        );

        // ----------------------------------------------------------
        // P11: Load-use + PCSrc simultáneos
        //   Stall tiene precedencia; flush también activo
        // ----------------------------------------------------------
        $display("=== Prueba 11: Load-use hazard + PCSrc simultáneos ===");
        set_idle();
        ID_EX_ResultSrc1 = 1'b1;
        ID_EX_rd  = 5'd9;
        IF_ID_rs1 = 5'd9;
        PCSrc     = 1'b1;
        #1;
        check_test(
            "Load-use + branch simultaneous",
            "Ambas condiciones activas → stall=1, flush=1",
            2'b00, 2'b00, 1'b1, 1'b1
        );

        // ----------------------------------------------------------
        // P12: Forwarding no activa cuando RegWrite=0
        // ----------------------------------------------------------
        $display("=== Prueba 12: Sin forwarding si RegWrite=0 ===");
        set_idle();
        ID_EX_rs1 = 5'd4;
        EX_MEM_rd = 5'd4;   EX_MEM_RegWrite = 1'b0;  // no escribe
        MEM_WB_rd = 5'd4;   MEM_WB_RegWrite = 1'b0;  // no escribe
        #1;
        check_test(
            "No forward when RegWrite=0",
            "EX/MEM y MEM/WB tienen el mismo rd pero RegWrite=0 → sin forward",
            2'b00, 2'b00, 1'b0, 1'b0
        );

        // ----------------------------------------------------------
        // P13: Forwarding doble (rs1 de MEM/WB, rs2 de EX/MEM)
        // ----------------------------------------------------------
        $display("=== Prueba 13: Forwarding doble (rs1 y rs2 distintos) ===");
        set_idle();
        ID_EX_rs1 = 5'd3;   // rs1 viene de MEM/WB
        ID_EX_rs2 = 5'd5;   // rs2 viene de EX/MEM
        EX_MEM_rd = 5'd5;   EX_MEM_RegWrite = 1'b1;
        MEM_WB_rd = 5'd3;   MEM_WB_RegWrite = 1'b1;
        #1;
        check_test(
            "Double forward: rs1 from MEM/WB, rs2 from EX/MEM",
            "FwdA=01 (MEM/WB→rs1) y FwdB=10 (EX/MEM→rs2) simultáneos",
            2'b01, 2'b10, 1'b0, 1'b0
        );

        // ----------------------------------------------------------
        // Resumen
        // ----------------------------------------------------------
        $display("============================================================");
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