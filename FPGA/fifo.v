/* async fifo */
module fifo # (
	/* data width */
	parameter DATA_BITS = 8,
	/* address width */
	parameter ADDR_BITS = 4,
	/* allow overflow (wrriting too many elements) */
	parameter ALLOW_OVERFLOW = 0,
	/* allow underflow (reading too many elements) */
	parameter ALLOW_UNDERFLOW = 0
)	
(
	/* write domain clock, reset and write enable*/
	input wire wr_clk, wr_rst, wr_we,
	/* write data */
	input wire [DATA_BITS-1:0] wr_data,
	/* fifo full */
	output wire wr_full,
	
	/* read domain clock, reset and output enable */
	input wire rd_clk, rd_rst, rd_oe,
	/* write data */
	output wire [DATA_BITS-1:0] rd_data,
	/* fifo empty */
	output wire rd_empty
);

/* read and write addresses */
wire [ADDR_BITS : 0] rd_addr, wr_addr;
/* read and write addresses cross domain synchronized */
wire [ADDR_BITS : 0] rd_addr_wr_domain, wr_addr_rd_domain;

/* fifo memory */
reg [DATA_BITS-1:0] mem [0:(1 << ADDR_BITS) - 1];

/* gray counters used for addressing, we use these since only one bit 
 * changes per increment (easy to synchronize) additional bit is 
 * used for empty/full signal generation */
gray #(.WIDTH(ADDR_BITS + 1)) rd_gray(.clk(rd_clk), .rst(rd_rst), 
	.enable(rd_en), .out(rd_addr));
gray #(.WIDTH(ADDR_BITS + 1)) wr_gray(.clk(wr_clk), .rst(wr_rst), 
	.enable(wr_en), .out(wr_addr));

/* pointer synchronization */
sync #(.WIDTH(ADDR_BITS + 1)) rd_sync(.clk(rd_clk), .rst(rd_rst), 
	.in(rd_addr), .out(rd_addr_wr_domain));
sync #(.WIDTH(ADDR_BITS + 1)) wr_sync(.clk(wr_clk), .rst(wr_rst), 
	.in(wr_addr), .out(wr_addr_rd_domain));

/* write logic */
always @ (posedge wr_clk)
	if (wr_en) mem[wr_addr[ADDR_BITS-1:0]] <= wr_data;
		
/* read logic */
assign rd_data = mem[rd_addr[ADDR_BITS-1:0]];

/* fifo empty & full signal */
assign rd_empty = rd_addr == wr_addr_rd_domain;
/* generate full signal */
generate
	/* use the symmetry of the gray code */
	if (ADDR_BITS > 1) begin
		assign wr_full = wr_addr == {~rd_addr_wr_domain[ADDR_BITS:ADDR_BITS-1], 
			rd_addr_wr_domain[ADDR_BITS-2:0]};
	/* simpler case for two element fifo */
	end else begin
		assign wr_full = wr_addr == ~rd_addr_wr_domain[ADDR_BITS:ADDR_BITS-1];
	end
endgenerate

/* simplify logic if over-/underflows are allowed */
generate
	assign rd_en = (ALLOW_UNDERFLOW) ? rd_oe : rd_oe & ~rd_empty;
	assign wr_en = (ALLOW_OVERFLOW) ? wr_we : wr_we & ~wr_full;
endgenerate 

endmodule