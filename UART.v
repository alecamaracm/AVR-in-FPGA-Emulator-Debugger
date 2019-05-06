module UART (output reg[7:0]outputData,output reg newData,input RXiN,input clk);
	
localparam pulses115200=434;
localparam pulses115200With5=651;
localparam pulses115200With52=100; //Wait after the stop bit 

localparam pulses9600=5208;
localparam pulses9600With5=7812;
localparam pulses9600With52=2500; //Wait after the stop bit 

reg[3:0]state;

localparam waiting=4'd0,data=4'd1;

reg[15:0]timeForNextBit;

reg[7:0]dataBitCounter;

reg[7:0]buffer;

wire RX;
assign RX=RXiN;
//SMALLDebouncer deb(clk,RXiN,RX);

	
always@(posedge clk)
begin
		//outputData=state;
	
		case (state)
		
		
			waiting:  //On each tick we look for the incoming signal
			begin
				if(RX==1'b0)
				begin
					state=data;
					timeForNextBit=pulses9600With5; 
					dataBitCounter=0;	
				end
			end
			
			data:				
			begin
				if(timeForNextBit<=0)
				begin
					if(dataBitCounter<=16'd7)
					begin
						buffer[dataBitCounter]=RX;
						dataBitCounter=dataBitCounter+1;
						
						timeForNextBit=pulses9600;
					end
					else if(dataBitCounter==16'd8)
					begin
						if(RX==1'b1)  //Successful stop
						begin
							outputData=buffer;
							newData=!newData;
						end	
						dataBitCounter=dataBitCounter+1;
						timeForNextBit=pulses9600With52;
					end
					else
					begin
						state=waiting;
					end
				end
				else
				begin
					timeForNextBit=timeForNextBit-16'd1;
				end			
			end	
		
		endcase

end


endmodule

