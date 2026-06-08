module adder #(parameter n = 4)
	(input logic [n - 1: 0] a, b,
	 input logic cin,
	 output logic [n - 1: 0] y,
	 output logic cin_msb, cout);
	 
	logic [n: 0]carries;
	assign carries[0] = cin;
	
	genvar i;
	
	generate
		for (i = 0; i < n; i = i+  1) begin : gen_adders
			fulladder fa_inst(a[i], b[i], carries[i], y[i], carries[i + 1]);
		end
	endgenerate
	
	assign cin_msb = carries[n - 1];
	assign cout = carries[n];

endmodule
