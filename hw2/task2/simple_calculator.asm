bits 64
default rel
global _start

section .data
    write_msg db "Write some string: ", 0
    write_msg_len  equ $ - write_msg
    reversed_msg db "Reversed: ", 0
    reversed_msg_len equ $ - reversed_msg
    err_empty_str db "Input should contain atleast one digit, please try again", 10
    err_empty_str_len equ $ - err_empty_str
    err_critical_problem db "Program encountered critical error during read_stdin, number conversion or write_stdout", 10
    err_critical_problem_len equ $ - err_critical_problem

section .bss
    input resb 1024             ; 1KB массив для входных данных
    first_number dq 0           ; 64bit переменная для хранения первого числа
    second_number dq 0          ; 64bit переменная для хранения второго числа
    output resb 1024            ; 1KB массив для выходных данных


section .text
_start:
    mov rbx, input                  ; Передаем указатель на массив, куда попадет исходная строка
    mov rcx, 1024                   ; Передаем размер этого массива
    call read_stdin                 ; Вызываем функцию чтения из stdin

    lea rax, [first_number]         ; Рассчитываем указатель на переменную
    mov rdi, input                  ; Передаем указатель на массив, содержащий число в виде строки
    mov rsi, rax                    ; Передаем указатель на переменную, куда запишем сконвертированное число
    
    call flip_string                ; Вызываем функцию "переворота" строки
    
    cmp r10, rax                    ; Проверяем, что "переворот" строки прошел успешно
    jnz exit_with_error

    mov rsi, reversed_msg           ; Выводим сообщение "Reversed: "
    mov rdx, reversed_msg_len
    call write_stdout

    mov rsi, reversed_str           ; Выводим полученную строку 
    mov rdx, r10
    call write_stdout

    jmp exit

; --- read_stdin ---
; @brief    Фукнция для чтения из stdin
; @param    rbx - указатель на массив, в который будут записаны данные
; @param    rcx - размер переданного массива
; @return   rax - размер записанных в массив данных
; @note     Аналог на Си: int read_stdin(char* input, size_t input_size)
; @note     Проверяет rax на содержание кода ошибки (отрицательное число) после
; @note     чтения из stdin
read_stdin:
    push rcx                        ; Сохранить rcx (rcx будет задействован в sys_write)
    mov rsi, write_msg              ; Выводим сообщение о необходимости ввести строку
    mov rdx, write_msg_len
    call write_stdout    
    pop rcx                         ; Восстановить rcx

    mov rax, 0                      ; 0 - sys_read
    mov rdi, 0                      ; 0 - stdin
    mov rsi, rbx                    ; передаем указатель на массив, в который попадут введенные данные
    mov rdx, rcx 
    syscall

    test rax, rax                   ; Проверка на корректное вовзращенное значение (>=0)
    js exit_with_error

    cmp byte [input], 0x0A          ; Проверка на строку, стостоящую только из перевода каретки 
    je empty_string_warning         ; Переход, если первый знак в input == 0x0A

    ret

; Сообщение о пустой строке
empty_string_warning:
    mov rsi, err_empty_str          ; Передаем указатель на строку с информацей об ошибке 
    mov rdx, err_empty_str_len      ; Передаем ее длину 
    call write_stdout               ; Вызываем функцию записи в stdout

    jmp read_stdin                  ; Повторяем попытку получить корректную строку от пользователя
; --- read_stdin ---

; --- flip_string ---
; @brief    Фукнция для "переворота" строки
; @param    rdi - указатель на массив исходных данных
; @param    rsi - указатель на массив, куда будет записана "перевенутая" строка
; @param    rdx - размер исходных данных
; @param    r9  - размер массива для записи данных (rsi)
; @return   rax - размер записанных в массив, переданный в rsi, данных
; @note     Аналог на Си: int flip_string(char* input, char* output, size_t input_size)
; @note     Если rdx < 1 возвращает код ошибки -1
; @note     Если размер исходных занных больше размера массива для записи
; @note     данных, возвращаемт код ошибки -2 

; Инициализация необходимых значений
stoi64:
    xor rdx, rdx

stoi64_loop:
    mov al, [rdi + rdx]             ; Получаем текущий знак 
    cmp al, 0                       ; al - младший байт регистра RAX, в данном случае необходим, так как данные длиной 1 байт 
    je stoi64_end    

    sub al, '0'
    mov rax, [rsi]
    mov rbx, 10
    mul rbx
    add qword [rsi], al
    inc rdx

    jmp stoi64_loop                 ; Повторяем, пока не обработаем все знаки

; Вставка перевода каретки в конец перевернутой строки
stoi64_end: 
    mov rax, [rsi]

    ret

exit_flip_string_with_error:
    mov rax, -1
    ret

exit_flip_string_overflow:
    mov rax, -2
    ret
; --- flip_string ---

; --- write_stdout ---
; @brief    Фукнция для записи в stdout
; @param    r9 - указатель на буфер, из которого будут извлечены данные
; @param    r10 - количество байт, которые необходимо записать в stdout
; @return   rax - размер записанных в stdout данных
; @note     Аналог на Си: int write_stdout(char* data, size_t input_size)
; @note     Проверяет rax на соответствие r9 после записи в stdout
write_stdout:
    mov rax, 1                      ; 1 - sys_write
    mov rdi, 1                      ; 1 - stdout
    syscall

    cmp rdx, rax                    ; Проверить, что все данные были записаны в stdout
    jnz exit_with_error
    ret
; --- write_stdout ---

; Выход
exit:
    mov rax, 60
    mov rdi, 0                  ; Возвращаем 0 при успешном завершении
    syscall

; Выход из программы с ошибкой
exit_with_error:
    mov rax, 1
    mov rdi, 2
    mov rsi, err_critical_problem
    mov rdx, err_critical_problem_len
    syscall

    mov rax, 60
    mov rdi, 1
    syscall
