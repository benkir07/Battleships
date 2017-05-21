IDEAL
MODEL small
STACK 100h
DATASEG
; --------------------------
; Your variables here
; --------------------------

ROW_AMOUNT equ 10
AREA equ ROW_AMOUNT * ROW_AMOUNT

;AI variables
Last_Hit_Part dw -1 ;remembers the offset of the last ship part hit, resets to -1 when ship is down
known_direction db 0 ;remebers the direction of the ship, -1 means the direction is unknown, 0 means up, 1 down, 2 left, 3 right

;actual variables
BLUE equ ' '
Player1Board db AREA dup (BLUE)
Player2Board db AREA dup (BLUE)

Player1Guessing db AREA dup (BLUE)
Player2Guessing db AREA dup (BLUE)

Starting_LeftShip db 2,3,3,4,5,'$' ;$ marks the end of the array
Player1LeftShip db 10 dup (0)
Player2LeftShip db 10 dup (0)

;output stuff
blueExplain db 219, 219, ' is an empty slot', 10, '$'
greenExplain db 219, 219,  ' is the slot you are currently looking at', 10, '$'
whiteExplain db 219, 219,  ' is a ship part', 10, '$'
redExplain db 219, 219,  ' is a slot that was shot and a ship discovered', 10, '$'
yellowExplain db 219, 219, ' is a slot uncovered to be without any ships', 10, '$'
active_player_string db 'Player $'
active_computer_string db 'Computer$'
place_ship1 db 'Starting to place a ship $'
place_ship2 db ' tiles long' , 10, 'Where would you like to have its first position?', 10, 'use the arrow keys to move your selected slot', 10, 'press enter when you have the slot you want to place selcted', 10, '$'
direction db 'What direction would you like this ship to continue?', 10, 'use the arrow keys', 10, '$'
direction2 db 'Press enter if you are satisfied with this placement', 10 ,'Press any other key to place this ship in another way', 10, '$'
illegal_direction db 'That is not a direction!', 10, '$'
illegal_place db 'There is an illegal place to place a ship in!' , 10, 'either one of its sides is taken or it is itelf taken', 10, '$'
no_space db 'There is no legal space in this direction to place a ship', 10, '$'
no_more_ship db 'You are done placing ships!' , 10, '$'
where_to_shoot db 'Where would you like to shoot?',10, 'use the arrow keys to move your selected slot', 10, 'press enter when you have the slot you want to shoot selcted',10,'$'
shot_already db 'You already uncovered this slot!', 10, '$'
miss db 'Miss!', 10, '$'
hit db 'Hit!', 10, '$'
fallen_ship db 'Ship is down! Ship is down!', 10, 'marking in yellow all adjacent slots', 10, '$'
any_key_to_continue db 'Press any key to continue...' , 10, '$'
computer_start_turn db 'This is the current state of the Compter, Computer Ready to shoot', 10 , '$'

;BMP print variables
	MenuPic db 'men.bmp',0
	RulesPic db 'rul.bmp',0
	PlayPic db 'pla.bmp',0
	Player1Win db 'pl1.bmp',0
	Player2Win db 'pl2.bmp',0
	win db 'win.bmp',0
	lose db 'los.bmp',0
	filehandle dw ?
	Header db 54 dup (0)
	Palette db 256*4 dup (0)
	ScrLine db 320 dup (0)
	ErrorMsg db 'Error', 13, 10,'$'

CODESEG
;this procedure allows the user to choose using the keyboard a position on the board
;input: active player number, offset of board
;output: offset of the chosen place
proc Choose_Place
	push bp
	mov bp, sp
	push ax
	push bx
	push cx
	push dx
	push si
	
	push [bp+6]
	push [bp+4]
	call Present_Board
	mov ax, 0
	int 33h
	
look_for_change:
	mov ax, 2
	int 33h
	mov ax, 3
	int 33h
	shr cx, 3
	shr dx, 3
	dec cx ;not counting the left part of present board
	shr cx, 1 ;we are using two digits for every slot, gotta remember that
	sub dx, 2 ;not counting the top part of the present board
	
	cmp cx, ROW_AMOUNT-1
	ja look_for_change
	cmp dx, ROW_AMOUNT-1
	ja look_for_change
	
	and bx, 1
	cmp bx, 1
	je chosen
	
	mov dh, dl ;board y axis
	add dh, 2
	mov dl, cl ;board x axis
	shl dl, 1
	inc dl
	
	cmp dx, si
	je look_for_change
	mov si, dx
	
	push [bp+6]
	push [bp+4]
	call Present_Board
	
	mov bh, 0
	mov ah, 2
	int 10h ;moves the cursor to the mouse
	
	mov ah, 9
	mov bx, 10 ;color number
	mov cx, 2
	int 10h ;changes the color
	mov ah, 2
	mov dl, 219
	int 21h
	int 21h
	jmp look_for_change

