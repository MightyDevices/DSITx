/* generic gray counter */
module gray # (
	/* counter bit width */
	parameter WIDTH = 8
)
(
	/* clock reset enable, signals */
	input wire clk, rst, enable,
	/* gray counter output */
	output reg [WIDTH-1:0] out
);

/* binary counter */
reg [WIDTH-1:0] cnt;
/* used for xor generation */
integer i;

/* synchronous logic */
always @ (posedge clk or posedge rst)
begin
	/* reset */
	if (rst) begin
		out <= 0; cnt <= 1;
	/* normal operation */
	end else if (enable) begin
		/* increment counter */
		cnt <= cnt + 1'b1;
		/* msb mimics the counter */
		out[WIDTH - 1] <= cnt[WIDTH-1];
		/* generate xors */
		for (i = 0; i < WIDTH-1; i = i + 1) 
			out[i] <= cnt[i] ^ cnt[i+1];
	end
end

endmodule