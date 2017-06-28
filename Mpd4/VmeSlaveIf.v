/* VmeSlaveIf.v - VME64x Slave Interface
 *
 * Author: Paolo Musico
 * Date:   1 December 2005
 * Rev:    1.0
 *
 * This is a slave VME64x interface Verilog synthetizable model with the following capabilities:
 * - A24-D32 for accessing CR/CSR space
 * - A32-D32 for standard accesses
 * - A32-D32 Block Transfers (BLT)
 * - A32-D32 2eVME (master terminated only)
 * - A32-D64 2eVME (master terminated only)
 * - A32-D32 2eSST (master terminated only)
 * - A32-D64 2eSST (master terminated only)
 *
 * The device is also an interrupter ROAK with D08(O) Status ID.
 * Unaligned data transfers are not permitted.
 *
 * On the user side the interface will provide a standard non muxed bus as following:
 *           _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _
 * CLK     _| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_
 *          ____ _______ _______ _______ _______ _______ _______ _______ _______ _______ ___
 * A[31:0]  ____X_______X_______X_______X_______X_______X_______X_______X_______X_______X___
 *               _______ _______            _____           ______ ______
 * D[63:0] -----X_______X_______X----------X_____X---------X______X______X------------------
 *          ____ _______ _______ _______ _______ _______ _______ _______ ___________________
 * CEb[7:0]     X_______X_______X       X_______X       X_______X_______X
 *         _________     ___     ___________________________________________________________
 * WEb              |___|   |___|
 *         _____________________________     ___________     ___     _______________________
 * REb                                  |___|           |___|   |___|    
 *         _____________________________         _______                 ___________________
 * OEb                                  |_______|       |_______________|
 *
 * The above diagram show that WEb and REb pulse are always 1 CLK cycle wide.
 * Async device can write with the rising edge of WEb, sync device can use
 * the rising edge of CLK at the end of WEb.
 * REb pulses can be used to extract data from sync (with CLK) or async devices.
 * The CEb[] are generated comparing the 8 MSB of the 32 bit address with
 * a constant, thus giving 8 MBytes each.
 *
 * Only 32 and 64 bit aligned data transfers are allowed.
 * The user data bus width can be limited to 32 bit.
 *
 *
 *
 */

`include "CompileTime.v"

`define MANUFACTURER_ID	24'h08_00_30	// CERN Manufacturer ID
`define BOARD_ID	32'h00_03_09_04	// Board ID - 394
`define REVISION_ID	32'h04_00_00_03	// Revision ID - MPD = 4, Fpga = 3


module VmeSlaveIf(
	VME_A, VME_AM, VME_D, VME_ASb, VME_DS1b, VME_DS0b, VME_WRITEb, VME_LWORDb, VME_IACKb,
	VME_IackInb, VME_IackOutb, VME_IRQ, VME_DTACK, VME_BERR, VME_GAb, VME_GAPb,
	VME_DATA_DIR, VME_DBUF_OEb, VME_ADDR_DIR, VME_ABUF_OEb,
	VME_DTACK_EN, VME_BERR_EN,
	VME_RETRY, VME_RETRY_EN,
	USER_D64,
	USER_VME64BIT,
	USER_ADDR, USER_DATA, USER_WEb, USER_REb, USER_OEb, USER_CEb, USER_IRQb, USER_WAITb,
	USER_STATUS, USER_CTRL, VME_CYCLE_IN_PROGRESS, RESETb, CLK, DEBUG
);
	inout [31:1] VME_A;	// VME address lines
	input [5:0] VME_AM;	// VME address modifier lines
	inout [31:0] VME_D;	// VME data lines
	input VME_ASb;		// VME address strobe (active low)
	input VME_DS1b;		// VME data strobe 1 (active low)
	input VME_DS0b;		// VME data strobe 0 (active low)
	input VME_WRITEb;	// VME write line (active low)
	inout VME_LWORDb;	// VME longword line (active low), also A[0] in A64-D64 cycles
	input VME_IACKb;	// VME interrupt acknowledge line (active low)
	input VME_IackInb;	// VME interrupt acknowledge line in (active low)
	output VME_IackOutb;	// VME interrupt acknowledge line out (active low)
	output [7:1] VME_IRQ;	// VME interrupt request (acive high): MUST DRIVE AN OPEN DRAIN BUFFER
	output VME_DTACK;	// VME data acknowledge line (acive low): MUST DRIVE A TRISTATE BUFFER
	output VME_BERR;	// VME bus error line (acive low): MUST DRIVE A TRISTATE BUFFER
	input [4:0] VME_GAb;	// Slot ID for geographical addressing (active low) (pullup-ed)
	input VME_GAPb;		// Slot ID parity for geographical addressing (active low) (pullup-ed)

	output VME_DATA_DIR;	// Direction signal for VME data buffers D[31:0]
	output VME_DBUF_OEb;	// Enable signal for VME data buffers D[31:0] (active low)
	output VME_ADDR_DIR;	// Direction signal for VME data buffers A[31:1] and LWORD
	output VME_ABUF_OEb;	// Enable signal for VME data buffers A[31:1] and LWORD (active low)
	output VME_DTACK_EN;	// Enable signal for DTACK buffer (active high)
       	output VME_BERR_EN;	// Enable signal for BERR buffer (active high)
	output VME_RETRY;	// VME RETRY signal (active low): MUST DRIVE A TRISTATE BUFFER
	output VME_RETRY_EN;	// Enable signal for RETRY buffer (active high)

	input USER_D64;		// Indicate the use of 64 bit bus on user side: STATIC SIGNAL (pullup-ed)
	output USER_VME64BIT;	// 64 bit VME data transaction: USER_ADDR[0] is meaningless
	output [21:0] USER_ADDR;// User side address lines
	inout [63:0] USER_DATA;	// User side data lines (pullup-ed)
	output USER_WEb;	// User side write pulse (active low)
	output USER_REb;	// User side read pulse (active low)
	output USER_OEb;	// User side output enable line (active low)
	output [7:0] USER_CEb;	// User side chip enable line (active low)
	input [7:1] USER_IRQb;	// User side interrupt request line (active low) (pullup-ed)
	input USER_WAITb;	// User side wait line (active low) (pullup-ed)
	input [7:0] USER_STATUS;// User status lines
	output [7:0] USER_CTRL;	// User control lines
	output VME_CYCLE_IN_PROGRESS;

	input RESETb;		// System reset (active low)
	input CLK;		// System free running 40 MHz clock

	output [7:0] DEBUG;

	parameter	A24_CRCSR = 6'h2F,
			A24_SINGLE1 = 6'h39,
			A24_SINGLE2 = 6'h3A,
			A24_SINGLE3 = 6'h3D,
			A24_SINGLE4 = 6'h3E,
			A32_SINGLE1 = 6'h09,	// Non privileged data space
			A32_SINGLE2 = 6'h0D,	// Supervisory data space
			A32_SINGLE3 = 6'h0A,	// Non privileged program space
			A32_SINGLE4 = 6'h0E,	// Supervisory program space
			A32_BLT1 = 6'h0B,	// Non privileged block transfer
			A32_BLT2 = 6'h0F,	// Supervisory block transfer
			A32_MBLT1 = 6'h08,	// Non privileged muxed block transfer
			A32_MBLT2 = 6'h0C,	// Supervisory muxed block transfer
			A32_2eVME1 = 6'h21,	// 3U 2e
			A32_2eVME2 = 6'h20;	// 6U 2e
	parameter	A32_2eSST = 8'h11,	// 3U A32D32_2eSST or 6U A32_D64_2eSST
			A32_D32_2eVME = 8'h01,	// 3U D32 2eVME
			//A32_A64_2eSST = 8'h12,// 3U A40D32_2eSST or 6U A64_D64_2eSST
			A32_D64_2eVME = 8'h01;	// 6U D64 2eVME
	parameter	SST_80 = 4'h0,		// 3U D32 SST with 50 ns strobe width: 80 MB/sec
			SST_160 = 4'h0;		// 6U D64 SST with 50 ns strobe width: 160 MB/sec


	reg LOCAL_DTACK;
	wire LOCAL_BERR;
	reg asB, ds0B, ds1B, writeB, lwordB, a1, iackB, iackInB;
	reg [5:0] am;
	reg old_asB, old_ds1B, ld_addr_counter;
	reg [7:0] xam, beats, IrqVector;
