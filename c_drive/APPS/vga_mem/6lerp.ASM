; animations using linear interpolation (LERP). more stars.

org 100h	
jmp main

; #############################################################
; UTILS
; #############################################################
; TIMING
; ! Use wait_for_frame to set animation speed
; Helpers
get_random:
; OUT: AX
                push bx

                mov ax, [rng_seed]
                mov bx, ax
                shl ax, 7          ; x ^= x << 7
                xor ax, bx
                mov bx, ax
                shr ax, 9          ; x ^= x >> 9
                xor ax, bx
                mov bx, ax
                shl ax, 8          ; x ^= x << 8  
                xor ax, bx
                mov [rng_seed], ax

                pop bx
                ret

get_timer:
; OUTPUT AX = Low order word of system tick count
                push dx
                xor ah, ah                                      ; func 0 = read system clock counter (ca. 18ticks per second)
                int 1Ah                                         ; result in CX:DX
                mov ax, dx                                      ; we only use the low order word of result
                pop dx
                ret

wait_ticks:
                call get_timer
                mov dx, ax                                      ; store result from get_timer
                add dx, bx                                      ; target tick count
wait_loop:
                call get_timer
                cmp ax, dx
                jb wait_loop
                ret
; Main utility
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

; RESULT = black to white on 16 to 31
                mov cx, 16                                      ; 16 brightness levels
                mov bl, 0                                       ; Starting brightness (0 = black)
                mov si, 16                                      ; Starting palette index

create_ramp:
; Some things may look weird here, like all the 'mov al, bl' and the setting of si.
; Both of these make sense when working with the restrictions of the 'out' instruction,
; Namely, that 'out' specifies: use DX and AL/AX. (in our case)

                ; Set palette index
                mov dx, 3C8h                                    ; VGA palette index port. 
                mov ax, si                                      ; Palette index (16-31)
                out dx, al                                      

                ; Set RGB values (VGA uses 6-bit RGB: 0-63)
                inc dx                                          ; DX = 3C9h (palette data port)
                mov al, bl                                      ; Red component
                out dx, al
                mov al, bl                                      ; Green component (same = white/gray)
                out dx, al  
                mov al, bl                                      ; Blue component (same = white/gray)
                out dx, al

                add bl, 4                                       ; Next brightness level (0, 4, 8, 12, ..., 60)
                inc si                                          ; Next palette index
                loop create_ramp

                pop dx
                pop cx
                pop bx
                pop ax
                ret

; DRAWING
wait_retrace:
; RESULT = start drawing just after retrace has started. 
                mov dx,3DAh                                     ; Load VGA status port address into DX
l1:
                in al,dx                                        ; Read status byte from port 3DAh into AL
                and al,08h                                      ; Mask out all bits except bit 3, MODIFYING AL
                jnz l1                                          ; If result is non-zero (bit 3 was set), keep looping
l2:
                in al,dx                                        ; Read status byte again  
                and al,08h                                      ; Mask out all bits except bit 3 again
                jz l2                                           ; If result is zero (bit 3 was clear), keep looping
                ret

draw_star:
; ASSUME AL = color, SI = index of star
push ax
                mov dl, [star_x + si]                           ; DL == X
                mov dh, [star_y + si]                           ; DH == Y
                mov bl, [star_sizes + si]                       ; BL == size

                xor bh, bh
                xor ch, ch                                      ; is this necessary?
                xor ah, ah

                mov cl, dh                                      ; copy Y to set up bitshift. avoids multiplication
                mov al, dh
                shl cx, 8                                       ; Y * 256
                shl ax, 6                                       ; Y * 64
                add ax, cx                                      ; AX = 256 + 64 = 320 * Y
                mov cl, dl                                      ; expand X to 16 bit by moving into reg
                xor ch, ch
                add ax, cx                                      ; AX = 320 * Y + X
                mov di, ax                                      ; set pointer to star position. AX can be discarded

                pop ax                                          ; restore color                  
                mov cl, bl                                      ; row counter. based on star_sizes + si
draw_row:
                mov ch, bl                                      ; col counter.
draw_col:
                stosb                                           ; write AL to [ES:DI] and increase DI
                dec ch                                          ; row done?
                jnz draw_col                                    ; if not, keep drawing columns

                dec cl                                          ; more rows to draw?
                jz done                                         ; if not, we are done

                sub di, bx                                      ; otherwise, set di to start of next row
                add di, 320
                jmp draw_row 
done:
                ret

; #############################################################
main:		
; #############################################################
; SETUP
                mov ah, 0fh	; get current videomode and store in al
                int 10h
                mov [og_video_mode], al

                xor ah, ah	; set video mode 13
                mov al, 13h                           	; 320x200, 256 colors
                int 10h

                call setup_fade_palette	; set up custom palette

                xor ah, ah                                      ; initialize random seed based on timer
                int 1Ah                                         ; result in CX:DX
                mov [rng_seed], dx

                mov ax, 0A000h                                  ; point es to video memory
                mov es, ax

