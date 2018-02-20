/* simple uart transmitter */
module uart_tx (
	/* baudrate clock x4, reset */
	input wire baud_clk, rst,
	
	/* output */
	output reg txd,
	
	/* data bus */
	input wire [7:0] data,
	/* send request */
	input wire req,
	/* send complete */
	output reg ack
);

/* sample counter */
reg [5:0] smpl_cnt;
/* shift register */
reg [9:0] sr;
/* busy register */
reg busy;

/* synchronous logic */
always @ (posedge baud_clk or posedge rst)
begin
	/* reset logic */
	if (rst) begin
		/* space for data byte, start and stop bit */
		sr <= 10'b1_11111111_1;
		smpl_cnt <= 0; busy <= 0;
		txd <= 1'b1; ack <= 0;
	/* normal operation */
	end else begin
		/* clear ack flag */
		ack <= 1'b0;
		
		/* increment sample counter */
		smpl_cnt <= busy ? smpl_cnt + 1'b1 : 0;
		
		/* time to shift bit */
		if (smpl_cnt[1:0] == 2'b11) begin
			/* so shift the bit */
			sr <= {1'b1, sr[9:1]};
			/* end of byte? */
			if (smpl_cnt[5:2] == 4'd8)
				busy <= 1'b0;
		end
			
		/* got bus request? */
		if (~busy & req) begin
			sr <= {1'b1, data, 1'b0};
			busy <= 1'b1; ack <= 1'b1;
		end
		
		/* set output line state */
		txd <= sr[0];
	end
end


endmodule