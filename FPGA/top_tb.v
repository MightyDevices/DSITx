`timescale 1 ns / 1 ns

module top_tb;

reg rxd, clk, rst;
wire txd;
/* integers */
integer i = 0, clk_per = 1000 / (2.08);

/* data size */
localparam MSG_SIZE = 7;
/* message to be received */

reg [MSG_SIZE*8-1:0] message = {	
	8'hc0,
	8'hF0,
	8'h19,
	8'hDB,
	8'hDC,
	8'h7F,
	8'hc0
};

/* top module instance */
top dut( .rxd(rxd) );


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
	/* reset */
	rst = 1; #clk_per;
	/* initial conditions */
	rst = 0; clk = 0; rxd = 1;
	#(clk_per*256);
	/* produce message on rxd line */
	for (i = 0; i < MSG_SIZE; i = i + 1)
		send_byte(message[8*(MSG_SIZE-i-1) +: 8], 8*clk_per*4);
	
	/* end simulation after this delay */
	#(481*5000);
	/* end simulation */
	$finish;
end


/* toggle clock */
always #(clk_per / 2) clk = !clk;

endmodule