; animate single pixel on the screen using bios interrupt

org 100h

; store current videomode
mov ah,0fh	; read input mode
int 10h 	; store in al
push ax

; set video mode 13
mov ah, 0 ; video mode function
mov al, 13h ; 320x200, 256 colors
int 10h

; set up draw pixel
mov ah, 0ch ; func to write pixel
mov bh, 0 ; page 0
; posX
mov cx, 100

; set up loop
; counter
; Y coordinate
mov bx, 0
; color
mov al, 100

loop_start:
; erase old pixel
mov dx, bx
push ax
mov al, 0   ; black
int 10h
pop ax

; move down
inc bx

; draw
mov ah, 0Ch
mov dx, bx
int 10h

; Simple delay loop
mov di, 03FFFh          ; SPEED
anim_delay:
    nop                 ; Do nothing (takes 1 CPU cycle)
    dec di
jnz anim_delay

cmp bx, 199
jl loop_start

; exit
; restore video mode
pop ax
mov ah,0
int 10h

mov ah,7	    ; Wait for key press
int 21h

int 20h
