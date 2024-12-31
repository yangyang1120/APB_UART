//################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Topic   : APB Bridge
// Author   : YaWen-Yang (ichhabediearbeit@gmail.com)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// File Name  : apb.v
// Module Name  : APB_BRIDGE
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//################################################################

module apb_uart (
    input PCLK,
    input PRESETn,
    input PSEL,
    input PENABLE,PWRITE,PREADY,PSLVERR,
    input [31:0] PADDR,PWDATA,PRDATA,
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
//wire PCLK,PRESETn,PSEL,PENABLE,PWRITE,PREADY,PSLVERR;
//wire [31:0] PADDR,PWDATA,PRDATA;
wire regif_sel, regif_write, regif_enable, bclk_en;
wire [7:0] regif_addr;
wire [31:0] regif_wdata;
wire [31:0] regif_rdata;
wire [31:0] baud_rate_tx,baud_rate_rx, frame_size, parity_type, tx_enable, tx_data, enable_reg, status_reg, clk_freq;
wire [7:0] rx_dout;
wire tx_done,rx_done,error,BR_config_error;
//================================================================
//	Design
//================================================================
APB2UART_INTERFACE APB2UART_INTERFACE(
  .PCLK(PCLK),
  .PRESETn(PRESETn),
  .PSEL(PSEL),
  .PENABLE(PENABLE),
  .PWRITE(PWRITE),
  .PWDATA(PWDATA),
  .PADDR(PADDR),

  // Outputs From Slave (APB I
  .PRDATA(PRDATA),
  .PREADY(PREADY),
  .PSLVERR(PSLVERR),

  // Outputs From Master (APB 
  .regif_sel(regif_sel),
  .regif_write(regif_write),
  .regif_enable(regif_enable), // nead?
  .regif_addr(regif_addr),
  .regif_wdata(regif_wdata),

  // Inputs From Master (Regis
  .regif_rdata(regif_rdata)
);


REG_INTERFACE REG_INTERFACE(
  .PCLK(PCLK),
  .PRESETn(PRESETn),
  // Inputs From Master (APB Inte
  .regif_sel(regif_sel),
  .regif_write(regif_write),
  .regif_addr(regif_addr),
  .regif_wdata(regif_wdata),
  .regif_enable(regif_enable),
  .dout (rx_dout),
  .tx_done(tx_done),
  .rx_done(rx_done),
  .error(error),
  .BR_config_error(BR_config_error),
  // Outputs From Slave (REG Inte
  .regif_rdata(regif_rdata),
  .baud_rate_tx(baud_rate_tx),
  .baud_rate_rx(baud_rate_rx),
  .frame_size(frame_size),
  .parity_type(parity_type),
  .uart_enable(tx_enable),
  .transfer_data(tx_data),
  .enable_reg(enable_reg),
  .status_reg(status_reg),
  .clk_freq_reg(clk_freq),
  .bclk_en(bclk_en)
);

uart uart(
  .clk(PCLK), 
  .rstn(PRESETn),
  
  // UART interface
  .tx(tx),
  .rx(rx),
  
  // Status
  .tx_done(tx_done),
  .rx_done(rx_done),
  .error(error),
  .BR_config_error(BR_config_error),
  .dout(rx_dout),
  
  // configuration reg
  .BAUD_RATE_TX(baud_rate_tx),
  .BAUD_RATE_RX(baud_rate_rx),
  .CLK_FREQ(clk_freq),
  .frame_size(frame_size),
  .parity_type(parity_type[1:0]), 
  .tx_en(tx_enable[0]),
  .din(tx_data[7:0]),
  .bclk_en(bclk_en)
);

intrif intrif(
  .clk(PCLK),
  .rstn(PRESETn),
  .status(status_reg),
  .enable(enable_reg),
  .IRQ(IRQ)
);

endmodule