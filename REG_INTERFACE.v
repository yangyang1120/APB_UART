//################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Topic   : APB Bridge
// Author   : YaWen-Yang (ichhabediearbeit@gmail.com)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// File Name  : apb.v
// Module Name  : APB_BRIDGE
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//################################################################
module REG_INTERFACE (
  // Inputs From Master (APB Bridge to REG Interface)
  input PCLK,
  input PRESETn,
  // Inputs From Master (APB Interface to REG Interface)
  input regif_sel,
  input regif_write,
  input [7:0] regif_addr,
  input [31:0] regif_wdata,
  input regif_enable,
  // Inputs From Slave (UART to REG Interface)
  input [7:0] dout,
  input tx_done, rx_done, error, BR_config_error, //status reg
  
  // Outputs From Slave (REG Interface to APB Interface)
  output reg [31:0] regif_rdata,
  
  // Config REG (REG Interface to UART)
  output [31:0] baud_rate_tx,baud_rate_rx,
  output [31:0] frame_size, 
  output [31:0] parity_type, 
  output [31:0] uart_enable, 
  output [31:0] transfer_data,
  // Interrupt REG (REG Interface to UART & Interrupt)
  output [31:0] enable_reg, 
  output [31:0] status_reg, 
  output [31:0] status_clear_reg,
  output [31:0] clk_freq_reg,
  output bclk_en
);
integer i;
reg [7:0] sp_mem [0:31];
reg [1:0] tx_done_ff;
reg [1:0] rx_done_ff;
reg BR_config_error_ff;
reg [1:0] error_ff;
reg bclk_en;
parameter BAUD_RATE_TX_ADDR     = 8'h00;
parameter FRAME_SIZE_ADDR    	= 8'h04;
parameter PARITY_TYPE_ADDR   	= 8'h08;
parameter UART_ENABLE_ADDR   	= 8'h0C;
parameter BAUD_RATE_RX_ADDR     = 8'h10;
parameter ENABLE_REG_ADDR    	= 8'h14;
parameter TRANSFER_DATA_ADDR 	= 8'h18;
parameter CLK_FREQ_REG_ADDR  	= 8'h1C;
parameter STATUS_REG_ADDR     	= 8'h20;
parameter RECEIVE_DATA_ADDR    	= 8'h24;

