
/*
	Bit 5 in the SREG in NOT implemented (Half carry)

*/

module BasicMCUInFPGA(input clk,
							output [15:0]digitalIO,
							input [7:0]inputs,
							output stuck,
							input butt,
							output [7:0]debug,	
							input RXD,
							input buttProg,
							input reset,
							output progMode,output TXD);

assign stuck=(state==STUCK);

assign progMode=(programmingMode!=4'd0);

//assign digitalIO=(programmingMode==4'd0)?{3'd0,IOregs[8'd5][5:0],IOregs[8'd11]}:8'b10101010;
assign digitalIO={3'd0,IOregs[8'd5][5:0],IOregs[8'd11]};
//assign digitalIO[7:0]=TXdebug;
//assign digitalIO={flash_out_1,flash_out_2};
//assign digitalIO=(buttProg==1'b1)?{flash_out_1}:nextByteProgCounter;
//assign digitalIO={8'd0,OPCODE};	
//assign digitalIO=SETcyclesToDo;
//assign digitalIO={IOregs[62],reg1output};
assign debug={OPCODE[3:0],state};	

reg [31:0]slowDownMax=32'd3000000;



reg[7:0]dataToShiftReal[6];
reg[7:0]dataToShift[6];
reg[7:0]dataToShiftProg[6];

reg shifterStateReal=0;
reg shifterState=0;
reg shifterStateProg=0;

reg lastShifterState=0;
reg lastShifterStateProg=0;

wire TXcomplete;
wire TXIcomplete;

always @(posedge clk)
begin	
	if(lastShifterState!=shifterState)
	begin
		lastShifterState=shifterState;
		if(TXcomplete==1)
		begin
			dataToShiftReal[0]=dataToShift[0];
			dataToShiftReal[1]=dataToShift[1];
			dataToShiftReal[2]=dataToShift[2];
			dataToShiftReal[3]=dataToShift[3];
			dataToShiftReal[4]=dataToShift[4];
			dataToShiftReal[5]=dataToShift[5];
			shifterStateReal=!shifterStateReal;			
		end
	end
	else	
	if(lastShifterStateProg!=shifterStateProg)
	begin
		lastShifterStateProg=shifterStateProg;
		if(TXcomplete==1)
		begin
			dataToShiftReal[0]=dataToShiftProg[0];
			dataToShiftReal[1]=dataToShiftProg[1];
			dataToShiftReal[2]=dataToShiftProg[2];
			dataToShiftReal[3]=dataToShiftProg[3];
			dataToShiftReal[4]=dataToShiftProg[4];
			dataToShiftReal[5]=dataToShiftProg[5];
			shifterStateReal=!shifterStateReal;			
		end
	end
end

packetSenter sender(clk,TXD,dataToShiftReal[0],
									dataToShiftReal[1],
									dataToShiftReal[2],
									dataToShiftReal[3],
									dataToShiftReal[4],
									dataToShiftReal[5],shifterStateReal,TXcomplete,TXIcomplete);

reg[15:0]debugData;
reg [7:0]result;

wire [3:0]regD;
assign regD=readedByte1[7:4];
wire [4:0]regDE;
assign regDE=readedByte1[8:4];

wire [4:0]regRE;
assign regRE={readedByte1[9],readedByte1[3:0]};

wire [7:0]valK;
assign valK={readedByte1[11:8],readedByte1[3:0]};
wire [7:0]valA;
assign valA={readedByte1[10:9],readedByte1[3:0]};
				
				
//Register file
reg [7:0]reg1input;
reg writeEn;
reg [7:0]reg2input;
reg writeEn2;
reg [4:0]reg1address;
wire [7:0]reg1output;

reg [7:0]reg2address;
wire [7:0]reg2output;

reg [7:0]SREG;

reg [15:0]SP;
reg [13:0]RA;

reg [15:0]PC;
wire [15:0]PCPlus2;
assign PCPlus2=PC+16'd2;

reg [7:0]IOregs[64];


//Flash
reg [13:0]flash_addr_1;
reg [13:0]flash_addr_2;

reg [15:0]flash_dataIN_1;
reg [15:0]flash_dataIN_2;
reg flash_WRen_1;
wire flash_WRen_2;

assign flash_WRen_2=0;

wire [15:0]flash_out_1;
wire [15:0]flash_out_2;

//RAM
reg [10:0]ram_address;
reg [7:0]ram_inputData;
wire [7:0]ram_outputData;
reg ram_WRen;



//Working regs
reg [3:0]state;
parameter FETCH=4'd0,FETCH2=4'd1,FETCH3=4'd2,WORK1=4'd3,WORK2=4'd4,WORK3=4'd5,STUCK=4'd6;

reg [15:0]readedByte1;
reg [15:0]readedByte2;

wire [7:0]OPCODE;

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
lsr=8'd43,
sbc=8'd44,
skip1=8'd156,
skip2=8'd157;

wire finalClock;
wire slowclk;

assign finalClock=slowclk;

slowClock cloco(clk, slowclk,slowDownMax);



wire [7:0]readdata;
wire dataCount;
UART prog(readdata,dataCount,RXD,clk);


instructionSelector selector(readedByte1,OPCODE,skipNext);


wire myClock;

PushButton_Debouncer debouncer(slowClock,butt,myClock);

wire [15:0]bit16Debug;

wire [255:0]directOutputX;
wire [7:0]directOutput[32];

assign directOutput[31]=directOutputX[7:0];
assign directOutput[30]=directOutputX[15:8];
assign directOutput[29]=directOutputX[23:16];
assign directOutput[28]=directOutputX[31:24];
assign directOutput[27]=directOutputX[39:32];
assign directOutput[26]=directOutputX[47:40];
assign directOutput[25]=directOutputX[55:48];
assign directOutput[24]=directOutputX[63:56];
assign directOutput[23]=directOutputX[71:64];
assign directOutput[22]=directOutputX[79:72];
assign directOutput[21]=directOutputX[87:80];
assign directOutput[20]=directOutputX[95:88];
assign directOutput[19]=directOutputX[103:96];
assign directOutput[18]=directOutputX[111:104];
assign directOutput[17]=directOutputX[119:112];
assign directOutput[16]=directOutputX[127:120];
assign directOutput[15]=directOutputX[135:128];
assign directOutput[14]=directOutputX[143:136];
assign directOutput[13]=directOutputX[151:144];
assign directOutput[12]=directOutputX[159:152];
assign directOutput[11]=directOutputX[167:160];
assign directOutput[10]=directOutputX[175:168];
assign directOutput[9]=directOutputX[183:176];
assign directOutput[8]=directOutputX[191:184];
assign directOutput[7]=directOutputX[199:192];
assign directOutput[6]=directOutputX[207:200];
assign directOutput[5]=directOutputX[215:208];
assign directOutput[4]=directOutputX[223:216];
assign directOutput[3]=directOutputX[231:224];
assign directOutput[2]=directOutputX[239:232];
assign directOutput[1]=directOutputX[247:240];
assign directOutput[0]=directOutputX[255:248];

registerFile regFile(clk,reg1input,writeEn,reg1address,reg1output,reg2address,reg2output,reg2input,writeEn2,bit16Debug,directOutputX);
reg [15:0]resultWord;

FLASH flash((programmingMode==4'd0)?PC:flash_addr_1,PC+1,clk,flash_dataIN_1,flash_dataIN_2,(programmingMode==4'd0)?0:flash_WRen_1,flash_WRen_2,flash_out_1,flash_out_2);
//FLASH flash(PC,PC+1,finalClock,flash_dataIN_1,flash_dataIN_2,flash_WRen_1,flash_WRen_2,flash_out_1,flash_out_2);


RAM ram(ram_address,clk,ram_inputData,ram_WRen,ram_outputData);

reg [3:0]programmingMode;
reg [7:0]cyclesToDo=0;

reg skipNext=1'b0;
reg hasToStopNextFETCH=0;


always @(posedge finalClock)
begin
	
	if(copyVars==1)
	begin
		copied=1;
		IOregs[8'd11]=IO11;
	end
	else
	begin
		copied=0;
	end	
	
	if(toReset==1)
	begin
		reseted=1;		
		PC=0;
		SP=0;
		SREG=0;
		state=FETCH;
		IOregs[8'd5]=0;
		IOregs[8'd11]=0;
	end
	else
	begin
		reseted=0;
	end
	
	if(SETcyclesToDo>0)
	begin
		cyclesToDo=cyclesToDo+SETcyclesToDo;
		gotCycles=1;
	end
	else
	begin
		gotCycles=0;
	end
	
	
		
			
	if(programmingMode==4'd0 && (debugging==0 || cyclesToDo>0)) 
	begin
	
		if(cyclesToDo>0)cyclesToDo=cyclesToDo-1;
	
		case (state)
				
		FETCH:
		begin
			//Wait for the RAM to output the data	
			//lsr
			//if(PC!=17'hac/2)state=FETCH2;
			
				state=FETCH2;
			
		
			
		
			writeEn=1'b0;
			writeEn2=1'b0;
			ram_WRen=1'b0;
		end
		
		FETCH2:
		begin
			readedByte1={flash_out_1[7:0],flash_out_1[15:8]}; //Read PC
			readedByte2={flash_out_2[7:0],flash_out_2[15:8]}; //Read PC+1 (For 32bit instructions
			//state=WORK1; //Set the state to work
		//	PC=PC+1;
			state=FETCH3;
		end
		
		FETCH3:
		begin //The instructionSelector does its job in this tick
			state=WORK1;
		end
		
		WORK1:
		begin
			
			case (OPCODE)
				ldi: 
				begin
					reg1address=5'd16+regD; //Calculates the register to write the info to
					reg1input=valK;
					writeEn=1'b1; 
					//Go to next state now,while the value is being stored
				end
				
				
				jmp:
				begin
					PC={readedByte2[15:0]}; //Set new value for PC (We are not using the full 32 bit as the datasheet seys (we don't need it for the ATMega328P
				end
				
				
				call:
				begin
					//Store to the stack the next address										
					ram_address=SP; //Store the next instruction into the address					
					ram_inputData=PCPlus2[15:8]; //Save the most significant digits to the first stack
					ram_WRen=1'b1;
					//Go to the next state by default, while the data1 is stored
				end
				
				
				out:
				begin
					writeEn=1'b0; //Just in case, we sent writeEn to 0
					reg1address=readedByte1[8:4]; //Request the data in the register file stored in the register we want

					//Wait just in case the register file taskes 1 cycle to output the data
				end
				
				ret:
				begin
					SP=SP+2;
					ram_WRen=1'b0; //Make sure we are not writing
					ram_address=SP; //Set the stack address to read
					//Waits for the ram to provide the data
					state=WORK2;
				end
			
				
				cli:
				begin
					SREG[7]=1'b0;  //Disable interrupt pin
					PC=PC+16'd1;
				end
			
				rjmp:
				begin
					PC=PC+({readedByte1[11],readedByte1[11],readedByte1[11],readedByte1[11],readedByte1[11:0]})+16'd1;  //Jump to the sign extended offset +1
				end
				
				eor:
				begin				
					writeEn=1'b0;  //Make sure we are not writing					
					reg1address=readedByte2[8:4]; //Read r1
					reg2address={readedByte1[9],readedByte1[3:0]}; //Read r2
					//Wait just in case for the register file
				end
				
				
				subi:
				begin
					writeEn=1'b0; //We are reading 
					reg1address=5'd16+regD;  //Register we are substracing from and to (16-32)
					//Wait until next cycle for the output
				end
				
				sbci:
				begin
					writeEn=1'b0; //We are reading 
					reg1address=5'd16+regD;  //Register we are substracing from and to (16-32)
					//Wait until next cycle for the output
				end
				
				brne:
				begin
					if(SREG[1]==1'b0) //If the zero flag is NOT set (Not equal), branch
					begin
						PC=PC+({readedByte1[9],readedByte1[9],readedByte1[9],readedByte1[9],readedByte1[9],readedByte1[9],readedByte1[9],readedByte1[9],readedByte1[9],readedByte1[9:3]})+16'd1;  //Jump to the sign extended offset +1				
					end
					else
					begin
						PC=PC+16'd1;
					end				
				end
				
				nop:
				begin
					
				end	
				
				cpi:
				begin
					writeEn=1'b0; //We are reading 
					reg1address=5'd16+regD;  //Register we are substracing from and to (16-32)
				end
				
				cpc:
				begin
					writeEn=1'b0; //We are reading 
					reg2address=regDE; 
					reg1address=regRE; 
				end
				
				sei:
				begin
					SREG[7]=1;
					PC=PC+16'd1;	
				end
				
				in:
				begin
					writeEn=1'b1;
					reg1address=regDE;
				//	reg1input=(regDE==6'd11)?inputs:IOregs[valA];
					reg1input=inputs;
				end
				
				ori:
				begin
					writeEn=1'b0; //We are reading 
					reg1address=5'd16+regD; 
				end
				
				lds:
				begin
					ram_WRen=1'b0;
					ram_address=readedByte2;
				end
				
				sts:
				begin
					reg1address=regDE;
					writeEn=1'b0;
				end
				
				breq:
				begin
					if(SREG[1]==1'b1) //If the zero flag is set (equal), branch
					begin
						PC=PC+({readedByte1[9],readedByte1[9],readedByte1[9],readedByte1[9],readedByte1[9],readedByte1[9],readedByte1[9],readedByte1[9],readedByte1[9],readedByte1[9:3]})+16'd1;  //Jump to the sign extended offset +1				
					end
					else
					begin
						PC=PC+16'd1;
					end				
				end
				
				brcc:
				begin
					if(SREG[0]==1'b0) //If the zero flag is set (equal), branch
					begin
						PC=PC+({readedByte1[9],readedByte1[9],readedByte1[9],readedByte1[9],readedByte1[9],readedByte1[9],readedByte1[9],readedByte1[9],readedByte1[9],readedByte1[9:3]})+16'd1;  //Jump to the sign extended offset +1				
					end
					else
					begin
						PC=PC+16'd1;
					end				
				end
				
				andi:
				begin
					writeEn=1'b0; //We are reading 
					reg1address=5'd16+regD; 
				end
				
				push:
				begin
					reg1address=regDE;
					writeEn=1'b0;				
				end
				
				pop:
				begin
					ram_address=SP+1;
					ram_WRen=1'b0;		
					SP=SP+1;							
				end
				
				mov:
				begin
					writeEn=1'b0;
					reg2address=regRE;				
				end
				
				lpmII:
				begin
					writeEn=1'b0;
					reg1address=5'd30; //Low Z
					reg2address=5'd31; //High Z
				end
				
				movw:
				begin
					writeEn=1'b0;
					reg1address={regRE[3:0],1'b0}; //*2 
					reg2address={regRE[3:0],1'b1}; //*2 +1	 		
				end
				
				Xand:
				begin
					writeEn=1'b0;
					reg1address=regRE; 
					reg2address=regDE;
				end
				
				cpse:
				begin
					writeEn=1'b0;
					reg1address=regRE; 
					reg2address=regDE;
				end
				
				skip1:
				begin
					PC=PC+1;
					skipNext=0;
				end
				
				skip2:
				begin
					PC=PC+2;
					skipNext=0;
				end
				
				Xor:
				begin
					writeEn=1'b0;
					reg1address=regRE; 
					reg2address=regDE;
				end
								
				com:
				begin
					writeEn=1'b0;
					reg1address=regDE; 
				end
				
				adiw:
				begin
					writeEn=1'b0;
					reg1address=24+{regDE,1'b0}; 
					reg2address=24+{regDE,1'b1};	
				end
				
				adc:
				begin
					writeEn=1'b0;
					reg1address=regDE;
					reg2address=regRE;
				end
				
				reti:
				begin
					SP=SP+14'd2; //Increment the stack by 2
					ram_WRen=1'b0; //Make sure we are not writing
					ram_address=SP; //Set the stack address to read
					//Waits for the ram to provide the data
					state=WORK2;
				end
				
				add:
				begin
					writeEn=1'b0;
					reg1address=regDE;
					reg2address=regRE;
				end
				
				sbiw:
				begin
					writeEn=1'b0;
					reg1address=24+{regDE,1'b0}; 
					reg2address=24+{regDE,1'b1};	
				end
				
				stX:
				begin
					writeEn=1'b0;
					reg1address=26; 
					reg2address=27;	
				end
				
				stXP:
				begin
					writeEn=1'b0;
					reg1address=26; 
					reg2address=27;	
				end
				
				ldZ:
				begin
					writeEn=1'b0;
					reg1address=30; 
					reg2address=31;	
				end
				
				stZ:
				begin
					writeEn=1'b0;
					reg1address=30; 
					reg2address=31;	
				end
				
			/*	in:
				begin
					writeEn=1'b1;
					reg1address=redDE;
					//Always input from the same register, we only support the board switches
					reg1input=inputs;
				end*/
				
				lsr:
				begin
					writeEn=1'b0;
					reg1address=regDE;
				end
				
				sbc:
				begin
					writeEn=1'b0;
					reg1address=regDE;
					reg2address=regRE;
				end
				
				
				
			endcase
	
			if(OPCODE==error) state=STUCK;
			else if(state!=STUCK)state=WORK2;
			
		end
		
		WORK2:
		begin
		
			case (OPCODE)
				ldi: 
				begin					
					//The value should be stored now,finish the instruction
					writeEn=1'b0; //Disable the writeEnable for the register file
					
					//if(readedByte1!=16'he0b1)
					PC=PC+16'd1;							
				end	
				
				call:
				begin
					//Store to the stack the next address										
					ram_address=SP+14'b1; //Store the next instruction into the address				
					ram_inputData=PCPlus2[7:0]; //Save the LEAST significant digits to the first stack
					ram_WRen=1'b1;
					//Go to the next state by default, while the data2 is stored				
				end
				
				
				out:
				begin
					
					if({readedByte1[10:9],readedByte1[3:0]}==6'b111101)
					begin
						SP[7:0]=reg1output;  //If the IO reg is 61, it is SPl
					end
					else if({readedByte1[10:9],readedByte1[3:0]}==6'b111110)
					begin
						SP[15:8]=reg1output; //If the IO reg is 62, its is SPH
					end
					else if({readedByte1[10:9],readedByte1[3:0]}==6'h8)
					begin
						
						/*dataToShift[0]=8'd32;
						dataToShift[1]=reg1output;	
						shifterState=!shifterState;*/
						//if(PC!=17'hac/2) state=STUCK;
					end
					else
					begin
						IOregs[{readedByte1[10:9],readedByte1[3:0]}]=reg1output;  //Set the right IO register to the data in the register file output						
					end				
					 
					PC=PC+16'd1;		
				end
				
				ret:
				begin
					PC[15:8]=ram_outputData; //Set the MSB of the PC to the data from the stack
					ram_address=SP+11'd1; //Read the LSB part
					//Wait until the LSB part can be read
				end	
				
				eor:
				begin
				   reg1input=reg1output^reg2output; //Do the xor operation and store it in the first register					
					writeEn=1'b1; //Enable the writing
					//Wait for the write
				end
							
			
				subi:
				begin
					//Address should already be set from the last step
					reg1input=reg1output-{readedByte1[11:8],readedByte1[3:0]};
					SREG[3]=(reg1output[7] & !readedByte1[11] & !reg1input[7])|(!reg1output[7] & readedByte1[11] & reg1input[7]);
					SREG[0]= (!reg1output[7] & readedByte1[11])|(readedByte1[11] & reg1input[7])|(reg1input[7] & !reg1output[7]);	

					writeEn=1'b1; 
					//Go to next state now,while the value is being stored
				end
				
				sbci:
				begin
					//Address should already be set from the last step
					reg1input=reg1output-{readedByte1[11:8],readedByte1[3:0]}-SREG[0];
					SREG[3]=(reg1output[7] & !readedByte1[11] & !reg1input[7])|(!reg1output[7] & readedByte1[11] & reg1input[7]);
					SREG[0]= (!reg1output[7] & readedByte1[11])|(readedByte1[11] & reg1input[7])|(reg1input[7] & !reg1output[7]);	
					writeEn=1'b1; 
					//Go to next state now,while the value is being stored
				end		
		
				cpi:
				begin
					result=reg1output-valK;
					SREG[0]=(!reg1output[7]&valK[7])|(reg1output[7]&valK[7]);
					SREG[1]=(result==0);
					SREG[2]=(result[7]);
					SREG[3]=0;
					PC=PC+16'd1;	
				end
				
				cpc:
				begin
					//2 is D, 1 is R
					result=reg2output-reg1output-SREG[0];
					SREG[0]=0;
					SREG[1]=(result==0) & SREG[1];
					SREG[2]=(result[7]);
					SREG[3]=0;
					PC=PC+16'd1;	
				end
				
				in:
				begin
					writeEn=1'b0;
					PC=PC+16'd1;	
				end
				
				ori:
				begin
					writeEn=1'b1;
					reg1input=reg1output|valK;
				end
				
				lds:
				begin
					writeEn=1'b1;
					reg1address=regDE;
					reg1input=ram_outputData;
				end
				
				sts:
				begin
					ram_address=readedByte2;
					ram_inputData=reg1output;
					ram_WRen=1;					
				end
				
				andi:
				begin
					writeEn=1'b1;
					reg1input=reg1output&valK;

				end
				
				push:
				begin
					ram_address=SP; 			
					ram_inputData=reg1output;
					ram_WRen=1'b1;					
				end
				
				pop:
				begin
					writeEn=1'b1;
					reg1address=regDE;
					reg1input=ram_outputData;	
				end
				
				mov:
				begin
					writeEn=1'b1;
					reg1address=regDE;	
					reg1input=reg2output;
				
				end
				
				lpmII:
				begin
					ram_WRen=1'b0;
					ram_address={reg2output,reg1output};					
				end
				
				movw:
				begin
					writeEn=1'b1;
					reg1input=reg1output; 
					
					reg1address={regD,1'b0}; 			
				end
				
				Xand:
				begin
					writeEn=1'b1;
					reg1address=regDE; 
					reg1input=reg1output & reg2output;
				end
				
				cpse:
				begin
					if(reg1output==reg2output)
					begin
						PC=PC+16'd1;	
						skipNext=1;
					end
					else
					begin
						PC=PC+16'd1;	
					end
				end
				
				Xand:
				begin
					writeEn=1'b1;
					reg1address=regDE; 
					reg1input=reg1output | reg2output;
				end
				
				com:
				begin
					writeEn=1'b1;
					reg1address=regDE; 
					reg1input=~reg1output;
				end
				
				adiw:
				begin
					writeEn=1'b1;
					{SREG[0],resultWord}={reg2output,reg1output}+{2'b0,readedByte1[7:6],readedByte1[3:0]};	
					reg1input=resultWord[7:0];
				end
				
				adc:
				begin
					{SREG[0],reg1input}=reg1output+reg2output+SREG[0];
					writeEn=1'b1;
				end
				
				
				reti:
				begin
					PC[7:0]=ram_outputData; //Set the MSB of the PC to the data from the stack
					ram_address=SP-14'b1; //Read the LSB part
					//Wait until the LSB part can be read
				end
				
				add:
				begin
					{SREG[0],reg1input}=reg1output+reg2output;

					writeEn=1'b1;
				end
				
				sbiw:
				begin
					writeEn=1'b1;
					{SREG[0],resultWord}={reg2output,reg1output}-{2'b0,readedByte1[7:6],readedByte1[3:0]};	
					reg1input=resultWord[7:0];
				end
				
				stX:
				begin
					ram_address={reg2output,reg1output};					
					reg1address=regDE;				
				end
				
				stXP:
				begin
					ram_address={reg2output,reg1output};					
					reg1address=regDE;				
				end
				
				ldZ:
				begin
					ram_address={reg2output,reg1output};			
				end
				
				stZ:
				begin
					ram_address={reg2output,reg1output};					
					reg1address=regDE;				
				end
				
				
				/*in:
				begin
					writeEn=1'b0;				
					PC=PC+1;
				end*/
				
				lsr:
				begin
					writeEn=1'b1;
					reg1address=regDE;
					reg1input={1'b0,reg1output[7:1]};
					SREG[0]=reg1output[0];
					
				end
				
				sbc:
				begin
					{reg1input}=reg1output-reg2output-SREG[0];
					
					writeEn=1'b1;
				end
				
				
			endcase			
			
			if(state!=STUCK) state=WORK3;
		end
		
		WORK3:
		begin
			case (OPCODE)
			
				call:
				begin		
					ram_WRen=1'd0;  //Stop writing to the ram
					PC={readedByte1[8:4],readedByte1[0],readedByte2[15:0]};  //Go to the address in the instruction					
					SP=SP-14'd2; //Decrease the stack pointer by 2 (Its is a postdecrement)
					//Finished, go on with the execution					
				end
					
				ret:
				begin
					PC[7:0]=ram_outputData; //Set the MSB of the PC to the data from the stack

					//Finished, go on with the execution				
				end
				
				eor:
				begin
					writeEn=1'b0; //Disable writing to the register file
					SREG[3]=1'b0;
					SREG[2]=reg1input[7];					
					SREG[1]=(reg1input==8'b0);					
					PC=PC+16'd1;
					//Finished, go on with the execution	
				end	
			
				subi:
				begin					
					writeEn=1'b0;  //Disable writing	
					SREG[2]=reg1input[7];					
					SREG[1]=(reg1input==8'b0);	
					
										
					
					
					PC=PC+16'd1;
					//Finished, go on with the execution				
				end
				
				sbci:
				begin					
					writeEn=1'b0;  //Disable writing	
					SREG[2]=reg1input[7];					
					SREG[1]=(reg1input==8'b0) & SREG[1];	 //Keeps the old value unless the result is not 0
					PC=PC+16'd1;
					//Finished, go on with the execution				
				end
				
				nop:
				begin
					PC=PC+16'd1;					
				end
				
				ori:
				begin
					writeEn=1'b0;
					SREG[1]=(reg1input==0);
					SREG[2]=(reg1input[7]);
					SREG[3]=0;
					PC=PC+16'd1;
				end
				
				lds:
				begin
					writeEn=1'b0;
					PC=PC+16'd2;
				end
				
				sts:
				begin
					ram_WRen=0;	
					PC=PC+16'd2;
				end
				
				andi:
				begin
					writeEn=1'b0;
					SREG[1]=(reg1input==0);
					SREG[2]=(reg1input[7]);
					SREG[3]=0;
					

					PC=PC+16'd1;
				end
				
				push:
				begin
					ram_WRen=1'b0;	
					SP=SP-1;
					PC=PC+16'd1;
				end
				
				pop:
				begin
					writeEn=1'b0;
					PC=PC+16'd1;
				end
				
				mov:
				begin
					writeEn=1'b0;
					PC=PC+16'd1;
				end
				
				lpmII:
				begin
					writeEn=1'b1;     //This will automatically be disbaled in the fetch instruction
					reg1input=ram_outputData;					
					PC=PC+16'd1;								
				end
				
				movw:
				begin
					writeEn=1'b1;  //This will automatically be disbaled in the fetch instruction
					reg1input=reg2output; 
					reg1address={regD,1'b1}; 		
					PC=PC+16'd1;		
				end
				
				Xand:
				begin
					writeEn=1'b0;
					SREG[1]=(reg1input==0);
					SREG[2]=(reg1input[7]);
					SREG[3]=0;
					PC=PC+16'd1;		
				end
				
				Xor:
				begin
					writeEn=1'b0;
					SREG[1]=(reg1input==0);
					SREG[2]=(reg1input[7]);
					SREG[3]=0;
					PC=PC+16'd1;		
				end
				
				com:
				begin
					writeEn=1'b0;
					PC=PC+16'd1;
					SREG[1]=(reg1input==0);
					SREG[2]=(reg1input[7]);
					SREG[3]=0;
					SREG[0]=1;
				end
				
				adiw:
				begin
					reg1address=24+{regDE,1'b1};					
					writeEn=1'b1;   //This will automatically be disbaled in the fetch instruction
					reg1input=resultWord[15:8];
					
					SREG[1]=(resultWord==0);
					SREG[2]=(resultWord[15]);
					SREG[3]=0;  //Setting to 0, not bothering to do the calculations.
				   //	SREG[0]=1;  Already set in the calculations
					
					
					PC=PC+16'd1;
				end
				
				adc:
				begin					
					writeEn=1'b0;
					SREG[1]=(reg1input==0);
					SREG[2]=(reg1input[7]);
					SREG[3]=0;  //Setting to 0, not bothering to do the calculations.
					//	SREG[0]=1;  Already set in the calculations
					PC=PC+16'd1;
				end
				
				reti:
				begin
					PC[15:8]=ram_outputData; //Set the MSB of the PC to the data from the stack
					SREG[7]=1;
					//Finished, go on with the execution				
				end
				
				add:
				begin					
					writeEn=1'b0;
					SREG[1]=(reg1input==0);
					SREG[2]=(reg1input[7]);
					SREG[3]=0;  //Setting to 0, not bothering to do the calculations.
					//	SREG[0]=1;  Already set in the calculations
					PC=PC+16'd1;
				end
				
				sbiw:
				begin
					reg1address=24+{regDE,1'b1};					
					writeEn=1'b1;   //This will automatically be disbaled in the fetch instruction
					reg1input=resultWord[15:8];
					
					SREG[1]=(resultWord==0);
					SREG[2]=(resultWord[15]);
					SREG[3]=0;  //Setting to 0, not bothering to do the calculations.
				   //	SREG[0]=1;  Already set in the calculations
					
					
					PC=PC+16'd1;
				end
				
				stX:
				begin				
					ram_inputData=reg1output;					
					ram_WRen=1'b1; //Will be set to false in FETCH		
		
					PC=PC+16'd1;		
				end
				
				stXP:
				begin				
					ram_inputData=reg1output;					
					ram_WRen=1'b1; //Will be set to false in FETCH	
					
					writeEn=1'b1; //Will be set to false in FETCH	
					writeEn2=1'b1; //Will be set to false in FETCH	
					
					reg1address=26; 
					reg2address=27;	
					{reg2input,reg1input}=ram_address+1;
					
					PC=PC+16'd1;
				end
				
				ldZ:
				begin				
					reg1input=ram_outputData;
					reg1address=regDE;
					writeEn=1'b1; //Will be set to false in FETCH	
					PC=PC+16'd1;
				end
				
				stZ:
				begin				
					ram_inputData=reg1output;					
					ram_WRen=1'b1; //Will be set to false in FETCH		
		
					PC=PC+16'd1;		
				end
				
				lsr:
				begin
					writeEn=1'b0;					

					SREG[1]=(reg1input==8'd0);
					SREG[2]=0;
					SREG[3]=SREG[0]^SREG[2];
					PC=PC+16'd1;
				end
				
				sbc:
				begin					
					writeEn=1'b0;
					//SREG[1]=(reg1input==0);
					SREG[2]=(reg1input[7]);
					SREG[3]=0;  //Setting to 0, not bothering to do the calculations.
					//	SREG[0]=1;  Already set in the calculations
					PC=PC+16'd1;
				end
					

			endcase			
			
			if(OPCODE==ret && 0)
			begin
				state=STUCK;
			end
			else
			begin
				state=FETCH;
			end
			
		end
		
		STUCK:
		begin
			//Stay here until the Wraiths destroy this planet :P
		end
		
		endcase
	
		SREG[4]=SREG[3]^SREG[2]; //Update the XOR in the SREG register
		
		IOregs[61]=SP[7:0];   //Update real IO stack registers from the SP that we use
		IOregs[62]=SP[15:8];
		
	
		
	
	end 
end

reg [7:0]IO11=0;
reg copyVars=0;
reg copied=0;

reg reseted=0;
reg toReset=0;

always @(posedge clk)
begin
	
	if(copied)
	begin
		copyVars=0;
	end
	
	if(reseted)
	begin
		toReset=0;
	end
	
	if(gotCycles)
	begin
		SETcyclesToDo=0;
	end
	

	if(programmingMode==4'd0)
	begin
		if(lastRXstate!=dataCount)
		begin
			lastRXstate=dataCount;
			if(readdata==8'd169)
			begin
				programmingMode=4'd1;
				nextByteProgCounter=0;
				timeToExitProgramming=40'd5000000;	
			end
			
			if(readdata==8'd42)
			begin
				programmingMode=4'd2;
				nextByteProgCounter=0;
				timeToExitProgramming=40'd5000000;
				progDetect=4'd0;		
			end				
		end
	end
	else if(programmingMode==4'd1)
	begin			
		if(lastRXstate!=dataCount)
		begin
			timeToExitProgramming=40'd5000000;
			if(nextByteProgCounter%2==0)
			begin
				flash_WRen_1=0;
				flash_dataIN_1[15:8]=readdata;
				flash_addr_1=nextByteProgCounter/2;
			end
			else
			begin
				flash_WRen_1=1;
				flash_dataIN_1[7:0]=readdata;
			end				
			
			
			nextByteProgCounter=nextByteProgCounter+1;
			lastRXstate=dataCount;							
		end
		else 
		begin
			timeToExitProgramming=timeToExitProgramming-1;
			if(timeToExitProgramming<=0)
			begin
				 programmingMode=4'd0;
				 toReset=1;
				flash_WRen_1=0;
			end
		end	
	end
	else if(programmingMode==4'd2)
	begin		
		
		if(progDetect<4'd5)
		begin
			if(lastRXstate!=dataCount)
			begin				
				lastRXstate=dataCount;
				inBuffer[progDetect]=readdata;
				progDetect=progDetect+1;
			end				
		end
		else
		begin
			progDetect=0;			
			programmingMode=0;
			
			case (inBuffer[0])
				8'd6:
				begin //Set output
					IO11=inBuffer[1];
					copyVars=1;					
				end
				
				8'd3:
				begin //Reset
					toReset=1;
				end
				
				8'd4:
				begin //Echo
					if(TXcomplete==1)
					begin					
						dataToShiftProg[0]=8'd4;
						dataToShiftProg[1]=inBuffer[1];
						dataToShiftProg[2]=inBuffer[2];
						dataToShiftProg[3]=inBuffer[3];
						dataToShiftProg[4]=inBuffer[4];
						dataToShiftProg[5]=8'd4;						

						shifterStateProg=!shifterStateProg;			
					end					
				end
				
				8'd5:
				begin //get PC
					if(TXcomplete==1)
					begin		
						dataToShiftProg[0]=42;  //Init message
						dataToShiftProg[1]=8'd5;
						dataToShiftProg[2]=PC[15:8];
						dataToShiftProg[3]=PC[7:0];
						dataToShiftProg[4]=state;
						dataToShiftProg[5]=OPCODE;
											

						shifterStateProg=!shifterStateProg;			
					end					
				end
				
				8'd7:
				begin //Set clock multiplier						
					slowDownMax[7:0]=inBuffer[1];
					slowDownMax[15:8]=inBuffer[2];
					slowDownMax[23:16]=inBuffer[3];
					slowDownMax[31:24]=inBuffer[4];	
				end
				
				8'd8:
				begin //Enter debugging						
					debugging=1;
				end
				
				8'd9:
				begin //Exit debugging					
					debugging=0;
				end
				
				8'd10:
				begin //Add cycle					
					SETcyclesToDo=SETcyclesToDo+1;//inBuffer[1];
				end
				
				8'd11:
				begin //Go until next instruction					
					SETcyclesToDo=SETcyclesToDo+(6-state);//inBuffer[1];
				end
				
				8'd12:
				begin //get RegisterStartingFrom [1]
					if(TXcomplete==1)
					begin		
						dataToShiftProg[0]=42;  //Init message
						dataToShiftProg[1]=8'd12;
						dataToShiftProg[2]=inBuffer[1];
						dataToShiftProg[3]=directOutput[inBuffer[1]];
						dataToShiftProg[4]=directOutput[inBuffer[1]+1];
						dataToShiftProg[5]=directOutput[inBuffer[1]+2];
											

						shifterStateProg=!shifterStateProg;			
					end					
				end
				
				8'd13:
				begin //get IORegsStartingFrom [1]
					if(TXcomplete==1)
					begin		
						dataToShiftProg[0]=42;  //Init message
						dataToShiftProg[1]=8'd13;
						dataToShiftProg[2]=inBuffer[1];
						dataToShiftProg[3]=IOregs[inBuffer[1]];
						dataToShiftProg[4]=IOregs[inBuffer[1]+1];
						dataToShiftProg[5]=IOregs[inBuffer[1]+2];											

						shifterStateProg=!shifterStateProg;			
					end					
				end
				
				8'd14:
				begin //get SP
					if(TXcomplete==1)
					begin		
						dataToShiftProg[0]=42;  //Init message
						dataToShiftProg[1]=8'd14;
						dataToShiftProg[2]=SP[15:8];
						dataToShiftProg[3]=SP[7:0];
						dataToShiftProg[4]=0;
						dataToShiftProg[5]=0;											

						shifterStateProg=!shifterStateProg;			
					end					
				end
				
				8'd15:
				begin //get Flash data
					if(TXcomplete==1)
					begin		
						dataToShiftProg[0]=42;  //Init message
						dataToShiftProg[1]=8'd15;
						dataToShiftProg[2]=readedByte1[15:8];
						dataToShiftProg[3]=readedByte1[7:0];
						dataToShiftProg[4]=readedByte2[15:8];
						dataToShiftProg[5]=readedByte2[7:0];											

						shifterStateProg=!shifterStateProg;			
					end					
				end
				
				
				default:
				begin
				
				end
			endcase
		end
		
	
	end
end


reg [7:0]inBuffer[10];

reg [49:0]nextByteProgCounter;
reg lastRXstate;



reg debugging=0;

reg[7:0]SETcyclesToDo=0;
reg gotCycles=0;

reg [3:0]progDetect;


reg [39:0]timeToExitProgramming;




endmodule