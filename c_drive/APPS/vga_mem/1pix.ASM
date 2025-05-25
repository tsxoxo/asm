; draw single pixel using direct memory access

; SETUP
org 100h

; store current videomode
mov ah,0fh	; read input mode
int 10h 	; store in al
push ax

; set video mode 13
mov ah, 0 ; video mode function
mov al, 13h ; 320x200, 256 colors
int 10h

; point es to video memory
mov ax, 0A000h
mov es, ax

; coordinates
mov cx, 160 ; X
mov dx, 100 ; Y

; MAIN
; Plot pixel
; Offset = Y * 320 + X
mov ax, 320
mul dx
add ax, cx
; DI now points to our desired position
mov di, ax
; set color
mov al, 15
; store byte in AL at address ES:DI and increment DI
stosb

; EXIT
; Wait for key press
mov ah,7
int 21h

; clear screen by re-setting video mode 13
mov ah, 0
mov al, 13h
int 10h

; restore video mode
pop ax
mov ah,0
int 10h

int 20h
