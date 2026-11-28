# Changes from Juan's v0.8

AmiMasterGear 2.0 is built from the sources of AmiMasterGear v0.8 (12 December 1999) by Juan
Antonio Gómez Gálvez. This file lists what changed for the user, grouped. Every change sits
behind its own assembler switch (`AMG_` names in `src/Amg10.asm`); without them the source
builds Juan's v0.8 byte for byte.

## 2.0 (28 November 2026)

Two programs: **AGA** (the 1.3 program, titles saying 2.0: `AMG_V20`) and **RTG**, new. The old
single program was called AmiMasterGear.

### The RTG program
- The game on a 16-bit Picasso96 screen, for PiStorm-class machines (`AMG_RTG`, `src/AmgRtg.asm`).
  The program draws the Master System's picture mode line by line as the emulated beam leaves
  each line, from the video RAM, registers and palette as they are then, so mid-frame changes
  show where the game makes them; only lines that changed since the last frame are copied. None
  of the AGA drawing runs.
- Speed from a CIA-B timer at the console's rate (59.92 Hz NTSC, 49.70 Hz PAL), never from the
  display's refresh. Frame skip as in the AGA program.
- Screen: Sharp (default) opens 960x540, exactly half of 1080p, with the Master System at 2x and
  the Game Gear at 3x (`AMG_RTGHALF`); Bigger opens the mode the picture fills best and leaves
  the rest to the graphics board's scaler.
- Scanlines (`AMG_RTGSCAN`): the seven settings of Arnold, in its order and words: Off, Hard
  25%, Hard 50%, Hard 75%, Blended light, Blended, Blended strong. Hard darkens the lower half of
  each game line's rows; Blended averages the line with the next one, then darkens (rounded
  down, as Arnold). Hard costs 2-5% of a frame, Blended 7-11% (WinUAE).
- Buffering (`AMG_RTGDBUF`, `AMG_DBUFDEF`): Double, the default, draws each frame to a hidden
  page and shows it with a pan timed 5 ms before the display's next vertical blank (its period
  and phase measured at open; every pan's return re-anchors it). Single draws straight to the
  screen.
- Settings in `AmiMasterGear.config` in the program's drawer (`Screen`, `Scanlines`,
  `ScanlineStyle`, `Buffering`, `Menu`), or the RTG icon's ToolTypes `RTGSCREEN=`,
  `SCANLINES=`, `SCANLINESTYLE=`, `BUFFERING=`, which win (`AMG_RTGCFG`, `src/AmgRtgCfg.asm`).
  A sample config is in the drawer.
- Without a usable Picasso96 mode the program runs as the AGA program.

### Big menu
- The menu opens at 1920x1080 (else 1280x720) on the graphics board (`AMG_BIGMENU`,
  `src/AmgMenu.asm`): Juan's GadTools menu scaled at open time, drawn in a pixel font at the
  screen's own size, with the logo and the pad pictures redrawn, and the selectors trimmed to
  the text's height. Without those modes: 640x270, else 640x256 (`AMG_RTGMENU`); `Menu = Classic`
  in the config asks for that one.
- Screen Options has Scanlines (Off / On) and Style (an OS 3.2 chooser pop-up, else a cycle
  gadget). A change is written to the config at once (other lines in the file are kept).

### Also in the RTG program
- Everything from 1.3 (`AMG_NOISESTOP`, `AMG_NAMECAP`).

### Checked
- On an A1200 with a PiStorm (Emu68), HDMI 1080p60: Micro Machines NTSC and PAL with Double (no
  tearing), Sonic with Scanlines On, Hard 50%, the big menu, the scanline settings kept in the
  config. At 1080p50: the frame timing logged in Micro Machines with Single and with Double.
- In WinUAE (uaegfx): every scanline setting matched a model of the maths pixel for pixel (56
  pictures); both release programs started from their icons to the menu (RTG: the big menu);
  the RTG program's release switches in a test build ran Sonic the Hedgehog on the Master
  System and the Game Gear, with Single and Double.
- `sh build.sh rel` still builds 1.3 byte for byte, `rel12` 1.2; the AGA program differs from 1.3
  only in its version texts (13 bytes).

### Known differences (RTG)
- Double with the display at 50 Hz: about 4% of frames miss the blank and show a frame late (a
  small judder). At 60 Hz it is clean. Workaround: Single, or 60 Hz output.
- The TMS9918 picture modes (Black Sea Treasure Hunters) are not drawn yet: black.

## 1.3 (27 November 2026)

