module add_sub #(parameter n = 32)
	(input logic [n - 1: 0] a, b,
	 input logic add_or_sub,  // [3]=funct7[5] (0: ADD/SRL, 1: SUB/SRA)
	 output logic [n - 1: 0] y,
	 output logic cin_msb, cout);
	 
	 logic sub, cin;
	 logic [n - 1: 0] add_b;
	 
	 // add_or_sub=1 indica SUB o SRA (requieren restar 1 en complemento a 2)
	 assign sub = add_or_sub;
	 
	 // Complemento a 2: invertir b si es resta
	 mux2to1_Nbits #(n) sel_B(b, ~b, sub, add_b);
	 
	 // Para resta: cin=1 (complemento a 2), para suma: cin=0
	 assign cin = sub;
	 
	 adder #(n) add_op(a, add_b, cin, y, cin_msb, cout);
	 
endmodule	 
	 