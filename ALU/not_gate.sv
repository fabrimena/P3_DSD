module not_gate #(parameter n = 4)
	(input logic [n - 1: 0] a,
	 output logic [n - 1: 0] y);
	 
	 assign y = ~a;
	 
endmodule
