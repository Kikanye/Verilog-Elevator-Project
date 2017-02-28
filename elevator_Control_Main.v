module elevator_Control_Main(input_floor, out_request_floor, In_floor, out_current_floor, direction, condition_for_delay, iCLK, LCD_DATA, LCD_RW, LCD_EN, LCD_RS);

input [3:0] input_floor;                               // Switches SW13 to SW16 to select the floor to be input
input iCLK;                                           // The internal clock for PIN_Y2 to setup the delay
output reg[6:0] out_request_floor;                    // Output to register and show the value of the requested floor on the 7 segment display (HEX6)
reg[3:0] request_floor;                               // Stores the floor number in binary form.
input In_floor;                                       // The clock value assigned to the KEY3 push button 
reg[3:0] current_floor;                               // Stores the value of the current floor as a 4-bit binary number
output reg[6:0] out_current_floor;                    // Output to register and show the value of the current floor on the 7 segment display (HEX4)


output reg [27:0] direction;                          // shows the direction on the seven segment displays UP (when going up) or UNUP(when going down) or ON (when stationery)

// What to show for different values of direction.
parameter GUP=28'b1111111111111100110001000001, GDOWN=28'b0011000100000100010010000001, ON=28'b0001001000000111111111111111;

///LCD Display Inputs and outputs
output [7:0] LCD_DATA;
output LCD_RW;
output LCD_EN;
output LCD_RS;
// LCD display inputs and outputs ends


// This converter sets up the value of the request_floor in binary based on the switch which is turned on and if the clock is pressed
always @ (posedge In_floor) // only set value when the button KEY3 is pressed
	casex(request_floor)
		4'bxxxx: if(input_floor[0]) request_floor=4'b0001;     								// if switch SW16 is ON set request_floor to 1 in binary
		else if(input_floor[1]) request_floor=4'b0010;        							 	// if switch SW15 is ON set request_floor to 2 in binary
		else if (input_floor[2]) request_floor=4'b0011;        								// if switch SW14 is ON set request_floor to 3 in binary
		else if (input_floor[3]) request_floor=4'b0100;        								// if switch SW13 is ON set request_floor to 4 in binary
	endcase
		


		
//This BCD converter below displays the floor that has been inputed on the  second 7-Segment (HEX6)
always @ (request_floor)
	begin
		case(request_floor)
			4'b0001:out_request_floor=7'b1001111;      // display 1
			4'b0010:out_request_floor=7'b0010010;      // display 2
			4'b0011:out_request_floor=7'b0000110;      // display 3
			4'b0100:out_request_floor=7'b1001100;      // display 4
			4'b0:out_request_floor=7'b1111110;         // display -
		endcase
	end 

	
// This BCD converter below displays the floor that the elevator is at on the fourth 7-Segment (HEX4)
always @ (current_floor)
	begin
		case(current_floor)
			4'b0001:out_current_floor=7'b1001111;         // display 1
			4'b0010:out_current_floor=7'b0010010;         // display 2
			4'b0011:out_current_floor=7'b0000110;         // display 3
			4'b0100:out_current_floor=7'b1001100;         // display 4
			4'b0:out_current_floor=7'b1111110;            // display -
		endcase
	end
	
	

