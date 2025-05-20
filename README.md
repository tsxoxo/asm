# Stuff that was helpful

For writing assembler on an intel Mac (2017 Macbook Air).

## Setup Instructions

- Download [dosbox-x](https://dosbox-x.com/)
- Create project directory: `mkdir asm/`
- Create dir to serve as `C:` drive within DosBox: `mkdir asm/c_drive`
- Create a config file for DosBox: `touch asm/dosbox-x.conf`
- If You want DPMI, download a server like japheth's [here](https://www.japheth.de/HX.html)

The rest of the setup I have put in the conf file for convenience.
I switched together the config based on tips found here:

- [ Philip Bohun's Youtube asm guide ](https://www.youtube.com/watch?v=HcLA6F5UTIE&list=PLSiFUSQSRYANu14mkQADmVMYPcssk_IqP&index=1)
- [ Hans-Joachim Rudolph's guide from the FASM forum ](https://board.flatassembler.net/topic.php?t=22910)
- [ The official Dosbox-x wiki ](https://dosbox-x.com/wiki/#Home)
- Other resources I'm almost certainly forgetting

## DosBox-X

- (MacOS) Path to default config file with useful comments: "${HOME}/Library/Preferences/DOSBox-X 2025.02.01 Preferences"

## Keys

- More info can be found in this repo in files with the `cheatsheet-` prefix

## IDE

_Keys for editing, debugging, compiling, etc._

### DEBUG

**d** -

### FASMD

**F2** - Save file
**Ctrl + F9** - Compile
**F9** - Compile and run
**F4** - Show file explorer
**Alt + F5** - Show user screen
**F1** - Show help menu
**Alt + 0..9** - Switch to file 0..9
**Ctrl + Tab** - Go to next file (exits the program if there isn't one)

### Copy and paste in DOSBox

Official docs: [Clipboard Support in DOSBox-X](https://dosbox-x.com/wiki/Guide%3AClipboard-support-in-DOSBox%E2%80%90X)

Using the mouse didn't work for me so I set it up via keyboard:

- Check the following option in the menu: `Main -> Shared clipboard functions -> Via arrow keys`

- Then use arrow keys to move. If that doesn't work, hold shift
- Start selection: `fn + shift + <left>`
- Copy selection: `fn + shift + <right>`
- Cancel: `esc`

## ASCII art

This is the BIOS Data Area (BDA) - a goldmine for ASCII art programming! It contains:

0040:0004-0005: Initial video mode (80×25 text indicated by values)
0040:0049: Current video mode (should be 3 for color text)
0040:004A-004B: Number of screen columns (80, or 50h)
0040:0050-0051: Cursor position for each page
0040:0060: Cursor shape information
0040:0063: Active display page

## TODO

### Workflow

- setup a 2-pane or 2-window: one for code one for execution:use volkov, norton commander or dos navigator
- use a watch script
- setup cheatsheets: helppc with ralf brown's interrupt list, as suggested [here](https://board.flatassembler.net/topic.php?t=22910)
