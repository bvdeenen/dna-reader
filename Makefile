all: dna_ctrl.vhd

dna_ctrl.vhd: dna_ctrl.psm
	kcpsm3.sh dna_ctrl.psm

dna_ctrl.mem: dna_ctrl.vhd	

bitfile: reading_dna.bit

reading_dna.bit reading_dna_rp.bit: dna_ctrl.mem 
	data2mem -bm my.bmm -bd dna_ctrl.mem -bt $@ 
	
impact:
	impact -batch project.batch

clean:
	@-rm dna_ctrl.coe dna_ctrl.fmt dna_ctrl.log dna_ctrl.vhd dna_ctrl.mem
	@-rm pass*.dat labels.txt constant.txt

