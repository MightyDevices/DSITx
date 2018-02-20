/* simple power on reset module */
module reset (
	/* clock */
	input wire clk,
	/* reset */
	output reg rst
) /* synthesis GSR=ENABLED */;

/* reset counter */
reg [1:0] cnt = 0;

/* logic */
always @ (posedge clk)
begin
	/* reset counter */
	if (cnt != 2'b11) begin
		/* increment reset */
		cnt <= cnt + 1'b1;
		/* keep the reset signal asserted */
		rst <= 1'b1;
	/* release the reset signal */
	end else begin
		rst <= 1'b0;
	end
end

endmodule
