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
	PlayPic db 'pla.bmp',0
	rules1 db 'ru1.bmp' ,0
	rules2 db 'ru2.bmp',0
	rules3 db 'ru3.bmp' ,0
	rules4 db 'ru4.bmp' ,0
	Player1Win db 'pl1.bmp',0
	Player2Win db 'pl2.bmp',0
	win db 'win.bmp',0
	lose db 'los.bmp',0
	Header db 54 dup (0)
	Palette db 256*4 dup (0)
	ScrLine db 320 dup (0)
	ErrorMsg db 'Error', 13, 10,'$'

CODESEG
;this procedure allows the user to choose using the keyboard a position on the board
;input: active player number
;		offset of board
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
	push [bp+6]
	push si
	call Present_Board
	
	mov ax, di
	sub ax, si ;ax has now the raw value of the place's offset (place offset - board offset)
	mov bl, ROW_AMOUNT
	div bl ;ah holds the x axis (0-9), al holds the y axis (0-9)
	mov dx, ax
	push dx ;keep it aside for more use later
	xchg dh, dl ;now, dh stores the y axis (row), dl stores the x axis (column), as needed for int 10h changing cursor position
	add dh, 2 ;go down two rows
	add dl, dl ;we are using two digits for each place, so we have to the double the visual movement
	inc dl ;go rigth one column
	xor bx, bx
	mov ah, 2
	int 10h ;moves the cursor, dh y axis, dl x axis
	mov bx, 10 ;light green
	mov cx, 2
	mov ah, 9
	int 10h ;changes the next two digits to light green
	mov ah, 2
	mov dl, 219
	int 21h
	int 21h
	
	pop bx ;bh hold x axis, bl y axis (as dx did before)
	
	up equ 048h
	left equ 04Bh
	down equ 050h
	right equ 04Dh
	keyEnter equ 01Ch
	;scan codes
	
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
	je chosen
	jmp waitForData
	
MoveRight:
	cmp bh, ROW_AMOUNT-1 ;makes sure player is not trying to move out of the boundries
	je waitForData
	inc di
	jmp present
MoveLeft:
	cmp bh, 0 ;makes sure player is not trying to move out of the boundries
	je waitForData
	dec di
	jmp present
MoveUp:
	cmp bl, 0 ;makes sure player is not trying to move out of the boundries
	je waitForData
	sub di, ROW_AMOUNT
	jmp present
MoveDown:
	cmp bl, ROW_AMOUNT-1 ;makes sure player is not trying to move out of the boundries
	je waitForData
	add di, ROW_AMOUNT
	jmp present
	
chosen:
	mov [bp+6], di
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret 2
endp Choose_Place


;this procedure checks whether or not a position on the board is legal to place a ship part (checks its surrondings)
;input: offset of place
;		board offset
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
	je CheckMid ;its is part of the top row so we should not check its top surronding
	cmp ah, 0
	je CheckTopMid ;it is part of the left column so we should not check its TopLeft corner
CheckTopLeft:
	cmp [byte ptr bx-ROW_AMOUNT-1], BLUE
	jne illegal3
CheckTopMid:
	cmp [byte ptr bx-ROW_AMOUNT], BLUE
	jne illegal3
	cmp ah, ROW_AMOUNT-1
	je CheckMid ;it is part of the right column so we should not check its TopRight corner
CheckTopRight:
	cmp [byte ptr bx-ROW_AMOUNT+1], BLUE
	jne illegal3
	
CheckMid:
	cmp ah, 0
	je CheckMidMid ;it is part of the left column so we should not check its left slot
CheckMidLeft:
	cmp [byte ptr bx-1], BLUE
	jne illegal3
CheckMidMid:
	cmp [byte ptr bx], BLUE
	jne illegal3
	cmp ah, ROW_AMOUNT-1
	je CheckBottom ;it is part of the right column so we should not check its right slot
CheckMidRight:
	cmp [byte ptr bx+1], BLUE
	jne illegal3

	cmp al, ROW_AMOUNT-1
	je DoneChecking ;it is part of the bottom row, so we should not check its bottom surronding
CheckBottom:
	cmp ah, 0
	je CheckBottomMid ;its is part of the left column, so we should not check its BottomLeft corner
CheckBottomLeft:
	cmp [byte ptr bx+ROW_AMOUNT-1], BLUE
	jne illegal3
CheckBottomMid:
	cmp [byte ptr bx+ROW_AMOUNT], BLUE
	jne illegal3
	cmp ah, ROW_AMOUNT-1
	je DoneChecking ;it is part of the right column, so we should not check its BottomRight corner
