//################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//	Topic 		: UART
//	Author 		: YaWen-Yang (ichhabediearbeit@gmail.com)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//	File Name 	: intrif.v
//	Module Name 	: intrif
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//################################################################



module intrif (
  input clk,
  input rstn,
  input [31:0] status,
  input [31:0] enable,
  output IRQ
);

//================================================================
//	Output
//================================================================
reg IRQ_tmp;
assign IRQ = IRQ_tmp;
always @ (posedge clk or negedge rstn) begin
  if (!rstn) IRQ_tmp <= 'd0;
  else IRQ_tmp <= |(status & enable);
end


endmodule