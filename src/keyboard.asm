;--------------------
; @name: keyboard
; @description: 加载程序四。键盘中断，替换 INT 9 中断程序，用户输入F1-F9将出现不一样的现象
; @author: dounine
;--------------------

PORT_KEY_DAT	equ	60H
PORT_KET_STA	equ	64H
EnterScanCode	equ	1CH
F1ScanCode		equ	3BH
F9ScanCode		equ	43H

;--------- code ----------
	section text
	bits 16
	org 7C00H
Begin:
	push cs
	pop ds
	mov si, prompt
PrintPrompt:		; 打印提示信息
	lodsb
	or al, al
	jz SetNewInt
	call putChar
	jmp PrintPrompt
SetNewInt:
	mov si, 9*4		; 9号中断向量在0000:(9*4)处，负责处理键盘输入，并将字符存放在键盘缓冲区，用户程序则通过 INT 16H 获取缓冲区数据。
	push 0
	pop es			; 设置es为0
	mov eax, [es:si]
	push eax		; 保存原本的9号中断向量

	cli				; 关中断
	mov word [es:si], new_int_09H	; 新中断处理程序的偏移
	mov [es:si+2], cs				; 新中断处理程序的段值
	sti				; 开中断
GetChar:			; 测试
	mov ah, 0
	int 16H			; 获取键盘输入
	mov ah, 14
	int 10H			; 显示输入字符
	cmp al, 0DH
	je End
	jmp GetChar		; 非回车字符，则不返回
End:
	pop eax
	mov [es:si], eax	; 恢复9号中断向量
	mov al, 0AH
	mov ah, 14
	int 10H			; 输出换行
	retf

;------------------------------------
; new_int_09H: 新的 INT 09H 中断
;------------------------------------
new_int_09H:
	pusha				; 保存现场
	mov al, 0ADH
	out PORT_KET_STA, al; 向64H发送0ADH命令，禁止键盘发送数据
	in al, PORT_KEY_DAT	; 读取已接受的键盘数据

	sti					; 开中断
	call handle_key		; 调用按键处理程序
	cli					; 关中断

	mov al, 0AEH
	out PORT_KET_STA, al; 向64H发送0AEH命令，允许键盘发送数据
	mov al, 20H
	out 20H, al			; 通知中断控制器8259A，当前中断处理已经结束
	popa				; 恢复现场
	iret

;------------------------------------
; handle_key: 键盘扫描码处理
;	@use: ah, al, bl
;	@params:
;		al: 键盘扫描码
;------------------------------------
handle_key:
	push bx
	cmp al, EnterScanCode
	je press_enter		; 如果是回车，则保存并退出
	cmp al, F1ScanCode
	jb handle_key_ret
	cmp al, F9ScanCode
	ja handle_key_ret	; 不在F1-F9范围的都不考虑
	mov ah, al			; 保存扫描码
	sub al, 3AH-30H		; 转换成对应的ASCII码，如：F1->'1'
	call Enqueue		; 保存到缓冲区

	push ax
	mov al, 0DH
	call putChar
	mov al, 0AH
	call putChar
	pop ax

	mov bl, al
	sub bl, '1'
handle_key_for1:
	cmp bl, 0
	je handle_key_ret
	call putChar
	dec bl
	jmp handle_key_for1
press_enter:
	mov ah, al		; 保存扫描码
	mov al, 0DH		; 设置回车键的ASCII码
	call Enqueue	; 保存到键盘缓冲区
handle_key_ret:
	pop bx
	ret

;------------------------------------
; Enqueue: 保存键信息到键盘缓冲区
;	@params:
;		ax: ah，扫描码；al，ASCII码
;------------------------------------
Enqueue:
	push ds
	mov bx, 40H
	mov ds, bx		; 设置数据段为 0040H
	mov bx, [001CH]	; 取队尾指针
	mov si, bx
	add si, 2
	cmp si, 003EH	; 判断是否会超出缓冲区
	jb Enqueue_lab1
	mov si, 001EH
Enqueue_lab1:
	cmp si, [001AH]	; 与队头指针比较
	jz Enqueue_lab2
	mov [bx], ax	; 把扫描码和ASCii填入
	mov [001CH], si	; 保存队尾指针
Enqueue_lab2:
	pop ds
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

;----------data----------
prompt	db	"Something wonderful when pressing F0-F9.", 0DH, 0AH, "Of course, you can press Enter to return...", 0DH, 0AH, 0

;--------- MBR补充(做为加载程序时，忽略) ------------
times 510 - ($ - $$) db 0	; 填满512个字节，满足MBR的要求
db  55H, 0AAH				; MBR程序最后的标识