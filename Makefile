all: dna_ctrl.xsvf

dna_ctrl.mem dna_ctrl.hex: dna_ctrl.psm	
	kcpsm3.sh dna_ctrl.psm

dna_ctrl.svf: dna_ctrl.hex
	dosemu hex2svf.exe dna_ctrl.hex  dna_ctrl.svf

dna_ctrl.xsvf: dna_ctrl.svf
	svf2xsvf502 -d -i dna_ctrl.svf -o dna_ctrl.xsvf
	
pico: dna_ctrl.xsvf
	impact -batch update_pb.cmd
	
install: reading_dna.bit
	impact -batch install.cmd

impact:
	impact -ipf jtag-uploader.ipf

clean:
	@-rm dna_ctrl.coe dna_ctrl.fmt dna_ctrl.log dna_ctrl.vhd dna_ctrl.mem
	@-rm pass*.dat labels.txt constant.txt

