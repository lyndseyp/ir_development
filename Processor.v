`timescale 1ns / 1ps

module Processor(
    //Standard Signals
    input           CLK,
    input           RESET,

    //BUS Signals
    inout   [7:0]   BUS_DATA,
    output  [7:0]   BUS_ADDR,
    output          BUS_WE,

    // ROM signals
    output  [7:0]   ROM_ADDRESS,
    input   [7:0]   ROM_DATA,

    // INTERRUPT signals
    input   [1:0]   BUS_INTERRUPTS_RAISE,
    output  [1:0]   BUS_INTERRUPTS_ACK
);

/*******************************************************************************
    Parameters
*******************************************************************************/

/*
    The microprocessor is essentially a state machine, with one sequential
    pipeline of states for each operation. The current list of operations is:

    0: Read from memory to A
    1: Read from memory to B
    2: Write to memory from A
    3: Write to memory from B
    4: Do maths with the ALU, and save result in reg A
    5: Do maths with the ALU, and save result in reg B
    6: if A (== or < or > B) GoTo ADDR
    7: Goto ADDR
    8: Go to IDLE
    9: End thread, goto idle state and wait for interrupt.
    10: Function call
    11: Return from function call
    12: Dereference A
    13: Dereference B
*/

    parameter [7:0]

        //Waits here until an interrupt wakes up the processor.
        p_idle                  = 8'hF0,

        // Wait.
        p_thread_start_addr_0   = 8'hF1,

        // Apply the new address to the program counter.
        p_thread_start_addr_1   = 8'hF2,

        // Wait. Goto ChooseOp.
        p_thread_start_addr_2   = 8'hF3,

        /*
            Depending on the value of ProgMemOut, goto one of the instruction
            start states.
        */

        // Operation selection
        p_choose_op             = 8'h00,

        // Memory Manipulation

        //Wait to find what address to read, save reg select.
        p_read_from_mem_a       = 8'h10,

        //Wait to find what address to read, save reg select.
        p_read_from_mem_b       = 8'h11,

        // Set BUS_ADDR to designated address.
        p_read_from_mem_0       = 8'h12,

        // wait - Increments program counter by 2. Reset offset.
        p_read_from_mem_1       = 8'h13,

        //Writes memory output to chosen register, end op.
        p_read_from_mem_2       = 8'h14,

        // Immediates
        p_read_immediate_a      = 8'h15,

        p_read_immediate_b      = 8'h16,

        p_read_immediate_0      = 8'h17,

        //Reads Op+1 to find what address to Write to.
        p_write_to_mem_a        = 8'h20,

        //Reads Op+1 to find what address to Write to.
        p_write_to_mem_b        = 8'h21,

        // Wait - Increments program counter by 2. Reset offset.
        p_write_to_mem_0        = 8'h22,

        // Data Manipulation

        // The result of maths op. is available, save it to Reg A.
        p_math_op_a             = 8'h30,

        // The result of maths op. is available, save it to Reg B.
        p_math_op_b             = 8'h31,

        // wait for new op address to settle. end op.
        p_math_op_0             = 8'h32,

        // Control Flow Manipulation

        // Evaluate branch condition
        p_branch_check          = 8'h40,

        // Branch if true
        p_branch_taken          = 8'h41,

        // Wait state for branches to resolve, regardless of taken/not taken.
        p_branch_wait           = 8'h42,

        // Initial Goto State
        p_goto_addr             = 8'h70,

        // Function Call
        p_funcall               = 8'h90,

        // p_return
        p_return                = 8'hA0,

        // Dereferencing

        // Dereference A
        p_deref_a               = 8'hB0,

        // Dereference B
        p_deref_b               = 8'hC0,

        p_deref_read_from_mem_0 = 8'hC1;

/*******************************************************************************
    Register/Wire Declarations
*******************************************************************************/

    /*
        The main data bus is treated as tristate, so we need a mechanism to
        handle this.
    */

    // Tristate signals that interface with the main state machine

    wire    [7:0]   bus_data_in;
    reg     [7:0]   curr_bus_data_out, next_bus_data_out;
    reg             curr_bus_data_out_we, next_bus_data_out_we;

    // Address

    reg     [7:0]   curr_bus_addr, next_bus_addr;

    /*
        The processor has two internal registers to hold data between
        operations, and a third to hold the current program context (Return
        Address) when using function calls.
    */

    reg     [7:0]   curr_reg_a, next_reg_a;
    reg     [7:0]   curr_reg_b, next_reg_b;
    reg             curr_reg_select, next_reg_select;
    reg     [7:0]   curr_prog_context, next_prog_context;

    // Dedicated Interrupt output lines - one for each interrupt line

    reg     [1:0]   curr_irq_ack, next_irq_ack;

    /*
        There is a program counter which points to the current operation. The
        program counter has an offset that is used to reference information that
        is part of the current operation
    */

    reg     [7:0]   curr_pc, next_pc;
    reg     [1:0]   curr_pc_offset, next_pc_offset;
    wire    [7:0]   prog_memory_out;
    wire    [7:0]   actual_addr;


    wire    [7:0] alu_out;



    reg [7:0] curr_state, next_state;

/*******************************************************************************
    Continous Assignments
*******************************************************************************/

    // Tristate Mechanism
    assign bus_data_in  = BUS_DATA;
    assign BUS_DATA     = curr_bus_data_out_we ? curr_bus_data_out : 8'hZZ;
    assign BUS_WE       = curr_bus_data_out_we;

    // Address
    assign BUS_ADDR     = curr_bus_addr;

    assign BUS_INTERRUPTS_ACK = curr_irq_ack;

    assign actual_addr = curr_pc + curr_pc_offset;

    // ROM signals
    assign ROM_ADDRESS = actual_addr;
    assign prog_memory_out = ROM_DATA;

/*******************************************************************************
    Submodules
*******************************************************************************/

    /*
        The processor has an integrated ALU that can do several different
        operations
    */

    ALU alu_0(
       //standard signals
       .CLK(CLK),
       .RESET(RESET),

       //I/O
       .IN_A(curr_reg_a),
       .IN_B(curr_reg_b),
       .ALU_OP(prog_memory_out[7:4]),
       .OUT_RESULT(alu_out)
    );

/*******************************************************************************
    Sequential Logic
*******************************************************************************/

    always@(posedge CLK) begin
        if(RESET) begin
            curr_state              <= 8'h00;
            curr_pc                 <= 8'h00;
            curr_pc_offset          <= 2'h0;
            curr_bus_addr           <= 8'hFF; //Initial instruction after reset.
            curr_bus_data_out       <= 8'h00;
            curr_bus_data_out_we    <= 1'b0;
            curr_reg_a              <= 8'h00;
            curr_reg_b              <= 8'h00;
            curr_reg_select         <= 1'b0;
            curr_prog_context       <= 8'h00;
            curr_irq_ack            <= 2'b00;
        end else begin
            curr_state              <= next_state;
            curr_pc                 <= next_pc;
            curr_pc_offset          <= next_pc_offset;
            curr_bus_addr           <= next_bus_addr;
            curr_bus_data_out       <= next_bus_data_out;
            curr_bus_data_out_we    <= next_bus_data_out_we;
            curr_reg_a              <= next_reg_a;
            curr_reg_b              <= next_reg_b;
            curr_reg_select         <= next_reg_select;
            curr_prog_context       <= next_prog_context;
            curr_irq_ack            <= next_irq_ack;
        end
    end

/*******************************************************************************
    Combinatorial Logic
*******************************************************************************/

    always@* begin
        // Generic assignment to reduce the complexity of the rest of the S/M
        next_state              = curr_state;
        next_pc                 = curr_pc;
        next_pc_offset          = 2'h0;
        next_bus_addr           = 8'hFF;
        next_bus_data_out       = curr_bus_data_out;
        next_bus_data_out_we    = 1'b0;
        next_reg_a              = curr_reg_a;
        next_reg_b              = curr_reg_b;
        next_reg_select         = curr_reg_select;
        next_prog_context       = curr_prog_context;
        next_irq_ack            = 2'b00;

        //Case statement to describe each state
        case (curr_state)
         //Thread states.
            p_idle: begin

                // Interrupt Request A.
                if(BUS_INTERRUPTS_RAISE[0]) begin
                    next_state      = p_thread_start_addr_0;
                    next_pc         = 8'hFF;
                    next_irq_ack    = 2'b01;

                //Interrupt Request B.
                end else if(BUS_INTERRUPTS_RAISE[1]) begin
                    next_state      = p_thread_start_addr_0;
                    next_pc         = 8'hFE;
                    next_irq_ack    = 2'b10;

                end else begin
                    next_state      = p_idle;
                    next_pc         = 8'hFF; //Nothing has happened.
                    next_irq_ack    = 2'b00;
                end
            end

            //Wait state - for new prog address to arrive.
            p_thread_start_addr_0: begin
                next_state = p_thread_start_addr_1;
            end

            //Assign the new program counter value
            p_thread_start_addr_1: begin
                next_state  = p_thread_start_addr_2;
                next_pc     = prog_memory_out;
            end

            //Wait for the new program counter value to settle
            p_thread_start_addr_2: begin
                next_state  = p_choose_op;
            end

            /*
                p_choose_op - Another case statement to choose which operation
                to perform
            */
            p_choose_op: begin
                case (prog_memory_out[3:0])
                    4'h0: begin
                        if (prog_memory_out[7:4] == 4'hF) begin
                            next_state  = p_read_immediate_a;
                        end else begin
                            next_state  = p_read_from_mem_a;
                        end
                    end
                    4'h1: begin
                        if (prog_memory_out[7:4] == 4'hF) begin
                            next_state  = p_read_immediate_b;
                        end else begin
                            next_state  = p_read_from_mem_b;
                        end
                    end
                    4'h2: next_state    = p_write_to_mem_a;
                    4'h3: next_state    = p_write_to_mem_b;
                    4'h4: next_state    = p_math_op_a;
                    4'h5: next_state    = p_math_op_b;
                    4'h6: next_state    = p_branch_check;
                    4'h7: next_state    = p_goto_addr;
                    4'h8: next_state    = p_idle;
                    4'h9: next_state    = p_funcall;
                    4'hA: next_state    = p_return;
                    4'hB: next_state    = p_deref_a;
                    4'hC: next_state    = p_deref_b;
                    default: next_state = curr_state;
                endcase
                next_pc_offset = 2'h1;
            end

            /*
                p_read_from_mem_a : here starts the memory read operational
                pipeline. Wait state - to give time for the mem address to be
                read. Reg select is set to 0
            */
            p_read_from_mem_a: begin
                next_state      = p_read_from_mem_0;
                next_reg_select = 1'b0;
            end

            /*
                p_read_from_mem_b : here starts the memory read operational
                pipeline. Wait state - to give time for the mem address to be
                read. Reg select is set to 1
            */
            p_read_from_mem_b: begin
                next_state      = p_read_from_mem_0;
                next_reg_select = 1'b1;
            end

            /*
                The address will be valid during this state, so set the BUS_ADDR
                to this value.
            */
            p_read_from_mem_0: begin
                next_state      = p_read_from_mem_1;
                next_bus_addr   = prog_memory_out;
            end

            /*
                Wait state - to give time for the mem data to be read. Increment
                the program counter here. This must be done 2 clock cycles ahead
                so that it presents the right data when required.
            */
            p_read_from_mem_1: begin
                next_state  = p_read_from_mem_2;
                next_pc     = curr_pc + 2;
            end

            /*
                The data will now have arrived from memory. Write it to the
                proper register.
            */
            p_read_from_mem_2: begin
                next_state = p_choose_op;
                if(!curr_reg_select) begin
                    next_reg_a = bus_data_in;
                end else begin
                    next_reg_b = bus_data_in;
                end
            end

            /*
                Load immediates
            */

            p_read_immediate_a: begin
                next_state      = p_read_immediate_0;
                next_reg_select = 1'b0;
                next_pc         = curr_pc + 2;
            end

            p_read_immediate_b: begin
                next_state      = p_read_immediate_0;
                next_reg_select = 1'b1;
                next_pc         = curr_pc + 2;
            end

            p_read_immediate_0: begin
                next_state      = p_choose_op;
                if(!curr_reg_select) begin
                    next_reg_a = prog_memory_out;
                end else begin
                    next_reg_b = prog_memory_out;
                end
            end

            /*
                p_write_to_mem_a : here starts the memory write operational
                pipeline. Wait state - to find the address of where we are
                writing. Increment the program counter here. This must be done 2
                clock cycles ahead so that it presents the right data when
                required.
            */
            p_write_to_mem_a: begin
                next_state      = p_write_to_mem_0;
                next_reg_select = 1'b0;
                next_pc         = curr_pc + 2;
            end

            /*
                p_write_to_mem_b : here starts the memory write operational
                pipeline. Wait state - to find the address of where we are
                writing. Increment the program counter here. This must be done 2
                clock cycles ahead so that it presents the right data when
                required.
            */
            p_write_to_mem_b: begin
                next_state      = p_write_to_mem_0;
                next_reg_select = 1'b1;
                next_pc         = curr_pc + 2;
            end

            /*
                The address will be valid during this state, so set the BUS_ADDR
                to this value, and write the value to the memory location.
            */
            p_write_to_mem_0: begin
                next_state      = p_choose_op;
                next_bus_addr   = prog_memory_out;

                if(!next_reg_select) begin
                    next_bus_data_out = curr_reg_a;
                end else begin
                    next_bus_data_out = curr_reg_b;
                end

                next_bus_data_out_we = 1'b1;
            end

            /*
                p_math_op_a : here starts the DoMaths operational pipeline. Reg
                A and Reg B must already be set to the desired values. The MSBs
                of the Operation type determines the maths operation type. At
                this stage the result is ready to be collected from the ALU.
            */
            p_math_op_a: begin
                next_state  = p_math_op_0;
                next_reg_a  = alu_out;
                next_pc     = curr_pc + 1;
            end

            /*
                p_math_op_b : here starts the DoMaths operational pipeline when
                the result will go into reg B.
            */
            p_math_op_b: begin
                next_state  = p_math_op_0;
                next_reg_b  = alu_out;
                next_pc     = curr_pc + 1;
            end

            //Wait state for new prog address to settle.
            p_math_op_0: begin
                next_state = p_choose_op;
            end

            /*
                The branch condition ALU opcodes are the same as the
                standard "math" ALU opcodes for EQ, GT and LT. Since
                choose_op sets the appropriate opcode, we only need to check
                the result.
            */
            p_branch_check: begin
                next_state = p_branch_wait;

                if (alu_out == 8'h01) begin
                    next_state = p_branch_taken;
                end else begin
                    next_pc = curr_pc + 2;
                end
            end

            /*
                We need an extra cycle in case the branch was taken, to allow the ROM output to stabilise and give us the next PC.
            */
            p_branch_taken: begin
                next_pc     = prog_memory_out;
                next_state  = p_branch_wait;
            end

            // Wait state for the new PC to settle
            p_branch_wait: begin
                next_state = p_choose_op;
            end

            // Need to wait a cycle for the address byte to appear on the bus
            p_goto_addr: begin
                next_state = p_branch_taken;
            end

            /*
                Store the PC of the next instruction and execute an
                unconditional jump.
            */
            p_funcall: begin
                next_prog_context   = curr_pc + 2;
                next_state          = p_branch_taken;
            end

            /*
                No need to wait for the address - we already have it saved!
                Set the PC to the stored context and wait for the next
                instruction to arrive.
            */
            p_return: begin
                next_pc     = curr_prog_context;
                next_state  = p_branch_wait;
            end

            p_deref_a:  begin
                next_bus_addr = curr_reg_a;
                next_reg_select = 1'b0;
                next_state = p_deref_read_from_mem_0;
            end

            p_deref_b:  begin
                next_bus_addr = curr_reg_b;
                next_reg_select = 1'b1;
                next_state = p_deref_read_from_mem_0;
            end

            p_deref_read_from_mem_0:  begin
              next_state = p_read_from_mem_1;
            end


        endcase
    end
endmodule
