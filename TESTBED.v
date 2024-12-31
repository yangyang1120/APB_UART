//################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//	Topic 		: UART
//	Author 		: YaWen-Yang (ichhabediearbeit@gmail.com)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//	File Name 	: TESTBED_UART.v
//	Module Name 	: TESTBED
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//################################################################

`timescale 1ns/1ps
`include "../00_TESTBED/PATTERN_v2.v"

`ifdef RTL
`include "../01_RTL/apb_top.v"
`include "../01_RTL/APB/apb.v"
`include "../01_RTL/APB/apbif.v"
`include "../01_RTL/APB/regif.v"
`include "../01_RTL/UART/uart.v"
`include "../01_RTL/UART/bclkgen.v"
`include "../01_RTL/UART/Tx.v"
`include "../01_RTL/UART/Rx.v"
`include "../01_RTL/UART/intrif.v"
`include "../01_RTL/apb_uart.v"
`endif

module TESTBED();

//Connection wires
wire	clk,resetn,transfer,write_read;
wire    [31:0] addr, wdata, rdata;
wire 	IRQ;
wire 	interconnect_tx2rx;

initial begin
  `ifdef RTL
    $fsdbDumpfile("top_v1.fsdb");
    $fsdbDumpvars(0,TESTBED,"+mda");
  `endif
end

top tx_uart (
    .clk(clk),
    .resetn(resetn),
    .transfer(transfer),
    .write_read(write_read),
    .addr(addr),
    .wdata(wdata),
    .rdata(rdata),
    .tx(interconnect_tx2rx),
    .rx(interconnect_tx2rx),
    .IRQ(IRQ)
);

PATTERN PATTERN (
    .clk(clk),
    .resetn(resetn),
    .transfer(transfer),
    .write_read(write_read),
    .addr(addr),
    .wdata(wdata),
    .rdata(rdata),
    .IRQ(IRQ)
);

endmodule