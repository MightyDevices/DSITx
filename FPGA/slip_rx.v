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
reg [1:0] state;
/* buffered version of data */
reg [7:0] din_buf;

/* synchronous logic */
always @ (posedge clk or posedge rst)
begin
	/* reset logic */
	if (rst) begin
		state <= SOF; frame <= 1'b0;
		dout_rdy <= 0; dout <= 0;
	/* normal operation */
	end else begin
		/* clear flag */
		if (dout_ack)
			dout_rdy <= 1'b0;
			
		/* time to process data? */
		if (din_rdy) begin
			/* slip state machine */
			case (state)
			/* wait for sof */
			SOF : begin
				dout <= din; 
				/* start of frame received */
				if (din == CHAR_END)
					state <= READ;
			end
			/* normal operation */
			READ : begin
				dout <= din; 
				/* got ending character? */
				if (din == CHAR_END) begin
					/* prevent multiple consecutive 0xc0 */
					if (frame) begin
						frame <= 1'b0; state <= SOF;
					end
				/* normal decoding */
				end else begin
					/* we are now in the middle of the frame */
					frame <= 1'b1;
					/* got an escape character? */
					if (din == CHAR_ESC) begin
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
				dout <= din == CHAR_ESC_END ? CHAR_END : CHAR_ESC;
				/* go back to 'normal' data reading */
				state <= READ; dout_rdy <= 1'b1;
			end
			endcase
		end
	end
end

endmodule