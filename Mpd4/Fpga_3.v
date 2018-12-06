
module Fpga(
	MASTER_RESETb,
	MASTER_CLOCK,	// 40 MHz local oxillatror
	MASTER_CLOCK2,	// 40 MHz from front panel

	VME_D, VME_A, VME_AM, VME_GA, VME_WRITEb, VME_DS0b, VME_DS1b, VME_ASb,
	VME_IACKb, VME_IACKINb, VME_IACKOUTb, VME_DTACKb, VME_BERRb, VME_RETRYb,
	VME_IRQ, VME_ADIR, VME_AOEb, VME_DDIR, VME_DOEb,
	VME_DTACK_EN, VME_BERR_EN, VME_RETRY_EN,
	VME_LIIb, VME_LIOb,

	ADC_DATA, ADC_RESETb, ADC_CS1b, ADC_CS2b, ADC_SCLK, ADC_SDA,
	ADC_LCLK1, ADC_LCLK2, ADC_FRAME_CK1, ADC_FRAME_CK2, ADC_CONV_CK,

	APV_CLOCK, APV_TRIGGER, APV_RESET,

	I2C_SCL, I2C_SDA_IN, I2C_SDA_OUT,

	USER_IN_TTL, USER_IN_NIM, USER_OUT, SEL_OUT,

	MII_25MHZ_CLOCK, MII_MDC, MII_MDIO,
	MII_TX_CLK, MII_TX_EN, MII_TXD,
	MII_RX_CLK, MII_RX_DV, MII_RX_ER, MII_RXD,
	MII_CRS, MII_COL, MII_RESETb,

	SDRAM_A, SDRAM_BA, SDRAM_CASb, SDRAM_CKE, SDRAM_CSb, SDRAM_DM, SDRAM_ODT,
	SDRAM_RASb, SDRAM_WEb, SDRAM_CK, SDRAM_CKb, SDRAM_DQ, SDRAM_DQS,

	SD_DAT2, SD_DAT1, SD_DAT0, SD_DETECT, SD_CD, SD_CMD, SD_CLK,

	READ1, READ_CLK1,
	READ2, READ_CLK2,

	LED, SWITCH,

	GXB_TX, GXB_RX, GXB_PRESENT, GXB_TX_DISABLE, GXB_RX_LOS, GXB_CK,

	TOKEN_OUT_P0, TOKEN_OUT_P2, TOKEN_IN_P0, TOKEN_IN_P2,
	TRIG_OUT, BUSY_OUT, SD_LINK_OUT,
	TRIG1_IN, TRIG2_IN, SYNC_IN, STATBIT_A_IN, STATBIT_B_IN,
	CLK_IN_P0,	// 62.5 MHz LVDS from backplane P0 connector
	STATBIT_A_OUT,

	SPARE1, SPARE2, SPARE3,
	
	SPARE33,
	SPARE25,
	SPARE_CLK_LVDS, SPARE_CLK_TTL
);
// Port interface definition
input MASTER_RESETb, MASTER_CLOCK, MASTER_CLOCK2;

inout [31:0] VME_D, VME_A;	// VME_A[0] = LWORD
input [5:0] VME_AM;
input [5:0] VME_GA;	// GA[5] = GAP
input VME_WRITEb, VME_DS0b, VME_DS1b, VME_ASb, VME_IACKb, VME_IACKINb;
output VME_IACKOUTb, VME_DTACKb, VME_BERRb, VME_RETRYb;
output [7:1] VME_IRQ;
output VME_ADIR, VME_AOEb, VME_DDIR, VME_DOEb;
output VME_DTACK_EN, VME_BERR_EN, VME_RETRY_EN;
input VME_LIIb;
output VME_LIOb;

input [15:0] ADC_DATA;	// 480 Mb/s data streams (LVDS)
output ADC_RESETb, ADC_CS1b, ADC_CS2b, ADC_SCLK, ADC_SDA;
input ADC_LCLK1, ADC_LCLK2;	// 240 MHz DDR clock from ADC (LVDS)
input ADC_FRAME_CK1, ADC_FRAME_CK2;		// Word clock from ADC
output ADC_CONV_CK; // 40 MHz clock (LVDS)

output 	APV_CLOCK, APV_TRIGGER;	// (2.5V LVTTL)
output 	APV_RESET;

output I2C_SCL;
input I2C_SDA_IN;
output I2C_SDA_OUT;

input [1:0] USER_IN_TTL, USER_IN_NIM;
output [1:0] USER_OUT, SEL_OUT;

output MII_25MHZ_CLOCK, MII_MDC;
inout MII_MDIO;
input MII_TX_CLK;
output MII_TX_EN;
output [3:0] MII_TXD;
input MII_RX_CLK, MII_RX_DV, MII_RX_ER;
input [3:0] MII_RXD;
input MII_CRS, MII_COL;
output MII_RESETb;

output [13:0] SDRAM_A;	// was [12:0]
output [2:0] SDRAM_BA;	// was [1:0]
output SDRAM_CASb;
output SDRAM_CKE, SDRAM_CSb;	// was [1:0]
output SDRAM_DM, SDRAM_RASb, SDRAM_WEb;
output SDRAM_ODT;
inout SDRAM_CK, SDRAM_CKb;
inout [7:0] SDRAM_DQ;
inout SDRAM_DQS;

inout SD_DAT2, SD_DAT1, SD_DAT0;
input SD_DETECT, SD_CD;
output SD_CMD, SD_CLK;

output READ_CLK1, READ1, READ_CLK2, READ2;

output [3:0] LED;
input [3:0] SWITCH;

output GXB_TX, GXB_TX_DISABLE;
input GXB_RX, GXB_PRESENT, GXB_RX_LOS, GXB_CK;

output TOKEN_OUT_P0, TOKEN_OUT_P2;
input TOKEN_IN_P0, TOKEN_IN_P2;
output TRIG_OUT, BUSY_OUT, SD_LINK_OUT;
input TRIG1_IN, TRIG2_IN, SYNC_IN, STATBIT_A_IN, STATBIT_B_IN, CLK_IN_P0;
output STATBIT_A_OUT;

// To Test & PMC connectors
inout SPARE1, SPARE2, SPARE3;

// To PMC connectors
inout [16:0] SPARE33;	// 3.3 V I/O
inout [25:0] SPARE25;	// 2.5 V I/O

output SPARE_CLK_LVDS;	// LVDS clock
output SPARE_CLK_TTL;	// 2.5 V clock

// End of port interface definition


wire [11:0] adc0, adc1, adc2, adc3, adc4, adc5, adc6, adc7;
wire [11:0] adc8, adc9, adc10, adc11, adc12, adc13, adc14, adc15;
wire [11:0] adcx0, adcx1, adcx2, adcx3, adcx4, adcx5, adcx6, adcx7;
wire [11:0] adcx8, adcx9, adcx10, adcx11, adcx12, adcx13, adcx14, adcx15;
wire [63:0] user_d;
wire [15:0] gxb_rxd;