//	reg [29:0] addr_counter;
	wire [29:0] addr_counter;
	reg [3:0] transfer_rate;
	reg [3:1] irq_ack_level;
	reg cr_csr_cycle, single_cycle, blt_cycle, mblt_cycle, bad_cycle;
	reg a32d32_2evme_cycle, a32d64_2evme_cycle, a32d32_2esst_cycle, a32d64_2esst_cycle;
	reg d32_2e_cycle, d64_2e_cycle;
	reg [63:0] sst_wr_data;
	wire [4:0] ga;
	wire [7:0] ader0, ader1, ader2, ader3, ader4, ader5, ader6, ader7, bar;
	wire [31:0] cr_dataout, csr_dataout, cr_csr_data, local_data;
	wire [63:0] internal_data;
	wire [7:0] irq_id1, irq_id2, irq_id3, irq_id4, irq_id5, irq_id6, irq_id7, irq_enable;
	wire [7:1] set_irq_ident;
	wire [2:0] irq_id_sel;
	wire cr_csr_select, module_selected, user_selected, incr_addr_counter;
	wire ld_a7_0, two_edge_cycle, data_2e_cycle, data_enable, addr_enable;
	wire sst_cycle, cycle_in_progress, iack_cycle, DataDtack, IrqDtack;
	wire any_bad, two_edge_start;	// DEBUG

	reg USER_VME64BIT;


	assign VME_DTACK = ~LOCAL_DTACK;
	assign VME_BERR = ~LOCAL_BERR;
	assign VME_DTACK_EN = LOCAL_DTACK;
	assign VME_BERR_EN = LOCAL_BERR;
	assign VME_RETRY = 1'b1;
	assign VME_RETRY_EN = 1'b0;

	assign module_selected = (~(&USER_CEb) | cr_csr_select | iack_cycle ) & ~VME_ASb;
	assign user_selected = ~(&USER_CEb) & ~VME_ASb;

	assign VME_DATA_DIR = VME_WRITEb;	// Or the inverted one...
	assign VME_ADDR_DIR = addr_enable;	// Or the inverted one...
	assign VME_DBUF_OEb = ~module_selected;
	assign VME_ABUF_OEb = 0;		// Address lines always enabled

	assign USER_ADDR = addr_counter[21:0];
//	assign USER_DATA = (~VME_WRITEb & user_selected) ? {VME_A, VME_LWORDb, VME_D} : 64'bz;
	assign USER_DATA = (~VME_WRITEb & cycle_in_progress) ? ( sst_cycle ? sst_wr_data : {VME_A, VME_LWORDb, VME_D}) : 64'bz;