CheckBottomRight:
	cmp [byte ptr bx+ROW_AMOUNT+1], BLUE
	jne illegal3
	
DoneChecking:
;if passed all the compares and got here, place is legal (all surrondings are BLUE)
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
;input: active player number
;		offset of the player's board
;		offset of an array keeping lengths of the ships to place
;output: none in the stack
;		 changes the player's board to the given settings
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
	push -1 ;signs we have passed the last part of the ship, ship parts's offset will be pushed after it
	call clear_board
	push [bp+8]
	push bx
	call Present_Board
	push 0
	call explainColors
	
illegal4:
	;informs the player the current ship's length
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
	dec ch ;signs that we have already "placed" a position
	mov [byte ptr di], GREEN ;paints the position for true view for the player
	call clear_board
	push [bp+8]
	push bx
	call Present_Board
	push 0
	call explainColors
	mov [byte ptr di], BLUE ;clears the place to allow correct checking of legal placing
	
	up equ 048h
	left equ 04Bh
	down equ 050h
	right equ 04Dh

	mov ah, 9
	mov dx, offset direction
	int 21h ;asks the player for direction
illegal5:
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
	jmp illegal5
	
place_up:
;checks it is far enough from the border
	mov al, ROW_AMOUNT
	mul ch ;ax stores now how much to reduce from the first position to get the last position
	mov dx, di
	sub dx, ax ;dx stores now where the last placement would be
	cmp dx, bx ;checks if the last poition is on board (and not above it)
	jl too_close_to_border
place_up1:
	sub di, ROW_AMOUNT
	push di
	push bx
	call Check_legal_to_place
	cmp al, 0
	jne remove_written_postitions ;remove the ship and go back to start placing it
up_legal:
	push di ;keep in the stack segment the position future to be painted
	dec ch
	cmp ch, 0
	jne place_up1
	jmp done_writing_positions
	
place_down:
;checks it is far enough from the border
	mov al, ROW_AMOUNT
	mul ch ;ax stores now how much to add to the first position to get the last position
	mov dx, di
	add dx, ax ;dx stores now where the last placement would be
	mov ax, bx
	add ax, AREA-1 ;ax stores the end of the board
	cmp dx, ax ;checks if the last poition is on board (and not bellow it)
	jg too_close_to_border
place_down1:
	add di, ROW_AMOUNT
	push di
	push bx
	call Check_legal_to_place
	cmp al, 0
	jne remove_written_postitions ;remove the ship and go back to start placing it
down_legal:
	push di ;keep in the stack segment the position future to be painted
	dec ch
	cmp ch, 0
	jne place_down1
	jmp done_writing_positions
	
place_left:
;checks it is far enough from the border
	mov ax, di
	sub ax, bx ;ax has now raw value of the position's offset (offset place - offset board)
	mov dl, ROW_AMOUNT
	div dl ;ah stores x axis, al stores y axis
;ah effectivly stores how many tiles are there to the left of the slot
	cmp ah, ch ;checks if we have enough tiles to the left for a ship this long
	jl too_close_to_border
place_left1:
	dec di
	push di
	push bx
	call Check_legal_to_place
	cmp al, 0
	jne remove_written_postitions ;remove the ship and go back to start placing it
left_legal:
	push di ;keep in the stack segment the position future to be painted
	dec ch
	cmp ch, 0
	jne place_left1
	jmp done_writing_positions
	
place_right:
;checks it is far enough from the border
	mov ax, di
	sub ax, bx ;ax has now raw value of the position's offset (offset place - offset board)
	mov dl, ROW_AMOUNT
	div dl ;ah stores x axis, al stores y axis
;ah effectivly stores how many tiles are there to the left
	mov al, ROW_AMOUNT
	sub al, [si] ;al stores now how many tiles to the left is maximun to allow for a ship this long to be
	cmp ah, al ;checks if we have too many tiles to the left for a ship this long
	jg too_close_to_border
place_right1:
	inc di
	push di
	push bx
	call Check_legal_to_place
	cmp al, 0
	jne remove_written_postitions ;remove the ship and go back to start placing it
right_legal:
	push di ;keep in the stack segment the position future to be painted
	dec ch
	cmp ch, 0
	jne place_right1
	jmp done_writing_positions
	
