`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Edinburgh University 
// Engineer: Lyndsey Penman (s1217623)
// 
// Create Date: 13.02.2016 12:37:43
// Design Name: IR_Transmitter_Mk_VIII
// Module Name: IR_Transmitter
// Project Name: IR Transmitter
// Target Devices: Digilent Basys 3
// Tool Versions: 
// Description: Generates packet to be sent to remote controlled cars (4 different colours)
//              Packet controls the car
// 
// Dependencies: 
// 
// Revision: 8
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
// State values - named for convenience and readability

`define IDLE        4'b0000
`define START       4'b0001
`define GAP         4'b0010
`define CARSELECT   4'b0011
`define RIGHT       4'b0100
`define LEFT        4'b0101
`define FORWARD     4'b0110
`define BACK        4'b0111
`define BLUE        4'b1000
`define YELLOW      4'b1001
`define GREEN       4'b1010
`define RED         4'b1011
`define NOCOLOUR    4'b1100

// Values of assert timings depending on colour

`define DEASSERTCOUNT   8'd22
`define ASSERTCOUNTB    8'd47
`define ASSERTCOUNTYG   8'd44
`define ASSERTCOUNTR    8'd48
`define NOCOLOURASSERT  8'd47

`define STARTCOUNT      8'd191
`define CARSELECTCOUNT  8'd47
`define GAPCOUNT        8'd25

/*`define DEASSERTCOUNT   8'd5
`define ASSERTCOUNTB    8'd10
`define ASSERTCOUNTYG   8'd10
`define ASSERTCOUNTR    8'd48
`define NOCOLOURASSERT  8'd47

`define STARTCOUNT      8'd11
`define CARSELECTCOUNT  8'd8
`define GAPCOUNT        8'd5*/