chosen:
	;now cx has x axis, and dx y axis of the board (not screen)
	mov al, dl ;y axis
	mov ah, ROW_AMOUNT
	mul ah
	add ax, cx ;x axis, ax has now the number to add to the board to get the chosen offset
	add ax, [bp+4]
	
	mov [bp+6], ax
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret 2
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
	mov bl, ROW_AMOUNT
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
;input: active player number, offset of the player's board, offset of an array keeping lengths of the ships to place
;output: none
proc CreatePlayerBoard
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
	push [bp+8]
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
	
	push [bp+8]
	push bx
	call Choose_Place
	pop di
	
	push di ;where the ship starts
	push bx
	call Check_legal_to_place
	cmp al, 0
	je legal3
	call clear_board
	push [bp+8]
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
	mov [byte ptr di], GREEN
	call clear_board
	push [bp+8]
	push bx
	call Present_Board
	push 0
	call explainColors
illegal5:
	mov [byte ptr di], BLUE ;clears the place to allow correct checking of legal placing
	
	up equ 048h
	left equ 04Bh
	down equ 050h
	right equ 04Dh
	
	mov ah, 9
	mov dx, offset direction
	int 21h
	mov ah, 0
	int 16h
	cmp ah, up
	je place_up
	cmp ah, down
	je place_down
	cmp ah, left
	je place_left
	cmp ah, right
	je place_right
	
;if here, input wasn't legal
	mov [byte ptr di], GREEN
	call clear_board
	push [bp+8]
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
	jl too_close_to_border
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
	jl too_close_to_border
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
	jne place_right1
	jmp done_writing_positions
	
too_close_to_border:
	add sp, 2
	inc ch
	call clear_board
	push [bp+8]
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
	push [bp+8]
	push bx
	call Present_Board
	push 0
	call explainColors
	mov dx, offset illegal_place
	mov ah, 9
	int 21h
	jmp illegal4
	
done_writing_positions:
	push bp
	mov bp, sp
place_ship:
	add bp, 2
	mov di, [bp]
	cmp di, -1
	je ship_placed
GREEN equ 'n'
	mov [byte ptr di], GREEN
	jmp place_ship
ship_placed:
	mov bp, sp
	pop bp
	call clear_board
	push [bp+8]
	push bx
	call Present_Board
	push 0
	call explainColors
	mov ah, 9
	mov dx, offset direction2
	int 21h
	
	keyEnter equ 01Ch
	mov ah, 0
	int 16h
	cmp ah, keyEnter
	je paint_ship_white
delete_positions:
	pop di
	cmp di, -1
	je start_placeing_ship
	mov [byte ptr di], BLUE
	jmp delete_positions
	
	
	
paint_ship_white:
	pop di
	cmp di, -1
	je done_placing_a_ship ;clears the stack from not wanted positions
	mov [di], cl
	jmp paint_ship_white
done_placing_a_ship:
	inc cl
	inc si
	cmp [byte ptr si], '$' ;checks if got to end of array
	jne start_placeing_ship
	
	call clear_board
	push [bp+8]
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
	ret 6
endp CreatePlayerBoard

;this procedure places ships on the board randomly
;input: offset of the computer's board, offset of an array keeping lengths of the ships to place
;output: none
proc CreateComputerBoard
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
start_placeing_ship_:
	push -1
illegal4_:
	mov ch, [si] ;ch represents the left slots to place
	push cx
	mov ah, 2Ch
	int 21h ;random place
	pop cx
	mov al, dl
	mov ah, AREA
	mul ah
	mov dl, 100
	div dl ;al has a random numeber betwin 0 and AREA-1
	xor ah, ah
	mov di, ax
	add di, bx ;di has now the position looked at
	
	push di ;where the ship starts
	push bx
	call Check_legal_to_place
	cmp al, 0
	jne illegal4_
	push di ;keep in the stack segment the position future to be painted
	dec ch

	push cx
	mov ah, 2Ch
	int 21h ;random direction
	pop cx
	mov al, dl
	xor ah, ah
	mov dl, 4
	div dl ;ah=0 would mean up, ah=1 down, ah=2 left, ah=3 right
	cmp ah, 0
	je place_up_
	cmp ah, 1
	je place_down_
	cmp ah, 2
	je place_left_
	jmp place_right_
	
place_up_:
;checks it is far enough from the border
	mov al, ROW_AMOUNT
	mul ch ;ax stores now how much could be between di and bx, where we place and the board's start
	mov dx, di
	sub dx, ax ;dx stores now where the last placement would be
	cmp dx, bx
	jl too_close_to_border_
