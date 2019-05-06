module PushButton_Debouncer(
    input clk,
    input PB,  
    output reg PB_state   
);

reg PB_sync_0;  always @(posedge clk) PB_sync_0 <= ~PB; 
reg PB_sync_1;  always @(posedge clk) PB_sync_1 <= PB_sync_0;

reg [15:0] PB_cnt;

wire PB_cnt_max = &PB_cnt;	// true when all bits of PB_cnt are 1's

always @(posedge clk)
if(PB_state==PB_sync_1)
    PB_cnt <= 0;  // nothing's going on
else
begin
    PB_cnt <= PB_cnt + 16'd1;  // something's going on, increment the counter
    if(PB_cnt_max) PB_state <= ~PB_state;  // if the counter is maxed out, PB changed!
end

endmodule

module SMALLDebouncer(
    input clk,
    input PB,  
    output reg PB_state   
);

reg PB_sync_0;  always @(posedge clk) PB_sync_0 <= ~PB; 
reg PB_sync_1;  always @(posedge clk) PB_sync_1 <= PB_sync_0;

reg [1:0] PB_cnt;

wire PB_cnt_max = &PB_cnt;	// true when all bits of PB_cnt are 1's

always @(posedge clk)
if(PB_state==PB_sync_1)
    PB_cnt <= 0;  // nothing's going on
else
begin
    PB_cnt <= PB_cnt + 16'd1;  // something's going on, increment the counter
    if(PB_cnt_max) PB_state <= ~PB_state;  // if the counter is maxed out, PB changed!
end

endmodule