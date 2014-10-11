/home/ggraves/scripts/AndroidSetup.sh
sftp -b /home/ggraves/scripts/cmds ggraves@pico.metrobg.com

/home/ggraves/scripts/loadIV-ADDL.pl   64.31.183.210 wigrodma 
/home/ggraves/scripts/loadAP-VENFIL.pl 64.31.183.210 wigrodma 
/home/ggraves/scripts/loadAR-CCLASS.pl 64.31.183.210 wigrodma
/home/ggraves/scripts/loadAR-CTYPE.pl  64.31.183.210 wigrodma
/home/ggraves/scripts/updAR-CUSMAS.pl  64.31.183.210 wigrodma
/home/ggraves/scripts/loadAR-CUSMAS.pl 64.31.183.210 wigrodma
/home/ggraves/scripts/loadAR-SLSMAN.pl 64.31.183.210 wigrodma
/home/ggraves/scripts/loadIV-ITMFIL.pl 64.31.183.210 wigrodma 
/home/ggraves/scripts/loadIV-MCODE.pl  64.31.183.210 wigrodma 
/home/ggraves/scripts/loadIV-PCLASS.pl 64.31.183.210 wigrodma
AGHOME=/home/ag6;TERM=xterm;export AGHOME TERM;/home/ag6/bin/show /tmp/IV-STATUS > /tmp/iv-keys
/home/ggraves/scripts/loadIV-STATUS.pl 64.31.183.210 wigrodma
/home/ggraves/scripts/loadIV-UOFM.pl   64.31.183.210 wigrodma