place_up1_:
	sub di, ROW_AMOUNT
	push di
	push bx
	call Check_legal_to_place
	cmp al, 0
	jne remove_written_postitions_ ;remove the ship and go back to start placing it
up_legal_:
	push di
	dec ch
	cmp ch, 0
	jne place_up1_
	jmp done_writing_positions_
	
place_down_:
;checks it is far enough from the border
	mov al, ROW_AMOUNT
	mul ch ;ax stores now how much could be between di and bx, where we place and the board's start
	mov dx, di
	add dx, ax ;dx stores now where the last placement would be
	mov ax, bx
	add ax, AREA-1 ;ax stores the end of the board
	cmp dx, ax
	ja too_close_to_border_
place_down1_:
	add di, ROW_AMOUNT
	push di
	push bx
	call Check_legal_to_place
	cmp al, 0
	jne remove_written_postitions_ ;remove the ship and go back to start placing it
down_legal_:
	push di
	dec ch
	cmp ch, 0
	jne place_down1_
	jmp done_writing_positions_
	
place_left_:
;checks it is far enough from the border
	mov ax, di
	sub ax, bx
	mov dl, ROW_AMOUNT
	div dl ;ah stores x axis, al stores y axis
;ah stores how many tiles are there to the left
	
	cmp ah, ch
	jl too_close_to_border_
place_left1_:
	dec di
	push di
	push bx
	call Check_legal_to_place
	cmp al, 0
	jne remove_written_postitions_ ;remove the ship and go back to start placing it
left_legal_:
	push di
	dec ch
	cmp ch, 0
	jne place_left1_
	jmp done_writing_positions_
	
place_right_:
;checks it is far enough from the border
	mov ax, di
	sub ax, bx
	mov dl, ROW_AMOUNT
	div dl ;ah stores x axis, al stores y axis
;ah stores how many tiles are there to the left
	mov al, ROW_AMOUNT
	sub al, [si] ;al stores now how many tiles is max allow to be to the left
	cmp ah, al
	ja too_close_to_border_
place_right1_:
	inc di
	push di
	push bx
	call Check_legal_to_place
	cmp al, 0
	jne remove_written_postitions_ ;remove the ship and go back to start placing it
right_legal_:
	push di
	dec ch
	cmp ch, 0
	jne place_right1_
	jmp done_writing_positions_
	
too_close_to_border_:
	add sp, 2
	jmp illegal4_
;removes the saved positions from the stack until hits the -1 signing to stop
;this allows to start again placing a ship
remove_written_postitions_:
	pop ax
	cmp ax, -1
	jne remove_written_postitions_
	push -1
	jmp illegal4_
	
done_writing_positions_:
	pop di
	cmp di, -1
	je done_placing_a_ship_
	mov [di], cl
	jmp done_writing_positions_
done_placing_a_ship_:
	inc cl
	inc si
	cmp [byte ptr si], '$' ;checks if got to end of array
	jne start_placeing_ship_
	
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret 4
endp CreateComputerBoard

proc clear_board
	push ax
	mov ax, 3
	int 10h
	pop ax
	ret
endp clear_board
;this procedure prints to the screen a chosen board
;input: active player number (-1 if computer), the board to print's offset
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
	
	cmp [word ptr bp+6], -1
	jne Player
	mov dx, offset active_computer_string
	int 21h
	jmp continue1
	
Player:
	mov dx, [bp+6]
	mov ah, 2
	int 21h
	
continue1:
	mov ah, 2
	mov dl, 0ah
	int 21h
	
	mov dl, ' '
	int 21h
	mov cx, ROW_AMOUNT
	mov dl, 'a'
printTopPart:
	int 21h
	push dx
	mov dl, ' '
	int 21h
	pop dx
	inc dx
	loop printTopPart
	
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
GREEN equ 'n'
;anything else is white
	
	cmp dl, BLUE
	je blue1
	cmp dl, RED
	je red1
	cmp dl, YELLOW
	je yellow1
	cmp dl, GREEN
	je green1
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
	jmp AfterColorSet
green1:
	mov bx, 10
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
	push bx
	push cx
	mov ah, 9
	mov cx, 1
	mov bx, 0
	int 10h
	mov ah, 2
	mov dl, 219
	int 21h ;visual help :)
	pop cx
	pop bx
	
	inc ch
	cmp ch, ROW_AMOUNT
	jb anotherLine
	
	mov dl, 0ah
	mov ah, 2
	int 21h
	
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret 4
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
;input: active player number, enemy's board offset, active player's guessing board offset, enemy's array of left ship offset
;output: al = 1 if won and al = 0 to continue
proc player_turn
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
	push [bp+10]
	push di
	call Present_Board
	push 1
	call explainColors