main_loop:
                ; call wait_retrace	; not sure if needed
                xor si, si
loop_stars:
                mov al, 16                                      ; erase stars
                call draw_star

update_positions:
; "Respawn" star after it disappears
; is star close to the center?
                cmp [star_distance_sum + si], 16
                ja not_close

reset_star:
                ; X coordinate
                call get_random
                xor dx, dx
                mov bx, 320
                div bx              ; DX = remainder (0-319)
                mov [star_x + si], dl

                ; Y coordinate
                call get_random
                xor dx, dx
                mov bx, 200
                div bx              ; DX = remainder (0-199)
                mov [star_y + si], dl

not_close:
; LERP towards center (160, 100)
; TODO: base on size
                mov dl, [star_x + si]                           ; DL == X
                mov dh, [star_y + si]                           ; DH == Y

                ; X component
                mov ax, 160                                     ; TARGET nextY = Y + (target - Y) * alpha j
                mov cl, dl                                      ; make X 16-bit for substraction
                sub ax, cx                                      ; AX = target - X = signed delta X
                ; TODO: does that mess up the value if i only take the lower portion? (probably yes)
                mov cl, al                                      ; CL == signed delta X (used later for color LERP)
                sar ax, 3	; use a constant for alpha => we can do a bitshift
                add al, dl
                mov [star_x + si], al

                ; Y component                                   ; nextY = Y + (target - Y) * alpha j
                mov bx, 100                                     ; TARGET
                push cx
                mov cl, dh
                sub bx, cx
                pop cx
                mov ch, bl                                      ; CH == signed distance Y (used later for color LERP)
                sar bx, 3
                add bl, dh 
                mov [star_y + si], bl

; update color
                ; Lerp this so that star 'fade away' as they move towards center
                ; new color = color - 16 * alpha
                ; alpha = 1/distance 
                ; we round distance to nearest power of 2
                ; ! Assume CL == X signed distance, CH == Y signed distance

; TODO: START HERE
; * extract draw_star to own func. Input: color, SI
; * make stars get smaller the closer to the center they are
; * improve LERP: they don't quite hit the center and they dont fade to black as a result I think
; * seed new stars, as old ones disappear...
                cmp cl, 0
                jl invert_x
                jmp check_if_y_negative

invert_x:
                neg cl

check_if_y_negative:
                cmp ch, 0
                jl invert_y
                jmp distances_positive

invert_y:
                neg ch

distances_positive:
; CL == X absolute distance,  CH == Y absolute distance
                xor dx, dx                                      
                mov dl, cl                                      ; Add distances -- why not
                add dl, ch                                      ; maximum sum = 160 + 100 = 260
                adc dh, 0                                       ; DX == sum of distances
                ; we are using this later, so let's save it
                mov bx, dx                                      ; BX == DX (used for size calculation below)
                                                                ; also save it for earlier in the loop -- respawn stars if distance low
                ; cmp bh, 0	; clamp to 256
                ; jz save_distance_sum
                ; mov bl, 255
                ; save_distance_sum:
                mov [star_distance_sum + si], bl

                cmp bl, 16                                      ; snap to black
                jl disappear
                ; mov bx, dx                                      ; restore original

                shr dx, 4                                       ; get range 1-16 
                add dx, 16
                jmp set_color

disappear:
                mov dl, 16

set_color:
                mov [star_colors + si], dl

; update size based on distance (x+y), which max 260
; max distance 
; distance   |   size
;     < 8    |   0
;     < 128  |   4
;     > 128  |   bigger
; size = seed + distance / 32
; shr bx, 5
; mov [star_sizes + si], bl

                mov al, [star_colors + si]
                call draw_star

                ; repeat for every star
                inc si
                cmp si, star_count
                jl loop_stars

                call wait_for_frame

                mov ah, 01h                                     ; Press any key to exit
                int 16h
                jz main_loop

                ; CLEANUP
                xor ah, ah                                      ; set video mode 13 to clear screen
                mov al, 13h
                int 10h

                mov al, [og_video_mode]                         ; restore original video mode
                int 10h

                int 20h                                         ; exit

; #############################################################
; DATA
; #############################################################
og_video_mode db 0
animation_speed = 1                                            ; higher number == slower framerate           

star_count = 9                          
star_x db 10, 60, 80, 120, 240, 74, 86, 92, 100                                  ; DB: define bytes
star_y db 60, 40, 80, 90,  70, 23, 45, 99, 120, 203           
star_distance_sum db 255, 255, 255, 255, 255, 255, 255, 255, 255
star_sizes db 4, 2, 3, 4, 5, 2, 1, 3, 4
star_colors db 31, 31, 31, 31, 31, 31, 31, 31, 31

rng_seed dw 0x1234  ; 16-bit seed, any non-zero value
