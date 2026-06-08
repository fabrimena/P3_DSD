module or_gate #(parameter n = 4)
	(input logic [n - 1: 0] a, b,
	 output logic [n - 1: 0] y);
	 
	 assign y = a | b;
	 
endmodule
