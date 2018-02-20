/* ddr serializer */
module ser8 (
	/* byte clock*/
	input wire byte_clk, 
	/* bit clock: 4x byte clock */
	input wire bit_clk, 
	/* reset signal */
	input wire rst,
	/* data */
	input wire [7:0] data,
	/* serializer output */
	output wire out
);

/* bit pair from data byte */
wire [1:0] d;
/* bit pair counter */
reg [1:0] cnt;

/* counter logic */
always @ (posedge byte_clk or posedge rst)
begin
	/* reset */
	if (rst) begin
		cnt <= 0;
	/* normal operation */
	end else begin
		cnt <= cnt + 1'b1;
	end
end

/* data pair mux */
always @ (*)
begin
	case (cnt)
	2'b00 : d = data[1:0];
	2'b01 : d = data[3:2];
	2'b10 : d = data[5:4];
	2'b11 : d = data[7:6];
	endcase
end

/* data ddr primitive */
ODDRXE d_ddr (.D0(d[0]), .D1(d[1]), .Q(out), .SCLK(bit_clk), .RST(rst));

endmodule