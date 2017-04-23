IDEAL
MODEL small
STACK 100h
DATASEG
; --------------------------
; Your variables here
; --------------------------

ROW_AMOUNT equ 10
AREA equ ROW_AMOUNT * ROW_AMOUNT

BoardRow0 db '          '
BoardRow1 db ' 00 11 22 '
BoardRow2 db '          '
BoardRow3 db ' 333 444  '
BoardRow4 db '          '
BoardRow5 db ' 5555     '
BoardRow6 db '          '
BoardRow7 db '          '
BoardRow8 db '          '
BoardRow9 db '          '
guessing_board db AREA dup (20h)

left_ship db 2,2,2,3,3,4

;output stuff
start_game db 'Wellcome to the game of battle ships!', 10, 'This is a very early version of the game, hopefully you will enjoy anyway', 10, 'this program was written by Ben Kirshenbaum', 10, '$'
tableTopPart db ' a b c d e f g h i j$'
where_to_shoot db 'Where would you like to shoot?',10, '(enter in format of little letter and then a number, a1 for example)',10,'$'
illegal_string db 'This position is not on the board!',10,'$'
shot_already db 'This position was already shot!', 10, '$'
miss db 'You missed!', 10, '$'
hit db 'Hit!', 10, '$'
fallen_ship db 'Ship is down! Ship is down!', 10, '$'
any_key_to_continue db 'Press any key to continue...' , 10, '$'
win db 'You won!' , 10, 'thank you for playing my game$'

;input stuff
input db 3,0,0,0

CODESEG
;this procedure prints to the screen a chosen board
;input: the board to print's offset
;output: none
proc Present_Board
	push bp
	mov bp, sp
	push ax
	push bx
	push cx
	push dx
	
	mov ah, 2
	mov cx, 25
downRow:
	mov dl, 0ah
	int 21h
	loop downRow
	;clears the board

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
	push bx
	push cx
	
BLUE equ 32
RED equ 120
YELLOW equ 109
;anything else is white
	
	cmp dl, BLUE
	je blue1
	cmp dl, RED
	je red1
	cmp dl, YELLOW
	je yellow1
white1:
	mov bx, 15
	jmp AfterColorSet
blue1:
	mov bx, 1
	jmp AfterColorSet
red1:
	mov bx, 4
	jmp AfterColorSet
yellow1:
	mov bx, 14
AfterColorSet:
	mov ah, 9
	mov cx, 2
	int 10h
	mov ah, 2
	mov dl, 219
	int 21h
	int 21h
	
	pop cx
	pop bx
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
endp Present_Board

;this proc converts a string of place the an actual offset
;input: string of place (like 1a, 1b ect...)
;output: number to add to offset to get the wanted place
proc place_to_offset
	push bp
	mov bp, sp
	push ax
	
	mov al, [bp+5] ;number
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

;this proc checks if the input i got from the user is legal
;input: string of place (like 1a, 1b ect...)
;output: al = 00h if legal and 0FFh if illegal
proc check_legal_string
	push bp
	mov bp, sp
	
	mov al, [bp+4] ;letter
	cmp al, 'a'
	jb illegal1
	cmp al, 'a'+ROW_AMOUNT
	jae illegal1
	; if we are here, letter is legal
	mov al, [bp+5]
	cmp al, '0'
	jb illegal1
	cmp al, 'a'+ROW_AMOUNT
	jae illegal1
	;here number is legal too
	xor al, al
	jmp legal1
illegal1:
	mov al, 0FFh
legal1:
	pop bp
	ret 2
endp check_legal_string

;this proc runs a single turn
;input: enemy's board offset, guessing board offset, an array of left ship offset
;output: al = 1 if won or al = 0 to continue
proc manage_turn
	push bp
	mov bp, sp
	push bx
	push cx
	push dx
	push si
	push di
	
	mov di, [bp+6] ;guessing board
	mov si, [bp+8] ;actual board	
	push di
	call Present_Board
illegal2:
	
	mov dx, offset where_to_shoot
	mov ah, 9
	int 21h
	mov ah, 0ah
	mov dx, offset input
	int 21h
	push [word ptr input+2]
	call check_legal_string
	cmp al, 0
	je legal_string1
	;illegal string
	mov dx, offset illegal_string
	mov ah, 9
	int 21h
	jmp illegal2
legal_string1:
	push [word ptr input+2]
	call place_to_offset
	pop bx ;the number to add to the board offset to get the desired place
	
	cmp [byte ptr di + bx], BLUE
	je shoot
	;already shot there
	push di
	call Present_Board
	mov dx, offset shot_already
	mov ah, 9
	int 21h
	jmp illegal2
shoot:
	cmp [byte ptr si + bx], BLUE ;checks the value in the actual board
	je miss1

	mov [byte ptr di + bx], RED ;hit sign
	push di
	call Present_Board
	mov dx, offset hit
	mov ah, 9
	int 21h

	mov al, [si + bx] ;the value of the ship
	sub al, '0' ;its place in the left ship array
	xor ah, ah
	mov si, [bp+4] ;left ship array
	add si, ax
	dec [byte ptr si]
	cmp [byte ptr si], 0
	jne continue_playing
ship_fell:	
	mov dx, offset fallen_ship
	mov ah, 9
	int 21h
	mov cx, 6 ;number of items in left ship
	mov si, [bp+4] ;left ship array
check_loop:
	cmp [byte ptr si], 0
	jne continue_playing
	inc si
	loop check_loop
	;player won if looped ended
	mov al, 1
	jmp end_turn
miss1:
	mov [byte ptr di + bx], YELLOW ;miss sign
	push di
	call Present_Board
	mov dx, offset miss
	mov ah, 9
	int 21h
continue_playing:
	xor al, al
end_turn:
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop bp
	ret 6
endp manage_turn

;This procedure waits for a key press to end
;used to allow the players to see the board before the game continues
proc Wait_for_key_press
	push ax
	push dx
	mov ah, 9
	mov dx, offset any_key_to_continue
	int 21h
	mov ah, 0
	int 16h
	pop dx
	pop ax
	ret
endp Wait_for_key_press

start:
	mov ax, @data
	mov ds, ax
; --------------------------
; Your code here
; --------------------------
	mov ah, 2
	mov cx, 25
downRow1:
	mov dl, 0ah
	int 21h
	loop downRow1
	;clears the board
	mov dx, offset start_game
	mov ah, 9
	int 21h
Another_Turn:
	call Wait_for_key_press
	push offset BoardRow0
	push offset guessing_board
	push offset left_ship
	call manage_turn
	cmp al, 1
	jne Another_Turn

	mov dx, offset win
	mov ah, 9
	int 21h
exit:
	mov ax, 4c00h
	int 21h
END start
