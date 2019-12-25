;--------------------
; @name: dou-snake
; @description: 加载程序七。自创贪吃蛇程序
; @author: dounine
;--------------------

EnterKey		equ	0DH
EscKey			equ	1BH
UpKey			equ	77H	; 'w'
DownKey			equ	73H	; 's'
LeftKey			equ	61H	; 'a'
RightKey		equ	64H	; 'd'
snake_len_max	equ	50H	; snake的最大长度
snake_head_pat	equ	0E9H
snake_node_pat	equ	'*'
fruit_pat		equ	'#'
score_row		equ	1	; 分数显示的行号
score_col		equ	70	; 分数显示的列号
speed_min		equ	5	; 越小越快
color			equ	0EH	; 颜色

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
	je Over				; 如果全局变量 is_gameOver==1，则直接退出
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
SetRight:
	mov byte [dir], 1
	jmp GetChar2
SetDown:
	mov byte [dir], 2
	jmp GetChar2
SetLeft:
	mov byte [dir], 3
	jmp GetChar2
Over:					; 游戏结束
	push 0
	pop es
	mov si, 01CH
	mov word [es:si], old_int_1CH	; 还原1CH号中断向量
GetChar3:
	; call getChar		; GetChar2中已经获取了用户按键
	cmp al, EscKey
	je Exit				; 如果用户按下Esc则结束，否则继续获取按键
	call getChar
	jmp GetChar3
Exit:
	call clearScreen	; 清屏
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
	pusha					; 保存现场
	push cs
	pop ds					; 设置数据段为代码段段值，为了能够找到数据位置
	cmp byte [is_gameOver], 1
	je new_int_1CH_ret		; 如果游戏已经结束
	dec byte [count]		; 触发次数减一
	jnz new_int_1CH_ret		; 若不等于0，则直接退出
	mov al, byte [speed]	; 若等于0，则重新设值，并进入函数
	mov byte [count], al

	sti						; 开中断
	call clearScreen		; 清屏
	call fruitShow			; 显示果子
	call scoreShow			; 显示分数

	call snakeMove			; snake前进
	call snakeShow			; 显示snake

	call snakeCheck			; 判断snake是否撞墙或撞自己了
	cmp al, 0
	je new_int_1CH_next		; 如果 al==0 ，则游戏未结束，继续下一步

	mov byte [is_gameOver], al		; 设置全局变量 is_gameOver=1，告诉主程序游戏结束
	call clearScreen		; 清屏
	mov dh, 10
	mov dl, 25
	mov si, gameOver_msg
	call printStr			; 打印游戏结束信息
	jmp new_int_1CH_ret
new_int_1CH_next:
	call isEatFruit			; 判断snake是否吃到果子，返回al
	cmp al, 0
	je new_int_1CH_ret		; 如果 al==0 ，则没吃到果子，直接退出

	call snakeAdd			; 如果吃到了果子，snake长度++
	inc word [score]		; 分数++
	call speedAdd			; 速度++
	call updateFruitPos		; 更新果子位置
new_int_1CH_ret:
	popa					; 恢复现场
	pop ds
	iret


;------------------------------------
; snakeCheck: 判断snake是否撞墙或撞自己了
;	@uses: dx, si
;	@returns:
;		al: 0否，1是
;------------------------------------
snakeCheck:
	push dx
	push si
	mov dh, byte [snake]		; 取蛇头行号
	mov dl, byte [snake+1]		; 取蛇头列号

	cmp dh, 24					; 检查是否碰壁
	je snakeCheck_gameOver
	cmp dh, 0
	je snakeCheck_gameOver
	cmp dl, 79
	je snakeCheck_gameOver
	cmp dl, 0
	je snakeCheck_gameOver

	mov si, 1					; 检查是否撞自己
snakeCheck_checkBody:
	cmp si, word [snake_len]
	je snakeCheck_gameNoOver
	shl si, 2					; si=si*4，每个结点4个字节
	cmp dh, byte [snake+si]		; 比较行号
	jne snakeCheck_next
	cmp dl, byte [snake+si+1]	; 如果行号相等，则比较列号
	je snakeCheck_gameOver		; 列号也相等，则游戏结束
snakeCheck_next:
	shr si, 2					; si=si/4
	inc si						; si++
	jmp snakeCheck_checkBody
snakeCheck_gameNoOver:
	mov al, 0
	jmp snakeCheck_ret
snakeCheck_gameOver:
	mov al, 1
snakeCheck_ret:
	pop dx
	pop si
	ret


