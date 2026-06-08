// set_lt.sv
// Devuelve un vector de n bits con LSB=1 si a < b (comparación con signo)
module set_lt #(parameter n = 32)
(
    input  logic [n-1:0] a,
    input  logic [n-1:0] b,
    input  logic is_unsigned, // 1 -> unsigned comparison (SLTU), 0 -> signed (SLT)
    output logic [n-1:0] out
);

    // Comparación signed/unsigned según la señal
    logic less;
    assign less = is_unsigned ? (a < b) : ($signed(a) < $signed(b));

    // Resultado en formato RV32: bit[0] = cmp, resto a 0
    assign out = {{(n-1){1'b0}}, less};

endmodule
