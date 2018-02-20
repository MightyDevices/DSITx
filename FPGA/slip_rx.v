/* slip protocol receiver */
module slip_rx (
	/* clock input, reset input */
	input wire clk, rst,
	
	/* frame signal - set to '1' when in the middle of 
	 * frame processing */
	output reg frame,
	
	/* slip encoded input data */
	input wire [7:0] din,
	/* input data ready signal */
	input wire din_rdy,
	
	/* decoded data output */
	output reg [7:0] dout,
	/* decoded data ready */
	output reg dout_rdy,
	/* decoded data ack */
	input wire dout_ack
);

/* state machine states */
localparam SOF 			= 0;
localparam READ			= 1;
localparam ESC			= 2;

/* special characters */
localparam CHAR_END  	= 8'hC0;
localparam CHAR_ESC		= 8'hDB;
localparam CHAR_ESC_END	= 8'hDC;
localparam CHAR_ESC_ESC = 8'hDD;


/* current state */
reg [1:0] state = SOF;
/* comparison registers, process byte flag */
reg is_end, is_esc, is_esc_end, process_byte;
/* buffered version of data */
reg [7:0] din_buf;

/* synchronous logic */
always @ (posedge clk or posedge rst)
begin
	/* reset asserted? */
	if (rst) begin
		state <= SOF; frame <= 1'b0;
		is_end <= 0; is_esc <= 0; is_esc_end <= 0; 
		process_byte <= 0; din_buf <= 0;
		dout_rdy <= 0; dout <= 0;
	/* normal operation */
	end else begin
		/* store data */
		din_buf <= din;
		/* update byte checkers */
		is_end <= din == CHAR_END;
		is_esc <= din == CHAR_ESC;
		is_esc_end <= din == CHAR_ESC_END;
		/* process flag */
		process_byte <= din_rdy;
		/* clear ready flag after byte has been read */
		if (dout_rdy && dout_ack)
			dout_rdy <= 1'b0;	
		
		/* time to process byte? */
		if (process_byte) begin
			/* slip state machine */
			case (state)
			/* wait for sof */
			SOF : begin
				/* start of frame received */
				if (is_end)
					state <= READ;
			end
			/* normal operation */
			READ : begin
				/* i know that this is nasty, but one shoud read the data as 
				 * soon as rdy is set high */
				dout <= din_buf; 
				/* got ending character? */
				if (is_end) begin
					/* prevent multiple consecutive 0xc0 */
					if (frame) begin
						frame <= 1'b0; state <= SOF;
					end
				/* normal decoding */
				end else begin
					/* we are now in the middle of the frame */
					frame <= 1'b1;
					/* got an escape character? */
					if (is_esc) begin
						state <= ESC;
					/* normal character */
					end else begin
						dout_rdy <= 1'b1;
					end
				end
			end
			/* escape */
			ESC : begin
				/* store decoded character */
				dout <= is_esc_end ? CHAR_END : CHAR_ESC;
				/* go back to 'normal' data reading */
				state <= READ; dout_rdy <= 1'b1;
			end
			endcase
		end
	end
end

endmodule