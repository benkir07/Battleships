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
blueExplain db 219, 219, ' is an empty slot', 10, '$'
greenExplain db 219, 219,  ' is the slot you are looking at currently', 10, '$'
whiteExplain db 219, 219,  ' is a ship part', 10, '$'
redExplain db 219, 219,  ' is a slot you shot and hit a ship', 10, '$'
yellowExplain db 219, 219, ' is a slot you shot and did not hit a ship', 10, '$'
place_ship1 db 'Starting to place a ship $'
place_ship2 db ' tiles long' , 10, 'Where would you like to have its first position?', 10, '(use the arrow keys to move your selected slot and press enter when you have the slot you want to place selcted)', 10, '$'
direction db 'What direction would you like this ship to continue?', 10, 'press w for up, s for down, a for left and d for right', 10, '$'
illegal_direction db 'That is not a direction!', 10, '$'
illegal_place db 'There is an illegal place to place a ship in!' , 10, 'either one of its sides is taken or it is itelf taken', 10, '$'
no_space db 'There is no legal space in this direction to place a ship', 10, '$'
no_more_ship db 'You are done placing ships!' , 10, '$'
where_to_shoot db 'Where would you like to shoot?',10, '(use the arrow keys to move your selected slot and press enter when you have the slot you want to shoot selcted)',10,'$'
illegal_string db 'This position is not on the board!',10,'$'
shot_already db 'This position was already shot!', 10, '$'
miss db 'You missed!', 10, '$'
hit db 'Hit!', 10, '$'
fallen_ship db 'Ship is down! Ship is down!', 10, '$'
any_key_to_continue db 'Press any key to continue...' , 10, '$'
win db 'You won!' , 10, 'thank you for playing my game$'

;input stuff
direction_input db 2,0,0,0

;actual variables
active_player_string db 'Player '
active_player_number db '1 $'
Player1Board db AREA dup (20h)
Player2Board db AREA dup (20h)

Player1Guessing db AREA dup (20h)
Player2Guessing db AREA dup (20h)

Player1LeftShip db 2,2,2,3,3,4,'$' ;$ marks the end of the array
Player2LeftShip db 2,2,2,3,3,4,'$' ;$ marks the end of the array

CODESEG
;this procedure allows the user to choose using the keyboard a position on the board
;input: offset of board
;output: offset of the chosen place
proc Choose_Place
	push bp
	mov bp, sp
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	mov si, [bp+4] ;the board offset
	mov di, [bp+4] ;the looked at position
present:
	push si
	call Present_Board
	
	up equ 048h
	left equ 04Bh
	down equ 050h
	right equ 04Dh
	keyEnter equ 01Ch
	
	
	mov ax, di
	sub ax, si
	mov bl, ROW_AMOUNT
	div bl ;ah holds the x axis (0-9), al holds the y axis (0-9)
	mov dx, ax
	
	push dx ;keep it aside
	
	xchg dh, dl ;now, dh stores the y axis (row), dl stores the x axis (column)
	add dh, 2 ;go down two rows
	add dl, dl ;we are using two digits for each place, so we have to the double the visual movement
	inc dl ;go rigth one column
	xor bx, bx
	mov ah, 2
	int 10h
	mov bx, 10
	mov cx, 2
	mov ah, 9
	int 10h
	mov ah, 2
	mov dl, 219
	int 21h
	int 21h
	
	pop bx ;bh hold x axis, bl y axis (as dx did before)
	
waitForData:
	mov ah, 0
	int 16h
	cmp ah, right
	je MoveRight
	cmp ah, left
	je MoveLeft
	cmp ah, up
	je MoveUp
	cmp ah, down
	je MoveDown
	cmp ah, keyEnter
	je done3
	jmp waitForData
	
MoveRight:
	cmp bh, ROW_AMOUNT-1
	je waitForData
	inc di
	jmp present
MoveLeft:
	cmp bh, 0
	je waitForData
	dec di
	jmp present
MoveUp:
	cmp bl, 0
	je waitForData
	sub di, ROW_AMOUNT
	jmp present
MoveDown:
	cmp bl, ROW_AMOUNT-1
	je waitForData
	add di, ROW_AMOUNT
	jmp present
	
done3:
	mov [bp+4], di
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret
endp Choose_Place


;this procedure checks whether or not a position on th board is legal to place a ship part
;input: offset of place, board offset
;output: al = 0 if legal and al = -1 if illegal 
proc Check_legal_to_place
	push bp
	mov bp, sp
	push bx
	push ax
	
	mov ax, [bp+6]
	sub ax, [bp+4]
	mov bl, 10
	div bl ;ah has now x axis, al has y axis
	mov bx, [bp+6]
	
	BLUE equ ' '
	
