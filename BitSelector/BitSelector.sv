module BitSelector #(parameter n = 32)
(
    input logic [n - 1: 0] in,
    input logic [2: 0] BitSel,
    output logic [n - 1: 0] out
);
    
    always_comb begin
        case (BitSel)
            3'b000: out = in; // lw
            3'b001: out = {{16{in[15]}}, in[15:0]}; // lh
            3'b010: out = {{24{in[7]}}, in[7:0]}; // lb
            3'b011: out = {16'b0, in[15:0]}; // lhu
            3'b100: out = {24'b0, in[7:0]}; // lbu
            default: out = in;
        endcase
    end
endmodule
