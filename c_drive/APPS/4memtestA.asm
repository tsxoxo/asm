org 100h

ret

; Initializes 4 bytes with value 0
; Makes the COM file 4 bytes larger.
foo db 4 dup (0)
