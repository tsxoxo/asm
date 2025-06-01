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

; To get random:
                ; ; X coordinate
                ; call get_random
                ; xor dx, dx
                ; mov bx, 320
                ; div bx              ; DX = remainder (0-319)
                ; mov [star_x + si], dl
                ;
                ; ; Y coordinate
                ; call get_random
                ; xor dx, dx
                ; mov bx, 200
                ; div bx              ; DX = remainder (0-199)
                ; mov [star_y + si], dl
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
                mov dl, [star_x_current + si]                           ; DL == X
                mov dh, [star_y_current + si]                           ; DH == Y
                mov bl, [star_size_current + si]                ; BL == size

                cmp bl, 0                                       ; don't draw size 0
                je done

                push ax

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
                mov cl, bl                                      ; draw as many rows as [star_size_current + si]
draw_row:
                mov ch, bl                                      ; draw as many cols as [star_size_current + si]
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

calculate_abs_XY_distances:
; In -> Current XY, Target XY
; OUT -> [distance_x/y_absolute]
; Assume SI == index of star

                push ax                                         ; Back up registers
                push bx
                push cx
                push dx

                mov cl, [star_x_current + si]
                mov ch, [star_y_current + si]
                mov bl, [target_x]
                mov bh, [target_y]
                ; assume CL = UNSIGNED current X, CH = UNSIGNED current Y 
                ; assume BL = UNSIGNED target X, BH = UNSIGNED target Y (160, 100)
                ; calculate SIGNED deltas: target - current

                ; calculate SIGNED delta X
                mov al, bl                                      ; extend target to AX 16-bit to do a signed calculation. 
                xor ah, ah
                mov dl, cl                                      ; extend current to DX
                xor dh, dh
                sub ax, dx                                      ; AX = SIGNED delta X, range -160 to 160 

                ; convert delta X to UNSIGNED absolute value
                cwd                                             ; sign extend AX to DX:AX
                xor ax, dx                                      ; flips to ~AX only if result negative (DX == FFFF == -1) 
                sub ax, dx                                      ; subtract 0 or -1. AX == UNSIGNED absolute delta X

                mov [ distance_x_absolute + si ], al                 ; store

                ; calculate SIGNED delta Y
                mov al, bh                                      ; extend target Y to AX 16-bit to do a signed calculation
                xor ah, ah
                mov dl, ch                                      ; extend current Y to DX
                xor dh, dh
                sub ax, dx                                      ; AX = SIGNED absolute delta Y

                ; convert delta Y to UNSIGNED absolute value
                cwd                                             ; sign extend AX to DX:AX
                xor ax, dx                                      ; flips to ~AX only if result negative (DX == FFFF == -1) 
                sub ax, dx                                      ; subtract 0 or -1. AX == UNSIGNED absolute delta Y

                mov [ distance_y_absolute + si], al                 ; store

                ; Calculate sum of distances
                mov bl, [distance_x_absolute + si]
                add al, bl
                ; TODO: probably check for overflow and clamp to 255
                mov [star_distance_sum + si], al

                pop dx                                          ; Restore registers
                pop cx
                pop bx
                pop ax

                ret

update_size:
; update size based on abs XY distances stored in memory

; In -> Absolute XY distances from target, UNSIGNED, 0-160
; OUT -> [star_size_current + si]

                push ax                                         ; Back up registers
                push bx
                push cx
                push dx

                mov al, [distance_x_absolute + si]
                xor ah, ah
                mov bl, [distance_y_absolute + si]
                xor bh, bh

                cmp ax, bx                                      ; lerp based on bigger delta (simple but effective)
                jl put_bigger_into_ax
                jmp lerp_size

                put_bigger_into_ax:
                xchg ax, bx                                     ; AX = UNSIGNED distance, range 0 - 160

                lerp_size:
                ; Use tiers
                ; Distance --- Size
                ; 160 to 128 = original size
                ; 128 to 64  = size / 2
                ; 64 to 32   = size / 4
                ; 32 to 8    = 1 pixel
                ; < 8        = 0
                ; (not really a LERP, but who cares)

                mov bl, [star_size_seed + si]                   ; BX = star size
                xor bh, bh

                cmp ax, 128
                jg set_size                                     ; TIER 0 -> don't change size

                cmp ax, 64                                      ; TIER 1 -> size / 2 (use bitshift)
                jg close

                cmp ax, 32                                      ; TIER 2 -> size / 4 (use bitshift)
                jg closer

                cmp ax, 8
                jg almost                                       ; TIER 3 -> 1 pixel

                jmp black_hole              ; TIER 4 -> 0

                close:
                shr bl, 1
                or bl, 1                                        ; dont make small stars disappear too early
                jmp set_size

                closer:
                shr bl, 2
                or bl, 1                                        ; dont make small stars disappear too earl
                jmp set_size

                almost:
                mov bl, 1
                jmp set_size

                black_hole:
                mov bl, 0

                set_size:
                ; WARN: clamp to 1 if something seems weird
                ; or bl, 1                                        ; clamp size to 1 pixel

                mov [star_size_current + si], bl                ; store

                pop dx
                pop cx
                pop bx
                pop ax
                ret

