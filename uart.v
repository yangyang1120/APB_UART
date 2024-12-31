//################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//	Topic 		: UART
//	Note		: give value at first cycle, idenify value at sample cycle
//	Author 		: YaWen-Yang (ichhabediearbeit@gmail.com)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//	File Name 	: uart.v
//	Module Name 	: uart
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//################################################################
module uart (   
  input clk, rstn,

  // UART interface
  input tx,

  output rx,
  // Status
  output tx_done,
  output rx_done,
  output error, 
  output BR_config_error,
  output [7:0] dout,


  // configuration reg
  input  [31:0] BAUD_RATE_TX, BAUD_RATE_RX, CLK_FREQ,
  input [3:0] frame_size,
  input [1:0] parity_type, //00:no parity, 01:odd parity, 10:even parity
  input tx_en,
  input [7:0] din,
  input bclk_en
);
//================================================================
//	Wires & Register
//================================================================
wire rx_bclk, tx_bclk;
wire BR_config_error_tx, BR_config_error_rx;
//================================================================
//	Design
//================================================================
assign BR_config_error = BR_config_error_tx || BR_config_error_rx;

// Tx
bclkgen #(1) TX_BCLKGEN(
	.clk(clk),
	.rstn(rstn),
	.bclk(tx_bclk),
	.BAUD_RATE(BAUD_RATE_TX),
	.CLK_FREQ(CLK_FREQ),
	.BR_config_error(BR_config_error_tx),
	.bclk_en(bclk_en)
);

tx_controller TX_CONTROLLER(
	.bclk(tx_bclk),
	.rstn(rstn),
	.din(din),
	.parity_type(parity_type),
	.tx_en(tx_en),
	.tx_done(tx_done),
	.tx(tx),
	.frame_size(frame_size)
);

// Rx
bclkgen #(16) RX_BCLKGEN(
	.clk(clk),
	.rstn(rstn),
	.bclk(rx_bclk),
	.BAUD_RATE(BAUD_RATE_RX),
	.CLK_FREQ(CLK_FREQ),
	.BR_config_error(BR_config_error_rx),
	.bclk_en(bclk_en)
);

rx_controller RX_CONTROLLER(
	.bclk(rx_bclk),
	.rstn(rstn),
	.rx(rx),
	.parity_type(parity_type),
	.rx_done(rx_done),
	.dout(dout),
	.error(error),
	.frame_size(frame_size)
);






endmodule