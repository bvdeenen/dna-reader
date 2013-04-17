setMode -bscan
setCable -p auto
addDevice -position 1 -file reading_dna.bit
addDevice -position 2 -part "xcf04s"
program -e -p 1
quit
