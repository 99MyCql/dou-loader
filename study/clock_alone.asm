;--------------------
; @name: clock_alone
; @description: 直接在裸机上运行。每过一秒，则更新并输出时间信息
; @author: dounine
;--------------------

	section text
	bits 16
	org 7C00H
Begin:
	push cs
	pop ds
	mov si, prompt
Lab1:
	lodsb				; 将si指向的一个字节，装入al中
	or al, al
	jz Lab2
	call putChar
	jmp Lab1
Lab2:
	mov si, 1CH*4		; 1CH号中断向量在0000:001CH处
	push 0
	pop es				; 设置es为0
	mov eax, [es:si]
	push eax			; 保存原本的1CH号中断向量

	cli					; 关中断
	mov ax, new_int_1CH
	mov [es:si], ax		; 设置中断程序的偏移地址
	mov ax, cs
	mov [es:si+2], ax	; 设置中断程序的段值
	sti					; 开中断
Lab3:
	mov ah, 0
	int 16H
	cmp al, 'q'
	jne Lab3
	call putChar
	pop eax
	mov [es:si], eax
End:
	jmp End


;------------------------------------
; new_int_1CH: 新的 INT 1CH 中断，由 INT 8 定时器中断调用，每过55ms触发一次 INT 8 。
;	当触发次数达到18次，即满1秒时，则在 INT 1CH 中调用时间显示程序。
;------------------------------------
new_int_1CH:
	dec byte [cs:count]
	jnz new_int_1CH_ret
	mov byte [cs:count], 18
	sti				; 开中断
	pusha			; 保存现场
	call printTime
	popa			; 恢复现场
new_int_1CH_ret:
	iret

;------------------------------------
; printTime: 在右上角显示当前时间
;	@use: ah, al, bh, dh, dl
;------------------------------------
printTime:
	push ax
	push bx
	push dx

	mov bh, 0	; 页号
	mov ah, 3
	int 10H		; 获取当前光标位置
	push dx		; 保存行号列号

	mov dh, 1	; 行号
	mov dl, 70	; 列号
	mov ah, 2
	int 10H		; 设置光标位置于右上角

	mov al, 04H	; 时单元地址
	out 70H, al
	in al, 71H
	call printBCD
	mov al, ':'
	call putChar
	mov al, 2	; 分单元地址
	out 70H, al
	in al, 71H
	call printBCD
	mov al, ':'
	call putChar
	mov al, 0	; 秒单元地址
	out 70H, al
	in al, 71H
	call printBCD

	pop dx
	mov ah, 2
	int 10H		; 恢复原光标位置

	pop ax
	pop bx
	pop dx
	ret

;------------------------------------
; printDec: 将BCD码转换成字符串，并打印输出
;	@params:
;		al: BCD码
;------------------------------------
printBCD:
	push ax
	shr al, 4
	add al, '0'
	call putChar
	
	pop ax
	and al, 0FH
	add al, '0'
	call putChar
	ret

;------------------------------------
; putChar: 打印字符
;	@params:
;		al: ASCII码
;------------------------------------
putChar:
	mov ah, 14
	int 10H
	ret


prompt	db	"press q to quit...", 0DH, 0AH, 0
count	db	18	; 计数器，定时器中断触发(每55ms一次)一次则减一，直至为0后重新开始

times 510 - ($ - $$) db 0	; 填满512个字节，满足MBR的要求
db  55H, 0AAH				; MBR程序最后的标识