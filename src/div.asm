;--------------------
; @name: div
; @description: 加载程序五。修改 INT 0 除法中断处理程序
; @author: dounine
;--------------------

;--------- code ----------
	section text
	bits 16
	org 7C00H
Begin:
    push cs
    pop ds

	mov si, 0*4		; 0号中断在0000:0000处
	mov ax, 0
	mov es, ax		; 设置es值为0
	mov eax, [es:si]
	push eax		; 保存原本的0号中断向量

	cli				; 关中断
	mov word [es:si], new_int_0H	; 设置新中断处理程序的偏移
	mov [es:si+2], cs				; 设置新中断处理程序的段值
	sti				; 开中断

    mov si, formula_msg
    call printStr

    mov ax, 1000
    mov bl, 1
    div bl          ; 测试0号中断
End:
    mov si, 0*4
	mov ax, 0
	mov es, ax
	pop eax
    mov [es:si], eax    ; 恢复0号中断向量
    retf

;------------------------------------
; new_int_0H: 新的 INT 0H 中断
;------------------------------------
new_int_0H:
    sti             ; 开中断
    pusha           ; 保护现场
    mov si, err_msg
    call printStr   ; 输出除0错误信息
    mov bp, sp
    add word [bp+16], 2 ; 将返回ip(pusha已经压了8个通用寄存器)加2，指向下一条指令(只适用于div bl，该指令长度为2)
    popa            ; 恢复现场
    iret


;------------------------------------
; printStr: 打印字符串
;   @params:
;       si: 字符串首地址
;------------------------------------
printStr:
	cld
printStr_for:
	lodsb			; 将si指向的一个字节，装入al中
	or al, al
	jz printStr_ret	; 检查字符串是否结束
	mov ah, 14
	int 10H
	jmp printStr_for
printStr_ret:
    ret

;----------data----------
formula_msg db  "ax(1000)/bl(1)=", 0DH, 0AH, 0
err_msg     db  "Divide overflow", 0DH, 0AH, 0

;--------- MBR补充(做为加载程序时，忽略) ------------
times 510 - ($ - $$) db 0	; 填满512个字节，满足MBR的要求
db  55H, 0AAH				; MBR程序最后的标识