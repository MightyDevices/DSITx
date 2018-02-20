`timescale 1 ns / 1 ns

module mipi_tb;
	
	
/* clock */
reg clk;
/* data input register */
reg [7:0] d_in;
/* data request, bus request */
reg d_req, b_req;

/* additional variables */
integer i;

/* power on reset */
PUR PUR_INST(.PUR(1'b1));
/* global set reset */
GSR GSR_INST(.GSR(1'b1));

/* power on reset counter */
reset reset_i (.clk(clk), .rst(rst));

/* mipi instance */
mipi mipi_i(
	/* quadrature */
	.clk(clk), .rst(rst),
	/* high speed lines */
	.d_hs(d_hs), .c_hs(c_hs),
	/* low speed signals */
	.d_lp_p(d_lp_p), .d_lp_n(d_lp_n),
	.c_lp_p(c_lp_p), .c_lp_n(c_lp_n),
	
	/* data bus interface */
	.d_in(d_in), .d_req(d_req), .b_req(b_req), .d_ack(d_ack)
);

/* initial conditions */
initial
begin
	clk = 0; d_req = 0; b_req = 0; d_in = 0;
	
	/* wait for reset sequence to complete */
	wait (!rst);
	/* start by making bus request */
	b_req = 1;
	
	/* data sending loop */
	for (i = 8'h55; i < 8'h57; i = i + 1) begin
		/* prepare data on the bus */
		d_in = 8'h80; d_req = 1'b1;
		/* wait for the bus ack signal */
		wait(d_ack);
		#10;
		d_req = 0;
	end
	#10;
	/* clear bus request */
	b_req = 0;
	
	/* end simulation after this delay */
	#500;
	/* end simulation */
	$finish;
end

/* toggle clock */
always #1 clk = !clk;
	
endmodule