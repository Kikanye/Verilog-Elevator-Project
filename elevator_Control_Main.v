module elevator_Control_Main(input_floor, out_request_floor, In_floor, out_current_floor, direction, condition_for_delay, iCLK); //LCD_DATA, LCD_RW, LCD_EN, LCD_RS);

input [3:0] input_floor;                                     // Switches SW13 to SW16 to select the floor to be input
input iCLK;                                                  // The internal clock for PIN_Y2 to setup the delay
output reg[6:0] out_request_floor;                           // Output to register and show the value of the requested floor on the 7 segment display (HEX6)
reg[3:0] request_floor;                                      // Stores the floor number in binary form.
input In_floor;                                              // The clock value assigned to the KEY3 push button 
reg[3:0] current_floor;                                      // Stores the value of the current floor as a 4-bit binary number
output reg[6:0] out_current_floor;                           // Output to register and show the value of the current floor on the 7 segment display (HEX4)


output reg [27:0] direction;                                 // shows the direction on the seven segment displays  ad UP or UNUP(for down)



///LCD Display Inputs and outputs
/*output [7:0] LCD_DATA;
output LCD_RW;
output LCD_EN;
output LCD_RS;*/
// LCD display inputs and outputs ends


// This converter sets up the value of the request_floor in binary based on the switch which is turned on and if the clock is pressed
always @ (posedge In_floor) // only set value when the button KEY3 is pressed
	casex(request_floor)
		4'bxxxx: if(input_floor[0]) request_floor=4'b0001;     // if switch SW16 is ON set request_floor to 1 in binary
		else if(input_floor[1]) request_floor=4'b0010;         // if switch SW15 is ON set request_floor to 2 in binary
		else if (input_floor[2]) request_floor=4'b0011;        // if switch SW14 is ON set request_floor to 3 in binary
		else if (input_floor[3]) request_floor=4'b0100;        // if switch SW13 is ON set request_floor to 4 in binary
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
	
	

reg [29:0] count_clock;                                // Register to use for timing (29 bits), 10seconds
initial count_clock=0;                                 // Initialize the vlaue of the counter to 0  
output reg condition_for_delay;                        // Stores the value of the leftmost bit to be used for delay and in the elevator if statement block
	
always @(posedge iCLK)											 // Use the internal clolck for the edge
begin
	count_clock=count_clock+1'b1;								 // Increase the value of the the counter by added one each time 
	condition_for_delay=count_clock[29];                // take the leftmost bit
			 if (request_floor>current_floor)             // Test to see if the request value is greater than the current floor
				 begin
				  direction=28'b1111111111111100110001000001;      //GOING UP!!!!!!!!!!!!!!!                    
				  if(condition_for_delay)										
				  begin
				  count_clock=0; //!!!!!!!!!!!!!!Might have to remove this
				  current_floor <= current_floor+4'b1;
				  count_clock=0;
				  end
				 end
		 
			 else if(request_floor<current_floor)
				begin
				  direction=28'b0011000100000100010010000001;// going down
				  if(condition_for_delay)
				  begin
				  count_clock=0; //!!!!!!!!!!!!!!!Might have to remove this
				  current_floor <= current_floor-4'b1;
				  count_clock=0;
				  end
				end
			 
			 else if(request_floor == current_floor)
				 begin
				  direction=28'b0001001000000111111111111111;
				 end
		end

		
		
