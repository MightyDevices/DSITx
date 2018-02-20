/* ddr serializer */
module oddrser8 (
	/* byte clock */
	input wire byte_clk, 
	/* bit clock: 4x byte clock */
	input wire bit_clk, 
	/* reset signal */
	input wire rst,
	/* data */
	input wire [7:0] data,
	/* serializer output */
	output wire out
) /* synthesis GSR=ENABLED */;

/* bit pair counter, bit pair */
reg [1:0] cnt, d;
/* data holding register */
reg [7:0] data_reg;

/* byte loading logic */
always @ (posedge byte_clk or posedge rst)
begin
	/* reset */
	if (rst) begin
		data_reg <= 0;
	/* normal operation */
	end else begin
		data_reg <= data;
	end
end

/* counter logic */
always @ (posedge bit_clk or posedge rst)
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
always @ (data_reg, cnt)
begin
	case (cnt)
	2'b00 : d = data_reg[1:0];
	2'b01 : d = data_reg[3:2];
	2'b10 : d = data_reg[5:4];
	2'b11 : d = data_reg[7:6];
	endcase
end

/* output ddr ff */
ODDRXE ddr (.D0(d[0]), .D1(d[1]), .Q(out), .SCLK(bit_clk), .RST(rst));

endmodule