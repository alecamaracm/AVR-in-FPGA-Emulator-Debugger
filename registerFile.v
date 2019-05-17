module registerFile(clk,reg1input,writeEn,reg1address,reg1output,reg2address,reg2output,reg2input,writeEn2,bit16Debug,directOutput);

input clk;

input [7:0]reg1input;
input [7:0]reg2input;
input writeEn,writeEn2;
input [4:0]reg1address;
output [7:0]reg1output;

input [4:0]reg2address;
output [7:0]reg2output;

reg [7:0]regs[32];

output [255:0]directOutput;


assign directOutput={regs[0],regs[1],regs[2],regs[3],regs[4],regs[5],regs[6],regs[7],regs[8],regs[9],regs[10],
							regs[11],regs[12],regs[13],regs[14],regs[15],regs[16],regs[17],regs[18],regs[19],regs[20],
							regs[21],regs[22],regs[23],regs[24],regs[25],regs[26],regs[27],regs[28],regs[29],regs[30],
							regs[31]};

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