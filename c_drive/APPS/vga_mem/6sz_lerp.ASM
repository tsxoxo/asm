; Sizecoding animation based on 6Lerp.asm

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
                cmp   bx, 320
                jae   skip_pixel
                cmp   cx, 200
                jae   skip_pixel

                mov dx, cx                                      ; copy Y to set up bitshift. avoids multiplication
                shl dx, 8                                       ; Y * 256
                shl cx, 6                                       ; Y * 64
                add cx, dx                                      ; CX = 256 + 64 = 320 * Y
                add cx, bx                                      ; AX = 320 * Y + X
                mov di, cx                                      ; set pointer to star position. AX can be discarded

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

; Calculate spawn position by mangling star index
; IN: DX == echo index, range 0-63
; OUT: BX == "random" X based purely on star index
get_spawn_x:
                mov bx, dx
                xor bx, 317                                     ; some constant. 317 == skewed grid
                ; xor bx, 293                                   ; alternative constant: sparse, sem-regular pairs
                rol bx, 3
                xor bh, bl
                and bx, 0FFh                                    ; clip to 0-255
                ret

; Calculate spawn position based on star index
; IN: DX == echo index
; OUT: CX == "random" Y based purely on star index
get_spawn_y:  
                mov cx, dx
                xor cl, 251                                     ; different constant
                rol cx, 5  
                and cx, 0FFh
                ret

; Calculate new XY based on spawnXY and progress value as well as distance to targetXY
; IN: DX == echo's progress (0-63), BP == echo's index (0-7)
; OUT: BX = X, CX = Y
calc_position:
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
; TODO: START HERE
; * write basic position lerp
; * lerp position based on size, giving a delayed/gravity effect

                ; call wait_retrace	; not sure if needed

                ; loop through 8 base stars
                xor si, si
core_erase_loop:                                                      

                mov bp, 0                                       ; draw the same star 8 times in different progress phase
echo_erase_loop:
                ; position = f(spawnPos, target, progress)
                ; color = f(progress)
                ;
                ; spawnPos = f(virtual SI (0-63))
                ; target = (160, 100)
                ; progress = VALUE_IN_MEM

                                                                ; Calculate virtual index
                mov dx, si                                      ; DX == 0-7
                shl dx, 3                                       ; DX == DX * 8 == 0-56
                add dx, bp                                      ; DX == 0-63

                                                                ; Get spawnXY based on virtual index in DX
                call get_spawn_x                                ; BX == spawn X
                call get_spawn_y                                ; CX == spawn Y

                                                                ; Calculate echo's progress
	; echo_progress = [core_progress + si] + (bp * 32)
                xor dh, dh
                mov dl, [core_progress + si]
                mov ax, bp                                      ; AX = echo number 0-7
                shl ax, 5                                       ; AX = AX  * 32 = range(0-224)
                add dx, ax                                      ; DX = echo_progress
                cmp dx, 255
                jbe progress_ok_erase
                mov dx, 255         ; Cap at 255
                progress_ok_erase:

                ; lerp X and store into BX
                ; X = spawnX + ((targetX - spawnX) * echo_progress) >> 8
                xor ah, ah
mov al, [target_x]
cmp al, bl          ; Compare target to spawn
ja target_greater_x_e ; Jump if target > spawn

; Target <= spawn (moving left)
sub bl, al          ; BL = spawn - target (positive!)
mul dl              ; progress * delta
mov al, ah          ; Shift result
sub bl, al          ; spawn - adjustment
jmp done_x_e

target_greater_x_e:
; Target > spawn (moving right)  
sub al, bl          ; AL = target - spawn (positive!)
mul dl              ; progress * delta
mov al, ah          ; Shift result
add bl, al          ; spawn + adjustment

done_x_e:
                ; Y -> CX
                xor ah, ah
mov al, [target_y]
cmp al, cl          ; Compare target to spawn
ja target_greater_y_e ; Jump if target > spawn

; Target <= spawn (moving left)
sub cl, al          ; BL = spawn - target (positive!)
mul dl              ; progress * delta
mov al, ah          ; Shift result
sub cl, al          ; spawn - adjustment
jmp done_y_e

