#!/bin/sh
# Assemble AmiMasterGear with vasm (Devpac mode). Output: build/AmiMasterGear
#   sh build.sh                          Juan's v0.8, no behaviour changes
#   sh build.sh rel                      the 1.3 program: build/rel/AmiMasterGear
#   sh build.sh rel12                    the 1.2 release program, byte for byte: build/rel12/AmiMasterGear
#   sh build.sh rel11                    the 1.1 release program, byte for byte: build/rel11/AmiMasterGear
#   sh build.sh rel20                    the 2.0 programs: build/rel20/AGA (1.3 + AMG_V20) and build/rel20/RTG
#                                        (1.3 + the RTG switches + AMG_V20, release titles)
#   sh build.sh rtg                      the RTG test program (1.3 + AMG_RTG, src/AmgRtg.asm; half-1080 game mode, the menu on RTG, AmiMasterGear.config screen options, the build in the titles): build/rtg/AmiMasterGear
#                                        with the big 1080p menu (AMG_BIGMENU, src/AmgMenu.asm)
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
# the RTG program's switches (src/AmgRtg.asm, src/AmgMenu.asm)
RTG="RTG RTGHALF RTGMENU BIGMENU RTGCFG RTGDBUF RTGSCAN DBUFDEF"
# rel20 builds both 2.0 programs: AGA (the 1.3 program with the 2.0 texts) and RTG (no build info)
if [ "$1" = rel20 ]; then
  OUT=build/rel20/AGA VASMDEFS="$VASMDEFS -DAMG_V20=1" sh "$0" rel || exit 1
  OUT=build/rel20/RTG VASMDEFS="$VASMDEFS -DAMG_V20=1" sh "$0" rtgrel
  exit $?
fi
if [ "$1" = rel ] || [ "$1" = rel12 ] || [ "$1" = rel11 ] || [ "$1" = rtg ] || [ "$1" = rtgrel ]; then
  [ "$1" != rel11 ] && REL="$REL $REL12"
  [ "$1" = rel ] && REL="$REL $REL13"
  [ "$1" = rtg ] && REL="$REL $REL13 $RTG BUILDINFO"
  [ "$1" = rtgrel ] && REL="$REL $REL13 $RTG"
  for s in $REL; do VASMDEFS="$VASMDEFS -DAMG_$s=1"; done
  mkdir -p build/$1 "$(dirname "${OUT:-build/$1/x}")"
  OUT=${OUT:-build/$1/AmiMasterGear}
fi
out=${OUT:-build/AmiMasterGear}
# AMG_BUILDINFO: the build in the menu's titles (src/Amg10.asm), from build/buildinfo.i, as the other
# emulators' test builds: "AmiMasterGear <AMG_VER> - <BUILDNAME> - test build <n> <dd.mm.yyyy hh:mm>",
# e.g. BUILDNAME="Sync Log" sh build.sh rtg. <n> counts the rtg builds, shared by all worktrees
# (<main checkout>/build/buildno).
case "$1" in rtg) ver=${AMG_VER:-2.0}; name=${BUILDNAME:-RTG dev} ;; *) ver=${AMG_VER:-1.2}; name=${BUILDNAME:-dev} ;; esac
nf="$(cd "$(git rev-parse --git-common-dir 2>/dev/null || echo .git)/.." && pwd)/build/buildno"
n=$(cat "$nf" 2>/dev/null || echo 0)
if [ "$1" = rtg ]; then n=$((n + 1)); mkdir -p "$(dirname "$nf")"; echo $n > "$nf"; fi
printf 'AMGBUILD\tMACRO\n\tDC.B\t"AmiMasterGear %s - %s - test build %s %s"\n\tENDM\n' \
  "$ver" "$name" "$n" "$(date '+%d.%m.%Y %H:%M')" > build/buildinfo.i
printf 'AMGVERS\tMACRO\n\tDC.B\t"AmiMasterGear %s"\n\tENDM\n' "$ver" >> build/buildinfo.i  # the credit and About boxes
( cd src && "$VASM" -devpac -nocase -m68020 -Fhunkexe -nosym -maxerrors=0 -I../build $VASMDEFS \
    -o "../$out" AmiMasterGear_Main.asm ) > build/build.log 2>&1
rc=$?
grep -E "^(error|fatal)" build/build.log | head -20
echo "vasm exit $rc ($out); $(grep -c '^warning' build/build.log) warnings"
exit $rc
