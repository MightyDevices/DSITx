module uart_rx # (
	/* baudrate divisor */
	parameter BDIV = 1
)
(
	/* system clock, reset */
	input wire clk, rst,
	
	/* rxd line */
	input wire rxd,
	
	/* output data */
	output reg [7:0] data,
	/* output data ready */
	output reg rdy,
	/* data ack */
	input wire ack
);

/* baudrate div times oversampling factor (oversampling is done by 
 * sampling counter) */
localparam BDIV_OV = BDIV * 1;
/* baudrate div counter width */
localparam BDIV_WIDTH = $clog2(BDIV_OV);

/* baudrate div counter */
reg [BDIV_WIDTH : 0] bdiv;
/* baudrate divider reload counter */
wire [BDIV_WIDTH : 0] bdiv_reload = (BDIV_OV) - 2; 
/* tick pulse generated from baudrate counter */
wire tick = bdiv[BDIV_WIDTH];

/* sampling register */
reg [2:0] samples;
/* sample counter (hot one encoded) */
reg [3:0] s_cnt;
/* shift register */
reg [8:0] sr;
/* bit counter (hot one encoded) */
reg [8:0] b_cnt;
/* in the process of byte reception */
reg busy;

/* start condition detected */
wire start_detected = ~samples[2];
/* one detected */
wire one_detected = samples[1];

/* synchronous logic */
always @ (posedge clk or posedge rst)
begin	
	/* reset logic */
	if (rst) begin
		/* bring all to the initial values */
		samples <= 3'h7; s_cnt <= 3'h1; 
		b_cnt <= 8'h1; rdy <= 0;
		bdiv <= 0; busy <= 0;
	/* normal operation */
	end else begin
		/* baudrate counter */
		bdiv <= bdiv[BDIV_WIDTH] ? bdiv_reload : bdiv - 1'b1;
		/* clear ready flag after byte has been read */
		if (rdy && ack)
			rdy <= 1'b0;

		/* sample */
		if (tick) begin
			/* update sample register by sampling rxd line */
			samples <= {samples[1:0], rxd};
			
			/* start condition detected while module was not busy? */
			if (~busy && start_detected)
				busy <= 1'b1;
			
			/* receiving */
			if (busy) begin
				/* counter increment */
				s_cnt <= {s_cnt[2:0], s_cnt[3]};
				/* time to sample data? */
				if (s_cnt[3]) begin
					/* store current bit */
					sr <= {one_detected, sr[8:1]};
					/* update bit counter */
					b_cnt <= {b_cnt[7:0], b_cnt[8]};
					/* end of byte? */
					if (b_cnt[8]) begin
						/* store data in output register */
						data <= sr[8:1]; rdy <= 1'b1; busy <= 1'b0;
					end
				end
			end	
		end
	end
end

endmodule