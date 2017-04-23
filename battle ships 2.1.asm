IDEAL
MODEL small
STACK 100h
DATASEG
; --------------------------
; Your variables here
; --------------------------

ROW_AMOUNT equ 10
AREA equ ROW_AMOUNT * ROW_AMOUNT

;output stuff
start_game db 'Wellcome to the game of battle ships!', 10, 'This is a very early version of the game, hopefully you will enjoy anyway', 10, 'this program was written by Ben Kirshenbaum', 10, '$'
tableTopPart db ' a b c d e f g h i j$'
place_ship1 db 'Starting to place a ship $'
place_ship2 db ' tiles long' , 10, 'Where would you like to have its first position?', 10, '$'
direction db 'What direction would you like this ship to continue?', 10, 'press w for up, s for down, a for left and d for right', 10, '$'
illegal_direction db 'That is not a direction!', 10, '$'
illegal_place db 'There is an illegal place to place a ship in!' , 10, 'either one of its sides is taken or it is itelf taken', 10, '$'
no_space db 'There is no legal space in this direction to place a ship', 10, '$'
no_more_ship db 'You are done placing ships!' , 10, '$'
where_to_shoot db 'Where would you like to shoot?',10, '(enter in format of little letter and then a number, a1 for example)',10,'$'
illegal_string db 'This position is not on the board!',10,'$'
shot_already db 'This position was already shot!', 10, '$'
miss db 'You missed!', 10, '$'
hit db 'Hit!', 10, '$'
fallen_ship db 'Ship is down! Ship is down!', 10, '$'
any_key_to_continue db 'Press any key to continue...' , 10, '$'
win db 'You won!' , 10, 'thank you for playing my game$'

;input stuff
place_input db 3,0,0,0,0
direction_input db 2,0,0,0

;actual variables
active_player_string db 'Player '
active_player_number db '1 $'
Player1Board db AREA dup (20h)
Player2Board db AREA dup (20h)

Player1Guessing db AREA dup (20h)
Player2Guessing db AREA dup (20h)

Player1LeftShip db 2,2,2,3,3,4,'$'
Player2LeftShip db 2,2,2,3,3,4,'$'

CODESEG
BLUE equ 32
;this procedure checks whether or not a position on th board is legal to place a ship part
;input: offset of place, string of the place (a0, b1)
;output: al = 0 if legal and al = -1 if illegal 
proc Check_legal_to_place
	push bp
	mov bp, sp
	push bx
	mov ax, [bp+4]
	mov bx, [bp+6]
	
CheckTop:
	cmp ah, '0'
	je CheckMid ;its is part of the top row
	cmp al, 'a'
	je CheckTopMid ;it is part of the left column
CheckTopLeft:
	cmp [byte ptr bx-ROW_AMOUNT-1], BLUE
	jne illegal3
CheckTopMid:
	cmp [byte ptr bx-ROW_AMOUNT], BLUE
	jne illegal3
	cmp al, 'a'+ROW_AMOUNT-1
	je CheckMid ;it is part of the right column
CheckTopRight:
	cmp [byte ptr bx-ROW_AMOUNT+1], BLUE
	jne illegal3
	
CheckMid:
	cmp al, 'a'
	je CheckMidMid ;it is part of the left column
CheckMidLeft:
	cmp [byte ptr bx-1], BLUE
	jne illegal3
CheckMidMid:
	cmp [byte ptr bx], BLUE
	jne illegal3
	cmp al, 'a'+ROW_AMOUNT-1
	je CheckBottom ;it is part of the right column
CheckMidRight:
	cmp [byte ptr bx+1], BLUE
	jne illegal3
	
CheckBottom:
	cmp al, 'a'
	je CheckBottomMid
CheckBottomLeft:
	cmp [byte ptr bx+ROW_AMOUNT-1], BLUE
	jne illegal3
CheckBottomMid:
	cmp [byte ptr bx+ROW_AMOUNT], BLUE
	jne illegal3
	cmp al, 'a'+ROW_AMOUNT-1
	je DoneChecking ;it is part of the right column