wire [1:0] internal_user_in, sel_in_ttl, sel_out_ttl;

wire ck_40MHz_Apv, ck_40MHz_Adc, ck_60MHz, ck_1MHz, time_clock, Vme_clock;
wire ck_10MHz, ck_10MHz_AdcSpi;
wire user_reB, user_weB, user_oeB;
wire [21:0] user_addr;
wire [7:0] user_ceB;
wire DataReadout_ceB;
wire AdcConfig_ceB, I2C_Controller_ceB, Sdram_ceB;
wire Histogrammer_ceB, Histogrammer0_ceB, Histogrammer1_ceB, ApvFifo_ceB;
wire [31:0] missing_trigger_count;
wire [15:0] ApvSynced, ApvFifoEmpty, ApvFifoFull, ApvError, ApvEnable, ApvFifo_read, ApvFifoRd_EVB,
	OneMoreEvent, ApvEndFrame, ApvFrameGate;
wire [31:0] TrigGenConfig, ReadoutConfig;
wire [2:0] TrigMode, ReadoutMode;
wire [7:0] ApvSyncPeriod;
wire [20:0] ApvFifoData0, ApvFifoData1, ApvFifoData2, ApvFifoData3,
	ApvFifoData4, ApvFifoData5, ApvFifoData6, ApvFifoData7,
	ApvFifoData8, ApvFifoData9, ApvFifoData10, ApvFifoData11,
	ApvFifoData12, ApvFifoData13, ApvFifoData14, ApvFifoData15;
wire [11:0] one_threshold, zero_threshold;

wire apv_reset101;
wire HeaderSeen07, HeaderSeen815;

wire Vme_user_reB, Vme_user_weB, Vme_user_oeB;
wire [21:0] Vme_user_addr;
wire [7:0] Vme_user_ceB;

wire scl_oeB, sda_oeB, i2c_ApvReset;
wire internal_trigger_disabled;
wire ReadoutTestMode, AllFifoClear, TrigTestMode, sw_apv_trig, sw_apv_reset;
wire [7:0] ResetLatency, CalibLatency;
wire [3:0] MaxTrigOut;
wire EnTrig1P0, EnTrig2P0, EnTrigFront, EnSyncP0, EnSyncFront, trigger, trigger_pulse, sync;


wire no_more_space07, no_more_space815, space_available07, space_available815;
wire fwd07, fwd815;
wire DecrEventCounter;
wire [11:0] used_fifo_words0, used_fifo_words1, used_fifo_words2, used_fifo_words3,
	used_fifo_words4, used_fifo_words5, used_fifo_words6, used_fifo_words7,
	used_fifo_words8, used_fifo_words9, used_fifo_words10, used_fifo_words11,
	used_fifo_words12, used_fifo_words13, used_fifo_words14, used_fifo_words15;

wire [7:0] we_ped_ram, re_ped_ram, we_thr_ram, re_thr_ram;
wire [11:0] common_offset;
wire en_baseline_subtraction;
wire Enable_EventBuilder;
wire [23:0] EvBuilderDataOut;
wire EventBuilder_Empty, EventBuilder_Full;
wire [11:0] EventBuilder_Wc;
wire [23:0] EventBuilder_EvCnt;
wire RSTb_sync;
wire [7:0] MarkerCh;


	wire [31:0] trigger_counter;
	wire trigger_time_fifo_rd, trigger_time_fifo_full, trigger_time_fifo_empty;
	wire [7:0] trigger_time_fifo_data;

	wire ck_40MHz_from_Bkplane, P0CkPll_Locked, ck_40MHz_Main;
	wire pll_clock_switch1, pll_clock_switch2;
	wire enable_fir;
	wire [15:0] fir_coeff0, fir_coeff1, fir_coeff2, fir_coeff3, fir_coeff4, fir_coeff5, fir_coeff6, fir_coeff7;
	wire [15:0] fir_coeff8, fir_coeff9, fir_coeff10, fir_coeff11, fir_coeff12, fir_coeff13, fir_coeff14, fir_coeff15;

assign SPARE33 = 0;
assign SPARE25 = 0;
assign SPARE_CLK_TTL = 0;
assign SPARE_CLK_LVDS = SPARE_CLK_TTL;
	
assign VME_LIOb = 1;
assign MII_RESETb = RSTb_sync;
assign MII_MDC = 0;
assign MII_TX_EN = 0;
assign MII_TXD = 4'b0;
assign GXB_TX_DISABLE = GXB_RX_LOS | GXB_PRESENT;

assign TOKEN_OUT_P0 = TOKEN_IN_P0;
assign TOKEN_OUT_P2 = TOKEN_IN_P2;
assign TRIG_OUT = TRIG1_IN | TRIG2_IN;
assign BUSY_OUT = internal_trigger_disabled;
assign STATBIT_A_OUT = STATBIT_A_IN | STATBIT_B_IN;
assign SD_LINK_OUT = 0;

assign SD_CMD = 0;
assign SD_CLK = 0;

assign READ1 = 1'b0;	// Additional control signals not yet implemented
assign READ2 = 1'b0;	// Additional control signals not yet implemented
assign READ_CLK1 = 1'b0;// Additional control signals not yet implemented
assign READ_CLK2 = 1'b0;// Additional control signals not yet implemented
 
assign ck_10MHz_AdcSpi = ck_10MHz;
assign ADC_RESETb = RSTb_sync;
assign ADC_CONV_CK = ck_40MHz_Adc;
assign APV_RESET = RSTb_sync & ~i2c_ApvReset;

assign AdcConfig_ceB = user_ceB[1];
assign I2C_Controller_ceB = user_ceB[2];
assign Histogrammer_ceB = user_ceB[3];
assign Histogrammer0_ceB = Histogrammer_ceB |  user_addr[13];
assign Histogrammer1_ceB = Histogrammer_ceB | ~user_addr[13];
assign ApvFifo_ceB = user_ceB[4];
assign Sdram_ceB = user_ceB[5];

assign I2C_SDA_OUT = (sda_oeB == 0) ? 0 : 1'bz;
assign I2C_SCL = (scl_oeB == 0) ? 0 : 1'bz;
//assign I2C_SCL = scl_oeB;


assign internal_user_in[0] = ~sel_in_ttl[0] ? USER_IN_TTL[0] : ~USER_IN_NIM[0];	// LVTTL default
assign internal_user_in[1] = ~sel_in_ttl[1] ? USER_IN_TTL[1] : ~USER_IN_NIM[1];	// LVTTL default

assign SEL_OUT[0] = sel_out_ttl[0];	// LVTTL default
assign SEL_OUT[1] = sel_out_ttl[1];	// LVTTL default

