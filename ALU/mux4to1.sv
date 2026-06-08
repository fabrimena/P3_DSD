module mux4to1 #(parameter n = 4)
	(input logic [n - 1: 0] a, b, c, d,
	 input logic [1: 0] sel,
	 output logic [n - 1: 0] y);
	 
	 logic [n - 1: 0] y_1, y_2;
	 
	 mux2to1_Nbits #(n) mux1(a, c, sel[1], y_1);
	 mux2to1_Nbits #(n) mux2(b, d, sel[1], y_2);
	 mux2to1_Nbits #(n) mux3(y_1, y_2, sel[0], y);
	 
endmodule
