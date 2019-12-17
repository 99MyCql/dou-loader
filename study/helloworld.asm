;--------------------
; @name: helloworld
; @description: 工作程序一，由loader引导加载。helloworld
; @author: dounine
;--------------------

Length  dw  End     ; 工作程序的长度
Start   dw  Begin   ; 工作程序入口的偏移
Zoneseg dw  0900H   ; 期望内存区域的起始段值
Reserved dd 0       ; 保留

hello db "Hello, world", 0DH, 0AH, 0

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

End: