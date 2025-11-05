bits 64
default rel
global _start

section .data
    char_to_print db 0
    write1_msg db "Write first number: ", 0
    write1_msg_len  equ $ - write1_msg
    write2_msg db "Write second number: ", 0
    write2_msg_len equ $ - write2_msg
    plus_msg db " + ", 0
    plus_msg_len equ $ - plus_msg
    equals_msg db " = ", 0
    equals_msg_len equ $ - equals_msg
    err_empty_str db "Input should contain atleast one digit, please try again", 10
    err_empty_str_len equ $ - err_empty_str
    err_wrong_char db " is not a decimal digit, try again", 10
    err_wrong_char_len equ $ - err_wrong_char
    err_critical_problem db "Program encountered critical error during read_stdin, number conversion, summ or write_stdout", 10
    err_critical_problem_len equ $ - err_critical_problem

section .bss
    input resb      1024           ; 1KB массив для входных данных
    first_number    dq      0      ; 64bit переменная для хранения первого числа
    second_number   dq      0      ; 64bit переменная для хранения второго числа
    sum             dq      0      ; 64bit переменная для суммы двух чисел
    output resb     1024           ; 1KB массив для выходных данных

section .text
_start:
    mov rsi, write1_msg             ; Выводим сообщение о необходимости ввести число
    mov rdx, write1_msg_len
    call write_stdout    

    mov rbx, input                  ; Передаем указатель на массив, куда попадет исходная строка
    mov rcx, 1024                   ; Передаем размер этого массива
    call read_stdin                 ; Вызываем функцию чтения из stdin

    mov rdi, input                  ; Передаем указатель на массив, содержащий число в виде строки
    
    call stoi64                     ; Вызываем функцию "переворота" строки

    mov [first_number], rax         ; Сохраняем первое число в переменную

    mov rsi, write2_msg             ; Выводим сообщение о необходимости ввести второе число
    mov rdx, write2_msg_len
    call write_stdout

    mov rbx, input                  ; Читаем второе число
    mov rcx, 1024
    call read_stdin

    mov rdi, input                  ; Конвертируем второе число
    call stoi64

    mov [second_number], rax        ; Сохраняем его

    mov rdi, [first_number]         ; Передаем первое число в функцию сложения
    mov rsi, [second_number]        ; Передаем второе число в функцию сложения

    call sum_of_two                 ; Вызываем функцию складывания

    mov [sum], rax
    
    mov rdi, [first_number]         ; Передаем значение переменной
    mov rsi, output                 ; Передаем указатель на массив, куда попадет строка 
    mov rdx, 1024                   ; Длина переданного массива для проверки на overflow
    call itos64

    test rax, rax                   ; Проверка на отсутствие ошибки
    js exit_with_error

    mov rsi, output                 ; Выводим первое число
    mov rdx, rax
    call write_stdout

    mov rsi, plus_msg               ; Выводим знак +
    mov rdx, plus_msg_len
    call write_stdout

    mov rdi, [second_number]        ; Конвертируем второе число в строку
    mov rsi, output
    mov rdx, 1024
    call itos64

    test rax, rax                   ; Проверяем на отсутствие ошибки
    js exit_with_error

    mov rsi, output                 ; Выводим второе число
    mov rdx, rax
    call write_stdout

    mov rsi, equals_msg             ; Выводим знак =
    mov rdx, equals_msg_len
    call write_stdout

    mov rdi, [sum]                  ; Конвертируем результат сложения
    mov rsi, output
    mov rdx, 1024
    call itos64
    
    test rax, rax                   ; Проверяем на отсутствие ошибки
    js exit_with_error
    
    mov rsi, output                 ; Выводим сумму
    mov rdx, rax
    call write_stdout

    mov byte [char_to_print], 10    ; Перевод каретки
    mov rsi, char_to_print
    mov rdx, 1
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

    jmp _start                  ; Повторяем попытку получить корректную строку от пользователя
; --- read_stdin ---

; --- stoi64 ---
; @brief    Фукнция для "переворота" строки
; @param    rdi - указатель на массив исходных данных
; @return   rax - строка переведенная в число
; @note     Аналог на Си: int stoi64(char* input)
; @note     Если в процессе парсинка встретилась не цифра, сообщает об этом и
; @note     возвращается к старту

; Инициализация необходимых значений
stoi64:
    xor rax, rax
    xor r8, r8
    xor r9, r9
    
    mov cl, [rdi + r8]              ; Проверяем первый знак на наличие '-' 
    cmp cl, '-'
    je stoi64_neg                  ; Переходим к конвертации отрицательного числа 

