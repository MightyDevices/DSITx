/* clock prescaler */
module prescaler # (
	/* clock divider */
	parameter DIV = 4
)
(
	/* clock reset */
	input wire clk, rst,
	/* output */
	output reg out
);

/* prescaler counter width */
localparam WIDTH = $clog2(DIV);
/* register counter */
reg [WIDTH-1:0] cnt;
/* reload signal */
wire reload = (cnt == (DIV-1));

/* counter logic */
always @ (posedge clk or posedge rst)
begin
	/* reset logic */
	if (rst) begin
		cnt <= 0;
	/* normal operation */
	end else begin
		cnt <= reload ? {(WIDTH){1'b0}} : cnt + 1'b1;
		out <= reload;
	end
end

endmodule