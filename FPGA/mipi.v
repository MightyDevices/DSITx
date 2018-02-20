module mipi (
	/* clock signal, reset signal*/
	input wire clk, rst,
	
	/* outputs: high speed outputs */
	output wire d_hs, c_hs,	
	/* low speed signalling */
	output wire d_lp_p, d_lp_n, c_lp_p, c_lp_n,
	
	/* data input */
	input wire [7:0] d_in,
	/* data send request signal, bus request signal */
	input wire d_req, b_req,
	/* data was consumed */
	output reg d_ack
);

/* states of local state machine */
localparam IDLE		= 0;
localparam CLK_HS	= 1;
localparam DAT_HS	= 2;
localparam SYNC		= 3;
localparam SEND		= 4;
localparam TOGGLE   = 5;
localparam DAT_LP	= 6;
localparam CLK_LP	= 7;

/* state machine */
reg [2:0] state;
/* bit pair counter */
reg [3:0] bit_cnt;
/* high speed request signals */
reg c_hs_req, d_hs_req, c_hs_tri, d_hs_tri;
/* ddr clock flip flop register */
reg c_ddr_in;
/* ddr data flip flop register */
reg [2:0] d_ddr_in;
/* data input holding register */
reg [7:0] data;
/* data not provided when mipi was expecting? */
reg underrun;
/* quadrature clock */
reg clk_i, clk_q;

/* quadrature clock generation */
/* in-phase clock */
always @ (posedge clk or posedge rst)
	if (rst) clk_i <= 0; else clk_i <= ~clk_i;
/* quadrature clock */
always @ (negedge clk or posedge rst)
	if (rst) clk_q <= 0; else clk_q <= clk_i;

/* logic synced to quadrature clock */
always @ (posedge clk or posedge rst)
begin
	/* reset asserted? */
	if (rst) begin
		state <= IDLE;
		c_hs_req <= 0; d_hs_req <= 0;
		c_hs_tri <= 1; d_hs_tri <= 1;
		bit_cnt <= 1; underrun <= 1;
		c_ddr_in <= 0; d_ddr_in <= 0;
		d_ack <= 0; data <= 0;
	/* normal operation */
	end else begin
		/* mipi state machine */
		case (state)
		/* idle state */
		IDLE : begin
			/* enable clock tri-state */
			c_hs_tri <= 1'b1;
			/* wait for bus request */
			if (b_req)
				state <= CLK_HS;
		end
		/* wait for the clock lane to transit into hs mode */
		CLK_HS : begin
			/* request high speed mode */
			c_hs_req <= 1'b1;
			/* clock high speed mode is now ready? */
			if (c_hs_rdy)
				state <= DAT_HS;
		end
		/* wait for high speed mode on data lane */
		DAT_HS : begin
			/* keep the clock going */
			c_hs_tri <= 1'b0;
			c_ddr_in <= 1'b1;
			/* request high speed mode */
			d_hs_req <= 1'b1;
			/* high speed mode ready? */
			if (d_hs_rdy)
				state <= SYNC;
		end
		/* sync to quadrature clock */
		SYNC : begin
			/* disable data tri-state */
			d_hs_tri <= 1'b0;
			/* clear ack */
			d_ack <= 0;
			/* got high state on in-phase clock? */
			if (clk_i)
				state <= SEND;
		end
		/* send state */
		SEND : begin
			/* setup next two bits for ddr action */
			d_ddr_in <= data[1:0];
			/* shift data down */
			data <= {data[7], data[7], data[7:2]};
			/* bit pair counter */
			bit_cnt <= {bit_cnt[2:0], bit_cnt[3]};
			/* enable clock if there is no underrun condition */
			c_ddr_in <= ~underrun;
			/* go back to sync state */
			state <= SYNC; 
			/* last pair of bits? */
			if (bit_cnt[3]) begin
				/* read data */
				if (d_req)
					data <= d_in;
				/* end bus activity? */
				if (~b_req)
					state <= TOGGLE;
				/* underrun && ack flags */
				underrun <= ~d_req;
				/* generate ack pulse */
				d_ack <= d_req;
			end
		end
		/* toggle data bit */
		TOGGLE : begin
			/* toggle last data bit */
			d_ddr_in <= ~data[1:0];
			/* toggle clock */
			c_ddr_in <= 1'b1;
			/* next state */
			state <= DAT_LP;
		end
		/* disable data lane high speed mode */
		DAT_LP : begin
			/* disable high speed mode */
			d_hs_req <= 1'b0;
			/* data lane released? */
			if (~d_hs_rdy)
				state <= CLK_LP;
		end
		/* end clock high speed mode */
		CLK_LP : begin
			/* enable data tri state */
			d_hs_tri <= 1'b1;
			/* keep the clock quiet */
			c_ddr_in <= 1'b0;
			/* release high speed mode */
			c_hs_req <= 1'b0;
			/* data lane disabled? */
			if (~c_hs_rdy)
				state <= IDLE;
		end
		endcase
	end
end
//wire c_ddr_hs /* synthesis syn_keep=1 nomerge=""*/;

wire buf1 = ~clk_q/* synthesis syn_keep=1 nomerge=""*/;
wire buf2 = ~buf1 /* synthesis syn_keep=1 nomerge=""*/;

/* data ddr primitive */
ODDRXE d_ddr (.D0(d_ddr_in[0]), .D1(d_ddr_in[1]), .Q(d_ddr_hs), .SCLK(clk_i), .RST(rst));
/* clock ddr primitive: we use ddr ff to generate clock if d0 is high then clock pulses are generated */
ODDRXE c_ddr (.D0(c_ddr_in), .D1(1'b0), .Q(c_ddr_hs), .SCLK(buf2), .RST(rst));

/* tristate control for high speed data */
assign d_hs = d_hs_tri ? 1'bz : d_ddr_hs;




/* tristate control for high speed clock */
assign c_hs = c_hs_tri ? 1'bz : c_ddr_hs;

/* data lane low speed signalling module */
lp lp_dat (.clk(clk), .hs_req(d_hs_req), .hs_rdy(d_hs_rdy), .lp_p(d_lp_p), .lp_n(d_lp_n), .rst(rst));
/* clock lane low speed signalling module */
lp lp_clk (.clk(clk), .hs_req(c_hs_req), .hs_rdy(c_hs_rdy), .lp_p(c_lp_p), .lp_n(c_lp_n), .rst(rst));

endmodule
