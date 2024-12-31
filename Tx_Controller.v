//################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//	Topic 		: no support wls version
//	Author 		: YaWen-Yang (ichhabediearbeit@gmail.com)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//	File Name 	: uart.v
//	Module Name 	: tx_controller
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//################################################################
module tx_controller ( 
  //===================
  //input setup signals
  //===================
  input bclk, rstn,
  //===================
  // status signals
  //=================== 
  output reg tx_done,
  //===================
  // output signals
  //===================
  output reg tx,
  //===================
  // configurate reg
  //===================  
  input [3:0] frame_size,
  input tx_en,
  input [1:0] parity_type, //00:no parity, 01:odd parity, 10:even parity
  input [7:0] din   // input signals
 
);
//================================================================
//	integer / genvar / parameters
//================================================================
//FSM
parameter IDLE 	 = 3'd0;
parameter START  = 3'd1;
parameter DATA 	 = 3'd2;
parameter PARITY = 3'd3;
parameter STOP 	 = 3'd4;

// parity type
parameter no 	 = 2'd0;
parameter odd  	 = 2'd1;
parameter even 	 = 2'd2;

localparam WL5 = 4'b0101;  // 5 bits
localparam WL6 = 4'b0110;  // 6 bits
localparam WL7 = 4'b0111;  // 7 bits
localparam WL8 = 4'b1000;  // 8 bits

wire [3:0] word_bits;

//================================================================
//	Wires & Register
//================================================================
reg [2:0] c_state, n_state;
reg [2:0] bit_cnt, bit_cnt_tmp;
reg tx_tmp;
reg tx_done_tmp, n_tx_done;

//================================================================
//	FSM
//================================================================
//c_state
always @(posedge bclk or negedge rstn) begin
  if (!rstn) c_state <= IDLE;
  else c_state <= n_state;
end
//n_state
always @(*) begin
  case (c_state) 
  IDLE    : n_state = (tx_en) ? START : c_state;
  START   : n_state = DATA;
  DATA    : begin
      if (bit_cnt == word_bits - 1) n_state = (parity_type == odd || parity_type == even) ? PARITY : STOP;
      else n_state = c_state;
  end
  PARITY  : n_state = STOP;
  STOP    : n_state = IDLE;
  default : n_state = c_state;
  endcase
end
//================================================================
//	Word_bits (Default = 8 bits)
//================================================================
assign word_bits =  (frame_size == WL5) ? 4'd5 :
		    (frame_size == WL6) ? 4'd6 :
		    (frame_size == WL7) ? 4'd7 : 
		    (frame_size == WL8) ? 4'd8 : 4'd8;
//================================================================
//	Counter
//================================================================
always @(*) begin
  if (c_state == DATA) bit_cnt_tmp = bit_cnt + 3'd1;
  else bit_cnt_tmp = 3'd0;
end

always @(posedge bclk or negedge rstn) begin
  if (!rstn) bit_cnt <= 3'd0;
  else bit_cnt <= bit_cnt_tmp;
end

//================================================================
//	Output : dout
//================================================================
always @(*) begin
  if 	  (c_state == IDLE)  tx_tmp = 1'b1;
  else if (c_state == START) tx_tmp = 1'b0; 
  else if (c_state == DATA)  tx_tmp = din[bit_cnt];
  else if (c_state == PARITY) begin
    case  (parity_type) 
    odd     : tx_tmp = ~(^din);                    
    even    : tx_tmp = (^din);
    default : tx_tmp = 1'b0;
    endcase
  end
  else if (c_state == STOP)  tx_tmp = 1'b1;
  else tx_tmp = 1'd1;
end

always @(posedge bclk or negedge rstn) begin
  if (!rstn) tx <= 1'd1;
  else tx <= tx_tmp;
end

//================================================================
//	Output : tx_done
//================================================================
/*
always @(*) begin
  case (c_state) 
    IDLE : n_tx_done_tmp = 1'b0;
    STOP : n_tx_done_tmp = 1'b1;
    default : n_tx_done_tmp = tx_done_tmp;
  endcase
end

always @(posedge bclk or negedge rstn) begin
  if (!rstn) tx_done_tmp <= 1'd0;
  else tx_done_tmp <= n_tx_done_tmp;
end

assign tx_done = (tx_done_clear) ? 1'b0 : tx_done_tmp;

*/



always @(*) begin
  if (c_state == STOP) n_tx_done = 1'b1;
  else n_tx_done = 1'b0;
end

always @(posedge bclk or negedge rstn) begin
  if (!rstn) tx_done <= 1'd0;
  else tx_done <= n_tx_done;
end

endmodule