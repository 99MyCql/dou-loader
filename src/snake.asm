;--------------------
; @name: snake
; @description: 加载程序七。自创贪吃蛇程序
; @author: dounine
;--------------------

EnterKey		equ	0DH
UpKey			equ	77H
DownKey			equ	73H
LeftKey			equ	61H
RightKey		equ	64H
snake_len_max	equ	5H
snake_head_pat	equ	'O'
snake_node_pat	equ	'#'

;--------- code ----------
	section text
	bits 16
	org 7C00H
Begin:
	push cs
	pop ds
	call clearScreen	; 清屏
	mov si, welcome_msg
	mov dh, 10
	mov dl, 25
	call printStr		; 打印欢迎信息
GetChar1:
	call getChar		; 获取用户按键
	cmp al, EnterKey
	je SetNewInt		; 如果用户按下Enter则下一步，否则继续获取按键
	jmp GetChar1
SetNewInt:
	mov si, 1CH*4		; 1CH号中断向量在0000:(001CH*4)处
	push 0
	pop es				; 设置es为0
	cli					; 关中断
	mov ax, new_int_1CH
	mov [es:si], ax		; 设置中断程序的偏移地址
	mov ax, cs
	mov [es:si+2], ax	; 设置中断程序的段值
	sti					; 开中断
GetChar2:
	cmp byte [is_gameOver], 1
	je Exit				; 如果全局变量 is_gameOver 被设置成1，则直接退出
	call getChar		; 获取方向键，设置全局变量dir
	cmp al, UpKey
	je SetUp
	cmp al, DownKey
	je SetDown
	cmp al, LeftKey
	je SetLeft
	cmp al, RightKey
	je SetRight
	jmp GetChar2
SetUp:
	mov byte [dir], 0
	jmp GetChar2
SetDown:
	mov byte [dir], 2
	jmp GetChar2
SetLeft:
	mov byte [dir], 3
	jmp GetChar2
SetRight:
	mov byte [dir], 1
	jmp GetChar2
Exit:
	mov word [es:si], old_int_1CH	; 还原1CH号中断向量
    retf


;------------------------------------
; old_int_1CH: 旧的 INT 1CH 中断，只有一条返回指令。
;------------------------------------
old_int_1CH:
	iret

;------------------------------------
; new_int_1CH: 新的 INT 1CH 中断，由 INT 8 定时器中断调用，每过55ms触发一次 INT 8 。
;	当触发次数达到18次，即满1秒时，则在 INT 1CH 中调用贪吃蛇相关程序。
;------------------------------------
new_int_1CH:
	push ds
	push cs
	pop ds
	dec byte [count]		; 触发次数减一
	jnz new_int_1CH_ret		; 若不等于0，则直接退出
	mov al, byte [speed]	; 若等于0，则重新设值，并进入函数
	mov byte [count], al
	add word [score], 1
	sti				; 开中断
	pusha			; 保存现场
	mov si, score_msg
	mov dh, 1
	mov dl, 70
	call printStr	; 打印"score:"字符串
	mov ax, [score]
	call printDec	; 打印分数
	popa			; 恢复现场
new_int_1CH_ret:
	pop ds
	iret

;------------------------------------
; printStr: 在指定位置打印字符串
;   @params:
;       si: 字符串首地址
;		dh: 行号
;		dl: 列号
;------------------------------------
printStr:
	mov bh, 0
	mov ah, 2
	int 10H		; 设置光标位置
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
; printDec: 将一个十进制数转换成字符串，并打印输出
;   @uses: bx, ax, di, si
;   @params:
;       ax: 十进制数
;------------------------------------
printDec:
    push bx
	push dx
	push di
	push si

    mov si, 0		; 记录十进制数的位数
	cmp ax, 0
	jne printDec_for1
	add al, '0'
	call putChar	; 如果分数为0，则直接打印
	jmp printDec_return
printDec_for1:		; 先依次将个位、十位、百位等等取余出来，并压入栈中
    cmp ax, 0
    je printDec_for2
    mov dx, 0
    mov di, 10
    div di			; (dx:ax)/10 = ax...dx
    push dx			; 将余数入栈，先进后出。防止低位在前高位在后，实现输出反转！！！
    add si, 1		; 十进制位数加一
    jmp printDec_for1
printDec_for2:		; 依次将高位到低位从栈中取出，并输出
    cmp si, 0
    je printDec_return
    pop ax
    add al, '0'
    call putChar
    dec si
    jmp printDec_for2
printDec_return:
	pop si
	pop di
	pop dx
    pop bx
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

;------------------------------------
; clearScreen: 清屏
;------------------------------------
clearScreen:
    mov ax, 3H
    int 10H
    ret

;----------data----------
snake:
	; 蛇头
	db	5				; 行号
	db	10				; 列号
	db	1				; 方向。0上，1右，2下，3左
	db	snake_head_pat	; 蛇头图案
	; 蛇身第一个结点
	db	5
	db	9
	db	1
	db	snake_node_pat	; 结点图案
	; 蛇身第二个结点
	db	5
	db	8
	db	1
	db	snake_node_pat
	; 蛇身其它结点预留
	times	snake_len_max-3	dd	0

; 果实位置
fruit_pos:
	db	5	; 行号
	db	15	; 列号

snakeLen		db	3	; 初始为3
dir				db	0	; 方向
speed			db	30	; 前进速度。值越大速度越快，等于18时，1秒动一次
count			db	30	; 计数器
score			dw	0	; 分数
is_gameOver		db	0	; 游戏是否结束，0否，1是
welcome_msg		db	"Welcome to Snake Game!!! (Enter)", 0
gameOver_msg	db	"Game is over, play again? (y/n)", 0
score_msg		db	"score:", 0


;--------- MBR补充(做为加载程序时，忽略) ------------
times   510 - ($-$$)    db  0
db      55H, 0AAH