target_greater_y_e:
; Target > spawn (moving right)  
sub al, cl          ; AL = target - spawn (positive!)
mul dl              ; progress * delta
mov al, ah          ; Shift result
add cl, al          ; spawn + adjustment

done_y_e:

                cmp bx, 320
                jb x_ok_e
                mov bx, 160     ; Force to center
                x_ok_e:
                cmp cx, 200
                jb y_ok_e  
                mov cx, 100     ; Force to center
                y_ok_e:

                mov al, 16                                      ; erase == draw black pixel at (BX, CX)
                call put_pixel

                inc bp
                cmp bp, 8
                jl echo_erase_loop

                mov dl, [core_progress + si]                    ; update core progress
                inc dl

	; progress = 255 == respawn star == reset progress 0
                cmp dl, 255                                     ; not sure if i need this -- overflow should take care of %255 right?
                jl dont_reset
                mov dl, 0
                dont_reset:

                mov [core_progress + si], dl

                inc si
                cmp si, 8
                jl core_erase_loop


                ; draw loop through 8 core stars
                xor si, si
core_draw_loop:                                                      

                mov bp, 0                                       ; draw the same star 8 times in different progress phase
echo_draw_loop:
                ; position = f(spawnPos, target, progress)
                ; color = f(progress)
                ;
                ; spawnPos = f(virtual SI (0-63))
                ; target = (160, 100)
                ; progress = VALUE_IN_MEM
                                                                ; Calculate virtual index
                mov dx, si                                      ; DX == 0-7
                shl dx, 3                                       ; DX == DX * 8 == 0-56
                add dx, bp                                      ; DX == 0-63

                                                                ; Get spawnXY based on virtual index in DX
                call get_spawn_x                                ; BX == spawn X
                call get_spawn_y                                ; CX == spawn Y

                                                                ; Calculate echo's progress
	; echo_progress = [core_progress + si] + (bp * 32)
                xor dh, dh
                mov dl, [core_progress + si]
                mov ax, bp                                      ; AX = echo number 0-7
                shl ax, 5                                       ; AX = AX  * 32 = range(0-224)
                add dx, ax                                      ; DX = echo_progress
                cmp dx, 255
                jbe progress_ok_draw
                mov dx, 255         ; Cap at 255
                progress_ok_draw:

                ; lerp X and store into BX
                ; X = spawnX + ((targetX - spawnX) * echo_progress) >> 8
                xor ah, ah
mov al, [target_x]
cmp al, bl          ; Compare target to spawn
ja target_greater_x ; Jump if target > spawn

; Target <= spawn (moving left)
sub bl, al          ; BL = spawn - target (positive!)
mul dl              ; progress * delta
mov al, ah          ; Shift result
sub bl, al          ; spawn - adjustment
jmp done_x

target_greater_x:
; Target > spawn (moving right)  
sub al, bl          ; AL = target - spawn (positive!)
mul dl              ; progress * delta
mov al, ah          ; Shift result
add bl, al          ; spawn + adjustment

done_x:
                ; Y -> CX
                xor ah, ah
mov al, [target_y]
cmp al, cl          ; Compare target to spawn
ja target_greater_y ; Jump if target > spawn

; Target <= spawn (moving left)
sub cl, al          ; BL = spawn - target (positive!)
mul dl              ; progress * delta
mov al, ah          ; Shift result
sub cl, al          ; spawn - adjustment
jmp done_y

target_greater_y:
; Target > spawn (moving right)  
sub al, cl          ; AL = target - spawn (positive!)
mul dl              ; progress * delta
mov al, ah          ; Shift result
add cl, al          ; spawn + adjustment

done_y:
                
                cmp bx, 320
                jb x_ok
                mov bx, 160     ; Force to center
                x_ok:
                cmp cx, 200
                jb y_ok  
                mov cx, 100     ; Force to center
                y_ok:

                mov al, 31                                      ; draw == draw white pixel at (BX, CX)
                call put_pixel

                inc bp
                cmp bp, 8
                jl echo_draw_loop

                inc si
                cmp si, 8
                jl core_draw_loop

                call wait_for_frame                             ; Chase beam and check if key pressed

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
animation_speed = 3                                            ; higher number == slower framerate           

black_hole_radius = 4

target_x db 160
target_y db 100

; seeds
core_progress db 0, 32, 64, 96, 128, 160, 192, 224
