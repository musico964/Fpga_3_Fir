`define HeaderLSB 8'h48  // "H"
`define HeaderMSB 8'h45  // "E"

module UsbSlaveIf(
	USB_RDb, USB_WR, USB_TXEb, USB_RXFb,
	USB_D,
	USER_ADDR, // 22 bit
       	USER_DATA, // 64 bit
	USER_WEb, USER_REb, USER_OEb,
	USER_CEb, // 8 bit
	RESETb, CK40, CK50, FSM0b
);

output USB_RDb, USB_WR;
input USB_TXEb, USB_RXFb;
inout [7:0] USB_D;
output [21:0] USER_ADDR;
inout [63:0] USER_DATA;
output USER_WEb, USER_REb, USER_OEb;
output [7:0] USER_CEb;
input RESETb, CK40, CK50;
output FSM0b;

reg USB_RDb, USB_WR;
reg USER_WEb, USER_REb, USER_OEb;
reg fsm_USER_WEb, fsm_USER_REb, old_fsm_USER_WEb, old_fsm_USER_REb;
reg [7:0] USER_CEb;
reg FSM0b;
reg ck20, ddir;
reg [7:0] fsm_status;
reg [7:0] hdr0, hdr1, usb_write_data;
reg [6:0] wc;
reg [15:0] addr;
reg [31:0] write_data, read_data;

wire usb_data_available, usb_tx_ready;

