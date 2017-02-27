module elevator_control(clock, input_floor, out_request_floor, In_floor, out_current_floor, reset, direction, led2);
input [3:0] input_floor; // four switcheds
input clock;
output reg[6:0] out_request_floor;
reg[3:0] request_floor;
input In_floor;
reg[3:0] current_floor;
output reg[6:0] out_current_floor;

output reg [27:0] direction;
//output reg led;
output reg led2;

reg complete;

input reset;


//reg [26:0] count;
//initial count=0;

//always@(negedge clock)
//begin
//count=count+1'b1;
//led=count[26];
//end
always @ (posedge In_floor)
	casex(request_floor)
		4'bxxxx: if(input_floor[0]) request_floor=4'b0001;
		else if(input_floor[1]) request_floor=4'b0010;
		else if (input_floor[2]) request_floor=4'b0011;
		else if (input_floor[3]) request_floor=4'b0100;
	endcase
		


/*always @ (posedge input_floor)
	casex(request_floor)
	// set the request_floor based on the push button pressed
		4'bxxxx: if(input_floor[0]) request_floor=4'b0001;
		else if(input_floor[1]) request_floor=4'b0010;
		else if (input_floor[2]) request_floor=4'b0011;
		else if (input_floor[3]) request_floor=4'b0100;
		//else if (reset) request_floor=4'b0;
		default: request_floor=4'b0;
	endcase*/
	

/*always @ (posedge clock)
	begin
		request_floor=4'b0;
		//if(input_floor)
			//begin
				casez(request_floor)
					4'b????: if(In0) request_floor=4'b0001;
					4'b????: if(In1) request_floor=4'b0010;
					4'b????: if(In2) request_floor=4'b0010;
					4'b????: if(In3) request_floor=4'b0100;
					default: request_floor= 4'b0;
			/*casex(input_floor)
				4'b0xxx: if(input_floor[0]) 
					request_floor=4'b0001 ;
					else if(input_floor[1]) 
						request_floor=4'b0010;
					else if(input_floor[2]) 
						request_floor=4'b0011;
					else if(input_floor[3]) 
						request_floor=4'b0100;*/
				//if (input_floor[0] && clock) request_floor=3'b001;
				//else if (input_floor[1] && clock) request_floor=3'b010;
				//else if (input_floor[2] && clock) request_floor=3'b011;
				//else if (input_floor[3] && clock) request_floor=3'b0100;
				
				/*4'b1000:request_floor=3'b001; // 1st floor
				4'b0100:request_floor=3'b010; // 2nd floor
				4'b0010:request_floor=3'b011; // 3rd floor
				4'b0001:request_floor=3'b100; // 4th floor*/
				//else request_floor=3'b0;
				//default:request_floor=4'b0;
			//endcase
		//end 
		//case(request_floor)
			//4'b0001:out_request_floor=7'b1001111; // display 1
			//4'b0010:out_request_floor=7'b0010010; // display 2
			//4'b0011:out_request_floor=7'b0000110; // display 3
			//4'b0100:out_request_floor=7'b1001100; // display 4
			//4'b0:out_request_floor=7'b1111110; // display -
		//endcase
	//end
		
always @ (request_floor)
	begin
		case(request_floor)
			4'b0001:out_request_floor=7'b1001111; // display 1
			4'b0010:out_request_floor=7'b0010010; // display 2
			4'b0011:out_request_floor=7'b0000110; // display 3
			4'b0100:out_request_floor=7'b1001100; // display 4
			4'b0:out_request_floor=7'b1111110; // display -
			//default:out_request_floor=7'b1111110; // display -
		endcase
	end 
	
always @ (current_floor)
	begin
		case(current_floor)
			4'b0001:out_current_floor=7'b1001111; // display 1
			4'b0010:out_current_floor=7'b0010010; // display 2
			4'b0011:out_current_floor=7'b0000110; // display 3
			4'b0100:out_current_floor=7'b1001100; // display 4
			4'b0:out_current_floor=7'b1111110; // display -
			//default:out_request_floor=7'b1111110; // display -
		endcase
	end
	

reg [27:0] count2;
initial count2=0;	
always @(negedge clock)
	 begin
//always@(negedge clock)
//begin
count2=count2+1'b1;
led2=count2[27];
//end
		 //if(led2)
			//begin
			 if (request_floor>current_floor)
				 begin
				  direction=28'b1111111111111100110001000001;//b1000001001100011111111111111;
				  if(led2)
				  begin
				  current_floor <= current_floor+3'b1;
				  count2=0;
				  end
				 end
		 
			 else if(request_floor<current_floor)
				begin
				  direction=28'b0011000100000100010010000001;//b0001001000000110000010011000;
				  if(led2)
				  begin
				  current_floor <= current_floor-3'b1;
				  count2=0;
				  end
				end
			 
			 else if(request_floor == current_floor)
				 begin
				  complete=1'b1;
				  direction=28'b0001001000000111111111111111;
				 end
			 //end
		end
		
endmodule		

