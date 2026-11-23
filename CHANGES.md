# Changes from Juan's v0.8

AmiMasterGear 1.1 is built from the sources of AmiMasterGear v0.8 (12 December 1999) by Juan
Antonio Gómez Gálvez. This file lists what changed for the user, grouped. Every change sits
behind its own assembler switch (`AMG_` names in `src/Amg10.asm`); without them the source
builds Juan's v0.8 byte for byte.

## 1.1 (pre-release, 23 November 2026)

The first community version, by Juan Antonio Gómez Gálvez and z00p.

### Cartridges
- Cartridges of any size up to 4 MB load. v0.8 refused any size that was not a multiple of
  32 KB ("Invalid Cartridge size!!"): 16 KB and 48 KB homebrew cartridges, Jumping Jack'son
  (208 KB).
- Codemasters cartridges: Micro Machines (Master System and Game Gear) and Micro Machines 2
  (Game Gear) run. v0.8 showed a black screen or garbage.
- Bank switching written through the IX and IY registers, and with the SET and RES
  instructions, now reaches the cartridge's mapper, as on the console. Many newer homebrew
  games switch banks that way: Electronic Dreams and Razing Core (black screen in v0.8), The
  Sword of Stone (wrong tiles on every screen) and Frontier Force (green bars) now run
  properly.
- Two banks of cartridge RAM instead of one. Shining Force: The Sword of Hajya starts (black
  screen in v0.8). Its battery file keeps both banks (32 KB); other games' files stay 16 KB.
  Defenders of Oasis and Royal Stone can now switch their battery RAM on and off.
- The console's 8 KB of RAM is mirrored at $E000-$FFFF, and the I/O ports answer over the
  whole range the console decodes, as on the console. Black Sea Treasure Hunters needs both.

### Picture
- Master System colours at full brightness: white is white (v0.8 drew it at 80%). Game Gear
  colours are unchanged.
- The TMS9918 text mode and Graphic II mode, with their sprites, are drawn. Black Sea Treasure
  Hunters plays (its menu was garbage in v0.8).
- The VDP status flags behave as on the console (v0.8 returned a made-up line flag and
  toggled the collision flag on each read). Black Sea Treasure Hunters no longer restarts.
- Writes to the VDP's registers also set its address, as on the console: no stray marks down
  the left edge of Ax Battler's intro.
- Realtime Palette Refresh is on by default, so colour changes partway down the screen show:
  the lower colour band of GG Aleste II's title is back.
- The screen is NTSC (60 Hz) by default: most games, and the Game Gear, are 60 Hz. PAL is the
  other Screen choice. Saved prefs still win.

### Sound
- The sound chip is followed as it works: a short "low bits only" note update no longer
  swallows the next command, so notes stay on pitch and the noise channel is no longer
  scrambled (Jumping Jack'son's music).
- Volumes in the chip's 2 dB steps (v0.8 had a straight line). The sound is a little louder.
- The noise channel plays at its own rate, and "periodic" noise (the bass in many homebrew
  games) has its own sound instead of hiss.
- Pitch checked against the Mesen emulator, in NTSC and PAL.

### Pads
- CD32 pads are read as in the other community emulators (a longer latch wait and a reader
  tested with KTRL pads): "CD32 Joypad".
- The fourth Joy-Control setting, v0.8's "Standard Joypad" (the same read as Amiga
  JoyStick), is now "KTRL CD32+": a slower read for the KTRL CD32+ and a Mega Multi adapter.
- CD32 buttons: red = button 1, blue = button 2, green = Pause, yellow = Start (Game Gear),
  Play = Pause and Start, either shoulder = back to the menu. On KTRL CD32+ the forward
  shoulder is Pause and Start and only the left shoulder goes back. v0.8 had Play = back to
  the menu and the shoulders as buttons 1 and 2.
- Pause gives one pause per press. v0.8 paused and unpaused on every frame while the pad's
  Pause button was held.
- Player 2's Play and green buttons pause too (v0.8 ignored player 2's Pause).
- The Joy-Control buttons read Port 2 (top: the joystick port, player 1) and Port 1 (the
  mouse port, player 2), the Amiga port each pad is read from.

### Menu and files
- Window, screen and About titles say "AmiMasterGear 1.1" and credit Juan Antonio Gómez
  Gálvez and z00p.
- The Insert and Frozen requesters open in the Cartridges and Frozen drawers beside the
  program when the drawers named in the prefs don't exist.
- A frozen game that can't be saved or loaded now gives a message ("Frozen file not saved!",
  "Frozen file not loaded!"); v0.8 ignored the error.
- PadTest.sms and PadTest.gg, our own pad test cartridges: each box fills while the console
  sees that input held.
