module aritmethic_shift_right #(parameter n = 4)
	(input logic [n - 1: 0] a, b,
    output logic [n - 1: 0] y,
	 output logic C);
	 
	 logic fill, carry_temp, c1;
	 assign fill = a[n - 1];
	 
	 mux2to1_Nbits #(n) sel((a >> b) | ({n{fill}} << (n - b)), {n{fill}}, b >= n, y);
	 
	 assign carry_temp = a[b - 1];
	 
	 mux2to1 mux_c1(carry_temp, 1'b0, b == 0, c1);
    mux2to1 mux_c2(c1, 1'b0, b >= n, C);
	 
endmodule
