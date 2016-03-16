`timescale 1ns / 1ps

module ROM(
    // Standard signals
    input           CLK,

    // Bus signals
    output [7:0]    DATA,
    input  [7:0]    ADDR
);
    parameter ram_addr_width = 8;

    reg [7:0] out;
    reg [7:0] mem [2**ram_addr_width-1:0];

    assign DATA = out;

    // Load program
    initial $readmemh("ROM.txt", mem);

    // Single port ROM
    always@(posedge CLK) begin
        out <= mem[ADDR];
    end

endmodule
