AmiMasterGear @VERSION@
=================

A Sega Master System and Game Gear emulator for AGA Amigas and
Picasso96 graphics boards, in 68020 assembly, by Juan Antonio Gomez
Galvez and z00p.

Juan began AmiMasterGear in 1997 and made it freeware. In 2026 he gave
his sources (version 0.8) to the community. This community version,
@VERSION@, is built from them and published with his permission.

Version @VERSION@, 28 November 2026. New in 2.0: the RTG program, which
shows the game on a Picasso96 screen (PiStorm), with a big 1080p menu,
scanlines and double buffering. The AGA program plays as 1.3 did.

Two programs, one drawer:

  AGA    Juan's AGA display, as in 1.x. Any AGA Amiga with a 68020
         or better; a 68030/50 is enough.
  RTG    the game on a Picasso96 screen, with the big menu. PiStorm-
         class machines with Picasso96 (see "The RTG program").

Upgrading from 1.x: the old program is called AmiMasterGear. Unpacking
2.0 over it leaves it in the drawer; delete it (and its icon) or keep
it. Shell scripts that start AmiMasterGear need the new names.

While a game runs, AmiMasterGear takes over the machine (both programs).
Esc goes back to the menu.

No games are included. You need cartridge images (.sms and .gg files)
of your own: copies you may legally have, for example dumps of
cartridges you own, or homebrew games whose authors allow it.


Requirements
------------
- An AGA Amiga (A1200, A4000 or an AGA FPGA core) with AmigaOS 3.0 or
  later. Without a 68020 or AGA the program says "MC68020+ and AGA
  required!".
- A 68020 or better. Tested on an A1200 with a PiStorm and in WinUAE.
  A 68030/50 runs every game we measured at full speed, NTSC and PAL,
  with room to spare (Micro Machines, the slowest: 128% of full speed
  on NTSC, 156% on PAL). Measured in WinUAE set up to match a real
  Blizzard 030/50, not on a real 030.
- asl.library (part of AmigaOS).
- The RTG program: a PiStorm-class accelerator with Picasso96 and a
  16-bit screen mode. Tested on an A1200 with a
  PiStorm (Emu68) on HDMI, and in WinUAE (uaegfx). Without a usable
  Picasso96 mode it runs as the AGA program.


Installation
------------
Copy the AmiMasterGear drawer anywhere and keep the files together.
The drawer holds:

  AGA                  the AGA program
  RTG                  the RTG program
  AmiMasterGear.config the RTG program's settings (see "The RTG
                       program"); the big menu writes to it
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
Double-click AGA or RTG. In the menu choose Insert (or Insert
Cartridge in the Cartridges menu), pick a cartridge, then Power ON.
A .sms file runs as a Master System, a .gg file as a Game Gear.

  Esc or Help    back to the menu
  Continue       carries on with the game
  Power ON       starts the cartridge again
  Exit / Quit    leaves the program

The screen is NTSC (60 Hz) by default, as most games and the Game Gear
are. PAL (50 Hz) is the other Screen choice in the menu.

Games that switch to the taller 224-line picture of the Master System
II and Game Gear (Micro Machines, Micro Machines 2) get it: the picture
grows upwards, its bottom edge stays where the usual 192 lines end.


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
(player 2, Master System only). A CD32 pad in Port 1: set Port 1 to
CD32 Joypad (or KTRL CD32+) and player 2 is on. A joystick in Port 1:
set it to Amiga JoyStick and tick JoyStick 2 ON in the Options menu.
Without a prefs file Port 2 is set to CD32 Joypad. With a
joystick, pick Amiga JoyStick (on CD32 Joypad a plain joystick moves
but does not fire), then Save Prefs to keep it.

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
show it (the GG Aleste II title). Sprites Priorities (Options, Video
Emulation) is on by default from 1.2: where sprites overlap, the one the
console shows wins, so the cars and boats in Micro Machines have their
colours. Turning it off draws a little faster but mixes the colours of
overlapping sprites. Background Priorities (same menu) is on by default
from 1.2 too: background marked "in front" covers the sprites, as on the
console (Defenders of Oasis' dialogue boxes). Upgrading: prefs saved by
0.8 or 1.1 get both options switched on when loaded (the rest is kept);
Save Prefs keeps them. Prefs saved by 1.2 keep your choice.


The RTG program
---------------
RTG draws the game itself onto a 16-bit Picasso96 screen and leaves
the scaling to the display, so every console pixel is the same size.
It plays the same games as AGA, with the same menu, keys, pads, saves
and prefs (S:AmiMasterGear.prefs is shared). The game's speed comes
from the Amiga's timer, at the console's own rate (59.92 Hz NTSC,
49.70 Hz PAL), never from the display.

The menu: 1920x1080 when the graphics board has that mode, else
1280x720: Juan's menu drawn large, in a pixel font, with the logo and
the pad pictures redrawn. Without either mode it opens at 640x270 or
640x256 ("Menu = Classic" in the config asks for that one). The big
menu has two more controls in Screen Options: Scanlines (Off / On) and
Style. Changing them writes AmiMasterGear.config at once; Save Prefs
works as before for everything else.

The display's refresh rate: on a PiStorm the HDMI output mode (50 or
60 Hz) is set at boot in Emu68's config.txt, not by the program. A
game at a different rate from the display has frames dropped (NTSC on
50 Hz: one in six) or shown twice (PAL on 60 Hz). 60 Hz output suits
NTSC games and is the one to pick with Buffering = Double (see Known
differences).

