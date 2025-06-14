; ================================= 
; Dump hex values of AX, BX, CX, DX
; ================================= 
; Inspired by Norton's guide to Assembler on PC

org 100h
jmp main

print_single_hex_char:
; IN: DX == single char to print (should have value 0-15)
; OUT: "F"
                push ax
                add dx, 30h
                cmp dx, 39h
                jle is_not_A_to_F
                add dx, 7

is_not_A_to_F:
                mov ah, 2                                       ; Printing function for int 21
                int 21h                                         ; print

                pop ax
                ret

print_reg:
; Print the hex representaion of the value of a 16-bit register
; IN:   AX == register to print
; OUT:  "FFFF"
                push cx
                push dx

                mov cx, 4
                process_nibble:
                rol ax, 4                                       ; rotate high 4 bits, so that they become low 4 bits
                mov dx, ax                                      ; copy to clean register
                and dx, 0Fh                                     ; only keep lower 4 bits == a single hex char
                call print_single_hex_char
                loop process_nibble                             ; after 4 rotations, a 16-bit reg is back to initial state

                pop dx
                pop cx
                ret

print_label_and_reg:
; Print reg label and hex value
; IN:   AX == reg to print
;       DX == ptr to label string
; OUT:  "AX: FFFF"
                ; print label in DX
                push ax
                mov ah, 9
                int 21h
                pop ax

                ; print reg in AX
                call print_reg

                ; print space
                push ax
                mov dx, space
                mov ah, 9
                int 21h
                pop ax

                ret

print_all:
                mov ax, 0aFFFh                                  ; print AX
                mov dx, AX_label
                call print_label_and_reg

                mov bx, 0bFFFh                                  ; print BX 
                mov ax, bx
                mov dx, BX_label
                call print_label_and_reg

                mov cx, 0cFFFh                                  ; print CX 
                mov ax, cx
                mov dx, CX_label
                call print_label_and_reg

                mov dx, 0dFFFh                                  ; print DX 
                mov ax, dx
                mov dx, DX_label
                call print_label_and_reg

                ret

main: 
                call print_all

                int 20h                                         ; exit

; DATA
AX_label db "AX: $"
BX_label db "BX: $"
CX_label db "CX: $"
DX_label db "DX: $"
space db "    $"

