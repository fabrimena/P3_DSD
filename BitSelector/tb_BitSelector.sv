`timescale 1ns / 1ps

// Testbench para BitSelector
module tb_BitSelector();

    parameter N = 32;

    reg [N-1:0] in;
    reg [2:0] BitSel;
    wire [N-1:0] out;

    integer i;

    // Instancia del DUT
    BitSelector #(N) uut (
        .in(in),
        .BitSel(BitSel),
        .out(out)
    );

    initial begin
        $display("========================================");
        $display("Testbench: BitSelector (param N=%0d)", N);
        $display("========================================");

        // Vector de prueba 1: patrón alternado
        in = 32'hA5A5_F0F0; // patrón con bits altos en distintos bytes
        $display("\n[TEST 1] in=0x%08h : recorrer BitSel 0..7", in);
        for (i = 0; i < 8; i = i + 1) begin
            BitSel = i;
            #1; // dejar tiempo para evaluar señales combinacionales
            $display("BitSel=%0d in=0x%08h out=0x%08h", BitSel, in, out);
        end

        // Vector de prueba 2: signo negativo en byte/halfword
        in = 32'hFFFF_8001; // bytes bajos con signo negativo en byte/half
        $display("\n[TEST 2] in=0x%08h (prueba sign-extencion)", in);
        for (i = 0; i < 8; i = i + 1) begin
            BitSel = i;
            #1;
            $display("BitSel=%0d in=0x%08h out=0x%08h", BitSel, in, out);
        end

        // Vector de prueba 3: bytes bajos con valor pequeño
        in = 32'h0000_00F7; // positivo, para observar zero-extend vs sign-extend
        $display("\n[TEST 3] in=0x%08h (prueba zero-extend)", in);
        for (i = 0; i < 8; i = i + 1) begin
            BitSel = i;
            #1;
            $display("BitSel=%0d in=0x%08h out=0x%08h", BitSel, in, out);
        end

        // Vector de prueba 4: valores límites
        in = 32'h8000_0000; // MSB=1
        $display("\n[TEST 4] in=0x%08h (MSB=1)", in);
        for (i = 0; i < 8; i = i + 1) begin
            BitSel = i;
            #1;
            $display("BitSel=%0d in=0x%08h out=0x%08h", BitSel, in, out);
        end

        // --- PRUEBAS LIMITE / NEGATIVAS ---
        $display("\n[TEST NEGATIVO] Senal de seleccion no definida/fuera de ISA (3'b111)");
        // El codigo RISCV no dicta lectura para esto, se debe mantener a salvo devolviendo word completa o cortando seguro
        in = 32'hDEADBEEF;
        BitSel = 3'b111; 
        #1;
        $display("BitSel=%0d in=0x%08h out=0x%08h -> Proteccion defensiva (usualmente default word)", BitSel, in, out);
        
        $display("\n[TEST NEGATIVO] Datos con alta inyeccion de ruidos en LBU");
        in = 32'hFFFFFFFF;
        BitSel = 3'b100; // lbu 
        #1;
        if(out !== 32'h000000FF) $display("ERROR CRITICO LBU: No zero extendio el 0xFF! dio -> %h", out);
        else $display("Exito Negativo: Aislado ruido extremo -> LBU=%h", out);

        $display("\nPruebas completadas.");
        $finish;
    end

endmodule