assign USER_OUT[0] = SEL_OUT[0] ? internal_trigger_disabled : ~internal_trigger_disabled;	// BUSY signal
assign USER_OUT[1] = SEL_OUT[1] ? ck_40MHz_Adc : ~ck_40MHz_Adc;

assign SPARE1 = 0;
assign SPARE2 = 0;
assign SPARE3 = 0;



// Some selector can be implemented
assign user_reB  = Vme_user_reB;
assign user_weB  = Vme_user_weB;
assign user_oeB  = Vme_user_oeB;
assign user_addr = Vme_user_addr;
assign user_ceB  = Vme_user_ceB;


assign ReadoutMode = ReadoutConfig[2:0];
//						DisableMode              = (DAQ_MODE == 3'b000);
//						ApvReadoutMode_Simple    = (DAQ_MODE == 3'b001);
//						SampleMode               = (DAQ_MODE == 3'b010);
//						ApvReadoutMode_Processed = (DAQ_MODE == 3'b011);
assign enable_fir = ReadoutConfig[4];
assign sel_in_ttl[0] = ReadoutConfig[8];
assign sel_in_ttl[1] = ReadoutConfig[9];
assign sel_out_ttl[0] = ReadoutConfig[10];
assign sel_out_ttl[1] = ReadoutConfig[11];
assign ReadoutTestMode = ReadoutConfig[15];	// NOT USED
assign common_offset = ReadoutConfig[27:16];
assign en_baseline_subtraction = ReadoutConfig[28];
assign Enable_EventBuilder = ReadoutConfig[30];
assign AllFifoClear = ReadoutConfig[31];

assign ResetLatency = TrigGenConfig[7:0];
assign MaxTrigOut = TrigGenConfig[11:8];
assign TrigMode = TrigGenConfig[14:12];
//						trig_disable      = (TRIG_MODE == 3'b000);
//						trig_apv_normal   = (TRIG_MODE == 3'b001);
//						trig_apv_multiple = (TRIG_MODE == 3'b010);
//						calib_trig_apv    = (TRIG_MODE == 3'b011);
assign TrigTestMode = TrigGenConfig[15];	// NOT USED
assign EnSyncP0 = TrigGenConfig[16];
assign EnSyncFront = TrigGenConfig[17];
assign sw_apv_trig = TrigGenConfig[18];
assign sw_apv_reset = TrigGenConfig[19];
assign EnTrig1P0 = TrigGenConfig[21];
assign EnTrig2P0 = TrigGenConfig[22];
assign EnTrigFront = TrigGenConfig[23];
assign CalibLatency = TrigGenConfig[31:24];	// effective latency = CalibLatency + 4


// TBD: CHECK THAT BOTH trigger AND sync SIGNALS WIDTH MUST BE AT LEAST 25 ns
// TBD: NEED TO SYNCHRONIZE THEM ???
assign trigger = (EnTrig1P0 & TRIG1_IN) |
		 (EnTrig2P0 & TRIG2_IN) |
		 (EnTrigFront & internal_user_in[0]) |
		 sw_apv_trig;

assign sync = (EnSyncP0 & SYNC_IN) | (EnSyncFront & internal_user_in[1]) | sw_apv_reset;

// MASTER_RESETb synchronizer
SyncReset ResetSynchronizer(.CK(MASTER_CLOCK), .ASYNC_RSTb(MASTER_RESETb),
	.SYNC_RSTb(RSTb_sync));

