all: pico

dna_ctrl.mem dna_ctrl.vhd dna_ctrl.hex: dna_ctrl.psm	
	./kcpsm3.sh dna_ctrl.psm

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


reading_dna.ngd: dna_ctrl.vhd
	xst -intstyle ise -ifn reading_dna.xst -ofn reading_dna.syr
	ngdbuild -intstyle ise -dd _ngo -nt timestamp -uc reading_dna.ucf -p xc3s700a-fg484-4 reading_dna.ngc reading_dna.ngd

reading_dna.pcf: reading_dna.ngd
	map -intstyle ise -p xc3s700a-fg484-4 -cm area -ir off -pr off -c 100 -o reading_dna_map.ncd reading_dna.ngd reading_dna.pcf


reading_dna.ncd: reading_dna.pcf
	par -w -intstyle ise -ol high -t 1 reading_dna_map.ncd reading_dna.ncd reading_dna.pcf
	trce -intstyle ise -v 3 -s 4 -n 3 -fastpaths -xml reading_dna.twx reading_dna.ncd -o reading_dna.twr reading_dna.pcf -ucf reading_dna.ucf

reading_dna.bit: reading_dna.ncd
	bitgen -intstyle ise -f reading_dna.ut reading_dna.ncd

