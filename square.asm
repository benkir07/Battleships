IDEAL
MODEL small
STACK 100h
DATASEG
; --------------------------
; Your variables here
; --------------------------
CODESEG

proc print_square
	push bp
	mov bp, sp
	color equ [bp+10]
	pixel_amount equ [bp+8]
	x equ [bp+6]
	y equ [bp+4]
	push ax bx cx dx si di
	
	mov ah, 0Ch
	mov al, color
	mov bh, 0
	mov dx, y
	
	mov di, pixel_amount
linesLoop:
	mov si, pixel_amount
	mov cx, x
columnsLoop:
	int 10h
	inc cx
	dec si
	cmp si, 0
	jne columnsLoop
	inc dx
	dec di
	jne linesLoop
	
	pop di si dx cx bx ax bp
	ret 8
endp print_square


start:
	mov ax, @data
	mov ds, ax
; --------------------------
; Your code here
; --------------------------
	
	mov ax, 13h
	int 10h
	
	push 4
	push 10
	push 100
	push 100
	call print_square


	mov ax, 4c00h
	int 21h
END start


