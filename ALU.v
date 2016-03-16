`timescale 1ns / 1ps

module ALU(
    // Standard signals
    input           CLK,
    input           RESET,

    // I/O
    input   [7:0]   IN_A,
    input   [7:0]   IN_B,
    input   [3:0]   ALU_OP,
    output  [7:0]   OUT_RESULT
);

    reg [7:0] out;

    assign OUT_RESULT = out;

    // Arithmetic Computation
    always@(posedge CLK) begin
        if(RESET) begin
            out <= 0;
        end else begin
            case (ALU_OP)
                // Maths Operations
                // Add A + B
                4'h0: out <= IN_A + IN_B;
                // Subtract A - B
                4'h1: out <= IN_A - IN_B;
                // Multiply A * B
                4'h2: out <= IN_A * IN_B;
                // Shift Left A << 1
                4'h3: out <= IN_A << 1;
                // Shift Right A >> 1
                4'h4: out <= IN_A >> 1;
                // Increment A+1
                4'h5: out <= IN_A + 1'b1;
                // Increment B+1
                4'h6: out <= IN_B + 1'b1;
                // Decrement A-1
                4'h7: out <= IN_A - 1'b1;
                // Decrement B+1
                4'h8: out <= IN_B - 1'b1;

                // Equality Operations
                // A == B
                4'h9: out <= (IN_A == IN_B) ? 8'h01 : 8'h00;
                // A > B
                4'hA: out <= (IN_A > IN_B) ? 8'h01 : 8'h00;
                // A < B
                4'hB: out <= (IN_A < IN_B) ? 8'h01 : 8'h00;

                //Default A
                default: out <= IN_A;
            endcase
        end
    end

endmodule
