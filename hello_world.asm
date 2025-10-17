global _start

section .data
    message: db "Hello, World!", 10
    length equ $ - message    

section .text
_start:
    mov rax, 1
    mov rdi, 1
    mov rsi, message
    mov rdx, length
    syscall

    mov rax, 60
    syscall
