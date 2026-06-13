// ============================================================
// tb_branch_predictor.sv
//
// Testbench para branch_predictor.sv
// Verifica:
//   1. Inicialización en NOT_TAKEN (predicción conservadora)
//   2. Saturación hacia STRONGLY_TAKEN tras 2 saltos tomados
//   3. Saturación hacia STRONGLY_NOT_TAKEN tras 2 no-tomados
//   4. Corrección del BTB al pasar el pc_target real desde EX
//   5. Comportamiento con is_branch_if = 0 (debe dar 0)
// ============================================================
`timescale 1ns/1ps

module tb_branch_predictor;

    // ── DUT ports ────────────────────────────────────────────
    logic        clk, rst;
    logic [31:0] pc_if;
    logic        is_branch_if;
    logic        bp_taken;
    logic [31:0] bp_target;
    logic        update_en;
    logic        branch_taken_ex;
    logic [31:0] pc_ex;
    logic [31:0] pc_target_ex;

    branch_predictor #(.ENTRIES(64)) dut (.*);

    // ── Clock ─────────────────────────────────────────────────
    initial clk = 0;
    always #5 clk = ~clk;   // 100 MHz

    // ── Task: mostrar estado ──────────────────────────────────
    task automatic show(input string msg);
        $display("[%0t] %-40s | bp_taken=%b  bp_target=0x%08h",
                 $time, msg, bp_taken, bp_target);
    endtask

    // ── Tarea: aplicar actualización desde EX ─────────────────
    task automatic ex_update(input logic taken, input logic [31:0] target);
        @(negedge clk);
        update_en      = 1;
        branch_taken_ex = taken;
        pc_target_ex   = target;
        @(posedge clk); #1;
        update_en = 0;
    endtask

    // ── Test principal ────────────────────────────────────────
    initial begin
        $dumpfile("tb_branch_predictor.vcd");
        $dumpvars(0, tb_branch_predictor);

        // Reset
        rst = 1; update_en = 0; is_branch_if = 0;
        pc_if = 32'h0000_0010; pc_ex = pc_if;
        pc_target_ex = 32'h0000_0100;
        @(posedge clk); @(posedge clk); #1;
        rst = 0;

        // ──────────────────────────────────────────────────────
        // Test 1: After reset, prediction must be NOT_TAKEN (=0)
        // ──────────────────────────────────────────────────────
        is_branch_if = 1;
        #1; show("T1: After reset (expect NOT TAKEN)");
        assert (bp_taken == 1'b0) else $error("FALLO T1: esperado bp_taken=0");

        // ──────────────────────────────────────────────────────
        // Test 2: One update TAKEN → state becomes TAKEN (predict 1)
        // ──────────────────────────────────────────────────────
        pc_ex = pc_if;
        ex_update(1'b1, 32'h0000_0100);
        @(posedge clk); #1;
        show("T2: After 1 taken update (expect TAKEN=1)");
        assert (bp_taken == 1'b1) else $error("FALLO T2: esperado bp_taken=1");
        assert (bp_target == 32'h0000_0100) else $error("FALLO T2: BTB incorrecto");

        // ──────────────────────────────────────────────────────
        // Test 3: Second TAKEN → STRONGLY_TAKEN (still predict 1)
        // ──────────────────────────────────────────────────────
        ex_update(1'b1, 32'h0000_0100);
        @(posedge clk); #1;
        show("T3: After 2 taken (expect STRONGLY_TAKEN=1)");
        assert (bp_taken == 1'b1) else $error("FALLO T3");

        // ──────────────────────────────────────────────────────
        // Test 4: One NOT_TAKEN → TAKEN (still predict 1)
        // ──────────────────────────────────────────────────────
        ex_update(1'b0, 32'h0000_0100);
        @(posedge clk); #1;
        show("T4: After 1 not-taken from ST (expect TAKEN=1)");
        assert (bp_taken == 1'b1) else $error("FALLO T4");

        // ──────────────────────────────────────────────────────
        // Test 5: Second NOT_TAKEN → NOT_TAKEN (predict 0)
        // ──────────────────────────────────────────────────────
        ex_update(1'b0, 32'h0000_0100);
        @(posedge clk); #1;
        show("T5: After 2 not-taken (expect NOT_TAKEN=0)");
        assert (bp_taken == 1'b0) else $error("FALLO T5");

        // ──────────────────────────────────────────────────────
        // Test 6: is_branch_if=0 → predictor must output 0
        // ──────────────────────────────────────────────────────
        is_branch_if = 0;
        ex_update(1'b1, 32'hDEAD_BEEF);
        @(posedge clk); #1;
        show("T6: is_branch_if=0 (expect bp_taken=0)");
        assert (bp_taken == 1'b0) else $error("FALLO T6: bp_taken debe ser 0 si no es branch");

        // ──────────────────────────────────────────────────────
        // Test 7: Diferente PC → diferente entrada de la BHT
        // ──────────────────────────────────────────────────────
        is_branch_if = 1;
        pc_if = 32'h0000_0040;   // índice diferente (PC[7:2]=0x10)
        #1; show("T7: Diferente PC, debe ser NOT_TAKEN (inicial)");
        assert (bp_taken == 1'b0) else $error("FALLO T7: entradas BHT independientes");

        $display("\n=== Todos los tests pasaron ===");
        #20 $finish;
    end

endmodule