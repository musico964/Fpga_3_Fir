module SyncReset(CK, ASYNC_RSTb, SYNC_RSTb);
input CK, ASYNC_RSTb;
output SYNC_RSTb;

`ifdef SYNTH
parameter MSB = 21;
`else
parameter MSB = 5;
`endif

reg SYNC_RSTb;
reg x1, x2, x3, x4, int_rstB;

reg [MSB:0] rst_count;

always @(posedge CK or negedge ASYNC_RSTb)
begin
	if( ASYNC_RSTb == 0 )
	begin
		x1 <= 0; x2 <= 0; x3 <= 0; x4 <= 0;
		int_rstB <= 0;
	end
	else
	begin
		x1 <= 1'b1;
		x2 <= x1;
		x3 <= x2;
		x4 <= x3;
		int_rstB <= x4;
	end
end

always @(posedge CK)
begin
	if( int_rstB == 0 )
	begin
		rst_count <= MSB+1'b0;
		SYNC_RSTb <= 0;
	end
	else
	begin
		if( rst_count[MSB] == 0 )
			rst_count <= rst_count + 1;
		SYNC_RSTb <= rst_count[MSB];
	end
end

endmodule

