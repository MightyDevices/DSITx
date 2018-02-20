/* clock signal generation using ddr output register */
module clock_hs_phy (
	/* byte clock */
	input wire byte_clk, 
	/* bit clock: 4x byte clock */
	input wire bit_clk, 
	/* reset signal */
	input wire byte_rst, bit_rst,
	
	/* clock generation enable */
	input wire enable,
	/* controls the tri-stating of the hs lane */
	input wire hi_z,
	
	/* clock output */
	output wire out
) /* synthesis GSR=ENABLED */;

/* enable register */
reg enable_reg;

/* enable update is synchronized to byte clock */
always @ (posedge byte_clk or posedge byte_rst)
begin
	/* reset logic */
	if (byte_rst) begin
		enable_reg <= 0;
	/* normal operation */
	end else begin
		enable_reg <= enable;
	end
end

/* output ddr ff */
ODDRXE ddr (.D0(enable_reg), .D1(1'b0), .Q(ddr_out), .SCLK(bit_clk), .RST(bit_rst));
/* tri state output control */
assign out = hi_z ? 1'bZ : ddr_out;

endmodule