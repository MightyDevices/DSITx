/* single lane dphy */
module dphy (
	/* byte clock */
	input wire byte_clk, 
	/* bit clock: 4x byte clock */
	input wire bit_clk, 
	/* reset signal */
	input wire byte_rst, bit_rst,

	/* data */
	input wire [7:0] data,
	/* data ready */
	input wire enable,
	/* data accepted */
	output wire ack,
	
	/* high speed mode request */
	input wire c_hs_mode, d_hs_mode,
	
	/* clock lane */
	output wire c_lp_p, c_lp_n, c_hs,
	/* data lane */
	output wire d_lp_p, d_lp_n, d_hs
);

/* clock is always generated when clock hs is requested and there is no interrupt in data stream */
assign c_enable = !(d_hs_rdy) | enable;
/* data enable is taken dire*/
assign d_enable = enable;
/* clock is in high speed mode when it is requested or there is still activity going on data lane */
assign c_hs_req = c_hs_mode | !d_lane_idle;
/* data mode can only be enabled if clock lane is in high speed mode */
assign d_hs_req = d_hs_mode & c_hs_rdy;

/* delay for clock lane */
delay # (.LENGTH(2)) delay_clock_lane (.a(bit_clk), .o(bit_clk_del));

/* clock lane instance */
clock_lane clock_lane_i (
	/* clocks */
	.byte_clk(byte_clk), .bit_clk(bit_clk_del),
	/* reset signal */
	.byte_rst(byte_rst), .bit_rst(bit_rst),
	
	/* enable signal for clock generation */
	.enable(c_enable),
	/* high speed lane control */
	.hs_req(c_hs_req), .hs_rdy(c_hs_rdy), .lane_idle(c_lane_idle),
	/* output signals */
	.lp_p(c_lp_p), .lp_n(c_lp_n), .hs(c_hs)
);

/* data lane instance */
data_lane data_lane_i (
	/* clocks */
	.byte_clk(byte_clk), .bit_clk(bit_clk),
	/* reset signal */
	.byte_rst(byte_rst), .bit_rst(bit_rst),
	
	/* data interface */
	.data(data), .enable(d_enable), .ack(ack),
	/* high speed lane control */
	.hs_req(d_hs_req), .hs_rdy(d_hs_rdy), .lane_idle(d_lane_idle),
	/* output signals */
	.lp_p(d_lp_p), .lp_n(d_lp_n), .hs(d_hs)
);


endmodule