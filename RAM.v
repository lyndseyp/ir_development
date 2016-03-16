`timescale 1ns / 1ps

module RAM(
    // Standard signals
    input           CLK,

    // Bus signals
    inout   [7:0]   BUS_DATA,
    input   [7:0]   BUS_ADDR,
    input           BUS_WE
);

    parameter       ram_base_addr     = 0;
    parameter       ram_addr_width    = 7; // 128 x 8-bits memory

    // Tristate
    wire    [7:0]   bus_data_buf;
    reg     [7:0]   out;
    reg             ram_bus_we;

    // Memory
    reg     [7:0]   mem [2**ram_addr_width-1:0];

    /*
        Only place data on the bus if the processor is NOT writing, and it is
        addressing this memory
    */
    assign BUS_DATA     = (ram_bus_we) ? out : 8'hZZ;
    assign bus_data_buf = BUS_DATA;

    /*
        Initialise the memory for data preloading, initialising variables,
        and declaring constants
    */
    initial $readmemh("RAM.txt", mem);

    // Single port RAM
    always@(posedge CLK) begin
        // TODO: Address validation could probably be done by BUS_ADDR[7] == 0?
        if((BUS_ADDR >= ram_base_addr) & (BUS_ADDR < ram_base_addr + 128)) begin
            if(BUS_WE) begin
                mem[BUS_ADDR[6:0]]  <= bus_data_buf;
                ram_bus_we          <= 1'b0;
            end else begin
                ram_bus_we <= 1'b1;
            end
        end else begin
            ram_bus_we <= 1'b0;
        end
        out <= mem[BUS_ADDR[6:0]];
    end
endmodule
