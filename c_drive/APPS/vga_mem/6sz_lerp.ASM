; Sizecoding animation based on 6Lerp.asm
; START_HERE:
; * lerp position based on size, giving a delayed/gravity effect

org 100h	
jmp main

; #############################################################
; UTILS
; #############################################################
; TIMING
; ! Use wait_for_frame to set animation speed
; Helpers
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
                mov al, bl                                      ; All values the same == grayscale
                out dx, al
                out dx, al  
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


put_pixel:                                                      ; IN: AL == color, BX == X, CX == Y
                                                                ; DEBUG: dont draw if coordinates too high
                cmp   bx, 320
                jae   skip_pixel
                cmp   cx, 200
                jae   skip_pixel

                mov dx, cx                                      ; copy Y to set up bitshift. avoids multiplication
                shl dx, 8                                       ; Y * 256
                shl cx, 6                                       ; Y * 64
                add cx, dx                                      ; CX = 256 + 64 = 320 * Y
                add cx, bx                                      ; CX = 320 * Y + X
                mov di, cx                                      ; set pointer to star position

                stosb                                           ; write AL to [ES:DI] and increase DI
                skip_pixel:
ret

calculate_abs_XY_distances:
; In -> Current XY, Target XY
; OUT -> [distance_x/y_absolute]
; Assume SI == index of star

                ret

update_size:
; update size based on abs XY distances stored in memory

; In -> Absolute XY distances from target, UNSIGNED, 0-160
; OUT -> [star_size_current + si]
                ret

update_position:
; Assume SI == index of star
; In -> Current XY positions
; OUT -> [star_x/y_current + si]

; Lerp towards target based on SIGNED XY deltas
                ret

update_color:
; update color based on abs XY distances stored in memory

; In -> Absolute XY distances from target, UNSIGNED, 0-160
; OUT -> [star_color + si]

                ; stars 'fade away' as they move towards center
ret

; do a 32 bit mult and then scale down by 64
; IN: AX, DX as operands
; OUT: AX -- scaled down result
mul32shr6:
                mul dx                                         ; result in DX:AX
                mov cx, 6
                bitshift:
                shr dx, 1
                rcr ax, 1
                loop bitshift
                ret

; IN:   AX == distance, SIGNED
;       DX == echo_progress
; OUT:  AX == (distance * echo_progress) >> 8
mul32shr8:
                push cx
                push dx

                imul dx
                mov cx, 8
                bitshift8:
                sar dx, 1
                rcr ax, 1
                loop bitshift8

                pop dx
                pop cx
                ret
; -----------------------------------------------
; Calculate spawn position by mangling star index
; -----------------------------------------------
; IN:  DX == echo index (0-63)
; OUT: BX == X, 
;      CX == Y
get_spawn_xy:
                push si

                mov si, dx

                ; --- X ---
                mov bx, dx                                      ; scramble range 0-63
                shl bx, 2                                       ; algo is called 'XOR fold'
                and bx, 63                                      ; x = x XOR (x*n)
                mov ax, dx
                xor ax, bx

                mov dx, 319                                     ; scale to 0-319
                call mul32shr6
                mov bx, ax

                ; --- Y ---
                mov cx, si
                shl cx, 5
                and cx, 63
                mov ax, si
                xor ax, cx

                mov dx, 199                                     ; scale to 0-199
                call mul32shr6
                mov cx, ax

                pop si
                ret

; Calculate new XY based on spawnXY and progress value as well as distance to targetXY
; IN: si == echo's progress (0-63), BP == echo's index (0-7)
; OUT: BX = X, CX = Y
calc_position:
                                                                ; Calculate virtual index
                mov dx, si                                      ; DX == 0-7
                shl dx, 3                                       ; DX == DX * 8 == 0-56
                add dx, bp                                      ; DX == 0-63

                                                                ; Get spawnXY based on virtual index in DX
                call get_spawn_xy                               ; BX == spawnX, CX == spawnY

                                                                ; Calculate echo's progress
	; echo_progress = [core_progress + si] + f(bp)
                xor dh, dh
                mov dl, [core_progress + si]
                mov ax, bp                                      ; AX = echo number 0-7
                shl al, 5                                       ; Transpose echo number
                add dl, al                                      ; DX = f(echo_ind) + core_progress = echo_progress

                ; lerp X and store into BX
                ; X = spawnX + ((targetX - spawnX) * echo_progress) >> 8
                xor ah, ah
                mov al, [target_x]
                sub ax, bx                                      ; AX == distanceX. range -95 - 160
                call mul32shr8
                add bx, ax

                ; Y -> CX
                xor ah, ah
                mov al, [target_y]
                sub ax, cx                                      ; AX == distanceX. range -95 - 160
                call mul32shr8
                add cx, ax
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

                mov ax, 0A000h                                  ; point es to video memory
                mov es, ax

main_loop:
                ; call wait_retrace	; not sure if needed

                ; loop through 8 base stars
                xor si, si
core_loop:                                                      

                ; --- ERASE ---
                mov bp, 0                                       ; draw the same star 8 times in different progress phase
echo_erase_loop:
                call calc_position

                mov al, 16                                      ; erase == draw black pixel at (BX, CX)
                call put_pixel

                inc bp
                cmp bp, star_count

                jl echo_erase_loop

                ; --- UPDATE ---
	; progress = 255 == respawn star == reset progress 0
                mov dl, [core_progress + si]                    ; update core progress
                ; inc dl
                add dl, 3
                mov [core_progress + si], dl

                ; --- DRAW ---
                mov bp, 0                                       ; draw the same star 8 times in different progress phase
echo_draw_loop:
                call calc_position

                mov al, 31                                      ; erase == draw black pixel at (BX, CX)
                call put_pixel

                inc bp
                cmp bp, star_count

                jl echo_draw_loop

                inc si
                cmp si, star_count
                jl core_loop

                ; ----------------------------- AFTER DRAWING -----------------------------
                ; call wait_for_frame                             ; Chase beam and check if key pressed

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
star_count = 8

black_hole_radius = 4

target_x db 160
target_y db 100

; seeds
core_progress db 90, 32, 64, 96, 128, 160, 192, 224