CheckBottomRight:
	cmp [byte ptr bx+ROW_AMOUNT+1], BLUE
	jne illegal3
	
DoneChecking:
;if passed all the compares and got here, place is legal
	xor al, al
	jmp EndOfProc
	
illegal3:
	mov al, -1
EndOfProc:
	pop bx
	pop bp
	ret 4
endp Check_legal_to_place

;this procedure places ships on the board according to input from the player
;input: offset of the player's board, offset of an array keeping lengths of the ships to place
;output: none
proc Create_Board
	push bp
	mov bp, sp
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	
	mov bx, [bp+6] ;the board
	mov si, [bp+4] ;array keeping the lengths of the ships
	xor cx, cx
	mov cl, '0' ;cl keeps the value that will represent the ship on the board
start_placeing_ship:
	push -1
	mov ch, [si] ;ch keep the length of the current placing ship
	push bx
	call Present_Board
	
illegal4:
	mov ah, 9
	mov dx, offset place_ship1
	int 21h
	mov dl, ch
	add dl, '0'
	mov ah, 2
	int 21h
	mov ah, 9
	mov dx, offset place_ship2
	int 21h
	
	mov ah, 0ah
	mov dx, offset place_input
	int 21h
	push [word ptr place_input+2]
	call check_legal_string
	cmp al, 0
	je legal2
	
	push bx
	call Present_Board
	mov dx, offset illegal_string
	mov ah, 9
	int 21h
	jmp illegal4
legal2:
	push [word ptr place_input+2]
	call place_to_offset
	pop di ;the number to add to the board offset to get the desired place
	add di, bx
	push di ;where the ship starts
	push [word ptr place_input+2]
	call Check_legal_to_place
	cmp al, 0
	je legal3
	push bx
	call Present_Board
	mov dx, offset illegal_place
	mov ah, 9
	int 21h
	mov ch, [si] ;ch keep the length of the current placing ship
	jmp illegal4
legal3:
	push di ;keep in the stack segment the position future to be painted
	mov [di], cl
	dec ch
	push bx
	call Present_Board
illegal5:
	mov [byte ptr di], BLUE
	mov dx, offset direction
	mov ah, 9
	int 21h
	mov ah, 0ah
	mov dx, offset direction_input
	int 21h
	cmp [direction_input+2], 'w'
	je place_up
	cmp [direction_input+2], 's'
	je place_down
	cmp [direction_input+2], 'a'
	je place_left
	cmp [direction_input+2], 'd'
	je place_right
;if here, input wasn't legal
	mov [di], cl
	push bx
	call Present_Board
	mov dx, offset illegal_direction
	mov ah, 9
	int 21h
	jmp illegal5
	
place_up:
;checks it is far enough from the border
	mov al, ROW_AMOUNT
	mul ch ;ax stores now how much could be between di and bx, where we place and the board's start
	mov dx, di
	sub dx, ax ;dx stores now where the last placement would be
	cmp dx, bx
	jae place_up1
	jmp start_placeing_ship
place_up1:
	sub di, ROW_AMOUNT
	push di
	dec [byte ptr place_input+3]
	push [word ptr place_input+2]
	call Check_legal_to_place
	cmp al, 0
	je up_legal
;remove the ship and go back to start placing it
	jmp remove_written_postitions
up_legal:
	push di
	dec ch
	cmp ch, 0
	jne place_up1
	jmp done_writing_positions
	
place_down:
;checks it is far enough from the border
	mov al, ROW_AMOUNT
	mul ch ;ax stores now how much could be between di and bx, where we place and the board's start
	mov dx, di
	add dx, ax ;dx stores now where the last placement would be
	mov ax, bx
	add ax, AREA-1 ;ax stores the end of the board
	cmp dx, ax 
	jbe place_down1
	jmp start_placeing_ship
place_down1:
	add di, ROW_AMOUNT
	push di
	inc [byte ptr place_input+3]
	push [word ptr place_input+2]
	call Check_legal_to_place
	cmp al, 0
	je down_legal
;remove the ship and go back to start placing it
	jmp remove_written_postitions
down_legal:
	push di
	dec ch
	cmp ch, 0
	jne place_down1
	jmp done_writing_positions
	