reg [26:0] count_clock;                                										// Register to use for timing (29 bits), 10seconds
initial count_clock=0;                                										// Initialize the vlaue of the counter to 0  
output reg condition_for_delay;                        										// Stores the value of the leftmost bit to be used for delay and in the elevator if statement block
	
	
always @(posedge iCLK)											 										// Use the internal clolck for the edge
begin
			 if (request_floor>current_floor)             										// Test to see if the request value is greater than the current floor
				 begin
				  direction=GUP;      							                            //GOING UP!!!!!!!!!!!!!!!  
				  
				  count_clock=count_clock+1'b1;								 										// Increase the value of the the counter by added one each time 
				  condition_for_delay=count_clock[26];                										// take the leftmost bit	(Part of delay setup)	
				  
				  if(condition_for_delay)										
				  begin

				  current_floor <= current_floor+4'b1;                                //Increase current floor by 1
				  count_clock=0;                                                      // Reset the clock delay after each floor change
				  
				  end
				 end
		 
			 else if(request_floor<current_floor)
				begin
				  direction=GDOWN;                                                     // GOING DOWN!!!!!!!!!!!!!
				  
				  count_clock=count_clock+1'b1;								 										// Increase the value of the the counter by added one each time 
				  condition_for_delay=count_clock[26];                										// take the leftmost bit	(Part of delay setup)
				  
				  if(condition_for_delay)
				  begin
				  
				  current_floor <= current_floor-4'b1;                                //Decrease current floor by 1
				  count_clock=0;                                                      //Reset the clock delay after each floor change
				  
				  end
				end
			 
			 else if(request_floor == current_floor)                                 //When the request floor is reached, just stay on
				 begin
				  direction=ON;                                                       //STAY ON!!!!!!!!!!!!
				 end
		end

		
	
	
/*---------------------------------------------------------------------------------------------------------------------------------------------------------------*/
/*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!LCD DISPLAY SECTION OF THE CODE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/
/*---------------------------------------------------------------------------------------------------------------------------------------------------------------*/	





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
	
	reg [25:0] count3;
	reg led3;                                    // the pulse of this will be used to reset the screen during short time intervals to update the display
	initial count3=0;	

	always@(posedge iCLK) 
		begin
		
	count3=count3+1'b1;
	led3=count3[25];
	
		if(led3)
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
		if(direction==GUP)                                                            //WHAT TO DISPLAY ON THE LCD WHEN GOING UP!
		begin		
		case(LUT_INDEX)
		
//			Initial - note highest order bit is a "0" for command
			LCD_INTIAL+0:	LUT_DATA	<=	9'h038;	//	
			LCD_INTIAL+1:	LUT_DATA	<=	9'h00C;	//
			LCD_INTIAL+2:	LUT_DATA	<=	9'h001;	//
			LCD_INTIAL+3:	LUT_DATA	<=	9'h006;	//
			LCD_INTIAL+4:	LUT_DATA	<=	9'h080;	//

			
