module EventBuilder(RSTb, TIME_CLK, CLK, TRIGGER, ALL_CLEAR, ENABLE_MASK, ENABLE_EVBUILD,
	CH_DATA0, CH_DATA1, CH_DATA2, CH_DATA3, CH_DATA4, CH_DATA5, CH_DATA6, CH_DATA7,
	CH_DATA8, CH_DATA9, CH_DATA10, CH_DATA11, CH_DATA12, CH_DATA13, CH_DATA14, CH_DATA15,
	DATA_RD, EVENT_PRESENT, DECREMENT_EVENT_COUNT, MODULE_ID,
	DATA_OUT, EMPTY, FULL, DATA_OUT_CNT, DATA_OUT_RD, EV_CNT
);

input RSTb, TIME_CLK, CLK, TRIGGER, ALL_CLEAR;
input [15:0] ENABLE_MASK;
input ENABLE_EVBUILD;
input [20:0] CH_DATA0, CH_DATA1, CH_DATA2, CH_DATA3, CH_DATA4, CH_DATA5, CH_DATA6, CH_DATA7;
input [20:0] CH_DATA8, CH_DATA9, CH_DATA10, CH_DATA11, CH_DATA12, CH_DATA13, CH_DATA14, CH_DATA15;
output [15:0] DATA_RD;
input [15:0] EVENT_PRESENT;
output DECREMENT_EVENT_COUNT;
input [11:0] MODULE_ID;
output [23:0] DATA_OUT;
output EMPTY, FULL;
output [11:0] DATA_OUT_CNT;
input DATA_OUT_RD;
output [23:0] EV_CNT;

reg [15:0] DATA_RD;
reg DECREMENT_EVENT_COUNT;

reg [23:0] EventCounter;
reg [47:0] TimeCounter, AsyncTimeCounter;
reg [4:0] ChCounter;
reg [7:0] DataCounter;

reg [7:0] fsm_status;
reg [23:0] data_bus;
reg [11:0] DataWordCount;
reg [23:0] ChannelData;

wire AllEnabledChannelsHaveEvent;
reg EventCounterFifo_Read, TimeCounterFifo_Read, OutputFifo_Write;
wire EventCounterFifo_Empty, EventCounterFifo_Full, TimeCounterFifo_Empty, TimeCounterFifo_Full;
wire [23:0] EventCounterFifo_Data;
wire [47:0] TimeCounterFifo_Data;
reg trigger_pulse, old_trigger, old_trigger2;
reg clear_time_counter;
reg FifoReset, ClearDataCounter;

assign AllEnabledChannelsHaveEvent = ((ENABLE_MASK & EVENT_PRESENT) == ENABLE_MASK) ? 1 : 0;
assign EV_CNT = EventCounter;

always @(posedge CLK)
	FifoReset <= ~RSTb | ALL_CLEAR;

Fifo_16x24 EventCounterFifo(.aclr(FifoReset), .clock(CLK),
	.data(EventCounter), .wrreq(trigger_pulse),
	.q(EventCounterFifo_Data), .rdreq(EventCounterFifo_Read),
	.empty(EventCounterFifo_Empty), .full(EventCounterFifo_Full));

Fifo_16x48 TimeCounterFifo(.aclr(FifoReset), .clock(CLK),
	.data(TimeCounter), .wrreq(trigger_pulse),
	.q(TimeCounterFifo_Data), .rdreq(TimeCounterFifo_Read),
	.empty(TimeCounterFifo_Empty), .full(TimeCounterFifo_Full));

assign DATA_OUT_CNT[11] = FULL;
Fifo_2048x24 OutputFifo(.aclr(FifoReset), .clock(CLK),
	.data(data_bus), .wrreq(OutputFifo_Write),
	.q(DATA_OUT), .rdreq(DATA_OUT_RD),
	.empty(EMPTY), .full(FULL), .usedw(DATA_OUT_CNT[10:0]));

// trigger_pulse
	always @(posedge CLK or negedge RSTb)
	begin
		if( RSTb == 0 )
		begin
			trigger_pulse <= 0;
			old_trigger <= 0;
			old_trigger2 <= 0;
		end
		else
		begin
			old_trigger <= TRIGGER;
			old_trigger2 <= old_trigger;
			if( old_trigger2 == 0 && old_trigger == 1 )
				trigger_pulse <= 1;
			else
				trigger_pulse <= 0;
		end
	end

// Data Counter (for checking)
	always @(posedge CLK or negedge RSTb)
	begin
		if( RSTb == 0 )
			DataCounter <= 0;
		else
		begin
			if( ClearDataCounter == 1 )
				DataCounter <= 0;
			else
				if( |DATA_RD )
					DataCounter <= DataCounter + 1;
		end
	end

// EVENT Counter
	always @(posedge CLK or negedge RSTb)
	begin
		if( RSTb == 0 )
			EventCounter <= 0;
		else
		begin
			if( ALL_CLEAR == 1 )
				EventCounter <= 0;
			else
				if( trigger_pulse == 1 )
					EventCounter <= EventCounter + 1;
		end
	end

// TIME Counter
	always @(posedge TIME_CLK)
		clear_time_counter <= ALL_CLEAR;

	always @(posedge TIME_CLK or negedge RSTb)
	begin
		if( RSTb == 0 )
			AsyncTimeCounter <= 0;
		else
		begin
			if( clear_time_counter == 1 )
				AsyncTimeCounter <= 0;
			else
				AsyncTimeCounter <= AsyncTimeCounter + 1;
		end
	end