place_left:
;checks it is far enough from the border
	mov al, [place_input+2] ;the number entered with the place
	sub al, 'a' ;al stores now how many tiles are there to the left
	cmp al, ch
	jae place_left1
	jmp start_placeing_ship
place_left1:
	sub di, 1
	push di
	dec [byte ptr place_input+2]
	push [word ptr place_input+2]
	call Check_legal_to_place
	cmp al, 0
	je left_legal
;remove the ship and go back to start placing it
	jmp remove_written_postitions
left_legal:
	push di
	dec ch
	cmp ch, 0
	jne place_left1
	jmp done_writing_positions
	
place_right:
;checks it is far enough from the border
	mov al, [place_input+2] ;the number entered with the place
	sub al, 'a' ;al stores now how many tiles are there to the left
	mov ah, ROW_AMOUNT
	sub ah, [si] ;ah stores now how many tiles is max allow to be to the left
	cmp ah, al
	jae place_right1
	jmp start_placeing_ship
place_right1:
	add di, 1
	push di
	inc [byte ptr place_input+2]
	push [word ptr place_input+2]
	call Check_legal_to_place
	cmp al, 0
	je right_legal
;remove the ship and go back to start placing it
	jmp remove_written_postitions
right_legal:
	push di
	dec ch
	cmp ch, 0
	jne place_right
	jmp done_writing_positions
	
;removes the saved positions from the stack until hits the -1 signing to stop
;this allows to start again placing a ship
remove_written_postitions:
	pop di
	cmp di, -1
	je remove_written_postitions
	push -1
	mov ch, [si] ;ch keep the length of the current placing ship
	push bx
	call Present_Board
	mov dx, offset no_space
	mov ah, 9
	int 21h
	jmp illegal4
	
done_writing_positions:
	pop di
	cmp di, -1
	je done_placing_a_ship
	mov [di], cl
	jmp done_writing_positions
done_placing_a_ship:
	inc cl
	inc si
	cmp [byte ptr si], '$'
	jne start_placeing_ship
	
	push bx
	call Present_Board
	mov dx, offset no_more_ship
	mov ah, 9
	int 21h
	
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret 4
endp Create_Board

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

	mov dx, offset active_player_string
	mov ah, 9
	int 21h
	
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
;output: al = 0 if legal and al = -1 if illegal
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
;output: al = 1 if won and al = 0 to continue
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
	mov dx, offset place_input
	int 21h
	push [word ptr place_input+2]
	call check_legal_string
	cmp al, 0
	je legal_string1
	;illegal string
	push di
	call Present_Board
	mov dx, offset illegal_string
	mov ah, 9
	int 21h
	jmp illegal2
legal_string1:
	push [word ptr place_input+2]
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

;this procedure changes
proc next_player
	cmp [byte ptr active_player_number], '1'
	je set2
	mov [byte ptr active_player_number], '1'
	jmp done2
set2:
	mov [byte ptr active_player_number], '2'
done2:
	ret
endp next_player

;this procedure gets already existing boards and runs a single game using them
;input: first player's: board, guessing board, left ship array
;		second player's: board, guessing board, left ship array
proc Manage_Game
	push bp
	mov bp, sp
	push ax
	push dx
turn_cycle:
	call Wait_for_key_press
	call next_player
	push offset Player2Board
	push offset Player1Guessing
	push offset Player2LeftShip
	call manage_turn
	cmp al, 1
	je win1
	call Wait_for_key_press
	call next_player
	push offset Player1Board
	push offset Player2Guessing
	push offset Player1LeftShip
	call manage_turn
	cmp al, 1
	je win1
	jmp turn_cycle
win1:
	mov dx, offset active_player_string
	mov ah, 9
	int 21h
	mov dx, offset win
	int 21h
	ret 12
endp Manage_Game

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
	
	push offset Player1Board
	push offset Player1LeftShip
	call Create_Board
	call next_player
	call Wait_for_key_press
	push offset Player2Board
	push offset Player2LeftShip
	call Create_Board
	call Manage_Game

exit:
	mov ax, 4c00h
	int 21h
END start
