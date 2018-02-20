/* clock lane */
module clock_lane (
	/* byte clock */
	input wire byte_clk, 
	/* bit clock: 4x byte clock */
	input wire bit_clk, 
	/* reset signal */
	input wire byte_rst, bit_rst,
	
	/* generate clock (valid data present) */
	input wire enable,
	
	/* clock lane/data lane high-speed mode request */
	input wire hs_req,
	/* hs ready signal, lane idle signal */
	output wire hs_rdy, lane_idle,
	
	/* output signals: clock lane */
	output wire lp_p, lp_n, hs
);

/* lane states */
localparam LP11 		= 0;
localparam LP01 		= 1;
localparam LP00 		= 2;
localparam HS_ZERO 		= 3;
localparam PRE			= 4;
localparam HS 			= 5;
localparam POST			= 6;
localparam EOT			= 7;

/* current state */
reg [2:0] state;
/* delay counter */
reg [2:0] cnt;

/* synchronous logic */
always @ (posedge byte_clk or posedge byte_rst)
begin
	/* reset */
	if (byte_rst) begin
		state <= LP11; cnt <= 0;
	/* normal operation */
	end else begin
		/* lane drive state machine */
		case (state)
		/* wait for high speed request */
		LP11 : begin
			if (hs_req)
				state <= LP01;
		end
		/* transition into 01 */
		LP01 : begin
			state <= LP00;
		end
		/* transition into 00 */
		LP00 : begin
			state <= HS_ZERO;
		end
		/* send zeros on the bus */
		HS_ZERO : begin
			/* done waiting? */
			cnt <= cnt + 1'b1;
			if (cnt == 3'b111)
				state <= PRE;
		end
		/* generate clock pulses before any data lane is enabled */
		PRE : begin
			/* done waiting? */
			cnt <= cnt + 1'b1;
			if (cnt == 3'b111)
				state <= HS;
		end
		/* high speed transmission */
		HS : begin
			/* no more hs request */
			if (!hs_req)
				state <= POST;
		end
		/* generate clock pulses after data lanes have been disabled */
		POST: begin
			/* done waiting? */
			cnt <= cnt + 1'b1;
			if (cnt == 3'b111)
				state <= EOT;
		end
		/* disable clock toggling so that the rx side can 
		 * detect the clock absence */
		EOT: begin
			/* done waiting? */
			cnt <= cnt + 1'b1;
			if (cnt == 3'b111)
				state <= LP11;
		end
		endcase
	end
end

/* low power signals control */
assign {lp_p, lp_n} = (state == LP11) ? 2'b11 :
					  (state == LP01) ? 2'b01 :
					  2'b00;
/* high speed tri-state control */
assign ser_hi_z = (state == LP11) | (state == LP01) | (state == LP00);
/* enable clock toggling */
assign ser_enable = ((state == HS) & enable) | (state == PRE) | (state == POST);
/* high speed ready signal */
assign hs_rdy = (state == HS);
/* lane idle signal */
assign lane_idle = (state == LP11);

/* data serializer */
clock_hs_phy clock_hs_phy_i (
	/* clocks */
	.byte_clk(byte_clk), .bit_clk(bit_clk),
	/* reset signal */
	.byte_rst(byte_rst), .bit_rst(bit_rst),
	/* data interface */
	.enable(ser_enable), .hi_z(ser_hi_z),
	/* high speed output */
	.out(hs)
);

endmodule