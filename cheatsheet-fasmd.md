# FASMD Keyboard Shortcuts - The Insider's Guide

## Core Navigation & Editing

```
F1        - Help screen (your best friend)
F2        - Save file
F10       - Menu access
Esc       - Cancel/exit dialog
Tab       - Smart indent
Shift+Tab - Unindent
Ctrl+Y    - Delete line
Ctrl+K    - Delete to end of line
Alt+F     - File menu
Alt+E     - Edit menu
Ctrl+BS   - Delete word left
```

From the official FASM guides: http://flatassembler.net/docs.php?article=manual

## Advanced Editing

```
Ctrl+F    - Find text
F3        - Find next
Ctrl+R    - Replace
Ctrl+G    - Go to line
Alt+0-9   - Set bookmark
Ctrl+0-9  - Go to bookmark
Alt+L     - Toggle line numbers
Ctrl+KK   - Block select start
Ctrl+KB   - Block select end
```

Documented in the FASM boards: http://board.flatassembler.net/topic.php?t=3801

## Power User Commands

```
Ctrl+F9   - Compile (most important!)
Alt+X     - Exit editor 
Ctrl+KS   - Save (WordStar compatible)
Ctrl+U    - Undo
Ctrl+QF   - Find/replace with options
Ctrl+O+C  - Center line
```

Verified on OS-specific threads: http://board.flatassembler.net/topic.php?t=11517

## Colorization & Display

```
Alt+C     - Customize colors
Alt+W     - Toggle word wrap
Alt+T     - Toggle syntax highlighting
Ctrl+P    - Print (if you've got a DOS printer!)
```

Deep FASM culture trivia - the highlighting scheme was inspired by Chris Dragan's early 90s editor work.

Source: http://fresh.flatassembler.net/docs/docs.rar (buried in CONFIG.SYS)

## Workflow Insights

The FASM community generally uses a split-screen approach when coding in DOS:
1. Edit with FASMD in the top half
2. Compile with F2, Ctrl+F9
3. Test run in bottom window
4. Rinse and repeat

This workflow is detailed in Tomasz Grysztar's original FASM guides (which are surprisingly hard to find these days outside of the FASM package itself).

The keyboard layout in FASMD borrows heavily from Brief and early Borland tools - many old-school hackers still have these keys in muscle memory.