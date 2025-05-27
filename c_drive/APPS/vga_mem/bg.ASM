; background shenanigans 

org 100h
jmp main

; UTILS
; Performs modulo so we can use our "circular buffers"
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
    ; push ax
    ; push bx
    ; push cx
    ; push dx
    mov bx, animation_speed
    call wait_ticks
    ; pop dx
    ; pop cx
    ; pop bx
    ; pop ax
ret

; DRAWING
; clear screen by putting a lot of pixels into video buffer
; first tests suggest this to be faster than 64000 x stosb
clear_screen:
  xor di, di

  ; count for rep instruction
  mov cx, 32000

  ; if color = 0 this is faster
  ; xor ax, ax
  ;mov al, bg_color
  xor ax, ax

; loop for creating patterns and bg animations
freak:
  ; be creative
  mov ax, cx
  add ax, di
  xor ax, cx
  shr ax, 7

  ; static
  ; and ax, 99
  ; and ax, 17
  ; and ax, 63      ; skewed squares
  ; and ax, 3       ; broad, centered columns

  ; animated
  and ax, 256
  ; and ax, 1023
  ; and ax, 319
  ; and ax, 320
  ; and ax, 666

  jp color2
  mov ax, 18
  jmp draw

  color2:
  xor ax, ax

  draw:
  stosw
  loop freak
ret

draw_stars:
  ; counter for "loop" instruction
  mov cx, star_count
  ; array index
  xor si, si

  draw_star:
  ; AX=pos calculation, later AL = color
  ; BX=320 constant
  ; CX=Counter based on size
  ; DX=star_size constant

    push cx
    xor ch, ch

    ; start position
    xor ah, ah
    mov al, [star_y + si]     
    mov bx, ax
    ; bitshift to avoid multiplication
    ; 320 = 256 + 64
    shl ax, 8
    shl bx, 6
    add ax, bx
    mov dl, [star_x + si]
    xor dh, dh
    add ax, dx
    mov di, ax

    mov cl, [star_sizes + si]
    mov dx, cx

  draw_row:
    push cx
    push di
    ; static color for now
    mov al, 15
    mov cx, dx
    rep stosb

    ; move to next row
    pop di
    add di, 320

    pop cx
    loop draw_row

    pop cx
    inc si
    loop draw_star
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
; SETUP
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

main_loop:
; call clear_each
call clear_screen
call update
call draw_stars
call wait_for_frame

; Press any key to exit
mov ah, 01h
int 16h
jz main_loop

; CLEANUP
; set video mode 13 to clear screen
xor ah, ah
mov al, 13h
int 10h

; restore original video mode
mov al, [og_video_mode]
int 10h

int 20h

; DATA
og_video_mode db 0
animation_speed = 1                         ; higher number == slower framerate           

star_count = 5                          
bg_color = 0

star_x db 50, 80, 120, 150, 200             ; DB: define bytes (8-bit values)
star_y db 60, 40,  80, 100,  70           
star_sizes db 10, 2, 7, 4, 5

; index to circular buffers
offsets db 0, 1, 2, 3, 4

; circular buffers
color_table db 68, 82, 72, 78, 64
; movement
x_offsets db 0, 1, 1, 1, 1                  ; distance
x_sign db 1, 1, 0, 0, 1                     ; direction 1=positive, 0=negative

y_offsets db 1, 1, 0, 1, 1
y_sign db 0, 1, 1, 0, 1
