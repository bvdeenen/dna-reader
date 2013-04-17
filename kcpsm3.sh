#!/bin/bash


# here I keep the dos files
# The unix path is a link to the directory with KCPSM3.EXE and ROM_form.* files in it
UNIXPATH=./XASM
TIMESTAMPFILE=$UNIXPATH/.timestamp
LOGFILE=kcpsm3.log
ln -sf $PWD/XASM $HOME/.dosemu/drive_c/XASM

if [ ! -e $UNIXPATH/KCPSM3.EXE -o ! -e $UNIXPATH/ROM_form.coe -o \
    ! -e $UNIXPATH/ROM_form.vhd -o ! -e $UNIXPATH/ROM_form.v ] ; then
    echo "$UNIXPATH doesn't contain one of the 4 required assembler files"
    exit 1

fi

FILENAME=$1

cp $FILENAME $UNIXPATH
BN=${FILENAME%.psm}

touch $TIMESTAMPFILE

INPUT="\P1;  C:\r cd \\xasm\r kcpsm3 $FILENAME > $LOGFILE\r exitemu\r"
dosemu -dumb -quiet -input "$INPUT"

mv $(find $UNIXPATH/ -type f -newer $TIMESTAMPFILE) .
rm $TIMESTAMPFILE
rm $UNIXPATH/$(basename $FILENAME)
rm $HOME/.dosemu/drive_c/XASM

ERR=$(egrep "^ERROR" $LOGFILE)
if [ "$ERR" != "" ] ; then
	echo "ERRORS : $ERR "
	exit 1 
else
	exit 0
fi
