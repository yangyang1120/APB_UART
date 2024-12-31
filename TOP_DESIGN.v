//################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Topic   : APB Bridge
// Author   : YaWen-Yang (ichhabediearbeit@gmail.com)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// File Name  : apb.v
// Module Name  : APB_BRIDGE
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//################################################################

module top (
    input clk,
    input resetn,
    input transfer,
    input write_read,
    input [31:0] addr,
    input [31:0] wdata,
    output [31:0] rdata,
    //uart tmp test
    input tx,
    output rx,
    output IRQ
//     output tx_done,
//     output rx_done,
//     output error
    //output [7:0] dout
);
//================================================================
//	Wires & Register
//================================================================
wire PCLK,PRESETn,PSEL,PENABLE,PWRITE,PREADY,PSLVERR;
wire [31:0] PADDR,PWDATA,PRDATA;
//================================================================
//	Design
//================================================================
APB_BRIDGE APB_BRIDGE (
  .clk(clk),
  .resetn(resetn),
  .transfer(transfer),
  .write_read(write_read),
  .addr(addr),
  .wdata(wdata),
  .rdata(rdata),  
  .PCLK(PCLK),
  .PRESETn(PRESETn),
  .PSEL(PSEL),
  .PENABLE(PENABLE),
  .PWRITE(PWRITE),
  .PADDR(PADDR),
  .PWDATA(PWDATA),
  .PRDATA(PRDATA),
  .PREADY(PREADY),
  .PSLVERR(PSLVERR)
);

apb_uart apb_uart1(
  .PCLK(PCLK),
  .PRESETn(PRESETn),
  .PSEL(PSEL),
  .PENABLE(PENABLE),
  .PWRITE(PWRITE),
  .PWDATA(PWDATA),
  .PADDR(PADDR),
  .PRDATA(PRDATA),
  .PREADY(PREADY),
  .PSLVERR(PSLVERR),
  // Outputs From Slave (APB I
  .tx(tx),
  .rx(rx),
  .IRQ(IRQ)
);

endmodule