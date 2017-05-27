IDEAL
MODEL small
STACK 100h
DATASEG
; --------------------------
; Your variables here
; --------------------------

NumArr db 5 dup (0)

CODESEG

proc print_num
	push bp
	mov bp, sp
	push ax
	push bx
	push dx
	push si
	
	mov si, offset NumArr + 4
	mov ax, [bp+4] ;the number
convert_number:
	xor dx, dx
	mov bx, 10
	div bx
	mov [si], dl
	dec si
	cmp si, offset NumArr - 1
	jne convert_number

	mov si, offset NumArr
	mov ah, 2
printLoop:
	mov dl, [si]
	add dl, '0'
	int 21h
	inc si
	cmp si, offset NumArr + 5
	jne printLoop
	
	pop si
	pop dx
	pop bx
	pop ax
	pop bp
	ret 2
endp print_num

start:
	mov ax, @data
	mov ds, ax
; --------------------------
; Your code here
; --------------------------
	push 65535
	call print_num


	mov ax, 4c00h
	int 21h
END start


