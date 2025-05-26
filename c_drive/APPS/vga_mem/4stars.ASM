; stars animated in a static loop
; new concepts:
;       * animation loop
;       * use bios timer ticks for consistent animation speed
;       * circular buffers
; 
; Note: This is heavy on the modules and function calls, to keep things tidy.
; Wisdom seems to be: write these things inline when optimizing.
; Example: Clearing the whole screen each frame on a 8086 lags like hell.

org 100h
jmp main

; MAINTENANCE
setup:
  ; get current videomode and store in al
  mov ah, 0fh
  int 10h
  mov [og_video_mode], al

  ; set video mode 13
  xor ah, ah
  mov al, 13h                           ; 320x200, 256 colors
  int 10h

  ; point es to video memory
  mov ax, 0A000h
  mov es, ax
ret

cleanup:
  ; set video mode 13 to clear screen
  xor ah, ah
  mov al, 13h
  int 10h

  ; restore original video mode
  mov al, [og_video_mode]
  int 10h
ret

; UTILS
; Performs modulo so we can use our "circular buffers"
; NOTE: Write a get_next_random that adds OR decreases offset based on smth like system time -- see get_timer
; (this would entail handling out of bounds cases)
get_next:
; INPUT BL=offset
; OUTPUT BL = (offset+1) % star_count (modulo)
  inc bl
  cmp bl, star_count
  je reset_to_zero
  ret
  reset_to_zero:
  xor bl, bl
ret

; TIMER
get_timer:
; OUTPUT AX = Low order word of system tick count
    push dx
    xor ah, ah                          ; func = read system clock counter (ca. 18ticks per second)
    int 1Ah                             ; result in CX:DX
    mov ax, dx                          ; we only use the low order word of result
    pop dx
ret

wait_ticks:
    call get_timer
    mov dx, ax                          ; store result from get_timer
    add dx, bx                          ; target tick count
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
    mov bx, animation_speed
    call wait_ticks
    pop dx
    pop cx
    pop bx
    pop ax
ret

; DRAWING
; clear screen by putting 64000 pixels into video buffer
clear_screen:
  push ax
  push cx
  push di

  xor di, di
  mov cx, 64000
  mov al, bg_color
  ; rep repeats cx times
  rep stosb

  pop di
  pop cx
  pop ax
ret

; clear screen by "erasing" each star 
clear_each:
  push bx
  push cx
  push di
  push si

  xor si, si
  mov bl, bg_color
  mov cx, star_count

  erase_star:
    push cx
    push dx
    xor ch, ch
    xor dh, dh

    mov cl, [star_x + si]
    mov dl, [star_y + si]
    call plot_pixel

    inc si

    pop dx
    pop cx
  loop erase_star

  pop si
  pop di
  pop cx
  pop bx
ret

; NOTE: Optimization opportunity: inline this in draw_stars
plot_pixel:
  ; Takes args:   * CX=X position
  ;               * DX=Y position
  ;               * BL=color

  push di

  ; Offset = Y * 320 + X
  mov ax, 320
  mul dx
  add ax, cx

  ; Point DI to XY
  mov di, ax

  ; color
  mov al, bl

  ; store byte in AL at address ES:DI and increment DI
  stosb

  pop di
ret

draw_stars:
  push dx

  ; counter for "loop" instruction
  mov cx, star_count
  ; array index
  xor si, si

  ; draw stars
  draw_star:
    ; set up bl=color, cx=x, dx=y and call plot_pixel
    push cx

    ; positions
    mov cl, [star_x + si]
    xor ch, ch

    mov dl, [star_y + si]
    xor dh, dh

    ; color
    mov bl, [offsets + si]
    mov bl, [color_table + bx]
    call plot_pixel

    inc si

    pop cx
  loop draw_star

  pop dx
ret

update:
  push ax
  push bx
  push si

  ; set up counters and registers
  xor si, si
  mov cx, star_count
  xor bh, bh
  xor ah, ah

  update_loop:
    ; pointer to star's current offset
    mov bl, [offsets + si]

    ; UPDATE POSITIONS
    ; X = star_x + (x_offset * x_sign)
    mov al, [star_x + si] 
    cmp [x_sign + bx], 0
    je subtract_x
    add al, [x_offsets + bx]
    jmp x_done
    subtract_x:
    sub al, [x_offsets + bx]
    x_done:
    mov [star_x + si], al

    ; Y = star_y + (y_offset * y_sign)
    mov al, [star_y + si] 
    cmp [y_sign + bx], 0
    je subtract_y
    add al, [y_offsets + bx]
    jmp y_done
    subtract_y:
    sub al, [y_offsets + bx]
    y_done:
    mov [star_y + si], al

    ; UPDATE OFFSETS
    call get_next
    mov [offsets + si], bl

    inc si
  loop update_loop

  pop si
  pop bx
  pop ax
ret


; MAIN
main:
  call setup
  call clear_screen

main_loop:
  call clear_each
  call update
  call draw_stars
  call wait_for_frame

  ; Check if key pressed (non-blocking)
  mov ah, 01h
  int 16h
jz main_loop

call cleanup
int 20h

; DATA
og_video_mode db 0
animation_speed = 5                         ; higher number == slower framerate           

star_count = 5                          
bg_color = 0

star_x db 50, 80, 120, 150, 200             ; DB: define bytes (8-bit values)
star_y db 60, 40,  80, 100,  70           

; index to circular buffers
offsets db 0, 1, 2, 3, 4

; circular buffers
color_table db 68, 82, 72, 78, 64
; movement
x_offsets db 0, 1, 1, 1, 1                  ; distance
x_sign db 1, 1, 0, 0, 1                     ; direction 1=positive, 0=negative

y_offsets db 1, 1, 0, 1, 1
y_sign db 0, 1, 1, 0, 1
