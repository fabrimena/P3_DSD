module ALU #(parameter n = 32)
	(input logic [n - 1: 0] a, b,
	 input logic [3: 0] ALUControl,  // 4 bits: [3]=funct7[5], [2:0]=funct3
	 output logic [n - 1: 0] ALUResult,
	 output logic [2: 0] ALUFlags);  // [0]=Zero, [1]=Less (for ADD/SUB only)
	 
	 logic [n - 1: 0] and_res, or_res, xor_res, add_res, lsl_res, lsr_res, asr_res, slt_res;
	 logic cin_msb, cout, overflow, C_lsl, C_lsr, C_asr;
	 
	 and_gate #(n)	and_op(a, b, and_res);
	 
	 or_gate #(n)	or_op(a, b, or_res);
	 
	add_sub #(n) add_or_sub(a, b, ALUControl[3], add_res, cin_msb, cout);
    
	// set less than (signed/unsigned) - is_unsigned = 1 for SLTU
	set_lt #(n) slt_op (
		.a(a),
		.b(b),
		.is_unsigned(ALUControl[0]), // SLTU si ALUControl[0] es 1, SLT si es 0
		.out(slt_res)
	);

	 xor_gate #(n)	xor_op(a, b, xor_res);
	 
	 logic_shift_left #(n) lsl(a, b[$clog2(n) - 1: 0], 1'b0, lsl_res, C_lsl);
	 
	 logic_shift_right #(n)	lsr(a, b[$clog2(n) - 1: 0], 1'b0, lsr_res, C_lsr);
	 
	 aritmethic_shift_right #(n)	asr(a, b[$clog2(n) - 1: 0], asr_res, C_asr);
	 
	// RV32I: 8 operaciones basadas en ALUControl
	// 4'b0000: ADD,  4'b1000: SUB
	// 4'b0001: SLL,  4'b0101: SRL,  4'b1101: SRA
	// 4'b0100: XOR,  4'b0110: OR,   4'b0111: AND
	// El multiplexor cubre la mayoría de operaciones; SLT/SLTU (0010/0011)
	// se manejan por separado usando `slt_res`.
	logic [n-1:0] mux_out;
	mux8to1 #(n) sel_op(add_res,slt_res, lsl_res, lsr_res, asr_res, and_res, or_res, xor_res, ALUControl, mux_out);
	 
	assign ALUResult = mux_out;
	 // Calcular Overflow y detectar si es operación ADD/SUB
	 // Operaciones ADD/SUB tienen funct3=000, diferenciadas por ALUControl[3]
	 // ADD/SUB: ALUControl[2:0]=000 (ALUControl==0000 o ALUControl==1000)
	
	 
	// Flags: [0]=Zero, [1]=Less
	assign ALUFlags[0] = ~(|ALUResult);                           // Zero flag
	assign ALUFlags[1] = (ALUControl[2:0] == 3'b011) ? (a < b) : ($signed(a) < $signed(b)); // Less (unsigned if SLTU)
	 
endmodule
	