AmiMasterGear @VERSION@
=================

A Sega Master System and Game Gear emulator for AGA Amigas, in 68020
assembly, by Juan Antonio Gomez Galvez and z00p.

Juan began AmiMasterGear in 1997 and made it freeware. In 2026 he gave
his sources (version 0.8) to the community. This community version,
@VERSION@, is built from them and published with his permission. It is
a PRE-RELEASE: some of the changes have so far been tried only in an
emulator (see "Not yet tried" below).

While a game runs, AmiMasterGear takes over the machine. Esc goes back
to the menu.

No games are included. You need cartridge images (.sms and .gg files)
of your own: copies you may legally have, for example dumps of
cartridges you own, or homebrew games whose authors allow it.


Requirements
------------
- An AGA Amiga (A1200, A4000 or an AGA FPGA core) with AmigaOS 3.0 or
  later. Without a 68020 or AGA the program says "MC68020+ and AGA
  required!".
- A 68020 or better. Tested on an A1200 with a PiStorm and in WinUAE.
  The speed on a 68030 at 50 MHz has not been measured for this
  version yet.
- asl.library (part of AmigaOS).


Installation
------------
Copy the AmiMasterGear drawer anywhere and keep the files together.
The drawer holds:

  AmiMasterGear        the program
  Cartridges           the Insert requester opens here: put your .sms
                       and .gg files in it, or browse to them anywhere.
                       PadTest.sms and PadTest.gg are in it.
  Frozen               Load Frozen and Save Frozen open here
  ReadMe.txt           this text (AmiMasterGear.guide is the same)
  CHANGES.txt          what changed from version 0.8
  NOTICE.txt           credits, licences and trademarks

Save Prefs (Project menu) writes S:AmiMasterGear.prefs. A prefs file
saved by version 0.8 still works, but it keeps 0.8's settings: PAL
screen, Realtime Palette Refresh off. Delete S:AmiMasterGear.prefs to
start from the @VERSION@ defaults, then Save Prefs again.


Playing a game
--------------
Double-click AmiMasterGear. In the menu choose Insert (or Insert
Cartridge in the Cartridges menu), pick a cartridge, then Power ON.
A .sms file runs as a Master System, a .gg file as a Game Gear.

  Esc or Help    back to the menu
  Continue       carries on with the game
  Power ON       starts the cartridge again
  Exit / Quit    leaves the program

The screen is NTSC (60 Hz) by default, as most games and the Game Gear
are. PAL (50 Hz) is the other Screen choice in the menu.


Keyboard
--------
The keyboard always works, whatever the Joy-Control setting.

  Cursor keys              up, down, left, right
  Space or Left Alt        button 1
  Left Shift or Left Amiga button 2
  Del                      Pause (Master System)
  Return                   Start (Game Gear)
  Esc or Help              back to the menu


Joysticks and pads
------------------
Joy-Control in the menu sets how each pad is read. The top button,
Port 2, is the joystick port (player 1); Port 1 is the mouse port
(player 2: Master System only, with JoyStick 2 ON in the Options
menu). Without a prefs file Port 2 is set to Keyboard Only: pick the
type of your joystick or pad, then Save Prefs to keep it.

  Amiga JoyStick   directions, fire = button 1, second fire =
                   button 2. Pause and Start from the keyboard.
  Keyboard Only    the keyboard alone.
  CD32 Joypad      a CD32 pad (a KTRL CD32, or a PlayStation pad on a
                   CD32 adapter):
                     Red       button 1
                     Blue      button 2
                     Green     Pause
                     Yellow    Start (Game Gear)
                     Play      Pause, and Start on the Game Gear
                     Shoulders back to the menu
  KTRL CD32+       the same buttons read in a slower way, for the KTRL
                   CD32+ and a Mega Multi adapter in CD32 mode. Here the
                   right (forward) shoulder is Pause and Start (on a
                   Mega Multi that is the pad's C button: the adapter
                   never sends Start) and only the left shoulder goes
                   back to the menu.

