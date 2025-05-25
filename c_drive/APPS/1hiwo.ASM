; Hello World program for FASM in DOS

org 100h	; COM file format starts at offset 100h

mov  ah, 9	    ; DOS function 9: print string
mov  dx, hello_msg  ; DX points to string
int  21h	    ; Call DOS interrupt

mov ah,7	    ; Wait for key press
int 21h

mov  ax, 4C00h	    ; DOS function 4C: terminate program
int  21h

; DATA
; 'b' in db stands for byte
hello_msg db 'Hello, World!$'  ; String with $ terminator for DOS
