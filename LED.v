`timescale 1ns / 1ps

module LED(
    // Standard signals
    input           CLK,

    // Bus signals
    inout   [7:0]   BUS_DATA,
    input   [7:0]   BUS_ADDR,
    input           BUS_WE,

    // LED outputs
    output  [7:0]   LED_OUT
);

    parameter       base_addr = 8'hC0;

    reg     [7:0]   led_mem;
    wire            bus_active;

    assign bus_active   = (BUS_ADDR >= base_addr) & (BUS_ADDR < base_addr + 1);
    assign LED_OUT      = led_mem;

    always@(posedge CLK) begin
        if(bus_active & BUS_WE) begin
            led_mem <= BUS_DATA;
        end
    end

endmodule
