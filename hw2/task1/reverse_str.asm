bits 64
default rel
global _start

section .data
    write_msg db "Write some string: ", 0
    write_msg_len  equ $ - write_msg
    err_msg db "Error...", 10   ; Добавить краткое описание ошибок
    err_msg_len equ $ - err_msg

section .bss
    input resb 1024             ; 1KB буффер для входных данных
    reversed_str resb 1024      ; 1KB буффер для "перевенутой" строки

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

    test rax, rax               ; Проверка на корректное вовзращенное значение (>=0)
    js exit_with_error

    mov rbx, rax                ; Сохраняем длину строки
    mov rcx, rbx                ; Счетчик от конца строки
    dec rcx                     ; Игнорируем перевод каретки

    jmp flip_string

; Разворот строки
flip_string:
    dec rcx                      ; уменьшаем счетчик, который указывает на конец input
    js write_stdout              ; если он стал отрицательным, значит инвесия закончена - выходим

    mov al, [input + rcx]        ; Получаем последний знак на данный момент 
                                 ; al - младший байт регистра RAX, в данном случае необходим, так как данные длиной 1 байт 
    mov [reversed_str + r8], al  ; помещаем последний знак в начало rersed_str
    inc r8

    jmp flip_string              ; Повторяем, пока не обработаем все знаки

; Запись в stdout
write_stdout:
    mov al, 10
    mov [reversed_str + r8], al   ; Перевод каретки
    inc r8

    mov rax, 1                      ; 1 - sys_write
    mov rdi, 1                      ; 1 - stdout
    mov rsi, reversed_str           ; Передать указатель на reserved_str буффер
    mov rdx, r8                     ; Передать размер прочитанной строки
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
