bits 64
default rel
global _start

section .data
    write_msg db "Write some string: ", 0
    write_msg_len  equ $ - write_msg
    err_msg db "Error reading stdin", 10
    err_msg_len equ $ - err_msg

section .bss
    input resb 1024        ; 1KB буффер для входных данных

section .text
_start:
    jmp read_stdin

; Чтение из stdin
read_stdin:
    mov rax, 0                  ; 0 - sys_read
    mov rdi, 0                  ; 0 - stdin
    mov rsi, input              ; передаем указатель на массив, в который попадут введенные данные
    mov rdx, 1024 
    syscall

    test rax, rax               ; Проверка на корректное вовзращенное значение
    js exit_with_error

    jmp echo_stdout

; Запись в stdout
echo_stdout:
    mov rdx, rax                ; Передать кол-во прочитанных байт в rdx для вывода
    mov rax, 1                  ; 1 - sys_write
    mov rdi, 1                  ; 1 - stdout
    mov rsi, input              ; Передать указатель на input буффер
    syscall

    cmp rdx, rax                ; Проверить, что все данные были записаны в stdout
    jnz exit_with_error
    
    jmp exit

; Выход
exit:
    mov rax, 60
    mov rdi, 0                  ; Возвращаем 0 при успешном завершении
    syscall

; Выход из программы с ошибкой
exit_with_error:
    mov rax, 1
    mov rdi, 2
    mov rsi, err_msg
    mov rdx, err_msg_len
    syscall

    mov rax, 60
    mov rdi, 1
    syscall
