module outputShifter(input clk,output outputPin,input [7:0]datain,input statex,output done);

localparam pulses9600=5208;
localparam pulses9600With5=7812;
localparam pulses9600With52=2500; //Wait after the stop bit 

localparam pulses115200=434;
localparam pulses115200With5=651;
localparam pulses115200With52=100; //Wait after the stop bit 

reg[3:0]state;
localparam waiting=4'd0,data=4'd2,start=4'd1,stop=4'd3;

reg[31:0]timeForNextBit;
reg[7:0]dataBitCounter;

reg lastState;
assign debug=datain;

reg outputData;
assign outputPin=(state===waiting || state===stop)?1'b1:outputData;

assign done=(state==waiting);


	
always@(posedge clk)
begin
	
		case (state)	
			waiting: 
			begin
				if(lastState!=statex)
				begin
					lastState=statex;
					state=start;
					timeForNextBit=pulses115200; 
					dataBitCounter=0;	
					outputData=0;
				end
			end
			
			start:				
			begin
				outputData=0;
				if(timeForNextBit<=0)
				begin				
					state=data;				
				end
				else
				begin
					timeForNextBit=timeForNextBit-32'd1;
				end			
			end	
			
			data:				
			begin
				if(timeForNextBit<=0)
				begin
					if(dataBitCounter<=16'd7)
					begin					
						outputData=datain[dataBitCounter];
						dataBitCounter=dataBitCounter+1;						
						timeForNextBit=pulses115200;						
					end
					else if(dataBitCounter==16'd8)
					begin	
						state=stop;
						timeForNextBit=pulses115200; 
					end
				end
				else
				begin
					timeForNextBit=timeForNextBit-32'd1;
				end			
			end	
			
			
			stop:				
			begin				
				if(timeForNextBit<=0)
				begin				
					state=waiting;				
				end
				else
				begin
					timeForNextBit=timeForNextBit-32'd1;
				end			
			end	
		
		endcase

end


endmodule