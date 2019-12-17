;--------------------
; @name: loader
; @description: 参考书本设计的主引导记录(MBR)：可引导多个程序，程序可任意入口地址，并可加载到程序指定的内存位置
; @author: dounine
;--------------------

Length      equ 0 ; 工作程序的长度字段偏移
Start       equ 2 ; 工作程序的入口地址字段偏移
Zoneseg     equ 4 ; 工作程序的指定内存加载地址字段偏移
ZONELOW     equ 1000H   ; 工作程序使用内存区域的段值
ZONEHIGH    equ 9000H   ; 工作程序使用内存区段值上限
ZONETEMP    equ 07E0H   ; 存放读取的工作程序的缓冲区的地址段值

    section text
    bits 16
    org 7C00H
Begin:
    mov ax, 0
    cli
    mov ss, ax
    mov sp, 7C00H ; 设置堆栈安排在 07C0:0000H
    sti

Lab1:
    cld
    push cs
    pop ds
    mov ax, ZONETEMP
    mov word [DiskAP+6], ax ; 填写DAP中的缓冲区起始地址段值字段
    mov es, ax ;

    mov dx, prompt_msg
    call PutStr
    call GetSecAdr ; 获取用户输入的工作程序起始LBA地址
    or eax, eax
    jz Over ; 如果用户输入为0，则结束

    mov [DiskAP+8], eax ; 将工作程序的LBA地址，填写到DAP中的LBA低4字节字段
    call ReadSec ; 读取工作程序到缓冲区
    jc Lab7

    mov cx, [es:Length] ; 获取工作程序长度
    cmp cx, 0
    jz Lab6 ; 不能为0
    add cx, 511
    shr cx, 9 ; (length+511)/512 = 需要读取的扇区数

    mov ax, [es:Zoneseg] ; 取得工作程序期望的内存段值
    ; 期望的内存段值必须在规定范围
    cmp ax, ZONELOW
    jb Lab2
    cmp ax, ZONEHIGH
    jb Lab3
Lab2:
    mov ax, ZONELOW ; 如果超出范围，则取下限
Lab3:
    mov word [DiskAP+6], ax ; 设置DAP中的缓冲区段值

    mov es, ax ; 保存工作期望的内存段值到es
    xor di, di ; 准备复制已经在内存中的首个扇区
    push ds
    push ZONETEMP
    pop ds
    xor si, si
    push cx ; cx含有工作程序的扇区数
    mov cx, 128
    rep movsd ; 复制128个双字
    pop cx
    pop ds

    dec cx
    jz Lab5
Lab4:
    add word [DiskAP+6], 20H
    inc dword [DiskAP+8]
    call ReadSec
    jc Lab7
    loop Lab4

Lab5:
    mov [es:Start+2], es ; 设置工作程序入口点的段值
    call far [es:Start]
    push cs
    pop ds
    mov dx, over_msg
    call PutStr
    jmp Lab1 ; 准备加载下一个工作程序

Lab6:
    mov dx, invaild_msg
    call PutStr
    jmp Lab1
Lab7:
    mov dx, read_msg
    call PutStr
    jmp Lab1
Over:
    mov dx, halt_msg
    call PutStr
Halt:
    hlt
    jmp short Halt

;---------子程序-------
ReadSec:
    push dx
    push si
    mov si, DiskAP
    mov dl, 80H
    mov ah, 42H
    int 13H
    pop si
    pop dx
    ret

GetSecAdr:
    mov dx, buffer
    call GetDStr
    mov al, 0DH
    call PutChar
    mov al, 0AH
    call PutChar
    mov si, buffer+1
    call DSTOB
    ret

DSTOB:
    xor eax, eax
    xor edx, edx
.next:
    lodsb
    cmp al, 0DH
    jz .ok
    and al, 0FH
    imul edx, 10
    add edx, eax
    jmp short .next
.ok:
    mov eax, edx
    ret

GetDStr:
    push si
    mov si, dx
    mov cl, [si]
    cmp cl, 1
    jb .lab6

    inc si
    xor ch, ch
.lab1:
    call GetChar
    or al, al
    jz short .lab1
    cmp al, 0DH
    je short .lab5 ; 若为回车，则结束输入
    cmp al, '0'
    jb short .lab1
    cmp al, '9'
    ja short .lab1
    cmp cl, 1
    ja short .lab3 ; 检查字符串缓冲区空间是否有余，若是则转字符串处理
.lab3:
    call PutChar
    mov [si], al
    inc si
    inc ch ; 字符计数
    dec cl ; 剩余空间计数
    jmp short .lab1
.lab5:
    mov [si], al
.lab6:
    pop si
    ret

PutChar:
    mov bh, 0
    mov ah, 14
    int 10H
    ret

GetChar:
    mov ah, 0
    int 16H
    ret

PutStr:
    mov bh, 0
    mov si, dx
.lab1:
    lodsb
    or al, al
    jz .lab2
    mov ah, 14
    int 10H
    jmp .lab1
.lab2:
    ret


;--------- data ----------
; 地址包
DiskAP:
    db  10H         ; 地址包尺寸：16字节
    db  0
    dw  1           ; 传输数据块个数(扇区个数)
    dw  0           ; 传输缓冲区起始地址(段值:偏移)，小于1MB。即目标地址
    dw  ZONETEMP
    dd  0
    dd  0           ; 磁盘起始绝对块地址(LBA地址)，8字节。即源地址

; 缓冲区
buffer:
    db  9           ; 缓冲区大小
    db  "123456789"

prompt_msg    db  "Input sector address:", 0
invaild_msg    db  "Invaild code...", 0DH, 0AH, 0
read_msg    db  "Reading disk error...", 0DH, 0AH, 0
halt_msg    db  "Halt...", 0
over_msg    db  "Subprocedure over...", 0DH, 0AH, 0

;--------- MBR补充 ------------
times   510 - ($-$$)    db  0
db      55H, 0AAH