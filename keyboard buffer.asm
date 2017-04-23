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
	up equ 'w'
	left equ 'a'
	down equ 's'
	right equ 'd'
	
waitForData:
	mov ah, 1
	int 16h
	jnz waitForData
	mov ah, 0
	int 16h
	cmp al, right
	je MoveRight
	cmp al, left
	je MoveLeft
	cmp al, up
	je MoveUp
	cmp al, down
	je MoveDown
	jmp waitForData
	

exit:
	mov ax, 4c00h
	int 21h
END start


