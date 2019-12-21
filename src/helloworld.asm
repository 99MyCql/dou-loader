;--------------------
; @name: helloworld
; @description: 加载程序一，由loader引导加载。以TTY方式输出helloworld，和输出有颜色的helloworld
; @author: dounine
;--------------------

;--------- code ----------
	section text
	bits 16
	org 7C00H
Begin:
	push cs
	pop ds

	cld
    mov si, hello1
Lab1:
    lodsb			; 将si指向的一个字节，装入al中
    or al, al
    jz Lab2
    mov ah, 14		; 以TTY方式显示：在当前光标处显示字符，并后移光标，解释回车、换行、退格和响铃等控制符
    int 10H
    jmp short Lab1

Lab2:
	mov bh, 0
	mov ah, 3		; 读光标位置。返回ch=光标开始行，cl=光标结束行，dh=行号，dl=列号
	int 10H
	mov si, hello2
Lab3:
	lodsb
	or al, al
	jz Exit
	mov bl, 0EH		; 字符属性。0EH 表示黑底黄字
	mov cx, 1		; 字符重复次数
	mov ah, 9		; 将字符和属性写到光标位置处，光标不移动
	int 10H

	inc dl
	mov ah, 2		; 置光标于下一个位置
	int 10H
	jmp Lab3
Exit:
	mov al, 0AH
	mov ah, 14
    int 10H			; 换行
    retf

;----------data----------
hello1 db "Hello, world!", 0DH, 0AH, 0	; AH=14 INT=10 时，才会解释回车、换行等
hello2 db "Hello, world!", 0			; AH=9 INT=10 时，使用

;--------- MBR补充(做为加载程序时，忽略) ------------
times   510 - ($-$$)    db  0
db      55H, 0AAH
