IDEAL
MODEL small
STACK 100h
DATASEG
; --------------------------
; Your variables here
; --------------------------
	down_a_row db 13,10
CODESEG
start:
	mov ax, @data
	mov ds, ax

;input: file's name, board
proc write_board
	push bp
	mov bp, sp
	push ax
	push bx
	push cx
	push dx
	
	mov dx, [bp+6]
	mov ah, 03Dh
	mov al, 1
	int 21h
	
	mov bx, ax
	mov cx, ROW_AMOUNT
	mov dx, [bp+4]
	
writeLine:
	push cx
	mov cx, ROW_AMOUNT
	mov ah, 40h
	int 21h
	add dx, ROW_AMOUNT
	push dx
	mov dx, offset down_a_row
	mov cx, 2
	mov ah, 40h
	int 21h ;goes down a row
	pop dx
	pop cx
	loop writeLine
	
	mov ah, 3Eh
	int 21h ;close file
	
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret 4
endp write_board

;this procedure loads a given text file (trusting it is legal), to a board
;input: text to open file's name, board to load into's offset
;output: the board changed to the text file's configurations
proc load_board
	push bp
	mov bp, sp
	push ax
	push bx
	push cx
	push dx
	push si
	
	mov dx, [bp+6]
	mov ah, 03Dh
	xor al, al
	int 21h
	
	mov bx, ax ;file handle
	mov cx, ROW_AMOUNT+2
	mov dx, [bp+4]
	xor si, si ;counts the lines read
	
readLine:
	mov ah, 03fh
	int 21h
	add dx, ROW_AMOUNT
	inc si
	cmp si, ROW_AMOUNT
	je done_copying
	cmp si, ROW_AMOUNT-1
	jne readLine
	sub cx, 2
	jmp readLine
	
done_copying:
	mov ah, 3Eh
	int 21h ;close file

	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret 4
endp load_board
exit:
	mov ax, 4c00h
	int 21h
END start


