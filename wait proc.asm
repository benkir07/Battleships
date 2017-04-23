IDEAL
MODEL small
STACK 100h
DATASEG
; --------------------------
; Your variables here
; --------------------------
CODESEG
;waits a time asked for
;input: how many miliseconds to wait
;output: none
proc wait1
	push bp
	mov bp, sp
	cmp [word ptr bp+4], 0
	je end1
	push ax
	push bx
	push cx
	push dx
	mov bx, [bp+4]
setsec:
	mov ah, 2ch
	int 21h
	mov al, dl ;seconds
checkforsec:
	mov ah, 2ch
	int 21h
	cmp al, dl ;checks if the seconds changed
	je checkforsec
	dec bx
	cmp bx, 0
	jne setsec
	pop dx
	pop cx
	pop bx
	pop ax
end1:
	pop bp
	ret 2
endp wait1

start:
	mov ax, @data
	mov ds, ax
; --------------------------
; Your code here
; --------------------------
exit:
	mov ax, 4c00h
	int 21h
END start


