module extend (
    input  logic [31:0] instr,
    input  logic [2:0]  ImmSrc,
    output logic [31:0] ImmExt
);

    always_comb begin
        case (ImmSrc)
            // --------------------------------------------------
            // I-type: addi, andi, ori, xori, lw, lh, lb, jalr
            // Inmediato en bits [31:20] (12 bits con signo)
            // --------------------------------------------------
            3'b000: begin
                ImmExt = {{20{instr[31]}}, instr[31:20]};
            end

            // --------------------------------------------------
            // S-type: sw, sh, sb
            // Inmediato: imm[11:5] en bits [31:25], imm[4:0] en bits [11:7]
            // Combinado: [imm[11:5], imm[4:0]]
            // --------------------------------------------------
            3'b001: begin
                ImmExt = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            end

            // --------------------------------------------------
            // B-type: beq, bne, blt, bge
            // Inmediato: [31]=imm[12], [30:25]=imm[10:5], [11:8]=imm[4:1], [7]=imm[11]
            // Valor: {imm[12], imm[10:5], imm[4:1], imm[11], 1'b0}
            // Nota: B-type siempre es par (el bit menos significativo es 0)
            // --------------------------------------------------
            3'b010: begin
                ImmExt = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
            end

            // --------------------------------------------------
            // J-type: jal
            // Inmediato: [31]=imm[20], [19:12]=imm[19:12], [20]=imm[11], [30:21]=imm[10:1]
            // Valor: {imm[20], imm[10:1], imm[11], imm[19:12], 1'b0}
            // Nota: J-type siempre es par (el bit menos significativo es 0)
            // --------------------------------------------------
            3'b011: begin
                ImmExt = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
            end

            // --------------------------------------------------
            // U-type: lui
            // Inmediato en bits [31:12] (20 bits)
            // Se carga en los 20 bits superiores, resto es 0
            // --------------------------------------------------
            3'b100: begin
                ImmExt = {instr[31:12], 12'b0};
            end

            default: begin
                ImmExt = 32'b0;
            end
        endcase
    end

endmodule
