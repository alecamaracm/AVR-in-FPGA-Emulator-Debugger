
module instructionSelector (
									input [15:0]readedByte1,
									output reg [7:0]OPCODE);
									
localparam error=8'd0,
ldi=8'd1,
jmp=8'd2,
call=8'd3,
out=8'd4,
ret=8'd5,
cli=8'd6,
rjmp=8'd7,
eor=8'd8;
			
			
always @(*)
begin
	
	if(readedByte1[15:12]==4'b1110)
		OPCODE<=ldi;
	else if(readedByte1[15:9]==7'b1001010 && readedByte1[3:1]==3'b110)
		OPCODE<=jmp;
	else if(readedByte1[15:9]==7'b1001010 && readedByte1[3:1]==3'b111)
		OPCODE<=call;
	else if(readedByte1[15:11]==5'b10111)
		OPCODE<=out;
	else if(readedByte1==16'b1001010100001000)
		OPCODE<=ret;
	else if(readedByte1==16'b1001010011111000)
		OPCODE<=cli;
	else if(readedByte1[15:12]==4'b1100)
		OPCODE<=rjmp;
	else if(readedByte1[15:10]==6'b001001)
		OPCODE<=eor;
	else 
		OPCODE<=error;
	
	
	
end
			
endmodule
									
									