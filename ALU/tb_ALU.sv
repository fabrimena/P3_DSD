`timescale 1ns / 1ps

module tb_ALU();
    // Parámetros y señales
    parameter n = 32;
    logic [n-1:0] a, b;
    logic [3:0] ALUControl;  // 4 bits: [3]=funct7[5], [2:0]=funct3
    logic [n-1:0] ALUResult;
    logic [2:0] ALUFlags; // [0]=Zero, [1]=Less

    // Variables para verificación
    logic [n-1:0] expected_res;
    logic [2:0] expected_flags;
    integer i, errors;

    // Instancia de la ALU (Unit Under Test)
    ALU #(n) dut (
        .a(a),
        .b(b),
        .ALUControl(ALUControl),
        .ALUResult(ALUResult),
        .ALUFlags(ALUFlags)
    );

    // Función para calcular el resultado esperado (Modelo de Referencia)
    function void check_expected(
        input [n-1:0] a_in, b_in, 
        input [3:0] ctrl
    );
        logic [n:0] sum_full; // Para operaciones aritméticas
        logic signed [n-1:0] sa, sb;
        
        sa = a_in; 
        sb = b_in;
        expected_flags = 2'b00;  // 2 bits: [0]=Zero, [1]=Less
        
        // El flag[1] (Less) se calcula SIEMPRE en la ALU:
        // SLTU (ctrl[2:0] == 3'b011): comparación sin signo (a < b)
        // Todas las otras operaciones: comparación con signo ($signed(a) < $signed(b))
        if (ctrl[2:0] == 3'b011) begin // SLTU (unsigned)
            expected_flags[1] = (a_in < b_in);
        end else begin // Todas las otras operaciones (signed)
            expected_flags[1] = ($signed(a_in) < $signed(b_in));
        end
        
        case(ctrl)
            4'b0000: begin // ADD (funct3=000, funct7[5]=0)
                sum_full = {1'b0, a_in} + {1'b0, b_in};
                expected_res = sum_full[n-1:0];
                
            end
            4'b1000: begin // SUB (funct3=000, funct7[5]=1)
                sum_full = {1'b0, a_in} + {1'b0, (~b_in + 32'b1)};
                expected_res = sum_full[n-1:0];
                
            end
            4'b0001: expected_res = a_in << b_in[4:0];   // SLL (funct3=001)
            4'b0101: expected_res = a_in >> b_in[4:0];   // SRL (funct3=101, funct7[5]=0)
            4'b1101: expected_res = $signed(a_in) >>> (b_in[4:0]); // SRA (funct3=101, funct7[5]=1)
            4'b0100: expected_res = a_in ^ b_in;         // XOR (funct3=100)
            4'b0110: expected_res = a_in | b_in;         // OR  (funct3=110)
            4'b0111: expected_res = a_in & b_in;         // AND (funct3=111)
            4'b0010: expected_res = {31'd0, expected_flags[1]}; // SLT  (funct3=010)
            4'b0011: expected_res = {31'd0, expected_flags[1]}; // SLTU (funct3=011)
            default: expected_res = 0;
        endcase
        
        expected_flags[0] = (expected_res == 0); // Zero flag
    endfunction

    // Tarea para aplicar estímulos y verificar
    task apply_test(input [n-1:0] ta, input [n-1:0] tb, input [3:0] tctrl);
        integer err_count = 0;
        begin
            a = ta; 
            b = tb; 
            ALUControl = tctrl;
            #10;
            
            check_expected(a, b, ALUControl);
            
            if (ALUResult !== expected_res) begin
                $display("ERROR Resultado: Ctrl=%4b | A=%0d, B=%0d | Obtenido=%0h, Esperado=%0h", 
                         tctrl, $signed(ta), $signed(tb), ALUResult, expected_res);
                errors = errors + 1;
                err_count = 1;
            end
            
            // Verificación de banderas (Zero y Less)
            if (ALUFlags[1:0] !== expected_flags[1:0]) begin
                $display("ERROR Flags: Ctrl=%4b | A=%0d, B=%0d | Flags Obtenidas=%b, Esperadas=%b", 
                         tctrl, $signed(ta), $signed(tb), ALUFlags, expected_flags);
                errors = errors + 1;
                err_count = 1;
            end
            
            if (err_count == 0) begin
                $display("EXITO: Ctrl=%4b | A=%0d, B=%0d | Res=%0h, Flags=%b", 
                         tctrl, $signed(ta), $signed(tb), ALUResult, ALUFlags);
            end
        end
    endtask

    initial begin
        $display("========================================");
        $display("Iniciando Testbench de ALU RV32I (32 bits)");
        $display("========================================");
        errors = 0;

        // --- PRUEBAS ADD (4'b0000) ---
        $display("\n[TEST ADD - funct3=000, funct7[5]=0]");
        apply_test(32'd10, 32'd5, 4'b0000);      // 10 + 5 = 15
        apply_test(32'd100, 32'd50, 4'b0000);    // 100 + 50 = 150
        apply_test(32'd0, 32'd0, 4'b0000);       // 0 + 0 = 0 (Zero flag)
        apply_test(32'h7FFFFFFF, 32'd1, 4'b0000); // Overflow positivo

        // --- PRUEBAS SUB (4'b1000) ---
        $display("\n[TEST SUB - funct3=000, funct7[5]=1]");
        apply_test(32'd10, 32'd5, 4'b1000);      // 10 - 5 = 5
        apply_test(32'd5, 32'd10, 4'b1000);      // 5 - 10 = -5 (borrow)
        apply_test(32'd0, 32'd0, 4'b1000);       // 0 - 0 = 0 (Zero flag)
        apply_test(32'sh7FFFFFFF, 32'sh1, 4'b1000); // Overflow en resta

        // --- PRUEBAS SLL (4'b0001) ---
        $display("\n[TEST SLL - Shift Left Logical (funct3=001)]");
        apply_test(32'h00000001, 32'd1, 4'b0001);  // 1 << 1 = 2
        apply_test(32'h00000001, 32'd31, 4'b0001); // 1 << 31 = 0x80000000
        apply_test(32'hFFFFFFFF, 32'd1, 4'b0001);  // 0xFFFFFFFF << 1

        // --- PRUEBAS SRL (4'b0101) ---
        $display("\n[TEST SRL - Shift Right Logical (funct3=101, funct7[5]=0)]");
        apply_test(32'h80000000, 32'd1, 4'b0101);  // 0x80000000 >> 1 = 0x40000000
        apply_test(32'hFFFFFFFF, 32'd8, 4'b0101);  // 0xFFFFFFFF >> 8 = 0x00FFFFFF
        apply_test(32'h00000001, 32'd1, 4'b0101);  // 1 >> 1 = 0

        // --- PRUEBAS SRA (4'b1101) ---
        $display("\n[TEST SRA - Shift Right Arithmetic (funct3=101, funct7[5]=1)]");
        apply_test(32'sh80000000, 32'd1, 4'b1101);  // -2147483648 >> 1 (aritmético)
        apply_test(32'sh7FFFFFFF, 32'd1, 4'b1101);  // 2147483647 >> 1 (aritmético)
        apply_test(32'shFFFFFFFF, 32'd1, 4'b1101);  // -1 >> 1 = -1 (todos 1s)

        // --- PRUEBAS XOR (4'b0100) ---
        $display("\n[TEST XOR (funct3=100)]");
        apply_test(32'hFFFFFFFF, 32'hFFFFFFFF, 4'b0100);  // 0 (Zero flag)
        apply_test(32'hAAAAAAAA, 32'h55555555, 4'b0100);  // 0xFFFFFFFF
        apply_test(32'h12345678, 32'h12345678, 4'b0100);  // 0 (Zero flag)

        // --- PRUEBAS OR (4'b0110) ---
        $display("\n[TEST OR (funct3=110)]");
        apply_test(32'h0F0F0F0F, 32'hF0F0F0F0, 4'b0110);  // 0xFFFFFFFF
        apply_test(32'h00000000, 32'h00000000, 4'b0110);  // 0 (Zero flag)
        apply_test(32'h12345678, 32'h87654321, 4'b0110);  // 0x97775779

        // --- PRUEBAS AND (4'b0111) ---
        $display("\n[TEST AND (funct3=111)]");
        apply_test(32'hFFFFFFFF, 32'h00000000, 4'b0111);  // 0 (Zero flag)
        apply_test(32'hAAAAAAAA, 32'h55555555, 4'b0111);  // 0 (Zero flag)
        apply_test(32'h0F0F0F0F, 32'hF0F0F0F0, 4'b0111);  // 0 (Zero flag)

        // --- PRUEBAS LIMITE / NEGATIVAS ---
        $display("\n--- PRUEBAS LIMITE Y CASOS NEGATIVOS (ALU) ---");
        // Overflow Suma Positivo
        apply_test(32'h7FFFFFFF, 32'd1, 4'b0000); // Salida esperada 0x80000000 (Min Negativo)
        // Underflow Resta Negativa
        apply_test(32'h80000000, 32'd1, 4'b1000); // Salida 0x7FFFFFFF (Max Positivo)
        // Shifts Limites (0 y 31)
        apply_test(32'hFFFFFFFF, 32'd0, 4'b0001); // SLL X, 0 -> No shift
        apply_test(32'hFFFFFFFF, 32'd31, 4'b0001); // SLL X, 31 -> 0x80000000
        // SLT y SLTU Limites
        apply_test(32'hFFFFFFFF, 32'd1, 4'b0010); // SLT -1 < 1 (esperado Result: 1, flag Less: 1)
        apply_test(32'hFFFFFFFF, 32'd1, 4'b0011); // SLTU 0xFFFFFFFF < 1 (esperado Result: 0, flag Less: 0)

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