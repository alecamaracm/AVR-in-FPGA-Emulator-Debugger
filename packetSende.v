module packetSenter(input clk,output TXD,input [7:0]data0,
									input [7:0]data1,
									input [7:0]data2,
									input [7:0]data3,
									input [7:0]data4,
									input [7:0]data5,input count,output complete,output completeInner);
	
	reg [7:0]dataForShifter;
	reg dataCountShifter;
	wire shifterDone;
	outputShifter shifter(clk,TXD,dataForShifter,dataCountShifter,shifterDone);
	
	reg [4:0]packetCount;
	
	reg [3:0]state=waiting;
	
	
	reg lastCount=0;
	
	localparam waiting=4'd0,working=4'd1;
	
	assign complete=(state==waiting);
	assign completeInner=shifterDone;
	
	reg justDid=0;

	always @(posedge clk)
	begin
		
		case (state)
	
		
		working:
		begin
			if(shifterDone==1  && justDid==0)
			begin
				justDid=1;
				if(packetCount<4'd6)
				begin		
		
					if(packetCount==4'd0)
					begin
						dataForShifter=data0;
						packetCount=packetCount+4'd1;
					end
					else if(packetCount==4'd1)
					begin
						dataForShifter=data1;
						packetCount=packetCount+4'd1;
					end
					else if(packetCount==4'd2)
					begin
						dataForShifter=data2;
						packetCount=packetCount+4'd1;
					end
					else if(packetCount==4'd3)
					begin
						dataForShifter=data3;
						packetCount=packetCount+4'd1;
					end
					else if(packetCount==4'd4)
					begin
						dataForShifter=data4;
						packetCount=packetCount+4'd1;
					end
					else if(packetCount==4'd5)
					begin
						dataForShifter=data5;
						packetCount=packetCount+4'd1;
					end
					
					
					dataCountShifter=!dataCountShifter;
				end
				else
				begin
					state=waiting;
				end
			end
			else
			begin
				justDid=0;
			end
		end
		
		default:
		begin
			if(lastCount!=count)
			begin
				lastCount=count;
				if(state==waiting)
				begin
					state=working;
					packetCount=4'd0;
				end
			end
		end
		
		endcase
		
	
	end

endmodule