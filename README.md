This is the implementation of the FPGA v3 for the Multi Purpose Digitizer (MPD)
used for GEM detector readout in the SBS setup at Jefferson Laboratory (USA).

No implementation for DDR2 SDRAM interface, Aurora Interface.
It implements an outdated VME address map.
No simulation environment used here.

This is implemented only on MPD HW4 release.

Directory structure
```
.			
|
+---+-- Mpd_Common	Common Rtl Code, user generated and MegaWizard generated
    |
    +-- Fir_Modules	FIR filters modules: 16 taps for MPD4
    |
    +-- Mpd4		Top level RTL files (Fpga_3.v), implementation specific verilog files (*Pll.v, VmeSlaveIf.v)
					and QUARTUS files for AGX50 implementation MPD rev 4.0
```	
	
