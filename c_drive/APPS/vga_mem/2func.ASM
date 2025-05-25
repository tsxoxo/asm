; draw a bunch of pixels
; concepts introduced:
; * functions

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

jmp main

plot_pixel:
  ; Takes args:   * CX=X position
  ;               * DX=Y position
  ;               * BL=color

  ; save whatever is in AX
  push ax
  push cx
  push dx
  ; Offset = Y * 320 + X
  mov ax, 320
  mul dx
  add ax, cx
  ; DI now points to XY
  mov di, ax
  ; store byte in AL at address ES:DI and increment DI
  mov al, bl
  stosb
  pop dx
  pop cx
  pop ax
ret

main:
  ; draw a diagonal
  ; start
  mov cx, 0 ; X
  mov dx, 0 ; Y
  ; color
  mov bl, 64

  draw_line:
    call plot_pixel
    inc cx
    inc dx
    cmp cx, 319
    jg exit
    cmp dx, 200
    jg exit
  jmp draw_line

; EXIT
exit:
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
