// RAM needed:
// 2 x 128x12  DPRAM	= 3072 bit	(Pedestal & Threshold) ALTSYNCRAM
// 1 x 1024x13 DCFIFO	= 13312 bit	(Frame Decoder Data output)
// 1 x 32x12   DCFIFO	= 384 bit	(Frame Decoder Mean output)
// 1 x 2048x21 SCFIFO	= 43008 bit	(Output data buffer)
// --------------------------------
// TOTAL		= 59776 bit

module ChannelProcessor(RSTb, CLK, CLK_APV, CH_ENABLE, ENABLE_BASE_SUB,
	ADC_PDATA, SYNC_PERIOD, COMMON_OFFSET, CH_ID,
	RAM_ADDRESS, RAM_DATA_IN, DATA_OUT, WE_PEDESTAL_RAM, WE_THRESHOLD_RAM, 
	RE_PEDESTAL_RAM, RE_THRESHOLD_RAM,	// RE_THRESHOLD_RAM not used
	FIFO_RD, 	// FIFO_RD comes from VME (or other user interface) or Event Builder
	FIFO_USED_WORDS,
	EVENT_PRESENT, DECR_EVENT_COUNTER,
	SYNCED, ALL_CLEAR,
	DAQ_MODE, ZERO_VAL, ONE_VAL, NO_MORE_SPACE, FIFO_EMPTY, FIFO_FULL, MODULE_ID, MARKER_CH
);

input RSTb, CLK, CLK_APV, CH_ENABLE, ENABLE_BASE_SUB;
input [11:0] ADC_PDATA, COMMON_OFFSET;
input [3:0] CH_ID;
input [7:0] SYNC_PERIOD;
input [6:0] RAM_ADDRESS;
input [11:0]  RAM_DATA_IN;
output [20:0] DATA_OUT;
input WE_PEDESTAL_RAM, WE_THRESHOLD_RAM, RE_PEDESTAL_RAM, RE_THRESHOLD_RAM;
input FIFO_RD;
output [11:0] FIFO_USED_WORDS;
output EVENT_PRESENT;
input DECR_EVENT_COUNTER;
output SYNCED;
input ALL_CLEAR;
input [2:0] DAQ_MODE;
input [11:0]  ZERO_VAL, ONE_VAL;
output NO_MORE_SPACE, FIFO_EMPTY, FIFO_FULL;
input [4:0] MODULE_ID;
input [7:0] MARKER_CH;

reg [11:0] FIFO_USED_WORDS;
reg FIFO_EMPTY, FIFO_FULL;

wire [6:0] pedestal_rd_address, threshold_rd_address;
wire [6:0] pedestal_internal_address, threshold_internal_address;
wire [11:0] pedestal_data, threshold_data, baseline;
wire [12:0] decoded_frame_data;
wire [20:0] output_fifo_data;
wire decoded_event_present, end_threshold_processing, decoded_frame_fifo_rd;
wire [11:0] OutputUsedWords, FrameDecoderUsedWords;
wire OutputFifoEmpty, OutputFifoFull, FrameDecoderFifoEmpty, FrameDecoderFifoFull;
//reg DisableMode, SampleMode, ApvReadoutMode_Simple, NoProcessorMode;
reg ApvReadoutMode_Processed;

