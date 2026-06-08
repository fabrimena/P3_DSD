module mux2to1_Nbits #(parameter n = 4)
	(input logic [n - 1: 0] a, b,
	 input logic sel,
	 output logic [n - 1: 0] y);
	 
	genvar i;
	generate
		for (i = 0; i < n; i = i+  1) begin : gen_muxes
			mux2to1 mux_inst(.a(a[i]), .b(b[i]), .sel(sel), .y(y[i]));
		end
	endgenerate
	
endmodule
