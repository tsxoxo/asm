; draw a bunch of pixels using arrays

org 100h
jmp main

setup:
  ; store current videomode
  mov ah,0fh	; read input mode
  int 10h 	; store in al
  mov [og_video_mode], al

  ; set video mode 13
  mov ah, 0 ; video mode function
  mov al, 13h ; 320x200, 256 colors
  int 10h

  ; point es to video memory
  mov ax, 0A000h
  mov es, ax
ret

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

cls:
  ; Wait for key press
  mov ah,7
  int 21h

  ; clear screen by re-setting video mode 13
  mov ah, 0
  mov al, 13h
  int 10h

  ; restore video mode
  mov al, [og_video_mode]
  mov ah, 0
  int 10h
ret

main:
  call setup


  ; Accessing array elements:
  mov cx,star_count
  ; array index
  mov si, 0

  draw_array:
    push cx
    mov cl, [star_x + si]             ; []: memory reference, gets star_x[2] = 120
    xor ch, ch
    mov dl, [star_y + si]             ; AH gets star_y[2] = 80
    xor dh, dh
    ; color
    mov bl, [colors + si]
    call plot_pixel
    inc si
    pop cx
  loop draw_array

  call cls

  int 20h

; DATA
og_video_mode db 0

star_x db 50, 80, 120, 150, 200           ; DB: define bytes (8-bit values)
star_y db 60, 40,  80, 100,  70           ; Creates 5 consecutive bytes in memory
colors db 3, 6, 15, 25, 64
star_count = 5                             ; EQU: define a constant (not stored in memory)
