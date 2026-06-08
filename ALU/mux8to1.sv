// Multiplexor 8-to-1 para seleccionar resultado de la operación ALU RV32I
// ALUControl codificación:
// 4'b0000: ADD/SUB (SUB si ALUControl[3]=1)
// 4'b0001: SLL (Shift Left Logical)
// 4'b0010: SLT/SLTU (comparación signed/unsigned, resultado en slt_res)
// 4'b0101: SRL (Shift Right Logical)  
// 4'b1101: SRA (Shift Right Arithmetic)
// 4'b0100: XOR
// 4'b0110: OR
// 4'b0111: AND

module mux8to1 #(parameter n = 32)
	(input logic [n - 1: 0] add_result,
	 input logic [n - 1: 0] slt_result,
	 input logic [n - 1: 0] sll_result,
	 input logic [n - 1: 0] srl_result,
	 input logic [n - 1: 0] sra_result,
	 input logic [n - 1: 0] and_result,
	 input logic [n - 1: 0] or_result,
	 input logic [n - 1: 0] xor_result,
	 input logic [3: 0] select,
	 output logic [n - 1: 0] mux_output);

	always_comb begin
		if (select[2:0] == 3'b101) begin
			// funct3=101: SRL si bit[3]=0, SRA si bit[3]=1
			mux_output = select[3] ? sra_result : srl_result;
		end else begin
			case(select[2:0])
				3'b000: mux_output = add_result;  // ADD/SUB (bit[3] manejado en add_sub)
				3'b010: mux_output = slt_result;  // SLT/SLTU
				3'b001: mux_output = sll_result;  // SLL
				3'b100: mux_output = xor_result;  // XOR
				3'b110: mux_output = or_result;   // OR
				3'b111: mux_output = and_result;  // AND
				default: mux_output = {n{1'b0}};
			endcase
		end
	end

endmodule
