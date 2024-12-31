//################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//	Topic 		: UART
//	Author 		: YaWen-Yang (ichhabediearbeit@gmail.com)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//	File Name 	: bclkgen.v
//	Module Name 	: bclkgen
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//################################################################

module bclkgen
# (//parameter CLK_FREQ = 50000000, //hz
   //parameter BAUD_RATE = 9600,
   parameter scale = 16
) 
( 
  //Input signals
  input clk,
  input rstn,
  //input [1:0] baud_sel, // support 00:9600/01:19200/10:115200
  input [31:0] BAUD_RATE,
  input [31:0] CLK_FREQ,
  input bclk_en,
  //Output signals
  output reg bclk,
  output reg BR_config_error
);
//================================================================
//	integer / genvar / parameters
//================================================================
parameter BAUD_9600   = 32'd9600;
parameter BAUD_19200  = 32'd19200;
parameter BAUD_115200 = 32'd115200;

parameter BAUD_4800   = 32'd4800;
parameter BAUD_38400  = 32'd38400;
parameter BAUD_57600  = 32'd57600;
parameter BAUD_230400 = 32'd230400;
parameter BAUD_460800 = 32'd460800;
parameter BAUD_921600 = 32'd921600;

parameter ERROR_TOLERANCE = 5;  // 5% error rate
//================================================================
//	Wires & Register
//================================================================
reg [31:0] cnt, n_cnt;
reg flag;
reg n_bclk, n_BR_config_error;
wire [31:0] BAUD_CNT;
wire [31:0] actual_div, actual_baud;
wire [31:0] error_percent;
//================================================================
//	Counter
//================================================================
assign actual_div = CLK_FREQ / (BAUD_RATE * scale);
assign actual_baud = CLK_FREQ / (actual_div * scale);
assign BAUD_CNT = actual_div -'d1;
assign error_percent = (actual_baud > BAUD_RATE) ? ((actual_baud - BAUD_RATE) * 100 / BAUD_RATE) : ((BAUD_RATE - actual_baud) * 100 / BAUD_RATE);
always @(*) begin
   if (bclk_en) begin 
    case (BAUD_RATE)
	  BAUD_4800,BAUD_9600,BAUD_19200, BAUD_38400,BAUD_57600,BAUD_115200,BAUD_230400,BAUD_460800, BAUD_921600: begin
	    if ((BAUD_RATE * scale > CLK_FREQ) || (actual_div == 0) || (error_percent > ERROR_TOLERANCE)) n_BR_config_error = 1'b1;
	    else n_BR_config_error = 1'b0;
	  end
	  default : n_BR_config_error = 1'b1; 
    endcase 
   end
   else begin
    n_BR_config_error = 1'b0;
   end
end

always @(posedge clk or negedge rstn) begin
  if (!rstn) BR_config_error <= 1'b0;
  else BR_config_error <= n_BR_config_error;
end

/*
always @(*) begin
   if (BR_config_error_status) n_BR_config_error = 1'd0; 
   else begin
    case (BAUD_RATE)
	  BAUD_4800,BAUD_9600,BAUD_19200, BAUD_38400,BAUD_57600,BAUD_115200,BAUD_230400,BAUD_460800, BAUD_921600: begin
	    if ((BAUD_RATE * scale > CLK_FREQ) || (actual_div == 0) || (error_percent > ERROR_TOLERANCE)) n_BR_config_error = 1'b1;
	    else n_BR_config_error = BR_config_error;
	  end
	  default : n_BR_config_error = 1'b1; 
    endcase 
   end
end
*/

always @ (*) begin
  if (!BR_config_error && cnt < BAUD_CNT) n_cnt = cnt + 'd1;
  else n_cnt = 'd0;
end

always @ (posedge clk or negedge rstn) begin
  if (!rstn) cnt <= 'd0;
  else cnt <= n_cnt;
end

always @ (*) begin
  if (!BR_config_error && cnt == BAUD_CNT) n_bclk = ~bclk;
  else n_bclk = bclk;
end

always @ (posedge clk or negedge rstn) begin
  if (!rstn) bclk <= 'd0;
  else bclk <= n_bclk;
end

/*
always @ (posedge clk or negedge rstn) begin
  if (!rstn) cnt <= 'd0;
  else if (!BR_config_error) begin
    if (cnt < BAUD_CNT) cnt <= cnt + 'd1;
    else cnt <= 'd0;
  end
end
*/

//================================================================
//	Output
//================================================================
/*always @ (posedge clk or negedge rstn) begin
  if (!rstn) bclk <= 'd0;
  else if (!BR_config_error) begin
    if (cnt == BAUD_CNT) bclk <= ~bclk;
    else bclk <= bclk;
  end
end
*/
endmodule





