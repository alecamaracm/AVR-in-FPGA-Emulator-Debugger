
module BasicMCUInFPGA(input clk,
							output [15:0]digitalIO,
							output stuck);

assign stuck=(state==STUCK);
//assign digitalIO={3'd0,IOregs[8'd5][5:0],IOregs[8'd11]};
					//assign digitalIO={readedByte1};		
//assign digitalIO={8'd0,OPCODE};	
assign digitalIO={PC};	
				
				
//Register file
reg [7:0]reg1input;
reg writeEn;
reg [4:0]reg1address;
wire [7:0]reg1output;

reg [7:0]reg2address;
wire [7:0]reg2output;

reg [7:0]SREG;

reg [13:0]SP;
reg [13:0]RA;

reg [15:0]PC;

reg [7:0]IOregs[63];


//Flash
wire [13:0]flash_addr_1;
wire [13:0]flash_addr_2;

wire [15:0]flash_dataIN_1;
wire [15:0]flash_dataIN_2;
wire flash_WRen_1;
wire flash_WRen_2;
assign flash_WRen_1=0;
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
parameter FETCH=4'd0,WORK1=4'd1,WORK2=4'd2,WORK3=4'd3,STUCK=4'd4;

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
eor=8'd8;


instructionSelector selector(readedByte1,OPCODE);





registerFile regFile(clk,reg1input,writeEn,reg1address,reg1output,reg2address,reg2output);

FLASH flash(PC,PC+1,clk,flash_dataIN_1,flash_dataIN_2,flash_WRen_1,flash_WRen_2,flash_out_1,flash_out_2);
//FLASH flash(0,1,clk,flash_dataIN_1,flash_dataIN_2,flash_WRen_1,flash_WRen_2,flash_out_1,flash_out_2);

RAM ram(ram_address,clk,ram_inputData,ram_WRen,ram_outputData);



always @(posedge clk)
begin

	case (state)
				
		FETCH:
		begin
			readedByte1={flash_out_1[7:0],flash_out_1[15:8]}; //Read PC
			readedByte2={flash_out_2[7:0],flash_out_2[15:8]}; //Read PC+1 (For 32bit instructions
			state=WORK1; //Set the state to work
		end
		
		WORK1:
		begin
			
			case (OPCODE)
				ldi: 
				begin
					reg1address=5'd16+readedByte1[7:4]; //Calculates the register to write the info to
					reg1input={readedByte1[11:8],readedByte1[3:0]};
					writeEn=1'b1; 
					//Go to next state now,while the value is being stored
				end
				
				
				jmp:
				begin
					PC={readedByte1[8:4],readedByte1[0],readedByte2[15:0]}; //Set new value for PC
					state=STUCK; //FETCH new instruction
				end
				
				
				call:
				begin
					//Store to the stack the next address										
					ram_address=SP; //Store the next instruction into the address
					PC=PC+16'd2; //Sets the PC to the next instruction, to save to the stack this value
					ram_inputData=PC[15:8]; //Save the most significant digits to the first stack
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
					SP=SP+14'd2; //Increment the stack by 2
					ram_WRen=1'b0; //Make sure we are not writing
					ram_address=SP; //Set the stack address to read
					//Waits for the ram to provide the data
				end
			
				
				cli:
				begin
					SREG[7]=1'b0;  //Disable interrupt pin
					PC=PC+16'd1;
					state=FETCH;
				end
			
				rjmp:
				begin
					PC=PC+({readedByte1[11],readedByte1[11],readedByte1[11],readedByte1[11],readedByte1[11:0]})+16'd1;  //Jump to the sign extended offset +1
					state=FETCH;
				end
				
				eor:
				begin
				
					writeEn=1'b0;  //Make sure we are not writing
					
					reg1address=readedByte2[8:4]; //Read r1
					reg2address={readedByte1[9],readedByte1[3:0]}; //Read r2

					//Wait just in case for the register file
				end
				
				error:
				begin
					state=STUCK; //OPCODE not defined
				end
				
				default:
				begin
					state=STUCK; //Uknown OPCODE
				end
				
			endcase
			
			//if(state==WORK1) state=WORK2; //If the state has not been controlled, go to next state		
		end
		
		WORK2:
		begin
		
			case (OPCODE)
				ldi: 
				begin					
					//The value should be stored now,finish the instruction
					writeEn=1'b0; //Disable the writeEnable for the register file
					PC=PC+16'd1;
					state=FETCH; //Go to the next instruction
				end	
				
				call:
				begin
					//Store to the stack the next address										
					ram_address=SP-14'b1; //Store the next instruction into the address				
					ram_inputData=PC[7:0]; //Save the LEAST significant digits to the first stack
					ram_WRen=1'b1;
					//Go to the next state by default, while the data2 is stored				
				end
				
				
				out:
				begin
					IOregs[{readedByte1[10:9],readedByte1[3:0]}]=reg1output;  //Set the right IO register to the data in the register file output
					PC=PC+16'd1;
					state=FETCH; //Go to the next instruction
				end
				
				ret:
				begin
					PC[15:8]=ram_outputData; //Set the MSB of the PC to the data from the stack
					ram_address=SP-14'b1; //Read the LSB part
					//Wait until the LSB part can be read
				end	
				
				eor:
				begin
				   reg1input=reg1output^reg2output; //Do the xor operation and store it in the first register					
					writeEn=1'b1; //Enable the writing
					//Wait for the write
				end
							
			endcase
			
		//	if(state==WORK2) state=WORK3; //If the state has not been controlled, go to next state		
		end
		
		WORK3:
		begin
			case (OPCODE)
			
				call:
				begin		
					ram_WRen=1'd0;  //Stop writing to the ram
					PC={readedByte1[8:4],readedByte1[0],readedByte2[15:0]};  //Go to the address in the instruction
					
					SP=SP-14'd2; //Decrease the stack pointer by 2 (Its is a postdecrement)
					state=FETCH; //Finished, go on with the execution					
				end
				
				ret:
				begin
					PC[7:0]=ram_outputData; //Set the MSB of the PC to the data from the stack
					state=FETCH; //Finished, go on with the execution				
				end
				
				eor:
				begin
					writeEn=1'b0; //Disable writing to the register file
					SREG[3]=1'b0;
					SREG[2]=reg1input[7];					
					SREG[1]=(reg1input==8'b0);					
					PC=PC+16'd1;
					state=FETCH; //Finished, go on with the execution	
				end
		
			
			endcase
			
			//if(state==WORK3) state=STUCK; //If the state has not been controlled, go to STUCK forever
		end
		
		STUCK:
		begin
			//Stay here until the Wraiths destroy this planet :P
		end
		
	endcase
	
	SREG[4]=SREG[3]^SREG[2]; //Update the XOR in the SREG register
end

endmodule