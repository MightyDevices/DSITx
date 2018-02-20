`timescale 1 ns / 1 ns

module top_tb;
	
/* clock */
reg clk;
/* rxd line */
reg rxd;
/* wires */
wire [7:0] uart_rx_data, slip_rx_dout;
/* data size */
localparam MSG_SIZE = 4;
/* message */
reg [MSG_SIZE * 8 - 1 : 0] message = {
	8'hc0, 8'hdb, 8'hdc, 8'hc0
};

/* power on reset */
PUR PUR_INST(.PUR(1'b1));
/* global set reset */
GSR GSR_INST(.GSR(1'b1));

/* power on reset counter */
reset reset_i (.clk(clk), .rst(rst));

/* uart interface: 130kbouds */
uart_rx # (.BDIV(4)) uart_rx_i(
	/* clock line */
	.clk(clk), .rst(rst),
	/* input line */
	.rxd(rxd), 
	/* received data */
	.data(uart_rx_data), .rdy(uart_rx_rdy), .ack(1'b1)
);

/* slip receiver */
slip_rx slip_rx_i(
	/* clock line */
	.clk(clk), .rst(rst),
	/* decoded data for mipi block */
	.frame(slip_rx_frame), .dout(slip_rx_dout), .dout_rdy(slip_rx_dout_rdy), 
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
	
/* integers */
integer i = 0;

/* send byte on serial bus (baudrate set by bdiv) */
task send_byte;
	/* byte value */
	input [7:0] x;
	/* delay controlling baudrate */
	input integer delay;
begin
	#(delay) rxd = 1'b0;     /* start bit */
	#(delay) rxd = x[0];     /* 1 */
	#(delay) rxd = x[1];     /* 2 */
	#(delay) rxd = x[2];     /* 3 */
	#(delay) rxd = x[3];     /* 4 */
	#(delay) rxd = x[4];     /* 5 */
	#(delay) rxd = x[5];     /* 6 */
	#(delay) rxd = x[6];     /* 7 */
	#(delay) rxd = x[7];     /* 8 */
	#(delay) rxd = 1'b1;     /* end bit */
end
endtask

initial
begin
	/* initial conditions */
	clk = 0; rxd = 1;
	/* wait for reset sequence to complete */
	wait (!rst);
	/* produce message on rxd line */
	for (i = MSG_SIZE - 1; i >= 0; i = i - 1)
		send_byte(message[8*(i) +: 8], 32);

	/* end simulation after this delay */
	#5000;
	
	/* end simulation */
	$finish;
end

/* toggle clock */
always #1 clk = !clk;

endmodule