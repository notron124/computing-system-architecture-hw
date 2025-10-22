bits 64
default rel
global _start

section .data
    message db "Hello world!", 10
    message_length  equ $ - message
    err_msg db 10, "Error writing to stdout", 10 ; Если не добавить перевод
                                                 ; каретки в начале, эта строка сольется с частью "Hello world!" так при не нулевой
                                                 ; длине ее часть успее вывестись 
    err_msg_len equ $ - err_msg

section .text
_start:
    ; Запись в файл
    mov rax, 1
    mov rdi, 1
    mov rsi, message
    mov rdx, 1                ; Указываем неверную длину сообщения для возникновения ошибки
    syscall

    cmp rax, message_length     ; Выставляет флаг нуля (ZF), если left_operand == right_operand
    jnz handle_error            ; jump if not zero 

    ; Выход
    mov rax, 60
    mov rdi, 0                  ; Возвращаем 0 при успешном завершении
    syscall

handle_error:
    ; Вывод в stderr
    mov rax, 1
    mov rdi, 2
    mov rsi, err_msg
    mov rdx, err_msg_len
    syscall

    mov rax, 60
    mov rdi, 1
    syscall
