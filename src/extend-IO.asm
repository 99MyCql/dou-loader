;--------------------
; @name: extend-IO
; @description: 加载程序六。设置 INT 90H 为扩展的输出程序，以TTY方式输出带属性的字符。
; @author: dounine
;--------------------

;--------- code ----------
	section text
	bits 16
	org 7C00H
Begin:
    push cs
    pop ds

	mov si, 90H*4	; 90号中断在 0000:90H*4 处
	push 0
	pop es			; 设置es值为0

	cli				; 关中断
	mov word [es:si], new_int_90H	; 设置新中断处理程序的偏移
	mov [es:si+2], cs				; 设置新中断处理程序的段值
	sti				; 开中断

	mov si, prompt
	mov bl, 0EH		; 黑底黄字
PrintPrompt:
	lodsb
	or al, al
	jz Next
	int 90H
	jmp PrintPrompt
Next:
	mov ah, 0
    int 16H 		; 从键盘读取字符保存到al中

	cmp al, 1BH
	je End			; 如果按下Esc键则结束

	int 90H			; 显示该字符
	cmp al, 0DH
	jne Next
	mov al, 0AH
	int 90H			; 如果按下回车键，再加上换行
	jmp Next
End:
	mov al, 0AH
	mov ah, 14
	int 10			; 显示换行
	retf

;------------------------------------
; new_int_90H: 设置90H号中断为：以TTY方式显示带属性字符
;	@params:
;		al: ASCII码
;		bl: 属性，即颜色
;------------------------------------
new_int_90H:
    sti			; 开中断
    pusha		; 保护现场
    push ds
    push es		; 保存用到的段寄存器
    call putchar
    pop es
    pop ds		; 恢复段寄存器
    popa		; 恢复现场
    iret

;------------------------------------
; putchar: 在当前光标位置处显示带属性的字符，随后光标后移一个位置。不支持退格符、响铃符等控制符
;	@params:
;		al: ASCII码
;		bl: 属性，即颜色
;------------------------------------
putchar:
    call get_lcursor; 获取行号(dh)和列号(dl)
    cmp al, 0DH
    jnz handleNormal
    mov dl, 0		; 如果是回车，列号置0
    jmp setCursor
handleNormal:
    cmp al, 0AH
    je handle0AH	; 如果是换行，转入相关处理

    mov ah, bl		; 保存字符属性
    mov bx, 0
    mov bl, dh
    imul bx, 80
    add bl, dl
    adc bh, 0
    shl bx, 1		; bx = (行号 x 80 + 列号) x 2

	push 0B800H		; 显示存储区的段值
    pop es			; 设置es
    mov [es:bx], ax	; 将字符信息(ah:属性，al:ASCII码)保存到对应显示储存区内存中

    inc dl			; 将列号加1
    cmp dl, 80
    jb setCursor	; 如果列号小于80，直接设置光标
    mov dl, 0		; 否则列号清零并换行
handle0AH:
    inc dh			; 行号加1
    cmp dh, 25
    jb setCursor	; 如果行号小于25，直接设置光标
    dec dh			; 行号减1

    cld
	mov ax, 0B800H	; 显示存储区的段值
    mov ds, ax		; 设置ds，源段值
    mov es, ax		; 设置es，目标段值
    mov si, 80*2	; 源偏移
    mov di, 0		; 目标偏移
    mov cx, 80*24	; 复制24行
    rep movsw

    mov cx, 80		; 设置80列
    mov di, 80*24*2	; 目标偏移，最后一行第一列
	mov ah, 07H		; 黑底白字
	mov al, 20H		; 空格符
    rep stosw
setCursor:			; 设置光标逻辑和物理地址
    call set_lcursor
    call set_pcursor
    ret

;------------------------------------
; get_lcursor: 获取光标的逻辑地址(保存在内存中)
;	@returns:
;		dh: 行号
;		dl: 列号
;------------------------------------
get_lcursor:
    push es
    push 0040H
    pop es
    mov dl, [es:0050H]	; 光标列号保存在 0040:0050H
    mov dh, [es:0051H]	; 光标行号保存在 0040:0051H
    pop es
    ret

;------------------------------------
; set_lcursor: 设置光标的逻辑地址(保存在内存中)
;	@params:
;		dh: 行号
;		dl: 列号
;------------------------------------
set_lcursor:
    push es
    push 0040H
    pop es
    mov [es:0050H], dl	; 保存列号
    mov [es:0051H], dh	; 保存行号
    pop es
    ret

;------------------------------------
; set_pcursor: 设置光标的物理地址，即让对应位置的光标显示在屏幕上
;	@params:
;		dh: 行号
;		dl: 列号
;------------------------------------
set_pcursor:
    mov al, 80
    mul dh		; ax = al*dh
    add al, dl	; al = al+dl
    adc ah, 0	; adc 若CF为1(即溢出)，则再加一
    mov cx, ax	; ax = 80*dh+dl 行号x80+列号

    mov dx,	3D4H
    mov al,	14
    out dx,	al
    mov dx,	3D5H
    mov al,	ch
    out dx,	al	; 设置高8位，即行号

    mov dx,	3D4H
    mov al,	15
    out dx,	al
    mov dx,	3D5H
    mov al,	cl
    out dx,	al	; 设置低8位，即列号
    ret


;----------data----------
prompt	db	"NO.90H int is ready.", 0DH, 0AH, "You can press any keys or press Esc to return.", 0DH, 0AH, 0

;--------- MBR补充(做为加载程序时，忽略) ------------
times 510 - ($ - $$) db 0	; 填满512个字节，满足MBR的要求
db  55H, 0AAH				; MBR程序最后的标识