illegal2:
	
	mov dx, offset where_to_shoot
	mov ah, 9
	int 21h
	push [bp+10]
	push di
	call Choose_Place
	pop bx 
	sub bx, di ;the number to add to a board's offset to get the desired place
	
	cmp [byte ptr di + bx], BLUE
	je shoot
	;already shot there
	call clear_board
	push [bp+10]
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
	push [bp+10]
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
;ship is down
	push di
	push bx
	call mark_around_fallen_ship
	call clear_board
	push [bp+10]
	push di
	call Present_Board
	push 1
	call explainColors
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
	push [bp+10]
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
	ret 8
endp player_turn

; this procedure detectes the placements of a ship and marks yellow around it so the player would know it is down
; input: guessing board offset, a number to add to the board to get one of the ship's places
proc mark_around_fallen_ship
	push bp
	mov bp, sp
	push ax
	push bx
	push si
	push di
	
	mov si, [bp+6] ;the board
	add si, [bp+4] ;the look at position
	mov ax, [bp+4]
	mov bl, ROW_AMOUNT
	div bl ;ah has x axis, al has y axis
	
	
;this part checks what direction the ship continues	
check_up:
	cmp al, 0
	je check_left
	cmp [byte ptr si - ROW_AMOUNT], RED
	je continue_up
	
check_left:
	cmp ah, 0
	je check_down ;if jumps here, we know it is the edge, we don't know in which direction
	cmp [byte ptr si - 1], RED
	je continue_left
	
check_down:
	cmp al, ROW_AMOUNT-1
	je mark_right ;we know it is not going up, not left and it can't go down, so it is left edge
	cmp [byte ptr si + ROW_AMOUNT], RED
	je mark_down ;if jumps here, we know it is the edge, and it move down from here
	jmp mark_right ;if it isn't going left, up, or down, it is going right, which is left edge
;
;this part moves the pointer (si) to the edge of the top or left edge of the ship (depending on its direction)
continue_up:
	sub si, ROW_AMOUNT
	dec al
	;checks the upper slot
	cmp al, 0
	je mark_down ;if it is top part, it is the edge
	cmp [byte ptr si - ROW_AMOUNT], RED
	je continue_up
	jmp mark_down
	
continue_left:
	dec si
	dec ah
	;checks the slot to the left
	cmp ah, 0
	je mark_right
	cmp [byte ptr si - 1], RED
	je continue_left
	jmp mark_right