### Sound
- The noise channel now restarts cleanly on a real Amiga when a game switches it between white
  noise (drums) and periodic noise (bass) (`AMG_NOISESTOP`). Paula only stops a channel at the
  end of the word it is playing, at the period it holds then. 1.2 set the new, much slower bass
  period before the stop, so the stop often came too late and the old white noise played on at
  the bass pitch: Jumping Jack'son's bass sounded rough and buzzy on the A1200. Now the channel
  is only restarted after Paula has really stopped: the fastest period goes in before the stop,
  the new one just before the restart, and the wait is the old period plus two lines (no longer
  capped at 40 lines; only on a white/periodic change). Heard on a real A1200. WinUAE stops a
  channel at once, so there it sounds as 1.2 did.

### Menu and files
- Picking a cartridge whose file name is 65 characters or longer no longer corrupts the
  program (`AMG_NAMECAP`). Juan's BuscaExt copied the end of the name into a 72-byte buffer
  with no limit, so a long name wrote over the code behind it: the next Insert crashed
  (80000004 on the A1200) or hung. The bug dates from the original 0.8. Only the last 64
  characters are looked at now (the extension is all it needs); the hook takes the same 14
  bytes as before, so nothing in Juan's code moves. The same fix as AmiGameBoy 2.5.1.
- Titles say "AmiMasterGear 1.3" (`AMG_V13`).

### Checked
- On an A1200 with a PiStorm (AGA, Paula): Jumping Jack'son's bass recorded by line-in with the
  noise fix, and the 1.3 candidate run.
- In WinUAE: two cartridges in one session, the first with a 69-character name. 1.2 never
  loaded the second; 1.3 ran both. Noise recorded from 1.2 and 1.3 in five Master System games
  (Jumping Jack'son, Sonic the Hedgehog, Streets of Rage, R-Type, Power Strike II): overall
  level within 0.05 dB in every band, no more different than two takes of 1.2.
- `sh build.sh rel12` still builds the 1.2 release byte for byte.

## 1.2 (25 November 2026)

### Picture
- The Master System II and Game Gear's 224-line picture (Mode 4 with M1 and M2 set) is shown:
  224 lines, the name table at $x700 with 32 rows, the vertical scroll wrapping at 256, sprites
  down to line 224 with no $D0 end marker, and the frame interrupt after line 224. Micro
  Machines (Master System and Game Gear) and Micro Machines 2 (Game Gear) race in it; in 1.1
  their track wrapped. The tall picture starts 32 lines higher on the Amiga screen, so its
  bottom edge, and every 192-line game, stay where they were. PAL and NTSC.
- Overlapping sprites are drawn as the console draws them: where two overlap, the one earlier
  in the sprite table shows. v0.8 and 1.1 mixed the two sprites' colour numbers, so the cars
  and boats in Micro Machines (Master System and Game Gear) came out grey; they now have their
  colours. This is v0.8's own "Sprites Priorities" (Options,
  Video Emulation), now on by default.
- Background tiles marked "in front of sprites" now cover the sprites, as on the console:
  Defenders of Oasis' dialogue boxes no longer have townspeople or pictures drawn over their
  text, and its title menu's highlighted line is readable. This is v0.8's own "Background
  Priorities" (Options, Video Emulation), now on by default.
- A prefs file saved by 0.8 or 1.1 gets both priority options switched on when it is loaded;
  everything else in it is kept. 1.2 marks the files it saves (in bytes 0.8 and 1.1 leave
  alone, so they still load them), and a 1.2 file keeps the user's choice, off included.

### Pads and keyboard
- Without a prefs file Port 2 starts on CD32 Joypad (1.1: Keyboard Only). Saved prefs still
  win; the keyboard works in every mode.
- Del gives one Pause per press. 1.1 gave two, whatever the Joy-Control setting: the game
  paused and carried straight on.
- Player 2: setting Joy-Control's Port 1 to CD32 Joypad or KTRL CD32+ turns player 2 on (Master
  System). In 1.1 port 1 was read only with "JoyStick 2 ON" ticked in the Options menu, so a
  CD32 pad in port 1 did nothing. With Amiga JoyStick or Keyboard Only on port 1, "JoyStick 2
  ON" is still needed (the mouse lives in port 1).

### Sound
- Periodic noise (the kick drum and bass in many homebrew games, such as Jumping Jack'son) is
  about 5.5 dB louder, back in balance with the tunes and the white noise as on the console
  (fully from the chip's third volume step down; the two loudest steps as far as Paula allows).

### Menu
- The Help page shows the CD32 buttons as they are since 1.1 (red = 1, blue = 2, green =
  Pause, yellow = Start, Play = Pause and Start, shoulders = back to the menu; KTRL CD32+:
  forward = Pause and Start, reverse = back to the menu) and the keyboard's buttons.
- Titles say "AmiMasterGear 1.2".

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
