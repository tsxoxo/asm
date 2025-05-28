; stars animated in a static loop with palette shenanigans
; NOTE: START HERE: * add palette shenanigans (fade in-fade out rotation)
;                   * play with profilng/border trick discussed with claude in "Troubleshooting Missing Pixels in Assembly Drawing Routine"

org 100h
jmp main

; UTILS
; Performs modulo so we can use our "circular buffers"
; NOTE: Write a get_next_random that adds OR decreases offset based on smth like system time -- see get_timer
; (this would entail handling out of bounds cases)
; could also add noise some other way, = <some pointer reg>%69 ?
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

; PALETTE
set_pal:
  mov al, 15
  mov dx, 3C8h                          ; palette index port
  out dx, al

  inc dx
  mov al, 9
  out dx, al
  mov al, 14
  out dx, al
  mov al, 28
  out dx, al
ret

setup_fade_palette:
    push ax
    push bx
    push cx
    push dx
    
    mov cx, 16                  ; 16 brightness levels
    mov bl, 0                   ; Starting brightness (0 = black)
    mov si, 16                  ; Starting palette index
    
create_ramp:
    ; Set palette index
    mov dx, 3C8h                ; VGA palette index port
    mov ax, si                  ; Palette index (16-31)
    out dx, al
    
    ; Set RGB values (VGA uses 6-bit RGB: 0-63)
    inc dx                      ; DX = 3C9h (palette data port)
    mov al, bl                  ; Red component
    out dx, al
    mov al, bl                  ; Green component (same = white/gray)
    out dx, al  
    mov al, bl                  ; Blue component (same = white/gray)
    out dx, al
    
    add bl, 4                   ; Next brightness level (0, 4, 8, 12, ..., 60)
    inc si                      ; Next palette index
    loop create_ramp
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
; DRAWING
; clear screen by putting a lot of pixels into video buffer
; doing it with 32000 and stosw produces less flicker than 64000 and stosb
clear_screen:
  xor di, di
  ; count for rep instruction
  mov cx, 32000
  ; if color = 0 this is faster
  xor ax, ax
  rep stosw
ret

draw_stars:
  ; counter for "loop" instruction
  mov cx, star_count
  ; array index
  xor si, si

  draw_star:
  ; AX=pos calculation
  ; BX=color
  ; CX=Counter based on size
  ; DX=star_size constant

    push cx
    xor ch, ch

    ; set DI to XY start position (upper left corner of square)
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

    ; save size for counting in CX and as a constant in DX
    mov cl, [star_sizes + si]
    mov dx, cx

  draw_row:
    push cx

    ; write a row = as many times as [star_sizes + si]
    ; xor ah, ah
    ; mov al, [color_table]
    
    ; animation
    ; set base value
    mov al, [color_table]

    ; do stuff
    ; opening doors
    ; sub al, cl
    ; shr al, 4

    ; sort of staggered flickering
    add al, dl
    add ax, si

    ; weird flickering patterns
    ; xor ax, di
    ; xor ax, 7

    ; clamp and set range
    and ax, 15
    add ax, 16

    mov cx, dx
    rep stosb

    ; move to next row
    sub di, dx
    add di, 320

    pop cx
    loop draw_row

; repeat for every star
    pop cx
    inc si
    loop draw_star
ret

update:
; time in dx
    ; cycle through palette range 
    add dl, 0Fh
    mov [color_table], dl
ret

wait_retrace:
mov dx,3DAh       ; Load VGA status port address into DX
l1:               ; Label for first loop
in al,dx          ; Read status byte from port 3DAh into AL
and al,08h        ; Mask out all bits except bit 3, MODIFYING AL
jnz l1            ; If result is non-zero (bit 3 was set), keep looping
l2:               ; Label for second loop
in al,dx          ; Read status byte again  
and al,08h        ; Mask out all bits except bit 3 again
jz l2             ; If result is zero (bit 3 was clear), keep looping
ret


; MAIN
main:
; get current videomode and store in al
mov ah, 0fh
int 10h
mov [og_video_mode], al

; set video mode 13
xor ah, ah
mov al, 13h                           ; 320x200, 256 colors
int 10h

; call set_pal
; call setup_fade_palette

; point es to video memory
mov ax, 0A000h
mov es, ax

main_loop:
; call wait_retrace
; call clear_screen

xor ah, ah                          ; func = read system clock counter (ca. 18ticks per second)
int 1Ah                             ; result in CX:DX

and dl, 1fh                         ; clamp to 0-15

; cycle through palette range 
; Create triangle wave: 0-15-0-15-0...
    cmp dl, 16
    jl triangle_done
    
    ; If >= 16, reverse it: 31-16=15, 30-16=14, etc.
    mov al, 31
    sub al, dl
    mov dl, al
    
triangle_done:
    add dl, 16                      ; Shift to palette 16-31
    mov [color_table], dl

call draw_stars
; call wait_for_frame

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
animation_speed = 5                         ; higher number == slower framerate           

star_count = 5                          
bg_color = 0

; flag for oscillating animation
reverse_flag db 0

star_x db 50, 80, 120, 150, 200             ; DB: define bytes (8-bit values)
star_y db 60, 40,  80, 100,  70           
star_sizes db 10, 2, 7, 40, 5

; index to circular buffers
offsets db 0, 1, 2, 3, 4

; circular buffers
color_table db 0, 82, 72, 78, 64
; movement
x_offsets db 0, 1, 1, 1, 1                  ; distance
x_sign db 1, 1, 0, 0, 1                     ; direction 1=positive, 0=negative

y_offsets db 1, 1, 0, 1, 1
y_sign db 0, 1, 1, 0, 1
