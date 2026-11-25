# AmiMasterGear

**AmiMasterGear 1.2, community version** (25 November 2026). Download: the LhA archive on the [Releases](https://github.com/z00p/AmiMasterGear/releases) page.

AmiMasterGear is a Sega Master System and Game Gear emulator for AGA Amigas, in 68020
assembly, by Juan Antonio Gómez Gálvez and z00p. It plays `.sms` and `.gg` cartridge images
with sound, battery saves, frozen games (snapshots) and CD32 pads. While a game runs it takes
over the machine.

No games are included. Bring cartridge images you may legally have.

## History

Juan began AmiMasterGear in 1997 and made it freeware; his sources are version 0.8 (12
December 1999). In 2026 he gave them to the community. This is a community update, released
with his permission. Version 1.1 keeps his program and menu and fixes what kept games from
running: cartridges of any size, the Codemasters mapper, bank switching as newer homebrew
does it, two banks of cartridge RAM, the TMS9918 text mode, the sound chip, full-brightness
Master System colours and the CD32 pad. Version 1.2 adds the Master System II and Game Gear's
224-line picture (Micro Machines). What changed is in [CHANGES.md](CHANGES.md).

## Running it

The release archive holds the AmiMasterGear drawer: the program, a Cartridges drawer (where
Insert opens, with the pad test cartridges PadTest.sms and PadTest.gg), a Frozen drawer,
`ReadMe.txt`, `AmiMasterGear.guide`, `CHANGES.txt` and `NOTICE.txt`. The manual is
[docs/package/ReadMe.txt](docs/package/ReadMe.txt): requirements, keys and pads, saves and
the limits.

Needs an AGA Amiga with a 68020 or better and AmigaOS 3.0 or later. Tested on an A1200 with a
PiStorm and in WinUAE. Not supported: the FM sound unit and the PAL Master System II's 240-line
picture.

## Building

- Assembler: [vasm](http://sun.hasenbraten.de/vasm/), the 68k Motorola-syntax version
  (`vasmm68k_mot`, tested with 2.0f). Put it at `tools/vasmm68k_mot.exe`, have it on the
  PATH, or set `VASM`.
- `sh build.sh rel` builds the 1.2 program, `build/rel/AmiMasterGear`;
  `sh build.sh rel11` the 1.1 release program byte for byte, `build/rel11/AmiMasterGear`. The
  switches each sets are listed in `build.sh`.
- `sh build.sh` with no switches builds Juan's v0.8 unchanged.
- The vasm line, for reference, run inside `src/`:
  `vasmm68k_mot -devpac -nocase -m68020 -Fhunkexe -nosym -maxerrors=0 -DAMG_...=1 -o AmiMasterGear AmiMasterGear_Main.asm`
- `python tools/padtest_sms.py` builds PadTest.sms and PadTest.gg (needs
  [sjasmplus](https://github.com/z00m128/sjasmplus); set `SJASMPLUS` or have it on the PATH).
- `python tools/make_release.py` builds the program and the pad tests and stages the release
  drawer in `build/release/` (needs Pillow for the drawer and text icons). The archive is
  made with the Amiga's own `lha`.

## Layout

| Path | What |
|---|---|
| `src/AmiMasterGear_Main.asm` | Juan's emulator: Z80, VDP, sound, pads, the main loop |
| `src/AmiMasterGear_Menu.asm` | Juan's menu, loader, saves and prefs |
| `src/GadToolsBox/` | the menu's GadToolsBox source and generated code |
| `src/data/` | Juan's graphics (logo, panel, font, pad pictures) and noise sample |
| `src/Amg10.asm` | the community changes, each behind its own `AMG_` switch |
| `src/AutoTest.asm` | test builds only (`-DAUTOTEST=1`), never in a release |
| `docs/package/` | the ReadMe that goes in the archive |
| `release/icons/` | the program's icon |
| `tools/` | the pad test cartridge and the release staging |

The first commit is Juan's v0.8 source as he gave it; then version 1.1 and version 1.2.

## Credit

- **AmiMasterGear:** Juan Antonio Gómez Gálvez (GUS Entertainment) and z00p (versions 1.1 and 1.2).
- **Icons and graphics** in Juan's original: Multivac.
- **CD32 pad read:** Afrotechmods / FAmiga.
- **Thanks** (Juan's): Zener and Sandman.
- Juan's original was made with Devpac III (HiSoft) and GadToolsBox (Jaba Development).

## Licence

AmiMasterGear is freeware by Juan Antonio Gómez Gálvez. Versions 1.1 and 1.2, by z00p, are a community
update made and published with his permission. The CD32 pad read is under the MIT licence.
See [NOTICE.md](NOTICE.md).

## Trademarks

Sega Master System and Game Gear are trademarks of Sega. This project is not affiliated with
or endorsed by Sega.

## Reporting problems

Open an issue with the game, the Joy-Control setting, and your machine: CPU or accelerator, or
emulator.
