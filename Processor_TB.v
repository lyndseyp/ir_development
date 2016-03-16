`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.03.2016 10:58:53
// Design Name: 
// Module Name: Processor_TB
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


module Processor_TB();

    reg        CLK;
    reg        RESET;
    
    wire [7:0] BUS_ADDR;
    wire [7:0] BUS_DATA;
    wire       BUS_WE;
    
    wire [7:0] ROM_ADDRESS;
    wire [7:0] ROM_DATA;
    
    reg  [1:0] BUS_INTERRUPTS_RAISE;
    wire [1:0] BUS_INTERRUPTS_ACK;
    
    wire       IR_OUT;

    Processor uut0 (.CLK(CLK),
                    .RESET(RESET),
                    .BUS_ADDR(BUS_ADDR),
                    .BUS_DATA(BUS_DATA),
                    .BUS_WE(BUS_WE),
                    .ROM_ADDRESS(ROM_ADDRESS),
                    .ROM_DATA(ROM_DATA),
                    .BUS_INTERRUPTS_RAISE(BUS_INTERRUPTS_RAISE),
                    .BUS_INTERRUPTS_ACK(BUS_INTERRUPTS_ACK)
                    );
                    
    ROM uut1       (.CLK(CLK),
                    .DATA(ROM_DATA),
                    .ADDR(ROM_ADDRESS)
                    );
                    
    RAM uu2        (.CLK(CLK),
                    .BUS_DATA(BUS_DATA),
                    .BUS_ADDR(BUS_ADDR),
                    .BUS_WE(BUS_WE)
                    );
                    
    IR uut3        (.CLK(CLK),
                    .RESET(RESET),
                    .BUS_ADDR(BUS_ADDR),
                    .BUS_DATA(BUS_DATA),
                    .BUS_WE(BUS_WE),
                    .IR_OUT(IR_OUT)
                    );
                    
    /*Timer uut4     (.CLK(CLK),
                    .RESET(RESET),
                    .BUS_DATA(BUS_DATA),
                    .BUS_ADDR(BUS_ADDR),
                    .BUS_WE(BUS_WE),
                    .IRQ_RAISE(BUS_INTERRUPTS_RAISE[1]),
                    .IRQ_ACK(BUS_INTERRUPTS_ACK[1])
                    );*/
                    
    always 
        #10 CLK = !CLK;
        
    always 
        #100 BUS_INTERRUPTS_RAISE[1] = !BUS_INTERRUPTS_RAISE[1];
        
    initial begin
        CLK = 1'b0;
        RESET = 1'b1;
        BUS_INTERRUPTS_RAISE = 2'b00;
        #20 RESET = 0;
    end
                    

endmodule
