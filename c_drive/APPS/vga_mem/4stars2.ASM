; animated stars
; new concepts:
;       * use bios timer ticks for consistent animation speed
;       * circular buffers

org 100h
jmp main

setup:
  ; store current videomode
  mov ah,0fh
  int 10h ; stores in al
  mov [og_video_mode], al

  ; set video mode 13
  mov ah, 0 ; video mode function
  mov al, 13h ; 320x200, 256 colors
  int 10h

  ; point es to video memory
  mov ax, 0A000h
  mov es, ax
ret

cleanup:
  ; clear screen by re-setting video mode 13
  mov ah, 0
  mov al, 13h
  int 10h

  ; restore video mode
  mov al, [og_video_mode]
  mov ah, 0
  int 10h
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

draw_stars:
  ; counter for loop instruction
  mov cx,star_count
  ; array index
  mov si, 0

  ; draw stars
  draw_star:
    push bx
    push cx
    push dx

    mov cl, [star_x + si]             ; []: memory reference, gets star_x[2] = 120
    xor ch, ch
    mov dl, [star_y + si]             ; AH gets star_y[2] = 80
    xor dh, dh
    ; color
    xor bx, bx
    mov bl, [offsets + si]
    mov bl, [color_table + bx]
    call plot_pixel
    inc si
    pop dx
    pop cx
    pop bx
  loop draw_star
ret

get_next:
; INPUT AL=offset
; OUTPUT AL = (offset+1) % star_count (modulo)
  inc al
  cmp al, star_count
  jl done
  xor al, al
  done:
ret

update:
  ; set new colors
  ; update offset
  ; set offset to get next based on current offset
  push ax
  push si

  ; set up counters
  xor si, si
  mov cx, star_count
  update_offset:
    mov al, [offsets + si]
    call get_next
    mov [offsets + si], al
    inc si
  loop update_offset

  pop si
  pop ax
ret

; Timer functions
get_timer:
push dx
    mov ah, 0
    int 1Ah
    mov ax, dx
    pop dx
    ret

wait_ticks:
    call get_timer
    mov dx, ax
    add dx, bx
wait_loop:
    call get_timer
    cmp ax, dx
    jb wait_loop
    ret

wait_for_frame:
    push ax
    push bx
    push cx
    push dx
    mov bx, 1
    call wait_ticks
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; MAIN
main:
call setup

main_loop:
; TODO: cls
  call update
  call draw_stars
  call wait_for_frame

  ; Check if key pressed (non-blocking)
  mov ah, 01h         ; Check keyboard status
  int 16h             ; BIOS keyboard interrupt
jz main_loop            ; Jump if key available (zero flag clear)

call cleanup
int 20h

; DATA
og_video_mode db 0

star_count = 5                             ; EQU: define a constant (not stored in memory)

star_x db 50, 80, 120, 150, 200           ; DB: define bytes (8-bit values)
star_y db 60, 40,  80, 100,  70           ; Creates 5 consecutive bytes in memory

; index to circular buffer
; used for both color_table and position
offsets db 0, 1, 2, 3, 4

; circular buffers
color_table db 3, 6, 15, 25, 64
; movement
x_offsets db 1, 2, 1, 3, 2          ; distance
x_sign db 1, 1, 0, 0, 1             ; direction 1=positive, 0=negative

y_offsets db 1, 1, 0, -2, 1
y_sign db 1, 1, 1, 0, 1
