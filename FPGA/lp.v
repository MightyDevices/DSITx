module lp (
	/* clock */
	input wire clk, rst,
	
	/* outputs: low speed */
	output reg lp_p, lp_n,
	/* high speed request */
	input wire hs_req,
	/* high speed ready */
	output reg hs_rdy
);

/* state machine states */
localparam LP11 	= 3'h0;
localparam LP01 	= 3'h1;
localparam LP00 	= 3'h2;
localparam HS		= 3'h3;		
localparam HS_END	= 3'h4;

/* delay counter */
reg [3:0] delay_cnt;
/* current state */
reg [2:0] state;

/* sync logic */
always @ (posedge clk or posedge rst)
begin
	/* reset logic */
	if (rst) begin
		delay_cnt <= 4'hF;
		state <= LP11;
		lp_p <= 1; lp_n <= 1;
		hs_rdy <= 0;
	/* normal operation */	
	end else begin
		/* do the counting */
		delay_cnt <= delay_cnt - 1'b1;

		/* state machine is synced with delay counter */
		if (delay_cnt == 0) begin
			/* switch on current satate */
			case (state)
			/* lines idle? */
			LP11 : begin
				/* high speed transition requested */
				if (hs_req) 
					state <= LP01;
			end
			/* LP01: p low, n high state */
			LP01 : begin
				/* set next state */
				state <= LP00;
				/* bring p line low */
				lp_p <= 1'b0;
			end
			/* wait for rx to turn on lvds termination */
			LP00 : begin
				/* bring n line low */
				lp_n <= 1'b0;
				/* high speed mode ready */
				hs_rdy <= 1'b1;
				/* next state */
				state <= HS;
			end
			/* in high speed mode */
			HS : begin
				/* high speed mode is no longer requested */
				if (~hs_req)
					state <= HS_END;
			end
			/* end high speed mode */
			HS_END : begin
				/* set next state */
				state <= LP11;
				/* reset lp lines */
				lp_p <= 1'b1;
				lp_n <= 1'b1;
				/* clear high speed ready */
				hs_rdy <= 1'b0;
			end
			endcase
	end
	end
end

endmodule