//assign BR_error = BR_config_error_ff[0] & ~BR_config_error_ff[1];
assign baud_rate_tx	= {sp_mem[3],sp_mem[2],sp_mem[1],sp_mem[0]}; //00
assign frame_size 	= {sp_mem[7],sp_mem[6],sp_mem[5],sp_mem[4]}; //04
assign parity_type 	= {sp_mem[11],sp_mem[10],sp_mem[9],sp_mem[8]}; //08
assign uart_enable 	= (tx_done) ? 8'd0 : {sp_mem[15],sp_mem[14],sp_mem[13],sp_mem[12]}; //0C
assign baud_rate_rx 	= {sp_mem[19],sp_mem[18],sp_mem[17],sp_mem[16]}; //10 //{29'b0, tx_done_clear, rx_done_clear,error_clear}
assign enable_reg 	= {sp_mem[23],sp_mem[22],sp_mem[21],sp_mem[20]}; //14 //{29'b0, tx_done_en, rx_done_en,error_en}
assign transfer_data 	= {sp_mem[27],sp_mem[26],sp_mem[25],sp_mem[24]}; //18
assign clk_freq_reg 	= {sp_mem[31],sp_mem[30],sp_mem[29],sp_mem[28]};//1C
assign status_reg = {28'b0, BR_config_error_ff, tx_done_ff[1], rx_done_ff[1], error_ff[1]}; //20
//assign status_reg 	= {sync_ff2[3],sync_ff2[2],sync_ff2[1],sync_ff2[0]}; //24
//assign status_reg 	= {sp_mem[39],sp_mem[38],sp_mem[37],sp_mem[36]}; //24

//cpu write
wire reg00_write = {regif_sel && regif_write && (regif_addr == BAUD_RATE_TX_ADDR)}; 
wire reg04_write = {regif_sel && regif_write && (regif_addr == FRAME_SIZE_ADDR)};
wire reg08_write = {regif_sel && regif_write && (regif_addr == PARITY_TYPE_ADDR)};
wire reg0C_write = {regif_sel && regif_write && (regif_addr == UART_ENABLE_ADDR) && !BR_config_error};
wire reg10_write = {regif_sel && regif_write && (regif_addr == BAUD_RATE_RX_ADDR)};
wire reg14_write = {regif_sel && regif_write && (regif_addr == ENABLE_REG_ADDR)};
wire reg18_write = {regif_sel && regif_write && (regif_addr == TRANSFER_DATA_ADDR)};
wire reg1C_write = {regif_sel && regif_write && (regif_addr == CLK_FREQ_REG_ADDR)};
wire reg20_write = {regif_sel && regif_write && (regif_addr == STATUS_REG_ADDR)};

//assign bclk_en = reg14_write;
always @(posedge PCLK or negedge PRESETn) begin
  if (!PRESETn) BR_config_error_ff <= 1'b0;
    else if (BR_config_error) BR_config_error_ff <= BR_config_error;

  else  if (reg20_write && regif_wdata[3]) begin
    BR_config_error_ff <= 1'b0;
  end
end

always @(posedge PCLK or negedge PRESETn) begin
  if (!PRESETn) bclk_en <= 1'b0;
  else if (reg10_write) bclk_en <= reg10_write;
  else  begin
    bclk_en <= 1'b0;
  end
end



always @(posedge PCLK or negedge PRESETn) begin
  if (!PRESETn) begin
    tx_done_ff <= 2'b00;
  end
  else if (tx_done) begin
    tx_done_ff[0] <= tx_done;
    tx_done_ff[1] <= tx_done_ff[0];
  end
  else if (reg20_write && regif_wdata[2]) begin
    tx_done_ff <= 2'b00;
  end
end

always @(posedge PCLK or negedge PRESETn) begin
  if (!PRESETn) begin
    rx_done_ff <= 2'b00;
  end
  else if (rx_done) begin
    rx_done_ff[0] <= rx_done;
    rx_done_ff[1] <= rx_done_ff[0];
  end
  else if (reg20_write && regif_wdata[1]) begin
    rx_done_ff <= 2'b00;
  end
end


always @(posedge PCLK or negedge PRESETn) begin
  if (!PRESETn) begin
    error_ff <= 2'b00;
  end
  else if (error) begin
    error_ff[0] <= error;
    error_ff[1] <= error_ff[0];
  end
  else if (reg20_write && regif_wdata[0]) begin
    error_ff <= 2'b00;
  end
end




always @(posedge PCLK or negedge PRESETn) begin
  if (!PRESETn) begin
    for (i = 0; i < 24; i=i+1) begin
      sp_mem[i] <= 8'd0;
    end
  end
  else begin
    if (reg00_write) begin
      sp_mem[8'h00+3] <= regif_wdata[31:24];
      sp_mem[8'h00+2] <= regif_wdata[23:16];
      sp_mem[8'h00+1] <= regif_wdata[15:8];
      sp_mem[8'h00+0] <= regif_wdata[7:0];
    end
    else if (reg04_write) begin
      sp_mem[8'h04+3] <= regif_wdata[31:24];
      sp_mem[8'h04+2] <= regif_wdata[23:16];
      sp_mem[8'h04+1] <= regif_wdata[15:8];
      sp_mem[8'h04+0] <= regif_wdata[7:0];
    end
    else if (reg08_write) begin
      sp_mem[8'h08+3] <= regif_wdata[31:24];
      sp_mem[8'h08+2] <= regif_wdata[23:16];
      sp_mem[8'h08+1] <= regif_wdata[15:8];
      sp_mem[8'h08+0] <= regif_wdata[7:0];
    end
    else if (reg0C_write) begin
      sp_mem[8'h0C+3] <= regif_wdata[31:24];
      sp_mem[8'h0C+2] <= regif_wdata[23:16];
      sp_mem[8'h0C+1] <= regif_wdata[15:8];
      sp_mem[8'h0C+0] <= regif_wdata[7:0];      
    end
    else if (reg10_write) begin
      sp_mem[8'h10+3] <= regif_wdata[31:24];
      sp_mem[8'h10+2] <= regif_wdata[23:16];
      sp_mem[8'h10+1] <= regif_wdata[15:8];
      sp_mem[8'h10+0] <= regif_wdata[7:0];
    end
    else if (reg14_write) begin
      sp_mem[8'h14+3] <= regif_wdata[31:24];
      sp_mem[8'h14+2] <= regif_wdata[23:16];
      sp_mem[8'h14+1] <= regif_wdata[15:8];
      sp_mem[8'h14+0] <= regif_wdata[7:0];
    end
    else if (reg18_write) begin
      sp_mem[8'h18+3] <= regif_wdata[31:24];
      sp_mem[8'h18+2] <= regif_wdata[23:16];
      sp_mem[8'h18+1] <= regif_wdata[15:8];
      sp_mem[8'h18+0] <= regif_wdata[7:0];
    end
    else if (reg1C_write) begin
      sp_mem[8'h1C+3] <= regif_wdata[31:24];
      sp_mem[8'h1C+2] <= regif_wdata[23:16];
      sp_mem[8'h1C+1] <= regif_wdata[15:8];
      sp_mem[8'h1C+0] <= regif_wdata[7:0];
    end
  end
end
/*
always @(posedge PCLK or negedge PRESETn) begin
  if (!PRESETn) begin
    for (i = 0; i < 24; i=i+1) begin
      sp_mem[i] <= 8'd0;
    end
  end
  else begin
    if (tx_done) begin
      sp_mem[8'h0C+3] <= 8'b0;
      sp_mem[8'h0C+2] <= 8'b0;
      sp_mem[8'h0C+1] <= 8'b0;
      sp_mem[8'h0C+0] <= 8'b0;  
    end
    else if (reg0C_write) begin
      sp_mem[8'h0C+3] <= regif_wdata[31:24];
      sp_mem[8'h0C+2] <= regif_wdata[23:16];
      sp_mem[8'h0C+1] <= regif_wdata[15:8];
      sp_mem[8'h0C+0] <= regif_wdata[7:0];      
    end
    end
end
*/
always @(*) begin
  case (regif_addr) 
    BAUD_RATE_TX_ADDR: regif_rdata = baud_rate_tx;
    FRAME_SIZE_ADDR: regif_rdata = frame_size;
    PARITY_TYPE_ADDR: regif_rdata = parity_type;
    UART_ENABLE_ADDR: regif_rdata = uart_enable;
    ENABLE_REG_ADDR: regif_rdata = enable_reg;
    TRANSFER_DATA_ADDR: regif_rdata = transfer_data;
    CLK_FREQ_REG_ADDR : regif_rdata = clk_freq_reg;
    BAUD_RATE_RX_ADDR : regif_rdata = baud_rate_rx;
    STATUS_REG_ADDR: regif_rdata = status_reg;
    RECEIVE_DATA_ADDR: regif_rdata = {24'b0, dout};
    default: regif_rdata = 32'h0;
  endcase
end

endmodule