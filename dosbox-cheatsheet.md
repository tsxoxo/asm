# DOSBox Cheatsheet for Assembly Programming

## Basic DOSBox Navigation and Commands

| Command | Description | Example |
|---------|-------------|---------|
| `DIR` | List files in current directory | `DIR` or `DIR *.ASM` |
| `CD` | Change directory | `CD ASM` |
| `CD ..` | Go up one directory | `CD ..` |
| `MKDIR` or `MD` | Create a directory | `MKDIR ASM` |
| `COPY` | Copy files | `COPY FILE1.ASM FILE2.ASM` |
| `DEL` | Delete files | `DEL FILE.ASM` |
| `REN` | Rename files | `REN OLD.ASM NEW.ASM` |
| `CLS` | Clear screen | `CLS` |
| `TYPE` | Display text file contents | `TYPE README.TXT` |
| `EDIT` | Open MS-DOS text editor | `EDIT FILE.ASM` |

## Viewing Text Files

1. **TYPE command**: Shows file content (no scrolling)
   ```
   TYPE FILE.ASM
   ```

2. **MORE command**: Display text one screen at a time
   ```
   TYPE FILE.ASM | MORE
   ```

3. **EDIT command**: DOS text editor - much more user-friendly
   ```
   EDIT FILE.ASM
   ```
   Navigation in EDIT:
   - F1: Help
   - F2: Save
   - F10: Menu
   - Alt+F: File menu
   - Alt+X: Exit

## Running FASM in DOSBox

1. **Start DPMI server**:
   ```
   HDPMI32
   ```
   or
   ```
   CWSDPMI -p -s-
   ```

2. **Assemble a program**:
   ```
   FASM HELLO.ASM HELLO.COM
   ```

3. **Run your program**:
   ```
   HELLO
   ```

## DOSBox File Management

1. **Mounting drives** (usually in autoexec section of config):
   ```
   MOUNT C ~/dosdrive
   C:
   ```

2. **Copying files between host and DOSBox**:
   - Place files in your mounted folder on host OS
   - They'll appear in DOSBox

## Debugging Assembly Programs

1. **DEBUG command**: Built-in debugger
   ```
   DEBUG HELLO.COM
   ```
   Common DEBUG commands:
   - `D`: Display memory
   - `U`: Unassemble (view code)
   - `T`: Trace (step execution)
   - `G`: Go (run)
   - `Q`: Quit

2. **FASM error messages** typically show:
   - Line number
   - Error type
   - Brief description

## DOSBox Shortcuts

| Shortcut | Function |
|----------|----------|
| Ctrl+F1 | Toggle key mapper |
| Alt+Enter | Toggle fullscreen |
| Ctrl+F4 | Swap mounted disk image |
| Ctrl+F5 | Save screenshot |
| Ctrl+F9 | Exit DOSBox |
| Ctrl+F10 | Capture/release mouse |
| Ctrl+F11 | Slow down emulation |
| Ctrl+F12 | Speed up emulation |

## Useful Tips for Assembly Programming in DOSBox

1. **Create a batch file** for your build process:
   ```
   ECHO OFF
   HDPMI32 >NUL
   FASM %1.ASM %1.COM
   IF ERRORLEVEL 1 GOTO ERROR
   ECHO Build successful
   GOTO END
   :ERROR
   ECHO Build failed!
   :END
   ```
   Save as `ASM.BAT` and use: `ASM HELLO`

2. **Use DOS wildcards** for file operations:
   - `*` matches any characters
   - `?` matches a single character
   - Example: `DEL *.BAK`

3. **Memory examination** for debugging:
   ```
   DEBUG
   D 100   (Display memory at offset 100h)
   ```