CheckTop:
	cmp al, 0
	je CheckMid ;its is part of the top row
	cmp ah, 0
	je CheckTopMid ;it is part of the left column
CheckTopLeft:
	cmp [byte ptr bx-ROW_AMOUNT-1], BLUE
	jne illegal3
CheckTopMid:
	cmp [byte ptr bx-ROW_AMOUNT], BLUE
	jne illegal3
	cmp ah, ROW_AMOUNT-1
	je CheckMid ;it is part of the right column
CheckTopRight:
	cmp [byte ptr bx-ROW_AMOUNT+1], BLUE
	jne illegal3
	
CheckMid:
	cmp ah, 0
	je CheckMidMid ;it is part of the left column
CheckMidLeft:
	cmp [byte ptr bx-1], BLUE
	jne illegal3
CheckMidMid:
	cmp [byte ptr bx], BLUE
	jne illegal3
	cmp ah, ROW_AMOUNT-1
	je CheckBottom ;it is part of the right column
CheckMidRight:
	cmp [byte ptr bx+1], BLUE
	jne illegal3

	cmp al, ROW_AMOUNT-1
	je DoneChecking
CheckBottom:
	cmp ah, 0
	je CheckBottomMid
CheckBottomLeft:
	cmp [byte ptr bx+ROW_AMOUNT-1], BLUE
	jne illegal3
CheckBottomMid:
	cmp [byte ptr bx+ROW_AMOUNT], BLUE
	jne illegal3
	cmp ah, ROW_AMOUNT-1
	je DoneChecking ;it is part of the right column
CheckBottomRight:
	cmp [byte ptr bx+ROW_AMOUNT+1], BLUE
	jne illegal3
	
DoneChecking:
;if passed all the compares and got here, place is legal
	pop ax
	xor al, al
	pop bx
	pop bp
	ret 4
	
illegal3:
	pop ax
	mov al, -1
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
	mov cl, '0' ;cl keeps the value that will represent the ship on the board
start_placeing_ship:
	push -1
	call clear_board
	push bx
	call Present_Board
	push 0
	call explainColors
	
illegal4:
	mov ah, 9
	mov dx, offset place_ship1
	int 21h
	mov ch, [si] ;ch keep the length of the current placing ship
	mov dl, ch
	add dl, '0'
	mov ah, 2
	int 21h
	mov ah, 9
	mov dx, offset place_ship2
	int 21h
	
	push bx
	call Choose_Place
	pop di
	
	push di ;where the ship starts
	push bx
	call Check_legal_to_place
	cmp al, 0
	je legal3
	call clear_board
	push bx
	call Present_Board
	push 0
	call explainColors
	mov dx, offset illegal_place
	mov ah, 9
	int 21h
	jmp illegal4
legal3:
	push di ;keep in the stack segment the position future to be painted
	dec ch
	mov [byte ptr di], cl
	call clear_board
	push bx
	call Present_Board
	push 0
	call explainColors
illegal5:
	mov [byte ptr di], BLUE ;clears the place to allow correct checking of legal placing
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
	call clear_board
	push bx
	call Present_Board
	push 0
	call explainColors
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
	jb too_close_to_border
place_up1:
	sub di, ROW_AMOUNT
	push di
	push bx
	call Check_legal_to_place
	cmp al, 0
	jne remove_written_postitions ;remove the ship and go back to start placing it
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
	ja too_close_to_border
place_down1:
	add di, ROW_AMOUNT
	push di
	push bx
	call Check_legal_to_place
	cmp al, 0
	jne remove_written_postitions ;remove the ship and go back to start placing it
down_legal:
	push di
	dec ch
	cmp ch, 0
	jne place_down1
	jmp done_writing_positions
	
place_left:
;checks it is far enough from the border
	mov ax, di
	sub ax, bx
	mov dl, ROW_AMOUNT
	div dl ;ah stores x axis, al stores y axis
;ah stores how many tiles are there to the left
	
	cmp ah, ch
	jb too_close_to_border
place_left1:
	dec di
	push di
	push bx
	call Check_legal_to_place
	cmp al, 0
	jne remove_written_postitions ;remove the ship and go back to start placing it
left_legal:
	push di
	dec ch
	cmp ch, 0
	jne place_left1
	jmp done_writing_positions
	
place_right:
;checks it is far enough from the border
	mov ax, di
	sub ax, bx
	mov dl, ROW_AMOUNT
	div dl ;ah stores x axis, al stores y axis
