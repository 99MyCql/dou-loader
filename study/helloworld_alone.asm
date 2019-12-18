;--------------------
; @name: helloworld_alone
; @description: 直接在裸机上运行，输出有颜色的helloworld字符串
; @author: dounine
;--------------------

	section text
	bits 16
	org 7C00H

Begin:
	push cs
	pop ds

	cld 			; 设df为0
	mov si, hello
	mov ch, 10
Lab1:
	mov bh, 0	; 显示页号
	mov dh, 5	; 行号
	mov dl, ch	; 列号
	mov ah, 2
	int 10H		; 将光标位置后移

	push cx

	lodsb			; 将si指向的一个字节，装入al中
	or al, al
	jz Lab2			; 检查是否到字符串结尾
	; mov ah, 14	; 以TTY方式显示：在当前光标处显示字符，并后移光标，解释回车、换行、退格和响铃等控制符
	mov bl, 0EH		; 字符属性
	mov cx, 1		; 字符重复次数
	mov ah, 9		; 将字符和属性写到光标位置处，光标不移动
	int 10H

	pop cx

	inc ch
	jmp short Lab1
Lab2:
	jmp Lab2

; hello db "Hello, world!", 0DH, 0AH, 0	; AH=14 INT=10 时，才会解释回车、换行等
hello db "Hello, world!", 0

times 510 - ($ - $$) db 0	; 填满512个字节，满足MBR的要求
db  55H, 0AAH				; MBR程序最后的标识