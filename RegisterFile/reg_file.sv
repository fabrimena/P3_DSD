// RegisterFile - 32 registros x 32 bits para RV32I
// Puertos: 2 de lectura (asíncrona), 1 de escritura (síncrona)
// Nota: Registro x0 siempre es 0 (no se puede escribir)

module reg_file
#(
    parameter DATA_N = 32,
    parameter SIZE   = 32
)
(
    input clk,
    input rst,
    input wr_en,
    input [4:0] w_addr,
    input [4:0] r0_addr,
    input [4:0] r1_addr,
    input [DATA_N-1:0] w_data,
    output [DATA_N-1:0] r0_data,
    output [DATA_N-1:0] r1_data
);

    reg [DATA_N-1:0] regs [0:SIZE-1];
    
    integer i;
    
    // Inicialización de registros
    initial begin
        for (i = 0; i < SIZE; i = i + 1) begin
            regs[i] = {DATA_N{1'b0}};
        end
    end
    
    // Lectura asíncrona (combinatoria)
    assign r0_data = regs[r0_addr];
    assign r1_data = regs[r1_addr];
    
    // Escritura síncrona (en flanco de reloj positivo)
    // No permitir escritura en x0 (registro zero siempre es 0)
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < SIZE; i = i + 1) begin
                regs[i] <= {DATA_N{1'b0}};
            end
        end else if (wr_en && w_addr != 5'b0) begin
            regs[w_addr] <= w_data;
        end
    end

endmodule