too_close_to_border:
	add sp, 2 ;removes the first position from the stack
	inc ch ;signing we actually did not place a ship part
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
	push -1 ;again, signs we have passed the last part of the ship, ship parts's offset will be pushed after it
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
	push bp ;we have to place the ship without taking the values out of the stack, because we might want to delete the ship, what requires us to remeber where have we written
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
	pop bp ;goes back to its original value
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
	jmp delete_positions ;deletes the positions from the stack and from the board
	
	
	
paint_ship_white:
	pop di
	cmp di, -1
	je done_placing_a_ship
	mov [di], cl
	jmp paint_ship_white ;paints the currently green positions, white
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
;input: offset of the computer's board
;		offset of an array keeping lengths of the ships to place
;output: none in the stack
;		 changes the computer's board to a randomly generated board
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
	push -1 ;signs we have passed the last part of the ship, ship parts's offset will be pushed after it
illegal4_:
	mov ch, [si] ;ch represents the left slots to place
	push cx
	mov ah, 2Ch
	int 21h ;random place
	pop cx
	mov al, dl ;al has a number betwin 0 and 99
	mov ah, AREA
	mul ah ;ax has a number betwin 0 and 100*AREA -1
	mov dl, 100
	div dl ;al has a random numeber betwin 0 and AREA-1
	xor ah, ah
	mov di, ax
	add di, bx ;di has now the position randomly generated
	
	push di ;where the ship starts
	push bx
	call Check_legal_to_place
	cmp al, 0
	jne illegal4_
	push di ;keep in the stack segment the position future to be painted
	dec ch ;signs that one position has already been chosen

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
	mul ch ;ax stores now how much to reduce from the first position to get the last position
	mov dx, di
	sub dx, ax ;dx stores now where the last placement would be
	cmp dx, bx ;checks if the last poition is on board (and not above it)
	jl too_close_to_border_
place_up1_:
	sub di, ROW_AMOUNT
	push di
	push bx
	call Check_legal_to_place
	cmp al, 0
	jne remove_written_postitions_ ;remove the ship and go back to start placing it
up_legal_:
	push di ;keep in the stack segment the position future to be painted
	dec ch
	cmp ch, 0
	jne place_up1_
	jmp done_writing_positions_
	
place_down_:
;checks it is far enough from the border
	mov al, ROW_AMOUNT
	mul ch ;ax stores now how much to add to the first position to get the last position
	mov dx, di
	add dx, ax ;dx stores now where the last placement would be
	mov ax, bx
	add ax, AREA-1 ;ax stores the end of the board
	cmp dx, ax ;checks if the last poition is on board (and not bellow it)
	jg too_close_to_border_
place_down1_:
	add di, ROW_AMOUNT
	push di
	push bx
	call Check_legal_to_place
	cmp al, 0
	jne remove_written_postitions_ ;remove the ship and go back to start placing it
down_legal_:
	push di ;keep in the stack segment the position future to be painted
	dec ch
	cmp ch, 0
	jne place_down1_
	jmp done_writing_positions_
	
place_left_:
;checks it is far enough from the border
	mov ax, di
	sub ax, bx ;ax has now raw value of the position's offset (offset place - offset board)
	mov dl, ROW_AMOUNT
	div dl ;ah stores x axis, al stores y axis
;ah effectivly stores how many tiles are there to the left of the slot
	cmp ah, ch ;checks if we have enough tiles to the left for a ship this long
	jl too_close_to_border_
place_left1_:
	dec di
	push di
	push bx
	call Check_legal_to_place
	cmp al, 0
	jne remove_written_postitions_ ;remove the ship and go back to start placing it
left_legal_:
	push di ;keep in the stack segment the position future to be painted
	dec ch
	cmp ch, 0
	jne place_left1_
	jmp done_writing_positions_
	
place_right_:
;checks it is far enough from the border
	mov ax, di
	sub ax, bx ;ax has now raw value of the position's offset (offset place - offset board)
	mov dl, ROW_AMOUNT
	div dl ;ah stores x axis, al stores y axis
;ah effectivly stores how many tiles are there to the left
	mov al, ROW_AMOUNT
	sub al, [si] ;al stores now how many tiles to the left is maximun to allow for a ship this long to be
	cmp ah, al ;checks if we have too many tiles to the left for a ship this long
	jg too_close_to_border_
place_right1_:
	inc di
	push di
	push bx
	call Check_legal_to_place
	cmp al, 0
	jne remove_written_postitions_ ;remove the ship and go back to start placing it
right_legal_:
	push di ;keep in the stack segment the position future to be painted
	dec ch
	cmp ch, 0
	jne place_right1_
	jmp done_writing_positions_
	
