`timescale 1ns/1ps

module testbench();

  import sim_uart_pkg::*;

  parameter SIMULATION  = 1;
  parameter HALF_CLOCK_PROFPGA = 5;
  parameter HALF_CLOCK_DDR3 = 3.125;
  parameter HALF_CLOCK_REF = 2.5;
  parameter HALF_CLOCK_UART = 5;

  parameter ADDR_WIDTH = 32;
  parameter WORD_WIDTH = 32;
  parameter LEN_WIDTH = 6;
  //parameter PACKET_SIZE_MIN = (ADDR_WIDTH/8) + 1; //Packet size in bytes without data
  

  //clock and reset
  logic reset          = 1;
  logic c0_main_clk_p  = 0;
  logic c0_main_clk_n  = 1;
  logic c1_main_clk_p  = 0;
  logic c1_main_clk_n  = 1;
  logic clk_ref_p      = 0;
  logic clk_ref_n      = 1;


  //UART
  logic uart_rxd  ;
  logic uart_txd  ;
  logic uart_cts ;
  logic uart_rts;



  logic profpga_clk0_p   = 0;  // 100 MHz clock
  logic profpga_clk0_n   = 1;  // 100 MHz clock
  logic profpga_sync0_p ;
  logic profpga_sync0_n ;

  //Other signals
  logic tb_uart_txd;
  logic tb_uart_rxd;
  logic clk;
  logic uart_clk, tb_uart_tick;

  //Top module instantiation
  top #( .SIMULATION (SIMULATION)
      ) top_inst (
      // MMI64
      .clk_board_p       ( profpga_clk0_p),
      .clk_board_n       ( profpga_clk0_n),
      .profpga_sync0_p   ( profpga_sync0_p),
      .profpga_sync0_n   ( profpga_sync0_n),
      .reset             ( reset),
      .uart_rxd          ( uart_rxd),
      .uart_txd          ( uart_txd),
      .uart_cts         ( uart_cts),
      .uart_rts         ( uart_rts),
      .LED_RED           ( open),
      .LED_GREEN         ( open),
      .LED_BLUE          ( open),
      .LED_YELLOW        ( open)
      );


  //Top module signals
  


  
  assign tb_uart_rxd = uart_txd;
  assign uart_rxd = tb_uart_txd;
  assign clk = profpga_clk0_p;
  
  always #HALF_CLOCK_PROFPGA profpga_clk0_p =~ profpga_clk0_p;
  always #HALF_CLOCK_PROFPGA profpga_clk0_n =~ profpga_clk0_n;
  
  always #HALF_CLOCK_DDR3 c0_main_clk_p =~ c0_main_clk_p;
  always #HALF_CLOCK_DDR3 c0_main_clk_n =~ c0_main_clk_n;
  always #HALF_CLOCK_DDR3 c1_main_clk_p =~ c1_main_clk_p;
  always #HALF_CLOCK_DDR3 c1_main_clk_n =~ c1_main_clk_n;
  
  always #HALF_CLOCK_REF clk_ref_p =~ clk_ref_p;
  always #HALF_CLOCK_REF clk_ref_n =~ clk_ref_n;
  
  always #HALF_CLOCK_UART uart_clk =~ uart_clk;
  always #(HALF_CLOCK_UART*UART_NUM_CLK_TICKS_BIT) tb_uart_tick =~ tb_uart_tick;

  initial
  begin
    profpga_clk0_p <= 0;
    profpga_clk0_n <= 1;
    c0_main_clk_p <= 0;
    c0_main_clk_n <= 1;
    c1_main_clk_p <= 0;
    c1_main_clk_n <= 1;
    clk_ref_p <= 0;
    clk_ref_n <= 1;
    profpga_sync0_p <= 0;
    profpga_sync0_n <= 1;
    reset = 1;
    tb_uart_txd = 1;
    uart_cts = 0;
    uart_clk = 0;
    tb_uart_tick = 0;
    repeat(100) @(posedge clk);
    reset         <= 0;
    
    //Send reset 4 times
    //repeat(10000) @(posedge clk);
    //sendPacketUart( .write(1'b1), .data_len('b0), .addr(32'h60000400), .data_in(32'h00000001));
    //repeat(10000) @(posedge clk);
    //sendPacketUart( .write(1'b1), .data_len('b0), .addr(32'h60000400), .data_in(32'h00000001));
    //repeat(10000) @(posedge clk);
    //sendPacketUart( .write(1'b1), .data_len('b0), .addr(32'h60000400), .data_in(32'h00000001));
    //repeat(10000) @(posedge clk);
    //sendPacketUart( .write(1'b1), .data_len('b0), .addr(32'h60000400), .data_in(32'h00000001));
    //repeat(10000) @(posedge clk);
    //repeat(300000) @(posedge clk);

    //sendPacketUart( .write(1'b1), .data_len('b0), .addr(32'h600003FC), .data_in(32'h00000001));

    repeat(1000000000) @(posedge clk);
    $finish;
  end
  
  
  ////////////////////////////////////////////////////////////////
	// TASK TO DULOCAL TRANSACTION SEND TOKEN RECEIVE RESPONSE 	////
	// THE UART USING THE PADS									////
	////////////////////////////////////////////////////////////////
	//task automatic TASK_duLocalTransaction;
	//	input duTokenType_t 	duLoc_m2s_tokenType;
	//	input [DU_CPUIDW-1:0]	duLoc_m2s_cpuid;
	//	input [DU_ADRW-1:0]		duLoc_m2s_adr;
	//	input [DU_DATW-1:0]		duLoc_m2s_dat;
  //
	//	output Response_t   duLoc_respArray;		
	//	integer duLoc_iterSend	= 0;
	//	integer duLoc_iterResp	= 0;
	//	
	//	@(posedge clk);
	//	fork
	//		//SEND TOKENS
	//		begin
	//			sendTokenUart(
	//				{duLoc_m2s_cpuid, duLoc_m2s_tokenType },
	//				{duLoc_m2s_adr }, //32bit adr
	//				{duLoc_m2s_dat }	//32bit dat
	//			);
	//		end
	//		
	//		// WAIT ACK OVER UART
	//		begin
	//			recvByteUart(recv_data);
	//			duLoc_respArray[HPOS_BIT_ACK_ERR_DU2H -:8 ] = recv_data;
	//			// data resp
	//			if(FUNC_isWriteToken ({ duLoc_m2s_cpuid, duLoc_m2s_tokenType  }) )
	//			begin
	//				duLoc_respArray[NUM_BYTE_DAT_DU2H*8-1:0] =32'b0;
	//			end
	//			else
	//			begin
	//				for(duLoc_iterResp=0; duLoc_iterResp<NUM_BYTE_DAT_DU2H; duLoc_iterResp=duLoc_iterResp+1)
	//				begin	// WAIT ACK+DATA OVER UART
	//					recvByteUart(recv_data);
	//					duLoc_respArray[HPOS_BIT_DAT_DU2H - (duLoc_iterResp*8) -:8] = recv_data;
	//				end
  //
	//			end
	//			$display("@%0t: %m DUT response ackErr: 0x%h data: 0x%h",
	//					$time,
	//					duLoc_respArray[HPOS_BIT_ACK_ERR_DU2H:LPOS_BIT_ACK_ERR_DU2H], 
	//					duLoc_respArray[HPOS_BIT_DAT_DU2H:LPOS_BIT_DAT_DU2H]	);
	//		end
	//	join
	//endtask

	////////////////////////////////////////////////
	// TASK TO SEND A duTOKEN TO 				////
	// THE UART USING THE PADS					////
	////////////////////////////////////////////////
	task sendPacketUart;
		input logic write; //Write or read
		input logic [LEN_WIDTH-1:0] data_len; //Length of data only (in bytes)
		input logic [ADDR_WIDTH-1:0] addr;  //Starting address
		input logic [WORD_WIDTH-1:0] data_in;  //Data (TODO let data have an arbitrary length up to data_len)
	
		automatic logic [3:0] iSendTokenUart='d0;
		automatic logic [UART_NUM_DWORD_BITS-1:0] tx_data;
		
		begin
			iSendTokenUart = 'd0;
			@(posedge uart_clk);
			$display("TASK sendTokenUart:\t%m write=%d, data_len=%d, adr=%h, data=%h",$time,write,data_len, addr, data_in);
		//SEND_CMD
			begin
				sendByteUart({1'b1, write, data_len});
				iSendTokenUart = iSendTokenUart+'d1;
				@(posedge uart_clk);
			end
			
		//SEND ADDR
			iSendTokenUart = 'd0;
			@(posedge uart_clk);
			repeat(ADDR_WIDTH/8) 
			begin		
				sendByteUart(addr[(ADDR_WIDTH/8-iSendTokenUart)*8-1 -:8]);
				iSendTokenUart = iSendTokenUart+'d1;
				@(posedge uart_clk);
			end
			
		//SEND DATA
      iSendTokenUart = 'd0;
      @(posedge uart_clk);
      repeat((WORD_WIDTH/8)*(data_len + 1))
      begin
        sendByteUart(data_in[(WORD_WIDTH/8-iSendTokenUart)*8-1 -: 8]);
        iSendTokenUart = iSendTokenUart+'d1;
        @(posedge uart_clk);
      end
		end

	endtask: sendPacketUart
	
	////////////////////////////////////////////////
	// TASK TO SEND BYTE TO 					////
	// THE UART USING THE PADS					////
	////////////////////////////////////////////////
	task automatic sendByteUart;
		input [UART_NUM_DWORD_BITS-1:0] txData; // 8 bit
		automatic integer iSendByteUart;
		begin
			assert(tb_uart_txd==1); //check tx == 1 if not sending
			@(posedge uart_clk);
	
			$display("@%0t: START %m(%b)",$time,txData);
			
		//start bit is 0 in uart communication protocol
			tb_uart_txd = '0;
			iSendByteUart	 = 'd0;
			repeat(UART_NUM_CLK_TICKS_BIT) @(posedge uart_clk);
		// send the payload, namely 8 bits
			repeat(UART_NUM_DWORD_BITS)
			begin
				tb_uart_txd = txData[iSendByteUart];
				//$display("@%0t: BIT %m(%b)",$time,tbSysUartTx);
				iSendByteUart    = iSendByteUart+'d1;
				repeat(UART_NUM_CLK_TICKS_BIT) @(posedge uart_clk);
			end
		// send stop bit/s, that is/are 1
			repeat(UART_NUM_STOP_BITS)
			begin
				tb_uart_txd = '1;
				repeat(UART_NUM_CLK_TICKS_BIT) @(posedge uart_clk);
			end
		// line is 1 when idle, thus keep it set to 1
		end
	endtask: sendByteUart
	
endmodule:testbench
