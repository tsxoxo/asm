; WORK IN PROGRESS
; Print out value of registers on screen

; store current videomode
mov ah,0fh	; read input mode
int 10h 	; store in al

;mov dl,al ; debug print stored in al
; wow that is not easy
;mov ax,200h ; comes out as ascii char but i wanna print hexv alue literally
;int 21h
push ax


; exit
; restore video mode
mov ah,0
pop ax
int 10h

mov ah,7	    ; Wait for key press
int 21h

int 20h