stoi64_loop:
    mov cl, [rdi + r8]              ; Получаем текущий знак 
                                    ; cl - младший байт регистра RAX, в данном случае необходим, так как данные длиной 1 байт  

    cmp cl, 10                      ; Проверяем на перевод каретки или нуль-терминатор
    jle stoi64_end    
    
    ; Проверяем, что обрабатываем цифру, а не какой-либо другой знак
    cmp cl, '0'                     
    jl stoi64_err_exit    
    cmp cl, '9'
    ja stoi64_err_exit

    sub cl, '0'                     ; Вычитаем '0' (в utf-8 = 32) из знака для получения "цифры"
    mov rbx, 10                     ; Не заполняем rax, так как он и так используется в качестве 
                                    ; первого операнда mul и будет хранить результат нашей конвертации
    mul rbx                         ; rax * 10

    movzx rcx, cl                   ; Расширить 8 бит до 64-х
    
    add rax, rcx
    inc r8

    jmp stoi64_loop                 ; Повторяем, пока не обработаем все знаки

stoi64_neg:
    mov r9, -1
    inc r8
    jmp stoi64_loop

; Для отладки на данный момент
stoi64_end:
    test r9, r9
    js stoi64_neg_end
 
    ret

stoi64_neg_end:
    neg rax
    ret

; Вот и функция, которая может вернуть отрицательное число, при этом желательно
; сделать возврат ошибок. Согласно стандарту, функции должны возвращать
; коды ошибок отрицательным числом, так как быть в данном случае?
; Какое бы число я в данном случае не вернул, оно может интерпретироваться
; по-разному. Как ошибка и как число. 
; Единственный вариант решения, который я вижу, это передача 
; указателя на переменную, в которую напрямую будет
; записываться результат конвертации, а возвращаемое значение функции всегда
; будет кодом ошибки. (На С сделал бы именно так)
; Если успею реализую данный функционал.
stoi64_err_exit:
    mov [char_to_print], cl    
    mov rsi, char_to_print
    mov rdx, 1
    call write_stdout    

    mov rsi, err_wrong_char
    mov rdx, err_wrong_char_len
    call write_stdout
    jmp _start

; --- stoi64 ---


; --- itos64 ---
; @brief    Фукнция для конвертации int64 в string
; @param    rdi - значение переменной для конвертации
; @param    rsi - указатель на массив, куда попадут сконвертированные данные
; @param    rdx - размер переданного в rsi массива
; @return   rax - количество байт, записанных в rsi
; @note     Аналог на Си: int itos64(int num, char* out_bif, size_t buf_size)
; @note     Если в процессе парсинга происходит выход за границы массива,
; @note     возвращает -1
itos64:
    xor rax, rax
    mov r8, rdx             ; Сохранить размер переданного буфера, так как в операции div rdx будет перезаписан
    xor r9, r9    
    xor r10, r10

    cmp rdi, 0              ; Если встретили 0, добавляем его в стэк, пропуская цикл
    jz itos64_zero

    test rdi, rdi
    js itos64_neg    
    
itos64_loop:
    cmp rdi, 0              ; Если обработали все число - выходим
    jz itos64_fill_output   ; Если просто выйти, то в output окажется перевернутое число, 
                            ; так как число мы обрабатываем от младшего к
                            ; старшему.
        
    mov rax, rdi            ; Младшая часть делимого
    xor rdx, rdx            ; Согласно ТЗ ограничение -32768..32768, так что старшей части никогда не будет
    mov rcx, 10             ; Делим на 10, rax будет содержать результат целочисленного деления
                            ; rdx будет содержать остаток от деления
    div rcx
    
    mov rdi, rax            ; Переносим результат деления в rdi для дальнейшей обработки
    add dl, '0'             ; добавляем '0' для превращения в знак
    movzx rdx, dl 
    push rdx
    inc r9

    cmp r9, r8              ; Проверяем на overflow
    ja itos64_exit_err
    
    jmp itos64_loop 

itos64_zero:
    xor rdx, rdx
    add dl, '0'
    movzx rdx, dl
    push rdx
    inc r9

itos64_fill_output:
    xor rcx, rcx           ; Если число отрицательное, запись начнется с индекса 1
    
    test r10, r10               ; Проверка на наличие знака у числа
    jz itos64_fill_output_loop
    mov byte [rsi], '-'
    mov rcx, 1

itos64_fill_output_loop:
    cmp rcx, r9            ; До этого мы запсали в r11 единицу, если число было отрицательным. Данная проверка выйден на единицу раньше и не перезапишет '-'.
    je itos64_end    

    pop rdx
    mov byte [rsi + rcx], dl
    inc rcx
   
    cmp rcx, r8              ; Проверяем на overflow
    ja itos64_exit_err
    
    jmp itos64_fill_output_loop

; Вернуть кол-во записанных в массив байт    
itos64_end:
    mov byte [rsi + rcx], 0
    inc rcx

    mov rax, rcx
    ret

itos64_neg:
    mov r10, 1
    neg rdi
    inc r9
    jmp itos64_loop

itos64_exit_err:
    mov rax, -1
    ret

; --- itos64 ---

; --- sum ---
; @brief    Фукнция для суммы двух чисел
; @param    rdi - первое число
; @param    rsi - второе число
; @return   rax - результат суммы
sum_of_two:
    mov rax, rdi
    add rax, rsi
    ret
; --- sum ---

; --- write_stdout ---
; @brief    Фукнция для записи в stdout
; @param    rsi - указатель на буфер, из которого будут извлечены данные
; @param    rdx - количество байт, которые необходимо записать в stdout
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
