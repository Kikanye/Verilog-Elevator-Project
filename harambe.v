module harambe(clk, in, out);

input clk, in;
output reg[0:6] out;
reg[3:0]z;

always @(posedge clk)
	case(z)
	4'b0001:if(in) z=4'b1001;
	else z = 4'b0011;
	
	4'b0011:if(in) z=4'b0001;
	else z = 4'b0111;
	
	4'b0111: if(in) z=4'b0011;
	else z = 4'b1001;
	
	4'b1001: if(in) z=4'b0111;
	else z=4'b0001;
	
	default z=4'b0001;
	endcase
	
always @ (z)
	begin
		case(z)
			4'b0001:out=7'b1001111;
			4'b0011:out=7'b0000110;
			4'b0111:out=7'b0001111;
			4'b1001:out=7'b0000100;
		endcase
	end
endmodule
			
	