module instructionMemory (
    input [4:0] PC,
    output [31:0] instr
);
    reg [31:0] ram [0:128]; 
    assign instr = ram[PC];
endmodule
