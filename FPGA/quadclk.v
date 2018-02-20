module quadclk (
	/* reset and clock signals */
	input wire clk,
	/* quadrature clock outputs */
	output reg clk_i = 0, clk_q = 0
);

/* in-phase clock */
always @ (posedge clk)
	clk_i <= ~clk_i; 
/* quadrature clock */
always @ (negedge clk)
	clk_q <= clk_i;

endmodule