//			Line 1 - note highest bit is a "1" for data
			LCD_LINE1+0:	LUT_DATA	<=	9'h120;	//	space
			LCD_LINE1+1:	LUT_DATA	<=	9'h147;	// G
			LCD_LINE1+2:	LUT_DATA	<=	9'h14F;	//	O
			LCD_LINE1+3:	LUT_DATA	<=	9'h149;	//	I
			LCD_LINE1+4:	LUT_DATA	<=	9'h14E;	//	N
			LCD_LINE1+5:	LUT_DATA	<=	9'h147;	//	G
			LCD_LINE1+6:	LUT_DATA	<=	9'h120;	//	space
			LCD_LINE1+7:	LUT_DATA	<=	9'h155;	//	U
			LCD_LINE1+8:	LUT_DATA	<=	9'h150;	//	P
			LCD_LINE1+9:	LUT_DATA	<=	9'h120;	//	space
			LCD_LINE1+10:	LUT_DATA	<=	9'h154;	//	T
			LCD_LINE1+11:	LUT_DATA	<=	9'h14F;	//	O
			LCD_LINE1+12:	LUT_DATA	<=	9'h120;	//	space
			LCD_LINE1+13:	LUT_DATA	<=	9'h128;	//	(
			LCD_LINE1+14:	if(request_floor==4'b0001) LUT_DATA	<=	9'h131;       //If the vlaue of the request_floor is 1 in binary then display 1 on the LCD
			else if(request_floor==4'b0010) LUT_DATA	<=	9'h132;                //If the vlaue of the request_floor is 2 in binary then display 2 on the LCD
			else if(request_floor==4'b0011) LUT_DATA	<=	9'h133;                //If the vlaue of the request_floor is 3 in binary then display 3 on the LCD
			else if(request_floor==4'b0100) LUT_DATA	<=	9'h134;                //If the vlaue of the request_floor is 4 in binary then display 4 on the LCD
			else LUT_DATA	<=	9'h13A;	                                         //If request_floor has no vlaue, then display :
			LCD_LINE1+15:	LUT_DATA	<=	9'h129;	//	)
			
//	Change Line
			LCD_CH_LINE:	LUT_DATA	<=	9'h0C0;
			
//	Line 2
 

			LCD_LINE2+0:	LUT_DATA	<=	9'h120;	//	space
			LCD_LINE2+1:	LUT_DATA	<=	9'h141;	// A
			LCD_LINE2+2:	LUT_DATA	<=	9'h154;	//	T
			LCD_LINE2+3:	LUT_DATA	<=	9'h120;	//	space
			LCD_LINE2+4:	LUT_DATA	<=	9'h146;	//	F
			LCD_LINE2+5:	LUT_DATA	<=	9'h14C;	//	L
			LCD_LINE2+6:	LUT_DATA	<=	9'h14F;	//	O
			LCD_LINE2+7:	LUT_DATA	<=	9'h14F;	//	O
			LCD_LINE2+8:	LUT_DATA	<=	9'h152;	//	R 
			LCD_LINE2+9:	LUT_DATA	<=	9'h120;	//	space
			LCD_LINE2+10:	LUT_DATA	<=	9'h128;	//	(
			LCD_LINE2+11:	if(current_floor==4'b0001) LUT_DATA	<=	9'h131;       //If the value of the current_floor is 1 in binary then display 1 on the LCD
			else if(current_floor==4'b0010) LUT_DATA	<=	9'h132;                //If the value of the current_floor is 2 in binary then display 2 on the LCD 
			else if(current_floor==4'b0011) LUT_DATA	<=	9'h133;                //If the value of the current_floor is 3 in binary then display 3 on the LCD
			else if(current_floor==4'b0100) LUT_DATA	<=	9'h134;                //If the value of the current_floor is 4 in binary then display 4 on the LCD
			else LUT_DATA	<=	9'h13A;                                           //If current_floor has no value, then display :
			LCD_LINE2+12:	LUT_DATA	<=	9'h129;	//	)
			LCD_LINE2+13:	LUT_DATA	<=	9'h120;	//	space
			LCD_LINE2+14:	LUT_DATA	<=	9'h13A;	//	:
			LCD_LINE2+15:	LUT_DATA	<=	9'h129;	//	)
		endcase
	end
	
	else if(direction==GDOWN)                                                             //WHAT TO DISPLAY ON THE LCD WHEN GOING DOWN
	begin
			case(LUT_INDEX)
//			Initial - note highest order bit is a "0" for command
			LCD_INTIAL+0:	LUT_DATA	<=	9'h038;	//	
			LCD_INTIAL+1:	LUT_DATA	<=	9'h00C;	//
			LCD_INTIAL+2:	LUT_DATA	<=	9'h001;	//
			LCD_INTIAL+3:	LUT_DATA	<=	9'h006;	//
			LCD_INTIAL+4:	LUT_DATA	<=	9'h080;	//

			
//			Line 1 - note highest bit is a "1" for data
			LCD_LINE1+0:	LUT_DATA	<=	9'h120;	//	space
			LCD_LINE1+1:	LUT_DATA	<=	9'h147;	// G
			LCD_LINE1+2:	LUT_DATA	<=	9'h14F;	//	O
			LCD_LINE1+3:	LUT_DATA	<=	9'h149;	//	I
			LCD_LINE1+4:	LUT_DATA	<=	9'h14E;	//	N
			LCD_LINE1+5:	LUT_DATA	<=	9'h147;	//	G
			LCD_LINE1+6:	LUT_DATA	<=	9'h120;	//	space
			LCD_LINE1+7:	LUT_DATA	<=	9'h144;	//	D
			LCD_LINE1+8:	LUT_DATA	<=	9'h14F;	//	O 
			LCD_LINE1+9:	LUT_DATA	<=	9'h157;	//	W
			LCD_LINE1+10:	LUT_DATA	<=	9'h14E;	//	N
			LCD_LINE1+11:	LUT_DATA	<=	9'h120;	//	space
			LCD_LINE1+12:	LUT_DATA	<=	9'h154;	//	T
			LCD_LINE1+13:	LUT_DATA	<=	9'h14F;	//	O
			LCD_LINE1+14:	LUT_DATA	<=	9'h120;	//	space
			LCD_LINE1+15:	if(request_floor==4'b0001) LUT_DATA	<=	9'h131;             //If the value of the request_floor is 1 in binary then display 1 on the LCD
			else if(request_floor==4'b0010) LUT_DATA	<=	9'h132;                      //If the value of the request_floor is 2 in binary then display 2 on the LCD
			else if(request_floor==4'b0011) LUT_DATA	<=	9'h133;                      //If the value of the request_floor is 3 in binary then display 3 on the LCD
			else if(request_floor==4'b0100) LUT_DATA	<=	9'h134;                      //If the value of the request_floor is 4 in binary then display 4 on the LCD
			else LUT_DATA	<=	9'h13A;	                                                // if request_floor has no value, then display :
			
//	Change Line
			LCD_CH_LINE:	LUT_DATA	<=	9'h0C0;
			
//	Line 2
 

			LCD_LINE2+0:	LUT_DATA	<=	9'h120;	//	space
			LCD_LINE2+1:	LUT_DATA	<=	9'h141;	// A
			LCD_LINE2+2:	LUT_DATA	<=	9'h154;	//	T
			LCD_LINE2+3:	LUT_DATA	<=	9'h120;	//	space
			LCD_LINE2+4:	LUT_DATA	<=	9'h146;	//	F
			LCD_LINE2+5:	LUT_DATA	<=	9'h14C;	//	L
			LCD_LINE2+6:	LUT_DATA	<=	9'h14F;	//	O
			LCD_LINE2+7:	LUT_DATA	<=	9'h14F;	//	O
			LCD_LINE2+8:	LUT_DATA	<=	9'h152;	//	R 
			LCD_LINE2+9:	LUT_DATA	<=	9'h120;	//	space
			LCD_LINE2+10:	LUT_DATA	<=	9'h128;	//	(
			LCD_LINE2+11:	if(current_floor==4'b0001) LUT_DATA	<=	9'h131;          //If the value of current_floor is 1 in binary, then display 1 on the LCD
			else if(current_floor==4'b0010) LUT_DATA	<=	9'h132;                   //If the value of current_floor is 2 in binary, then display 2 on the LCD
			else if(current_floor==4'b0011) LUT_DATA	<=	9'h133;                   //If the value of current_floor is 3 in binary, then display 3 on the LCD
			else if(current_floor==4'b0100) LUT_DATA	<=	9'h134;                   //If the value of current_floor is 4 in binary, then display 4 on the LCD
			else LUT_DATA	<=	9'h13A;                                              //if the current_floor has no vlaue, then display :
			LCD_LINE2+12:	LUT_DATA	<=	9'h129;	//	)
			LCD_LINE2+13:	LUT_DATA	<=	9'h120;	//	space
			LCD_LINE2+14:	LUT_DATA	<=	9'h13A;	//	:
			LCD_LINE2+15:	LUT_DATA	<=	9'h129;	//	)
		endcase
	end
	
	else if(direction==ON)                                                              // WHAT TO DISPLAY ON STAY ON
	 begin
			case(LUT_INDEX)
//			Initial - note highest order bit is a "0" for command
			LCD_INTIAL+0:	LUT_DATA	<=	9'h038;	//	
			LCD_INTIAL+1:	LUT_DATA	<=	9'h00C;	//
			LCD_INTIAL+2:	LUT_DATA	<=	9'h001;	//
			LCD_INTIAL+3:	LUT_DATA	<=	9'h006;	//
			LCD_INTIAL+4:	LUT_DATA	<=	9'h080;	//

			
//			Line 1 - note highest bit is a "1" for data
			LCD_LINE1+0:	LUT_DATA	<=	9'h120;	//	space
			LCD_LINE1+1:	LUT_DATA	<=	9'h141;	// A
			LCD_LINE1+2:	LUT_DATA	<=	9'h154;	//	T
			LCD_LINE1+3:	LUT_DATA	<=	9'h120;	//	space
			LCD_LINE1+4:	LUT_DATA	<=	9'h146;	//	F
			LCD_LINE1+5:	LUT_DATA	<=	9'h14C;	//	L
			LCD_LINE1+6:	LUT_DATA	<=	9'h14F;	//	O
			LCD_LINE1+7:	LUT_DATA	<=	9'h14F;	//	O
			LCD_LINE1+8:	LUT_DATA	<=	9'h152;	//	R 
			LCD_LINE1+9:	LUT_DATA	<=	9'h120;	//	space
			LCD_LINE1+10:	LUT_DATA	<=	9'h128;	//	(
			LCD_LINE1+11:	if(current_floor==4'b0001) LUT_DATA	<=	9'h131;             //If the value of current_floor is 1 in binary then display 1 on the LCD
			else if(current_floor==4'b0010) LUT_DATA	<=	9'h132;                      //If the vlaue of current_floor is 2 in binary then display 2 on the LCD
			else if(current_floor==4'b0011) LUT_DATA	<=	9'h133;                      //If the vlaue of current_floor is 3 in binary then display 3 on the LCD
			else if(current_floor==4'b0100) LUT_DATA	<=	9'h134;                      //If the vlaue of current_floor is 4 in binary then display 4 on the LCD
			else LUT_DATA	<=	9'h13A;                                                 //If current_floor has no value, then display :
			LCD_LINE1+12:	LUT_DATA	<=	9'h129;	//	)
			LCD_LINE1+13:	LUT_DATA	<=	9'h120;	//	space
			LCD_LINE1+14:	LUT_DATA	<=	9'h13A;	//	:
			LCD_LINE1+15:	LUT_DATA	<=	9'h129;	//	)
			
//	Change Line
			LCD_CH_LINE:	LUT_DATA	<=	9'h0C0;
			
//	Line 2


			LCD_LINE2+0:	LUT_DATA	<=	9'h145;	// E
			LCD_LINE2+1:	LUT_DATA	<=	9'h143;	// C
			LCD_LINE2+2:	LUT_DATA	<=	9'h145;	// E
			LCD_LINE2+3:	LUT_DATA	<=	9'h13A;	// :
			LCD_LINE2+4:	LUT_DATA	<=	9'h132;	// 2
			LCD_LINE2+5:	LUT_DATA	<=	9'h132;	// 2
			LCD_LINE2+6:	LUT_DATA	<=	9'h132;	// 2
			LCD_LINE2+7:	LUT_DATA	<=	9'h130;	// 0
			LCD_LINE2+8:	LUT_DATA	<=	9'h120;	// space
			LCD_LINE2+9:	LUT_DATA	<=	9'h150;	// P
			LCD_LINE2+10:	LUT_DATA	<=	9'h152;	// R
			LCD_LINE2+11:	LUT_DATA	<=	9'h14F;	// O
			LCD_LINE2+12:	LUT_DATA	<=	9'h14A;	// J
			LCD_LINE2+13:	LUT_DATA	<=	9'h145;	//	E
			LCD_LINE2+14:	LUT_DATA	<=	9'h143;	//	C
			LCD_LINE2+15:	LUT_DATA	<=	9'h154;	//	T
		endcase
	end
end

// Call to the module to control the LCD

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


/*---------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
/*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! MODULE TO CONTROL THE LCD!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/
/*---------------------------------------------------------------------------------------------------------------------------------------------------------------------*/


//LCD controller module
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
	reg [25:0] count3;
	reg led3;
	initial count3=0;	
	//always @(negedge iCLK)
	 //begin
	 //end

	always@(posedge iCLK) //or negedge iRST_N)
	begin
	
		count3=count3+1'b1;
	led3=count3[25];
	
		if(led3)
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