//	assign USER_DATA = (~VME_WRITEb & user_selected) ? ( sst_cycle ? sst_wr_data : {VME_A, VME_LWORDb, VME_D}) : 64'bz;

	assign data_enable = VME_WRITEb & module_selected;
	assign addr_enable = data_enable & data_2e_cycle & two_edge_cycle;

	assign VME_D = data_enable ? internal_data[31:0] : 32'bz;
	assign internal_data = ( cr_csr_cycle | iack_cycle ) ? {32'b0, local_data} : USER_DATA;
	assign local_data = ( cr_csr_cycle ) ? cr_csr_data : {24'b0, IrqVector};
	assign cr_csr_data = (addr_counter[18:0] < 19'h01000) ? cr_dataout : csr_dataout;

	assign VME_LWORDb = addr_enable ?  (d32_2e_cycle ? internal_data[16] : internal_data[32]) : 32'bz;
	assign VME_A[7:1] = addr_enable ?
		(d32_2e_cycle ? internal_data[23:17] : internal_data[39:33]) : 32'bz;
	assign VME_A[15:8] = addr_enable ?
		(d32_2e_cycle ? internal_data[31:24] : internal_data[47:40]) : 32'bz;
	assign VME_A[23:16] = addr_enable ? (d32_2e_cycle ? 8'b0 : internal_data[55:48]) : 32'bz;
	assign VME_A[31:24] = addr_enable ? (d32_2e_cycle ? 8'h0 : internal_data[63:56]) : 32'bz;

	assign two_edge_cycle = d32_2e_cycle | d64_2e_cycle;
	assign sst_cycle = a32d32_2esst_cycle | a32d64_2esst_cycle;
	assign ga = ~VME_GAb;
	assign VME_CYCLE_IN_PROGRESS = cycle_in_progress;

//	assign USER_VME64BIT = mblt_cycle | a32d64_2evme_cycle | a32d64_2esst_cycle;

	assign DEBUG = {user_selected, bad_cycle, two_edge_cycle, xam[1:0],
			any_bad, two_edge_start, cycle_in_progress};


// Sample VME data lines every transition of DS1b
	always @(posedge CLK or negedge RESETb)
	begin
		if( RESETb == 0 )
		begin
			sst_wr_data <= 0;
		end
		else
		begin
			if( ds1B != old_ds1B )
				sst_wr_data <= {VME_A, VME_LWORDb, VME_D};
		end
	end

// Sychronize all inputs
	always @(posedge CLK or negedge RESETb)
	begin
		if( RESETb == 0 )
		begin
			asB <= 0; ds0B <= 0; ds1B <= 0; writeB <= 0; lwordB <= 0;
			iackB <= 0; iackInB <= 0; am <= 0; xam <= 0; beats <= 0;
			old_asB <= 0; old_ds1B <= 0; transfer_rate <= 0;

			USER_VME64BIT <= 0;
		end
		else
		begin
			asB <= VME_ASb;
			ds0B <= VME_DS0b;
			ds1B <= VME_DS1b;
			writeB <= VME_WRITEb;
			lwordB <= VME_LWORDb;
			iackB <= VME_IACKb;
			iackInB <= VME_IackInb;
			am <= VME_AM;
			xam <= {VME_A[7:1], VME_LWORDb};
			beats <= VME_A[15:8];
			transfer_rate <= VME_D[3:0];

			old_asB <= asB;
			old_ds1B <= ds1B;

			USER_VME64BIT <= mblt_cycle | a32d64_2evme_cycle | a32d64_2esst_cycle;
		end
	end

// Load the address counter on falling edge of AS and decode the cycle
	always @(posedge CLK or negedge RESETb)
	begin
		if( RESETb == 0 )
		begin
			ld_addr_counter <= 0;
			cr_csr_cycle <= 0; single_cycle <= 0; blt_cycle <= 0; mblt_cycle <= 0;
			a32d32_2evme_cycle <= 0; a32d64_2evme_cycle <= 0;
			a32d32_2esst_cycle <= 0; a32d64_2esst_cycle <= 0;
			d32_2e_cycle <= 0; d64_2e_cycle <= 0;
			bad_cycle <= 0;
			a1 <= 0;
			irq_ack_level <= 0;
		end
		else
		begin
			if( old_asB == 0 && asB == 1 )	// rising edge of ASb
			begin
				cr_csr_cycle <= 0;
				single_cycle <= 0;
				blt_cycle <= 0;
				mblt_cycle <= 0;
				a32d32_2evme_cycle <= 0;
				a32d64_2evme_cycle <= 0;
				a32d32_2esst_cycle <= 0;
				a32d64_2esst_cycle <= 0;
				d32_2e_cycle <= 0;
				d64_2e_cycle <= 0;
				bad_cycle <= 0;
			end

			if( asB == 0 && old_asB == 1 )	// falling edge of ASb
			begin
				ld_addr_counter <= 1;
				a1 <= VME_A[1];
				irq_ack_level <= VME_A[3:1];
				if( iackB == 1 )
				case( am )
					A24_CRCSR,
					A24_SINGLE1,
					A24_SINGLE2,
					A24_SINGLE3,
					A24_SINGLE4:
						begin
							cr_csr_cycle <= 1;
							single_cycle <= 0;
							blt_cycle <= 0;
							mblt_cycle <= 0;
							a32d32_2evme_cycle <= 0;
							a32d64_2evme_cycle <= 0;
							a32d32_2esst_cycle <= 0;
							a32d64_2esst_cycle <= 0;
							d32_2e_cycle <= 0;
							d64_2e_cycle <= 0;
							bad_cycle <= 0;
						end
					A32_SINGLE1,
					A32_SINGLE2,
					A32_SINGLE3,
					A32_SINGLE4:
						begin
							cr_csr_cycle <= 0;
							single_cycle <= 1;
							blt_cycle <= 0;
							mblt_cycle <= 0;
							a32d32_2evme_cycle <= 0;
							a32d64_2evme_cycle <= 0;
							a32d32_2esst_cycle <= 0;
							a32d64_2esst_cycle <= 0;
							d32_2e_cycle <= 0;
							d64_2e_cycle <= 0;
							bad_cycle <= 0;
						end

					A32_BLT1,
					A32_BLT2:
						begin
							cr_csr_cycle <= 0;
							single_cycle <= 0;
							blt_cycle <= 1;
							mblt_cycle <= 0;
							a32d32_2evme_cycle <= 0;
							a32d64_2evme_cycle <= 0;
							a32d32_2esst_cycle <= 0;
							a32d64_2esst_cycle <= 0;
							d32_2e_cycle <= 0;
							d64_2e_cycle <= 0;
							bad_cycle <= 0;
						end

					A32_MBLT1,
					A32_MBLT2:
						begin
							cr_csr_cycle <= 0;
							single_cycle <= 0;
							blt_cycle <= 0;
							mblt_cycle <= USER_D64;
							a32d32_2evme_cycle <= 0;
							a32d64_2evme_cycle <= 0;
							a32d32_2esst_cycle <= 0;
							a32d64_2esst_cycle <= 0;
							d32_2e_cycle <= 0;
							d64_2e_cycle <= 0;
							bad_cycle <= ~USER_D64;
						end

					A32_2eVME1:
						case( xam )
							A32_2eSST:
								begin
									cr_csr_cycle <= 0;
									single_cycle <= 0;
									blt_cycle <= 0;
									mblt_cycle <= 0;
									a32d32_2evme_cycle <= 0;
									a32d64_2evme_cycle <= 0;
									a32d32_2esst_cycle <= 1;
									a32d64_2esst_cycle <= 0;
									d32_2e_cycle <= 1;
									d64_2e_cycle <= 0;
									bad_cycle <= 0;
								end
							A32_D32_2eVME:
								begin
									cr_csr_cycle <= 0;
									single_cycle <= 0;
									blt_cycle <= 0;
									mblt_cycle <= 0;
									a32d32_2evme_cycle <= 1;
									a32d64_2evme_cycle <= 0;
									a32d32_2esst_cycle <= 0;
									a32d64_2esst_cycle <= 0;
									d32_2e_cycle <= 1;
									d64_2e_cycle <= 0;
									bad_cycle <= 0;
								end
							default:
								begin
									cr_csr_cycle <= 0;
									single_cycle <= 0;
									blt_cycle <= 0;
									mblt_cycle <= 0;
									a32d32_2evme_cycle <= 0;
									a32d64_2evme_cycle <= 0;
									a32d32_2esst_cycle <= 0;
									a32d64_2esst_cycle <= 0;
									d32_2e_cycle <= 0;
									d64_2e_cycle <= 0;
									bad_cycle <= 1;
								end
						endcase

					A32_2eVME2:
						case( xam )
							A32_2eSST:
								begin
									cr_csr_cycle <= 0;
									single_cycle <= 0;
									blt_cycle <= 0;
									mblt_cycle <= 0;
									a32d32_2evme_cycle <= 0;
									a32d64_2evme_cycle <= 0;
									a32d32_2esst_cycle <= 0;
									a32d64_2esst_cycle <= USER_D64;
									d32_2e_cycle <= 0;
									d64_2e_cycle <= USER_D64;
									bad_cycle <= ~USER_D64;
								end
							A32_D64_2eVME:
								begin
									cr_csr_cycle <= 0;
									single_cycle <= 0;
									blt_cycle <= 0;
									mblt_cycle <= 0;
									a32d32_2evme_cycle <= 0;
									a32d64_2evme_cycle <= USER_D64;
									a32d32_2esst_cycle <= 0;
									a32d64_2esst_cycle <= 0;
									d32_2e_cycle <= 0;
									d64_2e_cycle <= USER_D64;
									bad_cycle <= ~USER_D64;
								end
							default:
								begin
									cr_csr_cycle <= 0;
									single_cycle <= 0;
									blt_cycle <= 0;
									mblt_cycle <= 0;
									a32d32_2evme_cycle <= 0;
									a32d64_2evme_cycle <= 0;
									a32d32_2esst_cycle <= 0;
									a32d64_2esst_cycle <= 0;
									d32_2e_cycle <= 0;
									d64_2e_cycle <= 0;
									bad_cycle <= 1;
								end
						endcase

					default:
						begin
							cr_csr_cycle <= 0;
							single_cycle <= 0;
							blt_cycle <= 0;
							mblt_cycle <= 0;
							a32d32_2evme_cycle <= 0;
							a32d64_2evme_cycle <= 0;
							a32d32_2esst_cycle <= 0;
							a32d64_2esst_cycle <= 0;
							d32_2e_cycle <= 0;
							d64_2e_cycle <= 0;
							bad_cycle <= 1;
						end
				endcase
			end
			else
				ld_addr_counter <= 0;
		end
	end

// DTACK generator: puts together DataDtack and IrqDtack
	always @(posedge CLK or negedge RESETb)
	begin
		if( RESETb == 0 )
			LOCAL_DTACK <= 0;
		else
			LOCAL_DTACK <= DataDtack | IrqDtack;
	end

// Interrupt vector selector
	always @(*)
	begin
		case( irq_id_sel )
			3'h0: IrqVector <= 0;
			3'h1: IrqVector <= irq_id1;
			3'h2: IrqVector <= irq_id2;
			3'h3: IrqVector <= irq_id3;
			3'h4: IrqVector <= irq_id4;
			3'h5: IrqVector <= irq_id5;
			3'h6: IrqVector <= irq_id6;
			3'h7: IrqVector <= irq_id7;
		endcase
	end


	AdCnt AddressCounter(.CLK(CLK), .RESETb(RESETb), .U_ADDR(addr_counter), .VME_ADDR(VME_A),
		.CR_CSR(cr_csr_cycle), .TWO_EDGE(two_edge_cycle), .LD(ld_addr_counter), .LD_A7_0(ld_a7_0),
		.INCR(incr_addr_counter));

	Decoder AddressDecoder(.ADDR(addr_counter), .BAR(bar), .CR_CSR_CYC(cr_csr_cycle),
		.CR_CSR_SEL(cr_csr_select), .USER_CEb(USER_CEb),
		.ADER0(ader0), .ADER1(ader1), .ADER2(ader2), .ADER3(ader3),
		.ADER4(ader4), .ADER5(ader5), .ADER6(ader6), .ADER7(ader7),
		.CLK(CLK), .RESETb(RESETb));

	ConfigRom CR(.ADDR(addr_counter[18:0]), .DATAOUT(cr_dataout));

	ControlStatusRegisters CSR(.DATAIN(VME_D[7:0]), .DATAOUT(csr_dataout), .ADDR(addr_counter[18:0]),
		.CLK(CLK), .WEb(USER_WEb), .RESETb(RESETb), .CSR_EN(cr_csr_cycle), .GA(ga),
		.ADER0(ader0), .ADER1(ader1), .ADER2(ader2), .ADER3(ader3),
		.ADER4(ader4), .ADER5(ader5), .ADER6(ader6), .ADER7(ader7),
		.BAR(bar),
		.BSET(), .BCLR(), /*.USER_BSET(),*/ .USER_BCLR(),	// Implemented But Still Not Used
		.USER_STATUS(USER_STATUS), .USER_CTRL(USER_CTRL),
		.IRQ_ID1(irq_id1), .IRQ_ID2(irq_id2), .IRQ_ID3(irq_id3),
		.IRQ_ID4(irq_id4), .IRQ_ID5(irq_id5), .IRQ_ID6(irq_id6), .IRQ_ID7(irq_id7),
		.IRQ_ENABLE(irq_enable), .SET_IRQ_IDENT(set_irq_ident));

	CtrlFsm DataCycleController(
		.CLK(CLK), .RESETb(RESETb), .DTACK(DataDtack), .BERR(LOCAL_BERR), .ASb(asB),
		.DS0b(ds0B), .DS1b(ds1B), .LWORDb(lwordB), .A1(a1), .WRITEb(writeB), .IACKb(iackB),
		.BEATS(beats), .RATE(transfer_rate),
		.START_CYCLE(ld_addr_counter),
		.CR_CSR_CYCLE(cr_csr_cycle), .SINGLE_CYCLE(single_cycle), .SELECTED(module_selected),
		.BLT_CYCLE(blt_cycle), .MBLT_CYCLE(mblt_cycle),
		.A32D32_2EVME_CYCLE(a32d32_2evme_cycle), .A32D64_2EVME_CYCLE(a32d64_2evme_cycle),
		.A32D32_2ESST_CYCLE(a32d32_2esst_cycle), .A32D64_2ESST_CYCLE(a32d64_2esst_cycle),
		.BAD_CYCLE(bad_cycle), .INCR_ADDR_COUNTER(incr_addr_counter),
		.LD_A7_0(ld_a7_0), .DATA_PHASE_2E(data_2e_cycle), .CYCLE_IN_PROGRESS(cycle_in_progress),
		.USER_WAITb(USER_WAITb), .USER_WEb(USER_WEb), .USER_REb(USER_REb), .USER_OEb(USER_OEb),
		.any_bad(any_bad), .two_edge_start(two_edge_start)	// DEBUG
		);

	SevenOneShot IrqShaper(.CLK(CLK), .RESETb(RESETb), .SIG_IN(USER_IRQb), .SIG_OUT(set_irq_ident));

	IrqCtrlFsm IrqController(
		.CLK(CLK), .RESETb(RESETb), .START(ld_addr_counter), .DTACK(IrqDtack), .ASb(asB),
		.DS0b(ds0B), .IACKb(iackB), .IACK_INb(iackInB), .IACK_OUTb(VME_IackOutb),
		.ACK_LEVEL(irq_ack_level), .VME_IRQ(VME_IRQ),
		.IRQ_ENABLE(irq_enable[7:1]), .IRQ_IN(set_irq_ident),
		.IRQ_ID_SEL(irq_id_sel), .IACK_CYCLE(iack_cycle)
		);

endmodule

// Address counter: since only D32 (or D64) aligned transfers are allowed, it counts only double-words
module AdCnt(CLK, RESETb, U_ADDR, VME_ADDR, CR_CSR, TWO_EDGE, LD, LD_A7_0, INCR);
input CLK, RESETb, LD, LD_A7_0, INCR, CR_CSR, TWO_EDGE;
input [31:1] VME_ADDR;
output [29:0] U_ADDR;

reg [29:0] addr_counter;

assign U_ADDR = addr_counter;

	always @(posedge CLK or negedge RESETb)
	begin
		if( RESETb == 0 )
			addr_counter <= 0;
		else
		begin
			if( LD == 1 )
				addr_counter <= (CR_CSR == 1) ? {6'b0, VME_ADDR[23:1], 1'b0} :
					(TWO_EDGE ? {VME_ADDR[31:8], 6'b0} : VME_ADDR[31:2]);
				if( LD_A7_0 == 1 )
					addr_counter <= {addr_counter[29:6], VME_ADDR[7:2]};
					if( INCR == 1 )
						addr_counter <= addr_counter + 1;
		end
	end

endmodule

// CR-CSR and user spaces address decoder: each user space is 8 MBytes
module Decoder(ADDR, BAR, CR_CSR_CYC, CR_CSR_SEL, USER_CEb,
	ADER0, ADER1, ADER2, ADER3, ADER4, ADER5, ADER6, ADER7, CLK, RESETb);

	input [29:0] ADDR;
	input [7:0] BAR;
	input CR_CSR_CYC;
	output CR_CSR_SEL;
	output [7:0] USER_CEb;
	input [7:0] ADER0, ADER1, ADER2, ADER3, ADER4, ADER5, ADER6, ADER7;
	input CLK, RESETb;

	reg CR_CSR_SEL;
	reg [7:0] USER_CEb;

	always @(posedge CLK or negedge RESETb)
	begin
		if( RESETb == 0 )
		begin
			USER_CEb <= 8'hFF;
			CR_CSR_SEL <= 0;
		end
		else
		begin
			CR_CSR_SEL <= CR_CSR_CYC & (ADDR[23:19] == BAR[7:3]);
			USER_CEb <= 8'hFF;
			if( CR_CSR_CYC == 0 )
			begin
				if( ADDR[29:22] == ADER0 && ADER0 != 0 )
					USER_CEb[0] <= 0;
				if( ADDR[29:22] == ADER1 && ADER1 != 0 )
					USER_CEb[1] <= 0;
				if( ADDR[29:22] == ADER2 && ADER2 != 0 )
					USER_CEb[2] <= 0;
				if( ADDR[29:22] == ADER3 && ADER3 != 0 )
					USER_CEb[3] <= 0;
				if( ADDR[29:22] == ADER4 && ADER4 != 0 )
					USER_CEb[4] <= 0;
				if( ADDR[29:22] == ADER5 && ADER5 != 0 )
					USER_CEb[5] <= 0;
				if( ADDR[29:22] == ADER6 && ADER6 != 0 )
					USER_CEb[6] <= 0;
				if( ADDR[29:22] == ADER7 && ADER7 != 0 )
					USER_CEb[7] <= 0;
			end
		end
	end
/*
	always @(*)
	begin
		if( CR_CSR_CYC == 1 )
		begin
			USER_CEb <= 8'hFF;
			if( ADDR[23:19] == BAR[7:3] )
				CR_CSR_SEL <= 1;
			else
				CR_CSR_SEL <= 0;
		end
		else
		begin
			CR_CSR_SEL <= 0;
			USER_CEb <= 8'hFF;
			if( ADDR[29:22] == ADER0 && ADER0 != 0 )
				USER_CEb[0] <= 0;
			if( ADDR[29:22] == ADER1 && ADER1 != 0 )
				USER_CEb[1] <= 0;
			if( ADDR[29:22] == ADER2 && ADER2 != 0 )
				USER_CEb[2] <= 0;
			if( ADDR[29:22] == ADER3 && ADER3 != 0 )
				USER_CEb[3] <= 0;
			if( ADDR[29:22] == ADER4 && ADER4 != 0 )
				USER_CEb[4] <= 0;
			if( ADDR[29:22] == ADER5 && ADER5 != 0 )
				USER_CEb[5] <= 0;
			if( ADDR[29:22] == ADER6 && ADER6 != 0 )
				USER_CEb[6] <= 0;
			if( ADDR[29:22] == ADER7 && ADER7 != 0 )
				USER_CEb[7] <= 0;
		end
	end
*/
endmodule

// Configuration ROM
module ConfigRom(ADDR, DATAOUT);

	input [18:0] ADDR;
	output [31:0] DATAOUT;

	reg [7:0] data;

	assign DATAOUT = {24'b0, data};
	always @(*)
		case( ADDR )
			19'h00000: data <= 8'h00;	// Checksum
			19'h00004: data <= 8'h00;	// Length to be checksummed
			19'h00008: data <= 8'h10;	// Length to be checksummed
			19'h0000C: data <= 8'h00;	// Length to be checksummed
			19'h00010: data <= 8'h84;	// CR data access width
			19'h00014: data <= 8'h84;	// CSR data access width
			19'h00018: data <= 8'h02;	// VME64x CR-CSR space
			19'h0001C: data <= 8'h43;	// ASCII 'C'
			19'h00020: data <= 8'h52;	// ASCII 'R'
			19'h00024: data <= (`MANUFACTURER_ID>>16) & 8'hFF;	// Manufacturer ID
			19'h00028: data <= (`MANUFACTURER_ID>>8) & 8'hFF;	// Manufacturer ID
			19'h0002C: data <= `MANUFACTURER_ID & 8'hFF;		// Manufacturer ID
			19'h00030: data <= (`BOARD_ID>>24) & 8'hFF;		// Board ID
			19'h00034: data <= (`BOARD_ID>>16) & 8'hFF;		// Board ID
			19'h00038: data <= (`BOARD_ID>>8) & 8'hFF;		// Board ID
			19'h0003C: data <= `BOARD_ID & 8'hFF;			// Board ID
			19'h00040: data <= (`REVISION_ID>>24) & 8'hFF;		// Revision ID
			19'h00044: data <= (`REVISION_ID>>16) & 8'hFF;		// Revision ID
			19'h00048: data <= (`REVISION_ID>>8) & 8'hFF;		// Revision ID
			19'h0004C: data <= `REVISION_ID & 8'hFF;		// Revision ID
			19'h00050: data <= 8'h00;	// Pointer to a NULL terminated string
			19'h00054: data <= 8'h00;	// Pointer to a NULL terminated string
			19'h00058: data <= 8'h00;	// Pointer to a NULL terminated string
			19'h0005C: data <= (`COMPILE_TIME>>24) & 8'hFF;		// RESERVED
			19'h00060: data <= (`COMPILE_TIME>>16) & 8'hFF;		// RESERVED
			19'h00064: data <= (`COMPILE_TIME>>8) & 8'hFF;		// RESERVED
			19'h00068: data <= `COMPILE_TIME & 8'hFF;		// RESERVED
			19'h0007C: data <= 8'h01;	// Program ID code
			19'h000B0: data <= 8'h07;	// Begin User CSR area MSB
			19'h000B4: data <= 8'hBF;	// Begin User CSR area
			19'h000B8: data <= 8'hDB;	// Begin User CSR area LSB
			19'h000BC: data <= 8'h07;	// End User CSR area MSB
			19'h000C0: data <= 8'hFB;	// End User CSR area
			19'h000C4: data <= 8'hFF;	// End User CSR area LSB
			19'h000E0: data <= 8'h06;	// Slave characteristic
			19'h000F4: data <= 8'hFE;	// Interrupter capabilities
			19'h00100: data <= 8'h84;	// Function 0 data access width
			19'h00104: data <= 8'h84;	// Function 1 data access width
			19'h00108: data <= 8'h84;	// Function 2 data access width
			19'h0010C: data <= 8'h84;	// Function 3 data access width
			19'h00110: data <= 8'h84;	// Function 4 data access width
			19'h00114: data <= 8'h84;	// Function 5 data access width
			19'h00118: data <= 8'h84;	// Function 6 data access width
			19'h0011C: data <= 8'h84;	// Function 7 data access width
			19'h0012C: data <= 8'h03;	// Function 0 AM code mask byte 3 (AM=0x8,9,A,B,D,E,F)
			19'h00138: data <= 8'hEE;	// Function 0 AM code mask byte 6 (AM=0x20, 0x21)
			19'h0014C: data <= 8'h03;	// Function 1 AM code mask byte 3 (AM=0x8,9,A,B,D,E,F)
			19'h00158: data <= 8'hEE;	// Function 1 AM code mask byte 6 (AM=0x20, 0x21)
			19'h0016C: data <= 8'h03;	// Function 2 AM code mask byte 3 (AM=0x8,9,A,B,D,E,F)
			19'h00178: data <= 8'hEE;	// Function 2 AM code mask byte 6 (AM=0x20, 0x21)
			19'h0018C: data <= 8'h03;	// Function 3 AM code mask byte 3 (AM=0x8,9,A,B,D,E,F)
			19'h00198: data <= 8'hEE;	// Function 3 AM code mask byte 6 (AM=0x20, 0x21)
			19'h001AC: data <= 8'h03;	// Function 4 AM code mask byte 3 (AM=0x8,9,A,B,D,E,F)
			19'h001B8: data <= 8'hEE;	// Function 4 AM code mask byte 6 (AM=0x20, 0x21)
			19'h001CC: data <= 8'h03;	// Function 5 AM code mask byte 3 (AM=0x8,9,A,B,D,E,F)
			19'h001D8: data <= 8'hEE;	// Function 5 AM code mask byte 6 (AM=0x20, 0x21)
			19'h001EC: data <= 8'h03;	// Function 6 AM code mask byte 3 (AM=0x8,9,A,B,D,E,F)
			19'h001F8: data <= 8'hEE;	// Function 6 AM code mask byte 6 (AM=0x20, 0x21)
			19'h0020C: data <= 8'h03;	// Function 7 AM code mask byte 3 (AM=0x8,9,A,B,D,E,F)
			19'h00218: data <= 8'hEE;	// Function 7 AM code mask byte 6 (AM=0x20, 0x21)
			19'h00298: data <= 8'h08;	// Function 0 XAM code mask byte 30 (XAM=0x11)
			19'h0029C: data <= 8'h01;	// Function 0 XAM code mask byte 31 (XAM=0x01)
			19'h00318: data <= 8'h08;	// Function 1 XAM code mask byte 30 (XAM=0x11)
			19'h0031C: data <= 8'h01;	// Function 1 XAM code mask byte 31 (XAM=0x01)
			19'h00398: data <= 8'h08;	// Function 2 XAM code mask byte 30 (XAM=0x11)
			19'h0039C: data <= 8'h01;	// Function 2 XAM code mask byte 31 (XAM=0x01)
			19'h00418: data <= 8'h08;	// Function 3 XAM code mask byte 30 (XAM=0x11)
			19'h0041C: data <= 8'h01;	// Function 3 XAM code mask byte 31 (XAM=0x01)
			19'h00498: data <= 8'h08;	// Function 4 XAM code mask byte 30 (XAM=0x11)
			19'h0049C: data <= 8'h01;	// Function 4 XAM code mask byte 31 (XAM=0x01)
			19'h00518: data <= 8'h08;	// Function 5 XAM code mask byte 30 (XAM=0x11)
			19'h0051C: data <= 8'h01;	// Function 5 XAM code mask byte 31 (XAM=0x01)
			19'h00598: data <= 8'h08;	// Function 6 XAM code mask byte 30 (XAM=0x11)
			19'h0059C: data <= 8'h01;	// Function 6 XAM code mask byte 31 (XAM=0x01)
			19'h00618: data <= 8'h08;	// Function 7 XAM code mask byte 30 (XAM=0x11)
			19'h0061C: data <= 8'h01;	// Function 7 XAM code mask byte 31 (XAM=0x01)
			19'h00620: data <= 8'hFF;	// Function 0 address decoder mask byte 3 (A31..A24 are decoded)
			19'h00630: data <= 8'hFF;	// Function 1 address decoder mask byte 3 (A31..A24 are decoded)
			19'h00640: data <= 8'hFF;	// Function 2 address decoder mask byte 3 (A31..A24 are decoded)
			19'h00650: data <= 8'hFF;	// Function 3 address decoder mask byte 3 (A31..A24 are decoded)
			19'h00660: data <= 8'hFF;	// Function 4 address decoder mask byte 3 (A31..A24 are decoded)
			19'h00670: data <= 8'hFF;	// Function 5 address decoder mask byte 3 (A31..A24 are decoded)
			19'h00680: data <= 8'hFF;	// Function 6 address decoder mask byte 3 (A31..A24 are decoded)
			19'h00690: data <= 8'hFF;	// Function 7 address decoder mask byte 3 (A31..A24 are decoded)
			default: data <= 8'h00;
		endcase

endmodule

module ControlStatusRegisters(
	DATAIN, DATAOUT, ADDR, CLK, WEb, RESETb, CSR_EN, GA,
	ADER0, ADER1, ADER2, ADER3, ADER4, ADER5, ADER6, ADER7, BAR, BSET, BCLR, /* USER_BSET, */ USER_BCLR,
	USER_STATUS, USER_CTRL, IRQ_ID1, IRQ_ID2, IRQ_ID3, IRQ_ID4, IRQ_ID5, IRQ_ID6, IRQ_ID7,
	IRQ_ENABLE, SET_IRQ_IDENT
);
	input [7:0] DATAIN;
	output [31:0] DATAOUT;
	input [18:0] ADDR;
	input [4:0] GA;
	input CLK;
	input WEb;
	input RESETb;
	input CSR_EN;
	output [7:0] ADER0, ADER1, ADER2, ADER3, ADER4, ADER5, ADER6, ADER7,
		BAR, BSET, BCLR, /*USER_BSET,*/ USER_BCLR,
		IRQ_ID1, IRQ_ID2, IRQ_ID3, IRQ_ID4, IRQ_ID5, IRQ_ID6, IRQ_ID7,
		IRQ_ENABLE;
	input [7:0] USER_STATUS;
	input [7:1] SET_IRQ_IDENT;
	output [7:0] USER_CTRL;

	reg [7:0] ADER0, ADER1, ADER2, ADER3, ADER4, ADER5, ADER6, ADER7,
		BAR, BSET, BCLR, USER_BSET, USER_BCLR,
		IRQ_ID0, IRQ_ID1, IRQ_ID2, IRQ_ID3, IRQ_ID4, IRQ_ID5, IRQ_ID6, IRQ_ID7,
		IRQ_ENABLE, IRQ_IDENT;
	reg [7:0] data;

	parameter	def_ader0 = 3'h0, def_ader1 = 3'h1, def_ader2 = 3'h2, def_ader3 = 3'h3,
			def_ader4 = 3'h4, def_ader5 = 3'h5, def_ader6 = 3'h6, def_ader7 = 3'h7,
			def_bset = 8'h00, def_bclr = 8'h00,
			def_user_bset = 8'h00, def_user_bclr = 8'h00,
			def_irq_id0 = 8'h00, def_irq_id1 = 8'h00, def_irq_id2 = 8'h00, def_irq_id3 = 8'h00,
			def_irq_id4 = 8'h00, def_irq_id5 = 8'h00, def_irq_id6 = 8'h00, def_irq_id7 = 8'h00,
			def_irqEnable = 8'h00, def_irqIdent = 8'h00;

	assign USER_CTRL = USER_BSET;
	assign DATAOUT = {24'b0, data};

// Writing to the registers
	always @(posedge CLK or negedge RESETb)
	begin
		if( RESETb == 0 )
		begin
			ADER0 <= {GA, def_ader0}; ADER1 <= {GA, def_ader1};
			ADER2 <= {GA, def_ader2}; ADER3 <= {GA, def_ader3};
			ADER4 <= {GA, def_ader4}; ADER5 <= {GA, def_ader5};
			ADER6 <= {GA, def_ader6}; ADER7 <= {GA, def_ader7};
			BAR <= {GA, 3'b0};
			BSET <= def_bset; BCLR <= def_bclr;
			USER_BSET <= def_user_bset; USER_BCLR <= def_user_bclr;
			IRQ_ID1 <= def_irq_id1;
			IRQ_ID2 <= def_irq_id2; IRQ_ID3 <= def_irq_id3;
			IRQ_ID4 <= def_irq_id4; IRQ_ID5 <= def_irq_id5;
			IRQ_ID6 <= def_irq_id6; IRQ_ID7 <= def_irq_id7;
			IRQ_ENABLE <= def_irqEnable; IRQ_IDENT <= def_irqIdent;
		end
		else
		begin
			if( WEb == 0 && CSR_EN )
			begin
				case( ADDR )
					19'h7FFFC: BAR <= DATAIN;
					19'h7FFF8: BSET <= DATAIN;
					19'h7FFF4: BCLR <= DATAIN;
					19'h7FFEC: USER_BSET <= DATAIN;
					19'h7FFE8: USER_BCLR <= DATAIN;
					19'h7FFD0: ADER7 <= DATAIN;
					19'h7FFC0: ADER6 <= DATAIN;
					19'h7FFB0: ADER5 <= DATAIN;
					19'h7FFA0: ADER4 <= DATAIN;
					19'h7FF90: ADER3 <= DATAIN;
					19'h7FF80: ADER2 <= DATAIN;
					19'h7FF70: ADER1 <= DATAIN;
					19'h7FF60: ADER0 <= DATAIN;

					19'h7FBF8: IRQ_ID7 <= DATAIN;
					19'h7FBF4: IRQ_ID6 <= DATAIN;
					19'h7FBF0: IRQ_ID5 <= DATAIN;
					19'h7FBEC: IRQ_ID4 <= DATAIN;
					19'h7FBE8: IRQ_ID3 <= DATAIN;
					19'h7FBE4: IRQ_ID2 <= DATAIN;
					19'h7FBE0: IRQ_ID1 <= DATAIN;
					19'h7FBDC: IRQ_ENABLE <= DATAIN;
					19'h7FBD8: IRQ_IDENT <= (DATAIN | {SET_IRQ_IDENT, 1'b0});
				endcase
			end
			else	// Set IRQ_IDENT register from external
				IRQ_IDENT <= (IRQ_IDENT | {SET_IRQ_IDENT, 1'b0});
		end
	end

// Reading from the registers
	always @(*)
	begin
		case( ADDR )
			19'h7FFFC: data <= BAR;
			19'h7FFF8: data <= BSET;
			19'h7FFF4: data <= BCLR;
			19'h7FFEC: data <= USER_BSET;
			19'h7FFE8: data <= USER_BCLR;
			19'h7FFD0: data <= ADER7;
			19'h7FFC0: data <= ADER6;
			19'h7FFB0: data <= ADER5;
			19'h7FFA0: data <= ADER4;
			19'h7FF90: data <= ADER3;
			19'h7FF80: data <= ADER2;
			19'h7FF70: data <= ADER1;
			19'h7FF60: data <= ADER0;

			19'h7FBFC: data <= USER_STATUS;
			19'h7FBF8: data <= IRQ_ID7;
			19'h7FBF4: data <= IRQ_ID6;
			19'h7FBF0: data <= IRQ_ID5;
			19'h7FBEC: data <= IRQ_ID4;
			19'h7FBE8: data <= IRQ_ID3;
			19'h7FBE4: data <= IRQ_ID2;
			19'h7FBE0: data <= IRQ_ID1;
			19'h7FBDC: data <= IRQ_ENABLE;
			19'h7FBD8: data <= IRQ_IDENT;
			default: data <= 0;
		endcase
	end

endmodule

// State machine for transaction control
module CtrlFsm(
	CLK, RESETb, DTACK, BERR, ASb, DS0b, DS1b, LWORDb, A1, WRITEb, IACKb,
	BEATS, RATE, START_CYCLE, SELECTED, CR_CSR_CYCLE, SINGLE_CYCLE, BLT_CYCLE, MBLT_CYCLE,
	A32D32_2EVME_CYCLE, A32D64_2EVME_CYCLE, A32D32_2ESST_CYCLE, A32D64_2ESST_CYCLE, BAD_CYCLE,
	LD_A7_0, DATA_PHASE_2E, CYCLE_IN_PROGRESS,
	INCR_ADDR_COUNTER, USER_WAITb, USER_WEb, USER_REb, USER_OEb,
	any_bad, two_edge_start	// DEBUG
);
	input CLK, RESETb, ASb, DS0b, DS1b, LWORDb, A1, WRITEb, IACKb, START_CYCLE, SELECTED;
	input CR_CSR_CYCLE, SINGLE_CYCLE, BLT_CYCLE, MBLT_CYCLE, USER_WAITb;
	input A32D32_2EVME_CYCLE, A32D64_2EVME_CYCLE, A32D32_2ESST_CYCLE, A32D64_2ESST_CYCLE, BAD_CYCLE;
	input [7:0] BEATS;
	input [3:0] RATE;
	output DTACK, BERR, USER_WEb, USER_REb, USER_OEb, INCR_ADDR_COUNTER, LD_A7_0;
	output DATA_PHASE_2E, CYCLE_IN_PROGRESS;
	output any_bad, two_edge_start;

//	reg DTACK;
	reg BERR, INCR_ADDR_COUNTER, USER_WEb, USER_REb, USER_OEb, LD_A7_0;
	reg DATA_PHASE_2E, CYCLE_IN_PROGRESS;
	reg [7:0] status, next_status;
	reg [8:0] beat_counter;
	reg [3:0] rate_code;
	wire d32_good, d32_bad, d32u_bad, d16_bad, d08_bad, any_bad;
	wire two_edge_vme, two_edge_sst, two_edges, two_edge_start;
	reg dly_start, ld_beat_counter, decr_beat_counter, even_cycle;
	reg logic_dtack, logic_berr, invert_even, clear_even_cycle;
	reg logic_reB, logic_oeB, logic_weB;
	reg dly_start1;
	
//	reg d32_good, d32_bad, d32u_bad, d16_bad, d08_bad, any_bad;
//	reg two_edge_vme, two_edge_sst, two_edges, two_edge_start;

	parameter	S00 = 0, S01 = 1, S02 = 2, S03 = 3, S04 = 4, S05 = 5, S06 = 6, S07 = 7,
			S08 = 8, S09 = 9, S10 = 10, S11 = 11, S12 = 12, S13 = 13, S14 = 14, S15 = 15,
			S16 = 16, S17 = 17, S18 = 18, S19 = 19, S20 = 20, S21 = 21, S22 = 22, S23 = 23,
			S24 = 24, S25 = 25, S26 = 26, S27 = 27, S28 = 28, S29 = 29, S30 = 30, S31 = 31;
/*
	always @(posedge CLK)
	begin
		d32_good <= dly_start & SELECTED & ~DS0b & ~DS1b & ~LWORDb & ~A1 & IACKb;
		d32_bad  <= dly_start & SELECTED & ~DS0b & ~DS1b & ~LWORDb & ~A1 & IACKb & BAD_CYCLE;
		d32u_bad <= dly_start & SELECTED & ~DS0b & ~DS1b & ~LWORDb & A1 & IACKb;
		d16_bad  <= dly_start & SELECTED & ~DS0b & ~DS1b & LWORDb & IACKb;
		d08_bad  <= dly_start & SELECTED & ((~DS0b & DS1b) | (DS0b & ~DS1b)) & IACKb;
		any_bad <= (dly_start & SELECTED & ((~DS0b & ~DS1b & ~LWORDb & ~A1 & IACKb & BAD_CYCLE)
			| (~DS0b & ~DS1b & ~LWORDb & A1 & IACKb)
			| (~DS0b & ~DS1b & LWORDb & IACKb)
			| (((~DS0b & DS1b) | (DS0b & ~DS1b)) & IACKb))) | BAD_CYCLE;
		two_edge_vme <= A32D32_2EVME_CYCLE | A32D64_2EVME_CYCLE;
		two_edge_sst <= A32D32_2ESST_CYCLE | A32D64_2ESST_CYCLE;
		two_edges <= (A32D32_2EVME_CYCLE | A32D64_2EVME_CYCLE) |
			(A32D32_2ESST_CYCLE | A32D64_2ESST_CYCLE);
		two_edge_start <= dly_start & SELECTED & ~DS0b &
			(A32D32_2EVME_CYCLE | A32D64_2EVME_CYCLE) |
			(A32D32_2ESST_CYCLE | A32D64_2ESST_CYCLE);
	end
*/
	assign d32_good = dly_start & SELECTED & ~DS0b & ~DS1b & ~LWORDb & ~A1 & IACKb;
	assign d32_bad  = dly_start & SELECTED & ~DS0b & ~DS1b & ~LWORDb & ~A1 & IACKb & BAD_CYCLE;
	assign d32u_bad = dly_start & SELECTED & ~DS0b & ~DS1b & ~LWORDb & A1 & IACKb;
	assign d16_bad  = dly_start & SELECTED & ~DS0b & ~DS1b & LWORDb & IACKb;
	assign d08_bad  = dly_start & SELECTED & ((~DS0b & DS1b) | (DS0b & ~DS1b)) & IACKb;
	assign any_bad = d32_bad | d32u_bad | d16_bad | d08_bad | BAD_CYCLE;
	assign two_edge_vme = A32D32_2EVME_CYCLE | A32D64_2EVME_CYCLE;
	assign two_edge_sst = A32D32_2ESST_CYCLE | A32D64_2ESST_CYCLE;
	assign two_edges = two_edge_vme | two_edge_sst;
	assign two_edge_start = dly_start & SELECTED & ~DS0b & two_edges;

	assign DTACK = logic_dtack;

// Beat counter for 2e transfers
	always @(posedge CLK or negedge RESETb)
	begin
		if( RESETb == 0 )
		begin
			beat_counter <= 0;
			rate_code <= 0;
		end
		else
		begin
			if( ld_beat_counter == 1 )
			begin
				beat_counter <= {BEATS, 1'b0};
				rate_code <= RATE;
			end
			else
				if( decr_beat_counter == 1 )
					beat_counter <= beat_counter - 1;
		end
	end

// State register and something
	always @(posedge CLK or negedge RESETb)
	begin
		if( RESETb == 0 )
		begin
			status <= S00;
			dly_start <= 0;
			dly_start1 <= 0;
			even_cycle <= 0;
			//DTACK <= 0;
			BERR <= 0;
			USER_OEb <= 0;
			USER_REb <= 0;
			USER_WEb <= 0;
			CYCLE_IN_PROGRESS <= 0;
		end
		else
		begin
			status <= next_status;
			dly_start1 <= START_CYCLE;
			dly_start <= dly_start1;
			//DTACK <= logic_dtack;
			BERR <= logic_berr;
			USER_OEb <= logic_oeB;
			USER_REb <= logic_reB;
			USER_WEb <= logic_weB;
			if( clear_even_cycle )
				even_cycle <= 0;	// Start with Odd cycle
			else
				if( invert_even )
					even_cycle <= ~even_cycle;

			if( next_status == S00 || next_status == S01 )
				CYCLE_IN_PROGRESS <= 0;
			else
				CYCLE_IN_PROGRESS <= 1;
		end
	end

// Data Cycle State Transition Logic
	always @(*)
	begin
		logic_berr <= 0;
		logic_dtack <= 0;
		invert_even <= 0;
		logic_weB <= 1;
		logic_reB <= 1;
		logic_oeB <= 1;
		clear_even_cycle <= 0;
		INCR_ADDR_COUNTER <= 0;
		LD_A7_0 <= 0;
		DATA_PHASE_2E <= 0;
		ld_beat_counter <= 0;
		decr_beat_counter <= 0;
		next_status <= S00;

		case( status )
			S00:	begin	// Idle state: everything starts here
					next_status <= S00;
//					if( d32_good & (CR_CSR_CYCLE | SINGLE_CYCLE | BLT_CYCLE) )
					if( d32_good & (CR_CSR_CYCLE | SINGLE_CYCLE | BLT_CYCLE | MBLT_CYCLE) )
						next_status <= S02;
					else
						if( two_edge_start )
						begin
							next_status <= S08;
							logic_dtack <= 1;
						end
						else
							if( any_bad )
							begin
								next_status <= S01;
								logic_berr <= 1;
							end
				end
			S01:	begin	// Generate BERR
					logic_berr <= 1;
					if( DS0b & DS1b )
						next_status <= S00;
					else
						next_status <= S01;
				end
	// Standard cycles: SINGLE and BLT
			S02:	begin
					if( ~USER_WAITb )
						next_status <= S02;
					else
					begin
						if( ASb )
							next_status <= S00;
						else
							if( DS0b | DS1b )
								next_status <= S02;
							else
							begin
								if( WRITEb )
								begin
									logic_oeB <= 0;
									logic_reB <= 0;
									next_status <= S05;
								end
								else
								begin
									logic_weB <= 0;
									next_status <= S03;
								end
							end
					end

				end
			S03:	begin	// Write cycle
					logic_weB <= 1;
					logic_dtack <= 1;
					next_status <= S04;
				end
			S04:	begin	// Generate DTACK in writing cycles
					logic_dtack <= 1;
					if( DS0b & DS1b )
					begin
						next_status <= S07;
						logic_dtack <= 0;
					end
					else
						next_status <= S04;
				end
			S05:	begin	// Read cycle
					logic_reB <= 1;
					logic_oeB <= 0;
					logic_dtack <= 1;
					next_status <= S06;
				end
			S06:	begin	// Generate DTACK in reading cycles
					logic_oeB <= 0;
					logic_dtack <= 1;
					if( DS0b & DS1b )
					begin
						logic_oeB <= 1;
						logic_dtack <= 0;
						next_status <= S07;
					end
					else
						next_status <= S06;
				end
			S07:	begin	// Increment address counter every rising edge of DSx
					INCR_ADDR_COUNTER <= 1;
					if( BLT_CYCLE )
						next_status <= S02;
					else
						next_status <= S00;
				end

	// Two Edge cycles cycles: 2eVME and 2eSST. Master always end with even cycle
			S08:	begin
					logic_dtack <= 1;
					if( DS0b )
						next_status <= S09;
					else
						next_status <= S08;
				end
			S09:	begin	// Address phase 2: get Beat Count and A[7:0]
					logic_dtack <= 0;
					LD_A7_0 <= 1;
					ld_beat_counter <= 1;
					clear_even_cycle <= 1;
					next_status <= S10;
				end
			S10:	begin
					logic_dtack <= 0;
					if( ~DS0b )
					begin
						next_status <= S11;
						logic_dtack <= 1;
					end
					else
						next_status <= S10;
				end
			S11:	begin	// Address phase 3: Not Used
					if( ~USER_WAITb )
						next_status <= S11;
					else
					begin
						logic_dtack <= 1;
						if( ~DS1b )
							case( {WRITEb, two_edge_vme} )
								2'b00:	begin	// 2eSST write
										next_status <= S23;
									end
								2'b01:	begin	// 2eVME write
										next_status <= S16;
									end
								2'b10:	begin	// 2eSST read
										logic_reB <= 0;
										logic_oeB <= 0;
										next_status <= S20;
									end
								2'b11:	begin	// 2eVME read
										logic_reB <= 0;
										logic_oeB <= 0;
										next_status <= S12;
									end
							endcase
						else
							next_status <= S11;
					end
				end

			S12:	begin	// 2eVME read cycle
					DATA_PHASE_2E <= 1;
					logic_dtack <= ~even_cycle;
					logic_oeB <= 0;
					logic_reB <= 1;
					next_status <= S13;
				end
			S13:	begin
					DATA_PHASE_2E <= 1;
					logic_oeB <= 0;
					logic_dtack <= even_cycle;
					next_status <= S14;
				end
			S14:	begin
					DATA_PHASE_2E <= 1;
					logic_oeB <= 0;
					logic_dtack <= even_cycle;
					if( (DS1b & ~even_cycle) | (~DS1b & even_cycle) | DS0b )
					begin
						logic_oeB <= 1;
						invert_even <= 1;
						next_status <= S15;
					end
					else
						next_status <= S14;
				end
			S15:	begin
					// even_cycle = ~even_cycle
					DATA_PHASE_2E <= 1;
					logic_dtack <= even_cycle;
					INCR_ADDR_COUNTER <= 1;
					decr_beat_counter <= 1;
					if( (beat_counter == 0) | ASb | DS0b )
						next_status <= S00;
					else
					begin
						logic_reB <= 0;
						logic_oeB <= 0;
						logic_dtack <= ~even_cycle;
						next_status <= S12;
					end
				end

			S16:	begin	// 2eVME write cycle
					DATA_PHASE_2E <= 1;
					logic_dtack <= ~even_cycle;
					logic_weB <= 0;
					next_status <= S17;
				end
			S17:	begin
					DATA_PHASE_2E <= 1;
					logic_weB <= 1;
					logic_dtack <= even_cycle;
					next_status <= S18;
				end
			S18:	begin
					DATA_PHASE_2E <= 1;
					logic_dtack <= even_cycle;
					if( (DS1b & ~even_cycle) | (~DS1b & even_cycle) | DS0b )
					begin
						invert_even <= 1;
						next_status <= S19;
					end
					else
						next_status <= S18;
				end
			S19:	begin
					// even_cycle = ~even_cycle
					DATA_PHASE_2E <= 1;
					logic_dtack <= even_cycle;
					INCR_ADDR_COUNTER <= 1;
					decr_beat_counter <= 1;
					if( beat_counter == 0 || ASb || DS0b )
						next_status <= S00;
					else
					begin
						logic_dtack <= ~even_cycle;
						next_status <= S16;
					end
				end

			S20:	begin	// 2eSST read cycle: DTACK is the clock
					DATA_PHASE_2E <= 1;
					logic_oeB <= 0;
					logic_dtack <= ~even_cycle;
					next_status <= S21;
				end
			S21:	begin
					DATA_PHASE_2E <= 1;
					logic_dtack <= even_cycle;
					invert_even <= 1;
					decr_beat_counter <= 1;
					next_status <= S22;
				end
			S22:	begin
					// even_cycle = ~even_cycle
					logic_dtack <= even_cycle;
					DATA_PHASE_2E <= 1;
					INCR_ADDR_COUNTER <= 1;
					if( beat_counter == 0 || ASb || DS0b )
						next_status <= S00;
					else
					begin
						logic_reB <= 0;
						logic_oeB <= 0;
						logic_dtack <= ~even_cycle;
						next_status <= S20;
					end
				end

			S23:	begin	// 2eSST write cycle: DS1 is the clock
					DATA_PHASE_2E <= 1;
					logic_dtack <= 1;
					next_status <= S24;
				end
			S24:	begin
					DATA_PHASE_2E <= 1;
					logic_dtack <= 1;
					if( (DS1b & even_cycle) | (~DS1b & ~even_cycle) )
					begin
						logic_weB <= 0;
						invert_even <= 1;
						next_status <= S25;
					end
					else
						next_status <= S24;
				end
			S25:	begin
					// even_cycle = ~even_cycle
					DATA_PHASE_2E <= 1;
					logic_dtack <= 1;
					INCR_ADDR_COUNTER <= 1;
					decr_beat_counter <= 1;
					if( beat_counter == 0 || ASb || DS0b )
						next_status <= S00;
					else
						next_status <= S23;
				end

			default: next_status <= S00;
		endcase
	end

endmodule

// Issue a pulse every falling edge of the inputs, after seen the input low for 3 clock cycles
module SevenOneShot(CLK, RESETb, SIG_IN, SIG_OUT
);
	input CLK, RESETb;
	input [7:1] SIG_IN;
	output [7:1] SIG_OUT;

	reg [7:1] SIG_OUT, sr0, sr1, sr2;

	always @(posedge CLK or negedge RESETb)
	begin
		if( RESETb == 0 )
		begin
			SIG_OUT <= 0;
			sr0 <= 0; sr1 <= 0; sr2 <= 0;
		end
		else
		begin
			sr0 <= SIG_IN;
			sr1 <= sr0;
			sr2 <= sr1;
			SIG_OUT <= ~SIG_IN & ~sr0 & ~sr1 & sr2;
		end
	end

endmodule

// State machine to control the generation of VME_IRQ and the acknowledge cycle
module IrqCtrlFsm(CLK, RESETb, START, DTACK, ASb, DS0b, IACKb, IACK_INb, IACK_OUTb,
	ACK_LEVEL, VME_IRQ, IRQ_ENABLE, IRQ_IN, IRQ_ID_SEL, IACK_CYCLE
);
	input CLK, RESETb, START, ASb, DS0b, IACKb, IACK_INb; 
	output DTACK, IACK_OUTb, IACK_CYCLE;
	output [7:1] VME_IRQ;
	output [2:0] IRQ_ID_SEL;
	input [7:1] IRQ_ENABLE, IRQ_IN;
	input [3:1] ACK_LEVEL;

	reg DTACK, IACK_OUTb, IACK_CYCLE;
	reg [2:0] IRQ_ID_SEL;
	reg [7:1] IrqLine, ClrIrqLine;
	reg [7:0] status, next_status;
	reg logic_IackOutB, logic_IackCycle, dly_start, dly_start1;


	parameter	S00 = 0, S01 = 1, S02 = 2, S03 = 3, S04 = 4, S05 = 5, S06 = 6, S07 = 7;

	assign VME_IRQ = IrqLine;

// S-R sync register
	always @(posedge CLK or negedge RESETb)
	begin
		if( RESETb == 0 )
			IrqLine <= 0;
		else
			IrqLine <= (IrqLine & ~ClrIrqLine) | (IRQ_IN & IRQ_ENABLE);
	end

// Priority encoder
	always @(*)
	begin
		casex( IrqLine )
			7'b0000000:	IRQ_ID_SEL <= 0;
			7'b0000001:	IRQ_ID_SEL <= 1;
			7'b000001?:	IRQ_ID_SEL <= 2;
			7'b00001??:	IRQ_ID_SEL <= 3;
			7'b0001???:	IRQ_ID_SEL <= 4;
			7'b001????:	IRQ_ID_SEL <= 5;
			7'b01?????:	IRQ_ID_SEL <= 6;
			7'b1??????:	IRQ_ID_SEL <= 7;
			default:	IRQ_ID_SEL <= 0;
		endcase
	end

// Status register and something
	always @(posedge CLK or negedge RESETb)
	begin
		if( RESETb == 0 )
		begin
			status <= S00;
			IACK_OUTb <= 1;
			IACK_CYCLE <= 0;
			dly_start <= 0;
			dly_start1 <= 0;
		end
		else
		begin
			status <= next_status;
			IACK_OUTb <= logic_IackOutB;
			IACK_CYCLE <= logic_IackCycle;
			dly_start1 <= START;
			dly_start <= dly_start1;
		end
	end

// State transition logic
	always @(*)
	begin
		next_status <= S00;
		DTACK <= 0;
		logic_IackOutB <= 1;
		logic_IackCycle <= 0;
		ClrIrqLine <= 0;

		case( status )
			S00:	begin	// Start the IACK cycle
					if( dly_start & ~IACK_INb )
						next_status <= S01;
					else
						next_status <= S00;
				end
	 		S01:	begin	// Decide if this module has generated the level being acknowledges or not
					if( IRQ_ID_SEL > 0 && ACK_LEVEL == IRQ_ID_SEL )
						next_status <= S03;
					else
					begin
						logic_IackOutB <= 0;
						next_status <= S02;
					end
				end
			S02:	begin	// Asserts IACK_OUTb until the end of the cycle
					logic_IackOutB <= 0;
					if( IACK_INb == 0 )
						next_status <= S02;
					else
						next_status <= S00;
				end
			S03:	begin	// Wait for the Data Strobe
					if( DS0b == 1 )
						next_status <= S03;
					else
					begin
						logic_IackCycle <= 1;
						next_status <= S04;
					end
				end
			S04:	begin	// Put Status/ID on the VME_D07 lines
					logic_IackCycle <= 1;
					next_status <= S05;
				end
			S05:	begin	// Generates DTACK
					logic_IackCycle <= 1;
					DTACK <= 1;
					if( DS0b == 0 )
						next_status <= S05;
					else
					begin	// Release the generated IRQ line
						DTACK <= 0;
						ClrIrqLine[IRQ_ID_SEL] <= 1;
						logic_IackOutB <= 0;
						next_status <= S02;
					end
				end

			default: next_status <= S00;
		endcase
	end

endmodule