Pause gives one pause per press, as the console's button does.

The pad test: PadTest.sms (Master System) or PadTest.gg (Game Gear), in
the Cartridges drawer. Insert it like a game. Each box fills while the
console sees that input held. The left column is player 1 (port 2),
the right column player 2 (port 1, Master System only). PAUSE lights
for half a second per press and NMIS counts the presses (in hex).
START is Game Gear only. The bottom line on the Master System shows
the raw ports (FF = nothing held).


Battery saves
-------------
Games with battery RAM keep it in a .sav file beside the cartridge,
with the cartridge's name (Game.sms, Game.sav). By default the file is
loaded when the cartridge goes in (Auto-Load Battery), and when you
leave a game whose battery RAM has changed the program asks before it
writes the file (Ask for Save Battery). Load, Save and Clear
RAM-Battery are in the Cartridges menu. Cartridges with two banks of
battery RAM (Shining Force: The Sword of Hajya) keep both: their file is
32 KB, other games' 16 KB.


Frozen games
------------
Save Frozen (Cartridges menu) writes the whole state of the running
game to a .Frozen file; Load Frozen brings it back. The requester opens
in the Frozen drawer. If the file can't be written or read, the program
now says so ("Frozen file not saved!" / "Frozen file not loaded!").


The menu
--------
From version 0.8, unchanged: the Screen, GFX Refresh and SPR Refresh
choices (frame skip), Speed, V.Lines, Country Code, Black Border, the
cheat mode (Do Poke and Find Poke), Save Graphics, and XPK packing for
saves. Realtime Palette Refresh (Options, Video Emulation) is on by
default in @VERSION@: games that change colours partway down the screen
show it (the GG Aleste II title).


Not supported
-------------
- The FM sound unit (YM2413).
- The Master System II's 224-line picture mode: Micro Machines shows
  its race as a first Master System does. It comes in the next version.
- Light gun, paddle, 3-D glasses, the Game Gear link cable.
- Cartridges over 4 MB.


Not yet tried
-------------
These changes have been tried in WinUAE but not yet on a real Amiga:
the new sound chip emulation, Pause from the Del key, battery saves,
frozen games, Black Sea Treasure Hunters, PlayStation pads on a CD32
adapter, and the speed on a 68030/50. Reports are welcome (see below).


Known differences
-----------------
- Micro Machines (Master System): the race picture differs from the
  console's (the 224-line mode, see above).
- Ax Battler (Game Gear): the intro's text sits in a different place.
- Wing Warriors (Master System): its menu differs from other emulators,
  probably because of the region the console reports.
- Sprite collisions in the Master System's own picture mode are still
  reported as version 0.8 did (a flag that changes on each read), not
  from the sprites.
- The Help page still shows version 0.8's CD32 pad buttons; the layout
  above is the one @VERSION@ uses.
- In emulator test runs a game now and then started on a black screen
  (a different game each time, never the first after start-up). Not
  reproduced on demand; cause not yet found. If it happens, please
  report the game and what ran before it.


Credits
-------
- Juan Antonio Gomez Galvez: AmiMasterGear, the program and emulation.
- z00p: the community version @VERSION@.
- Multivac: icons and graphics in Juan's original.
- Afrotechmods / FAmiga: the CD32 pad read.
- Juan's thanks: Zener and Sandman.
- Juan's original was made with Devpac III (HiSoft) and GadToolsBox
  (Jaba Development).


Licence
-------
AmiMasterGear is freeware by Juan Antonio Gomez Galvez. Version
@VERSION@, by z00p, is a community update, made and published with his
permission. The CD32 pad read is under the MIT licence (NOTICE.txt).
It comes with no warranty.

Sega Master System and Game Gear are trademarks of Sega. This project
is not affiliated with or endorsed by Sega. Games are not included;
they are copyright of their owners.


Source and problems
-------------------
The source is at https://github.com/z00p/AmiMasterGear. Please report
problems there (Issues) with the game, the Joy-Control setting, your
machine (CPU or accelerator, or emulator) and what you saw.