too_close_to_border_:
	add sp, 2 ;removes the first position from the stack
	jmp illegal4_
;removes the saved positions from the stack until hits the -1 signing to stop
;this allows to start again placing a ship
remove_written_postitions_:
	pop ax
	cmp ax, -1
	jne remove_written_postitions_
	push -1 ;signs we have passed the last part of the ship, ship parts's offset will be pushed after it
	jmp illegal4_
	
done_writing_positions_:
	pop di
	cmp di, -1
	je done_placing_a_ship_
	mov [di], cl ;paints white the chosen positions
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

;this procedure moves to text mode effectivly clearing the screen from all text
;input: none
;output: none
proc clear_board
	push ax
	mov ax, 3
	int 10h
	pop ax
	ret
endp clear_board

;this procedure prints to the screen a chosen board
;input: active player number (-1 if computer)
;		the board to print's offset
;output: none in the stack
;		 the board presented to the screen
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
	int 21h ;'Player'
	
	cmp [word ptr bp+6], -1
	jne Player
	mov dx, offset active_computer_string
	int 21h ;'Compter'
	jmp continue1
	
Player:
	mov dx, [bp+6]
	mov ah, 2
	int 21h
	
continue1:
	mov ah, 2
	mov dl, 0ah
	int 21h ;down a row
	
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
	loop printTopPart ;prints the letters in the top part of the screen
	
	mov ch, 0 ;counts the lines
	mov bx, [bp+4]
anotherLine:
	mov cl, 0 ;counts the columns
	mov dl, 0ah
	mov ah, 2
	int 21h
	;down a row
	mov dl, ch
	add dl, '0'
	mov ah, 2
	int 21h
	;the row's number
anotherColumn:
	push bx
	push cx
	mov dl, [bx] ;dl stores the value in the currently scanned position
	
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
	int 10h ;changes the color
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
	int 10h ;changes the color to black
	mov ah, 2
	mov dl, 219
	int 21h ;prints a black blank to prevent the cursor showing
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
;input: 0 for placing stage, or 1 for shooting stage
;output: none in the stack
;		 the needed information presented to the screen
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


;this procedure runs a single player turn, asking the player for a place to shoot and managing that shot
;input: active player number
;		enemy's board offset
;		active player's guessing board offset
;		enemy's array of left ship offset
;output: none in the stack
;		 al = 1 if won or al = 0 to continue
;		 the guessing board is changed according to the shot
;		 the enemy's left ship array changes according to the shot
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
;				we need the offset this way so we can add it to both the guessing board and the enemy board
	
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
	add si, ax ;si has now the place in the left ship array of the ship that was just shot
	dec [byte ptr si] ;signs a ship part was hit
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
;if all ships have no left parts, player won
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

;this procedure detectes the placements of a ship and marks yellow around it so the player would know it is down
;input: guessing board offset
;		a number to add to the board to get one of the ship's places (offset place - offset board)
;output: none in the stack
;		 the guessing board is changed according to the wanted changes (surronding the fallen ship)
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
	je check_left ;if part of top row should not check if continuing up
	cmp [byte ptr si - ROW_AMOUNT], RED ;checks above
	je continue_up
	
check_left:
	cmp ah, 0
	je check_down ;if part of left column should not check if continueing left
	cmp [byte ptr si - 1], RED ;checks to the left
	je continue_left
	
check_down:
	cmp al, ROW_AMOUNT-1
	je mark_right ;we know it is not going up, not left and it can't go down (because it is in the bottom row), so it is left edge of the ship, continuing right
	cmp [byte ptr si + ROW_AMOUNT], RED ;checks bellow
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
	je continue_up ;continues going up until it is the last slot
	jmp mark_down
	
continue_left:
	dec si
	dec ah
	;checks the slot to the left
	cmp ah, 0
	je mark_right
	cmp [byte ptr si - 1], RED
	je continue_left ;continues going left until it is the last slot
	jmp mark_right

