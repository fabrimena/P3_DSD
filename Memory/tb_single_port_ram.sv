`timescale 1ns / 1ps

// Testbench para RAM

module tb_single_port_ram();
    
    parameter DATA_N = 32;
    parameter SIZE = 1024;
    
    // Señales de test
    reg clk;
    reg [3:0] wr_en;
    reg [$clog2(SIZE)-1:0] addr;
    reg [DATA_N-1:0] w_data;
    wire [DATA_N-1:0] r_data;
    
    integer errors = 0;
    integer i;
    
    // Instancia de RAM
    single_port_ram #(DATA_N, SIZE) ram_inst (
        .clk(clk),
        .wr_en({4{wr_en[0]}}),
        .addr(addr),
        .w_data(w_data),
        .r_data(r_data)
    );
    
    // Generador de reloj
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Tarea para escribir
    task write_memory(
        input [9:0] address,
        input [DATA_N-1:0] data,
        input string desc
    );
        begin
            @(negedge clk);
            wr_en = 1;
            addr = address;
            w_data = data;
            @(posedge clk);
            #1;
            wr_en = 0;
            $display("Escribir: [%d] = 0x%08h (%s)", address, data, desc);
        end
    endtask
    
    // Tarea para leer
    task read_memory(
        input [9:0] address,
        input [DATA_N-1:0] expected,
        input string desc
    );
        begin
            @(negedge clk);
            wr_en = 0;
            addr = address;
            @(posedge clk);
            #1;
            
            if (r_data === expected) begin
                $display("EXITO: [%d] = 0x%08h (%s)", address, r_data, desc);
            end else begin
                $display("ERROR: [%d] = 0x%08h, esperado 0x%08h (%s)", 
                         address, r_data, expected, desc);
                errors = errors + 1;
            end
        end
    endtask
    
    initial begin
        $display("========================================");
        $display("Testbench: Single-Port RAM (1024x32)");
        $display("========================================");
        errors = 0;
        
        // Reset inicial
        $display("\n[RESET]");
        wr_en = 0;
        @(posedge clk);
        @(posedge clk);
        
        // Test 1: Escribir y leer valores simples
        $display("\n[TEST 1: ESCRITURA Y LECTURA SIMPLE]");
        write_memory(10'h000, 32'h12345678, "Primera palabra");
        write_memory(10'h001, 32'hABCDEF00, "Segunda palabra");
        write_memory(10'h002, 32'h11223344, "Tercera palabra");
        
        read_memory(10'h000, 32'h12345678, "Verificar primera");
        read_memory(10'h001, 32'hABCDEF00, "Verificar segunda");
        read_memory(10'h002, 32'h11223344, "Verificar tercera");
        
        // Test 2: Escribir en direcciones diferentes
        $display("\n[TEST 2: DIRECCIONES NO CONTIGUAS]");
        write_memory(10'h100, 32'hDEADBEEF, "Dirección 0x100");
        write_memory(10'h200, 32'hCAFEBABE, "Dirección 0x200");
        write_memory(10'h3FF, 32'hFFFFFFFF, "Última dirección (0x3FF)");
        
        read_memory(10'h100, 32'hDEADBEEF, "Verificar 0x100");
        read_memory(10'h200, 32'hCAFEBABE, "Verificar 0x200");
        read_memory(10'h3FF, 32'hFFFFFFFF, "Verificar 0x3FF");
        
        // Test 3: Sobrescribir datos
        $display("\n[TEST 3: SOBRESCRIBIR DATOS]");
        write_memory(10'h050, 32'h00000001, "Escribir 1");
        write_memory(10'h050, 32'h00000002, "Sobrescribir con 2");
        write_memory(10'h050, 32'h00000003, "Sobrescribir con 3");
        
        read_memory(10'h050, 32'h00000003, "Valor final debe ser 3");
        
        // Test 4: Llenar múltiples direcciones
        $display("\n[TEST 4: LLENAR MÚLTIPLES DIRECCIONES]");
        for (i = 0; i < 16; i = i + 1) begin
            write_memory(10'(i + 10'h010), {16'h1111, 16'(i)}, $sformatf("Dir 0x%02x", i + 16));
        end
        
        for (i = 0; i < 16; i = i + 1) begin
            read_memory(10'(i + 10'h010), {16'h1111, 16'(i)}, $sformatf("Verificar 0x%02x", i + 16));
        end
        
        // Test 5: Valores especiales
        $display("\n[TEST 5: VALORES ESPECIALES]");
        write_memory(10'h080, 32'h80000000, "MSB = 1");
        write_memory(10'h081, 32'h7FFFFFFF, "MSB = 0");
        write_memory(10'h082, 32'hFFFFFFFF, "Todos 1s");
        write_memory(10'h083, 32'h00000000, "Todos 0s");
        
        read_memory(10'h080, 32'h80000000, "Verificar 0x80000000");
        read_memory(10'h081, 32'h7FFFFFFF, "Verificar 0x7FFFFFFF");
        read_memory(10'h082, 32'hFFFFFFFF, "Verificar 0xFFFFFFFF");
        read_memory(10'h083, 32'h00000000, "Verificar 0x00000000");
        
        // Test 6: Lectura asíncrona (verificar valores previamente escritos)
        $display("\n[TEST 6: LECTURA ASÍNCRONA]");
        // Leer valores que ya escribimos en test 1
        @(negedge clk);
        wr_en = 0;
        addr = 10'h000;
        @(posedge clk);
        #1;
        if (r_data === 32'h12345678) begin
            $display("EXITO: Lectura asíncrona desde 0x000 = 0x%08h", r_data);
        end else begin
            $display("ERROR: Lectura asíncrona desde 0x000 = 0x%08h, esperado 0x%08h", 
                     r_data, 32'h12345678);
            errors = errors + 1;
        end
        
        // Cambiar dirección instantáneamente
        addr = 10'h001;
        #1;
        if (r_data === 32'hABCDEF00) begin
            $display("EXITO: Lectura asíncrona desde 0x001 = 0x%08h", r_data);
        end else begin
            $display("ERROR: Lectura asíncrona desde 0x001 = 0x%08h, esperado 0x%08h", 
                     r_data, 32'hABCDEF00);
            errors = errors + 1;
        end
        
        // Test 7: Verificar que la RAM retiene valores
        $display("\n[TEST 7: RETENCIÓN DE VALORES]");
        for (i = 0; i < 100; i = i + 1) begin
            @(posedge clk);
        end
        
        read_memory(10'h000, 32'h12345678, "Valor inicial (después 100 ciclos)");
        read_memory(10'h100, 32'hDEADBEEF, "Valor en 0x100 (después 100 ciclos)");
        
        // Resumen
        $display("\n========================================");
        $display("Total de ERRORES: %0d", errors);
        if (errors == 0) begin
            $display("TODOS LOS TESTS PASARON EXITOSAMENTE");
        end else begin
            $display("HAY %0d ERRORES EN LOS TESTS", errors);
        end
        $display("========================================");
        
        $finish;
    end

endmodule
