`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 11.03.2016 18:10:11
// Design Name:
// Module Name: IR
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module IR(
    input CLK,
    input RESET,
    inout [7:0] BUS_DATA,
    input [7:0] BUS_ADDR,
    input BUS_WE,
    output IR_OUT
    );

    parameter dir_addr = 8'h90;

    reg blue = 1, yellow = 0, green = 0, red = 0;
    reg [3:0] control;
    reg [7:0] dir_data;

    initial dir_data = 0;
    initial control = 0;

    always @ (posedge CLK) begin
        if (BUS_ADDR == dir_addr) begin
            dir_data <= BUS_DATA;
        end
    end

    always @ (posedge CLK) begin
        if (BUS_ADDR == dir_addr) begin
            dir_data <= BUS_DATA;
        end
    end

    always @ (*) begin
        control = 0;
        case (dir_data)
            8'h1:   begin
                control[2] = 1;
            end
            8'h2:   begin
                control[3] = 1;
            end
            8'h3:   begin
               control[2] = 1;
               control[0] = 1;
            end
            8'h4:   begin
                control[2] = 1;
                control[1] = 1;
            end
            8'h5:   begin
                control[3] = 1;
                control[0] = 1;
            end
            8'h6:   begin
                control[3] = 1;
                control[1] = 1;
            end
            8'h7:   begin
                control = 0;
            end
        endcase
    end

    IR_Transmitter ir_1 (.CLK (CLK),
                         .RESET (RESET),
                         .BLUE (blue),
                         .YELLOW (yellow),
                         .GREEN (green),
                         .RED (red),
                         .CONTROL (control),
                         .IR_LED (IR_OUT)
                         );

endmodule
