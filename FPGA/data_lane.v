/* data lane */
module data_lane (
	/* byte clock */
	input wire byte_clk, 
	/* bit clock: 4x byte clock */
	input wire bit_clk, 
	/* reset signals */
	input wire byte_rst, bit_rst,
	
	/* data */
	input wire [7:0] data,
	/* enable signal (valid data present) */
	input wire enable,
	/* data accepted, active for one byte_clock period */
	output wire ack,
	
	/* clock lane/data lane high-speed mode request */
	input wire hs_req,
	/* hs ready signal */
	output wire hs_rdy, lane_idle,
	
	/* output signals: data lane */
	output wire lp_p, lp_n, hs
);

/* lane states */
localparam LP11 		= 0;
localparam LP01 		= 1;
localparam LP00 		= 2;
localparam HS_ZERO 		= 3;
localparam SOT 			= 4;
localparam HS 			= 5;
localparam EOT 			= 6;

/* current state */
reg [2:0] state;
/* delay counter */
reg [2:0] cnt;
/* last bit of the last data word: used for terminating transmission */
reg last_bit;

/* multi-bit interconnections */
wire [7:0] ser_data;

/* synchronous logic */
always @ (posedge byte_clk or posedge byte_rst)
begin
	/* reset */
	if (byte_rst) begin
		state <= LP11; cnt <= 0; last_bit <= 0;
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
				state <= SOT;
		end
		/* send sot */
		SOT : begin
			state <= HS;
		end
		/* high speed transmission */
		HS : begin
			/* store last bit for eot generation */
			if (enable)
				last_bit <= data[7];
			/* no more data & hs request */
			else if (!hs_req)
				state <= EOT;
		end
		/* eot - final data lane transition */
		EOT : begin
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
/* serializer data */
assign ser_data = (state == SOT) ? 8'hB8 :
				  (state == HS) ? data :
				  (state == EOT) ? { (8) { ~last_bit } } :
				  8'h00;
/* serializer enable */
assign ser_enable = ((state == HS) & enable) | (state == SOT) | (state == EOT);
/* high speed ready signal */
assign hs_rdy = (state == HS);
/* ack signal */
assign ack = ((state == HS) & enable);
/* lane idle signal */
assign lane_idle = (state == LP11);

/* data serializer */
data_hs_phy data_hs_phy_i ( 
	/* clocks */
	.byte_clk(byte_clk), .bit_clk(bit_clk),
	/* reset signal */
	.byte_rst(byte_rst), .bit_rst(bit_rst),
	/* data interface */
	.data(ser_data), .enable(ser_enable), .hi_z(ser_hi_z),
	/* high speed output */
	.out(hs)
);

endmodule