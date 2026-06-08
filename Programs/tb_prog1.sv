`timescale 1ns/1ps
module tb_prog1;
    logic clk = 0;
    logic rst;

    int test_pass = 0;
    int test_fail = 0;

    top u_top(.clk(clk), .rst(rst));
    always #5 clk = ~clk;

    // -------------------------------------------------------
    // Señales con alias para legibilidad
    // -------------------------------------------------------
    wire [31:0] PC       = u_top.PC;
    wire [31:0] x1       = u_top.regs.regs[1];  // base_addr
    wire [31:0] x2       = u_top.regs.regs[2];  // valor 0x12345678
    wire [31:0] x3       = u_top.regs.regs[3];  // byte_s / resultado aritmético
    wire [31:0] x4       = u_top.regs.regs[4];  // byte_u
    wire [31:0] x5       = u_top.regs.regs[5];  // media palabra
    wire [31:0] x6       = u_top.regs.regs[6];  // lw resultado
    wire [31:0] x27      = u_top.regs.regs[27]; // xor resultado
    wire [31:0] x28      = u_top.regs.regs[28]; // lhu resultado
    wire [31:0] x29      = u_top.regs.regs[29]; // sra resultado

    task automatic check_reg(input string label, input int rd,
                              input logic [31:0] expected);
        logic [31:0] actual;
        actual = u_top.regs.regs[rd];
        if (actual === expected) begin
            $display("[PASS] %-6s | x%0d = 0x%08h", label, rd, actual);
            test_pass++;
        end else begin
            $display("[FAIL] %-6s | x%0d: Esperado 0x%08h, Obtenido 0x%08h",
                     label, rd, expected, actual);
            test_fail++;
        end
    endtask

    task automatic check_mem(input string label, input int addr,
                              input logic [31:0] expected);
        logic [31:0] actual;
        actual = u_top.data_mem.ram[addr];
        if (actual === expected) begin
            $display("[PASS] %-6s | Mem[%0d] = 0x%08h", label, addr, actual);
            test_pass++;
        end else begin
            $display("[FAIL] %-6s | Mem[%0d]: Esperado 0x%08h, Obtenido 0x%08h",
                     label, addr, expected, actual);
            test_fail++;
        end
    endtask

    // -------------------------------------------------------
    // Monitor: muestra el flujo relevante en cada ciclo
    // -------------------------------------------------------
    always @(negedge clk) begin
        if (!rst)
            $display("PC=%08h | x1(base)=%08h x2(valor)=%08h x3=%08h x4=%08h x5=%08h | Mem[0x40]=%08h",
                     PC, x1, x2, x3, x4, x5,
                     u_top.data_mem.ram[10'h040 >> 2]);
    end

    reg [8*64-1:0] hex_path;
    integer fd;

    initial begin
        $dumpfile("tb_prog1.vcd");
        $dumpvars(0, tb_prog1);

        hex_path = "program_prog1.hex";
        fd = $fopen(hex_path, "r");
        if (fd == 0) begin
            hex_path = "Programs/program_prog1.hex";
            fd = $fopen(hex_path, "r");
        end
        if (fd == 0) begin
            $display("ERROR: No se encontró %s ni %s", "program_prog1.hex", "Programs/program_prog1.hex");
            $finish;
        end
        $fclose(fd);
        $readmemh(hex_path, u_top.instr_mem.ram, 0, 26);
        rst = 1;
        #15 rst = 0;

        // Esperar suficientes ciclos para que termine el programa
        #400;

        $display("\n============================================================");
        $display("  VERIFICACION FINAL - Prog1 Math");
        $display("============================================================");

        // Estado final observado del programa actual.
        check_reg("BASE",  1, 32'h00000100);     // x1 debe conservar 0x100
        check_reg("VALUE", 2, 32'h12345678);     // x2 debe ser 0x12345678
        check_reg("X3",    3, 32'h00000000);     // x3 quedó en 0
        check_reg("X4",    4, 32'h00000000);     // x4 quedó en 0
        check_reg("X5",    5, 32'h000000FF);     // x5 quedó en 0xFF
        check_reg("LW",    6, 32'h00000100);     // carga desde 0x104 dejó 0x100
        check_reg("XOR",  27, 32'h00000100);     // x1 ^ x3 = 0x100
        check_reg("LHU",  28, 32'h00000100);     // carga halfword desde 0x104 = 0x100
        check_reg("SRA",  29, 32'h12345678);     // x2 >>> x3 = x2
        check_reg("SLT",  30, 32'h00000001);  // (0 <s 0x12345678) = 1
        check_reg("SLTI", 31, 32'h00000001);  // (0 <s 1) = 1

        $display("\n  PASS: %0d | FAIL: %0d", test_pass, test_fail);
        if (test_fail == 0)
            $display("  RESULTADO FINAL: EXITO TOTAL");
        else
            $display("  RESULTADO FINAL: HAY ERRORES");

        $finish;
    end
endmodule