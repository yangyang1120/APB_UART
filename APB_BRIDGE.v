//################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Topic   : APB Bridge
// Author   : YaWen-Yang (ichhabediearbeit@gmail.com)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// File Name  : apb.v
// Module Name  : APB_BRIDGE
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//################################################################
module APB_BRIDGE (
  // Inputs From Master (CPU [Dummy signals] to APB Bridge)
  input clk,
  input resetn,
  input transfer,
  input write_read,
  input [31:0] addr,
  input [31:0] wdata,
  
  // Outputs From Slave (APB Bridge to CPU [Dummy signals])
  output [31:0] rdata,
  
  // Outputs From Slave (APB Bridge to UART [APB Interface]) 
  output PCLK,
  output PRESETn,
  output reg PSEL,
  output reg PENABLE,
  output reg PWRITE,
  output reg [31:0] PADDR,
  output reg [31:0] PWDATA,
  
  // Inputs From Slave (UART [APB Interface] to APB Bridge)
  input [31:0] PRDATA,
  input PREADY,
  input PSLVERR
);

//================================================================
// integer / genvar / parameters
//================================================================
//FSM
parameter IDLE   = 2'b00;
parameter SETUP  = 2'b01;
parameter ACCESS = 2'b10;

//================================================================
// Wires & Register
//================================================================
reg [1:0] c_state, n_state;

//================================================================
// FSM
//================================================================
//c_state
always @(posedge clk or negedge resetn) begin
  if (!resetn) c_state <= IDLE;
  else c_state <= n_state;
end

//n_state
always @(*) begin
  case (c_state) 
  IDLE    : n_state = (transfer) ? SETUP : c_state;
  SETUP   : n_state = ACCESS;
  ACCESS  : begin
    if (PREADY == 1'b1) n_state = (transfer) ? SETUP : IDLE;
    else n_state = c_state;
  end
  default : n_state = IDLE;
  endcase
end
//================================================================
// Design : Write transfers 
//================================================================
assign PCLK = clk;
assign PRESETn = resetn;


//================================================================
// Output : PSEL
//================================================================
always @(posedge clk or negedge resetn) begin
    if (!resetn) PSEL <= 1'd0;
    else if (transfer) PSEL <= 1'd1;
    else if (c_state == SETUP) PSEL <= PSEL;
    else if (c_state == ACCESS) PSEL <= (PREADY) ? 1'd0 : PSEL; 
    else PSEL <= 1'd0;
end

//================================================================
// Output : PENABLE
//================================================================
always @(posedge clk or negedge resetn) begin
    if (!resetn) PENABLE <= 1'd0;
    else if (c_state == IDLE) PENABLE <= 1'd0;
    else if (c_state == SETUP) PENABLE <= 1'd1;
    else if (c_state == ACCESS) PENABLE <= (PREADY) ? 1'd0 : PENABLE;
    else PENABLE <= 1'd0;
end

//================================================================
// Output : PWRITE
//================================================================
always @(posedge clk or negedge resetn) begin
    if (!resetn) PWRITE <= 1'd0;
    else if (n_state == SETUP) PWRITE <= write_read; //1:write癒A0:read
    else PWRITE <= PWRITE;
end

//================================================================
// Output : PADDR
//================================================================
always @(posedge clk or negedge resetn) begin
    if (!resetn) PADDR <= 1'd0;
    else if (n_state == SETUP) PADDR <= addr;
    else PADDR <= PADDR;
end

//================================================================
// Output : PWDATA
//================================================================
always @(posedge clk or negedge resetn) begin
    if (!resetn) PWDATA <= 1'd0;
    else if (n_state == SETUP) PWDATA <= wdata;
    else PWDATA <= PWDATA;
end
//================================================================
// Design : Read transfers 
//================================================================

//================================================================
// Output : rdata
//================================================================
/*always @(posedge clk or negedge resetn) begin
    if (!resetn) rdata <= 1'd0;
    else if (c_state == ACCESS) rdata <= (~PWRITE && PREADY) ? PRDATA : 1'd0;
    else rdata <=  1'd0;
end*/
assign rdata = (c_state == ACCESS && ~PWRITE && PREADY) ? PRDATA : 32'd0;
endmodule