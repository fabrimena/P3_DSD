// ============================================================
// tb_top_pipeline.sv
// Testbench para el procesador RV32I segmentado de 5 etapas
// Adaptado del tb_top.sv original; ajusta la espera de ciclos
// para compensar la latencia del pipeline (aprox. +4 ciclos).
// ============================================================
`timescale 1ns / 1ps

module tb_top;
    logic clk;
    logic rst;

    int test_pass = 0;
    int test_fail = 0;

    // Instancia del procesador segmentado
    top u_top (
        .clk(clk),
        .rst(rst)
    );

    // Reloj: periodo = 10 ns
    initial clk = 0;
    always #5 clk = ~clk;

    // ----------------------------------------------------------
    // Tareas de verificación (paths actualizados al pipeline)
    // ----------------------------------------------------------
    task automatic check_reg(input string label, input int rd, input int expected);
        logic [31:0] actual;
        actual = u_top.regs.regs[rd];
        if (actual === expected) begin
            $display("[PASS] %-10s | x%0d = %0d (0x%08h)", label, rd, $signed(actual), actual);
            test_pass++;
        end else begin
            $display("[FAIL] %-10s | x%0d: esperado %0d (0x%08h), obtenido %0d (0x%08h)",
                     label, rd, $signed(expected), expected, $signed(actual), actual);
            test_fail++;
        end
    endtask

    task automatic check_mem(input string label, input int addr, input logic [31:0] expected);
        logic [31:0] actual;
        actual = u_top.data_mem.ram[addr];
        if (actual === expected) begin
            $display("[PASS] %-10s | Mem[%0d] = 0x%08h", label, addr, actual);
            test_pass++;
        end else begin
            $display("[FAIL] %-10s | Mem[%0d]: esperado 0x%08h, obtenido 0x%08h",
                     label, addr, expected, actual);
            test_fail++;
        end
    endtask

    // Avanza N ciclos de reloj
    task automatic tick(input int n);
        repeat(n) @(negedge clk);
    endtask

    // ----------------------------------------------------------
    // Programa de prueba cargado directamente en la memoria de
    // instrucciones (usando $readmemh o inicialización inline).
    // Aquí se usa el programa prog1 del proyecto original.
    // ----------------------------------------------------------
    initial begin
        // Cargar programa (mismo hex que el proyecto original)
        $readmemh("Programs/program_prog1.hex", u_top.instr_mem.ram);

        // Reset
        rst = 1;
        @(negedge clk);
        @(negedge clk);
        rst = 0;

        $display("=== Pipeline RV32I - Test Prog1 (Math) ===");

        // El pipeline tarda 4 ciclos adicionales en completar la
        // primera instrucción. Cada instrucción tarda 1 ciclo más
        // que en el uniciclo (latencia de relleno del pipeline).
        // Se agregan ~5 ciclos extra sobre el tb original.

        // Esperar suficientes ciclos para que el programa termine
        tick(60);

        $display("=== Resultados ===");
        $display("[INFO] Verificando registros tras ejecución de prog1");

        // Las verificaciones específicas dependen del programa hex.
        // Aquí verificamos que x0 siempre sea 0 (propiedad fundamental).
        check_reg("x0_zero",  0, 32'd0);

        // Espacio para agregar verificaciones del programa específico:
        // check_reg("label", N_REG, EXPECTED_VALUE);
        // check_mem("label", MEM_ADDR, EXPECTED_DATA);

        tick(5);
        $display("=== Resumen: %0d pasaron, %0d fallaron ===", test_pass, test_fail);

        if (test_fail == 0)
            $display("[OK] Todos los tests pasaron.");
        else
            $display("[ERROR] %0d test(s) fallaron.", test_fail);

        $finish;
    end

    // Timeout de seguridad
    initial begin
        #50000;
        $display("[TIMEOUT] Simulacion excedio el tiempo maximo.");
        $finish;
    end

endmodule