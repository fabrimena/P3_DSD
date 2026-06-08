`timescale 1ns/1ps

module pc_increment_tb;
    // Señales de entrada
    logic clk;
    logic rst;
    logic PCSrc;
    logic [31:0] PCBranch;
    
    // Señal de salida
    logic [31:0] PC;
    
    // Instanciar el módulo
    pc_increment dut (
        .clk(clk),
        .rst(rst),
        .PCSrc(PCSrc),
        .PCBranch(PCBranch),
        .PC(PC)
    );
    
    // Generar clock (período de 10 ns)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Test vectors
    initial begin
        $dumpfile("pc_increment.vcd");
        $dumpvars(0, pc_increment_tb);
        
        // Prueba 1: Reset
        $display("=== Prueba 1: Reset ===");
        rst = 1;
        PCSrc = 0;
        PCBranch = 32'h00000000;
        #10;
        $display("PC después de reset: %h (esperado: 00000000)", PC);
        
        // Prueba 2: Incremento secuencial (sin salto)
        $display("\n=== Prueba 2: Incremento secuencial ===");
        rst = 0;
        PCSrc = 0;  // Selecciona PC + 4
        #10;
        $display("PC (ciclo 1): %h (esperado: 00000004)", PC);
        
        #10;
        $display("PC (ciclo 2): %h (esperado: 00000008)", PC);
        
        #10;
        $display("PC (ciclo 3): %h (esperado: 0000000C)", PC);
        
        // Prueba 3: Salto condicional (PCSrc = 1)
        $display("\n=== Prueba 3: Salto condicional ===");
        PCBranch = 32'h00000100;  // Dirección de salto
        PCSrc = 1;  // Selecciona PCBranch
        #10;
        $display("PC (salto): %h (esperado: 00000100)", PC);
        
        // Prueba 4: Volver a incremento secuencial
        $display("\n=== Prueba 4: Regreso a incremento secuencial ===");
        PCSrc = 0;
        #10;
        $display("PC: %h (esperado: 00000104)", PC);
        
        #10;
        $display("PC: %h (esperado: 00000108)", PC);
        
        // --- PRUEBAS LIMITE / NEGATIVAS ---
        $display("\n=== PRUEBAS LIMITE Y CASOS NEGATIVOS (PC) ===");
        $display("[TEST NEGATIVO] Salto Destructivo a Extremo de Memoria (Overflow Logico)");
        PCSrc = 1;
        PCBranch = 32'hFFFFFFF0; // Supera limite superior habitual de instrucciones
        #10;
        $display("PC: %h | Branch Forzado al extremo: FFFFFFF0", PC);
        
        $display("[TEST LIMITE] Incremento cruzando barrera de Overflow Zero");
        PCSrc = 0;
        #10;
        $display("PC (tras +4): %h | Expected modulo-32 wrap o 0xFFFFFFF4", PC);
        #40; // Dejar fluir
        
        $display("\n=== Fin de pruebas ===");
        $finish;
    end
    
endmodule
