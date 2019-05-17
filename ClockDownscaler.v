module slowClock(clk, clk_out,downScale);

input clk;
output clk_out;
input [31:0]downScale;

reg [31:0] counter;
reg clk_out = 40'b0;


always@(posedge clk)
begin
	counter <= counter + 1;
	if (counter >= downScale)     //
	 begin
		  counter <= 0;
		  clk_out <= ~clk_out;
	 end
end
endmodule   