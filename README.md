# Stuff that was helpful

For writing assembler on an intel Mac (2017 Macbook Air) using Dosbox-x and FASM.

These information have been compiled/collected from various sources. Credits go to all the people who made the guides listed under `Resources`. Also, thanks Claude.

## Setup Instructions

- Download [dosbox-x](https://dosbox-x.com/)
- Create project directory: `mkdir asm/`
- Create dir to serve as `C:` drive within DosBox: `mkdir asm/c_drive`
- Create a config file for DosBox: `touch asm/dosbox-x.conf`
- If You want DPMI, download a server like japheth's [here](https://www.japheth.de/HX.html)

For the last step, copy the contents (or part of them) from the file `dosbox-x.conf` in this repo into your config.

### LSP

- in NeoVim, "asm-lsp" does a decent job for me.

NB: For some reason, this works better in files with CAPITALIZED extension `.ASM`

### Compile cycle

_Work in progress_

- Edit in Neovim on native OS (outside of dosbox)
- In `foo.asm`, set up exit on a keyboard input
- In dosbox, run `watch foo`
- After making an edit in nvim, switch to dosbox window and press a key
- watcher tries to recompile `foo.asm` and run `foo.com`

This is slightly easier than

- ... switch to doxbox window
- hit key to terminate program
- `fasm foo.asm`
- `foo.com`

(You could of course run a build script by hand)

## Resources

I stitched together the config based on tips found here:

- [ Philip Bohun's Youtube asm guide ](https://www.youtube.com/watch?v=HcLA6F5UTIE&list=PLSiFUSQSRYANu14mkQADmVMYPcssk_IqP&index=1)
- [ Hans-Joachim Rudolph's guide from the FASM forum ](https://board.flatassembler.net/topic.php?t=22910)
- [ The official Dosbox-x wiki ](https://dosbox-x.com/wiki/#Home)
- Other resources I'm almost certainly forgetting

## DosBox-X

- (MacOS) Path to default config file with useful comments: "${HOME}/Library/Preferences/DOSBox-X 2025.02.01 Preferences"

## Keys

- More info can be found in this repo in files with the `cheatsheet-` prefix (these are copied answers from Claude.ai)

## IDE

_Keys for editing, debugging, compiling, etc._

### DEBUG

- **t** - [t]race (step execution)
- **g** - [g]o! Run program
- **g 102** - Run program until instruction at offset 102 (i.e. IP === 102)
- **d hhhh** - [d]ump memory at given offset using the default segment.
- **p** - Show [p]rocessor state
- **q** - [q]uit

- **a 100** - start [a]ssembly mode at offset 100: enter instructions in human readable format. E.g. `mov ah,02`
- **u 100** - [u]nassemble data starting from offset 100: show stored instructions in human readable format.
- **d hhhh:hhhh** - dump memory at exact segment:offset. Example: `d b800:0000` can show the screen buffer in default graphics mode.
- **r ax** - Create prompt to enter value and move it into [r]egister ax
- **e 100** - Create prompt to [e]nter bytes, starting at offset 100. Leave empty and press enter to exit this mode.
- **h 1 f** - compares two [h]ex numbers. Shows sum and difference. Limited to 2 bytes, rest will be cut. -1 = FFFFh.

### FASMD

- **F2** - Save file
- **Ctrl + F9** - Compile
- **F9** - Compile and run
- **F4** - Show file explorer
- **Alt + F5** - Show user screen
- **F1** - Show help menu
- **Alt + 0..9** - Switch to file 0..9
- **Ctrl + Tab** - Go to next file (exits the program if there isn't one)

### Copy and paste in DOSBox

Official docs: [Clipboard Support in DOSBox-X](https://dosbox-x.com/wiki/Guide%3AClipboard-support-in-DOSBox%E2%80%90X)

Using the mouse didn't work for me so I set it up via keyboard:

- Check the following option in the menu: `Main -> Shared clipboard functions -> Via arrow keys`

- Then use arrow keys to move. If that doesn't work, hold shift
- Start selection: `fn + shift + <left>`
- Copy selection: `fn + shift + <right>`
- Cancel: `esc`

## ASM instructions

**mov ax,<value>** - overwrites ax with value of register/constant/memory address
**add <value>** - adds value to ax

## DOS instructions

- [ List 1, old ](https://www.ctyme.com/intr/int-21.htm)
- [ List 2, wiki ](https://en.wikipedia.org/wiki/DOS_API#DOS_INT_21h_services)

### Interrupts

**20** - exit
**21** - prints char. Set ah to 02h (specifies the function). Set DL to the ASCII code.

## ASCII art

### Chars

_ascii hex codes_

**☻** - 02

This is the BIOS Data Area (BDA) - a goldmine for ASCII art programming! It contains:

- 0040:0004-0005: Initial video mode (80×25 text indicated by values)
- 0040:0049: Current video mode (should be 3 for color text)
- 0040:004A-004B: Number of screen columns (80, or 50h)
- 0040:0050-0051: Cursor position for each page
- 0040:0060: Cursor shape information
- 0040:0063: Active display page

## TODO

### Workflow

- setup a 2-pane or 2-window: one for code one for execution:use volkov, norton commander or dos navigator
- use a watch script
- setup cheatsheets: helppc with ralf brown's interrupt list, as suggested [here](https://board.flatassembler.net/topic.php?t=22910)
