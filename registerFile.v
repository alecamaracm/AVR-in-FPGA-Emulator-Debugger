module registerFile(clk,reg1input,writeEn,reg1address,reg1output,reg2address,reg2output);

input clk;

input [7:0]reg1input;
input writeEn;
input [4:0]reg1address;
output [7:0]reg1output;

input [4:0]reg2address;
output [7:0]reg2output;

reg [7:0]regs[4:0];

assign reg1output=regs[reg1address];
assign reg2output=regs[reg2address];

always @(posedge clk)
begin	
	if(writeEn)
	begin
		regs[reg1address]=reg1input;
	end
	
end

endmodule