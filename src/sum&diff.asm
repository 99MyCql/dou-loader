;--------------------
; @name: sum&diff
; @description: 加载程序二。接收用户从键盘输入的两个十进制整数，然后计算并输出这两个数的和与差
; @author: dounine
;--------------------

%define SPACE 20H ; 空格
%define ENTER 0DH ; 回车

;--------- code ----------
	section text
	bits 16
	org 7C00H
Begin:
    cld
    push cs
    pop ds

    mov dx, prompt
    call printStr ; 打印提示信息
    call getDec
    mov [a], ax
    call getDec
    mov [b], ax
    ; prompt sum
    mov dx, sumStr
    call printStr
    ; 求和
    mov ax, [a]
    add ax, [b]
    call printDec
    ; 回车+换行
    mov dx, newline
    call printStr
    
    ; prompt diff
    mov dx, diffStr
    call printStr
    ; 求差
    mov ax, [a]
    cmp ax, [b]
    jle b_sub_a
    sub ax, [b]
    call printDec
    jmp over
b_sub_a:
    mov ax, [b]
    sub ax, [a]
    call printDec
over:
    ; 回车+换行
    mov dx, newline
    call printStr
    retf


;------------------------------------
; printDec: 将一个十进制数转换成字符串，并打印输出
;   @uses: bx, ax, di, si
;   @params:
;       ax: 十进制数
;------------------------------------
printDec:
    push bx
    mov si, 0 ; 十进制数的位数
; 先依次将个位、十位、百位等等取余出来，并压入栈中
printDec_for1:
    cmp ax, 0
    je printDec_for2
    mov dx, 0
    mov di, 10
    div di ; (dx:ax)/10 = ax...dx
    push dx ; 将余数入栈，先进后出。防止低位在前高位在后，实现输出反转！！！
    add si, 1 ; 十进制位数加一
    jmp printDec_for1
; 依次将高位到低位从栈中取出，并输出
printDec_for2:
    cmp si, 0
    je printDec_return
    pop dx
    add dl, '0'
    call putChar
    dec si
    jmp printDec_for2
printDec_return:
    pop bx
    ret

;------------------------------------
; getDec: 获取输入的一个十进制数
;   @returns:
;       ax: 十进制数
;------------------------------------
getDec:
    push bx
    mov bx, 0 ; sum，最终数
    mov ax, 0
getDec_for1:
    call getChar

    cmp al, ENTER
    je getDec_enter ; 遇到回车进行相关处理

    cmp al, SPACE
    je getDec_space ; 遇到空格进行相关处理

    cmp al, '0'
    jb getDec_for1
    cmp al, '9'
    ja getDec_for1 ; 输入必须0-9

    mov dl, al
    call putChar ; 显示输入的字符，0-9之间

    sub al, '0'
    imul bx, 10 ; sum = sum*10 + num
    mov ah, 0
    add bx, ax
    jmp getDec_for1
getDec_enter:
    mov dx, newline
    call printStr ; 显示回车+换行
    jmp getDec_return
getDec_space:
    mov dl, al
    call putChar ; 显示空格
getDec_return:
    mov ax, bx
    pop bx
    ret

;------------------------------------
; printStr: 打印字符串
;   @params:
;       dx: 字符串首地址
;------------------------------------
printStr:
    ; mov ah, 9
    ; int 21H
    ; ret
    push bx
    mov bx, dx
printStr_for1:
    mov dl, [bx]
    cmp dl, 0
    je printStr_return
    call putChar
    inc bx
    jmp printStr_for1
printStr_return:
    pop bx
    ret

;------------------------------------
; putChar: 打印字符
;   @uses: ah
;   @params:
;       dl: 字符的ASCII码值
;------------------------------------
putChar:
    mov al, dl
    mov ah, 14
    int 10H ; 以TTY方式显示
    ret

;------------------------------------
; getChar: 获取输入字符
;   @uses: ah
;   @returns:
;       al: 字符的ASCII码值
;------------------------------------
getChar:
    mov ah, 0
    int 16H ; 从键盘读取字符保存到al中
    ret

;----------data----------
prompt  db "please input two nums(please press Enter or Space to separate):", 0DH, 0AH, 0
a       dw 0
b       dw 0
sum     dw 0
diff    dw 0
sumStr  db "sum: ", 0
diffStr db "diff: ", 0
newline db 0DH, 0AH, 0

;--------- MBR补充(做为加载程序时，忽略) ------------
times   510 - ($-$$)    db  0
db      55H, 0AAH