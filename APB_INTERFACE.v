//################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Topic   : APB Bridge
// Author   : YaWen-Yang (ichhabediearbeit@gmail.com)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// File Name  : apb.v
// Module Name  : APB_BRIDGE
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//################################################################
module APB2UART_INTERFACE (
  // Inputs From Master (APB Bridge to APB Interface)
  input PCLK,
  input PRESETn,
  input PSEL,
  input PENABLE,
  input PWRITE,
  input [31:0] PWDATA,
  input [31:0] PADDR,
  
  // Outputs From Slave (APB Interface to APB Bridge)
  output reg [31:0] PRDATA,
  output PREADY,
  output PSLVERR,
  
  // Outputs From Master (APB Interface to Register file) 
  output regif_sel,
  output regif_write,
  output regif_enable, // nead??
  output [7:0] regif_addr,
  output [31:0] regif_wdata,
  
  // Inputs From Master (Register file to APB Interface)
  input [31:0] regif_rdata
);
assign regif_enable = PENABLE;
assign regif_sel = PSEL;
assign regif_write = PWRITE;
assign regif_addr = PADDR [7:0]; //00(0000_0000) 04(0000_0100) 08(0000_1000) 0C(0000_1000) 10(0000_1100) 14(0001_0000)
assign regif_wdata = PWDATA;
assign PSLVERR = 1'b0;
assign PREADY = (PENABLE) ? 1'd1 : 1'd0;
always @(posedge PCLK or negedge PRESETn) begin
  if (!PRESETn) PRDATA <= 32'd0;
  else if (PSEL && ~PWRITE) PRDATA <= regif_rdata;
  else PRDATA <= 32'd0;
end
/*
always @(posedge PCLK or negedge PRESETn) begin
  if (!PRESETn) PREADY <= 1'd0;
  else if (PSEL && PENABLE) PREADY <= 1'd1;
  else PREADY <= 1'd0;
end
*/
/*
always @(posedge PCLK or negedge PRESETn) begin
  if (!PRESETn) PRDATA <= 32'd0;
  else if (PSEL) PRDATA <= regif_rdata;
  else PRDATA <= 32'd0;
end
*/
endmodule





