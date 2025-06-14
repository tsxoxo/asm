; Prints number to screen in binary
; Use carry flag and bit rotation
; From Norton's Guide to Assembler on PC

; setup
; org 100h
mov dx,0       
mov bx,00B7h	; number to print

rcl bl,1	; rotate carry left
adc dx,30h	; clever: 30 is ascii code for "0", 31h=="1". "adv" adds the carry flag so al will oscillate betwen 30 and 31h.

; print
mov ax,200h	; set up printing function
int 21h

mov ah,7	    ; Wait for key press
int 21h
int 20h
