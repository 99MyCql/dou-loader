    section text
    bits 16
    org 7C00H
Begin:
    cld
    push cs
    pop ds
    mov si, hello
Lab1:
    lodsb ; 将si指向的一个字节，装入al中
    or al, al
    jz Lab2
    mov ah, 14
    int 10H ; 以TTY方式显示：在当前光标处显示字符，并后移光标，解释回车、换行、退格和响铃等控制符
    jmp short Lab1
Lab2:
    retf

hello db "Hello, world", 0DH, 0AH, 0