;------------------------------------
; updateFruitPos: 更新果子的位置
;	@uses: ax, bx
;------------------------------------
updateFruitPos:
	push ax
	push bx
	mov ax, 0H					; 间隔定时器
    out 43H, al					; 通过端口43h
    in al, 40H					; 访问3次，保证随机性
    mov bl, 20
    div bl						; ax/bl(20) = al......ah
    mov al, ah					; 取余数
	add al, 3					; 3-22的随机数
	mov byte [fruit_pos], al	; 保存行号

	mov ax, 0H					; 间隔定时器
    out 43H, al					; 通过端口43h
    in al, 40H					; 访问3次，保证随机性
    mov bl, 60
    div bl						; ax/bl(60) = al......ah
    mov al, ah					; 取余数
	add al, 10					; 10-69的随机数
	mov byte [fruit_pos+1], al	; 保存列号
updateFruitPos_ret:
	pop bx
	pop ax
	ret

;------------------------------------
; speedAdd: 前进速度变快
;------------------------------------
speedAdd:
	cmp byte [speed], speed_min
	je speedAdd_ret
	dec byte [speed]
speedAdd_ret:
	ret


;------------------------------------
; snakeAdd: 蛇变长
;   @uses: si, di, eax
;------------------------------------
snakeAdd:
	push eax
	push si
	push di
	cmp word [snake_len], snake_len_max
	je snakeAdd_ret
	mov si, word [snake_len]
	shl si, 2					; 指向新结点
	mov di, word [snake_len]
	dec di
	shl di, 2					; 指向蛇尾结点
	mov eax, dword [snake+di]
	mov dword [snake+si], eax	; 复制到新结点中

	mov al, byte [snake+si+2]	; 获取方向
	cmp al, 0
	je updateUp
	cmp al, 1
	je updateRight
	cmp al, 2
	je updateDown
	cmp al, 3
	je updateLeft
	jmp snakeAdd_ret
updateUp:
	inc byte [snake+si]			; 向下增加结点，行号++
	jmp snakeAdd_ret
updateRight:
	dec byte [snake+si+1]		; 向左增加结点，列号--
	jmp snakeAdd_ret
updateDown:
	dec byte [snake+si]			; 向上增加结点，行号--
	jmp snakeAdd_ret
updateLeft:
	inc byte [snake+si+1]		; 向右增加结点，列号++
snakeAdd_ret:
	inc word [snake_len]
	pop di
	pop si
	pop eax
	ret

;------------------------------------
; isEatFruit: 判断是否吃到果子
;   @uses: dx
;	@returns:
;		al: 0否，1是
;------------------------------------
isEatFruit:
	push dx
	mov dh, byte [snake]
	mov dl, byte [snake+1]
	cmp dh, byte [fruit_pos]
	jne not_eat
	cmp dl, byte [fruit_pos+1]
	jne not_eat
	mov	al, 1
	jmp isEatFruit_ret
not_eat:
	mov al, 0
isEatFruit_ret:
	pop dx
	ret


;------------------------------------
; snakeMove: 根据全局变量 snake 让蛇前进
;   @uses: si, di, ax, bx
;------------------------------------
snakeMove:
	push ax
	push bx
	push si
	push di
snakeHeadMove:					; 蛇头移动
	mov si, 0
	mov ah, byte [dir]			; 取用户按下的方向
	mov al, byte [snake+si+2]	; 取蛇头结点的方向
	cmp al, ah					; 比较两个结点的方向
	je forwardDir				; 如果相同，则方向不变，snake直接前进
	mov bx, ax
	sub bh, bl
	cmp bh, 2
	je snakeMove_reverse		; ah-al==2 则反方向
	mov bx, ax
	sub bl, bh
	cmp bl, 2
	je snakeMove_reverse		; al-ah==2 也算反向
	jmp snakeMove_turn
snakeMove_reverse:				; 如果是反方向(两者相减的绝对值为2)，按键无效，snake也直接前进
	mov ah, al					; ah 记录上一个结点的方向，由于按键无效，所以重新赋值 ah=al
	jmp forwardDir
snakeMove_turn:					; 如果不相同也不是反方向，则方向改变，snake转弯
	mov byte [snake+si+2], ah
	mov al, ah
	jmp forwardDir
snakeMove_for1:					; 蛇身移动
	cmp si, word [snake_len]	; 判断是否超过snake长度
	je snakeMove_ret
	shl si, 2					; si=si*4
	mov al, byte [snake+si+2]	; 取当前结点方向

	cmp al, ah					; 比较两个结点的方向， ah 记录着上一个结点的前进方向
	je forwardDir				; 如果相同，则方向不变，当前结点直接前进
	mov byte [snake+si+2], ah	; 如果不相同，则方向改变(决定下一次前进的方向)，但当前结点按原方向前进
	mov ah, al					; 因为当前结点还是原方向前进，所以 ah 记录当前结点的原方向
forwardDir:
	cmp al, 0
	je forwardUp
	cmp al, 1
	je forwardRight
	cmp al, 2
	je forwardDown
	cmp al, 3
	je forwardLeft
	jmp snakeMove_for1_end
forwardUp:
	dec byte [snake+si]			; 向上，行号--
	jmp snakeMove_for1_end
forwardRight:
	inc byte [snake+si+1]		; 向右，列号++
	jmp snakeMove_for1_end
forwardDown:
	inc byte [snake+si]			; 向下，行号++
	jmp snakeMove_for1_end
forwardLeft:
	dec byte [snake+si+1]		; 向左，列号--
snakeMove_for1_end:
	shr si, 2
	inc si
	jmp snakeMove_for1
snakeMove_ret:
	pop di
	pop si
	pop bx
	pop ax
	ret


;------------------------------------
; snakeShow: 根据全局变量 snake 显示蛇
;   @uses: si, dx, bh, ax
;------------------------------------
snakeShow:
	push si
	push dx
	push bx
	push ax						; 保存用到的寄存器
	mov si, 0
snakeShow_for1:
	cmp si, word [snake_len]			; 判断是否超过snake长度
	je snakeShow_ret
	shl si, 2					; si=si*4，每个结点4个字节
	mov dh, byte [snake+si]		; 取行号
	mov dl, byte [snake+si+1]	; 取列号
	mov bh, 0
	mov ah, 2
	int 10H						; 设置光标位置
	mov al, byte [snake+si+3]	; 取结点字符
	call putChar
	shr si, 2					; si=si/4
	inc si						; si++
	jmp snakeShow_for1
snakeShow_ret:
	mov dx, 0
	mov bh, 0
	mov ah, 2
	int 10H						; 设置光标位置于左上角
	pop ax
	pop bx
	pop dx
	pop si						; 恢复用到的寄存器
	ret

;------------------------------------
; scoreShow: 显示分数
;   @uses: ax, dx, si
;------------------------------------
scoreShow:
	push ax
	push dx
	push si
	mov si, score_msg
	mov dh, score_row
	mov dl, score_col
	call printStr			; 打印"score:"字符串
	mov ax, [score]
	call printDec			; 打印分数
scoreShow_ret:
	pop si
	pop dx
	pop ax
	ret


;------------------------------------
; fruitShow: 根据全局变量 fruit_pos 显示果子
;   @uses: ax, bx, dx
;------------------------------------
fruitShow:
	push ax
	push bx
	push dx
	mov dh, byte [fruit_pos]
	mov dl, byte [fruit_pos+1]
	mov bh, 0
	mov ah, 2
	int 10H					; 设置光标位置
	mov al, fruit_pat
	call putChar			; 打印果子
fruitShow_ret:
	pop dx
	pop bx
	pop ax
	ret


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
	push ax
	push bx
	push cx
	push dx
	mov bh, 0
	mov ah, 3		; 读光标位置。返回ch=光标开始行，cl=光标结束行，dh=行号，dl=列号
	int 10H

	mov bl, color	; 字符属性
	mov cx, 1		; 字符重复次数
	mov ah, 9		; 将字符和属性写到光标位置处，光标不移动
	int 10H

	inc dl
	mov ah, 2		; 置光标于下一个位置
	int 10H
	pop dx
	pop cx
	pop bx
	pop ax
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
	db	2				; 列号
	db	1				; 方向。0上，1右，2下，3左
	db	snake_head_pat	; 蛇头图案
	; 蛇身第一个结点
	db	5
	db	1
	db	1
	db	snake_node_pat	; 结点图案
	; 蛇身第二个结点
	db	5
	db	0
	db	1
	db	snake_node_pat
	; 蛇身其它结点预留
	times	snake_len_max-3	dd	0

; 果实位置
fruit_pos:
	db	6	; 行号
	db	50	; 列号

snake_len		dw	3	; 初始为3
dir				db	1	; 方向
speed			db	10	; 前进速度。值越大速度越快，等于18时，1秒动一次
count			db	1	; 计数器
score			dw	0	; 分数
is_gameOver		db	0	; 游戏是否结束，0否，1是
welcome_msg		db	"Welcome to Snake Game!!! (Enter)", 0
gameOver_msg	db	"HaHaHaHa!!! Game is over. (Esc)", 0
score_msg		db	"score:", 0


;--------- MBR补充(做为加载程序时，忽略) ------------
; times   510 - ($-$$)    db  0
; db      55H, 0AAH