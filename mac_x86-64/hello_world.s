#================================================================ 
# ASM demo for Mac x86-64
# Using Intel syntax.
#
# Taken from:
# https://zerodayarcade.com/tutorials/hello-world-assembly-macos
#================================================================ 
# Instructions to run
# 
# > as hello_world.s -o hello_world.o 
# > gcc -o hello_world hello_world.o -nostdlib -static
# > ./hello_world
#================================================================ 
.global start
.intel_syntax noprefix

start:
    # Write "Hello World"
    mov rax, 0x2000004                # system call 4 (write code)
    mov rdi, 1                        # STDOUT file descriptor
    lea rsi, hello_world[rip]         # buffer to print
    mov rdx, OFFSET msglen            # rdc == length of buffer
    syscall                           # envoke syscall

    # Exit program
    mov rax, 0x2000001                # system call 1 (exit code)
    mov rdi, 99                       # set the exit code to 99
    syscall

hello_world:                          # Definition of hello_world
    .asciz "Hello World\n"
    .set msglen, (. - hello_world)
