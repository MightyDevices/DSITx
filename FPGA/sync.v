/* cross domain synchronizer */
module sync # (
	/* bit width of the signal being synchronized */
	parameter WIDTH = 8,
	/* number of stages */
	parameter STAGES = 2
)
(
	/* clock and reset in destination domain */
	input wire clk, rst,
	/* input signal from source domain */
	input wire [WIDTH-1:0] in,
	/* output signal in destination domain */
	output wire [WIDTH-1:0] out
);

/* sync register */
reg [WIDTH-1:0] sync_reg [0:STAGES];
/* integer for sync reg chain generation */
integer i;

/* synchronization */
always @ (posedge clk or posedge rst)
begin
	/* reset logic */
	if (rst) begin
		for (i = 0; i < STAGES; i = i + 1)
			sync_reg[i] <= 0;
	/* normal synchronization */
	end else begin
		/* connect the input */
		sync_reg[0] <= in;
		/* chain sync registers */
		for (i = 1; i < STAGES; i = i + 1)
			sync_reg[i] <= sync_reg[i-1];
	end
end

/* connect the output */
assign out = sync_reg[STAGES - 1];

endmodule