;
;this part moves down or right and marks it (depending on ship's direction)
mark_down:
	cmp al, 0
	je down_mark_loop
	cmp ah, 0
	je after_left_marked
	mov [byte ptr si-ROW_AMOUNT-1], YELLOW
after_left_marked:
	mov [byte ptr si-ROW_AMOUNT], YELLOW
	cmp ah, ROW_AMOUNT-1
	je down_mark_loop
	mov [byte ptr si-ROW_AMOUNT+1], YELLOW
	
down_mark_loop:
	cmp ah, 0
	je mark_right_slot
	mov [byte ptr si-1], YELLOW
mark_right_slot:
	cmp ah, ROW_AMOUNT-1
	je check_bottom_edge
	mov [byte ptr si+1], YELLOW
check_bottom_edge:
	cmp al, ROW_AMOUNT-1
	je done_marking
	cmp [byte ptr si+ROW_AMOUNT], RED
	jne mark_bottom_part
	add si, ROW_AMOUNT
	inc al ;y axis
	jmp down_mark_loop

mark_bottom_part:	
	cmp ah, 0
	je mark_bottom_middle
	mov [byte ptr si+ROW_AMOUNT-1], YELLOW
mark_bottom_middle:
	mov [byte ptr si+ROW_AMOUNT], YELLOW
	cmp ah, ROW_AMOUNT-1
	je done_marking
	mov [byte ptr si+ROW_AMOUNT+1], YELLOW
	jmp done_marking
	
	
	
mark_right:
	cmp ah, 0
	je right_mark_loop
	cmp al, 0
	je after_top_marked
	mov [byte ptr si-ROW_AMOUNT-1], YELLOW
after_top_marked:
	mov [byte ptr si-1], YELLOW
	cmp al, ROW_AMOUNT-1
	je right_mark_loop
	mov [byte ptr si+ROW_AMOUNT-1], YELLOW
	
right_mark_loop:
	cmp al, 0
	je mark_bottom_slot
	mov [byte ptr si-ROW_AMOUNT], YELLOW
mark_bottom_slot:
	cmp al, ROW_AMOUNT-1
	je check_right_edge
	mov [byte ptr si+ROW_AMOUNT], YELLOW
check_right_edge:
	cmp ah, ROW_AMOUNT-1
	je done_marking
	cmp [byte ptr si+1], RED
	jne mark_right_part
	inc si
	inc ah ;x axis
	jmp right_mark_loop

mark_right_part:	
	cmp al, 0
	je mark_right_middle
	mov [byte ptr si-ROW_AMOUNT+1], YELLOW
mark_right_middle:
	mov [byte ptr si+1], YELLOW
	cmp al, ROW_AMOUNT-1
	je done_marking
	mov [byte ptr si+ROW_AMOUNT+1], YELLOW
	jmp done_marking

done_marking:
	pop di
	pop si
	pop bx
	pop ax
	pop bp
	ret 4
endp mark_around_fallen_ship

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

;this procedure runs a two player match, creating boards and then running the game
;input: first player's: board, guessing board, left ship array
;		second player's: board, guessing board, left ship array
proc two_player_match
	push bp
	mov bp, sp
	push ax
	push bx
	push dx
	
	push [bp+14] ;Player1Board
	push [bp+12] ;Player1Guessing
	push [bp+10] ;Player1LeftShip
	push [bp+8] ;Player2Board
	push [bp+6] ;Player2Guessing
	push [bp+4] ;Player2LeftShip
	call reset_variables
	
	mov bx, '1' ;active player number
	
	push bx
	push [bp+14] ;Player1Board
	push [bp+10] ;Player1LeftShip
	call CreatePlayerBoard
	xor bx, 11b
	call Wait_for_key_press
	push bx
	push [bp+8] ;Player2Board
	push [bp+4] ;Player2LeftShip
	call CreatePlayerBoard
	call Wait_for_key_press
	xor bx, 11b
	
	
turn_cycle:
	push bx
	push [bp+8] ;Player2Board
	push [bp+12] ;Player1Guessing
	push [bp+4] ;Player2LeftShip
	call player_turn
	cmp al, 1
	je win1
	call Wait_for_key_press
	xor bx, 11b
	push bx
	push [bp+14] ;Player1Board
	push [bp+6] ;Player2Guessing
	push [bp+10] ;Player1LeftShip
	call player_turn
	cmp al, 1
	je win2
	call Wait_for_key_press
	xor bx, 11b
	jmp turn_cycle
win1:
	push offset Player1Win
	call PrintBMP
	jmp end_game
win2:
	push offset Player2Win
	call PrintBMP
end_game:
	mov ah, 0
	int 16h
	
	pop dx
	pop bx
	pop ax
	pop bp
	ret 12
endp two_player_match

;this procedure resets all variables needed to run a match to thier starting values
;input: first player's: board, guessing board, left ship array
;		second player's: board, guessing board, left ship array
;output: the given variables reset
proc reset_variables
	push bp
	mov bp, sp
	push ax
	push bx
	push si
	push di

	mov si, AREA-1
reset_boards:
	mov bx, [bp+14]
	mov [byte ptr bx+si], BLUE
	mov bx, [bp+12]
	mov [byte ptr bx+si], BLUE
	mov bx, [bp+8]
	mov [byte ptr bx+si], BLUE
	mov bx, [bp+6]
	mov [byte ptr bx+si], BLUE
	cmp si, 0
	je done_boards
	dec si
	jmp reset_boards
	
done_boards:
	mov bx, offset Starting_LeftShip
	mov si, [bp+10]
	mov di, [bp+4]
reset_left_ship:
	mov al, [bx]
	mov [si], al
	mov [di], al
	cmp [byte ptr bx], '$'
	je done_left_ships
	inc bx
	inc si
	inc di
	jmp reset_left_ship
	
done_left_ships:
	pop di
	pop si
	pop bx
	pop ax
	pop bp
	ret 12
endp reset_variables

;this procedure runs a turn of the computer, using basic thinking to try and make some good shots
;input: player's board offset, computer's guessing board, player's left ships array, last_hit_part offset, known_direction offset
proc computer_turn
	push bp
	mov bp, sp
	push bx
	push cx
	push dx
	push si
	push di
	push ax
	
	mov di, [bp+10] ;computer's guessing board
	mov si, [bp+12] ;player's board
	
	call clear_board
	push -1
	push di
	call Present_Board
	push 1
	call explainColors
	mov dx, offset computer_start_turn
	mov ah, 9
	int 21h
	call Wait_for_key_press
	
	mov bx, [bp+6]
	cmp [word ptr bx], -1
	je randomPlace
	
	mov bx, [bp+4]
	cmp [byte ptr bx], -1
	jne shoot_direction
	
randomDirection:
	mov ah, 2Ch
	int 21h
	mov al, dl
	xor ah, ah
	mov dl, 25
	div dl ;al=0 would mean up, al=1 down, al=2 left, al=3 right
	mov bx, [bp+6]
	mov bx, [bx]
	cmp al, 0
	je up1
	cmp al, 1
	je down1
	
	push ax
	mov ax, bx
	mov dl, ROW_AMOUNT
	div dl ;ah has x axis, al has y axis
	mov dx, ax
	pop ax
	cmp al, 2
	je left1
	jmp right1
up1:
	cmp bx, ROW_AMOUNT
	jb randomDirection
	sub bx, ROW_AMOUNT
	cmp [byte ptr di+bx], BLUE
	jne randomDirection
	jmp shoot1
down1:
	add bx, ROW_AMOUNT
	cmp bx, AREA
	jae randomDirection
	cmp [byte ptr di+bx], BLUE
	jne randomDirection
	jmp shoot1
left1:
	cmp dh, 0
	je randomDirection
	dec bx
	cmp [byte ptr di+bx], BLUE
	jne randomDirection
	jmp shoot1
right1:
	cmp dh, ROW_AMOUNT-1
	je randomDirection
	inc bx
	cmp [byte ptr di+bx], BLUE
	jne randomDirection
	jmp shoot1
	
switchDirection:
	push bx
	mov bx, [bp+4]
	xor [byte ptr bx], 1 ;switches 0 to 1, and 2 to 3 and backwards (effectivly up to down and left to right and backwards)
	pop bx
shoot_direction:
	mov bx, [bp+4]
	mov al, [bx]
	mov bx, [bp+6]
	mov bx, [bx]
	cmp al, 0
	je up2
	cmp al, 1
	je down2
	
	push ax
	mov ax, bx
	mov dl, ROW_AMOUNT
	div dl ;ah has x axis, al has y axis
	mov dx, ax
	pop ax
	cmp al, 2
	je left2
	jmp right2
up2:
	cmp bx, ROW_AMOUNT
	jb switchDirection
	sub bx, ROW_AMOUNT
	cmp [byte ptr di+bx], YELLOW
	je switchDirection
	cmp [byte ptr di+bx], RED
	je up2
	jmp shoot1
down2:
	add bx, ROW_AMOUNT
	cmp bx, AREA
	jae switchDirection
	cmp [byte ptr di+bx], YELLOW
	je switchDirection
	cmp [byte ptr di+bx], RED
	je down2
	jmp shoot1
left2:
	cmp dh, 0
	je switchDirection
	dec bx
	cmp [byte ptr di+bx], YELLOW
	je switchDirection
	cmp [byte ptr di+bx], RED
	je left2
	jmp shoot1
right2:
	cmp dh, ROW_AMOUNT-1
	je switchDirection
	inc bx
	cmp [byte ptr di+bx], YELLOW
	je switchDirection
	cmp [byte ptr di+bx], RED
	je right2
	jmp shoot1
	
	
randomPlace:
	mov ah, 2Ch
	int 21h
	mov al, dl
	mov ah, AREA
	mul ah
	mov dl, 100
	div dl ;al has a random numeber betwin 0 and AREA-1
	xor ah, ah
	mov bx, ax
	
	cmp [byte ptr di+bx], BLUE
	jne randomPlace
	mov al, -1
shoot1:
	cmp [byte ptr si + bx], BLUE ;checks the value in the actual board
	je miss2

	mov [byte ptr di + bx], RED ;hit sign
	mov cx, bx
	mov bx, [bp+6]
	mov [bx], cx
	mov bx, [bp+4]
	mov [bx], al
	mov bx, cx
	call clear_board
	push -1
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
	mov si, [bp+8] ;left ship array
	add si, ax
	dec [byte ptr si]
	cmp [byte ptr si], 0
	jne continue_playing1
;ship is down
	push bx
	mov bx, [bp+6]
	mov [word ptr bx], -1
	mov bx, [bp+4]
	mov [byte ptr bx], -1
	pop bx
	push di
	push bx
	call mark_around_fallen_ship
	call clear_board
	push -1
	push di
	call Present_Board
	push 1
	call explainColors
	mov dx, offset fallen_ship
	mov ah, 9
	int 21h
	mov si, [bp+8] ;left ship array
check_loop1:
	cmp [byte ptr si], '$'
	je won1 ;continue checking until hit $ meaning array is over
	cmp [byte ptr si], 0
	jne continue_playing1
	inc si
	jmp check_loop1
won1:
	pop ax
	mov al, 1
	jmp end_turn1
miss2:
	mov [byte ptr di + bx], YELLOW ;miss sign
	call clear_board
	push -1
	push di
	call Present_Board
	push 1
	call explainColors
	mov dx, offset miss
	mov ah, 9
	int 21h
continue_playing1:
	pop ax
	xor al, al
end_turn1:
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop bp
	ret 10
endp computer_turn
	
;this procedure gets already existing boards and runs a single game using them
;input: player's: board, guessing board, left ship array
;		computer's: board, guessing board, left ship array
proc one_player_Match
	push bp
	mov bp, sp
	push ax
	push dx
	
	push [bp+14] ;playerBoard
	push [bp+12] ;playerGuessingBoard
	push [bp+10] ;playerLeftShip
	push [bp+8] ;computerBoard
	push [bp+6] ;computerGuessingBoard
	push [bp+4] ;computerLeftShips
	call reset_variables
	
	push '1'
	push [bp+14] ;playerBoard
	push [bp+10] ;playerLeftShip
	call CreatePlayerBoard
	call Wait_for_key_press
	push [bp+8]
	push [bp+4]
	call CreateComputerBoard
	
	
turn_cycle1:
	push '1'
	push [bp+8] ;computerBoard
	push [bp+12] ;playerGuessingBoard
	push [bp+4] ;computerLeftShip
	call player_turn
	cmp al, 1
	je win3
	call Wait_for_key_press
	push [bp+14] ;playerBoard
	push [bp+6] ;computerGuessingBoard
	push [bp+10] ;playerLeftShip
	push offset Last_Hit_Part
	push offset known_direction
	call computer_turn
	cmp al, 1
	je lose1
	call Wait_for_key_press
	jmp turn_cycle1
win3:
	push offset win
	call PrintBMP
	jmp end_game1
lose1:
	push offset lose
	call PrintBMP
end_game1:
	mov ah, 0
	int 16h
	pop dx
	pop ax
	pop bp
	ret 12
endp one_player_Match

;opens a file
;input: offset file name
;output: file's handle
proc OpenFile
	push bp
	mov bp, sp
	push ax
	push bx
	push dx
	; Open file
	mov ah, 3Dh
	xor al, al
	mov dx, [bp+4] ;file name
	int 21h
	jc openerror
	mov [bp+4], ax ;file's handle
	
	pop dx
	pop bx
	pop ax
	pop bp
	ret
openerror:
	mov dx, offset ErrorMsg
	mov ah, 9h
	int 21h
	pop dx
	pop bx
	pop ax
	pop bp
	ret
endp OpenFile

;Reads Header and Palette
;input: file handle, offset to put header, offset to put Palette
;output: 
proc ReadHeaderPalette
	push bp
	mov bp, sp
	push ax
	push bx
	push cx
	push dx
	mov bx, [bp+8]
	mov ah,3fh
	mov cx,54
	mov dx, [bp+6]
	int 21h
	; Read BMP file color palette, 256 colors * 4 bytes (400h)
	mov ah,3fh
	mov cx,400h
	mov dx, [bp+4]
	int 21h
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret 6
endp ReadHeaderPalette

;Copies the palette
;input: file handle, offset to read Palette from
proc CopyPal
	push bp
	mov bp, sp
	push ax
	push bx
	push cx
	push dx
	push si
	mov bx, [bp+6]
	; Copy the colors palette to the video memory
	; The number of the first color should be sent to port 3C8h
	; The palette is sent to port 3C9h
	mov si, [bp+4]
	mov cx,256
	mov dx,3C8h
	mov al,0
	; Copy starting color to port 3C8h
	out dx,al
	; Copy palette itself to port 3C9h
	inc dx
PalLoop:
	; Note: Colors in a BMP file are saved as BGR values rather than RGB.
	mov al,[si+2] ; Get red value.
	shr al,2 ; Max. is 255, but video palette maximal
	; value is 63. Therefore dividing by 4.
	out dx,al ; Send it.
	mov al,[si+1] ; Get green value.
	shr al,2
	out dx,al ; Send it.
	mov al,[si] ; Get blue value.
	shr al,2
	out dx,al ; Send it.
	add si,4 ; Point to next color.
	; (There is a null chr. after every color.)
	loop PalLoop
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret 4
endp CopyPal

;prints to the graphic screen the BMP file (after opening file, reading palette and copying it)
;input: file handle
proc CopyBitmap
	push bp
	mov bp, sp
	push ax
	push bx
	push cx
	push dx
	push di
	push si
	mov bx, [bp+4] ;handle
	; BMP graphics are saved upside-down.
	; Read the graphic line by line (200 lines in VGA format),
	; displaying the lines from bottom to top.
	mov ax, 0A000h
	mov es, ax
	mov cx,200
PrintBMPLoop:
	push cx
	; di = cx*320, point to the correct screen line
	mov di,cx
	shl cx,6
	shl di,8
	add di,cx
	; Read one line
	mov ah,3fh
	mov cx,320
	mov dx,offset ScrLine
	int 21h
	; Copy one line into video memory
	cld ; Clear direction flag, for movsb
	mov cx,320
	mov si,offset ScrLine
	rep movsb ; Copy line to the screen
	;rep movsb is same as the following code:
	;mov es:di, ds:si
	;inc si
	;inc di
	;dec cx
	pop cx
	loop PrintBMPLoop
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret 2
endp CopyBitmap

;closes an open file
;input: file handle
proc CloseFile
	push bp
	mov bp, sp
	push ax
	push bx
	mov ah, 03Eh
	mov bx, [bp+4]
	int 21h
	pop bx
	pop ax
	pop bp
	ret 2
endp CloseFile

;this procedure prints to the screen a BMP file
;input: offset of file's name
proc PrintBMP
	push bp
	mov bp, sp
	push ax
	
	; Graphic mode
	mov ax, 13h
	int 10h
	; Process BMP file
	push [bp+4]
	call OpenFile
	pop ax ;file's handle
	push ax
	push offset Header
	push offset Palette
	call ReadHeaderPalette
	push ax
	push offset Palette
	call CopyPal
	push ax
	call CopyBitmap
	push ax
	call CloseFile
	
	pop ax
	pop bp
	ret 2
endp PrintBMP

proc MainMenu
	push ax
	push bx
	push cx
	push dx
	
	mov ax, 0
	int 33h
PresentMain:
	push offset MenuPic
	call PrintBMP
MainMenuDataWait:
	mov ax, 1
	int 33h
	mov ax, 3
	int 33h
	and bx, 1
	cmp bx, 1
	jne MainMenuDataWait
	
MainMenuReleaseWait:
	mov ax, 3
	int 33h
	and bx,1
	cmp bx, 1
	je MainMenuReleaseWait
	
	cmp cx, 0088h
	jb MainMenuDataWait
	cmp cx, 01CAh
	ja MainMenuDataWait
	cmp dx, 002Dh
	jb MainMenuDataWait
	cmp dx, 0040h
	jb Play
	cmp dx, 004Fh
	jb MainMenuDataWait
	cmp dx, 0062h
	jb Rules
	cmp dx, 0072h
	jb MainMenuDataWait
	cmp dx, 0082h
	jb ExitButton
	jmp MainMenuDataWait
	
	
	
play:
	call PlayMenu
	jmp PresentMain
Rules:
	push offset RulesPic
	call PrintBMP
	mov ah, 0
	int 16h
	jmp PresentMain
	
ExitButton:
	call clear_board
	pop dx
	pop cx
	pop bx
	pop ax
	ret
endp MainMenu

proc PlayMenu
	push ax
	push bx
	push cx
	push dx
	
	push offset PlayPic
	call PrintBMP
PlayMenuDataWait:
	mov ax, 1
	int 33h
	mov ax, 3
	int 33h
	and bx, 1
	cmp bx, 1
	jne PlayMenuDataWait
PlayMenuReleaseWait:
	mov ax, 3
	int 33h
	and bx,1
	cmp bx, 1
	je PlayMenuReleaseWait
	
	cmp cx, 0088h
	jb PlayMenuDataWait
	cmp cx, 01CAh
	ja PlayMenuDataWait
	cmp dx, 002Dh
	jb PlayMenuDataWait
	cmp dx, 0040h
	jb OnePlayer
	cmp dx, 004Fh
	jb PlayMenuDataWait
	cmp dx, 0062h
	jb TwoPlayer
	cmp dx, 0072h
	jb PlayMenuDataWait
	cmp dx, 0082h
	jb BackToMainMenu
	jmp PlayMenuDataWait
	
OnePlayer:
	push offset Player1Board
	push offset Player1Guessing
	push offset Player1LeftShip
	push offset Player2Board
	push offset Player2Guessing
	push offset Player2LeftShip
	call one_player_Match
	jmp BackToMainMenu
TwoPlayer:
	push offset Player1Board
	push offset Player1Guessing
	push offset Player1LeftShip
	push offset Player2Board
	push offset Player2Guessing
	push offset Player2LeftShip
	call two_player_Match
BackToMainMenu:
	
	pop dx
	pop cx
	pop bx
	pop ax
	ret
endp PlayMenu
start:
	mov ax, @data
	mov ds, ax
; --------------------------
; Your code here
; --------------------------
	call MainMenu
exit:
	mov ax, 4c00h
	int 21h
END start