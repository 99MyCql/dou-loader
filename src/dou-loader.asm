;--------------------
; @name: dou-loader
; @description: 加载器/主引导记录(MBR)，可选择性加载多个工作程序
; @author: dounine
;--------------------

helloworld_LBA	equ	1
helloworld_len	equ	1
PROG_TEMP		equ 7C00H	; 存放工作程序的内存区地址偏移值

;--------- code ----------
    section text
    bits 16
Begin:
	mov ax, 0
    mov ss, ax		; 设置堆栈段的段值0000H
    mov sp, 7C00H 	; 设置堆栈的偏移，安排在 0000:7C00H处，栈从高往低
	mov ds, ax		; 源段值
	mov es, ax		; 目标段值
	mov si, 7C00H	; 源偏移
	mov di, 600H	; 目标偏移
	mov cx, 200H	; 数据块字节数 200H=512
	cld
	repz movsb		; 复制到目标地址
	push word 0060H
	push word PrintPrompt
	retf			; 跳转到 0060:PrintPrompt 处

PrintPrompt:			; 打印提示信息
	push cs
	pop ds
	mov si, prompt_msg
	call printStr
Next:
	call getDec			; 获取用户输入的选项
	mov di, ax
	dec di				; 减1
	cmp di, ProgCount
	jae Invaild			; 大于等于程序数则报错
	mov word [DiskAP+4], PROG_TEMP	; 设置加载程序存放的内存地址偏移值
	shl di, 2						; di=di*4
	mov si, [ProgInfo+di]
	mov [DiskAP+8], esi				; 设置加载程序的LBA地址
	mov di, [ProgInfo+di+2]			; 保存加载程序的长度
	jmp LoadProg
Invaild:				; 其它输入，则报错
	mov si, invaild_msg
	call printStr		; 打印错误信息
	jmp PrintPrompt
LoadProg:
	cmp di, 0
	je JmpProg
	mov si, DiskAP
	mov dl, 80H			; C盘
	mov ah, 42H			; 读功能
	int 13H				; 磁盘I/O中断
	jc ReadError		; 读失败，CF为1；读成功，CF为0
	dec di
	add word [DiskAP+4], 512	; 存放加载程序的目标地址偏移值 + 512
	add dword [DiskAP+8], 1		; 读取下一个扇区的目标程序剩余内容
	jmp LoadProg
ReadError:
	mov si, readErr_msg
	call printStr		; 打印读磁盘失败信息
	jmp PrintPrompt
JmpProg:
	call 0000:7C00H		; 跳转至工作程序入口地址
	jmp PrintPrompt

;------------------------------------
; getDec: 获取输入的一个十进制数字符串
;   @returns:
;       ax: 十进制数
;------------------------------------
getDec:
    push bx
    mov bx, 0 		; sum，最终数
    mov ax, 0
getDec_for1:
    call getChar

    cmp al, 0DH
    je getDec_enter	; 遇到回车进行相关处理

    cmp al, '0'
    jb getDec_for1
    cmp al, '9'
    ja getDec_for1 	; 输入必须0-9

    call putChar	; 显示输入的字符，0-9之间

    sub al, '0'
    imul bx, 10
    mov ah, 0
    add bx, ax		; sum = sum*10 + num
    jmp getDec_for1
getDec_enter:
    mov al, 0DH
	call putChar
	mov al, 0AH
    call putChar 	; 显示回车+换行
getDec_return:
    mov ax, bx
    pop bx
    ret

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
	call putChar
	jmp printStr_for
printStr_ret:
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

;------------------------------------
; putChar: 打印字符
;	@params:
;		al: ASCII码
;------------------------------------
putChar:
	mov ah, 14
	int 10H
	ret


;--------- data ----------
; 地址包
DiskAP:
    db  10H			; 地址包尺寸：16字节
    db  0
    dw  1			; 传输数据块个数(扇区个数)
    dw  PROG_TEMP	; 传输缓冲区起始地址偏移。即目标地址
    dw  0			; 传输缓冲区起始地址段值
    dd  0			; 工作程序的LBA地址，低4字节
    dd  0           ; 高4字节。即源地址

; 加载程序信息
ProgInfo:
	; 1.helloworld
	dw	1	; LBA
	dw	1	; 所占扇区数
	; 2.sum&diff
	dw	2	; LBA
	dw	1	; 所占扇区数
	; 3.clock
	dw	3	; LBA
	dw	1	; 所占扇区数

ProgCount	db	2 ; 加载程序数量
prompt_msg	db	0DH, 0AH, "Choose:", 0DH, 0AH, "1.helloworld", 0DH, 0AH, "2.sum&diff", 0DH, 0AH, "3.clock", 0DH, 0AH, 0DH, 0AH, "dou-loader > ", 0
invaild_msg	db	"Invaild choose...", 0DH, 0AH, 0
readErr_msg	db	"Reading disk error...", 0DH, 0AH, 0

;--------- MBR补充 ------------
times   510 - ($-$$)    db  0
db      55H, 0AAH