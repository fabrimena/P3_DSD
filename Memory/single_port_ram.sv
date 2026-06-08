module single_port_ram #(
    parameter DATA_N = 32,
    parameter SIZE   = 1024
)
(
    input clk,
    input [3:0] wr_en,
    input [$clog2(SIZE)-1:0] addr,
    input [DATA_N-1:0] w_data,
    output [DATA_N-1:0] r_data
);

    reg [DATA_N-1:0] ram [0:SIZE-1];
    
    integer i;
    initial begin
        for (i = 0; i < SIZE; i = i + 1) begin
            ram[i] = {DATA_N{1'b0}};
        end
    end
    
    assign r_data = ram[addr];
    
    always @(posedge clk) begin
        if (wr_en[0]) ram[addr][7:0]   <= w_data[7:0];
        if (wr_en[1]) ram[addr][15:8]  <= w_data[15:8];
        if (wr_en[2]) ram[addr][23:16] <= w_data[23:16];
        if (wr_en[3]) ram[addr][31:24] <= w_data[31:24];
    end
endmodule