// Everything must be synchronous with CLK
	always @(posedge CLK)
		TimeCounter <= AsyncTimeCounter;

// Channel Data Selector
	always @(*)
	begin
		case(ChCounter[3:0])
			4'd0:  ChannelData <= {3'b000, CH_DATA0};
			4'd1:  ChannelData <= {3'b000, CH_DATA1};
			4'd2:  ChannelData <= {3'b000, CH_DATA2};
			4'd3:  ChannelData <= {3'b000, CH_DATA3};
			4'd4:  ChannelData <= {3'b000, CH_DATA4};
			4'd5:  ChannelData <= {3'b000, CH_DATA5};
			4'd6:  ChannelData <= {3'b000, CH_DATA6};
			4'd7:  ChannelData <= {3'b000, CH_DATA7};
			4'd8:  ChannelData <= {3'b000, CH_DATA8};
			4'd9:  ChannelData <= {3'b000, CH_DATA9};
			4'd10: ChannelData <= {3'b000, CH_DATA10};
			4'd11: ChannelData <= {3'b000, CH_DATA11};
			4'd12: ChannelData <= {3'b000, CH_DATA12};
			4'd13: ChannelData <= {3'b000, CH_DATA13};
			4'd14: ChannelData <= {3'b000, CH_DATA14};
			4'd15: ChannelData <= {3'b000, CH_DATA15};
		endcase
	end

// Main FSM
	always @(posedge CLK or negedge RSTb)
	begin
		if( RSTb == 0 )
		begin
			DATA_RD <= 0;
			DECREMENT_EVENT_COUNT <= 0;
			ChCounter <= 0;
			EventCounterFifo_Read <= 0;
			TimeCounterFifo_Read <= 0;
			OutputFifo_Write <= 0;
			DataWordCount <= 0;
			data_bus <= 0;
			ClearDataCounter <= 0;
			fsm_status <= 0;
		end
		else
		begin
			case( fsm_status )
				0:	begin
						DATA_RD <= 0;
						DECREMENT_EVENT_COUNT <= 0;
						ChCounter <= 0;
						EventCounterFifo_Read <= 0;
						TimeCounterFifo_Read <= 0;
						OutputFifo_Write <= 0;
						DataWordCount <= 0;
						ClearDataCounter <= 0;
						if( ENABLE_EVBUILD & AllEnabledChannelsHaveEvent )
							fsm_status <= 1;
					end
				1:	begin	// Starting sequence: EventCounter + TimeCounter
						data_bus <= EventCounterFifo_Data;
						OutputFifo_Write <= 1;
						EventCounterFifo_Read <= 1;
						fsm_status <= 2;
					end
				2:	begin
						data_bus <= TimeCounterFifo_Data[47:24];
						EventCounterFifo_Read <= 0;
						fsm_status <= 3;
					end
				3:	begin
						data_bus <= TimeCounterFifo_Data[23:0];
						TimeCounterFifo_Read <= 1;
						ClearDataCounter <= 1;
						fsm_status <= 4;
					end
				4:	begin
						TimeCounterFifo_Read <= 0;
						ClearDataCounter <= 0;
						OutputFifo_Write <= 0;
						data_bus <= ChannelData;
						if( ENABLE_MASK[ChCounter[3:0]] & EVENT_PRESENT[ChCounter[3:0]] )
						begin
							data_bus <= ChannelData;
							fsm_status <= 6;
							DATA_RD[ChCounter[3:0]] <= 1;
						end
						else
							fsm_status <= 5;
					end
				5:	begin
						if( ChCounter != 5'h10 )
						begin
							ChCounter <= ChCounter + 1;
							fsm_status <= 4;
						end
						else
							fsm_status <= 9;
					end

				6:	begin	// Main copying loop
						data_bus <= ChannelData;
						DataWordCount <= DataWordCount + 1;
						OutputFifo_Write <= 1;
						if( ChannelData[20:19] == 2'b11 || DataCounter > 133 ) // Channel Trailer ID
						begin
							DATA_RD[ChCounter[3:0]] <= 0;
							fsm_status <= 7;
						end
					end
				7:	begin
						data_bus <= ChannelData;
						OutputFifo_Write <= 0;
						DataWordCount <= DataWordCount + 1;
						fsm_status <= 8;	// Write channel trailer
					end
				8:	begin
						if( ChCounter != 5'h0F )
						begin
							ChCounter <= ChCounter + 1;
							fsm_status <= 4;
						end
						else
							fsm_status <= 9;

					end

				9:	begin	// Closing sequence
						data_bus <= {MODULE_ID, DataWordCount};
						OutputFifo_Write <= 1;
						DECREMENT_EVENT_COUNT <= 1;
						fsm_status <= 10;
					end
				10:	begin
						data_bus <= 0;	// TRAILER: 2 words = 0 ???
						DECREMENT_EVENT_COUNT <= 0;
						fsm_status <= 11;
					end
				11:	begin
						fsm_status <= 0;
					end

				12:	begin
					end
				13:	begin
					end
				default: fsm_status <= 0;
			endcase
		end
	end

endmodule