update_position:
; Assume SI == index of star
; In -> Current XY positions
; OUT -> [star_x/y_current + si]

; Lerp towards target based on SIGNED XY deltas
                push ax                                         ; Back up registers
                push bx
                push cx
                push dx

                mov dl, [star_x_current + si]                           ; DL == X
                mov dh, [star_y_current + si]                           ; DH == Y

                xor ah, ah
                xor bh, bh
                xor ch, ch

                ; X component
                mov al, [target_x]                                     ; TARGET nextY = Y + (target - Y) * alpha j
                mov cl, dl                                      ; make X 16-bit for substraction
                sub ax, cx                                      ; AX = target - X = signed delta X
                ; TODO: does that mess up the value if i only take the lower portion? (probably yes)
                sar ax, 3	; use a constant for alpha => we can do a bitshift

                cmp ax, 0                                       ; Check if movement is 0
                jne x_move_ok
                mov ax, 1                                       ; Force at least 1 pixel movement
x_move_ok:
                add al, dl

                mov [star_x_current + si], al                   ; Store new X

                ; Y component                                   ; nextY = Y + (target - Y) * alpha j
                mov bl, [target_y]                                     ; TARGET
                mov cl, dh
                sub bx, cx
                sar bx, 3

                cmp bx, 0                                       ; Check if movement is 0
                jne y_move_ok
                mov bx, 1                                       ; Force at least 1 pixel movement
y_move_ok:
                add bl, dh 

                mov [star_y_current + si], bl                   ; Store new Y

                pop dx
                pop cx
                pop bx
                pop ax
                ret

update_color:
; update color based on abs XY distances stored in memory

; In -> Absolute XY distances from target, UNSIGNED, 0-160
; OUT -> [star_color + si]

                ; stars 'fade away' as they move towards center
                push ax                                         ; Back up registers
                push bx
                push cx
                push dx

                mov al, [distance_x_absolute + si]
                xor ah, ah
                mov bl, [distance_y_absolute + si]
                xor bh, bh

                cmp ax, bx                                      ; lerp based on bigger delta (simple but effective)
                jl put_bigger_into_ax_colors
                jmp lerp_color

                put_bigger_into_ax_colors:
                xchg ax, bx                                     ; AX = UNSIGNED distance, range 0 - 160

                lerp_color:
                mov bl, [black_hole_radius]
                cmp al, bl                                        ; is inside center?
                jl disappear                                    ; snap to black

; TODO: i am pretty sure this is wrong
; maybe just tier this, like in update_size
                shr ax, 4                                       ; get range 0-15 
                add ax, 16                                      ; bring color in range 16 - 31
                jmp set_color

disappear:
                mov al, 16

set_color:
                mov [star_color + si], al

                pop dx
                pop cx
                pop bx
                pop ax
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
; TODO: START HERE
; * refactor color and pos lerping. use results from calc done in update_size
; * update_size: extract calculations into procedures
; * improve spawning algo: simply spawn in initial pos? distribute spawn points more towards edges of screen?
; * possibly remove or simplify randomness: use init pos + an offset as new spawn?
; * lerp position based on size, giving a delayed/gravity effect
; * possible refactor: mov al, [current_x] once in main loop, then smaller lerp functions
; * get rid of storing sum of distances in mem?

                ; call wait_retrace	; not sure if needed
                xor si, si
loop_stars:
                mov al, 16                                      ; erase stars
                call draw_star

; CASE 1: star is spawning

                cmp [is_spawning + si], 1                        ; is spawning?
                je keep_spawning
                jmp check_is_in_black_hole                      ; if not, it must be moving towards black_hole, so check progress

keep_spawning:
; idea: advance spawn only sometimes
                xor ah, ah
                int 1Ah
                add dx, si
                shr dx, 1
                jc skip_lerps_and_draw

                inc [star_color + si]                          ; star gets a little brighter
                                                                ; TODO: (increase size)
                cmp [star_color + si], 31                      ; star has finished spawning?
                jae finished_spawning                            ; yes -> set flag 
                jmp skip_lerps_and_draw                                    ; no -> skip lerping, just draw

finished_spawning:
                mov [is_spawning + si], 0
                jmp do_lerps