assign APV_CLOCK = ck_40MHz_Apv;
assign time_clock = CLK_IN_P0;

	OneShot TurnOnLed0(.OUT(LED[0]), .START(VME_DTACK_EN), .CK(ck_1MHz), .RSTb(RSTb_sync));
	OneShot TurnOnLed1(.OUT(LED[1]), .START(APV_TRIGGER),  .CK(ck_1MHz), .RSTb(RSTb_sync));
	OneShot TurnOnLed2(.OUT(LED[2]), .START(~I2C_SCL),     .CK(ck_1MHz), .RSTb(RSTb_sync));
	OneShot TurnOnLed3(.OUT(LED[3]), .START(1'b0),         .CK(ck_1MHz), .RSTb(RSTb_sync));

// Clocking devices
// CLK_IN_P0 = 62.5 MHz = 250 MHz / 4
// A PLL is used to generate 40 MHz from CLK_IN_P0 
// A MUX is implemented to choose between P0 generated and FrontPanel clock
// A PLL is used to generate all needed clock, choosing between local oscillator and the output of the MUX
P0CK_Pll P0Clk_Pll_Inst(
	.inclk0(CLK_IN_P0),	// 62.5 MHz
	.c0(ck_40MHz_from_Bkplane),	// 40 MHz
	.locked(P0CkPll_Locked));

assign pll_clock_switch1 = SWITCH[0];	// default = OPEN = OFF = 1
assign pll_clock_switch2 = SWITCH[1];	// default = OPEN = OFF = 1
/* pll_clock_switch1 pll_clock_switch2 Main clock source
 *       0 (ON)            0 (ON)          CLK_IN_P0 (40 MHz, PLL generated from 62.5 MHz)
 *       0 (ON)            1 (OFF)         MASTER_CLOCK2 (40 MHz, front panel clock)
 *       1 (OFF)           0 (ON)          MASTER_CLOCK (40 MHz, local oscillator)
 *       1 (OFF) *         1 (OFF) *       MASTER_CLOCK (40 MHz, local oscillator)
 *
 * Switch default: *
 */

// Connection for CK40_MUX are very crytical for P&R: do not modify them
CK40_MUX Ck40Mux_Inst(
	.clkselect(pll_clock_switch2),	// OFF = MASTER_CLOCK2 (front panel clock)
	.inclk0x(ck_40MHz_from_Bkplane),
	.inclk1x(MASTER_CLOCK2),
	.outclk(ck_40MHz_Main));

GlobalPll ClockGenerator(
	.clkswitch(pll_clock_switch1),	// OFF = MASTER_CLOCK (local oscillator)
	.inclk0(ck_40MHz_Main),
	.inclk1(MASTER_CLOCK),
	.c0(ck_60MHz),
	.c1(ck_40MHz_Adc),
	.c2(ck_40MHz_Apv),
	.c3(MII_25MHZ_CLOCK),
	.c4(ck_10MHz),
	.c5(ck_1MHz));	// 1.2 MHz
// End of Clocking devices

// Dummy connections !!! For fill up FPGA Only !!!
Gxb OpticalLinkIf(.cal_blk_clk(ck_60MHz),
	.gxb_powerdown(1'b0),
	.pll_inclk(GXB_CK),
	.rx_analogreset(),
	.rx_cruclk(ck_60MHz),
	.rx_datain(GXB_RX),
	.rx_digitalreset(),
	.tx_ctrlenable(),
	.tx_datain(gxb_rxd),
	.tx_digitalreset(),
	.rx_ctrldetect(),
	.rx_dataout(gxb_rxd),
	.rx_disperr(),
	.rx_errdetect(),
	.tx_clkout(),
	.tx_dataout(GXB_TX));

assign Vme_clock = ck_60MHz;
/*
Ddr2SdramIf Ddr2SdramIf_inst(
	.aux_full_rate_clk (mem_aux_full_rate_clk),	// output
	.aux_half_rate_clk (mem_aux_half_rate_clk),	// output
	.dll_reference_clk (dll_reference_clk),		// output
	.dqs_delay_ctrl_export (dqs_delay_ctrl_export),	// output
	.global_reset_n (RSTb_sync),

	.local_init_done (init_done),	// output
	.local_refresh_ack (),		// output
	.local_burstbegin (local_burstbegin),
	.local_be (mem_local_be),			// [3:0]
	.local_size (mem_local_size),

	.local_address (mem_local_addr),	// [24:0]

	.local_rdata (mem_local_rdata),
	.local_read_req (mem_local_read_req),
	.local_rdata_valid (mem_local_rdata_valid),

	.local_wdata (mem_local_wdata),
	.local_write_req (mem_local_write_req),
	.local_ready (mem_local_ready),

	.mem_addr (SDRAM_A),
	.mem_ba (SDRAM_BA),
	.mem_cas_n (SDRAM_CASb),
	.mem_cke (SDRAM_CKE),
	.mem_clk (SDRAM_CK),
	.mem_clk_n (SDRAM_CKb),
	.mem_cs_n (SDRAM_CSb),
	.mem_dm (SDRAM_DM),
	.mem_dq (SDRAM_DQ),
	.mem_dqs (SDRAM_DQS),
	.mem_ras_n (SDRAM_RASb),
	.mem_we_n (SDRAM_WEb),
	.mem_odt (SDRAM_ODT),

	.phy_clk (Vme_clock),		// output 110 MHz

	.pll_ref_clk (MASTER_CLOCK),		// input 40 MHz
	.reset_phy_clk_n (),		// output
	.reset_request_n (),		// output
	.soft_reset_n (1'b1)
    );
*/

VmeSlaveIf VmeIf(
	.VME_A(VME_A[31:1]), .VME_AM(VME_AM), .VME_D(VME_D),
	.VME_ASb(VME_ASb), .VME_DS1b(VME_DS1b), .VME_DS0b(VME_DS0b),
	.VME_WRITEb(VME_WRITEb), .VME_LWORDb(VME_A[0]), .VME_IACKb(VME_IACKb),
	.VME_IackInb(VME_IACKINb), .VME_IackOutb(VME_IACKOUTb),
	.VME_IRQ(VME_IRQ), .VME_DTACK(VME_DTACKb), .VME_BERR(VME_BERRb),
	.VME_DTACK_EN(VME_DTACK_EN), .VME_BERR_EN(VME_BERR_EN),
	.VME_RETRY(VME_RETRYb), .VME_RETRY_EN(VME_RETRY_EN),
	.VME_GAb(VME_GA[4:0]), .VME_GAPb(VME_GA[5]),
	.VME_DATA_DIR(VME_DDIR), .VME_DBUF_OEb(VME_DOEb),
	.VME_ADDR_DIR(VME_ADIR), .VME_ABUF_OEb(VME_AOEb),
	.USER_D64(1'b1),	// Permit VME 64 bit data transactions
	.USER_VME64BIT(),	// 64 bit VME data transaction: USER_ADDR[0] is meaningless
	.USER_ADDR(Vme_user_addr), // 22 bit
    .USER_DATA(user_d), // 64 bit
	.USER_WEb(Vme_user_weB), .USER_REb(Vme_user_reB), .USER_OEb(Vme_user_oeB),
	.USER_CEb(Vme_user_ceB), // 8 bit
	.USER_IRQb(7'h7F), // 7 bit
	.USER_WAITb(1'b1),
	.USER_STATUS(), .USER_CTRL(), .VME_CYCLE_IN_PROGRESS(),
	.RESETb(RSTb_sync),
	.CLK(Vme_clock),
	.DEBUG());

AdcConfigMachine AdcConfigurator(
	.RSTb(RSTb_sync), .CLK(Vme_clock),
	.WEb(user_weB), .REb(user_reB), .OEb(user_oeB), .CEb(AdcConfig_ceB),
	.USER_DATA(user_d),
	.AdcConfigClk(ck_10MHz_AdcSpi),
	.ADC_CS1b(ADC_CS1b), .ADC_CS2b(ADC_CS2b), .ADC_SCLK(ADC_SCLK), .ADC_SDA(ADC_SDA));

i2c_master_top I2C_Controller(
	.wb_clk_i(Vme_clock), .wb_rst_i(1'b0), .arst_i(RSTb_sync), .wb_adr_i(user_addr[2:0]),
	.dat(user_d), .weB(user_weB), .reB(user_reB), .oeB(user_oeB), .ceB(I2C_Controller_ceB),
	.scl_pad_i(I2C_SCL), .scl_pad_o(), .scl_padoen_o(scl_oeB),
	.sda_pad_i(I2C_SDA_IN), .sda_pad_o(), .sda_padoen_o(sda_oeB),
	.ApvReset(i2c_ApvReset) );





AdcDeser AdcDeser0(.ADC_SDATA(ADC_DATA[7:0]), .LCLK(ADC_LCLK1), .ADCLK(ADC_FRAME_CK1),
	.ADC_PDATA0(adc0), .ADC_PDATA1(adc1), .ADC_PDATA2(adc2), .ADC_PDATA3(adc3),
	.ADC_PDATA4(adc4), .ADC_PDATA5(adc5), .ADC_PDATA6(adc6), .ADC_PDATA7(adc7));

AdcDeser AdcDeser1(.ADC_SDATA(ADC_DATA[15:8]), .LCLK(ADC_LCLK2), .ADCLK(ADC_FRAME_CK2),
	.ADC_PDATA0(adc8), .ADC_PDATA1(adc9), .ADC_PDATA2(adc10), .ADC_PDATA3(adc11),
	.ADC_PDATA4(adc12), .ADC_PDATA5(adc13), .ADC_PDATA6(adc14), .ADC_PDATA7(adc15));
/*
fir_16tap fir0(.CLK(ADC_FRAME_CK1), .ENABLE_FIR(enable_fir), .DATA_IN(adc0), .DATA_OUT(adcx0),
	.COEFF_0(fir_coeff0), .COEFF_1(fir_coeff1), .COEFF_2(fir_coeff2), .COEFF_3(fir_coeff3),
	.COEFF_4(fir_coeff4), .COEFF_5(fir_coeff5), .COEFF_6(fir_coeff6), .COEFF_7(fir_coeff7),
	.COEFF_8(fir_coeff8), .COEFF_9(fir_coeff9), .COEFF_10(fir_coeff10), .COEFF_11(fir_coeff11),
	.COEFF_12(fir_coeff12), .COEFF_13(fir_coeff13), .COEFF_14(fir_coeff14), .COEFF_15(fir_coeff15));

fir_16tap fir1(.CLK(ADC_FRAME_CK1), .ENABLE_FIR(enable_fir), .DATA_IN(adc1), .DATA_OUT(adcx1),
	.COEFF_0(fir_coeff0), .COEFF_1(fir_coeff1), .COEFF_2(fir_coeff2), .COEFF_3(fir_coeff3),
	.COEFF_4(fir_coeff4), .COEFF_5(fir_coeff5), .COEFF_6(fir_coeff6), .COEFF_7(fir_coeff7),
	.COEFF_8(fir_coeff8), .COEFF_9(fir_coeff9), .COEFF_10(fir_coeff10), .COEFF_11(fir_coeff11),
	.COEFF_12(fir_coeff12), .COEFF_13(fir_coeff13), .COEFF_14(fir_coeff14), .COEFF_15(fir_coeff15));

fir_16tap fir2(.CLK(ADC_FRAME_CK1), .ENABLE_FIR(enable_fir), .DATA_IN(adc2), .DATA_OUT(adcx2),
	.COEFF_0(fir_coeff0), .COEFF_1(fir_coeff1), .COEFF_2(fir_coeff2), .COEFF_3(fir_coeff3),
	.COEFF_4(fir_coeff4), .COEFF_5(fir_coeff5), .COEFF_6(fir_coeff6), .COEFF_7(fir_coeff7),
	.COEFF_8(fir_coeff8), .COEFF_9(fir_coeff9), .COEFF_10(fir_coeff10), .COEFF_11(fir_coeff11),
	.COEFF_12(fir_coeff12), .COEFF_13(fir_coeff13), .COEFF_14(fir_coeff14), .COEFF_15(fir_coeff15));

fir_16tap fir3(.CLK(ADC_FRAME_CK1), .ENABLE_FIR(enable_fir), .DATA_IN(adc3), .DATA_OUT(adcx3),
	.COEFF_0(fir_coeff0), .COEFF_1(fir_coeff1), .COEFF_2(fir_coeff2), .COEFF_3(fir_coeff3),
	.COEFF_4(fir_coeff4), .COEFF_5(fir_coeff5), .COEFF_6(fir_coeff6), .COEFF_7(fir_coeff7),
	.COEFF_8(fir_coeff8), .COEFF_9(fir_coeff9), .COEFF_10(fir_coeff10), .COEFF_11(fir_coeff11),
	.COEFF_12(fir_coeff12), .COEFF_13(fir_coeff13), .COEFF_14(fir_coeff14), .COEFF_15(fir_coeff15));

fir_16tap fir4(.CLK(ADC_FRAME_CK1), .ENABLE_FIR(enable_fir), .DATA_IN(adc4), .DATA_OUT(adcx4),
	.COEFF_0(fir_coeff0), .COEFF_1(fir_coeff1), .COEFF_2(fir_coeff2), .COEFF_3(fir_coeff3),
	.COEFF_4(fir_coeff4), .COEFF_5(fir_coeff5), .COEFF_6(fir_coeff6), .COEFF_7(fir_coeff7),
	.COEFF_8(fir_coeff8), .COEFF_9(fir_coeff9), .COEFF_10(fir_coeff10), .COEFF_11(fir_coeff11),
	.COEFF_12(fir_coeff12), .COEFF_13(fir_coeff13), .COEFF_14(fir_coeff14), .COEFF_15(fir_coeff15));

fir_16tap fir5(.CLK(ADC_FRAME_CK1), .ENABLE_FIR(enable_fir), .DATA_IN(adc5), .DATA_OUT(adcx5),
	.COEFF_0(fir_coeff0), .COEFF_1(fir_coeff1), .COEFF_2(fir_coeff2), .COEFF_3(fir_coeff3),
	.COEFF_4(fir_coeff4), .COEFF_5(fir_coeff5), .COEFF_6(fir_coeff6), .COEFF_7(fir_coeff7),
	.COEFF_8(fir_coeff8), .COEFF_9(fir_coeff9), .COEFF_10(fir_coeff10), .COEFF_11(fir_coeff11),
	.COEFF_12(fir_coeff12), .COEFF_13(fir_coeff13), .COEFF_14(fir_coeff14), .COEFF_15(fir_coeff15));

fir_16tap fir6(.CLK(ADC_FRAME_CK1), .ENABLE_FIR(enable_fir), .DATA_IN(adc6), .DATA_OUT(adcx6),
	.COEFF_0(fir_coeff0), .COEFF_1(fir_coeff1), .COEFF_2(fir_coeff2), .COEFF_3(fir_coeff3),
	.COEFF_4(fir_coeff4), .COEFF_5(fir_coeff5), .COEFF_6(fir_coeff6), .COEFF_7(fir_coeff7),
	.COEFF_8(fir_coeff8), .COEFF_9(fir_coeff9), .COEFF_10(fir_coeff10), .COEFF_11(fir_coeff11),
	.COEFF_12(fir_coeff12), .COEFF_13(fir_coeff13), .COEFF_14(fir_coeff14), .COEFF_15(fir_coeff15));

fir_16tap fir7(.CLK(ADC_FRAME_CK1), .ENABLE_FIR(enable_fir), .DATA_IN(adc7), .DATA_OUT(adcx7),
	.COEFF_0(fir_coeff0), .COEFF_1(fir_coeff1), .COEFF_2(fir_coeff2), .COEFF_3(fir_coeff3),
	.COEFF_4(fir_coeff4), .COEFF_5(fir_coeff5), .COEFF_6(fir_coeff6), .COEFF_7(fir_coeff7),
	.COEFF_8(fir_coeff8), .COEFF_9(fir_coeff9), .COEFF_10(fir_coeff10), .COEFF_11(fir_coeff11),
	.COEFF_12(fir_coeff12), .COEFF_13(fir_coeff13), .COEFF_14(fir_coeff14), .COEFF_15(fir_coeff15));

fir_16tap fir8(.CLK(ADC_FRAME_CK2), .ENABLE_FIR(enable_fir), .DATA_IN(adc8), .DATA_OUT(adcx8),
	.COEFF_0(fir_coeff0), .COEFF_1(fir_coeff1), .COEFF_2(fir_coeff2), .COEFF_3(fir_coeff3),
	.COEFF_4(fir_coeff4), .COEFF_5(fir_coeff5), .COEFF_6(fir_coeff6), .COEFF_7(fir_coeff7),
	.COEFF_8(fir_coeff8), .COEFF_9(fir_coeff9), .COEFF_10(fir_coeff10), .COEFF_11(fir_coeff11),
	.COEFF_12(fir_coeff12), .COEFF_13(fir_coeff13), .COEFF_14(fir_coeff14), .COEFF_15(fir_coeff15));

fir_16tap fir9(.CLK(ADC_FRAME_CK2), .ENABLE_FIR(enable_fir), .DATA_IN(adc9), .DATA_OUT(adcx9),
	.COEFF_0(fir_coeff0), .COEFF_1(fir_coeff1), .COEFF_2(fir_coeff2), .COEFF_3(fir_coeff3),
	.COEFF_4(fir_coeff4), .COEFF_5(fir_coeff5), .COEFF_6(fir_coeff6), .COEFF_7(fir_coeff7),
	.COEFF_8(fir_coeff8), .COEFF_9(fir_coeff9), .COEFF_10(fir_coeff10), .COEFF_11(fir_coeff11),
	.COEFF_12(fir_coeff12), .COEFF_13(fir_coeff13), .COEFF_14(fir_coeff14), .COEFF_15(fir_coeff15));

fir_16tap fir10(.CLK(ADC_FRAME_CK2), .ENABLE_FIR(enable_fir), .DATA_IN(adc10), .DATA_OUT(adcx10),
	.COEFF_0(fir_coeff0), .COEFF_1(fir_coeff1), .COEFF_2(fir_coeff2), .COEFF_3(fir_coeff3),
	.COEFF_4(fir_coeff4), .COEFF_5(fir_coeff5), .COEFF_6(fir_coeff6), .COEFF_7(fir_coeff7),
	.COEFF_8(fir_coeff8), .COEFF_9(fir_coeff9), .COEFF_10(fir_coeff10), .COEFF_11(fir_coeff11),
	.COEFF_12(fir_coeff12), .COEFF_13(fir_coeff13), .COEFF_14(fir_coeff14), .COEFF_15(fir_coeff15));

fir_16tap fir11(.CLK(ADC_FRAME_CK2), .ENABLE_FIR(enable_fir), .DATA_IN(adc11), .DATA_OUT(adcx11),
	.COEFF_0(fir_coeff0), .COEFF_1(fir_coeff1), .COEFF_2(fir_coeff2), .COEFF_3(fir_coeff3),
	.COEFF_4(fir_coeff4), .COEFF_5(fir_coeff5), .COEFF_6(fir_coeff6), .COEFF_7(fir_coeff7),
	.COEFF_8(fir_coeff8), .COEFF_9(fir_coeff9), .COEFF_10(fir_coeff10), .COEFF_11(fir_coeff11),
	.COEFF_12(fir_coeff12), .COEFF_13(fir_coeff13), .COEFF_14(fir_coeff14), .COEFF_15(fir_coeff15));

fir_16tap fir12(.CLK(ADC_FRAME_CK2), .ENABLE_FIR(enable_fir), .DATA_IN(adc12), .DATA_OUT(adcx12),
	.COEFF_0(fir_coeff0), .COEFF_1(fir_coeff1), .COEFF_2(fir_coeff2), .COEFF_3(fir_coeff3),
	.COEFF_4(fir_coeff4), .COEFF_5(fir_coeff5), .COEFF_6(fir_coeff6), .COEFF_7(fir_coeff7),
	.COEFF_8(fir_coeff8), .COEFF_9(fir_coeff9), .COEFF_10(fir_coeff10), .COEFF_11(fir_coeff11),
	.COEFF_12(fir_coeff12), .COEFF_13(fir_coeff13), .COEFF_14(fir_coeff14), .COEFF_15(fir_coeff15));

fir_16tap fir13(.CLK(ADC_FRAME_CK2), .ENABLE_FIR(enable_fir), .DATA_IN(adc13), .DATA_OUT(adcx13),
	.COEFF_0(fir_coeff0), .COEFF_1(fir_coeff1), .COEFF_2(fir_coeff2), .COEFF_3(fir_coeff3),
	.COEFF_4(fir_coeff4), .COEFF_5(fir_coeff5), .COEFF_6(fir_coeff6), .COEFF_7(fir_coeff7),
	.COEFF_8(fir_coeff8), .COEFF_9(fir_coeff9), .COEFF_10(fir_coeff10), .COEFF_11(fir_coeff11),
	.COEFF_12(fir_coeff12), .COEFF_13(fir_coeff13), .COEFF_14(fir_coeff14), .COEFF_15(fir_coeff15));

fir_16tap fir14(.CLK(ADC_FRAME_CK2), .ENABLE_FIR(enable_fir), .DATA_IN(adc14), .DATA_OUT(adcx14),
	.COEFF_0(fir_coeff0), .COEFF_1(fir_coeff1), .COEFF_2(fir_coeff2), .COEFF_3(fir_coeff3),
	.COEFF_4(fir_coeff4), .COEFF_5(fir_coeff5), .COEFF_6(fir_coeff6), .COEFF_7(fir_coeff7),
	.COEFF_8(fir_coeff8), .COEFF_9(fir_coeff9), .COEFF_10(fir_coeff10), .COEFF_11(fir_coeff11),
	.COEFF_12(fir_coeff12), .COEFF_13(fir_coeff13), .COEFF_14(fir_coeff14), .COEFF_15(fir_coeff15));

fir_16tap fir15(.CLK(ADC_FRAME_CK2), .ENABLE_FIR(enable_fir), .DATA_IN(adc15), .DATA_OUT(adcx15),
	.COEFF_0(fir_coeff0), .COEFF_1(fir_coeff1), .COEFF_2(fir_coeff2), .COEFF_3(fir_coeff3),
	.COEFF_4(fir_coeff4), .COEFF_5(fir_coeff5), .COEFF_6(fir_coeff6), .COEFF_7(fir_coeff7),
	.COEFF_8(fir_coeff8), .COEFF_9(fir_coeff9), .COEFF_10(fir_coeff10), .COEFF_11(fir_coeff11),
	.COEFF_12(fir_coeff12), .COEFF_13(fir_coeff13), .COEFF_14(fir_coeff14), .COEFF_15(fir_coeff15));
*/
assign adcx0 = adc0;
assign adcx1 = adc1;
assign adcx2 = adc2;
assign adcx3 = adc3;
assign adcx4 = adc4;
assign adcx5 = adc5;
assign adcx6 = adc6;
assign adcx7 = adc7;
assign adcx8 = adc8;
assign adcx9 = adc9;
assign adcx10 = adc10;
assign adcx11 = adc11;
assign adcx12 = adc12;
assign adcx13 = adc13;
assign adcx14 = adc14;
assign adcx15 = adc15;

Histogrammer AdcHisto0(.LCLK(ADC_LCLK1), .ADCLK(ADC_FRAME_CK1),
	.ADC_PDATA0(adcx0), .ADC_PDATA1(adcx1), .ADC_PDATA2(adcx2), .ADC_PDATA3(adcx3),
	.ADC_PDATA4(adcx4), .ADC_PDATA5(adcx5), .ADC_PDATA6(adcx6), .ADC_PDATA7(adcx7),
	.RSTb(RSTb_sync), .CLK(Vme_clock),
	.WEb(user_weB), .REb(user_reB), .OEb(user_oeB), .CEb(Histogrammer0_ceB),
	.USER_ADDR(user_addr[12:0]), .USER_DATA(user_d));

Histogrammer AdcHisto1(.LCLK(ADC_LCLK2), .ADCLK(ADC_FRAME_CK2),
	.ADC_PDATA0(adcx8), .ADC_PDATA1(adcx9), .ADC_PDATA2(adcx10), .ADC_PDATA3(adcx11),
	.ADC_PDATA4(adcx12), .ADC_PDATA5(adcx13), .ADC_PDATA6(adcx14), .ADC_PDATA7(adcx15),
	.RSTb(RSTb_sync), .CLK(Vme_clock),
	.WEb(user_weB), .REb(user_reB), .OEb(user_oeB), .CEb(Histogrammer1_ceB),
	.USER_ADDR(user_addr[12:0]), .USER_DATA(user_d));


TrigGen ApvTriggerHandler(.APV_TRG(APV_TRIGGER), .RESET101(apv_reset101), .RSTb(RSTb_sync),
	.CLK(APV_CLOCK), .MAX_TRIG_OUT(MaxTrigOut), .TRIG_PULSE(trigger_pulse),
	.TRIG_MODE(TrigMode),
	.TRIG_CMD(trigger), .RESET_CMD(sync),
	.MISSING_TRIGGER_CNT(missing_trigger_count), .MAX_RESET_LATENCY(ResetLatency),
	.CALIB_LATENCY(CalibLatency),
	.NO_MORE_SPACE(no_more_space07 | no_more_space815),
//	.SPACE_AVAILABLE(space_available07 & space_available815),
	.SPACE_AVAILABLE( &ApvFifoEmpty ),
	.TRIGGER_DISABLED(internal_trigger_disabled));	// BUSY signal



EightChannels ApvProcessor_0_7(.RSTb(RSTb_sync), .APV_CLK(ADC_FRAME_CK1), .PROCESS_CLK(Vme_clock),
	.ENABLE(ApvEnable[7:0]),
	.EN_BASELINE_SUBTRACTION(en_baseline_subtraction),
	.ADC_PDATA0(adcx0), .ADC_PDATA1(adcx1), .ADC_PDATA2(adcx2), .ADC_PDATA3(adcx3),
	.ADC_PDATA4(adcx4), .ADC_PDATA5(adcx5), .ADC_PDATA6(adcx6), .ADC_PDATA7(adcx7),
	.SYNC_PERIOD(ApvSyncPeriod), .SYNCED(ApvSynced[7:0]),
	.COMMON_OFFSET(common_offset), .BANK_ID(1'b0),
	.FIFO_DATA_OUT0(ApvFifoData0), .FIFO_DATA_OUT1(ApvFifoData1),
	.FIFO_DATA_OUT2(ApvFifoData2), .FIFO_DATA_OUT3(ApvFifoData3),
	.FIFO_DATA_OUT4(ApvFifoData4), .FIFO_DATA_OUT5(ApvFifoData5),
	.FIFO_DATA_OUT6(ApvFifoData6), .FIFO_DATA_OUT7(ApvFifoData7),
	.FIFO_EMPTY(ApvFifoEmpty[7:0]), .FIFO_FULL(ApvFifoFull[7:0]),
	.FIFO_RD(Enable_EventBuilder ? ApvFifoRd_EVB[7:0] : ApvFifo_read[7:0]),
	.HIGH_ONE(one_threshold), .LOW_ZERO(zero_threshold),
	.ALL_CLEAR(AllFifoClear|apv_reset101), .DAQ_MODE(ReadoutMode),
	.USED_FIFO_WORDS0(used_fifo_words0), .USED_FIFO_WORDS1(used_fifo_words1),
	.USED_FIFO_WORDS2(used_fifo_words2), .USED_FIFO_WORDS3(used_fifo_words3),
	.USED_FIFO_WORDS4(used_fifo_words4), .USED_FIFO_WORDS5(used_fifo_words5),
	.USED_FIFO_WORDS6(used_fifo_words6), .USED_FIFO_WORDS7(used_fifo_words7),
	.ONE_MORE_EVENT(OneMoreEvent[7:0]), .DECR_EVENT_COUNTER(DecrEventCounter),
	.NO_MORE_SPACE(no_more_space07), .SPACE_AVAILABLE(space_available07),
	.RAM_ADDR(user_addr[6:0]), .RAM_DIN(user_d[31:0]),
	.WE_PED_RAM(we_ped_ram[3:0]), .RE_PED_RAM(re_ped_ram[3:0]),
	.WE_THR_RAM(we_thr_ram[3:0]), .RE_THR_RAM(re_thr_ram[3:0]), .MODULE_ID(~VME_GA[4:0]),
	.MARKER_CH(MarkerCh)
	);

EightChannels ApvProcessor_8_15(.RSTb(RSTb_sync), .APV_CLK(ADC_FRAME_CK2), .PROCESS_CLK(Vme_clock),
	.ENABLE(ApvEnable[15:8]),
	.EN_BASELINE_SUBTRACTION(en_baseline_subtraction),
	.ADC_PDATA0(adcx8), .ADC_PDATA1(adcx9), .ADC_PDATA2(adcx10), .ADC_PDATA3(adcx11),
	.ADC_PDATA4(adcx12), .ADC_PDATA5(adcx13), .ADC_PDATA6(adcx14), .ADC_PDATA7(adcx15),
	.SYNC_PERIOD(ApvSyncPeriod), .SYNCED(ApvSynced[15:8]),
	.COMMON_OFFSET(common_offset), .BANK_ID(1'b1),
	.FIFO_DATA_OUT0(ApvFifoData8), .FIFO_DATA_OUT1(ApvFifoData9),
	.FIFO_DATA_OUT2(ApvFifoData10), .FIFO_DATA_OUT3(ApvFifoData11),
	.FIFO_DATA_OUT4(ApvFifoData12), .FIFO_DATA_OUT5(ApvFifoData13),
	.FIFO_DATA_OUT6(ApvFifoData14), .FIFO_DATA_OUT7(ApvFifoData15),
	.FIFO_EMPTY(ApvFifoEmpty[15:8]), .FIFO_FULL(ApvFifoFull[15:8]),
	.FIFO_RD(Enable_EventBuilder ? ApvFifoRd_EVB[15:8] : ApvFifo_read[15:8]),
	.HIGH_ONE(one_threshold), .LOW_ZERO(zero_threshold),
	.ALL_CLEAR(AllFifoClear|apv_reset101), .DAQ_MODE(ReadoutMode),
	.USED_FIFO_WORDS0(used_fifo_words8), .USED_FIFO_WORDS1(used_fifo_words9),
	.USED_FIFO_WORDS2(used_fifo_words10), .USED_FIFO_WORDS3(used_fifo_words11),
	.USED_FIFO_WORDS4(used_fifo_words12), .USED_FIFO_WORDS5(used_fifo_words13),
	.USED_FIFO_WORDS6(used_fifo_words14), .USED_FIFO_WORDS7(used_fifo_words15),
	.ONE_MORE_EVENT(OneMoreEvent[15:8]), .DECR_EVENT_COUNTER(DecrEventCounter),
	.NO_MORE_SPACE(no_more_space815), .SPACE_AVAILABLE(space_available815),
	.RAM_ADDR(user_addr[6:0]), .RAM_DIN(user_d[31:0]),
	.WE_PED_RAM(we_ped_ram[7:4]), .RE_PED_RAM(re_ped_ram[7:4]),
	.WE_THR_RAM(we_thr_ram[7:4]), .RE_THR_RAM(re_thr_ram[7:4]), .MODULE_ID(~VME_GA[4:0]),
	.MARKER_CH(MarkerCh)
	);

FifoVmeIf ApvVmeIf(.FIFO_RD(ApvFifo_read),
	.FIFO_DATA_OUT0(ApvFifoData0), .FIFO_DATA_OUT1(ApvFifoData1),
	.FIFO_DATA_OUT2(ApvFifoData2), .FIFO_DATA_OUT3(ApvFifoData3),
	.FIFO_DATA_OUT4(ApvFifoData4), .FIFO_DATA_OUT5(ApvFifoData5),
	.FIFO_DATA_OUT6(ApvFifoData6), .FIFO_DATA_OUT7(ApvFifoData7),
	.FIFO_DATA_OUT8(ApvFifoData8), .FIFO_DATA_OUT9(ApvFifoData9),
	.FIFO_DATA_OUT10(ApvFifoData10), .FIFO_DATA_OUT11(ApvFifoData11),
	.FIFO_DATA_OUT12(ApvFifoData12), .FIFO_DATA_OUT13(ApvFifoData13),
	.FIFO_DATA_OUT14(ApvFifoData14), .FIFO_DATA_OUT15(ApvFifoData15),
	.USED_FIFO_WORDS0(used_fifo_words0), .USED_FIFO_WORDS1(used_fifo_words1),
	.USED_FIFO_WORDS2(used_fifo_words2), .USED_FIFO_WORDS3(used_fifo_words3),
	.USED_FIFO_WORDS4(used_fifo_words4), .USED_FIFO_WORDS5(used_fifo_words5),
	.USED_FIFO_WORDS6(used_fifo_words6), .USED_FIFO_WORDS7(used_fifo_words7),
	.USED_FIFO_WORDS8(used_fifo_words8), .USED_FIFO_WORDS9(used_fifo_words9),
	.USED_FIFO_WORDS10(used_fifo_words10), .USED_FIFO_WORDS11(used_fifo_words11),
	.USED_FIFO_WORDS12(used_fifo_words12), .USED_FIFO_WORDS13(used_fifo_words13),
	.USED_FIFO_WORDS14(used_fifo_words14), .USED_FIFO_WORDS15(used_fifo_words15),
	.FIFO_EMPTY(ApvFifoEmpty), .FIFO_FULL(ApvFifoFull),
	.SYNCED(ApvSynced), .ERROR(ApvError),
	.ENABLE(ApvEnable), .SYNC_PERIOD(ApvSyncPeriod),
	.RSTb(RSTb_sync), .CLK(Vme_clock),
	.WEb(user_weB), .REb(user_reB), .OEb(user_oeB), .CEb(ApvFifo_ceB),
	.USER_ADDR(user_addr[21:0]), .USER_DATA(user_d),
	.TRIG_GEN_CONFIG(TrigGenConfig), .READOUT_CONFIG(ReadoutConfig),
	.MISSED_TRIGGER(missing_trigger_count),
	.ONE_THR(one_threshold), .ZERO_THR(zero_threshold),
	.WE_PED_RAM(we_ped_ram), .RE_PED_RAM(re_ped_ram),
	.WE_THR_RAM(we_thr_ram), .RE_THR_RAM(re_thr_ram),
	.EV_BUILDER_DATA_OUT(24'b0), .EV_BUILDER_ENABLE(1'b0),
	.EV_BUILDER_FIFO_EMPTY(1'b1), .EV_BUILDER_FIFO_FULL(1'b0),
	.EV_BUILDER_FIFO_WC(12'b0),
	.EV_BUILDER_EV_CNT(24'b0),
	.MARKER_CH(MarkerCh)
	);
	/*
EventBuilder TheBuilder(.RSTb(RSTb_sync), .TIME_CLK(time_clock), .CLK(Vme_clock),
	.TRIGGER(trigger_pulse), .ALL_CLEAR(AllFifoClear|apv_reset101),
	.ENABLE_MASK(ApvEnable), .ENABLE_EVBUILD(Enable_EventBuilder),
	.CH_DATA0(ApvFifoData0), .CH_DATA1(ApvFifoData1),
	.CH_DATA2(ApvFifoData2), .CH_DATA3(ApvFifoData3),
	.CH_DATA4(ApvFifoData4), .CH_DATA5(ApvFifoData5),
	.CH_DATA6(ApvFifoData6), .CH_DATA7(ApvFifoData7),
	.CH_DATA8(ApvFifoData8), .CH_DATA9(ApvFifoData9),
	.CH_DATA10(ApvFifoData10), .CH_DATA11(ApvFifoData11),
	.CH_DATA12(ApvFifoData12), .CH_DATA13(ApvFifoData13),
	.CH_DATA14(ApvFifoData14), .CH_DATA15(ApvFifoData15),
	.DATA_RD(ApvFifoRd_EVB), .EVENT_PRESENT(OneMoreEvent),
	.DECREMENT_EVENT_COUNT(DecrEventCounter), .MODULE_ID({7'b0, ~VME_GA[4:0]}),
	.DATA_OUT(EvBuilderDataOut), .EMPTY(EventBuilder_Empty), .FULL(EventBuilder_Full),
	.DATA_OUT_CNT(EventBuilder_Wc), .DATA_OUT_RD(Enable_EventBuilder&ApvFifo_read[0]),
	.EV_CNT(EventBuilder_EvCnt));
*/
endmodule

