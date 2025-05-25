; draw single pixel on the screen using bios interrupt

org 100h

; store current videomode
mov ah,0fh	; read input mode
int 10h 	; store in al
push ax

; set video mode 13
mov ah, 0 ; video mode function
mov al, 13h ; 320x200, 256 colors
int 10h

; draw pixel
mov ah, 0ch ; func
mov al, 3 ; color (index in palette)
mov bh, 0 ; page 0
mov cx, 160 ; X
mov dx, 100 ; Y
int 10h

; Wait for key press
mov ah,7
int 21h

; CLEAN UP AND EXIT
; clear screen by re-setting video mode 13
mov ah, 0
mov al, 13h
int 10h

; restore video mode
pop ax
mov ah,0
int 10h

int 20h