assign USER_ADDR = {6'b000000, addr};
assign usb_data_available = ~USB_RXFb;
assign usb_tx_ready = ~USB_TXEb;
assign header_found = (hdr0 == `HeaderLSB && hdr1 == `HeaderMSB) ? 1 : 0; // hdr == "HE"
assign USER_DATA = (USER_WEb == 0) ? {32'b0, write_data} : 64'bz;
assign USB_D = (USB_WR == 1) ? usb_write_data : 8'bz;

always @(posedge CK40 or negedge RESETb)
	if( RESETb == 0 )
		ck20 <= 0;
	else
		ck20 <= ~ck20;

always @(posedge CK50 or negedge RESETb)
begin
	if( RESETb == 0 )
	begin
		USER_WEb <= 1;
		USER_REb <= 1;
		old_fsm_USER_WEb <= 0;
		old_fsm_USER_REb <= 0;
	end
	else
	begin
		old_fsm_USER_WEb <= fsm_USER_WEb;
		old_fsm_USER_REb <= fsm_USER_REb;

		if( old_fsm_USER_WEb == 1 && fsm_USER_WEb == 0 )
			USER_WEb <= 0;
		else
			USER_WEb <= 1;

		if( old_fsm_USER_REb == 1 && fsm_USER_REb == 0 )
			USER_REb <= 0;
		else
			USER_REb <= 1;
	end
end

always @(posedge ck20 or negedge RESETb)
begin
	if( RESETb == 0 )
	begin
		USB_RDb <= 1;
		USB_WR <= 0;
		fsm_USER_WEb <= 1;
		fsm_USER_REb <= 1;
		USER_OEb <= 1;
		USER_CEb <= 8'hFF;
		addr <= 0;
		hdr0 <= 0; hdr1 <= 0;
		wc <= 0; ddir <= 0;
		write_data <= 0; read_data <= 0;
		FSM0b <= 0;
		fsm_status <= 0;
	end
	else
	begin
		case( fsm_status )
			0:  begin
				hdr0 <= 0; hdr1 <= 0;
				wc <= 0;   ddir <= 0;
				fsm_USER_WEb <= 1; fsm_USER_REb <= 1; USER_OEb <= 1;
				USER_CEb <= 8'hFF;
				USB_RDb <= 1; USB_WR <= 0;
				FSM0b <= 0;
				if( usb_data_available )
				begin
					USB_RDb <= 0;
					fsm_status <= 1;
				end
			    end
			1:  begin
				FSM0b <= 1;
				hdr0 <= USB_D;
				USB_RDb <= 1;
				fsm_status <= 2;
			    end
			2:  begin
				if( usb_data_available )
				begin
					USB_RDb <= 0;
					fsm_status <= 3;
				end
				else
					fsm_status <= 2;
			    end
			3:  begin
				hdr1 <= USB_D;
				USB_RDb <= 1;
				fsm_status <= 4;
			    end
			4:  begin
				if( header_found )
					fsm_status <= 40;
				else
					fsm_status <= 0;
			    end
			40: begin
				if( usb_data_available )
				begin
					USB_RDb <= 0;
					fsm_status <= 5;
				end
				else
					fsm_status <= 40;
			    end
			5:  begin
				hdr0 <= 0; hdr1 <= 0;
				ddir <= USB_D[7];
			       	wc <= USB_D[6:0];
				USB_RDb <= 1;
				fsm_status <= 6;
			    end
			6:  begin
				if( usb_data_available )
				begin
					USB_RDb <= 0;
					fsm_status <= 7;
				end
				else
					fsm_status <= 6;
			    end
			7:  begin
				USER_CEb <= USB_D;
				USB_RDb <= 1;
				fsm_status <= 8;
			    end
			8:  begin
				if( usb_data_available )
				begin
					USB_RDb <= 0;
					fsm_status <= 9;
				end
				else
					fsm_status <= 8;
			    end
			9:  begin
				addr[15:8] <= USB_D;
				USB_RDb <= 1;
				fsm_status <= 10;
			    end
			10: begin
				if( usb_data_available )
				begin
					USB_RDb <= 0;
					fsm_status <= 11;
				end
				else
					fsm_status <= 10;
			    end
			11: begin
				addr[7:0] <= USB_D;
				USB_RDb <= 1;
				if( ddir == 0 )
					fsm_status <= 12;
				else
					fsm_status <= 22;
			    end

			12: begin	// Write
				if( wc == 0 )
					fsm_status <= 0;
				else
				begin
					if( usb_data_available )
					begin
						USB_RDb <= 0;
						fsm_status <= 13;
					end
					else
						fsm_status <= 12;
				end
			    end
			13: begin
				write_data[31:24] <= USB_D;
				USB_RDb <= 1;
				fsm_status <= 14;
			    end
			14: begin
				if( usb_data_available )
				begin
					USB_RDb <= 0;
					fsm_status <= 15;
				end
				else
					fsm_status <= 14;
			    end
			15: begin
				write_data[23:16] <= USB_D;
				USB_RDb <= 1;
				fsm_status <= 16;
			    end
			16: begin
				if( usb_data_available )
				begin
					USB_RDb <= 0;
					fsm_status <= 17;
				end
				else
					fsm_status <= 16;
			    end
			17: begin
				write_data[15:8] <= USB_D;
				USB_RDb <= 1;
				fsm_status <= 18;
			    end
			18: begin
				if( usb_data_available )
				begin
					USB_RDb <= 0;
					fsm_status <= 19;
				end
				else
					fsm_status <= 18;
			    end
			19: begin
				write_data[7:0] <= USB_D;
				USB_RDb <= 1;
				fsm_status <= 20;
			    end
			20: begin
				fsm_USER_WEb <= 0;
				fsm_status <= 21;
			    end
			21: begin
				fsm_USER_WEb <= 1;
				wc <= wc - 7'h1;
				addr <= addr + 16'h1;
				fsm_status <= 12;
			    end

			22: begin	// Read
				if( wc == 0 )
					fsm_status <= 0;
				else
				begin
					fsm_USER_REb <= 0;
					USER_OEb <= 0;
					fsm_status <= 23;
				end
			    end
			23: begin
				fsm_USER_REb <= 1;
				USER_OEb <= 1;
				read_data <= USER_DATA[31:0];
				fsm_status <= 24;
			    end
			24: begin
				if( usb_tx_ready )
				begin
					usb_write_data <= read_data[31:24];
					USB_WR <= 1;
					fsm_status <= 25;
				end
				else
					fsm_status <= 24;
			    end
			25: begin
				USB_WR <= 0;
				fsm_status <= 26;
			    end
			26: begin
				if( usb_tx_ready )
				begin
					usb_write_data <= read_data[23:16];
					USB_WR <= 1;
					fsm_status <= 27;
				end
				else
					fsm_status <= 26;
			    end
			27: begin
				USB_WR <= 0;
				fsm_status <= 28;
			    end
			28: begin
				if( usb_tx_ready )
				begin
					usb_write_data <= read_data[15:8];
					USB_WR <= 1;
					fsm_status <= 29;
				end
				else
					fsm_status <= 28;
			    end
			29: begin
				USB_WR <= 0;
				fsm_status <= 30;
			    end
			30: begin
				if( usb_tx_ready )
				begin
					usb_write_data <= read_data[7:0];
					USB_WR <= 1;
					fsm_status <= 31;
				end
				else
					fsm_status <= 30;
			    end
			31: begin
				USB_WR <= 0;
				fsm_status <= 32;
			    end
			32: begin
				wc <= wc - 7'h1;
				addr <= addr + 16'h1;
				fsm_status <= 22;
			    end
		endcase
	end
end

endmodule

