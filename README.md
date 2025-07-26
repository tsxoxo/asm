# Getting Started with DOS Assembly on macOS

A collection of setup tips, workflows and resources. 

Basically, just me documenting how I approached this in 2025 trying to play with assembly on an Intel Mac (2017 Macbook Air) using Dosbox-x and FASM.

This information was collected from various sources. Credits go to all the people who shared their knowledge, see [Resources](#resources) section below. Also, thanks Claude.

## Highlights

[6LERP.webm](https://github.com/user-attachments/assets/eb8c31b2-558f-4b3b-a9d7-1aa0021684d0)

*A very big (over 1KB), very naively implemented starfield-inspired demo. `/APPS/VGA_MEM/6LERP`*

---

[6SZ_LERP.webm](https://github.com/user-attachments/assets/8962cd1d-90df-46f6-8596-dbc01ab2ad6c)

*An attempt to cut the above demo down to size. Result: ~350kb. `/APPS/VGA_MEM/6SZ_LERP`* 

## Resources

I stitched together the DOSbox config using tips from these sources:

- [ Philip Bohun's Youtube asm guide ](https://www.youtube.com/watch?v=HcLA6F5UTIE&list=PLSiFUSQSRYANu14mkQADmVMYPcssk_IqP&index=1)
- [ Hans-Joachim Rudolph's guide from the FASM forum ](https://board.flatassembler.net/topic.php?t=22910)
- [ The official Dosbox-x wiki ](https://dosbox-x.com/wiki/#Home)
- Other resources I'm almost certainly forgetting

## Setup Instructions

- Download [dosbox-x](https://dosbox-x.com/)
- Create project directory: `mkdir asm/`
- Create dir to serve as `C:` drive within DosBox: `mkdir asm/c_drive`
- Create a config file for DosBox: `touch asm/dosbox-x.conf`
- If You want DPMI, download a server like japheth's [here](https://www.japheth.de/HX.html)

For the last step, copy all or part of the `dosbox-x.conf` file from this repo into your own config.

### LSP

- in NeoVim, "asm-lsp" does a decent job for me.

NB: For some reason, the LSP works better in files with a capitalized `.ASM` extension.

### Compile cycle

_Work in progress_

- Edit `foo.asm` in editor of choise on your host OS (outside of DOSBox)
- In `foo.asm`, make sure the program exits on a key press
- In DOSBox, run `watch foo`
- After making an edit, switch to DOSBox window and press a key
- `watch` will recompile `foo.asm` and run `foo.com`

This is slightly easier than manually:

- Switching to DOSBox after making an edit
- Pressing a key to exit the program
- Running `fasm foo.asm`
- Running `foo.com`

## DosBox-X

- (MacOS) Path to default config file with useful comments: "${HOME}/Library/Preferences/DOSBox-X 2025.02.01 Preferences"

## Keys

- More info can be found in this repo in files with the `cheatsheet-` prefix (these are copied answers from Claude.ai)

## IDE

_Keys for editing, debugging, compiling, etc._

### DEBUG
(The 'DEBUG' program that comes with dosbox-x)

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

## TODO

- setup cheatsheets: helppc with ralf brown's interrupt list, as suggested [here](https://board.flatassembler.net/topic.php?t=22910)
