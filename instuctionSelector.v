
module instructionSelector (
									input [15:0]readedByte1,
									output reg [7:0]OPCODE_FINAL,
									input skipNext);
									
localparam error=8'd0,
ldi=8'd1,
jmp=8'd2,
call=8'd3,
out=8'd4,
ret=8'd5,
cli=8'd6,
rjmp=8'd7,
eor=8'd8,
subi=8'd9,
sbci=8'd10,
brne=8'd11,
nop=8'd12,
cpi=8'd13,
cpc=8'd14,
sei=8'd15,
in=8'd16,
ori=8'd17,
ld=8'd18,
lds=8'd19,
st=8'd20,
sts=8'd21,
breq=8'd22,
brcc=8'd23,
andi=8'd24,
push=8'd25,
pop=8'd26,
mov=8'd27,
lpmII=8'd28,
movw=8'd29,
Xand=8'd30,
cpse=8'd31,
Xor=8'd32,
com=8'd33,
adiw=8'd34,
adc=8'd35,
reti=8'd36,
add=8'd37,
sbiw=8'd38,
stXP=8'd39,
stX=8'd40,
ldZ=8'd41,
stZ=8'd42,
skip1=8'd156,
skip2=8'd157;


reg [7:0]OPCODE;
			
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
		else if(readedByte1[15:12]==4'b0101)
			OPCODE<=subi;
		else if(readedByte1[15:12]==4'b0100)
			OPCODE<=sbci;
		else if(readedByte1[15:10]==6'b111101 && readedByte1[2:0]==3'b001)
			OPCODE<=brne;
		else if(readedByte1==16'd0)
			OPCODE<=nop;
		else if(readedByte1[15:12]==4'b0011)
			OPCODE<=cpi;
		else if(readedByte1[15:10]==6'b000001)
			OPCODE<=cpc;
		else if(readedByte1==16'b1001010001111000)
			OPCODE<=sei;
		else if(readedByte1[15:11]==5'b10110)
			OPCODE<=in;
		else if(readedByte1[15:12]==4'b0110)
			OPCODE<=ori;
		else if(readedByte1[15:9]==7'b1001000 && readedByte1[3:0]==4'b0000)
			OPCODE<=lds;
		else if(readedByte1[15:9]==7'b1001001 && readedByte1[3:0]==4'b0000)
			OPCODE<=sts;
		else if(readedByte1[15:10]==6'b111100 && readedByte1[2:0]==3'b001)
			OPCODE<=breq;
		else if(readedByte1[15:10]==6'b111101 && readedByte1[2:0]==3'b000)
			OPCODE<=brcc;
		else if(readedByte1[15:12]==4'b0111)
			OPCODE<=andi;
		else if(readedByte1[15:9]==7'b1001001 && readedByte1[3:0]==4'b1111)
			OPCODE<=push;
		else if(readedByte1[15:9]==7'b1001000 && readedByte1[3:0]==4'b1111)
			OPCODE<=pop;
		else if(readedByte1[15:10]==6'b001011)
			OPCODE<=mov;
		else if(readedByte1[15:9]==7'b1001000 && readedByte1[3:0]==4'b0100)
			OPCODE<=lpmII;	
		else if(readedByte1[15:8]==8'b0000001)
			OPCODE<=movw;	
		else if(readedByte1[15:10]==6'b001000)
			OPCODE<=Xand;	
		else if(readedByte1[15:10]==6'b000100)
			OPCODE<=cpse;	
		else if(readedByte1[15:10]==6'b001010)
			OPCODE<=Xor;
		else if(readedByte1[15:9]==7'b1001010 && readedByte1[3:0]==4'b0000)
			OPCODE<=com;
		else if(readedByte1[15:8]==8'b10010110)
			OPCODE<=adiw;
		else if(readedByte1[15:10]==6'b000111)
			OPCODE<=adc;
		else if(readedByte1==16'b1001010100011000)
			OPCODE<=reti;
		else if(readedByte1[15:10]==6'b000011)
			OPCODE<=add;
		else if(readedByte1[15:8]==8'b10010111)
			OPCODE<=sbiw;
		else if(readedByte1[15:9]==7'b1001001 && readedByte1[3:0]==4'b1100)
			OPCODE<=stX;
		else if(readedByte1[15:9]==7'b1001001 && readedByte1[3:0]==4'b1101)
			OPCODE<=stXP;
		else if(readedByte1[15:9]==7'b1000000 && readedByte1[3:0]==4'b0000)
			OPCODE<=ldZ;
		else if(readedByte1[15:9]==7'b1000001 && readedByte1[3:0]==4'b0000)
			OPCODE<=stZ;
			//OPCODE<=error;
	
		else 
			OPCODE<=error;
	
end

			
always @(*)
begin

	if(skipNext==1)
	begin
		if(OPCODE==call || OPCODE==lds|| OPCODE==sts)
		begin
			OPCODE_FINAL<=skip1;
		end
		else
		begin
			OPCODE_FINAL<=skip2;
		end
	end
	else
	begin
		OPCODE_FINAL=OPCODE;
	end
end
			
endmodule
									
									