;this part moves down or right and marks it (depending on ship's direction)
mark_down:
	cmp al, 0
	je down_mark_loop
;this part marks the three slots above the top edge of the ship
;if the top edge is part of the top row, this part would be skipped to down_mark_loop
	cmp ah, 0
	je after_left_marked ;do not mark to the left if is part of the left column
	mov [byte ptr si-ROW_AMOUNT-1], YELLOW
after_left_marked:
	mov [byte ptr si-ROW_AMOUNT], YELLOW
	cmp ah, ROW_AMOUNT-1
	je down_mark_loop ;do not mark to the right if it is part of the right column
	mov [byte ptr si-ROW_AMOUNT+1], YELLOW
	
;this part marks besides the ship and goes down until it gets to the bottom edge of the ship
down_mark_loop:
	cmp ah, 0
	je mark_right_slot ;do not mark to the left if is part of the left column
	mov [byte ptr si-1], YELLOW
mark_right_slot:
	cmp ah, ROW_AMOUNT-1
	je check_bottom_edge ;do not mark to the right if it is part of the right column
	mov [byte ptr si+1], YELLOW
check_bottom_edge:
	cmp al, ROW_AMOUNT-1
	je done_marking ;we are done marking if the current place is in the bottom line of the board
	cmp [byte ptr si+ROW_AMOUNT], RED
	jne mark_bottom_part ;mark the three bottom slots if ship is over
	add si, ROW_AMOUNT ;update paramenters to the next slot
	inc al ;y axis
	jmp down_mark_loop

;this part marks the three slots bellow the ship
mark_bottom_part:	
	cmp ah, 0
	je mark_bottom_middle ;do not mark to the left if is part of the left column
	mov [byte ptr si+ROW_AMOUNT-1], YELLOW
mark_bottom_middle:
	mov [byte ptr si+ROW_AMOUNT], YELLOW
	cmp ah, ROW_AMOUNT-1
	je done_marking ;do not mark to the right if it is part of the right column
	mov [byte ptr si+ROW_AMOUNT+1], YELLOW
	jmp done_marking
	
	
	
mark_right:
	cmp ah, 0
	je right_mark_loop
;this part marks the three slots left to the ship's edge
;if the left edge is part of the left row, this part would be skipped to right_mark_loop
	cmp al, 0
	je after_top_marked ;do not mark the top if part of the top row
	mov [byte ptr si-ROW_AMOUNT-1], YELLOW
after_top_marked:
	mov [byte ptr si-1], YELLOW
	cmp al, ROW_AMOUNT-1
	je right_mark_loop ;do not mark the bottom if part of bottom row
	mov [byte ptr si+ROW_AMOUNT-1], YELLOW
	
;this part marks besides the ship and goes right until it gets to the right edge of the ship
right_mark_loop:
	cmp al, 0
	je mark_bottom_slot ;do not mark the top if part of the top row
	mov [byte ptr si-ROW_AMOUNT], YELLOW
mark_bottom_slot:
	cmp al, ROW_AMOUNT-1
	je check_right_edge ;do not mark the bottom if part of bottom row
	mov [byte ptr si+ROW_AMOUNT], YELLOW
check_right_edge:
	cmp ah, ROW_AMOUNT-1
	je done_marking ;we are done marking if the current place is in the most right column of the board
	cmp [byte ptr si+1], RED
	jne mark_right_part ;mark the three bottom slots if ship is over
	inc si ;update paramenters to the next slot
	inc ah ;x axis
	jmp right_mark_loop

;this part marks the three slots right to the ship's edge
mark_right_part:	
	cmp al, 0
	je mark_right_middle ;do not mark the top if part of the top row
	mov [byte ptr si-ROW_AMOUNT+1], YELLOW
mark_right_middle:
	mov [byte ptr si+1], YELLOW
	cmp al, ROW_AMOUNT-1
	je done_marking ;do not mark the bottom if part of bottom row
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

;This procedure waits for a key press
;used to allow the players to see the board before the game continues
;input: none
;output: none
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
;input: first player's: board
;						guessing board
;						left ship array
;		second player's: board
;						 guessing board
;						 left ship array
;output: none in the stack
;		 changes all given paramenters according to the game's actions
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
	xor bx, 11b ;changes '1' to '2' and '2' to '1'
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
	int 16h ;waits for a key press during the win message
	
	pop dx
	pop bx
	pop ax
	pop bp
	ret 12
endp two_player_match

;this procedure resets all variables needed to run a match to thier starting values
;input: first player's: board
;						guessing board
;						left ship array
;		second player's: board
;						 guessing board
;						 left ship array
;output: none in the stack
;		 the given variables reset (boards to all BLUE and left ships arrays to the Starting_LeftShip array, used only by this procedure remembering the ships lengths)
proc reset_variables
	push bp
	mov bp, sp
	push ax
	push bx
	push si
	push di

	mov si, AREA-1
reset_boards:
	mov bx, [bp+14] ;Player1Board
	mov [byte ptr bx+si], BLUE
	mov bx, [bp+12] ;Player1Guessing
	mov [byte ptr bx+si], BLUE
	mov bx, [bp+8] ;Player2Board
	mov [byte ptr bx+si], BLUE
	mov bx, [bp+6] ;Player2Guessing
	mov [byte ptr bx+si], BLUE
	cmp si, 0
	je done_boards
	dec si
	jmp reset_boards
	
done_boards:
	mov bx, offset Starting_LeftShip
	mov si, [bp+10] ;Player1LeftShip
	mov di, [bp+4] ;Player2LeftShip
reset_left_ship:
	mov al, [bx] ;moves the needed value to al
	mov [si], al ;moves the needed value to Player1's LeftShip
	mov [di], al ;moves the needed value to Player2's LeftShip
	cmp [byte ptr bx], '$' ;'$' signs the end of the array, stop copying when '$' is found
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
;input: player's board offset
;		computer's guessing board
;		player's left ships array
;		last_hit_part offset
;		known_direction offset
;output: none in the stack
;		 al = 1 if won and al = 0 to continue
;		 the guessing board is changed according to the shot
;		 the player's left ship array changes according to the shot
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
	je randomPlace ;if there is no known place already, shoot a random place
	
	mov bx, [bp+4]
	cmp [byte ptr bx], -1
	jne shoot_direction ;if there is a known direction, shoot the known direction from the knwon place
	
;here if there is a known place but the direction is still unknown
;so generate a direction
randomDirection:
	mov ah, 2Ch
	int 21h
	mov al, dl
	xor ah, ah
	mov dl, 25
	div dl ;al=0 would mean up, al=1 down, al=2 left, al=3 right
	mov bx, [bp+6]
	mov bx, [bx] ;bx has the offset of the last part hit, which is the value of the variable Last_Hit_Part
;				  we use the Last_Hit_Part in all 4 following branches so we get it here already
	cmp al, 0
	je up1
	cmp al, 1
	je down1
	
	;the processes of shooting left or right need the x axis, so if those directions are chosen, we should calculate it
	push ax
	mov ax, bx
	mov dl, ROW_AMOUNT
	div dl ;ah has x axis, al has y axis
	mov dx, ax ;dh has x axis, dl has y axis
	pop ax
	cmp al, 2
	je left1
	jmp right1
up1:
	cmp bx, ROW_AMOUNT
	jb randomDirection ;if the last part hit is part of the top row, we cannot shoot above it and should generate a new direction
	sub bx, ROW_AMOUNT
	cmp [byte ptr di+bx], BLUE
	jne randomDirection ;if the slot above the last part hit was already uncovered, we cannot shoot it and should generate a new direction
	jmp shoot1
down1:
	add bx, ROW_AMOUNT
	cmp bx, AREA
	jae randomDirection ;if the position bellow the last part hit is not on the board (which means the last part hit is in the bottom row), we cannot shoot it and should generate a new direction
	cmp [byte ptr di+bx], BLUE
	jne randomDirection ;if the slot bellow the last part hit was already uncovered, we cannot shoot it and should generate a new direction
	jmp shoot1
left1:
	cmp dh, 0
	je randomDirection ;if the last part hit is part of the left column, we cannot shoot left to it and should generate a new direction
	dec bx
	cmp [byte ptr di+bx], BLUE
	jne randomDirection ;if the slot left to the last part hit was already uncovered, we cannot shoot it and should generate a new direction
	jmp shoot1
right1:
	cmp dh, ROW_AMOUNT-1
	je randomDirection ;if the last part hit is part of the right column, we cannot shoot right to it and should generate a new direction
	inc bx
	cmp [byte ptr di+bx], BLUE
	jne randomDirection ;if the slot right to the last part hit was already uncovered, we cannot shoot it and should generate a new direction
	jmp shoot1
	
switchDirection:
	mov bx, [bp+4] ;known_direction
	xor [byte ptr bx], 1 ;switches 0 to 1, and 2 to 3 and backwards (effectivly up to down and left to right and backwards)
shoot_direction:
	mov bx, [bp+4] ;known_direction
	mov al, [bx] ;the value of the known_direction, 0 means up, 1 means down, 2 means left and 3 means right
	mov bx, [bp+6] ;Last_Hit_Part
	mov bx, [bx]
	cmp al, 0
	je up2
	cmp al, 1
	je down2

	;the processes of shooting left or right need the x axis, so we should calculate it
	push ax
	mov ax, bx
	mov dl, ROW_AMOUNT
	div dl ;ah has x axis, al has y axis
	mov dx, ax ;dh has x axis, dl has y axis
	pop ax
	cmp al, 2
	je left2
	jmp right2
up2:
	cmp bx, ROW_AMOUNT
	jb switchDirection ;if the last part hit was part of the top row and the known direction is up, we should switch direction to shoot down until the ship is down
	sub bx, ROW_AMOUNT
	cmp [byte ptr di+bx], YELLOW
	je switchDirection ;when encounter a yellow slot in the known direction, switch direction
	cmp [byte ptr di+bx], RED
	je up2 ;if the slot to the known direction is RED (which means hit), too, continue moving this direction
	jmp shoot1 ;when found a position in the direction that is empty, shoot it
down2:
	add bx, ROW_AMOUNT
	cmp bx, AREA
	jae switchDirection ;if the last part hit was part of the bottom row and the known direction is down, we should switch direction to shoot up until the ship is down
	cmp [byte ptr di+bx], YELLOW
	je switchDirection ;when encounter a yellow slot in the known direction, switch direction
	cmp [byte ptr di+bx], RED
	je down2 ;if the slot to the known direction is RED (which means hit), too, continue moving this direction
	jmp shoot1 ;when found a position in the direction that is empty, shoot it
left2:
	cmp dh, 0
	je switchDirection ;if the last part hit was part of the left column and the known direction is left, we should switch direction to shoot right until the ship is down
	dec bx
	cmp [byte ptr di+bx], YELLOW
	je switchDirection ;when encounter a yellow slot in the known direction, switch direction
	cmp [byte ptr di+bx], RED
	je left2 ;if the slot to the known direction is RED (which means hit), too, continue moving this direction
	jmp shoot1 ;when found a position in the direction that is empty, shoot it
right2:
	cmp dh, ROW_AMOUNT-1
	je switchDirection ;if the last part hit was part of the right column and the known direction is right, we should switch direction to shoot left until the ship is down
	inc bx
	cmp [byte ptr di+bx], YELLOW
	je switchDirection ;when encounter a yellow slot in the known direction, switch direction
	cmp [byte ptr di+bx], RED
	je right2 ;if the slot to the known direction is RED (which means hit), too, continue moving this direction
	jmp shoot1 ;when found a position in the direction that is empty, shoot it
	
	
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
	jne randomPlace ;if randomized place was shot already, randomize another place
	mov al, -1 ;signs that the direction is unknown and that we are shooting randomly
shoot1: ;runs the process of shooting the position in bx (si should be the player's board, di should be the computer's guessing board, and al should be the current direction shooting, -1 if randomly)
	cmp [byte ptr si + bx], BLUE ;checks the value in the actual board
	je miss2

	mov [byte ptr di + bx], RED ;hit sign
	;when hit
	mov cx, bx
	mov bx, [bp+6]
	mov [bx], cx ;sign in the Last_Hit_Part the part hit now
	mov bx, [bp+4]
	mov [bx], al ;sign in the known_direction the direction currently shot, -1 if unknown
	mov bx, cx ;bx gets back his value
	call clear_board
	push -1
	push di
	call Present_Board
	push 1
	call explainColors
	mov dx, offset hit
	mov ah, 9
	int 21h

	mov al, [si + bx] ;checks the value of the ship
	sub al, '0' ;its place in the left ship array
	xor ah, ah
	mov si, [bp+8] ;left ship array
	add si, ax ;points now at the place of the ship just shot
	dec [byte ptr si] ;signs one part of the ship was shot
	cmp [byte ptr si], 0
	jne continue_playing1
;ship is down
	;resets the known direction and last part hit to unknown, so the computer would shoot randomly again
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
	jmp check_loop1 ;checks if the computer won
won1:
;if went through the whole array and no ship has any parts of it left, computer won
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
	
;this procedure runs a single player vs computer match, from creating the player's board and computer's turn to shooting to ending the game with a fitting message
;input: first player's: board
;						guessing board
;						left ship array
;		second player's: board
;						 guessing board
;						 left ship array
;output: none in the stack
;		 changes all given paramenters according to the game's actions
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
	int 16h ;waits for a key press during the win/loss message
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
;input: file handle
;		offset to put header
;		offset to put Palette
;output: none in the stack
;		 changes the given places the the header and palette
;		 moves the reading pointer in the file to the start of the actual image
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

;chnanges the colors from BGR (assemblu color format) to RGB (NMP file color format)
;input: offset to read Palette from
;output: none in the stack
;		 the colors in the ports are changed
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
	ret 2
endp CopyPal

;prints to the graphic screen the BMP file (after opening file, reading palette and copying it)
;input: file handle
;output: none in the stack
;		 copying the BMP file from the file to the data segment to the A000 segment, the graphics screen
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
;output: none
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

;this procedure prints to the screen a BMP file, doing all the things needed
;opening the file, reading header, reading palette, copying the palette, copying the BMP, and closing the file
;input: offset of file's name
;output: none in the stack
;		 moving to graphics mode and chaning the screen to the given BMP file
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

;this procedure runs the main menu, continuing from there to other menues and the game itself, or exiting using the exit button
;input: none
;output: none
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
	and bx, 1 ;nullifies the register except for the bit signing left click
	cmp bx, 1 ;checks for a left click
	jne MainMenuDataWait
	
MainMenuReleaseWait:
	mov ax, 3
	int 33h
	and bx,1 ;nullifies the register except for the bit signing left click
	cmp bx, 1 ;checks for a left click
	je MainMenuReleaseWait ;waits until the left click stops (key is released)
	
	cmp cx, 0088h
	jb MainMenuDataWait ;if click is left to the buttons wait for data
	cmp cx, 01CAh
	ja MainMenuDataWait ;if click is right to the buttons wait for data
	cmp dx, 002Dh
	jb MainMenuDataWait ;if click above the buttons wait for data
	cmp dx, 0040h
	jb Play ;if click above the Top button's bottom do its thing
	cmp dx, 004Fh
	jb MainMenuDataWait ;if click above second button's top wait for data
	cmp dx, 0062h
	jb Rules ;if click above the second button's bottom do its thing
	cmp dx, 0072h
	jb MainMenuDataWait ;if click above third button's top wait for data
	cmp dx, 0082h
	jb ExitButton ;if click above third button's bottom do its thing
	jmp MainMenuDataWait ;if click does is not in any above categories wait for data
	
	
	
play:
	call PlayMenu
	jmp PresentMain
Rules:
	call RulesMenu
	jmp PresentMain
	
ExitButton:
	call clear_board
	pop dx
	pop cx
	pop bx
	pop ax
	ret
endp MainMenu

;this procedure runs the play menu, continuing from there to games, or goinh back to the main menu
;input: none
;output: none
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
	
;buttons here work just like the buttons in the Main Menu
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

;this procedure runs the rules interface
;input: none
;output: none
proc RulesMenu
	push ax
	push bx
	push cx
	push dx
	push si
	
	mov si, 1 ;keeps the current page
	
Page1:
	push offset rules1
	call PrintBMP
	jmp RulesWaitForData
Page2:
	push offset rules2
	call PrintBMP
	jmp RulesWaitForData
Page3:
	push offset rules3
	call PrintBMP
	jmp RulesWaitForData
Page4:
	push offset rules4
	call PrintBMP
	
RulesWaitForData:

	mov ah, 1
	int 16h
	jnz KeyPress ;check if keyboard pressed

	mov ax, 1
	int 33h
	mov ax, 3
	int 33h
	and bx, 1
	cmp bx, 1 ;checks if left click pressed
	jne RulesWaitForData
	
RulesMenuReleaseWait:
	mov ax, 3
	int 33h
	and bx,1
	cmp bx, 1 ;waits for left click to release
	je RulesMenuReleaseWait
	
;buttons checks work very similar to other MainMenu's way
	cmp dx, 003Eh
	jb RulesWaitForData
	cmp dx, 005Fh
	ja RulesWaitForData
	cmp cx, 000Ch
	jb RulesWaitForData
	cmp cx, 0036h
	jb GoBack
	cmp cx, 0248h
	jb RulesWaitForData
	cmp cx, 0272h
	jb GoOn
	jmp RulesWaitForData
	
GoBack:
	cmp si, 1
	je RulesWaitForData ;if page 1 cannot go back
	dec si
	jmp GoToPage
GoOn:
	cmp si, 4
	je RulesWaitForData ;if last page cannot go forward
	inc si
GoToPage:
;checks what page is it and prints it
	cmp si, 1
	je Page1
	cmp si, 2
	je Page2
	cmp si, 3
	je Page3
	cmp si, 4
	je Page4
	
KeyPress:
	escKey equ 011Bh
	mov ah, 0
	int 16h ;checks if the key press was esc, if it was, end the procedure, if wasnt keep waiting for data
	cmp ax, escKey
	jne RulesWaitForData
	
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret
endp RulesMenu

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