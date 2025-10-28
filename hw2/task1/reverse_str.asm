bits 64
default rel
global _start

section .data
    write_msg db "Write some string: ", 0
    write_msg_len  equ $ - write_msg
    err_empty_str db "String should contain at least one character, try again", 10   ; Добавить краткое описание ошибок
    err_empty_str_len equ $ - err_empty_str

section .bss
    input resb 1024             ; 1KB буффер для входных данных
    reversed_str resb 1024      ; 1KB буффер для "перевернутой" строки

section .text
_start:
    mov rbx, input
    mov rcx, 1024
    call read_stdin

    mov rdi, input                  ; Передаем указатель на массив, содержащий исходную строку
    mov rsi, reversed_str           ; Передаем указатель на массив, куда попадет перевернутая строка
    mov rdx, rax                    ; Передаем размер исходной строки
    
    mov r9, rax                     ; Сохраняем размер исходной строки

    call flip_string
    
    cmp r9, rax
    jnz exit_with_error

    mov rsi, reversed_str
    mov rdx, rax

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
; @return   rax - размер записанных в массив, переданный в rsi, данных
; @note     Аналог на Си: int flip_string(char* input, char* output, size_t input_size)
; @note     Проверяет, что rdx больше 1, иначе возвращает код ошибки -1

; Инициализация необходимых значений
flip_string:
    cmp rdx, 1                      ; Если размер переданных данных меньше 1
    jl exit_flip_string_with_error  ; выходим с ошибкой

    mov rcx, rdx                    ; Инициализируем счетчик, который будет указывать на текущий последний знак в строке
    dec rcx                         ; Пропускаем перевод каретки
    xor r9, r9                      ; обнуляем r9, так как будем исользовать
                                    ; его в качестве счетчика обработанный байт

; "Переворот" данных
flip_string_loop:
    dec rcx                         ; уменьшаем счетчик, который указывает на конец input
    js end_flip_string              ; если он стал отрицательным, значит инвесия закончена - выходим

    mov al, [rdi + rcx]             ; Получаем последний знак на данный момент 
                                    ; al - младший байт регистра RAX, в данном случае необходим, так как данные длиной 1 байт 
    mov [rsi + r9], al              ; помещаем последний знак в начало reversed_str
    inc r9

    jmp flip_string_loop            ; Повторяем, пока не обработаем все знаки

; Вставка перевода каретки в конец перевернутой строки
end_flip_string: 
    mov al, 10
    mov [reversed_str + r9], al     ; Перевод каретки
    inc r9

    mov rax, r9

    ret

exit_flip_string_with_error:
    mov rax, -1
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
    ; mov rax, 1
    ; mov rdi, 2
    ; mov rsi, err_msg
    ; mov rdx, err_msg_len
    ; syscall

    mov rax, 60
    mov rdi, 1
    syscall
