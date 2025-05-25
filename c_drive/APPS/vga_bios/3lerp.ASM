; animate single pixel while lerping color

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
; posY
mov dx, 0

main_loop:
; erase old pixel
push ax
mov al, 0   ; black
int 10h
pop ax

; move down
inc dx

; change color lerp
; Save XY Positions
push cx
push dx
mov ax, dx        ; LERP based on Y position...
mov cx, 15        ; ...in range
mul cx            ; AX * CX -> DX:AX
mov cx, 200       ; range of Y positions
div cx            ; AX / CX -> quotient in AX
add al, 16        ; start color
; Restore positions
pop dx
pop cx

; draw
mov ah, 0Ch
int 10h

; Simple delay loop
mov di, 02FFFh          ; SPEED
anim_delay:
    nop                 ; Do nothing (takes 1 CPU cycle)
    dec di
jnz anim_delay

; Stop when pixel reaches bottom of screen
cmp dx, 199
jl main_loop

; Wait for key press
mov ah,7
int 21h

; EXIT
; restore video mode
pop ax
mov ah,0
int 10h

int 20h ; exit
