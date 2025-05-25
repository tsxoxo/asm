; WORK IN PROGRESS
; bounce with a trail 

; STRATEGY
; add current position in array, up to 5
; foreach pos call plot_pixel with trail_colors[pos]

org 100h

; store current videomode
mov ah,0fh	; func 
int 10h 	; mode is stored in AL 
push ax

; set video mode 13
mov ah, 0 ; func
mov al, 13h ; arg: mode 13 -- 320x200, 256 colors
int 10h

; array counter
mov si, 0

main_loop:
  ; Calculate next positions in temp registers
  mov ax, [pos_x]
  add ax, [vel_x]     ; AL = next X
  mov bx, [pos_y] 
  add bx, [vel_y]     ; BL = next Y

  ; Check if out of bounds
  ; check_x
  cmp ax, 0
  jl bounce_x
  cmp ax, 319
  jg bounce_x
  jmp check_y
  bounce_x:
    neg word [vel_x]

  check_y:
    cmp bx, 0
    jl bounce_y
    cmp bx, 199
    jg bounce_y
    jmp no_bounce
  bounce_y:
    neg word [vel_y]

  no_bounce:
    ; Erase old position
    ; This will ahve to be adjusted to remove last piece of trail
    mov cx, [pos_x]     ; Current X
    mov dx, [pos_y]     ; Current Y
    ; need ax for drawing func and color
    push ax
    ; need bh for page num
    push bx
    mov bh,0
    mov al, 0           ; Black
    mov ah, 0ch
    int 10h
    pop bx
    pop ax

    ; Commit new positions
    mov [pos_x], ax     ; Store new X
    mov [pos_y], bx     ; Store new Y
    ; Store in array
    ; TODO: Shift elements in positions
    mov [positions + si*4], ax      ; Store X (lower 16 bits)
    mov [positions + si*4 + 2], bx  ; Store Y (upper 16 bits)
    inc si

    ; Draw new position
    mov cx, ax          ; New X  
    mov dx, bx          ; New Y
    mov al, 15          ; Color
    push bx
    mov bh,0
    mov ah, 0ch
    int 10h
    pop bx

    ; Check if key pressed (non-blocking)
    mov ah, 01h        ; Check keyboard status
    int 16h            ; BIOS keyboard interrupt
    jnz exit_loop    ; Jump if key available (zero flag clear)

    ; Simple delay loop
    mov di, 03FFFh    ; FRAMERATE
    anim_delay:
      nop               ; Do nothing (takes 1 CPU cycle)
      dec di
      jnz anim_delay
      jmp main_loop

exit_loop:
  ; clear screen by re-setting video mode
  mov ah, 0     
  mov al, 13h   
  int 10h       

  ; restore video mode
  pop ax
  mov ah,0
  int 10h

  int 20h ; exit

; DATA
; Pixel starting pos and velocity
pos_x: dw 0
pos_y: dw 0  
vel_x: dw 1
vel_y: dw 1

positions: times 5 dd 0
trail_colors db 20, 19, 18, 17, 16
num_trail db 5
