; stars animated in a static loop with palette shenanigans

org 100h	
jmp main

; #############################################################
; UTILS
; #############################################################
; TIMING
; use wait_for_frame to set animation speed
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


; #############################################################
main:		
; #############################################################
        mov ah, 0fh		; get current videomode and store in al
        int 10h
        mov [og_video_mode], al

        xor ah, ah		; set video mode 13
        mov al, 13h                           	; 320x200, 256 colors
        int 10h

        call setup_fade_palette	; set up custom palette

        mov ax, 0A000h		; point es to video memory
        mov es, ax

        xor bp, bp

main_loop:
        ; call wait_retrace		; not sure if needed

        xor si, si                                              ; draw stars

        xor ax, ax                                              ; get timer once per frame and save low word in CX
        int 1Ah                             	; result in CX:DX

        and dx, 15                                              ; only update every 16 frames
        jz draw_star
        mov bp, dx
draw_star:
        xor ah, ah                                              ; set DI to XY start position (upper left corner of square)
        xor dh, dh                                              ; cannot assume DX === 0
        mov al, [star_y + si]                                   ; offset = Y * 320 + X     
        mov bx, ax                                              ; copy it to set up bitshift. avoids multiplication
        shl ax, 8                                               ; Y * 256
        shl bx, 6                                               ; Y * 64
        add ax, bx                                              ; 256 + 64 = 320
        mov dl, [star_x + si]
        add ax, dx
        mov di, ax                                              ; set pointer. AX can be discarded

        xor bh, bh
        mov bl, [star_sizes + si]                               ; store size for easy access

        ; set color
        mov ax, 31
        xor bp, 411                                             ; mix BP (timer) with noise to produce oscillations
        and bp, ax                                              ; Clamp to double the palette range 0-31 to produce a triangle wave
        cmp bp, 16                                              ; test if it's "over the hump"
        jl triangle_done                                        ; either draw one way

        and bp, 15                                              ; or the other
        sub ax, bp
        jmp color_done

triangle_done:
        mov ax, bp

color_done:
        mov dx, si                                              ; base on index of star
        add ax, dx

        and al, 15                                              ; clamp and offset to get range 16-31 
        add al, 16

        mov cl, bl                                              ; row counter. based on star_sizes + si
draw_row:
        mov ch, bl                                              ; col counter. based on star_sizes + sidraw_col:
draw_col:
        stosb                                                   ; write AL to [ES:DI] and increase DI
        dec ch                                                  ; row done?
        jnz draw_col                                            ; if not, keep drawing columns

        dec cl                                                  ; more rows to draw?
        jz next_star                                            ; if not, draw next star

        sub di, bx                                              ; otherwise, set di to start of next row
        add di, 320
        jnz draw_row 

next_star:
        ; repeat for every star
        inc si
        cmp si, star_count
        jl draw_star

        call wait_for_frame

        mov ah, 01h                                             ; Press any key to exit
        int 16h
        jz main_loop

        ; CLEANUP
        xor ah, ah                                              ; set video mode 13 to clear screen
        mov al, 13h
        int 10h

        mov al, [og_video_mode]                                 ; restore original video mode
        int 10h

        int 20h                                                 ; exit

; #############################################################
; DATA
; #############################################################
og_video_mode db 0
animation_speed = 12                                             ; higher number == slower framerate           

star_count = 5                          

star_x db 10, 60, 80, 120, 240                                 ; DB: define bytes
star_y db 60, 40,  80, 100,  70           
star_sizes db 10, 2, 7, 40, 5

