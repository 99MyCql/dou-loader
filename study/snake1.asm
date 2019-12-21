;--------------------
; @name: snake1
; @description: 工作程序三。网上找到的贪吃蛇程序1，存在bug。
; @author: xxxxxx
;--------------------
org 7c00h

global start
start:

    jmp entry

keyboard_interrupt:
    in  al,0x60
    and al,0x80

	mov ah,al
	cmp ah,byte [forbiden]
	jz keyboard_interrupt_exit

	cmp ah,0x50
	jz gotkey
	cmp ah,0x4b
	jz gotkey
	cmp ah,0x4d
	jz gotkey
	cmp ah,0x48
	jnz keyboard_interrupt_exit
gotkey:
	mov byte[dir],ah

keyboard_interrupt_exit:
	iret

handler:
	nop
	mov al,byte [counter]
	inc al
	mov byte [counter],al
	cmp al,10
	jnz handler_exit
	mov al,0
	mov byte [counter],al

premove:
	mov bx,word [snake]
	mov ah,byte [dir]
	cmp ah,0x48
	jz up
	cmp ah,0x50
	jz down
	cmp ah,0x4b
	jz left
	cmp ah,0x4d
	jz right
	jmp move
up:
	mov byte [forbiden],0x50
	dec bh
	jmp move
down:
	mov byte [forbiden],0x48
	inc	bh
	jmp move
left:
	mov byte [forbiden],0x4d
	dec bl
	jmp move
right:
	mov byte [forbiden],0x4b
	inc bl
move:
	call deadcheck
	mov di,snake
	add di,word [snakelen]
	add di,word [snakelen]
	sub di,2
moveloop:
	sub di,2
	mov ax,word [es:di]
	add di,2
	mov word [es:di],ax
	sub di,2
	cmp di,snake
	jnz moveloop

	mov word [snake],bx
	call clear
	call putsnake
handler_exit:
	mov al,20h
	out 20h,al
	iret

setuptimer:
	mov ax,0 ;在8*4内存地址处注册中断处理程序的入口地址
	mov ds,ax
	mov bx,32
	mov word [bx],handler-$$
	mov word [bx+2],07c0h
	int 8h

;	mov bx,36
;	mov word [bx],keyboard_interrupt-$$
;	mov word [bx+2],keyboard_interrupt-$$
;	int 8h

	sti
	ret

entry:
	nop
	mov ax,cs
	mov es,ax

	; set video mode
	mov ah,0
	mov al,3
	int 10h
	call clear
	call gamestart
	call getchar
	call clear
	call putsnake

	call setuptimer

loop:
	jmp $

putchar:
	push bp
	mov bp,sp
	push ax
	push bx
	push cx
	push dx

	mov AH,02h
	mov BH,0h
	mov dx,[bp+4]
	int 10h

	mov AH,09h
	mov AL,03h
	mov BH,0
	;mov BL,77h
	mov bx,13
	mov bh,0
	mov CX,1
	int 10h

	pop dx
	pop cx
	pop bx
	pop ax
	mov sp,bp
	pop bp
	ret

putsnake:
	push ax
	push cx
	push di

	mov cx,word [snakelen]
	mov di,snake
putloop:
	mov ax,[es:di]
	push ax
	call putchar
	add sp,2
	add di,2
	dec cx
	jnz putloop

	pop di	
	pop cx
	pop ax
	ret

getchar:
    mov ah, 1  
    int 16h  
    jz getchar_clear_read ; ///< 键盘缓冲区都空了, 可以转"读键盘输入"
  
    mov ah, 0  
    int 16h  
    jmp getchar ; ///< 继续清键盘缓冲区  
  
getchar_clear_read:   
    mov ah, 1  
    int 16h  
    jz getchar_clear_read ; ///< 如果没有键盘输入，继续死等键盘输入
  
    mov ah, 0 ; ///< al是键盘输入  
    int 16h  
    ret
 
clear:
	push ax
	push bx
	push cx
	push dx
	mov bh,7
	mov ah,6
	mov al,0
	mov ch,0
	mov cl,0
	mov dh,24
	mov dl,79
	int 10h
	pop dx
	pop cx
	pop bx
	pop ax
	ret

gamestart:
	mov si,bp
	mov bp,startstr		;es:bp 指向的内容就是我们要显示的字符串地址了
	mov cx,word [startlen]		;显示的字符串长度
	mov dh,12			;显示的行号
	mov dl,36			;显示的列号
	mov bh,0			;显示的页数
	mov al,1			;显示的是串结构
	mov bl,0ch			;显示的字符属性
	mov ah,13h			;明确调用13h子程序
	int 10h
	mov bp,si
	ret

gameover:
	mov bp,endstr		;es:bp 指向的内容就是我们要显示的字符串地址了
	mov cx,word [endlen]			;显示的字符串长度
	mov dh,12			;显示的行号
	mov dl,36			;显示的列号
	mov bh,0			;显示的页数
	mov al,1			;显示的是串结构
	mov bl,0ch			;显示的字符属性
	mov ah,13h			;明确调用13h子程序
	int 10h
	jmp $

deadcheck:
	cmp bl,79
	JG gameover
	cmp bh,24	
	jg gameover
	cmp bl,0
	jz gameover
	cmp bh,0
	jz gameover
	ret


counter:
    db 0
dir:
    db 0x4d
forbiden:
    db 0x4b
startstr:
    db "press s to start"
startlen:
    dw $-startstr
endstr: 
    db	"Game Over!"
endlen:
    dw	$-endstr
snake:
    dw 0509h,0508h,0507h,0506h,0505h
snakelen:
    dw 5 

times 510-($-$$) db 0
dw 0xaa55