; CASE 2: star is not spawning
check_is_in_black_hole:
; if so, respawn (reset all attributes to seeds)
                mov bl, [black_hole_radius]
                cmp [star_distance_sum + si], bl                ; is star inside black hole?
                ja do_lerps                                     ; if outside -> lerp

                                                                ; if inside -> reset attributes
                ; spawn flag
                mov [is_spawning + si], 1

                ; X
                mov al, [star_x_seed + si]
                mov [star_x_current + si], al

                ; Y
                mov al, [star_y_seed + si]
                mov [star_y_current + si], al

                ; size
                mov al, [star_size_seed + si]
                mov [star_size_current + si], al

                ; color
                mov [star_color + si], 16


                jmp skip_lerps_and_draw


; lerp a bunch of stuff
do_lerps:
                ; Stores basis for LERPing in memory
                call calculate_abs_XY_distances

                ; update size based on abs XY distances stored in memory
                call update_size

                ; update color based on abs XY distances stored in memory
                call update_color

                ; Lerp towards target based on SIGNED XY deltas stored in memory
                call update_position

skip_lerps_and_draw:
                mov al, [star_color + si]
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

black_hole_radius = 8

target_x db 160
target_y db 100

; seeds
star_count = 64
star_x_seed db 66, 113, 137, 180, 222, 202, 209, 189, 159, 118, 193, 102, 56, 192, 201, 223
            db 190, 49, 178, 166, 49, 105, 106, 119, 214, 174, 53, 42, 147, 169, 62, 162
            db 113, 235, 169, 176, 228, 136, 59, 204, 101, 142, 208, 221, 107, 130, 175, 217
            db 163, 183, 219, 117, 172, 168, 167, 225, 95, 177, 147, 170, 162, 130, 219, 65
star_y_seed db 111, 140, 93, 99, 60, 99, 172, 119, 3, 29, 166, 58, 42, 33, 31, 134
            db 17, 49, 81, 106, 56, 132, 124, 193, 37, 56, 132, 116, 44, 185, 119, 143
            db 15, 52, 169, 86, 70, 129, 54, 24, 52, 72, 59, 38, 133, 9, 188, 95
            db 13, 157, 126, 133, 97, 48, 132, 41, 91, 73, 121, 126, 194, 124, 79, 100
star_size_seed db 4, 4, 4, 3, 3, 2, 1, 2, 1, 1, 1, 2, 1, 1, 1, 1
            db 1, 1, 2, 2, 1, 2, 2, 1, 1, 2, 1, 1, 2, 1, 1, 2
            db 1, 1, 1, 2, 1, 2, 1, 1, 2, 2, 1, 1, 2, 1, 1, 2
            db 1, 2, 1, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1

; current
star_x_current db 66, 113, 137, 180, 222, 202, 209, 189, 159, 118, 193, 102, 56, 192, 201, 223
            db 190, 49, 178, 166, 49, 105, 106, 119, 214, 174, 53, 42, 147, 169, 62, 162
            db 113, 235, 169, 176, 228, 136, 59, 204, 101, 142, 208, 221, 107, 130, 175, 217
            db 163, 183, 219, 117, 172, 168, 167, 225, 95, 177, 147, 170, 162, 130, 219, 65
star_y_current db 111, 140, 93, 99, 60, 99, 172, 119, 3, 29, 166, 58, 42, 33, 31, 134
            db 17, 49, 81, 106, 56, 132, 124, 193, 37, 56, 132, 116, 44, 185, 119, 143
            db 15, 52, 169, 86, 70, 129, 54, 24, 52, 72, 59, 38, 133, 9, 188, 95
            db 13, 157, 126, 133, 97, 48, 132, 41, 91, 73, 121, 126, 194, 124, 79, 100
star_size_current db 4, 4, 4, 3, 3, 2, 1, 2, 1, 1, 1, 2, 1, 1, 1, 1
            db 1, 1, 2, 2, 1, 2, 2, 1, 1, 2, 1, 1, 2, 1, 1, 2
            db 1, 1, 1, 2, 1, 2, 1, 1, 2, 2, 1, 1, 2, 1, 1, 2
            db 1, 2, 1, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
star_distance_sum db 64 dup(255) ; Re-added as requested
distance_x_absolute db 64 dup(100)
distance_y_absolute db 64 dup(100)
star_color db 31, 18, 30, 26, 16, 22, 31, 21, 31, 31, 31, 22, 31, 31, 31, 31
            db 31, 31, 24, 28, 21, 20, 26, 31, 31, 20, 19, 25, 28, 31, 31, 23
            db 16, 19, 31, 31, 31, 25, 23, 27, 31, 24, 18, 27, 31, 31, 24, 31
            db 16, 21, 31, 31, 31, 31, 17, 31, 31, 31, 23, 31, 29, 31, 17, 31 ; Adjusted based on is_spawning
is_spawning db 0, 1, 1, 1, 1, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0
            db 0, 0, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 0, 0, 1
            db 1, 1, 0, 0, 0, 1, 1, 1, 0, 1, 1, 1, 0, 0, 1, 0
            db 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 1, 0 ; 64 unique 0/1 values

rng_seed dw 0x1234  ; 16-bit seed, any non-zero value
