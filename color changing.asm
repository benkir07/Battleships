IDEAL
MODEL small
STACK 100h
DATASEG
; --------------------------
; Your variables here
; --------------------------
CODESEG
start:
	mov ax, @data
	mov ds, ax
; --------------------------
; Your code here
; --------------------------
	mov ah, 9 ;code to change colors
	mov bx, 2 ;color number
	mov cx, 2 ;how many characters to print this color
	int 10h ;changes by the above changes
	mov ah, 2 ;print one char code
	mov dl, ' ' ;the char to print
	int 21h ;print a char by the above settings
	int 21h ;just prints a character because we set one digit to paint
exit:
	mov ax, 4c00h
	int 21h
END start