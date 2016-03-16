`timescale 1ns / 1ps

module Timer(
    // Standard signals
    input           CLK,
    input           RESET,

    // Bus signals
    inout   [7:0]   BUS_DATA,
    input   [7:0]   BUS_ADDR,
    input           BUS_WE,

    // Interrupts
    output          IRQ_RAISE,
    input           IRQ_ACK
 );

/*******************************************************************************
    Parameters
*******************************************************************************/

    // timer Base Address in the Memory Map
    parameter [7:0] p_timer_base_addr   = 8'hF0;

    // Default interrupt rate leading to 1 interrupt every 100 ms
    parameter       p_initial_irq_rate  = 100;

    // By default the Interrupt is Enabled
    parameter       p_initial_irq_en    = 1'b1;

    /*
        BaseAddr + 0 -> reports current timer value

        BaseAddr + 1 -> Address of a timer interrupt interval register, 100 ms
        by default

        BaseAddr + 2 -> Resets the timer, restart counting from zero

        BaseAddr + 3 -> Address of an interrupt Enable register, allows the
            microprocessor to disable the timer

        This module will raise an interrupt flag when the designated time is up.
        It will automatically set the time of the next interrupt to the time of
        the last interrupt plus a configurable value (in milliseconds).
        Interrupt Rate Configuration - The Rate is initialised to 100 by the
        parameter above, but can also be set by the processor by writing to mem address BaseAddr + 1;
    */

/*******************************************************************************
    Register/Wire Declarations
*******************************************************************************/

    reg     [7:0]   irq_rate;
    reg             irq_en;

    reg     [31:0]  down_counter;
    reg     [31:0]  timer;

    reg             target_reached;
    reg     [31:0]  last_time;

    reg             irq;

    reg             transmit_timer_value;

/*******************************************************************************
    Continous Assignments
*******************************************************************************/

    assign IRQ_RAISE    = irq;
    assign BUS_DATA     = (transmit_timer_value) ? timer[7:0] : 8'hZZ;

/*******************************************************************************
    Sequential Logic
*******************************************************************************/

    always@(posedge CLK) begin
        if(RESET) begin
            irq_rate <= p_initial_irq_rate;
        end else if((BUS_ADDR == p_timer_base_addr + 8'h01) & BUS_WE) begin
            irq_rate <= BUS_DATA;
        end
    end

    always@(posedge CLK) begin
        if(RESET) begin
            irq_en <= p_initial_irq_en;
        end else if((BUS_ADDR == p_timer_base_addr + 8'h03) & BUS_WE) begin
            irq_en <= BUS_DATA[0];
        end
    end

    // First we must lower the clock speed from 100MHz to 1 KHz (1ms period)

    always@(posedge CLK) begin
        if(RESET) begin
            down_counter <= 0;
        end else begin
            if(down_counter == 32'd99999) begin
                down_counter <= 0;
            end else begin
                down_counter <= down_counter + 1'b1;
            end
        end
    end

    /*
        Now we can record the last time an interrupt was sent, and add a value
        to it to determine if it is time to raise the interrupt. But first, let
        us generate the 1ms counter (timer)
    */

    always@(posedge CLK) begin
        if(RESET | (BUS_ADDR == p_timer_base_addr + 8'h02)) begin
            timer <= 0;
        end else begin
            if((down_counter == 0)) begin
                timer <= timer + 1'b1;
            end else begin
                timer <= timer;
            end
        end
    end

    //Interrupt generation

    always@(posedge CLK) begin
        if(RESET) begin
            target_reached  <= 1'b0;
            last_time       <= 0;
        end else if((last_time + irq_rate) == timer) begin
            if(irq_en) begin
                target_reached <= 1'b1;
            end
            last_time <= timer;
        end else begin
            target_reached <= 1'b0;
        end
    end

    //Broadcast the Interrupt

    always@(posedge CLK) begin
        if(RESET) begin
            irq <= 1'b0;
        end else if(target_reached) begin
            irq <= 1'b1;
        end else if(IRQ_ACK) begin
            irq <= 1'b0;
        end
    end

    // Tristate output for interrupt timer output value

    always@(posedge CLK) begin
        if(BUS_ADDR == p_timer_base_addr) begin
            transmit_timer_value        <= 1'b1;
        end else begin
            transmit_timer_value        <= 1'b0;
        end
    end

endmodule
