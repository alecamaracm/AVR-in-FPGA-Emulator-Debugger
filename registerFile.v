module registerFile(clk,reg1input,writeEn,reg1address,reg1output,reg2address,reg2output,reg2input,writeEn2,bit16Debug);

input clk;

input [7:0]reg1input;
input [7:0]reg2input;
input writeEn,writeEn2;
input [4:0]reg1address;
output [7:0]reg1output;

input [4:0]reg2address;
output [7:0]reg2output;

reg [7:0]regs[32];

output [15:0]bit16Debug;
assign bit16Debug={regs[27],regs[26]};

assign reg1output=regs[reg1address];
assign reg2output=regs[reg2address];

always @(posedge clk)
begin	
	if(writeEn)
	begin
		regs[reg1address]=reg1input;
	end
	
	if(writeEn2)
	begin
		regs[reg2address]=reg2input;
	end
	
end

endmodule