;ah stores how many tiles are there to the left
	mov al, ROW_AMOUNT
	sub al, [si] ;al stores now how many tiles is max allow to be to the left
	cmp ah, al
	ja too_close_to_border
place_right1:
	inc di
	push di
	push bx
	call Check_legal_to_place
	cmp al, 0
	jne remove_written_postitions ;remove the ship and go back to start placing it
right_legal:
	push di
	dec ch
	cmp ch, 0
	jne place_right
	jmp done_writing_positions
	
too_close_to_border:
	sub sp, 2
	inc ch
	call clear_board
	push bx
	call Present_Board
	push 0
	call explainColors
	mov dx, offset no_space
	mov ah, 9
	int 21h
	jmp illegal4
;removes the saved positions from the stack until hits the -1 signing to stop
;this allows to start again placing a ship
remove_written_postitions:
	pop ax
	cmp ax, -1
	jne remove_written_postitions
	push -1
	call clear_board
	push bx
	call Present_Board
	push 0
	call explainColors
	mov dx, offset illegal_place
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
	cmp [byte ptr si], '$' ;checks if got to end of array
	jne start_placeing_ship
	
	call clear_board
	push bx
	call Present_Board
	push 0
	call explainColors
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

proc clear_board
	push ax
	mov ax, 3
	int 10h
	pop ax
	ret
endp clear_board
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
	xor bx, bx
	xor cx, cx
	xor dx, dx
	int 10h
	;moves the cursor to the start position
	
	mov dx, offset active_player_string
	mov ah, 9
	int 21h
	
	mov dl, 0ah
	mov ah, 2
	int 21h
	
	mov dx, offset tableTopPart
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
	push bx
	push cx
	mov dl, [bx]
	
BLUE equ ' '
RED equ 'x'
YELLOW equ 'm'
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

;this procedure explains what each color on the board means
;input: 0 for placing stage
;		1 for shooting stage
proc explainColors
	push bp
	mov bp, sp
	push ax
	push bx
	push cx
	push dx
	mov ah, 9
	mov cx, 2
	mov bx, 10
	int 10h
	mov dx, offset greenExplain
	int 21h
	mov bx, 1
	int 10h
	mov dx, offset blueExplain
	int 21h
	cmp [word ptr bp+4], 0
	je placeStage
	jne shootStage
placeStage:
	mov bx, 15
	int 10h 
	mov dx, offset whiteExplain
	int 21h
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret 2
shootStage:
	mov bx, 14
	int 10h
	mov dx, offset yellowExplain
	int 21h
	mov bx, 4
	int 10h 
	mov dx, offset redExplain
	int 21h
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret 2
endp explainColors


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
	push ax
	
	mov di, [bp+6] ;guessing board
	mov si, [bp+8] ;enemy board
	call clear_board
	push di
	call Present_Board
	push 1
	call explainColors
illegal2:
	
	mov dx, offset where_to_shoot
	mov ah, 9
	int 21h
	push di
	call Choose_Place
	pop bx 
	sub bx, di ;the number to add to a board's offset to get the desired place
	
	cmp [byte ptr di + bx], BLUE
	je shoot
	;already shot there
	call clear_board
	push di
	call Present_Board
	push 1
	call explainColors
	mov dx, offset shot_already
	mov ah, 9
	int 21h
	jmp illegal2
shoot:
	cmp [byte ptr si + bx], BLUE ;checks the value in the actual board
	je miss1

	mov [byte ptr di + bx], RED ;hit sign
	call clear_board
	push di
	call Present_Board
	push 1
	call explainColors
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
	mov si, [bp+4] ;left ship array
check_loop:
	cmp [byte ptr si], '$'
	je won ;continue checking until hit $ meaning array is over
	cmp [byte ptr si], 0
	jne continue_playing
	inc si
	jmp check_loop
won:
	pop ax
	mov al, 1
	jmp end_turn
miss1:
	mov [byte ptr di + bx], YELLOW ;miss sign
	call clear_board
	push di
	call Present_Board
	push 1
	call explainColors
	mov dx, offset miss
	mov ah, 9
	int 21h
continue_playing:
	pop ax
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
	jne turn_cycle
win1:
	mov dx, offset active_player_string
	mov ah, 9
	int 21h
	mov dx, offset win
	int 21h
	pop dx
	pop ax
	pop bp
	ret 12
endp Manage_Game

start:
	mov ax, @data
	mov ds, ax
; --------------------------
; Your code here
; --------------------------
	call clear_board
	mov dx, offset start_game
	mov ah, 9
	int 21h
	call Wait_for_key_press
	
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