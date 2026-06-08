module pc_increment(
    input logic clk,
    input logic rst,
    input logic PCSrc,
    input logic [31:0] PCBranch,
    output logic [31:0] PC,
    output logic [31:0] PCPlus4
);

    // Señales internas
    logic [31:0] PCNext;

    // Adder: suma PC + 4 para obtener el siguiente PC secuencial
    adder #(32) pc_adder(
        .a(PC),
        .b(32'd4),
        .cin(1'b0),
        .y(PCPlus4)
    );

    // Mux: selecciona entre PC+4 (PCSrc=0) o PCBranch (PCSrc=1)
    mux2to1_Nbits #(32) pc_mux(
        .sel(PCSrc),
        .a(PCPlus4),
        .b(PCBranch),
        .y(PCNext)
    );

    // Registro: almacena el valor del PC
    pc pc_reg (
        .clk(clk),
        .rst(rst),
        .PCnext(PCNext),
        .PC(PC)
    );
endmodule