module IR_Transmitter (
    input           CLK,
    
    // Button controls from the board
    
    input [3:0]     CONTROL,
    
    // Switch inputs to control the car colour
    
    input           BLUE,
    input           YELLOW,
    input           GREEN,
    input           RED,
    
    // Enable and resets for 10Hz counter and state machine
    
    //input           ENABLE,
    //input           SMRESET,
    input           RESET,
   
    
    // LEDs used for testing purposes
    
    //output          ENVELOPELED,
    /*output          PULSEOUT,
    output          COUNTLED,
    output          IDLELED,
    output          STARTLED,
    output          GAPLED,
    output          CARSELECTLED,
    output          RIGHTLED,
    output          LEFTLED,
    output          FORWARDLED,
    output          BACKLED,*/
    
    // Final output - what's transmitted to the car
    
    output          IR_LED
    //output          SEND_PACKET_LED,
    
    // 7 segment display outputs 
    
    //output [7:0]    HEX_OUT,
    //output [3:0]    SEG_SELECT_OUT
    );
    
    // Wires to carry signals from 10Hz counter to the rest of the module
    
    wire PULSETRIG;
    wire SEND_PACKET; // Enables other counter
    
    //reg RESET = 0;
    reg SMRESET = 0;
    
    reg ENABLE = 1;
    
    // 10Hz counter to generate enable signal for clock step-down counter 10x per second
    
    GenericCounter TENHzCounter (.CLK (CLK),
                                .ENABLE (ENABLE),
                                .RESET (RESET),
                                .TRIG_OUT (SEND_PACKET)
                                );
    
    reg [3:0] COLOUR;
    initial COLOUR = `BLUE;
    
    // FREQDIVIDE holds the value the clock needs to be stepped down by depending on the car colour
    
    reg [25:0] FREQDIVIDE;
    initial FREQDIVIDE = 1389;
    
    // Uses switch input to control the frequency of the clock depending on the car colour
    
    always @ (*) begin
        if (BLUE) begin
            COLOUR = `BLUE;
            FREQDIVIDE = 1389;
        end
        else if (YELLOW) begin
            COLOUR = `YELLOW;
            FREQDIVIDE = 1250;
        end
        else if (GREEN) begin
            COLOUR = `GREEN;
            FREQDIVIDE = 1333;
        end
        else if (RED) begin
            COLOUR = `RED;
            FREQDIVIDE = 1389;
        end
        else begin
            COLOUR = `NOCOLOUR;
            FREQDIVIDE = 1389;
        end
    end
    
    // Module to control the 7 segment display to display the car colour
    
    /*Decoder ColourDisplay   (.SEG_SELECT_IN (COLOUR),
                             .HEX_OUT (HEX_OUT),
                             .SEG_SELECT_OUT (SEG_SELECT_OUT)
                             );*/
    
    // Counter to step down clock signal to required value for cars
    
    GenericCounter2 PULSEFREQ (.CLK (CLK),
                               .ENABLE (SEND_PACKET),
                               .FREQDIVIDE (FREQDIVIDE),
                               .RESET (RESET),
                               .TRIG_OUT (PULSETRIG)
                               );
    
    // Wires to carry timing values from ColourSelect to where they're needed
    
    /*wire [7:0] STARTCOUNT;
    wire [7:0] CARSELECTCOUNT;
    wire [7:0] GAPCOUNT;*/

    // Module to set the timing values of Start, Gap, and CarSelect

    /*ColourSelect ColourSelect (.CLK (CLK),
                               .COLOUR (COLOUR),
                               .StartSize (STARTCOUNT),
                               .CarSelectSize (CARSELECTCOUNT),
                               .GapSize (GAPCOUNT)
                               );*/

    // Maximum value of the counter timing the bursts

    reg [7:0] COUNTERMAX;
    initial COUNTERMAX = 1;
    
    reg [7:0] COUNT;
    initial COUNT = 0;
    
    //reg COUNTLEDREG;
    //initial COUNTLEDREG = 0;
    
    // MOVEON register indicates when a state change should occur
    
    reg MOVEON;
    initial MOVEON = 0;
   
    // Counter to count the time to remain in each state
                               
    always @ (posedge PULSETRIG) begin
        if (COUNT == (COUNTERMAX - 1)) begin        // If the machine has been in the current state for the right amount of time
            MOVEON = 1;                             // Signal a state change    
            COUNT = 0;                              // Reset the count value ready for the next count
            //COUNTLEDREG = 1;
        end
        else if (SMRESET) begin                     // If the state machine has been reset
            MOVEON = 0;                             // Don't signal a state change
            COUNT = 0;                              // Reset count
            //COUNTLEDREG = 0;
        end
        else begin                                  // Otherwise behave as normal and increment counter
            MOVEON = 0;
            COUNT = COUNT + 1;
            //COUNTLEDREG = 0;
        end
    end
    
    // Registers to hold the current state, the next state, and the state to move to after the GAP state
    
    reg [2:0] STATE;
    initial STATE = `IDLE;
    reg [2:0] NEXTSTATE;
    initial NEXTSTATE = `IDLE;
    reg [2:0] AFTERGAP;
    initial AFTERGAP = `CARSELECT;
    reg [2:0] NOWAFTERGAP;
    initial NOWAFTERGAP = `CARSELECT;
    
    // Register to hold a square wave which will later be anded with the state machine signal 
    // to create the packet to transmit to the car
    
    reg ENVELOPE;
    initial ENVELOPE = 0;
    
    // Sets STATE equal to NEXTSTATE on the stepped-down clock edge
    // and indicates the state the machine should go to following the gap state
    
    always @ (posedge PULSETRIG) begin
        if (SMRESET) begin
            STATE = `IDLE;
            NOWAFTERGAP = `IDLE;
        end
        else begin
            STATE = NEXTSTATE;
            NOWAFTERGAP = AFTERGAP;
        end
    end
    
    // Registers to hold the values of the state LEDs
    
    /*reg IDLELEDREG;
    reg STARTLEDREG;
    reg GAPLEDREG;
    reg CARSELECTLEDREG;
    reg RIGHTLEDREG;
    reg LEFTLEDREG;
    reg FORWARDLEDREG;
    reg BACKLEDREG;
    
    initial IDLELEDREG = 0;
    initial STARTLEDREG = 0;
    initial GAPLEDREG = 0;
    initial CARSELECTLEDREG = 0;
    initial RIGHTLEDREG = 0;
    initial LEFTLEDREG = 0;
    initial FORWARDLEDREG = 0;
    initial BACKLEDREG = 0;*/
    
    // Main state machine controlling the state changes to generate the packet to be transmitted to the car
    
    always @ (*) begin
        case (STATE)
            `IDLE       :   begin
                if (MOVEON) begin                           // If MOVEON is asserted (i.e. count has reached 9)
                    NEXTSTATE = `START;                     // Move to the START state next
                    AFTERGAP = `CARSELECT;                  // AFTERGAP is really pointless here but there's an error if it's not here
                    COUNTERMAX = `STARTCOUNT;
                end
                else begin                                  // If MOVEON is not asserted (i.e. count hasn't reached 9)
                    NEXTSTATE = `IDLE;                      // Remain in the IDLE state
                    AFTERGAP = `CARSELECT;                  // AFTERGAP is really pointless here but there's an error if it's not here
                    COUNTERMAX = 1;
                end
            end
            `START      :   begin
                if (MOVEON) begin                           // If MOVEON is asserted (i.e. count has reached 9)
                    NEXTSTATE = `GAP;                       // Move to the GAP state next
                    AFTERGAP = `CARSELECT;                  // The state after the GAP state is CARSELECT
                    COUNTERMAX = `GAPCOUNT;
                end
                else begin                                  // If MOVEON is not asserted (i.e. count hasn't reached 9)
                    NEXTSTATE = `START;
                    AFTERGAP = `CARSELECT;
                    COUNTERMAX = `STARTCOUNT;
                end
            end
            `GAP        :   begin
                if (MOVEON) begin                           // If MOVEON is asserted (i.e. count has reached 9)
                    case (NOWAFTERGAP)
                        `IDLE   :   begin
                            NEXTSTATE = `IDLE;
                            AFTERGAP = `IDLE;
                            COUNTERMAX = 1;
                        end
                        `START  :   begin
                            NEXTSTATE = `START;
                            AFTERGAP = `START;
                            COUNTERMAX = `STARTCOUNT;
                        end
                        `CARSELECT  :   begin
                            NEXTSTATE = `CARSELECT;
                            AFTERGAP = `CARSELECT;
                            COUNTERMAX = `CARSELECTCOUNT;
                        end
                        `RIGHT  :   begin
                            NEXTSTATE = `RIGHT;
                            AFTERGAP = `RIGHT;
                            if (CONTROL[0]) begin
                                if (BLUE)                               // Decides timing of ASSERT and DEASSERT depending on car colour
                                    COUNTERMAX = `ASSERTCOUNTB;
                                else if (GREEN)
                                    COUNTERMAX = `ASSERTCOUNTYG;
                                else if (YELLOW)
                                    COUNTERMAX = `ASSERTCOUNTYG;
                                else if (RED)
                                    COUNTERMAX = `ASSERTCOUNTR;
                                else
                                    COUNTERMAX = `NOCOLOURASSERT;
                            end
                            else
                                COUNTERMAX = `DEASSERTCOUNT;
                        end
                        `LEFT   :   begin
                            NEXTSTATE = `LEFT;
                            AFTERGAP = `LEFT;
                            if (CONTROL[1]) begin
                                if (BLUE)
                                    COUNTERMAX = `ASSERTCOUNTB;
                                else if (GREEN)
                                    COUNTERMAX = `ASSERTCOUNTYG;
                                else if (YELLOW)
                                    COUNTERMAX = `ASSERTCOUNTYG;
                                else if (RED)
                                    COUNTERMAX = `ASSERTCOUNTR;
                                else
                                    COUNTERMAX = `NOCOLOURASSERT;
                            end
                            else
                                COUNTERMAX = `DEASSERTCOUNT;
                        end
                        `FORWARD    :   begin
                            NEXTSTATE = `FORWARD;
                            AFTERGAP = `FORWARD;
                            if (CONTROL[2]) begin
                                if (BLUE)
                                    COUNTERMAX = `ASSERTCOUNTB;
                                else if (GREEN)
                                    COUNTERMAX = `ASSERTCOUNTYG;
                                else if (YELLOW)
                                    COUNTERMAX = `ASSERTCOUNTYG;
                                else if (RED)
                                    COUNTERMAX = `ASSERTCOUNTR;
                                else
                                    COUNTERMAX = `NOCOLOURASSERT;
                            end
                            else
                                COUNTERMAX = `DEASSERTCOUNT;
                        end
                        `BACK   :   begin
                            NEXTSTATE = `BACK;
                            AFTERGAP = `BACK;
                            if (CONTROL[3]) begin
                                if (BLUE)
                                    COUNTERMAX = `ASSERTCOUNTB;
                                else if (GREEN)
                                    COUNTERMAX = `ASSERTCOUNTYG;
                                else if (YELLOW)
                                    COUNTERMAX = `ASSERTCOUNTYG;
                                else if (RED)
                                    COUNTERMAX = `ASSERTCOUNTR;
                                else
                                    COUNTERMAX = `NOCOLOURASSERT;
                            end
                            else
                                COUNTERMAX = `DEASSERTCOUNT;
                        end
                        default :   begin
                            NEXTSTATE = `IDLE;
                            AFTERGAP = `IDLE;
                            COUNTERMAX = 1;
                        end
                    endcase
                end
                else begin                                  // If MOVEON is not asserted (i.e. count hasn't reached 9)
                    NEXTSTATE = `GAP;                       // Remain in the GAP state
                    AFTERGAP = AFTERGAP;
                    COUNTERMAX = `GAPCOUNT;
                end
            end
            `CARSELECT  :   begin
                if (MOVEON) begin                           // If MOVEON is asserted (i.e. count has reached 9)
                    NEXTSTATE = `GAP;                       // Move to the GAP state
                    AFTERGAP = `RIGHT;                      // The state after the GAP state is RIGHT
                    COUNTERMAX = `GAPCOUNT;
                end
                else begin                                  // If MOVEON is not asserted (i.e. count hasn't reached 9)
                    NEXTSTATE = `CARSELECT;                 // Remain in the CARSELECT state
                    AFTERGAP = `RIGHT;
                    COUNTERMAX = `CARSELECTCOUNT;
                end                
            end
            `RIGHT  :   begin
                if (MOVEON) begin                           // If MOVEON is asserted (i.e. count has reached 9)
                    NEXTSTATE = `GAP;                       // Move to the GAP state
                    AFTERGAP = `LEFT;                       // The state after the GAP state is LEFT
                    COUNTERMAX = `GAPCOUNT;
                end
                else begin                                  // If MOVEON is not asserted (i.e. count hasn't reached 9)
                    NEXTSTATE = `RIGHT;                     // Remain in the RIGHT state
                    AFTERGAP = `LEFT;
                    if (CONTROL[0]) begin
                        if (BLUE)
                            COUNTERMAX = `ASSERTCOUNTB;
                        else if (GREEN)
                            COUNTERMAX = `ASSERTCOUNTYG;
                        else if (YELLOW)
                            COUNTERMAX = `ASSERTCOUNTYG;
                        else if (RED)
                            COUNTERMAX = `ASSERTCOUNTR;
                        else
                            COUNTERMAX = `NOCOLOURASSERT;
                    end
                    else
                        COUNTERMAX = `DEASSERTCOUNT;
                end
            end
            `LEFT   :   begin
                if (MOVEON) begin                           // If MOVEON is asserted (i.e. count has reached 9)
                    NEXTSTATE = `GAP;                       // Move to the GAP state
                    AFTERGAP = `FORWARD;                    // The state after the GAP state is FORWARD
                    COUNTERMAX = `GAPCOUNT;
                end
                else begin                                  // If MOVEON is not asserted (i.e. count hasn't reached 9)
                    NEXTSTATE = `LEFT;                      // Remain in the LEFT state
                    AFTERGAP = `FORWARD;
                    if (CONTROL[1]) begin
                        if (BLUE)
                            COUNTERMAX = `ASSERTCOUNTB;
                        else if (GREEN)
                            COUNTERMAX = `ASSERTCOUNTYG;
                        else if (YELLOW)
                            COUNTERMAX = `ASSERTCOUNTYG;
                        else if (RED)
                            COUNTERMAX = `ASSERTCOUNTR;
                        else
                            COUNTERMAX = `NOCOLOURASSERT;
                    end
                    else
                        COUNTERMAX = `DEASSERTCOUNT;
                end
            end
            `FORWARD    :   begin
                if (MOVEON) begin                           // If MOVEON is asserted (i.e. count has reached 9)
                    NEXTSTATE = `GAP;                       // Move to the GAP state
                    AFTERGAP = `BACK;                       // The state after the GAP state is BACK
                    COUNTERMAX = `GAPCOUNT;
                end
                else begin                                  // If MOVEON is not asserted (i.e. count hasn't reached 9)
                    NEXTSTATE = `FORWARD;                   // Remain in the FORWARD state
                    AFTERGAP = `BACK;
                    if (CONTROL[2]) begin
                        if (BLUE)
                            COUNTERMAX = `ASSERTCOUNTB;
                        else if (GREEN)
                            COUNTERMAX = `ASSERTCOUNTYG;
                        else if (YELLOW)
                            COUNTERMAX = `ASSERTCOUNTYG;
                        else if (RED)
                            COUNTERMAX = `ASSERTCOUNTR;
                        else
                            COUNTERMAX = `NOCOLOURASSERT;
                    end
                    else
                        COUNTERMAX = `DEASSERTCOUNT;
                end
            end
            `BACK   :   begin
                if (MOVEON) begin                           // If MOVEON is asserted (i.e. count has reached 9)
                    NEXTSTATE = `GAP;                       // Move to the GAP state
                    AFTERGAP = `START;                      // The state after the GAP state is IDLE
                    COUNTERMAX = `GAPCOUNT;
                end
                else begin                                  // If MOVEON is not asserted (i.e. count hasn't reached 9)
                    NEXTSTATE = `BACK;                      // Remain in the BACK state
                    AFTERGAP = `START;
                    if (CONTROL[3]) begin
                        if (BLUE)
                            COUNTERMAX = `ASSERTCOUNTB;     // Logic to control the timing of the assert and deassert signals
                        else if (GREEN)                     // This is not optimal because the optimise version didn't work for no explainable reason???
                            COUNTERMAX = `ASSERTCOUNTYG;
                        else if (YELLOW)
                            COUNTERMAX = `ASSERTCOUNTYG;
                        else if (RED)
                            COUNTERMAX = `ASSERTCOUNTR;
                        else
                            COUNTERMAX = `NOCOLOURASSERT;
                    end
                    else
                        COUNTERMAX = `DEASSERTCOUNT;
                end
            end
            default :   begin                               // If the state machine isn't in a known state
                NEXTSTATE = `IDLE;                          // Go to the IDLE state
                AFTERGAP = `IDLE;
                COUNTERMAX = 1;
            end
        endcase
    end
    
    // Statement to create the square wave to and with the car frequency signal
    
    always @ (posedge CLK) begin
        if (STATE == `IDLE || STATE == `GAP)        // In IDLE state or GAP state set the output to 0
            ENVELOPE = 0;
        else                                        // In the other states, allow the output to proceed as normal
            ENVELOPE = 1;
    end
    
    /*always @ (posedge CLK) begin
        if (STATE == `IDLE)
            IDLELEDREG <= 1;
        else
            IDLELEDREG <= 0;
        if (STATE == `START)
            STARTLEDREG <= 1;
        else
            STARTLEDREG <= 0;
        if (STATE == `CARSELECT)
            CARSELECTLEDREG <= 1;
        else
            CARSELECTLEDREG <= 0;
        if (STATE == `RIGHT)
            RIGHTLEDREG <= 1;
        else
            RIGHTLEDREG <= 0;
        if (STATE == `LEFT)
            LEFTLEDREG <= 1;
        else
            LEFTLEDREG <= 0;
        if (STATE == `FORWARD)
            FORWARDLEDREG <= 1;
        else
            FORWARDLEDREG <= 0;
        if (STATE == `BACK)
            BACKLEDREG <= 1;
        else
            BACKLEDREG <= 0;
        if (STATE == `GAP)
            GAPLEDREG <= 1;
        else
            GAPLEDREG <= 0;
    end*/
    
    reg IR_LED_REG;
    initial IR_LED_REG = 0;
    
    // Register to hold the output of the AND operation modulating the car frequency signal
    
    always @ (*) begin
        IR_LED_REG = (ENVELOPE && PULSETRIG);
    end
    
    // Assigning the values of the LED registers to the LED outputs
    
    //assign COUNTLED = COUNTLEDREG;                  // LED lights up when the counter reaches 9
    
    //assign PULSEOUT = PULSETRIG;                    // Stepped down clock signal output
    
    //assign SEND_PACKET_OUT = SEND_PACKET;
    
    // State indicator LEDs
    
    /*assign IDLELED  = IDLELEDREG;
    assign STARTLED = STARTLEDREG;
    assign GAPLED   = GAPLEDREG;
    assign CARSELECTLED = CARSELECTLEDREG;
    assign RIGHTLED = RIGHTLEDREG;
    assign LEFTLED = LEFTLEDREG;
    assign FORWARDLED = FORWARDLEDREG;
    assign BACKLED = BACKLEDREG;*/
    
    //assign SEND_PACKET_LED = SEND_PACKET;
    
    //assign ENVELOPELED = ENVELOPE;
    
    // Assigns the register holding the output to the actual output
    
    assign IR_LED = IR_LED_REG;
    
endmodule
