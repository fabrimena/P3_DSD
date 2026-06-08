module fulladder(input logic a, b, cin,
					  output logic y, cout);
					  
	assign y = a ^ b ^ cin;
	assign cout = a & b | a & cin | b & cin;
	
endmodule
