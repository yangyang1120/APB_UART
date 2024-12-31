//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//	Topic 		: UART
//	Author 		: YaWen-Yang (ichhabediearbeit@gmail.com)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : PATTERN_UART.v
//   Module Name : PATTERN
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`ifdef RTL
`define CYCLE_TIME 10000.0
`endif

module PATTERN(
output reg clk,
output reg resetn,
output reg transfer,
output reg write_read,
output reg [31:0] addr,
output reg [31:0] wdata,
input [31:0] rdata,
input IRQ
);
//================================================================
//  integer / parameter
//================================================================
integer test_idx, frame_idx,parity_idx,error_idx;

//================================================================
//  wire & output registers 
//================================================================
reg [31:0] test_case_num;
// Test configuration arrays
reg [31:0] baud_rates [0:8];      // Normal
reg [31:0] frame_sizes [0:3];     // 5,6,7,8 bits
reg [1:0]  parity_types [0:2];    // None, Odd, Even
reg [31:0] test_patterns [0:7];   

// Error test configurations
reg [31:0] error_baud_rates [0:3];    
reg [31:0] error_frame_sizes [0:1];   
reg [1:0]  error_parity_types [0:1];  
reg [31:0] error_frequencies [0:1];   

//================================================================
//  clock
//================================================================
always  #(`CYCLE_TIME/2.0)  clk = ~clk ;
initial clk = 0 ;
//================================================================
//  initial
//================================================================
initial begin
    //baud_rates[0] = 4800;  
    baud_rates[0] = 9600;    
    baud_rates[1] = 19200;
    //baud_rates[3] = 38400;
    //baud_rates[4] = 57600;
    baud_rates[2] = 115200;
    //baud_rates[6] = 230400;
    //baud_rates[7] = 460800;
    //baud_rates[7] = 921600;
    
    frame_sizes[0] = 5;
    frame_sizes[1] = 6;
    frame_sizes[2] = 7;
    frame_sizes[3] = 8;
    
    parity_types[0] = 2'b00; // None 
    parity_types[1] = 2'b01; // Odd
    parity_types[2] = 2'b10; // Even
    
    test_patterns[0] = 32'b00111;  // 5-bit patterns (0-31)    
    test_patterns[1] = 32'b101010;  // 6-bit patterns (0-63)   
    test_patterns[2] = 32'b1010101;  // 7-bit patterns (0-127)  
    test_patterns[3] = 32'b11110000; // 8-bit patterns (0-255)
    
    // initial error test 
    error_baud_rates[0] = 1234;      // Invalid baud rate
    error_baud_rates[1] = 100;       // smaller baud rate
    error_baud_rates[2] = 1000000;   // bigger baud rate
    error_baud_rates[3] = 12345;     // non-standard baud rate
    
    error_frame_sizes[0] = 4;        // smaller frame size
    error_frame_sizes[1] = 9;        // bigger frame size
    ///test 4 9 8 time 
    
    error_parity_types[0] = 2'b11;   // Invalid parity
    
    // baud rate = 9600, downsample = 16
    // min frequency = 9600 * 16 = 153600 Hz
    error_frequencies[0] = 100000;    // smaller frequency
    error_frequencies[1] = 200000000; // bigger frequency
    
  // reset output signals
  resetn = 1;
  transfer = 0;
  write_read = 0;
  addr = 0;
  wdata = 0;
  // reset 
  force clk = 0 ;
  reset_task;
  test_case_num = 1;
  @(negedge clk);
  
  $display("============================================");
  $display("\n=== Starting All Configuration Tests ===\n");
  $display("============================================");
  for(frame_idx = 0; frame_idx < 4; frame_idx = frame_idx + 1) begin
    for(test_idx = 0; test_idx < 3; test_idx = test_idx + 1) begin
      for(parity_idx = 0; parity_idx < 3; parity_idx = parity_idx + 1)begin 
      test_uart_config( 
	50000000,
	baud_rates[test_idx],
	baud_rates[test_idx],
	frame_sizes[frame_idx],
	parity_types[parity_idx],
	test_patterns[frame_idx],
	test_case_num
      );
      test_case_num = test_case_num + 1;
      @(negedge clk);
      end
    end
  end
 
	//100000,
	//9600,
	//4800,
	//frame_sizes[0],
	//parity_types[0],
	//test_patterns[0],
  
  $display("============================================");
  $display("\n==== Starting Error Condition Tests ====\n");
  $display("\n======== Invalid baud rate test ========\n");
  $display("============================================");
  
  for(error_idx = 0; error_idx < 4; error_idx = error_idx + 1) begin
    test_uart_config(
    	50000000,                    // f
	error_baud_rates[error_idx], // TX baud
	error_baud_rates[error_idx], // RX baud
	frame_sizes[3],              // 8-bit
	parity_types[1],             // No parity
	test_patterns[3],            // 8-bit pattern
	test_case_num
    );
    test_case_num = test_case_num + 1;
    @(negedge clk);
  end
  
  $display("============================================");
  $display("\n=== Starting All Configuration Tests ===\n");
  $display("============================================");
  for(frame_idx = 0; frame_idx < 1; frame_idx = frame_idx + 1) begin
    for(test_idx = 0; test_idx < 2; test_idx = test_idx + 1) begin
      for(parity_idx = 0; parity_idx < 1; parity_idx = parity_idx + 1)begin 
      test_uart_config( 
	50000000,
	baud_rates[test_idx],
	baud_rates[test_idx],
	frame_sizes[frame_idx],
	parity_types[parity_idx],
	test_patterns[frame_idx],
	test_case_num
      );
      test_case_num = test_case_num + 1;
      @(negedge clk);
      end
    end
  end
  
  
  $display("============================================");
  $display("\n==== Starting Error Condition Tests ====\n");
  $display("\n========== Baud rate mismatch ==========\n");
  $display("============================================");
  for(error_idx = 0; error_idx < 3; error_idx = error_idx + 1) begin
    for(test_idx = 0; test_idx < 3; test_idx = test_idx + 1) begin
      test_uart_config(
	    50000000,                // f
	    //115200,
	    //115200,
	    baud_rates[error_idx],
	    baud_rates[test_idx],
	    frame_sizes[3],          // 8-bit
	    parity_types[1],         // No parity
	    test_patterns[3],        // 8-bit pattern         
	    test_case_num
      );
      test_case_num = test_case_num + 1;
      @(negedge clk);  
    end
  end
  
  
  $display("============================================");
  $display("\n==== Starting Error Condition Tests ====\n");
  $display("\n========== Frame size mismatch =========\n");
  $display("============================================");
  for(error_idx = 0; error_idx < 2; error_idx = error_idx + 1) begin
    test_uart_config(
	  50000000,
	  baud_rates[1],
	  baud_rates[1],
	  error_frame_sizes[error_idx],
	  parity_types[1],
	  test_patterns[3],
	  test_case_num
    );
    test_case_num = test_case_num + 1;
    @(negedge clk);  
  end
  
  $display("============================================");
  $display("\n==== Starting Error Condition Tests ====\n");
  $display("\n========= Parity Type mismatch =========\n");
  $display("============================================");
  test_uart_config(
	  50000000,
	  baud_rates[1],
	  baud_rates[1],
	  frame_sizes[3],
	  error_parity_types[0],
	  test_patterns[3],
	  test_case_num
    );
    test_case_num = test_case_num + 1;
    @(negedge clk);
  
  $display("============================================");
  $display("\n==== Starting Error Condition Tests ====\n");
  $display("\n========= Test freq small/big ==========\n");
  $display("============================================");
   test_uart_config(
	  error_frequencies[0],
	  //50000000,
	  baud_rates[1],
	  baud_rates[1],
	  frame_sizes[3],
	  parity_types[1],
	  test_patterns[3],
	  test_case_num
    );
    test_case_num = test_case_num + 1;
    @(negedge clk);
    
  #(5000000);
  YOU_PASS_task;
  //$finish;
