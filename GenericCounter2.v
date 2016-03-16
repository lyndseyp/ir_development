`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Edinburgh University
// Engineer: Lyndsey Penman (s1217623)
// 
// Create Date:    17:05:28 10/18/2014 
// Design Name: Clock Step Down Counter
// Module Name: GenericCounter2
// Project Name: IR Transmitter
// Target Devices: Digilent Basys 3
// Tool versions: 
// Description:  Generic counter module which can be used by instantiation in other modules to make multiple counters
// of varying sizes (counter size and maximum value are defined by the user). Counter counts up to a maximum value (defined by the user), 
// and resets to 0, transmitting a trigger out signal upon reset which can be used as an enable signal by other counters
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
`define BLUE        4'b1000
`define YELLOW      4'b1001
`define GREEN       4'b1010
`define RED         4'b1011
`define NOCOLOUR    4'b1100

module GenericCounter2( CLK,									// Master clock signal from board (typically 50MHz)
				       RESET,									// Reset signal
				  	   ENABLE,								// Enable signal which will allow the counter to begin counting
					   FREQDIVIDE,
					   //COLOUR,
					   TRIG_OUT								// Trigger out signal sent out when the counter reaches its maximum and resets to 0
					   //COUNT									// Output of the counter, will be a bus containing the value the counter has counted to
					   );
							
	parameter COUNTER_WIDTH = 26;								// Parameter which controls width of the counter 
	//parameter COUNTER_MAX = 50000000;
	//reg COUNTER_MAX;									// Parameter which defines maximum counter value, after which it will reset to 0
	//initial COUNTER_MAX = 50000000;
	
	input CLK;														// Actual definitions of inputs and outputs
	input RESET;
	input ENABLE;
	input [25:0] FREQDIVIDE;
	//input [3:0] COLOUR;
	output TRIG_OUT;
	//output [COUNTER_WIDTH - 1:0] COUNT;						// Using COUNTER_WIDTH - 1 allows to counter to have a variable count while only having to change COUNTER_WIDTH at the top
	
	reg [COUNTER_WIDTH - 1:0] Counter = 0;						// Register holding the value of COUNT between clock cycles
	reg TriggerOut = 0;												// Register holding the current value of the trigger
	
	/*always @ (*) begin
	   case (COLOUR)
	       `BLUE   :   begin
	           COUNTER_MAX = 25000000;
	       end
	       `YELLOW :   begin
	           COUNTER_MAX = 16666667;
	       end
	       `GREEN  :   begin
	           COUNTER_MAX = 12500000;
	       end
	       `RED    :   begin
	           COUNTER_MAX = 10000000;
	       end
	       `NOCOLOUR   :   begin
	           COUNTER_MAX = 50000000;
	       end
	       default :   begin
	           COUNTER_MAX = 50000000;
	       end
	   endcase
	end*/
	
	// Synchronous Counter Logic
	always @ (posedge CLK) begin
		if (RESET)													// If RESET is true, reset the count to 0
			Counter <= 0;
		else begin
			if (ENABLE) begin
				if (Counter == FREQDIVIDE)					// If the count has reached the maximum value, reset to 0
					Counter <= 0;
				else
					Counter <= Counter + 1;						// Otherwise increment the counter
			end
		end
	end
	
	// Synchronous Trigger Out Logic
	always @ (posedge CLK) begin
		if (RESET)													// If RESET is true, TriggerOut is 0 (i.e. don't send count signal to the next counter)
			TriggerOut <= 0;
		else begin
			if (ENABLE && (Counter == FREQDIVIDE))		// If the count is enabled, and the counter has reached the reset value, send a signal to the next counter
				TriggerOut <= ~TriggerOut;
			else
				TriggerOut <= TriggerOut;
		end
	end
	
	// Assign the register that holds the output value to the actual output
	//assign COUNT = Counter;
	assign TRIG_OUT = TriggerOut;
		

endmodule