Settings: in AmiMasterGear.config in the program's drawer (plain text,
"Key = Value" a line, any case; a missing line means the default), or
as ToolTypes in the RTG icon, which win over the file for that icon.

  Config line        ToolType        Values (default first)
  Screen             RTGSCREEN=      Sharp, Bigger
  Scanlines          SCANLINES=      Off, On
  ScanlineStyle      SCANLINESTYLE=  50, 25, 75, blendlight, blend,
                                     blendstrong
  Buffering          BUFFERING=      Double, Single
  Menu               -               Classic (no line: the big menu)

Screen: Sharp opens 960x540, exactly half of 1080p, with the Master
System at 2x and the Game Gear at 3x, so a 1080p display shows square
pixels. Bigger opens the mode the picture fills best and lets the
graphics board scale it: more of the display filled, a little softer.

Scanlines: the same seven settings as Arnold (Amstrad CPC emulator):
Off, Hard 25%, Hard 50%, Hard 75%, Blended light, Blended, Blended
strong. Hard darkens the lower half of each game line's screen rows by
25, 50 or 75%; Blended mixes the line with the one below first (softer).
The style is kept while Scanlines is Off. They show when the picture is
drawn at 2x or more (Sharp; Game Gear also in Bigger). Hard costs 2-5%
of a frame, Blended 7-11% (measured in WinUAE). "Scanlines = blend" (one
of the style words) also works, as in Arnold: On in that style.

Buffering: Double draws each frame out of sight and shows it in the
display's vertical blank, so fast scrolling does not tear. Single draws
straight to the screen: no missed blanks, but a tear can show in fast
movement.


Not supported
-------------
- The FM sound unit (YM2413).
- The 240-line picture of the PAL Master System II (no game we tested
  uses it).
- Light gun, paddle, 3-D glasses, the Game Gear link cable.
- Cartridges over 4 MB.
- The RTG program: no screen surround, LCD blend or AHI sound yet.


Tried on real hardware
----------------------
On an A1200 with a PiStorm, AGA screen, sound from Paula: the 224-line
picture (Micro Machines on the Master System and Game Gear, Micro
Machines 2 on the Game Gear, NTSC and PAL), the sprite colours and the
background priority (Micro Machines, Defenders of Oasis, Sonic, Shinobi,
Wonder Boy III), Alex Kidd, Columns, GG Aleste II, the Help page, Pause
from the Del key, battery saves (Shining Force, Defenders of Oasis),
frozen games, Black Sea Treasure Hunters, CD32 pads in both ports (a
KTRL CD32 and a PlayStation pad on a CD32 adapter, with PadTest), the
drums in Jumping Jack'son, and prefs from 1.1 getting both priority
options switched on. Not tried on hardware: the Port 2 default without
a prefs file (WinUAE only). 1.3: Jumping Jack'son's bass recorded by
line-in from the A1200 with the noise fix, and the 1.3 candidate run
there. The long-name fix was tested in WinUAE (a second Insert after a
69-character name).
No real 68030 was to hand: its speed is the WinUAE measurement only.
2.0, the RTG program, on an A1200 with a PiStorm (Emu68), HDMI 1080p60:
Micro Machines NTSC and PAL with Buffering = Double (no tearing), Sonic
with Scanlines On, Hard 50%, the big menu, and the scanline settings
kept in the config. At 1080p50: the frame timing logged with Single
and with Double (Micro Machines).


Known differences
-----------------
- Sprite collisions in the Master System's own picture mode are still
  reported as version 0.8 did (a flag that changes on each read), not
  from the sprites.
- An occasional one-frame black flicker during play, seen on an A1200
  (Micro Machines). Cause not yet found.
- A thin line can show at the left edge of the picture on bright screens
  on real AGA (also in 1.1).
- RTG, Buffering = Double with the display at 50 Hz: about 4% of frames
  miss the display's blank and show a frame late, a small judder. At
  60 Hz it is clean. Workaround: Buffering = Single, or 60 Hz output.
- RTG: the TMS9918 picture modes (Black Sea Treasure Hunters) are not
  drawn yet and show black. The AGA program draws them.


Credits
-------
- Juan Antonio Gomez Galvez: AmiMasterGear, the program and emulation.
- z00p: the community version @VERSION@, the RTG program and big menu
  (pixel font and menu kit).
- Multivac: icons and graphics in Juan's original.
- Afrotechmods / FAmiga: the CD32 pad read.
- Juan's thanks: Zener and Sandman.
- Juan's original was made with Devpac III (HiSoft) and GadToolsBox
  (Jaba Development).


Licence
-------
AmiMasterGear is freeware by Juan Antonio Gomez Galvez. Version
@VERSION@, by z00p, is a community update, made and published with his
permission. The CD32 pad read and the menu kit are under the MIT
licence (NOTICE.txt).
It comes with no warranty.

Sega Master System and Game Gear are trademarks of Sega. This project
is not affiliated with or endorsed by Sega. Games are not included;
they are copyright of their owners.


Source and problems
-------------------
The source is at https://github.com/z00p/AmiMasterGear. Please report
problems there (Issues) with the game, the Joy-Control setting, your
machine (CPU or accelerator, or emulator) and what you saw.
