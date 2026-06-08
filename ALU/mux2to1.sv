module mux2to1(input logic a, b, sel,
					output logic y);
					
	assign y = a & ~sel | b & sel;
	
endmodule
