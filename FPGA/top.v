module top (
	/* receive line */
	input wire rxd, nrst,
	
	/* debug leds */
	output wire [7:0] leds,
	
	/* mipi signals: clock lane & data lane */
	output wire d_lp_n, d_lp_p, d_hs,
	output wire c_lp_n, c_lp_p, c_hs,
	
	/* reset and sync pins */
	output wire reset, sync
);

/* wires */
wire [7:0] uart_rx_data, slip_rx_dout;

/* oscillator */
OSCH # (.NOM_FREQ(33.25)) osch_i (.STDBY(1'b0), .OSC(clk), .SEDSTDBY());
/* global set reset */
GSR GSR_INST(.GSR(nrst));

/* power on reset counter */
reset reset_i (.clk(clk), .rst(rst));

/* uart interface: 4.160Mbauds, 8N1 */
uart_rx # (.BDIV(2)) uart_rx_i(
	/* clock line, reset line  */
	.clk(clk), .rst(rst),
	/* input line */
	.rxd(rxd), 
	/* received data */
	.data(uart_rx_data), .rdy(uart_rx_rdy), .ack(1'b1)
);

/* slip receiver */
slip_rx slip_rx_i(
	/* clock line, reset line */
	.clk(clk), .rst(rst),
	/* decoded data for mipi block */
	.frame(slip_rx_frame), .dout(slip_rx_dout), .dout_rdy(slip_rx_dout_rdy),
	/* we do not use the ack */
	.dout_ack(mipi_d_ack),
	/* encoded data from uart receiver */
	.din(uart_rx_data), .din_rdy(uart_rx_rdy)
);

/* mipi instance */
mipi mipi_i(
	/* quadrature clocks */
	.clk(clk), .rst(rst),
	/* high speed lines */
	.d_hs(d_hs), .c_hs(c_hs),
	/* low speed signals */
	.d_lp_p(d_lp_p), .d_lp_n(d_lp_n),
	.c_lp_p(c_lp_p), .c_lp_n(c_lp_n),
	
	/* data bus interface */
	.d_in(slip_rx_dout), .d_req(slip_rx_dout_rdy),
	/* data ack */
	.d_ack(mipi_d_ack),
	/* frame signal */
	.b_req(slip_rx_frame)
);

assign leds[7:2] = ~slip_rx_dout[7:2];
assign leds[0] = ~slip_rx_frame;
assign leds[1] = ~slip_rx_dout_rdy;

assign reset = ~rst;
assign sync = 1'bz;

endmodule