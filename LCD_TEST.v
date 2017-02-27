	module	LCD_TEST (	
//	Host Side
	iCLK,
	iRST_N,				// make the reset SW0 PIN_AA
			
//	LCD Side
	LCD_DATA,
	LCD_RW,
	LCD_EN,
	LCD_RS
	);

	
//	Host Side
	input					iCLK			;				//	iCLK set up from the 50 MHz clock PIN_Y2
	input					iRST_N		;				//	just a reset (active low) which was setup on SW17 PIN_AB28
	
//	LCD Side
	output			[7:0]		LCD_DATA		;		// 8-bit data sent to LCD display
	output						LCD_RW		;		// LCD READ/WRIE - in controller pulled low for WRITE only - PIN_M1
	output						LCD_EN		;		// LCD ENABLE - pulled low during "reset" and high for operation - PIN_L4
	output						LCD_RS		;		// LCD - 0 = Command, 1= data
	

//	Internal Wires/Registers
	reg				[5:0]		LUT_INDEX	;		// Used as an index to point to either a initialization, line 1 or line 2 transmit
	reg				[8:0]		LUT_DATA		;		//	Register for holding data ot be transmitted - highest order bit use for command/data 
	reg				[5:0]		mLCD_ST		;		// Defines the state 0 = intialization, 1 = Line 1, 2 = Line 2, 3 = LUT_INDEX increment - reset state   
	reg				[17:0]	mDLY			;		// Delay between states 2 and 3 - i.e. time to wirte a full line =  3FFFE = 262142
	reg							mLCD_Start	;		// Used to define command or data state 
	reg				[7:0]		mLCD_DATA	;		// Register for holding data 
	reg							mLCD_RS		;		// Register for command/data bit
	wire							mLCD_Done	;		// Wire from controller to say that initial;lzation is completed.

	parameter			LCD_INTIAL	=	0					;	// Initial index set to 0
	parameter			LCD_LINE1	=	5					;	// Index for start of Line 1 data 
	parameter			LCD_CH_LINE	=	LCD_LINE1+16	;	//	End of Line 1 data = 16 characters per line
	parameter			LCD_LINE2	=	LCD_LINE1+16+1	;	// Index for start of Line 2 data 
	parameter			LUT_SIZE		=	LCD_LINE1+32+1	;	// Total size of data index 

	always@(posedge iCLK or negedge iRST_N)
		begin
		if(!iRST_N)
		begin
			LUT_INDEX	<=	0;										// During reset all set to 0
			mLCD_ST		<=	0;										// Set state  to initiliaze the lCD
			mDLY			<=	0;										// Set the inintial delay L:in1/Line 2 to 0 
			mLCD_Start	<=	0;										// initilaise the start  
			mLCD_DATA	<=	0;										//	Set data to all 0's
			mLCD_RS		<=	0;										// Set RS to command mode
		end
		
		else
		begin
					
		
			if(LUT_INDEX<LUT_SIZE)
			begin
				case(mLCD_ST)
				
				0:	begin												// Initialization state
						mLCD_DATA	<=	LUT_DATA[7:0];
						mLCD_RS		<=	LUT_DATA[8];			// Set RS to highest oerder bit of LUT_DATA
						mLCD_Start	<=	1;							// Set start to "COMMAND"
						mLCD_ST		<=	1;							// Set state to Lin1
					end
					
				1:	begin												// Writng 1st line of data
						if(mLCD_Done)								// Check to see if initilaization is complete
						begin
							mLCD_Start	<=	0;						// Set to start DATA trasmit
							mLCD_ST		<=	2;						// Set state to Line 2
						end
					end
					
				2:	begin												// Writng 2nd line of data AFTER delay
						if(mDLY<18'h3FFFE)						// Delay to allow 1st line
							mDLY	<=	mDLY+1;						// Delay counter
						else
						begin								
							mDLY	<=	0;								// Reset delay counter
							mLCD_ST	<=	3;							// Move to increment state
						end
					end
					
				3:	begin
						LUT_INDEX	<=	LUT_INDEX+1;
						mLCD_ST	<=	0;
					end
				endcase
			end
		end
	end

		
	

//	ALWAYS loop sets LUT_DATA at all time based on the LUT_INDEX value which determines intialization, line 1 or lin 2	
	always
	begin
	
				
		case(LUT_INDEX)
//			Initial - note highest order bit is a "0" for command
			LCD_INTIAL+0:	LUT_DATA	<=	9'h038;	//	
			LCD_INTIAL+1:	LUT_DATA	<=	9'h00C;	//
			LCD_INTIAL+2:	LUT_DATA	<=	9'h001;	//
			LCD_INTIAL+3:	LUT_DATA	<=	9'h006;	//
			LCD_INTIAL+4:	LUT_DATA	<=	9'h080;	//

			
//			Line 1 - note highest bit is a "1" for data
			LCD_LINE1+0:	LUT_DATA	<=	9'h157;	//	W
			LCD_LINE1+1:	LUT_DATA	<=	9'h165;	// e
			LCD_LINE1+2:	LUT_DATA	<=	9'h16C;	//	l
			LCD_LINE1+3:	LUT_DATA	<=	9'h163;	//	c
			LCD_LINE1+4:	LUT_DATA	<=	9'h16F;	//	o
			LCD_LINE1+5:	LUT_DATA	<=	9'h16D;	//	m
			LCD_LINE1+6:	LUT_DATA	<=	9'h165;	//	e
			LCD_LINE1+7:	LUT_DATA	<=	9'h120;	//	space
			LCD_LINE1+8:	LUT_DATA	<=	9'h174;	//	t 
			LCD_LINE1+9:	LUT_DATA	<=	9'h16F;	//	o
			LCD_LINE1+10:	LUT_DATA	<=	9'h120;	//	space
			LCD_LINE1+11:	LUT_DATA	<=	9'h174;	//	t
			LCD_LINE1+12:	LUT_DATA	<=	9'h168;	//	h
			LCD_LINE1+13:	LUT_DATA	<=	9'h165;	//	e
			LCD_LINE1+14:	LUT_DATA	<=	9'h120;	//	space
			LCD_LINE1+15:	LUT_DATA	<=	9'h120;	//	space
			
//	Change Line
			LCD_CH_LINE:	LUT_DATA	<=	9'h0C0;
			
//	Line 2
//	 Changed to ECE:2220 Altera DE2 Board 

			LCD_LINE2+0:	LUT_DATA	<=	9'h145;	// E
			LCD_LINE2+1:	LUT_DATA	<=	9'h143;	// C
			LCD_LINE2+2:	LUT_DATA	<=	9'h145;	// E
			LCD_LINE2+3:	LUT_DATA	<=	9'h13A;	// :
			LCD_LINE2+4:	LUT_DATA	<=	9'h132;	// 2
			LCD_LINE2+5:	LUT_DATA	<=	9'h132;	// 2
			LCD_LINE2+6:	LUT_DATA	<=	9'h132;	// 2
			LCD_LINE2+7:	LUT_DATA	<=	9'h130;	// 0
			LCD_LINE2+8:	LUT_DATA	<=	9'h120;	// space
			LCD_LINE2+9:	LUT_DATA	<=	9'h14C;	// L
			LCD_LINE2+10:	LUT_DATA	<=	9'h161;	// a
			LCD_LINE2+11:	LUT_DATA	<=	9'h162;	// b
			LCD_LINE2+12:	LUT_DATA	<=	9'h128;	// (
			LCD_LINE2+13:	LUT_DATA	<=	9'h164;	//	d
			LCD_LINE2+14:	LUT_DATA	<=	9'h162;	//	b
			LCD_LINE2+15:	LUT_DATA	<=	9'h129;	//	)
		endcase
end

LCD_Controller u0	(	

//			Host Side
			.iDATA(mLCD_DATA),
			.iRS(mLCD_RS),
			.iStart(mLCD_Start),
			.oDone(mLCD_Done),
			.iCLK(iCLK),
			.iRST_N(iRST_N),
					
//			LCD Interface
			.LCD_DATA(LCD_DATA),
			.LCD_RW(LCD_RW),
			.LCD_EN(LCD_EN),
			.LCD_RS(LCD_RS)	

			);

endmodule

// ----------------------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------------------


module LCD_Controller (	

//	Host Side
				iDATA,
				iRS,
				iStart
				,oDone,
				iCLK,iRST_N,
						
//	LCD Interface
				LCD_DATA,
				LCD_RW,
				LCD_EN,
				LCD_RS
				);
				
//	CLK
	parameter	CLK_Divide	=	16;

//	Host Side
	input			[7:0]	iDATA		;
	input					iRS		;
	input					iStart	;
	input					iCLK		;
	input					iRST_N	;
	output	reg		oDone		;			// Bit to be set when 

	
	
	
//	LCD Interface
	output			[7:0]	LCD_DATA	;
	output	reg			LCD_EN	;
	output					LCD_RW	;
	output					LCD_RS	;

	
//	Internal Register
	reg				[4:0]	Cont		;
	reg				[1:0]	ST			;
	reg						preStart	;
	reg						mStart	;

	
//	Only write to LCD, bypass iRS to LCD_RS
	assign	LCD_DATA	=	iDATA		; 
	assign	LCD_RW	=	1'b0		;
	assign	LCD_RS	=	iRS		;

	
//

	always@(posedge iCLK or negedge iRST_N)
	begin
		if(!iRST_N)
		begin
			oDone	<=	1'b0		;					// Initilaise all on reset
			LCD_EN	<=	1'b0	;
			preStart<=	1'b0	;
			mStart	<=	1'b0	;
			Cont	<=	0			;
			ST		<=	0			;
		end
		
		else
		begin
		
//			Input Start Detect 
			preStart <=	iStart;
			if({preStart,iStart}==2'b01)
			begin
				mStart	<=	1'b1;
				oDone	<=	1'b0;			
			end

			

			if(mStart)
			begin
				case(ST)
				
				0:	ST	<=	1;							//	Wait Setup
				
				1:	begin								// STATE 1 = LCD enable	
						LCD_EN	<=	1'b1;			
						ST		<=	2;					
					end
					
				2:	begin								// STATE 2 = Clock divide to enable LCD write
						if(Cont<CLK_Divide)
							Cont	<=	Cont+1;
						else
							ST		<=	3;
					end
					
				3:	begin								// STATE 3 = set DONE and reset LCD_EN, start etc
						LCD_EN	<=	1'b0;
						mStart	<=	1'b0;
						oDone	<=	1'b1;
						Cont	<=	0;
						ST		<=	0;
					end
				endcase
			
			end
		end
	end

endmodule