end

//================================================================
//  input task
//================================================================

task test_uart_config;
    input [31:0] freq;
    input [31:0] baud_tx;
    input [31:0] baud_rx;
    input [31:0] frame;
    input [1:0]  parity;
    input [31:0] data;
    input [31:0] test_num;
    begin
    @(negedge clk);
    transfer = 1;
    write_transaction(32'h001C, freq);    // frequency
    write_transaction(32'h0000, baud_tx);    // baud rate t
    write_transaction(32'h0010, baud_rx);    // baud rate r
    write_transaction(32'h0004, frame);   // frame size
    write_transaction(32'h0008, parity);  // parity type
    write_transaction(32'h0014, 32'b1111);// enable reg
    write_transaction(32'h0018, data);    // tx data
    write_transaction(32'h000C, 32'b1);   // uart transfer enable
    wait (IRQ);
    wait_uart_status(test_num, baud_tx, baud_rx, frame, parity,freq);
    read_transaction(32'h0024, rdata); // read rx dout
    $display ("Test %0d dout = %b (Expected = %b)", test_num, rdata, data);
    if(rdata !== data) begin
        $display("ERROR: Data mismatch in Test %0d", test_num);
        $display("Expected: %b", data);
        $display("Got     : %b", rdata);
        //$finish;
    end
    ///@(negedge clk); //for BR_config_error can keep going next pattern
    write_transaction(32'h0020, 32'b1111); // clear reg
    wait (!IRQ);
    //@(negedge clk);
    transfer = 0;
    end
endtask

task write_transaction;
    input [31:0] write_addr;
    input [31:0] write_data;
    begin
        write_read = 1;
        addr = write_addr;
        wdata = write_data;
        @(negedge clk);
        @(negedge clk);
    end
endtask

task read_transaction;
    input [31:0] read_addr;
    input [31:0] rdata;
    begin
        write_read = 0;
        addr = read_addr; 
        @(negedge clk);
        @(negedge clk);
    end
endtask

task wait_uart_status;
    input [31:0] test_num;
    input [31:0] baud_tx;
    input [31:0] baud_rx;
    input [31:0] frame;
    input [1:0]  parity;
    input [31:0] f;
begin
    begin: wait_status
    while(1) begin
        if (IRQ === 1) begin
            if (rdata[1:0] == 2'b10) begin 
                $display("--------------------------------------");
                $display("     Test %0d: Transfer Complete!     ", test_num);
                $display("     freq=%d,Baud_Tx=%0d,Baud_Rx=%0d Frame=%0d, Parity=%0d, status=%0b ",f, baud_tx,baud_rx, frame, parity,rdata);
                $display("     Time=%0t status = %b            ", $time, rdata);
                $display("--------------------------------------");
                //transfer = 0;
                disable wait_status;
                
            end
            else if (rdata[1:0] == 2'b11) begin 
                $display("----------------------------------------------------");
                $display("     Baud rate mismatch!                            ");
                $display("     Error in Test %0d !!!                          ", test_num);
                $display("     freq=%d,Baud_Tx=%0d,Baud_Rx=%0d Frame=%0d, Parity=%0d, status=%0b ",f, baud_tx,baud_rx, frame, parity,rdata);
                $display("----------------------------------------------------");
                disable wait_status;
            
                //$finish;
            end
            else read_transaction(32'h0020, rdata);
            
            if (rdata[3]) begin
                $display("----------------------------------------------------");
                $display("     Baud rate or frequency config error!           ");
                $display("     Error in Test %0d !!!                          ", test_num);
                $display("     freq=%d,Baud_Tx=%0d,Baud_Rx=%0d Frame=%0d, Parity=%0d,status=%0b ",f, baud_tx,baud_rx, frame, parity, rdata);
                $display("----------------------------------------------------");
                disable wait_status;
                //$finish;           
            end
            else read_transaction(32'h0020, rdata);
            
            @(negedge clk);
        end
    end
    end
end
endtask
/*
task wait_uart_status;
    input [31:0] test_num;
    input [31:0] baud_tx;
    input [31:0] baud_rx;
    input [31:0] frame;
    input [1:0]  parity;
begin
    begin: wait_status
    while(1) begin
        //$display("4. IRQ = %d",IRQ);
        if (IRQ === 1) begin
        //$display("5. IRQ = %d",IRQ);
            case (rdata)
            TX_DONE : begin 
                //$display("Test %0d: TX DONE (Baud=%0d, Frame=%0d, Parity=%0d)", test_num, baud, frame, parity);
                read_transaction(32'h0020, rdata);
            end
            RX_DONE : begin 
                $display("--------------------------------------");
                $display("     Test %0d: Transfer Complete!     ", test_num);
                $display("     Baud_Tx=%0d,Baud_Rx=%0d Frame=%0d, Parity=%0d ", baud_tx,baud_rx, frame, parity);
                $display("     Time=%0t status = %b            ", $time, rdata);
                $display("--------------------------------------");
                transfer = 0;
                disable wait_status;       
            end
            ERROR : begin 
                $display("----------------------------------------------------");
                $display("     Baud rate mismatch!                            ");
                $display("     Error in Test %0d !!!                          ", test_num);
                $display("     Baud_Tx=%0d,Baud_Rx=%0d Frame=%0d, Parity=%0d ", baud_tx,baud_rx, frame, parity);
                $display("----------------------------------------------------");
                disable wait_status;
                //$finish;
            end
            BR_CONFIG_ERROR : begin
                $display("----------------------------------------------------");
                $display("     Baud rate or frequency config error!           ");
                $display("     Error in Test %0d !!!                          ", test_num);
                $display("     Baud_Tx=%0d,Baud_Rx=%0d Frame=%0d, Parity=%0d ", baud_tx,baud_rx, frame, parity);
                $display("----------------------------------------------------");
                disable wait_status;
                //$finish;           
            end
            default : begin read_transaction(32'h0020, rdata); end
            endcase
            @(negedge clk);
        end
    end
    end
end
endtask
*/
//================================================================
//  env task
//================================================================
task reset_task ; begin
    #(`CYCLE_TIME/2);	resetn = 0 ;
    #(`CYCLE_TIME*3);
    #(`CYCLE_TIME/2);	resetn = 1 ;
    #(`CYCLE_TIME);	release clk;
end endtask

//================================================================
//  pass/fail task
//================================================================
task YOU_PASS_task ; begin
$display ("----------------------------------------------------------------------------------------------------------------------");
$display ("                                                  Congratulations!                                                    ");
$display ("                                           You have passed all patterns!                                              ");
$display ("----------------------------------------------------------------------------------------------------------------------");
$finish;    
end endtask

endmodule