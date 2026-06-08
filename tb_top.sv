// ============================================================
// tb_top.sv  —  Self-checking testbench para el pipeline RV32I
//
// CORRECCIONES respecto al tb_top del documento de referencia:
//
//  1. DOBLE RST: el initial original llamaba rst=0 DOS veces.
//     FIX: un único rst=0.
//
//  2. PRE-CARGA BORRADA POR RESET: reg_file tiene reset síncrono
//     en posedge. Cualquier valor escrito en regs[] con rst=1
//     activo es borrado en el siguiente posedge. Lo mismo aplica
//     a data_mem (single_port_ram con reset implícito via wr_en).
//     FIX: las asignaciones a regs[] y ram[] se hacen DESPUÉS del
//     primer posedge con rst=0 y ANTES del primer posedge útil,
//     usando @(posedge clk) + #1 para escribir en zona segura.
//
//  3. LATENCIA DEL PIPELINE: resultados visibles 4 negedges
//     después del fetch. Se añaden 3 show_pad de drenaje al inicio.
//
//  4. PC DE BRANCHES: verificar 1 negedge después del que fallaba
//     en el tb original (el salto se resuelve en EX, el nuevo PC
//     aparece en IF un ciclo después).
// ============================================================
`timescale 1ns / 1ps

module tb_top;
    logic clk;
    logic rst;

    int step      = 0;
    int test_pass = 0;
    int test_fail = 0;
    localparam int REQUIRED_TESTS = 34;

    top u_top (
        .clk(clk),
        .rst(rst)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // ----------------------------------------------------------
    // Tareas de verificación
    // ----------------------------------------------------------
    task automatic check_reg(
        input string label,
        input int    rd,
        input int    expected
    );
        logic [31:0] actual;
        actual = u_top.regs.regs[rd];
        if (actual === expected) begin
            $display("[PASS] %-7s | x%0d = %0d (0x%08h)",
                     label, rd, $signed(actual), actual);
            test_pass++;
        end else begin
            $display("[FAIL] %-7s | ERROR en x%0d: Esperado %0d (0x%08h), Obtenido %0d (0x%08h)",
                     label, rd,
                     $signed(expected), expected,
                     $signed(actual),   actual);
            test_fail++;
        end
    endtask

    task automatic check_mem(
        input string       label,
        input int          addr,
        input logic [31:0] expected
    );
        logic [31:0] actual;
        actual = u_top.data_mem.ram[addr];
        if (actual === expected) begin
            $display("[PASS] %-7s | Mem[%0d] = 0x%08h", label, addr, actual);
            test_pass++;
        end else begin
            $display("[FAIL] %-7s | ERROR en Mem[%0d]: Esperado 0x%08h, Obtenido 0x%08h",
                     label, addr, expected, actual);
            test_fail++;
        end
    endtask

    task automatic check_pc(
        input string       label,
        input logic [31:0] expected_pc
    );
        logic [31:0] actual_pc;
        actual_pc = u_top.PC;
        if (actual_pc === expected_pc) begin
            $display("[PASS] %-7s | PC = 0x%08h", label, actual_pc);
            test_pass++;
        end else begin
            $display("[FAIL] %-7s | ERROR en PC: Esperado 0x%08h, Obtenido 0x%08h",
                     label, expected_pc, actual_pc);
            test_fail++;
        end
    endtask

    task automatic show_pad(input string label);
        $display("[INFO] %-7s | drenando pipeline...", label);
    endtask

    // ----------------------------------------------------------
    // Monitor negedge — un paso por ciclo desde rst=0
    // ----------------------------------------------------------
    always @(negedge clk) begin
        if (!rst) begin
            case (step)
                // 3 ciclos de drenaje (pipeline fill: 4 etapas post-IF)
                0: show_pad("FILL1");
                1: show_pad("FILL2");
                2: show_pad("FILL3");

                // Resultados alineados al negedge en que WB ya ocurrió
                3:  check_reg("LUI",   1,  32'h00000000);
                4:  check_reg("ADDI",  1,  32'd16);
                5:  show_pad("NOP");
                6:  show_pad("NOP");
                7:  check_reg("ADD",   4,  32'd4);
                8:  check_reg("SUB",   5,  32'd6);
                9:  check_reg("ANDI",  6,  32'd2);
                10: check_reg("ORI",   7,  32'd10);
                11: check_reg("XORI",  8, -32'd11);
                12: check_reg("SLLI",  9,  32'd20);
                13: check_reg("SRLI", 10,  32'd10);
                14: check_reg("SRAI", 11, -32'd1);
                15: check_reg("SLTI", 12,  32'd1);
                16: check_reg("SLTIU",13,  32'd0);
                17: check_reg("AND",  14,  32'd0);
                18: check_reg("OR",   15,  32'd1);
                19: check_reg("XOR",  16,  32'd1);
                20: check_reg("SLL",  17,  32'd10);
                21: check_reg("SRL",  18,  32'd5);
                22: check_reg("SRA",  19, -32'd1);
                23: check_reg("SLT",  20,  32'd1);
                24: check_reg("SLTU", 21,  32'd0);
                // Stores: MEM escribe 1 ciclo antes de WB
                25: check_mem("SW",    1,  32'h00000010);
                26: check_mem("SH",    2,  32'h00000010);
                27: check_mem("SB",    2,  32'h10000010);
                // Loads
                28: check_reg("LW",   22,  32'hDEAD8080);
                29: check_reg("LH",   23,  32'hFFFF8080);
                30: check_reg("LHU",  24,  32'h00008080);
                31: check_reg("LB",   25,  32'hFFFFFF80);
                32: show_pad("NOP");
                33: check_reg("LBU",  26,  32'h00000080);
                // Branches/Jumps: PC verificado 2 negedges post-fetch
                34: check_pc("BEQ",  32'h00000080);
                35: show_pad("NOP");
                36: check_pc("BGE",  32'h00000088);
                37: show_pad("NOP");
                38: check_pc("BLT",  32'h00000090);
                39: show_pad("NOP");
                40: check_pc("BNE",  32'h00000098);
                41: show_pad("NOP");
                42: check_pc("JAL",  32'h000000A0);
                43: show_pad("ADDI");
                44: show_pad("NOP");
                45: check_pc("JALR", 32'h000000AC);
                default: ;
            endcase
            step++;
        end
    end

    // ----------------------------------------------------------
    // Estímulos
    // ----------------------------------------------------------
    initial begin
        $dumpfile("tb_top_sim.vcd");
        $dumpvars(0, tb_top);

        // ── Fase 1: instrucciones se cargan durante el reset ──
        // La instruction memory es ROM combinatoria, no tiene reset.
        rst = 1;
        @(negedge clk);  // asegurar estado estable

        u_top.instr_mem.ram[0]  = 32'h000000B7; // lui   x1, 0          → x1 = 0x00000000
        u_top.instr_mem.ram[1]  = 32'h01008093; // addi  x1, x1, 16     → x1 = 16
        u_top.instr_mem.ram[2]  = 32'h00000013; // nop
        u_top.instr_mem.ram[3]  = 32'h00000013; // nop
        u_top.instr_mem.ram[4]  = 32'h00310233; // add   x4, x2, x3     → (-1)+5 = 4
        u_top.instr_mem.ram[5]  = 32'h402182B3; // sub   x5, x3, x2     → 5-(-1) = 6
        u_top.instr_mem.ram[6]  = 32'h0032F313; // andi  x6, x5, 3      → 6&3 = 2
        u_top.instr_mem.ram[7]  = 32'h00836393; // ori   x7, x6, 8      → 2|8 = 10
        u_top.instr_mem.ram[8]  = 32'hFFF3C413; // xori  x8, x7, -1     → 10^-1 = -11
        u_top.instr_mem.ram[9]  = 32'h00219493; // slli  x9, x3, 2      → 5<<2 = 20
        u_top.instr_mem.ram[10] = 32'h0014D513; // srli  x10, x9, 1     → 20>>1 = 10
        u_top.instr_mem.ram[11] = 32'h40115593; // srai  x11, x2, 1     → -1>>>1 = -1
        u_top.instr_mem.ram[12] = 32'h0005A613; // slti  x12, x11, 0    → (-1<0) = 1
        u_top.instr_mem.ram[13] = 32'h0005B693; // sltiu x13, x11, 0    → 0
        u_top.instr_mem.ram[14] = 32'h00D67733; // and   x14, x12, x13  → 1&0 = 0
        u_top.instr_mem.ram[15] = 32'h00D667B3; // or    x15, x12, x13  → 1|0 = 1
        u_top.instr_mem.ram[16] = 32'h00D64833; // xor   x16, x12, x13  → 1^0 = 1
        u_top.instr_mem.ram[17] = 32'h00C198B3; // sll   x17, x3, x12   → 5<<1 = 10
        u_top.instr_mem.ram[18] = 32'h00C8D933; // srl   x18, x17, x12  → 10>>1 = 5
        u_top.instr_mem.ram[19] = 32'h40C159B3; // sra   x19, x2, x12   → -1>>>1 = -1
        u_top.instr_mem.ram[20] = 32'h00312A33; // slt   x20, x2, x3    → (-1<5) = 1
        u_top.instr_mem.ram[21] = 32'h00313AB3; // sltu  x21, x2, x3    → 0
        u_top.instr_mem.ram[22] = 32'h0011A023; // sw    x1, 0(x3)      → Mem[5]=0x10 → word_idx=1
        u_top.instr_mem.ram[23] = 32'h00119223; // sh    x1, 4(x3)      → Mem[9][15:0] → word_idx=2
        u_top.instr_mem.ram[24] = 32'h00118323; // sb    x1, 6(x3)      → Mem[11][7:0] → word_idx=2
        u_top.instr_mem.ram[25] = 32'h0000AB03; // lw    x22, 0(x1)     → Mem[4]=DEAD8080
        u_top.instr_mem.ram[26] = 32'h00009B83; // lh    x23, 0(x1)     → FFFF8080
        u_top.instr_mem.ram[27] = 32'h0000DC03; // lhu   x24, 0(x1)     → 00008080
        u_top.instr_mem.ram[28] = 32'h00008C83; // lb    x25, 0(x1)     → FFFFFF80
        u_top.instr_mem.ram[29] = 32'h0000CD03; // lbu   x26, 0(x1)     → 00000080
        u_top.instr_mem.ram[30] = 32'h017B0463; // beq   x22, x23, +8   → tomado
        u_top.instr_mem.ram[31] = 32'h00000013; // nop   (saltado)
        u_top.instr_mem.ram[32] = 32'h017B5463; // bge   x22, x23, +8   → tomado
        u_top.instr_mem.ram[33] = 32'h00000013; // nop   (saltado)
        u_top.instr_mem.ram[34] = 32'h00314463; // blt   x2, x3, +8     → tomado (-1<5)
        u_top.instr_mem.ram[35] = 32'h00000013; // nop   (saltado)
        u_top.instr_mem.ram[36] = 32'h002B1463; // bne   x22, x2, +8    → tomado
        u_top.instr_mem.ram[37] = 32'h00000013; // nop   (saltado)
        u_top.instr_mem.ram[38] = 32'h0080006F; // jal   x0, +8         → PC=0xA0
        u_top.instr_mem.ram[39] = 32'h00000013; // nop   (saltado)
        u_top.instr_mem.ram[40] = 32'h0AC00E13; // addi  x28, x0, 0xAC  → x28=0xAC
        u_top.instr_mem.ram[41] = 32'h000E0067; // jalr  x0, x28, 0     → PC=0xAC

        // ── Fase 2: liberar reset, luego cargar registros y memoria ──
        // CRÍTICO: reg_file tiene reset SÍNCRONO en posedge → cualquier
        // valor escrito con rst=1 activo es borrado en el siguiente posedge.
        // Se libera rst y LUEGO se escriben los valores en la zona
        // combinatoria (entre posedge y el siguiente posedge).
        @(posedge clk);   // último posedge con rst=1
        #1;               // pequeño delta después del posedge
        rst = 0;          // liberar reset

        // Ahora rst=0 y aún no ha habido un posedge nuevo:
        // los valores que escribimos aquí NO serán borrados por el reset.
        u_top.regs.regs[2]    = 32'hFFFF_FFFF;  // x2 = -1
        u_top.regs.regs[3]    = 32'd5;           // x3 =  5
        u_top.data_mem.ram[4] = 32'hDEAD8080;   // addr=16 (word_index=4)

        $display("\n============================================================");
        $display("  INICIANDO SIMULACION SELF-CHECKING");
        $display("============================================================");

        // Esperar suficiente tiempo para todas las instrucciones
        #800;

        $display("\n============================================================");
        $display("  RESUMEN TB TOP");
        $display("============================================================");
        $display("  Pruebas PASS : %0d", test_pass);
        $display("  Pruebas FAIL : %0d", test_fail);
        $display("  Objetivo     : %0d instrucciones", REQUIRED_TESTS);
        if (test_fail == 0 && test_pass == REQUIRED_TESTS)
            $display("  RESULTADO FINAL: EXITO TOTAL (%0d/%0d)", test_pass, REQUIRED_TESTS);
        else
            $display("  RESULTADO FINAL: HAY ERRORES — revisar logs arriba");
        $display("============================================================\n");
        $finish;
    end

endmodule