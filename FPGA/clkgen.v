/* clock divider */
module clkgen (
	/* input clock, reset signal */
	input wire clk, rst,
	/* generated clocks */
	output wire clk_div1, clk_div4
) /* synthesis GSR=ENABLED */;

/* prescaler counter */
reg [1:0] cnt;

/* prescaler logic */
always @ (posedge clk or posedge rst)
begin
	/* reset logic */
	if (rst) begin
		cnt <= 2'b10;
	/* count pulses */
	end else begin
		cnt <= cnt + 1'b1;
	end
end

/* assign signals */
assign clk_div1 = clk;
assign clk_div4 = cnt[1];

endmodule