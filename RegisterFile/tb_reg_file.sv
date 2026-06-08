`timescale 1ns / 1ps

// Testbench para RegisterFile

module tb_reg_file();
    
    parameter DATA_N = 32;
    parameter SIZE = 32;
    
    // Señales de test
    reg clk, rst, wr_en;
    reg [4:0] w_addr, r0_addr, r1_addr;
    reg [DATA_N-1:0] w_data;
    wire [DATA_N-1:0] r0_data, r1_data;
    
    integer errors = 0;
    integer i;
    
    // Instancia del RegisterFile
    reg_file #(DATA_N, SIZE) rf (
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en),
        .w_addr(w_addr),
        .r0_addr(r0_addr),
        .r1_addr(r1_addr),
        .w_data(w_data),
        .r0_data(r0_data),
        .r1_data(r1_data)
    );
    
    // Generador de reloj
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Tarea para escribir en un registro
    task write_register(
        input [4:0] addr,
        input [DATA_N-1:0] data,
        input string reg_name
    );
        begin
            @(negedge clk);
            wr_en = 1;
            w_addr = addr;
            w_data = data;
            @(posedge clk);
            #1;
            wr_en = 0;
            $display("  Escribir: %s (x%0d) = 0x%08h", reg_name, addr, data);
        end
    endtask
    
    // Tarea para leer un registro (verificar)
    task verify_register(
        input [4:0] addr,
        input [DATA_N-1:0] expected,
        input string reg_name
    );
        begin
            @(negedge clk);
            r0_addr = addr;
            @(posedge clk);
            #1;
            
            if (r0_data === expected) begin
                $display("EXITO: %s (x%0d) = 0x%08h", reg_name, addr, r0_data);
            end else begin
                $display("ERROR: %s (x%0d) = 0x%08h, esperado 0x%08h", 
                         reg_name, addr, r0_data, expected);
                errors = errors + 1;
            end
        end
    endtask
    
    // Tarea para verificar dos lecturas simultáneas
    task verify_dual_read(
        input [4:0] addr1,
        input [4:0] addr2,
        input [DATA_N-1:0] expected1,
        input [DATA_N-1:0] expected2,
        input string name1,
        input string name2
    );
        begin
            @(negedge clk);
            r0_addr = addr1;
            r1_addr = addr2;
            @(posedge clk);
            #1;
            
            if ((r0_data === expected1) && (r1_data === expected2)) begin
                $display("EXITO: Dual read - %s=0x%08h, %s=0x%08h", 
                         name1, r0_data, name2, r1_data);
            end else begin
                $display("ERROR: Dual read - %s=0x%08h (exp 0x%08h), %s=0x%08h (exp 0x%08h)",
                         name1, r0_data, expected1, name2, r1_data, expected2);
                errors = errors + 1;
            end
        end
    endtask
    
    initial begin
        $display("========================================");
        $display("Testbench: RegisterFile (32x32)");
        $display("========================================");
        errors = 0;
        
        // Reset inicial
        $display("\n[RESET]");
        rst = 1;
        wr_en = 0;
        r0_addr = 0;
        r1_addr = 0;
        @(posedge clk);
        @(posedge clk);
        rst = 0;
        @(posedge clk);
        
        // Verificar que todos los registros sean 0 después del reset
        $display("\n[VERIFICAR RESET]");
        for (i = 0; i < 8; i = i + 1) begin
            r0_addr = i;
            @(posedge clk);
            #1;
            if (r0_data !== 32'h00000000) begin
                $display("ERROR: Registro x%0d no es 0 después de reset: 0x%08h", i, r0_data);
                errors = errors + 1;
            end
        end
        $display("EXITO: Todos los registros son 0 después de reset");
        
        // Test 1: Escribir en registros individuales
        $display("\n[TEST 1: ESCRITURA SIMPLE]");
        write_register(5'd1, 32'h12345678, "x1");
        write_register(5'd2, 32'hABCDEF00, "x2");
        write_register(5'd3, 32'h11223344, "x3");
        verify_register(5'd1, 32'h12345678, "x1");
        verify_register(5'd2, 32'hABCDEF00, "x2");
        verify_register(5'd3, 32'h11223344, "x3");
        
        // Test 2: No permitir escritura en x0
        $display("\n[TEST 2: PROTECCIÓN DE x0]");
        write_register(5'd0, 32'hDEADBEEF, "x0 (intento fallido)");
        verify_register(5'd0, 32'h00000000, "x0 (debe estar protegido)");
        
        // Test 3: Lectura simultánea (dual read)
        $display("\n[TEST 3: LECTURA SIMULTÁNEA]");
        verify_dual_read(5'd1, 5'd2, 32'h12345678, 32'hABCDEF00, "x1", "x2");
        verify_dual_read(5'd2, 5'd3, 32'hABCDEF00, 32'h11223344, "x2", "x3");
        
        // Test 4: Sobrescribir registros
        $display("\n[TEST 4: SOBRESCRIBIR REGISTROS]");
        write_register(5'd1, 32'hFFFFFFFF, "x1 (nuevo valor)");
        verify_register(5'd1, 32'hFFFFFFFF, "x1");
        verify_register(5'd2, 32'hABCDEF00, "x2 (sin cambios)");
        
        // Test 5: Escribir y leer desde mismo registro
        $display("\n[TEST 5: ESCRIBIR MÚLTIPLES REGISTROS]");
        for (i = 4; i < 16; i = i + 1) begin
            write_register(i, (32'h00000000 | i * 32'h11111111), $sformatf("x%0d", i));
        end
        
        for (i = 4; i < 16; i = i + 1) begin
            verify_register(i, (32'h00000000 | i * 32'h11111111), $sformatf("x%0d", i));
        end
        
        // Test 6: Valores especiales
        $display("\n[TEST 6: VALORES ESPECIALES]");
        write_register(5'd20, 32'h80000000, "x20 (MSB=1)");
        write_register(5'd21, 32'h7FFFFFFF, "x21 (MSB=0)");
        write_register(5'd22, 32'hFFFFFFFF, "x22 (todos 1s)");
        write_register(5'd23, 32'h00000000, "x23 (todos 0s)");
        
        verify_register(5'd20, 32'h80000000, "x20");
        verify_register(5'd21, 32'h7FFFFFFF, "x21");
        verify_register(5'd22, 32'hFFFFFFFF, "x22");
        verify_register(5'd23, 32'h00000000, "x23");
        
        // Test 7: Reset limpia todos los registros
        $display("\n[TEST 7: RESET LIMPIA TODO]");
        rst = 1;
        @(posedge clk);
        @(posedge clk);
        rst = 0;
        
        for (i = 0; i < 32; i = i + 1) begin
            r0_addr = i;
            @(posedge clk);
            #1;
            if (r0_data !== 32'h00000000) begin
                $display("ERROR: Registro x%0d no es 0 después de reset: 0x%08h", i, r0_data);
                errors = errors + 1;
            end
        end
        $display("EXITO: Todos los registros limpios después de reset");
        
        // --- PRUEBAS LIMITE / NEGATIVAS ---
        $display("\n[TEST LIMITE]: Modificar registro 0 con valores maximos bajo un enable forzado");
        wr_en = 1;
        w_addr = 0;
        w_data = 32'hFFFFFFFF; // Forzar escritura 
        @(posedge clk);
        #1;
        r0_addr = 0;
        @(posedge clk);
        if (r0_data !== 32'h00000000) begin
             $display("ERROR (Negativo): Registro cero sufrio alteracion: 0x%08h", r0_data);
             errors = errors + 1;
        end else begin
             $display("EXITO (Negativo): Registro x0 es inmutable ante w_data=0xFFFFFFFF");
        end

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
