/* data signal generation using ddr output register */
module data_hs_phy (
	/* byte clock */
	input wire byte_clk, 
	/* bit clock: 4x byte clock */
	input wire bit_clk, 
	/* reset signal */
	input wire byte_rst, bit_rst,
	
	/* data */
	input wire [7:0] data,
	/* enable signal */
	input wire enable,
	/* controls the tri-stating of the hs lane */
	input wire hi_z,
	
	/* serializer output */
	output wire out
) /* synthesis GSR=ENABLED */;

/* bit pair counter, bit pair */
reg [1:0] cnt, pair;
/* data holding register */
reg [7:0] data_reg;
/* registered version */
reg enable_reg;

/* byte loading logic */
always @ (posedge byte_clk or posedge byte_rst)
begin
	/* reset */
	if (byte_rst) begin
		data_reg <= 0; enable_reg = 0;
	/* normal operation */
	end else begin
		/* enable signal is registered */
		enable_reg <= enable;
		/* update data reg only when enable is set */
		data_reg <= enable ? data : 8'h00;
	end
end

/* counter logic */
always @ (posedge bit_clk or posedge bit_rst)
begin
	/* reset */
	if (bit_rst) begin
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
	2'b00 : pair = data_reg[1:0];
	2'b01 : pair = data_reg[3:2];
	2'b10 : pair = data_reg[5:4];
	2'b11 : pair = data_reg[7:6];
	endcase
end

/* output ddr ff */
ODDRXE ddr (.D0(pair[0]), .D1(pair[1]), .Q(ddr_out), .SCLK(bit_clk), .RST(bit_rst));
/* tri state output control */
assign out = hi_z ? 1'bZ : ddr_out;

endmodule