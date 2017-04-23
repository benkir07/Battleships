IDEAL
MODEL small
STACK 100h
DATASEG
; --------------------------
; Your variables here
; --------------------------

ROW_AMOUNT equ 10
AREA equ ROW_AMOUNT * ROW_AMOUNT

board db AREA dup (20h)
guessing_board db AREA dup (20h)
tableTopPart db ' a b c d e f g h i j$'
where_to_shoot db 'Where would you like to shoot? (enter in format of little letter and then a number, a1 for example)$'
input db 3,0,0,0

place equ input+2 ;the actual string i get from input

CODESEG
;this procedure prints to the screen a chosen board
;input: the board to print's offset
;output: none
proc present_board
BLUE equ 32
RED equ 120
YELLOW equ 109
;anything else is white
	push bp
	mov bp, sp
	push ax
	push bx
	push cx
	push dx
	
	mov dl, 0ah
	mov ah, 2
	int 21h
	
	lea dx, [tableTopPart]
	mov ah, 9
	int 21h
	mov ch, 0 ;counts the lines
	mov bx, [bp+4]
anotherLine:
	mov cl, 0 ;counts the columns
	mov dl, 0ah
	mov ah, 2
	int 21h
	;down a line
	mov dl, ch
	add dl, '0'
	mov ah, 2
	int 21h
	;the line's number
anotherColumn:
	
	mov dl, [bx]
	xor dh, dh
	push dx
	call print_a_part
	inc cl
	inc bx
	cmp cl, ROW_AMOUNT
	jb anotherColumn
	inc ch
	cmp ch, ROW_AMOUNT
	jb anotherLine
	
	mov dl, 0ah
	mov ah, 2
	int 21h
done1:
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret 2
endp present_board

;this procedure gets a raw value of a board part and prints to the screen what it is supposed to show
;input: value of the board part
;output: none
proc print_a_part
	push bp
	mov bp, sp
	push ax
	push bx
	push cx
	push dx
	cmp [word ptr bp+4], BLUE
	je blue
	cmp [word ptr bp+4], RED
	je red
	cmp [word ptr bp+4], YELLOW
	je yellow
white:
	mov bl, 15
	jmp afterBlSet
blue:
	mov bl, 1
	jmp afterBlSet
red:
	mov bl, 4
	jmp afterBlSet
yellow:
	mov bl, 14
afterBlSet:
	mov ah, 9
	mov cx, 1
	int 10h
	mov ah, 2
	mov dl, 219
	int 21h
	int 21h
done2:
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret 2
endp print_a_part

;this proc converts a string of place the an actual offset
;input: string of place (like a0, b1 ect...)
;output: number to add to offset to get the wanted place
proc place_to_offset
	push bp
	mov bp, sp
	push ax
	
	mov al, [bp+3] ;number
	sub al, '0' ;actual number
	mov ah, ROW_AMOUNT
	mul ah
	add al, [bp+4] ;letter
	sub al, 'a'
	xor ah, ah
	mov [bp+4], ax
	
	pop ax
	pop bp
	ret
endp place_to_offset
start:
	mov ax, @data
	mov ds, ax
; --------------------------
; Your code here
; --------------------------
	mov ah, 0ah
	mov dx, offset input
	int 21h
	mov bx, [word ptr place]
	push bx
	call place_to_offset
	pop bx
	mov [board+bx], YELLOW
exit:
	mov ax, 4c00h
	int 21h
END start