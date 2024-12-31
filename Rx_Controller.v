//####################################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//	Topic 		: no support wls/SYNC version
//	Note		: give value at first cycle, idenify value at sample cycle
//	Author 		: YaWen-Yang (ichhabediearbeit@gmail.com)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//	File Name 	: Rx.v
//	Module Name 	: rx_controller
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//####################################################################################
module rx_controller (   
  //===================
  // input signals
  //===================
  input rx, // 1 start, 8 din, 1 parity_value, 1 stop = 10 times data in
  //===================
  //input setup signals
  //===================
  input bclk, rstn,
  //===================
  // status signals
  //=================== 
  output reg rx_done,
  output reg error,
  //===================
  // output signals
  //===================
  output reg [7:0] dout,
  //===================
  // configurate reg
  //===================  
  input [3:0] frame_size,
  input [1:0] parity_type //00:no parity, 01:odd parity, 10:even parity, default = no parity


);
//================================================================
//	integer / genvar / parameters
//================================================================
//FSM
parameter IDLE  = 3'd0;
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
//================================================================
//	Wires & Register
//================================================================
reg [2:0] c_state, n_state;
reg [2:0] bit_cnt, n_bit_cnt;
reg [3:0] clk_cnt, n_clk_cnt;
reg [1:0] rx_sync, n_rx_sync;
reg [7:0] rx_s2p, n_rx_s2p;
reg [4:0] sample, n_sample;
reg rx_parity, tx_parity, n_rx_parity, n_tx_parity;
reg n_error, n_rx_done;
reg rx_done_tmp, error_tmp;
wire rx_falling;
reg check_flag;
wire sample_pt;
wire [3:0] word_bits;

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
  IDLE    : n_state = (rx_falling) ? START : c_state;
  START   : n_state = (clk_cnt == 4'd13) ? DATA : c_state;
  DATA    : begin
    if (clk_cnt == 4'd15 && bit_cnt == (word_bits - 1)) n_state = (parity_type == odd || parity_type == even) ? PARITY : STOP;
    else n_state = c_state;
  end
  PARITY  : n_state = (clk_cnt == 4'd15) ? STOP : c_state;
  STOP    : n_state = (clk_cnt == 4'd15) ? IDLE : c_state;
  default : n_state = c_state;
  endcase
end
//================================================================
//	Word bits 
//================================================================
assign word_bits =  (frame_size == WL5) ? 4'd5 :
		    (frame_size == WL6) ? 4'd6 :
		    (frame_size == WL7) ? 4'd7 : 
		    (frame_size == WL8) ? 4'd8 : 4'd8;
//================================================================
//	Bits Counter
//================================================================
always @(posedge bclk or negedge rstn) begin
  if (!rstn) bit_cnt <= 3'd0;
  else bit_cnt <= n_bit_cnt;
end

always @(*) begin
  if (c_state == DATA && clk_cnt == 4'd15) n_bit_cnt = bit_cnt + 3'd1; // final = 8 bits
  else if (c_state == IDLE) n_bit_cnt = 3'd0;
  else n_bit_cnt = bit_cnt;
end


//================================================================
//	Clock Cycle Counter
//================================================================
always @(posedge bclk or negedge rstn) begin
  if (!rstn) clk_cnt <= 4'd0;
  else clk_cnt <= n_clk_cnt;
end

always @(*) begin
  if (rx_falling || (c_state == START && clk_cnt == 4'd13)) n_clk_cnt = 4'd0;
  else if (clk_cnt < 4'd15) n_clk_cnt = clk_cnt + 4'd1;
  else n_clk_cnt = 4'd0;
end


//================================================================
//  rx_sync &  rx_falling for detecting the negedge start bits
//================================================================
always @(posedge bclk or negedge rstn) begin
  if (!rstn) rx_sync <= 2'b11;
  else rx_sync <= n_rx_sync;
end

always @(*) begin
  if (c_state == IDLE) n_rx_sync = {rx_sync[0], rx};
  else n_rx_sync = 2'b11;
end

assign rx_falling = ((c_state == IDLE) && (rx_sync[1] && ~rx_sync[0]));

//================================================================
//	Sample rx value
//================================================================
always @(posedge bclk or negedge rstn) begin
  if (!rstn) rx_s2p <= 'd0;
  else rx_s2p <= n_rx_s2p;
end

always @(*) begin
  if (check_flag) begin
    case (word_bits) 
      WL5 : n_rx_s2p = {1'b0, 1'b0 , 1'b0 ,rx, rx_s2p[4:1]};
      WL6 : n_rx_s2p = {1'b0, 1'b0 ,rx, rx_s2p[5:1]};
      WL7 : n_rx_s2p = {1'b0 ,rx, rx_s2p[6:1]};
      WL8 : n_rx_s2p = {rx, rx_s2p[7:1]};
      default: n_rx_s2p = {rx, rx_s2p[7:1]};
    endcase
  end
  else n_rx_s2p = rx_s2p;
end


always @(posedge bclk or negedge rstn) begin
  if (!rstn) sample <= 5'd0;
  else sample <= n_sample;
end

always @(*) begin
  if (c_state == DATA) begin
    case (clk_cnt) 
      4'd3 : begin
	n_sample[4] = rx;
	n_sample[3] = 1'b0;
	n_sample[2] = 1'b0;     
	n_sample[1] = 1'b0;
	n_sample[0] = 1'b0;
      end
      4'd7 : begin
	n_sample[4] = sample[4];
	n_sample[3] = rx;
	n_sample[2] = 1'b0;     
	n_sample[1] = 1'b0;
	n_sample[0] = 1'b0;
      end 
      4'd8 : begin
	n_sample[4] = sample[4];
	n_sample[3] = sample[3];
	n_sample[2] = rx;     
	n_sample[1] = 1'b0;
	n_sample[0] = 1'b0;
      end 
      4'd9 : begin
	n_sample[4] = sample[4];
	n_sample[3] = sample[3];
	n_sample[2] = sample[2];     
	n_sample[1] = rx;
	n_sample[0] = 1'b0;
      end 
      4'd12 : begin
	n_sample[4] = sample[4];
	n_sample[3] = sample[3];
	n_sample[2] = sample[2];     
	n_sample[1] = sample[1];
	n_sample[0] = rx;
      end 
      default : begin
	n_sample = sample;
      end  
    endcase
  end
  else n_sample = 5'b0;
end

always @(*) begin
   if (c_state == DATA && clk_cnt == 4'd13) check_flag = (sample[0] == sample[1] && 
							  sample[1] == sample[2] && 
							  sample[2] == sample[3] && 
							  sample[3] == sample[4] && 
							  sample[4] == sample[0]);
   else check_flag = 1'b0;
end

//================================================================
//	Output : dout
//================================================================
always @(posedge bclk or negedge rstn) begin
  if (!rstn) dout <= 'd0;
  else if (c_state == STOP) dout <= rx_s2p;
  else dout <= 'd0;
end

//================================================================
//	Output : parity_value
//================================================================
always @(posedge bclk or negedge rstn) begin
  if (!rstn) rx_parity <= 1'd0;
  else rx_parity <= n_rx_parity;
end


always @(*) begin
  if (c_state == PARITY) begin
    case (parity_type) 
    odd     : n_rx_parity = ~(^rx_s2p);                    
    even  : n_rx_parity = (^rx_s2p);
    default : n_rx_parity = 1'd0;
    endcase
  end
  else n_rx_parity = 1'd0;
end


always @(posedge bclk or negedge rstn) begin
  if (!rstn) tx_parity <= 1'd0;
  else tx_parity <= n_tx_parity;
end

always @(*) begin
  case (c_state)
    IDLE    : n_tx_parity = 1'd0;
    PARITY  : n_tx_parity = rx;
    default : n_tx_parity = tx_parity;
  endcase
end
//================================================================
//	Output : error
//================================================================
always @(posedge bclk or negedge rstn) begin
  if (!rstn) error <= 1'd0; 
  else error <= n_error;
end

always @(*) begin
  if (clk_cnt > 1) n_error = (error || (c_state == PARITY && rx_parity != tx_parity) 
				    || (c_state == STOP && rx != 1'd1) 
				    || (c_state == START && rx != 1'd0) 
				    || (c_state == DATA && clk_cnt == 4'd13 && check_flag != 1'd1));
  else n_error = 1'd0;
end
/*
assign error = (error_clear) ? 1'b0 : error_tmp;

always @(posedge bclk or negedge rstn) begin
  if (!rstn) error_tmp <= 1'd0; 
  else error_tmp <= n_error_tmp;
end

always @(*) begin
  if (error_tmp || (c_state == PARITY && rx_parity != tx_parity) || (c_state == STOP && rx == 1'd0) || (c_state == START && rx == 1'd1)) n_error_tmp = 1'd1;
  else if (c_state == IDLE) n_error_tmp = 1'd0;
  else n_error_tmp = error_tmp;
end
*/
// always @(posedge bclk or negedge rstn) begin
//   if (!rstn) baud_rate_error <= 1'd0; 
//   else if (sample_pt) baud_rate_error <= (baud_rate_error || );
//   else if (baud_rate_error_clear) baud_rate_error <= 1'd0;
//   else baud_rate_error <= baud_rate_error;1
// end

//================================================================
//	Output : tx_done
//================================================================
always @(posedge bclk or negedge rstn) begin
  if (!rstn) rx_done <= 1'd0;
  else rx_done <= n_rx_done;
end

always @(*) begin
  if (c_state == STOP && clk_cnt == 4'd15) n_rx_done = rx; // check at stop rx == 1
  else n_rx_done = 1'd0;
end

/*
always @(posedge bclk or negedge rstn) begin
  if (!rstn) rx_done_tmp <= 1'b0;
  else rx_done_tmp <= n_rx_done_tmp;
end

always @(*) begin
  case (c_state) 
    IDLE : n_rx_done_tmp = 1'b0;
    STOP : n_rx_done_tmp = (clk_cnt == 4'd15) ? 1'b1 : rx_done_tmp;
    default : n_rx_done_tmp = rx_done_tmp;
  endcase
end

assign rx_done = (rx_done_clear) ? 1'b0 : rx_done_tmp;
*/

endmodule