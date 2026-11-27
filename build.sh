#!/bin/sh
# Assemble AmiMasterGear with vasm (Devpac mode). Output: build/AmiMasterGear
#   sh build.sh                          Juan's v0.8, no behaviour changes
#   sh build.sh rel                      the 1.3 program: build/rel/AmiMasterGear
#   sh build.sh rel12                    the 1.2 release program, byte for byte: build/rel12/AmiMasterGear
#   sh build.sh rel11                    the 1.1 release program, byte for byte: build/rel11/AmiMasterGear
#   VASMDEFS="-DSWITCH=1" sh build.sh    extra assembler switches (with rel too)
#   VASM=path/to/vasmm68k_mot sh build.sh  another assembler (tested: vasm 2.0f)
# Without VASM: tools/vasmm68k_mot.exe, else vasmm68k_mot on the PATH.
cd "$(dirname "$0")" && mkdir -p build || exit 1
root=$(pwd)
if [ -z "$VASM" ]; then
  VASM=vasmm68k_mot
  [ -f "$root/tools/vasmm68k_mot.exe" ] && VASM=$root/tools/vasmm68k_mot.exe
fi
# The 1.1 release: every change from v0.8, each behind its own AMG_ switch (src/Amg10.asm)
REL="ANYSIZE BITMAP CODIES FROZERR IXMAP PALFULL SRAM2 TITLES DRAWERS PADS NTSC VDPCODE2 RASTERPAL
TMSMODES PORTMIRROR RAMMIRROR VDPSTATUS PORTLABELS PAUSEEDGE PADMAP PSG"
# 1.2 adds these (also in src/Amg10.asm)
REL12="M224 DELPAUSE PADDEF HELP V12 SPRPRI BGPRI P2PAD NOISELVL OLDPREFS"
# 1.3 adds these (src/Amg10.asm; NAMECAP's hook in src/AmiMasterGear_Menu.asm)
REL13="NOISESTOP NAMECAP V13"
if [ "$1" = rel ] || [ "$1" = rel12 ] || [ "$1" = rel11 ]; then
  [ "$1" != rel11 ] && REL="$REL $REL12"
  [ "$1" = rel ] && REL="$REL $REL13"
  for s in $REL; do VASMDEFS="$VASMDEFS -DAMG_$s=1"; done
  mkdir -p build/$1
  OUT=${OUT:-build/$1/AmiMasterGear}
fi
out=${OUT:-build/AmiMasterGear}
( cd src && "$VASM" -devpac -nocase -m68020 -Fhunkexe -nosym -maxerrors=0 $VASMDEFS \
    -o "../$out" AmiMasterGear_Main.asm ) > build/build.log 2>&1
rc=$?
grep -E "^(error|fatal)" build/build.log | head -20
echo "vasm exit $rc ($out); $(grep -c '^warning' build/build.log) warnings"
exit $rc
