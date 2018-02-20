/* top model */
module top (
	/* data signals */
	output wire d_lp_p, d_lp_n, d_hs,
	/* clock lane */
	output wire c_lp_p, c_lp_n, c_hs,
	
	/* uart rx pin */
	input wire rxd,
	/* leds */
	output wire [7:0] leds,
	
	/* reset and sync pins */
	output wire nrst, reset, sync
);

/* multi-bit wires */
wire [7:0] uart_rx_i_data, slip_rx_i_dout, slip_fifo_i_rd_data;

/* oscillator */
OSCH # (.NOM_FREQ(88.67)) osch_i (.STDBY(1'b0), .OSC(clk), .SEDSTDBY());
/* global set reset */
GSR GSR_INST(.GSR(1'b1));
/* power on reset */
PUR PUR_INST(.PUR(1'b1));

/* RESET AND CLOCK PRESCALING */
/* power on reset generator for different domains */
reset reset_clk_i (.clk(clk), .rst(rst));
reset reset_byte_clk_i (.clk(byte_clk), .rst(byte_rst));
reset reset_uart_clk_i (.clk(uart_clk), .rst(uart_rst));

/* byte clock prescaler */
prescaler #(.DIV(4)) prescaler_byte_i(.clk(clk), .rst(rst), .out(byte_clk));
/* uart prescaler */
prescaler #(.DIV(8)) prescaler_uart_i(.clk(clk), .rst(rst), .out(uart_clk));

/* COMMUNICATION */
/* simple uart receiver */
uart_rx uart_rx_i (
	/* clock and reset */
	.baud_clk(uart_clk), .rst(uart_rst), 
	/* input rxd line */
	.rxd(rxd), 
	/* data output */
	.data(uart_rx_i_data), .rdy(uart_rx_i_rdy), .ack(1'b1));
	
/* slip protocol decoder */
slip_rx slip_rx_i (
	/* clock and reset */
	.clk(uart_clk), .rst(uart_rst), 
	/* decoder input */
	.din(uart_rx_i_data), .din_rdy(uart_rx_i_rdy), 
	/* decoder output */
	.dout(slip_rx_i_dout), .dout_rdy(slip_rx_i_dout_rdy), 
	.dout_ack(1'b1), .frame(slip_rx_i_frame)
);

/* DOMAIN CROSSING & BUFFERING */
/* fifo for domain crossing/data storage */
fifo #(.DATA_BITS(8), .ADDR_BITS(1), .ALLOW_OVERFLOW(1)) slip_fifo_i(
	/* write port */
	.wr_clk(uart_clk), .wr_rst(uart_rst), .wr_we(slip_rx_i_dout_rdy), 
	.wr_data(slip_rx_i_dout), .wr_full(), 
	/* read port */
	.rd_clk(byte_clk), .rd_rst(byte_rst), .rd_oe(dphy_i_ack), 
	.rd_data(slip_fifo_i_rd_data), .rd_empty(slip_fifo_i_rd_empty)
);

/* frame signal synchronizer */
sync #(.WIDTH(1), .STAGES(2)) frame_sync_i(
	/* destination domain clock and reset */
	.clk(byte_clk), .rst(byte_rst),
	/* input and output signals */
	.in(slip_rx_i_frame), .out(frame_sync_i_out)
);

/* DPHY (MIPI) LOGIC */
/* data lane */
dphy dphy_i (
	/* clocks & reset */
	.byte_clk(byte_clk), .bit_clk(clk), 
	.byte_rst(byte_rst), .bit_rst(rst),
	/* data interface */
	.data(slip_fifo_i_rd_data), .enable(!slip_fifo_i_rd_empty), 
	.ack(dphy_i_ack),
	/* high speed mode request */
	.c_hs_mode(frame_sync_i_out), .d_hs_mode(frame_sync_i_out),
	/* data lane */
	.d_lp_p(d_lp_p), .d_lp_n(d_lp_n), .d_hs(d_hs),
	/* clock lane */
	.c_lp_p(c_lp_p), .c_lp_n(c_lp_n), .c_hs(c_hs)
);
/* tie uart data to leds for activity monitoring */
assign leds = uart_rx_i_data;
	
/* tie lcd rst to system reset */
assign reset = ~rst;
/* we do not use lcd sync output */
assign sync = 1'bz;

endmodule