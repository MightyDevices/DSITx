/* simple delay element done with the use of LUT */
module delay # (
	/* number of luts used */
	parameter LENGTH = 1
)
(
	/* input signal */
	input wire a,
	/* output signal */
	output wire o
);


genvar i;
/* lut generation */
generate
	for (i = 0; i < LENGTH; i = i + 1) begin : DELAY_ELEMS
		wire z /* synthesis syn_keep=1 nomerge=""*/;
		/* 1st element, uses 'a' as the input signal */
		if (i == 0) begin
			LUT4 # (.init(16'h0002)) I1 (.A(a), .B(1'b0), .C(1'b0), .D(1'b0), .Z(z));
		/* evey other element uses _z signal as the input */
		end else begin
			LUT4 # (.init(16'h0002)) I1 (.A(DELAY_ELEMS[i-1].z), .B(1'b0), .C(1'b0), .D(1'b0), .Z(z));
		end
	end
endgenerate

/* assign output signals */
assign o = DELAY_ELEMS[LENGTH - 1].z;

endmodule 