always @(posedge CLK)
begin
//	DisableMode <= (DAQ_MODE == 3'b000) ? 1 : 0;
//	ApvReadoutMode_Simple <= (DAQ_MODE == 3'b001) ? 1 : 0;
//	SampleMode <= (DAQ_MODE == 3'b010) ? 1 : 0;
	ApvReadoutMode_Processed <= (DAQ_MODE == 3'b011) ? 1 : 0;
//	NoProcessorMode <= ApvReadoutMode_Simple | SampleMode;

	FIFO_USED_WORDS <= ApvReadoutMode_Processed ? OutputUsedWords : FrameDecoderUsedWords;
	FIFO_EMPTY <= ApvReadoutMode_Processed ? OutputFifoEmpty : FrameDecoderFifoEmpty;
	FIFO_FULL <= ApvReadoutMode_Processed ? OutputFifoFull : FrameDecoderFifoFull;
end

assign pedestal_rd_address = CH_ENABLE ? pedestal_internal_address : RAM_ADDRESS;
assign threshold_rd_address = CH_ENABLE ? threshold_internal_address : RAM_ADDRESS;
assign DATA_OUT = CH_ENABLE ? ( ApvReadoutMode_Processed ? output_fifo_data : {8'b0, decoded_frame_data}) :
	(RE_PEDESTAL_RAM ? {9'b0,pedestal_data} : {9'b0,threshold_data});



DpRam128x12 PedestalRam( .clock(CLK),
	.data(RAM_DATA_IN), .wraddress(RAM_ADDRESS), .wren(WE_PEDESTAL_RAM),
	.rdaddress(pedestal_rd_address), .q(pedestal_data));

DpRam128x12 ThresholdRam( .clock(CLK),
	.data(RAM_DATA_IN), .wraddress(RAM_ADDRESS), .wren(WE_THRESHOLD_RAM),
	.rdaddress(threshold_rd_address), .q(threshold_data));

ApvReadout ApvFrameDecoder(.RSTb(RSTb), .CLK(CLK_APV), .ENABLE(CH_ENABLE), .ADC_PDATA(ADC_PDATA),
	.SYNC_PERIOD(SYNC_PERIOD), .SYNCED(SYNCED), .ERROR(),
	.FIFO_DATA_OUT(decoded_frame_data),
	.FIFO_EMPTY(FrameDecoderFifoEmpty), .FIFO_FULL(FrameDecoderFifoFull),
	.FIFO_RD_CLK(CLK), .FIFO_RD(ApvReadoutMode_Processed ? decoded_frame_fifo_rd : FIFO_RD),
	.HIGH_ONE(ONE_VAL), .LOW_ZERO(ZERO_VAL), .FIFO_CLEAR(ALL_CLEAR),
	.DAQ_MODE(DAQ_MODE),
	.NO_MORE_SPACE_FOR_EVENT(NO_MORE_SPACE),
	.USED_FIFO_WORDS(FrameDecoderUsedWords),
	.ONE_MORE_EVENT(decoded_event_present),
	.PEDESTAL_ADDRESS(pedestal_internal_address), .PEDESTAL_DATA(pedestal_data),
	.OFFSET(COMMON_OFFSET), .MEAN(baseline), .RD_NEXT_MEAN(end_threshold_processing),
	.MARKER_CH(MARKER_CH)
	);

BaselineSubtractorAndThresholdCut ThrSub(.RSTb(RSTb & ~ALL_CLEAR), .CLK(CLK),
	.ENABLE_BASE_SUB(ENABLE_BASE_SUB),
	.DATA_IN(decoded_frame_data), .FIFO_DATA_RD(decoded_frame_fifo_rd),
	.EVENT_PRESENT(decoded_event_present), .MEAN(baseline),
	.THRESHOLD_ADDRESS(threshold_internal_address), .THRESHOLD_DATA(threshold_data),
	.CH_ID(CH_ID),
	.FIFO_DATA_OUT(output_fifo_data), .OUT_FIFO_RD(FIFO_RD),
	.FIFO_EMPTY(OutputFifoEmpty), .FIFO_FULL(OutputFifoFull),
	.FIFO_USED_WORDS(OutputUsedWords),
	.END_PROCESSING(end_threshold_processing), .MODULE_ID(MODULE_ID)
	);

FiveBitCounter EvCounter(.RSTb(RSTb & ~ALL_CLEAR), .CLK(CLK), .INC(end_threshold_processing),
	.NON_ZERO(EVENT_PRESENT), .DEC(DECR_EVENT_COUNTER)
	);

endmodule


module BaselineSubtractorAndThresholdCut(RSTb, CLK, ENABLE_BASE_SUB,
	DATA_IN, FIFO_DATA_RD,
	EVENT_PRESENT, MEAN,
	THRESHOLD_ADDRESS, THRESHOLD_DATA, CH_ID,
	FIFO_DATA_OUT, OUT_FIFO_RD, FIFO_EMPTY, FIFO_FULL, FIFO_USED_WORDS,
	END_PROCESSING, MODULE_ID
);
input RSTb, CLK, ENABLE_BASE_SUB;
input [12:0] DATA_IN;
output FIFO_DATA_RD;
input EVENT_PRESENT;
input [11:0] MEAN;
output [6:0] THRESHOLD_ADDRESS;
input [11:0] THRESHOLD_DATA;
input [3:0] CH_ID;
output [20:0] FIFO_DATA_OUT;
input OUT_FIFO_RD;
output FIFO_EMPTY, FIFO_FULL, END_PROCESSING;
output [11:0] FIFO_USED_WORDS;
input [4:0] MODULE_ID;

reg FIFO_DATA_RD;
reg END_PROCESSING;
reg [7:0] ThrAddr;

reg fifo_out_wr, active_channel;
reg [20:0] fifo_data_in;
reg [7:0] word_count;
reg [7:0] fsm_status;

wire [11:0] enabled_mean;
wire [12:0] data_minus_baseline;

assign enabled_mean = ENABLE_BASE_SUB ? MEAN : 12'b0;
assign FIFO_USED_WORDS[11] = FIFO_FULL;
assign THRESHOLD_ADDRESS = ThrAddr[6:0];

Fifo_2048x21 TempFifo21( .aclr(~RSTb), .clock(CLK),
	.data(fifo_data_in), .wrreq(fifo_out_wr),
	.empty(FIFO_EMPTY), .full(FIFO_FULL), .rdreq(OUT_FIFO_RD), .q(FIFO_DATA_OUT),
	.usedw(FIFO_USED_WORDS[10:0]));

Sub13 BaselineSubtractor(.dataa(DATA_IN), .datab({1'b0,enabled_mean}),
	.result(data_minus_baseline));

	always @(posedge CLK or negedge RSTb)
	begin
		if( RSTb == 0 )
		begin
			FIFO_DATA_RD <= 0;
			ThrAddr <= 0;
			END_PROCESSING <= 0;
			fifo_out_wr <= 0;
			active_channel <= 0;
			fifo_data_in <= 0;
			word_count <= 0;
			fsm_status <= 0;
		end
		else
		begin
			case( fsm_status )
				0:	begin
						FIFO_DATA_RD <= 0;
						ThrAddr <= 0;
						END_PROCESSING <= 0;
						fifo_out_wr <= 0;
						word_count <= 2;
						if( EVENT_PRESENT == 1 )
						begin
							fifo_data_in <= {1'b0, 1'b0, 1'b0, MEAN[11], DATA_IN, CH_ID};
							FIFO_DATA_RD <= 1;
							fifo_out_wr <= 1;
							fsm_status <= 1;
						end
					end
				1:	begin
						fifo_data_in <= {1'b0, 1'b1, THRESHOLD_ADDRESS, data_minus_baseline[11:0]};
						fifo_out_wr <= 0;
						FIFO_DATA_RD <= 0;
						fsm_status <= 2;
					end
				2:	begin
						fifo_out_wr <= 0;
						FIFO_DATA_RD <= 0;
						if( THRESHOLD_DATA == 12'hFFF )
							active_channel <= 0;
						else
							active_channel <= 1;
						fsm_status <= 3;
					end
				3:	begin
						fifo_data_in <= {1'b0, 1'b1, THRESHOLD_ADDRESS, data_minus_baseline[11:0]};
						ThrAddr <= ThrAddr + 1;
						if( active_channel & (data_minus_baseline > THRESHOLD_DATA) )
						begin
							fifo_out_wr <= 1;
							word_count <= word_count + 1;
						end
						if( ThrAddr != 8'h80 )
						begin
							FIFO_DATA_RD <= 1;
							fsm_status <= 2;
						end
						else
						begin	// Handle trailer coming from preceding stage
							fifo_out_wr <= 1;
							fifo_data_in <= {1'b1, 1'b0, 2'b0, MODULE_ID, DATA_IN[11:0]};
//							fifo_data_in <= {1'b1, 1'b0, 6'b0, DATA_IN};
							FIFO_DATA_RD <= 0;
							fsm_status <= 4;
						end
					end
				4:	begin
						FIFO_DATA_RD <= 0;
						fifo_out_wr <= 0;
						fsm_status <= 5;
						END_PROCESSING <= 1;
					end
				5:	begin
						fifo_out_wr <= 1;
						fifo_data_in <= {1'b1, 1'b1, MEAN[10:0], word_count};	// Write TRAILER
						FIFO_DATA_RD <= 1;
						END_PROCESSING <= 0;
						fsm_status <= 6;
					end
				6:	begin
						FIFO_DATA_RD <= 0;
						fifo_out_wr <= 0;
						fsm_status <= 0;
					end
				default: fsm_status <= 0;
			endcase
		end
	end

endmodule



module FiveBitCounter(RSTb, CLK, INC, NON_ZERO, DEC);
input RSTb, CLK, INC, DEC;
output NON_ZERO;

reg [4:0] cnt;
reg NON_ZERO;

	always @(posedge CLK or negedge RSTb)
	begin
		if( RSTb == 0 )
		begin
			cnt <= 0;
			NON_ZERO <= 0;
		end
		else
		begin
			NON_ZERO <= (cnt != 0) ? 1 : 0;
			if( INC == 1 && cnt != 5'h1F )
				cnt <= cnt + 1;
			else
				if( DEC == 1 && cnt != 5'h00 )
					cnt <= cnt - 1;
		end
	end
endmodule





module EightChannels(RSTb, APV_CLK, PROCESS_CLK, ENABLE, EN_BASELINE_SUBTRACTION,
	ADC_PDATA0, ADC_PDATA1, ADC_PDATA2, ADC_PDATA3,
	ADC_PDATA4, ADC_PDATA5, ADC_PDATA6, ADC_PDATA7,
	SYNC_PERIOD, SYNCED,
	COMMON_OFFSET,
	BANK_ID,
	FIFO_DATA_OUT0, FIFO_DATA_OUT1, FIFO_DATA_OUT2, FIFO_DATA_OUT3,
	FIFO_DATA_OUT4, FIFO_DATA_OUT5, FIFO_DATA_OUT6, FIFO_DATA_OUT7,
	FIFO_EMPTY, FIFO_FULL, FIFO_RD,
	HIGH_ONE, LOW_ZERO, ALL_CLEAR, DAQ_MODE,
	USED_FIFO_WORDS0, USED_FIFO_WORDS1, USED_FIFO_WORDS2, USED_FIFO_WORDS3,
	USED_FIFO_WORDS4, USED_FIFO_WORDS5, USED_FIFO_WORDS6, USED_FIFO_WORDS7,
	ONE_MORE_EVENT, DECR_EVENT_COUNTER,
	NO_MORE_SPACE, SPACE_AVAILABLE,
	RAM_ADDR, RAM_DIN, WE_PED_RAM, RE_PED_RAM, WE_THR_RAM, RE_THR_RAM, MODULE_ID,
	MARKER_CH
	);

input RSTb, APV_CLK, PROCESS_CLK;
input [7:0] ENABLE;
input EN_BASELINE_SUBTRACTION;
input [11:0] ADC_PDATA0, ADC_PDATA1, ADC_PDATA2, ADC_PDATA3;
input [11:0] ADC_PDATA4, ADC_PDATA5, ADC_PDATA6, ADC_PDATA7;
input [7:0] SYNC_PERIOD;
output [7:0] SYNCED;
input [11:0] COMMON_OFFSET;
input BANK_ID;
output [20:0] FIFO_DATA_OUT0, FIFO_DATA_OUT1, FIFO_DATA_OUT2, FIFO_DATA_OUT3;
output [20:0] FIFO_DATA_OUT4, FIFO_DATA_OUT5, FIFO_DATA_OUT6, FIFO_DATA_OUT7;
output [7:0] FIFO_EMPTY, FIFO_FULL;
input [7:0] FIFO_RD;
input [11:0] HIGH_ONE, LOW_ZERO;
input ALL_CLEAR;
input [2:0] DAQ_MODE;
output [11:0] USED_FIFO_WORDS0, USED_FIFO_WORDS1, USED_FIFO_WORDS2, USED_FIFO_WORDS3;
output [11:0] USED_FIFO_WORDS4, USED_FIFO_WORDS5, USED_FIFO_WORDS6, USED_FIFO_WORDS7;
output [7:0] ONE_MORE_EVENT;
input DECR_EVENT_COUNTER;
output NO_MORE_SPACE, SPACE_AVAILABLE;
input [6:0] RAM_ADDR;
input [31:0] RAM_DIN;
input [3:0] WE_PED_RAM, RE_PED_RAM, WE_THR_RAM, RE_THR_RAM;
input [4:0] MODULE_ID;
input [7:0] MARKER_CH;

wire [7:0] no_more_space;

assign NO_MORE_SPACE = |no_more_space;
assign SPACE_AVAILABLE = &(~no_more_space);

	ChannelProcessor Ch0(.RSTb(RSTb), .CLK(PROCESS_CLK), .CLK_APV(APV_CLK),
		.CH_ENABLE(ENABLE[0]), .ENABLE_BASE_SUB(EN_BASELINE_SUBTRACTION),
		.ADC_PDATA(ADC_PDATA0), .SYNC_PERIOD(SYNC_PERIOD), .COMMON_OFFSET(COMMON_OFFSET),
		.CH_ID({BANK_ID, 3'd0}),
		.RAM_ADDRESS(RAM_ADDR), .RAM_DATA_IN(RAM_DIN[11:0]), .DATA_OUT(FIFO_DATA_OUT0),
		.WE_PEDESTAL_RAM(WE_PED_RAM[0]), .WE_THRESHOLD_RAM(WE_THR_RAM[0]), 
		.RE_PEDESTAL_RAM(RE_PED_RAM[0]), .RE_THRESHOLD_RAM(RE_THR_RAM[0]),
		.FIFO_RD(FIFO_RD[0]),
		.FIFO_USED_WORDS(USED_FIFO_WORDS0),
		.EVENT_PRESENT(ONE_MORE_EVENT[0]), .DECR_EVENT_COUNTER(DECR_EVENT_COUNTER),
		.SYNCED(SYNCED[0]), .ALL_CLEAR(ALL_CLEAR),
		.DAQ_MODE(DAQ_MODE), .ZERO_VAL(LOW_ZERO), .ONE_VAL(HIGH_ONE),
		.NO_MORE_SPACE(no_more_space[0]),
		.FIFO_EMPTY(FIFO_EMPTY[0]), .FIFO_FULL(FIFO_FULL[0]), .MODULE_ID(MODULE_ID),
		.MARKER_CH(MARKER_CH)
	);
	ChannelProcessor Ch1(.RSTb(RSTb), .CLK(PROCESS_CLK), .CLK_APV(APV_CLK),
		.CH_ENABLE(ENABLE[1]), .ENABLE_BASE_SUB(EN_BASELINE_SUBTRACTION),
		.ADC_PDATA(ADC_PDATA1), .SYNC_PERIOD(SYNC_PERIOD), .COMMON_OFFSET(COMMON_OFFSET),
		.CH_ID({BANK_ID, 3'd1}),
		.RAM_ADDRESS(RAM_ADDR), .RAM_DATA_IN(RAM_DIN[27:16]), .DATA_OUT(FIFO_DATA_OUT1),
		.WE_PEDESTAL_RAM(WE_PED_RAM[0]), .WE_THRESHOLD_RAM(WE_THR_RAM[0]), 
		.RE_PEDESTAL_RAM(RE_PED_RAM[0]), .RE_THRESHOLD_RAM(RE_THR_RAM[0]),
		.FIFO_RD(FIFO_RD[1]),
		.FIFO_USED_WORDS(USED_FIFO_WORDS1),
		.EVENT_PRESENT(ONE_MORE_EVENT[1]), .DECR_EVENT_COUNTER(DECR_EVENT_COUNTER),
		.SYNCED(SYNCED[1]), .ALL_CLEAR(ALL_CLEAR),
		.DAQ_MODE(DAQ_MODE), .ZERO_VAL(LOW_ZERO), .ONE_VAL(HIGH_ONE),
		.NO_MORE_SPACE(no_more_space[1]),
		.FIFO_EMPTY(FIFO_EMPTY[1]), .FIFO_FULL(FIFO_FULL[1]), .MODULE_ID(MODULE_ID),
		.MARKER_CH(MARKER_CH)
	);

	ChannelProcessor Ch2(.RSTb(RSTb), .CLK(PROCESS_CLK), .CLK_APV(APV_CLK),
		.CH_ENABLE(ENABLE[2]), .ENABLE_BASE_SUB(EN_BASELINE_SUBTRACTION),
		.ADC_PDATA(ADC_PDATA2), .SYNC_PERIOD(SYNC_PERIOD), .COMMON_OFFSET(COMMON_OFFSET),
		.CH_ID({BANK_ID, 3'd2}),
		.RAM_ADDRESS(RAM_ADDR), .RAM_DATA_IN(RAM_DIN[11:0]), .DATA_OUT(FIFO_DATA_OUT2),
		.WE_PEDESTAL_RAM(WE_PED_RAM[1]), .WE_THRESHOLD_RAM(WE_THR_RAM[1]), 
		.RE_PEDESTAL_RAM(RE_PED_RAM[1]), .RE_THRESHOLD_RAM(RE_THR_RAM[1]),
		.FIFO_RD(FIFO_RD[2]),
		.FIFO_USED_WORDS(USED_FIFO_WORDS2),
		.EVENT_PRESENT(ONE_MORE_EVENT[2]), .DECR_EVENT_COUNTER(DECR_EVENT_COUNTER),
		.SYNCED(SYNCED[2]), .ALL_CLEAR(ALL_CLEAR),
		.DAQ_MODE(DAQ_MODE), .ZERO_VAL(LOW_ZERO), .ONE_VAL(HIGH_ONE),
		.NO_MORE_SPACE(no_more_space[2]),
		.FIFO_EMPTY(FIFO_EMPTY[2]), .FIFO_FULL(FIFO_FULL[2]), .MODULE_ID(MODULE_ID),
		.MARKER_CH(MARKER_CH)
	);
	ChannelProcessor Ch3(.RSTb(RSTb), .CLK(PROCESS_CLK), .CLK_APV(APV_CLK),
		.CH_ENABLE(ENABLE[3]), .ENABLE_BASE_SUB(EN_BASELINE_SUBTRACTION),
		.ADC_PDATA(ADC_PDATA3), .SYNC_PERIOD(SYNC_PERIOD), .COMMON_OFFSET(COMMON_OFFSET),
		.CH_ID({BANK_ID, 3'd3}),
		.RAM_ADDRESS(RAM_ADDR), .RAM_DATA_IN(RAM_DIN[27:16]), .DATA_OUT(FIFO_DATA_OUT3),
		.WE_PEDESTAL_RAM(WE_PED_RAM[1]), .WE_THRESHOLD_RAM(WE_THR_RAM[1]), 
		.RE_PEDESTAL_RAM(RE_PED_RAM[1]), .RE_THRESHOLD_RAM(RE_THR_RAM[1]),
		.FIFO_RD(FIFO_RD[3]),
		.FIFO_USED_WORDS(USED_FIFO_WORDS3),
		.EVENT_PRESENT(ONE_MORE_EVENT[3]), .DECR_EVENT_COUNTER(DECR_EVENT_COUNTER),
		.SYNCED(SYNCED[3]), .ALL_CLEAR(ALL_CLEAR),
		.DAQ_MODE(DAQ_MODE), .ZERO_VAL(LOW_ZERO), .ONE_VAL(HIGH_ONE),
		.NO_MORE_SPACE(no_more_space[3]),
		.FIFO_EMPTY(FIFO_EMPTY[3]), .FIFO_FULL(FIFO_FULL[3]), .MODULE_ID(MODULE_ID),
		.MARKER_CH(MARKER_CH)
	);

	ChannelProcessor Ch4(.RSTb(RSTb), .CLK(PROCESS_CLK), .CLK_APV(APV_CLK),
		.CH_ENABLE(ENABLE[4]), .ENABLE_BASE_SUB(EN_BASELINE_SUBTRACTION),
		.ADC_PDATA(ADC_PDATA4), .SYNC_PERIOD(SYNC_PERIOD), .COMMON_OFFSET(COMMON_OFFSET),
		.CH_ID({BANK_ID, 3'd4}),
		.RAM_ADDRESS(RAM_ADDR), .RAM_DATA_IN(RAM_DIN[11:0]), .DATA_OUT(FIFO_DATA_OUT4),
		.WE_PEDESTAL_RAM(WE_PED_RAM[2]), .WE_THRESHOLD_RAM(WE_THR_RAM[2]), 
		.RE_PEDESTAL_RAM(RE_PED_RAM[2]), .RE_THRESHOLD_RAM(RE_THR_RAM[2]),
		.FIFO_RD(FIFO_RD[4]),
		.FIFO_USED_WORDS(USED_FIFO_WORDS4),
		.EVENT_PRESENT(ONE_MORE_EVENT[4]), .DECR_EVENT_COUNTER(DECR_EVENT_COUNTER),
		.SYNCED(SYNCED[4]), .ALL_CLEAR(ALL_CLEAR),
		.DAQ_MODE(DAQ_MODE), .ZERO_VAL(LOW_ZERO), .ONE_VAL(HIGH_ONE),
		.NO_MORE_SPACE(no_more_space[4]),
		.FIFO_EMPTY(FIFO_EMPTY[4]), .FIFO_FULL(FIFO_FULL[4]), .MODULE_ID(MODULE_ID),
		.MARKER_CH(MARKER_CH)
	);
	ChannelProcessor Ch5(.RSTb(RSTb), .CLK(PROCESS_CLK), .CLK_APV(APV_CLK),
		.CH_ENABLE(ENABLE[5]), .ENABLE_BASE_SUB(EN_BASELINE_SUBTRACTION),
		.ADC_PDATA(ADC_PDATA5), .SYNC_PERIOD(SYNC_PERIOD), .COMMON_OFFSET(COMMON_OFFSET),
		.CH_ID({BANK_ID, 3'd5}),
		.RAM_ADDRESS(RAM_ADDR), .RAM_DATA_IN(RAM_DIN[27:16]), .DATA_OUT(FIFO_DATA_OUT5),
		.WE_PEDESTAL_RAM(WE_PED_RAM[2]), .WE_THRESHOLD_RAM(WE_THR_RAM[2]), 
		.RE_PEDESTAL_RAM(RE_PED_RAM[2]), .RE_THRESHOLD_RAM(RE_THR_RAM[2]),
		.FIFO_RD(FIFO_RD[5]),
		.FIFO_USED_WORDS(USED_FIFO_WORDS5),
		.EVENT_PRESENT(ONE_MORE_EVENT[5]), .DECR_EVENT_COUNTER(DECR_EVENT_COUNTER),
		.SYNCED(SYNCED[5]), .ALL_CLEAR(ALL_CLEAR),
		.DAQ_MODE(DAQ_MODE), .ZERO_VAL(LOW_ZERO), .ONE_VAL(HIGH_ONE),
		.NO_MORE_SPACE(no_more_space[5]),
		.FIFO_EMPTY(FIFO_EMPTY[5]), .FIFO_FULL(FIFO_FULL[5]), .MODULE_ID(MODULE_ID),
		.MARKER_CH(MARKER_CH)
	);

	ChannelProcessor Ch6(.RSTb(RSTb), .CLK(PROCESS_CLK), .CLK_APV(APV_CLK),
		.CH_ENABLE(ENABLE[6]), .ENABLE_BASE_SUB(EN_BASELINE_SUBTRACTION),
		.ADC_PDATA(ADC_PDATA6), .SYNC_PERIOD(SYNC_PERIOD), .COMMON_OFFSET(COMMON_OFFSET),
		.CH_ID({BANK_ID, 3'd6}),
		.RAM_ADDRESS(RAM_ADDR), .RAM_DATA_IN(RAM_DIN[11:0]), .DATA_OUT(FIFO_DATA_OUT6),
		.WE_PEDESTAL_RAM(WE_PED_RAM[3]), .WE_THRESHOLD_RAM(WE_THR_RAM[3]), 
		.RE_PEDESTAL_RAM(RE_PED_RAM[3]), .RE_THRESHOLD_RAM(RE_THR_RAM[3]),
		.FIFO_RD(FIFO_RD[6]),
		.FIFO_USED_WORDS(USED_FIFO_WORDS6),
		.EVENT_PRESENT(ONE_MORE_EVENT[6]), .DECR_EVENT_COUNTER(DECR_EVENT_COUNTER),
		.SYNCED(SYNCED[6]), .ALL_CLEAR(ALL_CLEAR),
		.DAQ_MODE(DAQ_MODE), .ZERO_VAL(LOW_ZERO), .ONE_VAL(HIGH_ONE),
		.NO_MORE_SPACE(no_more_space[6]),
		.FIFO_EMPTY(FIFO_EMPTY[6]), .FIFO_FULL(FIFO_FULL[6]), .MODULE_ID(MODULE_ID),
		.MARKER_CH(MARKER_CH)
	);
	ChannelProcessor Ch7(.RSTb(RSTb), .CLK(PROCESS_CLK), .CLK_APV(APV_CLK),
		.CH_ENABLE(ENABLE[7]), .ENABLE_BASE_SUB(EN_BASELINE_SUBTRACTION),
		.ADC_PDATA(ADC_PDATA7), .SYNC_PERIOD(SYNC_PERIOD), .COMMON_OFFSET(COMMON_OFFSET),
		.CH_ID({BANK_ID, 3'd7}),
		.RAM_ADDRESS(RAM_ADDR), .RAM_DATA_IN(RAM_DIN[27:16]), .DATA_OUT(FIFO_DATA_OUT7),
		.WE_PEDESTAL_RAM(WE_PED_RAM[3]), .WE_THRESHOLD_RAM(WE_THR_RAM[3]), 
		.RE_PEDESTAL_RAM(RE_PED_RAM[3]), .RE_THRESHOLD_RAM(RE_THR_RAM[3]),
		.FIFO_RD(FIFO_RD[7]),
		.FIFO_USED_WORDS(USED_FIFO_WORDS7),
		.EVENT_PRESENT(ONE_MORE_EVENT[7]), .DECR_EVENT_COUNTER(DECR_EVENT_COUNTER),
		.SYNCED(SYNCED[7]), .ALL_CLEAR(ALL_CLEAR),
		.DAQ_MODE(DAQ_MODE), .ZERO_VAL(LOW_ZERO), .ONE_VAL(HIGH_ONE),
		.NO_MORE_SPACE(no_more_space[7]),
		.FIFO_EMPTY(FIFO_EMPTY[7]), .FIFO_FULL(FIFO_FULL[7]), .MODULE_ID(MODULE_ID),
		.MARKER_CH(MARKER_CH)
	);

endmodule


module FifoVmeIf(FIFO_RD,
	FIFO_DATA_OUT0, FIFO_DATA_OUT1, FIFO_DATA_OUT2, FIFO_DATA_OUT3,
	FIFO_DATA_OUT4, FIFO_DATA_OUT5, FIFO_DATA_OUT6, FIFO_DATA_OUT7,
	FIFO_DATA_OUT8, FIFO_DATA_OUT9, FIFO_DATA_OUT10, FIFO_DATA_OUT11,
	FIFO_DATA_OUT12, FIFO_DATA_OUT13, FIFO_DATA_OUT14, FIFO_DATA_OUT15,
	USED_FIFO_WORDS0, USED_FIFO_WORDS1, USED_FIFO_WORDS2, USED_FIFO_WORDS3,
	USED_FIFO_WORDS4, USED_FIFO_WORDS5, USED_FIFO_WORDS6, USED_FIFO_WORDS7,
	USED_FIFO_WORDS8, USED_FIFO_WORDS9, USED_FIFO_WORDS10, USED_FIFO_WORDS11,
	USED_FIFO_WORDS12, USED_FIFO_WORDS13, USED_FIFO_WORDS14, USED_FIFO_WORDS15,
	FIFO_EMPTY, FIFO_FULL, SYNCED, ERROR, ENABLE, SYNC_PERIOD,
	RSTb, CLK, WEb, REb, OEb, CEb,
	USER_ADDR, USER_DATA,
	TRIG_GEN_CONFIG, READOUT_CONFIG,
	MISSED_TRIGGER, ONE_THR, ZERO_THR,
	WE_PED_RAM, RE_PED_RAM, WE_THR_RAM, RE_THR_RAM,
	EV_BUILDER_DATA_OUT, EV_BUILDER_ENABLE,
	EV_BUILDER_FIFO_EMPTY, EV_BUILDER_FIFO_FULL,
	EV_BUILDER_FIFO_WC, EV_BUILDER_EV_CNT, MARKER_CH,
	COEFF_0, COEFF_1, COEFF_2, COEFF_3, COEFF_4, COEFF_5, COEFF_6, COEFF_7,
	COEFF_8, COEFF_9, COEFF_10, COEFF_11, COEFF_12, COEFF_13, COEFF_14, COEFF_15);

output [15:0] FIFO_RD;
input [20:0] FIFO_DATA_OUT0, FIFO_DATA_OUT1, FIFO_DATA_OUT2, FIFO_DATA_OUT3;
input [20:0] FIFO_DATA_OUT4, FIFO_DATA_OUT5, FIFO_DATA_OUT6, FIFO_DATA_OUT7;
input [20:0] FIFO_DATA_OUT8, FIFO_DATA_OUT9, FIFO_DATA_OUT10, FIFO_DATA_OUT11;
input [20:0] FIFO_DATA_OUT12, FIFO_DATA_OUT13, FIFO_DATA_OUT14, FIFO_DATA_OUT15;
input [11:0] USED_FIFO_WORDS0, USED_FIFO_WORDS1, USED_FIFO_WORDS2, USED_FIFO_WORDS3;
input [11:0] USED_FIFO_WORDS4, USED_FIFO_WORDS5, USED_FIFO_WORDS6, USED_FIFO_WORDS7;
input [11:0] USED_FIFO_WORDS8, USED_FIFO_WORDS9, USED_FIFO_WORDS10, USED_FIFO_WORDS11;
input [11:0] USED_FIFO_WORDS12, USED_FIFO_WORDS13, USED_FIFO_WORDS14, USED_FIFO_WORDS15;
input [15:0] FIFO_EMPTY, FIFO_FULL, SYNCED, ERROR;
output [15:0] ENABLE;
output [7:0] SYNC_PERIOD;
input RSTb, CLK, WEb, REb, OEb, CEb;
input [21:0] USER_ADDR;
inout [63:0] USER_DATA;
output [31:0] TRIG_GEN_CONFIG;
output [31:0] READOUT_CONFIG;
input [31:0] MISSED_TRIGGER;
output [11:0] ONE_THR, ZERO_THR;
output [7:0] WE_PED_RAM, RE_PED_RAM, WE_THR_RAM, RE_THR_RAM;
input [23:0] EV_BUILDER_DATA_OUT;
input EV_BUILDER_ENABLE;
input EV_BUILDER_FIFO_EMPTY, EV_BUILDER_FIFO_FULL;
input [11:0] EV_BUILDER_FIFO_WC;
input [23:0] EV_BUILDER_EV_CNT;
output [7:0] MARKER_CH;
output [15:0] COEFF_0, COEFF_1, COEFF_2, COEFF_3, COEFF_4, COEFF_5, COEFF_6, COEFF_7;
output [15:0] COEFF_8, COEFF_9, COEFF_10, COEFF_11, COEFF_12, COEFF_13, COEFF_14, COEFF_15;

reg [15:0] ENABLE;
reg [7:0] SYNC_PERIOD;
reg [15:0] FIFO_RD;
reg [31:0] TRIG_GEN_CONFIG;
reg [31:0] READOUT_CONFIG;
reg [31:0] int_data, int_data_Latched;
reg [11:0] ONE_THR, ZERO_THR;
reg [7:0] WE_PED_RAM, RE_PED_RAM, WE_THR_RAM, RE_THR_RAM;
reg [7:0] MARKER_CH;
reg [15:0] COEFF_0, COEFF_1, COEFF_2, COEFF_3, COEFF_4, COEFF_5, COEFF_6, COEFF_7;
reg [15:0] COEFF_8, COEFF_9, COEFF_10, COEFF_11, COEFF_12, COEFF_13, COEFF_14, COEFF_15;

assign USER_DATA = (CEb == 0 && OEb == 0) ?  {32'b0, int_data_Latched} : 64'bz;

always @(*)
begin
	int_data_Latched <= int_data_Latched;
	if( REb == 0 )
		int_data_Latched <= int_data;
end

always @(*)
begin
	FIFO_RD <= 16'b0;
	casex( USER_ADDR[17:0] )
		18'h0_0???: FIFO_RD[0] <= ~REb & ~CEb;
		18'h0_1???: FIFO_RD[1] <= ~REb & ~CEb;
		18'h0_2???: FIFO_RD[2] <= ~REb & ~CEb;
		18'h0_3???: FIFO_RD[3] <= ~REb & ~CEb;
		18'h0_4???: FIFO_RD[4] <= ~REb & ~CEb;
		18'h0_5???: FIFO_RD[5] <= ~REb & ~CEb;
		18'h0_6???: FIFO_RD[6] <= ~REb & ~CEb;
		18'h0_7???: FIFO_RD[7] <= ~REb & ~CEb;
		18'h0_8???: FIFO_RD[8] <= ~REb & ~CEb;
		18'h0_9???: FIFO_RD[9] <= ~REb & ~CEb;
		18'h0_A???: FIFO_RD[10] <= ~REb & ~CEb;
		18'h0_B???: FIFO_RD[11] <= ~REb & ~CEb;
		18'h0_C???: FIFO_RD[12] <= ~REb & ~CEb;
		18'h0_D???: FIFO_RD[13] <= ~REb & ~CEb;
		18'h0_E???: FIFO_RD[14] <= ~REb & ~CEb;
		18'h0_F???: FIFO_RD[15] <= ~REb & ~CEb;
		default: FIFO_RD <= 16'b0;
	endcase
end

always @(*)
begin
	RE_PED_RAM <= 16'b0;
	casex( USER_ADDR[17:0] )
		18'h1_0???: RE_PED_RAM[0] <= ~REb & ~CEb;
		18'h1_1???: RE_PED_RAM[1] <= ~REb & ~CEb;
		18'h1_2???: RE_PED_RAM[2] <= ~REb & ~CEb;
		18'h1_3???: RE_PED_RAM[3] <= ~REb & ~CEb;
		18'h1_4???: RE_PED_RAM[4] <= ~REb & ~CEb;
		18'h1_5???: RE_PED_RAM[5] <= ~REb & ~CEb;
		18'h1_6???: RE_PED_RAM[6] <= ~REb & ~CEb;
		18'h1_7???: RE_PED_RAM[7] <= ~REb & ~CEb;
		default: RE_PED_RAM <= 8'b0;
	endcase
end

always @(*)
begin
	RE_THR_RAM <= 16'b0;
	casex( USER_ADDR[17:0] )
		18'h1_8???: RE_THR_RAM[0] <= ~REb & ~CEb;
		18'h1_9???: RE_THR_RAM[1] <= ~REb & ~CEb;
		18'h1_A???: RE_THR_RAM[2] <= ~REb & ~CEb;
		18'h1_B???: RE_THR_RAM[3] <= ~REb & ~CEb;
		18'h1_C???: RE_THR_RAM[4] <= ~REb & ~CEb;
		18'h1_D???: RE_THR_RAM[5] <= ~REb & ~CEb;
		18'h1_E???: RE_THR_RAM[6] <= ~REb & ~CEb;
		18'h1_F???: RE_THR_RAM[7] <= ~REb & ~CEb;
		default: RE_THR_RAM <= 8'b0;
	endcase
end

always @(*)
begin
	WE_PED_RAM <= 8'b0;
	casex( USER_ADDR[17:0] )
		18'h1_0???: WE_PED_RAM[0] <= ~WEb & ~CEb;
		18'h1_1???: WE_PED_RAM[1] <= ~WEb & ~CEb;
		18'h1_2???: WE_PED_RAM[2] <= ~WEb & ~CEb;
		18'h1_3???: WE_PED_RAM[3] <= ~WEb & ~CEb;
		18'h1_4???: WE_PED_RAM[4] <= ~WEb & ~CEb;
		18'h1_5???: WE_PED_RAM[5] <= ~WEb & ~CEb;
		18'h1_6???: WE_PED_RAM[6] <= ~WEb & ~CEb;
		18'h1_7???: WE_PED_RAM[7] <= ~WEb & ~CEb;
		default: WE_PED_RAM <= 8'b0;
	endcase
end

always @(*)
begin
	WE_THR_RAM <= 8'b0;
	casex( USER_ADDR[17:0] )
		18'h1_8???: WE_THR_RAM[0] <= ~WEb & ~CEb;
		18'h1_9???: WE_THR_RAM[1] <= ~WEb & ~CEb;
		18'h1_A???: WE_THR_RAM[2] <= ~WEb & ~CEb;
		18'h1_B???: WE_THR_RAM[3] <= ~WEb & ~CEb;
		18'h1_C???: WE_THR_RAM[4] <= ~WEb & ~CEb;
		18'h1_D???: WE_THR_RAM[5] <= ~WEb & ~CEb;
		18'h1_E???: WE_THR_RAM[6] <= ~WEb & ~CEb;
		18'h1_F???: WE_THR_RAM[7] <= ~WEb & ~CEb;
		default: WE_THR_RAM <= 8'b0;
	endcase
end

always @(*)
begin
	casex( USER_ADDR[17:0] )
		18'h0_0???: int_data <= EV_BUILDER_ENABLE ? {8'h0, EV_BUILDER_DATA_OUT} : {11'h0, FIFO_DATA_OUT0};
		18'h0_1???: int_data <= {11'h0, FIFO_DATA_OUT1};
		18'h0_2???: int_data <= {11'h0, FIFO_DATA_OUT2};
		18'h0_3???: int_data <= {11'h0, FIFO_DATA_OUT3};
		18'h0_4???: int_data <= {11'h0, FIFO_DATA_OUT4};
		18'h0_5???: int_data <= {11'h0, FIFO_DATA_OUT5};
		18'h0_6???: int_data <= {11'h0, FIFO_DATA_OUT6};
		18'h0_7???: int_data <= {11'h0, FIFO_DATA_OUT7};
		18'h0_8???: int_data <= {11'h0, FIFO_DATA_OUT8};
		18'h0_9???: int_data <= {11'h0, FIFO_DATA_OUT9};
		18'h0_A???: int_data <= {11'h0, FIFO_DATA_OUT10};
		18'h0_B???: int_data <= {11'h0, FIFO_DATA_OUT11};
		18'h0_C???: int_data <= {11'h0, FIFO_DATA_OUT12};
		18'h0_D???: int_data <= {11'h0, FIFO_DATA_OUT13};
		18'h0_E???: int_data <= {11'h0, FIFO_DATA_OUT14};
		18'h0_F???: int_data <= {11'h0, FIFO_DATA_OUT15};
/* ???
		18'h1_0???: int_data <= EV_BUILDER_ENABLE ? {8'h0, EV_BUILDER_DATA_OUT} : {11'h0, FIFO_DATA_OUT0};
		18'h1_1???: int_data <= {11'h0, FIFO_DATA_OUT1};
		18'h1_2???: int_data <= {11'h0, FIFO_DATA_OUT2};
		18'h1_3???: int_data <= {11'h0, FIFO_DATA_OUT3};
		18'h1_4???: int_data <= {11'h0, FIFO_DATA_OUT4};
		18'h1_5???: int_data <= {11'h0, FIFO_DATA_OUT5};
		18'h1_6???: int_data <= {11'h0, FIFO_DATA_OUT6};
		18'h1_7???: int_data <= {11'h0, FIFO_DATA_OUT7};
		18'h1_8???: int_data <= {11'h0, FIFO_DATA_OUT8};
		18'h1_9???: int_data <= {11'h0, FIFO_DATA_OUT9};
		18'h1_A???: int_data <= {11'h0, FIFO_DATA_OUT10};
		18'h1_B???: int_data <= {11'h0, FIFO_DATA_OUT11};
		18'h1_C???: int_data <= {11'h0, FIFO_DATA_OUT12};
		18'h1_D???: int_data <= {11'h0, FIFO_DATA_OUT13};
		18'h1_E???: int_data <= {11'h0, FIFO_DATA_OUT14};
		18'h1_F???: int_data <= {11'h0, FIFO_DATA_OUT15};
??? */

		18'h2_0000: int_data <= EV_BUILDER_ENABLE ? {EV_BUILDER_EV_CNT[15:0], 4'h0, EV_BUILDER_FIFO_WC} :
							{4'h0, USED_FIFO_WORDS1, 4'h0, USED_FIFO_WORDS0};
		18'h2_0001: int_data <= {4'h0, USED_FIFO_WORDS3, 4'h0, USED_FIFO_WORDS2};
		18'h2_0002: int_data <= {4'h0, USED_FIFO_WORDS5, 4'h0, USED_FIFO_WORDS4};
		18'h2_0003: int_data <= {4'h0, USED_FIFO_WORDS7, 4'h0, USED_FIFO_WORDS6};
		18'h2_0004: int_data <= {4'h0, USED_FIFO_WORDS9, 4'h0, USED_FIFO_WORDS8};
		18'h2_0005: int_data <= {4'h0, USED_FIFO_WORDS11, 4'h0, USED_FIFO_WORDS10};
		18'h2_0006: int_data <= {4'h0, USED_FIFO_WORDS13, 4'h0, USED_FIFO_WORDS12};
		18'h2_0007: int_data <= {4'h0, USED_FIFO_WORDS15, 4'h0, USED_FIFO_WORDS14};

		18'h2_0008: int_data <= EV_BUILDER_ENABLE ? {FIFO_FULL[15:1], EV_BUILDER_FIFO_FULL,
						FIFO_EMPTY[15:1], EV_BUILDER_FIFO_EMPTY} : {FIFO_FULL, FIFO_EMPTY};
		18'h2_0009: int_data <= {SYNCED, ERROR};
		18'h2_000A: int_data <= MISSED_TRIGGER;
//		18'h2_000B: int_data <= Reserved for future expansions;

		18'h2_000C: int_data <= READOUT_CONFIG;
		18'h2_000D: int_data <= TRIG_GEN_CONFIG;
		18'h2_000E: int_data <= {4'h0, ONE_THR, 4'h0, ZERO_THR};
		18'h2_000F: int_data <= {MARKER_CH, SYNC_PERIOD, ENABLE};
		18'h2_0010: int_data <= {COEFF_1, COEFF_0};
		18'h2_0011: int_data <= {COEFF_3, COEFF_2};
		18'h2_0012: int_data <= {COEFF_5, COEFF_4};
		18'h2_0013: int_data <= {COEFF_7, COEFF_6};
		18'h2_0014: int_data <= {COEFF_9, COEFF_8};
		18'h2_0015: int_data <= {COEFF_11, COEFF_10};
		18'h2_0016: int_data <= {COEFF_13, COEFF_12};
		18'h2_0017: int_data <= {COEFF_15, COEFF_14};
		default: int_data <= 0;
	endcase
end

always @(posedge CLK or negedge RSTb)
begin
	if( RSTb == 0 )
	begin
		ENABLE <= 0; SYNC_PERIOD <= 0;
		TRIG_GEN_CONFIG <= 0;
		ZERO_THR <= 0;
		ONE_THR <= 0;
		MARKER_CH <= 8'hFF;
	end
	else
	begin
		if( CEb == 0 && WEb == 0 )
		begin
			case( USER_ADDR[17:0] )
				18'h2_000C: READOUT_CONFIG <= USER_DATA[31:0];
				18'h2_000D: TRIG_GEN_CONFIG <= USER_DATA[31:0];
				18'h2_000E:	begin
							ZERO_THR <= USER_DATA[11:0];
							ONE_THR  <= USER_DATA[27:16];
						end
				18'h2_000F: {MARKER_CH, SYNC_PERIOD, ENABLE} <= USER_DATA[31:0];
				18'h2_0010: {COEFF_1, COEFF_0} <= USER_DATA[31:0];
				18'h2_0011: {COEFF_3, COEFF_2} <= USER_DATA[31:0];
				18'h2_0012: {COEFF_5, COEFF_4} <= USER_DATA[31:0];
				18'h2_0013: {COEFF_7, COEFF_6} <= USER_DATA[31:0];
				18'h2_0014: {COEFF_9, COEFF_8} <= USER_DATA[31:0];
				18'h2_0015: {COEFF_11, COEFF_10} <= USER_DATA[31:0];
				18'h2_0016: {COEFF_13, COEFF_12} <= USER_DATA[31:0];
				18'h2_0017: {COEFF_15, COEFF_14} <= USER_DATA[31:0];
			endcase
		end
	end
end

endmodule

