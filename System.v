`timescale 1ns / 1ps


module System(
    input           CLK,
    input           RESET,

    output          IR_OUT

    //output  [7:0]   LED
    //inout           DATA_MOUSE,
    //inout           CLK_MOUSE
);

    wire    [7:0]   bus_data;
    wire    [7:0]   bus_addr;
    wire            bus_we;

    wire    [7:0]   rom_addr;
    wire    [7:0]   rom_data;

    wire    [1:0]   bus_irqs_raise;
    wire    [1:0]   bus_irqs_ack;

    //wire    [7:0]   leds;

    //wire            data_mouse;
    //wire            clk_mouse;

    //assign LED = leds;

    Processor processor_0(
        .CLK(CLK),
        .RESET(RESET),
        .BUS_DATA(bus_data),
        .BUS_ADDR(bus_addr),
        .BUS_WE(bus_we),
        .ROM_ADDRESS(rom_addr),
        .ROM_DATA(rom_data),
        .BUS_INTERRUPTS_RAISE(bus_irqs_raise),
        .BUS_INTERRUPTS_ACK(bus_irqs_ack)
    );

    /*mouse_wrapper mouse_0(
        .RESET(RESET),
        .CLK(CLK),

        .CLK_MOUSE(CLK_MOUSE),
        .DATA_MOUSE(DATA_MOUSE),

        .BUS_ADDR(bus_addr),
        .BUS_DATA(bus_data),
        .BUS_WE(bus_we),

        .IRQ_RAISE(bus_irqs_raise[0]),
        .IRQ_ACK(bus_irqs_ack[0])
    );*/

    ROM rom_0(
        .CLK(CLK),
        .DATA(rom_data),
        .ADDR(rom_addr)
    );

    RAM ram_0(
        .CLK(CLK),
        .BUS_DATA(bus_data),
        .BUS_ADDR(bus_addr),
        .BUS_WE(bus_we)
    );

    Timer timer0(
        .CLK(CLK),
        .RESET(RESET),

        .BUS_DATA(bus_data),
        .BUS_ADDR(bus_addr),
        .BUS_WE(bus_we),

        .IRQ_RAISE(bus_irqs_raise[1]),
        .IRQ_ACK(bus_irqs_ack[1])
    );

    /*LED led_0(
        .CLK(CLK),
        .BUS_DATA(bus_data),
        .BUS_ADDR(bus_addr),
        .BUS_WE(bus_we),
        .LED_OUT(leds)
    );*/

    IR ir_0 (.CLK(CLK),
             .RESET(RESET),
             .BUS_ADDR(bus_addr),
             .BUS_DATA(bus_data),
             .BUS_WE(bus_we),
             .IR_OUT(IR_OUT)
             );


endmodule
