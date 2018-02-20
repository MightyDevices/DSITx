/* simple uart receiver */
module uart_rx (
	/* baudrate clock x4, reset */
	input wire baud_clk, rst,
	
	/* rxd line */
	input wire rxd,
	
	/* output data */
	output reg [7:0] data,
	/* output data ready */
	output reg rdy,
	/* data ack */
	input wire ack
);

/* samples counter (8 bits * 4smpls per bit)*/
reg [5:0] smpl_cnt;
/* samples */
reg [2:0] samples;
/* shift register */
reg [8:0] sr;
/* during byte reception? */
reg busy;

/* start condition detected */
wire start_detected = ~samples[2];
/* one detected */
wire one_detected = samples[1];

/* synchronous logic */
always @ (posedge baud_clk or posedge rst)
begin
	/* reset logic */
	if (rst) begin
		/* bring all to the initial values */
		samples <= 3'h7; smpl_cnt <= 0;
		busy <= 0; rdy <= 0; sr <= 0;
	/* normal operation */
	end else begin
		/* clear ready flag after byte has been read */
		if (ack)
			rdy <= 1'b0;
		
		/* sample rxd */
		samples <= {samples[1:0], rxd};
		/* got start bit? */
		if (start_detected)
			busy <= 1'b1;
		
		/* start bit found, start counting bits */
		smpl_cnt <= busy ? smpl_cnt + 1'b1 : 5'd0;
		
		/* got whole bit sampled? */
		if (smpl_cnt[1:0] == 2'b11) begin
			/* shift register */
			sr <= {one_detected, sr[8:1]};
			/* store data in output register */
			if (smpl_cnt[5]) begin
				data <= sr[8:1]; rdy <= 1'b1; busy <= 1'b0;		
			end
		end
	end
end

endmodule