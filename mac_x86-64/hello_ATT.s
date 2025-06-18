#================================================================ 
# ASM demo for Mac x86-64
# Using AT&T syntax
#
# Taken from:
# https://retrocoding.net/hello-world-in-x8664-assembly-on-linux-and-macos#heading-macos
#================================================================ 
# Instructions to run
# 
# > as -arch x86_64 hello_ATT.s -o hello_ATT.o 
# > ld -arch x86_64 -L /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib -lSystem -o hello_ATT hello_ATT.o
# > ./hello_ATT
#================================================================ 

.code64
.global _main
.static_data
msg: .ascii "Hello, World!\n"
.set msglen, (. - msg)
.text
_main:
    mov $0x2000004, %rax 
    mov $1, %rdi 
    lea msg(%rip), %rsi 
    mov $msglen, %rdx
    syscall 
    mov $0x2000001, %rax 
    xor %rdi, %rdi 
    syscall
