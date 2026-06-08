// ============================================================
// alu_decoder.sv
// ============================================================
`timescale 1ns/1ps
module alu_decoder (
    input  logic [1:0] ALUOp,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,
    output logic [3:0] ALUControl
);

    logic f7b5; // funct7[5] como señal intermedia
    assign f7b5 = funct7[5];

    always_comb begin
        case (ALUOp)
            // Forzar ADD (loads, stores, jalr, jal)
            2'b00: ALUControl = 4'b0000;

            // Branch: SUB para comparar
            2'b01: ALUControl = 4'b1000;

            // R-type: {funct7[5], funct3}
            2'b10: ALUControl = {f7b5, funct3};

            // I-type: funct7[5] solo para srli/srai (funct3=101)
            2'b11: begin
                case (funct3)
                    3'b101:  ALUControl = {f7b5,  funct3}; // srli / srai
                    default: ALUControl = {1'b0,  funct3}; // resto
                endcase
            end

            default: ALUControl = 4'b0000;
        endcase
    end

endmodule
