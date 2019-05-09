module slowClock(clk, clk_out);

input clk;
output clk_out;

reg [39:0] counter;
reg clk_out = 40'b0;


always@(posedge clk)
begin
	counter <= counter + 1;
	if (counter == 40'd1_000_000)     //
	 begin
		  counter <= 0;
		  clk_out <= ~clk_out;
	 end
end
endmodule   