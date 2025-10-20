bits 64
default rel
global _start

section .data
    filename db "../output/output.txt", 0
    filename_length equ $ - filename
    message db "Hello world!", 10
    message_length  equ $ - message

section .text
_start:
    ; Открыть или создать файл
    mov rax, 85                 ; 85 - системный вызов sys_creat
    mov rdi, filename
    mov rsi, 0o644              ; 6 - rw для роли owner (r = 4, w = 2, x = 1), 4 - read для остальных
    syscall
    
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

    test rax, rax               
    js handle_error

    ; Закрыть файл
    mov rax, 3                  ; 3 - системный вызов sys_close
    mov rdi, rbx                ; передаем в него файл дескриптор
    syscall

    test rax, rax               
    js handle_error             ; А как проверять функции, которые возвращают
                                ; отрицательное число? Делать функцию, которая
                                ; будет возвращать явную константу на ошибку,
                                ; или есть способ лучше?

    ; Выход
    mov rax, 60
    mov rdi, 0
    syscall

; На C я бы сделал текстовый вывод под каждую ошибку, если успею, то сделаю и
; тут. (Прим. "Failed to open/create *file_name*, errno: %d")
handle_error:
    neg rax
    mov rdi, rax
    mov rax, 60
    syscall
