bits 64
default rel
global _start

section .data
    filename db "output/output.txt", 0
    filename_length equ $ - filename
    message db "Hello world!", 10
    message_length  equ $ - message
    err_creat_file db "Error creating file", 10
    err_creat_file_len equ $ - err_creat_file
    err_write_file db "Error writing to file", 10
    err_write_file_len equ $ - err_write_file
    err_close_file db "Error closing file", 10
    err_close_file_len equ $ - err_close_file

section .text
_start:
    ; Открыть или создать файл
    mov rax, 85                 ; 85 - системный вызов sys_creat
    mov rdi, filename
    mov rsi, 0o644              ; 6 - rw для роли owner (r = 4, w = 2, x = 1), 4 - read для остальных
    syscall

    mov rcx, err_creat_file
    mov r8, err_creat_file_len
    
    test rax, rax               ; eax and eax, выставляет SF флаг, если eax отрицательный
    js handle_error             ; jump if sign, провека на флаг знака

    mov rbx, rax                ; Системный вызов возвращает
                                ; дескриптор файла, сохраняем его в регистр rbx                                
    
    ; Запись в файл
    mov rax, 1
    mov rdi, rbx
    mov rsi, message
    mov rdx, message_length
    syscall

    mov rcx, err_write_file
    mov r8, err_write_file_len

    cmp rax, message_length     ; Выставляет флаг нуля (ZF), если left_operand == right_operand
    jnz handle_error            ; jump if not zero 

    ; Закрыть файл
    mov rax, 3                  ; 3 - системный вызов sys_close
    mov rdi, rbx                ; передаем в него файл дескриптор
    syscall

    mov rcx, err_close_file
    mov r8, err_close_file_len

    test rax, rax               
    js handle_error             ; А как проверять функции, которые возвращают
                                ; отрицательное число? Делать функцию, которая
                                ; будет возвращать явную константу на ошибку,
                                ; или есть способ лучше?
                                ; Ответ от преподавателя -> смотреть спецификацию стандарта.

    ; Выход
    mov rax, 60
    mov rdi, 0                  ; Возвращаем 0 при корректной работе
    syscall

handle_error:
    ; neg rax                   ; Почитал и это не согласутеся со стандартом, при
    ; mov rdi, rax              ; некорректном выполнении код завершения всегда = 1

    mov rax, 1
    mov rdi, 2                  ; stderr
    mov rsi, rcx                ; последний указатель на строку, который был помещен данный регистр
    mov rdx, r8                 ; длина последней строки
    syscall    

    mov rax, 60
    mov rdi, 1                  ; Возвращаем 1 при возникновении ошибки
    syscall
