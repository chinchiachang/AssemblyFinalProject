TITLE Snake.asm

; A snake game written in assembly using Kip Irvnine's Irvine32 assembly
; library.

INCLUDE Irvine32.inc

main  EQU start@0

.DATA

a WORD 720 DUP(0)  ; Framebuffer ( 24*30)
         ;12445678901244567890124456789012445678901244567890124456789012445678901244567890 
map BYTE "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW"
    BYTE "W                                                   W"
    BYTE "W   WWWWWWWW   WWWWWWWW   W   WWWWWWWW   WWWWWWWW   W"
    BYTE "W   W      W   W      W   W   W      W   W      W   W"
    BYTE "W   WWWWWWWW   WWWWWWWW   W   WWWWWWWW   WWWWWWWW   W"
    BYTE "W                                                   W"
    BYTE "W   WWWWWWWW   W   WWWWWWWWWWWWWWW   W   WWWWWWWW   W"
    BYTE "W                         W                         W"
    BYTE "WWWWWWWWWWWW   WWWWWWWW   W   WWWWWWWW   WWWWWWWWWWWW"
    BYTE "           W   W                     W   W           "
    BYTE "WWWWWWWWWWWW   W   WWWWWWWWWWWWWWW   W   WWWWWWWWWWWW"
    BYTE "                   W             W                   "
    BYTE "WWWWWWWWWWWW   W   WWWWWWWWWWWWWWW   W   WWWWWWWWWWWW"
    BYTE "           W   W                     W   W           "
    BYTE "WWWWWWWWWWWW   W   WWWWWWWWWWWWWWW   W   WWWWWWWWWWWW"
    BYTE "W                         W                         W"
    BYTE "W   WWWWWWWW   WWWWWWWW   W   WWWWWWW    WWWWWWWW   W"
    BYTE "W          W                         W              W"
    BYTE "WWWWWWWW   W   W   WWWWWWWWWWWWWWW   W   W   WWWWWWWW"
    BYTE "W              W                     W              W"
    BYTE "W   WWWWWWWWWWWWWWWWWWW   W   WWWWWWWWWWWWWWWWWWW   W"
    BYTE "W                         W                         W"
    BYTE "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW", 0 
  
; tR BYTE 14d         ; Snake tail row number
; tC BYTE 47d         ; Snake tail column number
hR BYTE 13d         ; Snake head row number
hC BYTE 20d         ; Snake head column number
fR BYTE 0           ; Food row
fC BYTE 0           ; Food column

tmpR BYTE 0         ; Temporary variable for storing row indexes
tmpC BYTE 0         ; Temporary variable for storing column indexes

rM BYTE 0d          ; Index of row above current row (row minus)
cM BYTE 0d          ; Index of column left of current column (column minus)
rP BYTE 0d          ; Index of row below current row (row plus)
cP BYTE 0d          ; Index of column right of current column (column plus)
tempr BYTE 0d
tempc BYTE 0d

eTail   BYTE    1d  ; Flag for indicating if tail should be deleted or not
search  WORD    0d  ; Variable for storing value of next snake segment
eGame   BYTE    0d  ; Flag for indicating that game should be ended (collision)
cScore  DWORD   0d  ; Total score

d       BYTE    'w' ; Variable for holding the current direction of the snake
wall    BYTE    'n' ;where is the wall
newD    BYTE    'w' ; Variable for holding the new direction specified by input
delTime DWORD   150 ; Delay time between frames (game speed)

; Strings for menu display
menuS   BYTE "1. Start Game", 0Dh, 0Ah, 0
levelS  BYTE "1. None", 0Dh, 0Ah, "2. Box", 0Dh, 0Ah, "3. Rooms", 0Dh, 0Ah, 0
speedS  BYTE "1. Earthworm", 0Dh, 0Ah, "2. Centipede", 0Dh, 0Ah, "3. Cobra",
             0Dh, 0Ah, "4. Black Mamba", 0Dh, 0Ah, 0
hitS    BYTE "Game Over!", 0
scoreS  BYTE "Score: 0", 0

myHandle DWORD ?    ; Variable for holding the terminal input handle
numInp   DWORD ?    ; Variable for holding number of bytes in input buffer
temp BYTE 16 DUP(?) ; Variable for holding data of type INPUT_RECORD
bRead    DWORD ?    ; Variable for holding number of read input bytes

.CODE

main PROC

; The main procedure handles printing menus to the user, configuring the game
; and then starting the game.

    menu:
    CALL Randomize              ; Set seed for food generation �i�Hcall �H���禡
    CALL Clrscr                 ; Clear terminal screen
    MOV EDX, OFFSET menuS       ; Copy pointer to menu string into EDX
    CALL WriteString            ; Write menu string to terminal

    wait1:                      ; Loop for reading menu choices
    CALL ReadChar

    CMP AL, '1'                 ; Check if start game was selected
    JE startG

    ; CMP AL, '2'                 ; Check if speed settig was selected
    ; JE speed

    ; CMP AL, '3'                 ; Check if level choice was selected
    ; JE level

    ; CMP AL, '4'                 ; If any other character was read,
    ; JNE wait1                   ; continue loop until a valid character
                                ; has been given, else exit program
    EXIT

    ; level:                      ; Level chooser section
    ; CALL Clrscr                 ; Clear terminal screen
    ; MOV EDX, OFFSET levelS      ; Copy pointer to level menu string into EDX
    ; CALL WriteString            ; Write level menu string to screen

    ; wait2:                      ; Wait for valid input for level choice
    ; CALL ReadChar

    ; CMP AL, '1'                 ; No obsacles level
    ; JE level1

    ; CMP AL, '2'                 ; Box level
    ; JE level2

    ; CMP AL, '3'                 ; Rooms level
    ; JE level3

    ; JMP wait2                   ; Invalid choice, continue loop

    ; level1:                     ; No obstacles level
    ; CALL clearMem               ; Clear framebuffer and reset all game flags
    ; MOV AL, 1                   ; Set flag for level generation in AL and jump
    ; CALL GenLevel               ; to level generation section of program
    ; JMP menu

    ; level2:                     ; Box obstacle level
    ; CALL clearMem               ; Clear framebuffer and reset all game flags
    ; MOV AL, 2                   ; Set flag for level generation in AL and jump
    ; CALL GenLevel               ; to level generation section of program
    ; JMP menu

    ; level3:                     ; Rooms obstacle level
    ; CALL clearMem               ; Clear framebuffer and reset all game flags
    ; MOV AL, 3                   ; Set flag for level generation in AL and jump
    ; CALL GenLevel               ; to level generation section of program
    ; JMP menu

    ; speed:                      ; This section of code selects the game speed
    ; CALL Clrscr                 ; Clear terminal screen
    ; MOV EDX, OFFSET speedS      ; Copy pointer to speed menu into EDX
    ; CALL WriteString            ; Write speed menu string to screen

    ; wait3:                      ; Wait for valid input for speed choice
    ; CALL ReadChar

    ; CMP AL, '1'                 ; Slow speed
    ; JE speed1

    ; CMP AL, '2'                 ; Normal speed
    ; JE speed2

    ; CMP AL, '3'                 ; Fast speed
    ; JE speed3

    ; CMP AL, '4'                 ; Invalid choice, continue loop
    ; JE speed4
    ; JMP wait3

    ; speed1:                     ; Set refresh rate of game to 150ms
    ; MOV delTime, 150
    ; JMP menu

    ; speed2:                     ; Set refresh rate of game to 100ms
    ; MOV delTime, 100
    ; JMP menu

    ; speed3:
    ; MOV delTime, 50             ; Set refresh rate of game to 50ms
    ; JMP menu

    ; speed4:
    ; MOV delTime, 35             ; Set refresh rate of game to 35ms
    ; JMP menu                    ; Go back to main menu

    startG:                     ; This section sets  the necessary flags
    CALL GenLevel               ; and calls the main infinite loop
    MOV EAX, 0                  ; Clear registers
    MOV EDX, 0
    CALL Clrscr                 ; Clear terminal screen
    CALL initSnake              ; Initialize snake position
    CALL Paint                  ; Paint level to terminal screen
    CALL createFood             ; Create snake food location, print to screen
    CALL startGame              ; Call main infinite loop
    MOV EAX, white + (black * 16)
    CALL SetTextColor           ; Gave was exited, reset screen color
    JMP menu                    ; and jump back to main menu

main ENDP

initSnake PROC USES EBX EDX

; This procedure initializes the snake to the default position
; in the center of the screen

    MOV DH, 13      ; Set row number to 13
    MOV DL, 20      ; Set column number to 47
    MOV BX, 1       ; First segment of snake
    CALL saveIndex  ; Write to framebuffer

    ; MOV DH, 14      ; Set row number to 14
    ; MOV DL, 47      ; Set column number to 47
    ; MOV BX, 2       ; Second segment of snake
    ; CALL saveIndex  ; Write to framebuffer

    ; MOV DH, 15      ; Set row number to 15
    ; MOV DL, 47      ; Set column number to 47
    ; MOV BX, 3       ; Third segment of snake
    ; CALL saveIndex  ; Write to framebuffer

    ; MOV DH, 16      ; Set row number to 16
    ; MOV DL, 47      ; Set column number to 47
    ; MOV BX, 4       ; Fourth segment of snake
    ; CALL saveIndex  ; Write to framebuffer

    RET

initSnake ENDP

; clearMem PROC

; ; This procedure clears the framebuffer, resets the snake position and length,
; ; and sets all the game related flags back to their default value.

;     MOV DH, 0               ; Set the row register to zero
;     MOV BX, 0               ; Set the data register to zero

;     oLoop:                  ; Outer loop for matrix indexing (for rows)
;         CMP DH,  24          ; Count for  24 rows and break if row number is  24
;                             ; (since indexing starts form 0)
;         JE endOLoop

;         MOV DL, 0           ; Set the column number to zero

;         iLoop:              ; Inner loop for matrix indexing (for columns)
;             CMP DL, 30      ; Count for 30 columns and
;             JE endILoop     ; break if column number is 30

;             CALL saveIndex  ; Call procedure for writing to the framebuffer
;                             ; based on the DH and DL registers
;             INC DL          ; Increment column number
;             JMP iLoop       ; Continue inner loop

;     endILoop:               ; End of innter loop
;         INC DH              ; Increment row number
;         JMP oLoop           ; Continue outer loop

; endOLoop:                   ; End of outer loop
;     MOV tR, 16              ; Reset coordinates of
;     MOV tC, 47              ; snake tail (row and column)
;     MOV hR, 13              ; Reset coordinates of
;     MOV hC, 47              ; snake head (row and column)

;     MOV eGame, 0            ; Clear the end game flag
;     MOV eTail, 1            ; Set the erase tail flag (no food eaten)
;     MOV d, 'w'              ; Set current direction to up
;     MOV newD, 'w'           ; Set new direction to up
;     MOV cScore, 0           ; Reset total score

;     RET
; clearMem ENDP

startGame PROC USES EAX EBX ECX EDX

; This procedure is the main process, and has an infinite loop which exits
; when the user presses ESC or when it comes to a collision with a wall or the
; snake itself. Upon exit, the procedure resets the game flags to default and
; clears the framebuffer.
; The procedure decides which direction change has to be made, depending on the
; current direction of the snake and the user input from the terminal. The
; procedure also delays the game between frames, which controls the gamespeed.
;
; Notes about console interaction:
; The ReadConsoleInput procedure reads data structures called INPUT_RECORD from
; the termninal input program memory. The procedure takes as input the console
; input handle, a pointer to the buffer for holding INPUT_RECORD messages,
; number of INPUT_RECORD messages to be read, and a pointer to where to store
; the number of INPUT_RECORD messages read in the procedure call.
;
; The INPUT_RECORD is a structure that has an EventType (WORD) and an Event
; which can be an event from a keyboard, a mouse, menu event, focus event, etc.
; The KEY_EVENT_RECORD has bKeyDown (BOOL), wRepeatCount (WORD),
; wVirtualKeyCode (WORD), wVirtualScanCode (WORD) and so on...

        ;CALL GenLevel
        MOV EAX, white + (black * 16)       ; Set text color to white on black
        CALL SetTextColor
        MOV DH,  24                          ; Move cursor to bottom lef side
        MOV DL, 0                           ; of screen, to write the score
        CALL GotoXY                         ; string
        MOV EDX, OFFSET scoreS
        CALL WriteString

        ; Get console input handle and store it in memory
        INVOKE getStdHandle, STD_INPUT_HANDLE
        MOV myHandle, EAX
        MOV ECX, 10

        ; Read two events from buffer
        INVOKE ReadConsoleInput, myHandle, ADDR temp, 1, ADDR bRead
        INVOKE ReadConsoleInput, myHandle, ADDR temp, 1, ADDR bRead

       ; Main infinite loop
    more:

        ; Get number of events in input buffer
        INVOKE GetNumberOfConsoleInputEvents, myHandle, ADDR numInp
        MOV ECX, numInp

        CMP ECX, 0                          ; Check if input buffer is empty
        JE done                             ; Continue loop if buffer is empty

        ; Read one event from input buffer and save it at temp
        INVOKE ReadConsoleInput, myHandle, ADDR temp, 1, ADDR bRead
        MOV DX, WORD PTR temp               ; Check if EventType is KEY_EVENT,
        CMP DX, 1                           ; which is determined by 1st WORD
        JNE SkipEvent                       ; of INPUT_RECORD message

            MOV DL, BYTE PTR [temp+4]       ; Skip key released event
            CMP DL, 0
            JE SkipEvent
                MOV DL, BYTE PTR [temp+10]  ; Copy pressed key into DL

                CMP DL, 1Bh                 ; Check if ESC key was pressed and
                JE quit                     ; quit the game if it was

        
                ;CMP d, 'w'                  ; Check if current snake direction
                ;JE case1                    ; is vertical, and jump to case1 to
                ;CMP d, 's'                  ; handle direction change if the
                ;JE case1                    ; change is horizontal

                ;JMP case2                   ; Jump to case2 if the current
                                            ; direction is horizontal
                ; case1:
                     CMP DL, 25h             ; Check if left arrow was in input
                     JE case11
                    CMP DL, 27h             ; Check if right arrow was in input
                    JE case12
                    CMP DL, 26h             ; Check if up arrow was in input
                    JE case21
                    CMP DL, 28h             ; Check if down arrow was in input
                    JE case22
                    JMP SkipEvent           ; If up or down arrows were in
                                            ; input, no direction change
                    case11:
                    cmp wall,'a'
                    je SkipEvent
                        MOV newD, 'a'       ; Set new direction to left
                        mov wall,'n'
                        JMP SkipEvent
                    case12:
                    cmp wall,'d'
                    je SkipEvent
                        MOV newD, 'd'       ; Set new direction to right
                        mov wall,'n'
                        JMP SkipEvent

                ; case2:
                    
                    ;JMP SkipEvent           ; If left of right arrows were in
                                            ; input, no direction change
                    case21:
                    cmp wall,'w'
                    je SkipEvent
                        MOV newD, 'w'       ; Set new direction to up
                        mov wall,'n'
                        JMP SkipEvent
                    case22:
                    cmp wall,'s'
                    je SkipEvent
                        MOV newD, 's'       ; Set new direction to down
                        mov wall,'n'
                        JMP SkipEvent

    SkipEvent:
        JMP more                            ; Continue main loop

    done:
        
        MOV BL, newD                        ; Set new direction as snake
                                            ; direction
        MOV d, BL
        CALL MoveSnake                      ; Update direction and position
        MOV EAX, DelTime                    ; Delay before next iteration (game
        CALL Delay                          ; speed is influenced this way)

        MOV BL, d                           ; Why is this needed?
        MOV newD, BL                        ; Maybe delete these two lines

        CMP eGame, 1                        ; Check if end game flag is set
        JE quit                             ; (from a collision)

        JMP more                            ; Continue main loop

        quit:
        EXIT
        ; CALL clearMem                       ; Set all game related things to
        ; MOV delTime, 100                    ; default, and go back to main
                                            ; menu
    RET

startGame ENDP

MoveSnake PROC USES EBX EDX

; This procedure updates the framebuffer, thus moving the snake. The procedure
; starts from the snake tail, and searches for the next segment in the
; region of the current segment. All segments get updated, while the last
; segment gets erased (if no food has been eaten), and a new segment gets
; addded to the beginning of the snake, depending on the terminal input.
; This procedure also check if there has been a collision, and if the food was
; gobbled or not.

    ;CMP eTail, 1            ; Check if erase tail flag is set
    ;JNE NoETail             ; Don't erase the tail if flag is not set

        MOV DH, hR          ; Copy tail row index into DH----->copy head row index
        MOV DL, hC          ; Copy tail column index into DL-->copy head col index
        MOV tempr, DH
        MOV tempc, DL
        CALL accessIndex    ; Access framebuffer at given index
        DEC BX              ; Decrement value returned from framebuffer (this
                            ; gives us the value of the next segment)
        MOV search, BX      ; Copy value of next segment to search

        MOV BX, 0           ; Erase the value at current index from the
        CALL saveIndex      ; framebuffer (the snake tail)

        CALL GotoXY         ; Erase snake tail pixel from screen---->erase head
        MOV EAX, white + (black * 16)
        CALL SetTextColor
        MOV AL, ' '
        CALL WriteChar

        PUSH EDX            ; Move cursor to bottom right side of the screen
        MOV DL, 29
        MOV DH, 24
        CALL GotoXY
        POP EDX

    ;     MOV AL, DH          ; Copy tail row index into AL
    ;     DEC AL              ; Get index of row above current row
    ;     MOV rM, AL          ; Save index of row above current row
    ;     ADD AL, 2           ; Get index of row below current row
    ;     MOV rP, AL          ; Save index of row below current row

    ;     MOV AL, DL          ; Copy tail column index into AL
    ;     DEC AL              ; Get index of column left of current column
    ;     MOV cM, AL          ; Save index of column left of current column
    ;     ADD AL, 2           ; Get index of column right of current column
    ;     MOV cP, AL          ; Save index of column right of current column
	; ;��ɭ��ˬd
    ;     CMP rP, 24          ; Check if new index is getting off screen
    ;     JNE next1
        
    ;         MOV rP, 0       ; Wrap the index around the screen

    ;     next1:
    ;     CMP cP, 29          ; Check if new index is getting off screen
    ;     JNE next2
        
    ;         MOV cP, 0       ; Wrap the index around the screen

    ;     next2:
    ;     CMP rM, 1           ; Check if new index is getting off screen
    ;     JGE next3
        
    ;         MOV rM, 24      ; Wrap the index around the screen

    ;     next3:
    ;     CMP cM, 1           ; Check if new index is getting off screen
    ;     JGE next4
        
    ;         MOV cM, 29      ; Wrap the index around the screen

    ;     next4:
	; ;���s�w��tail��m
    ;     MOV DH, rM          ; Copy row index of pixel above tail into DH
    ;     MOV DL, tC          ; Copy column index of pixel above tail into DL
    ;     CALL accessIndex    ; Access pixel value in framebuffer
    ;     CMP BX, search      ; Check if pixel is the next segment of the snake
    ;     JNE melseif1
    ;         MOV tR, DH      ; Move tail to new location, if it is
    ;         JMP mendif

    ;     melseif1:
    ;     MOV DH, rP          ; Copy row index of pixel below tail into DH
    ;     CALL accessIndex    ; Acces pixel value in framebuffer
    ;     CMP BX, search      ; Check if pixel is the next segment of the snake
    ;     JNE melseif2
    ;         MOV tR, DH      ; Move tail to new location, if it is
    ;         JMP mendif

    ;     melseif2:
    ;     MOV DH, tR          ; Copy row index of pixel left of tail into DH
    ;     MOV DL, cM          ; Copy column index of pixel left of tail into DH
    ;     CALL accessIndex    ; Access pixel value in framebuffer
    ;     CMP BX, search      ; Check if pixes is the next segment of the snake
    ;     JNE melse
    ;         MOV tC, DL      ; Move tail to new location, if it is
    ;         JMP mendif

    ;     melse:
    ;         MOV DL, cP      ; Move tail to pixel right of tail
    ;         MOV tC, DL

    ;     mendif:

    ; NoETail:

    ; MOV eTail, 1            ; Set erase tail flag
    ; MOV DH, tR              ; Copy row index of tail into DH
    ; MOV DL, tC              ; Copy column index of tail into DL
    ; MOV tmpR, DH            ; Copy row index into memory
    ; MOV tmpC, DL            ; Copy column index into memory

    ; whileTrue:              ; Infinite loop for going over all the snake
    ;                         ; segments and adjusting each value
    ;     MOV DH, tmpR        ; Copy current row index into DH
    ;     MOV DL, tmpC        ; Copy current column index into DL
    ;     CALL accessIndex    ; Get pixel value form framebuffer
    ;     DEC BX              ; Decrement pixel value to get the value of the
    ;                         ; next snake segment
    ;     MOV search, BX      ; Copy value of next segment into search

    ;     PUSH EBX            ; Replace current segment value in framebuffer with
    ;     ADD BX, 2           ; previous segment value (snake is moving, segments
    ;     CALL saveIndex      ; are moving)
    ;     POP EBX

    ;     CMP BX, 0           ; Check if the current segment is the head of the
    ;     JE break            ; snake

    ;     MOV AL, DH          ; Copy row index of current segment into AL
    ;     DEC AL              ; Get index of row above current row
    ;     MOV rM, AL          ; Save index of row above current row
    ;     ADD AL, 2           ; Get index of row below current row
    ;     MOV rP, AL          ; Save index of row below current row

    ;     MOV AL, DL          ; Copy column index of current segment into AL
    ;     DEC AL              ; Get index of column left of current column
    ;     MOV cM, AL          ; Save index of column left of current column
    ;     ADD AL, 2           ; Get index of column right of current column
    ;     MOV cP, AL          ; Save index of column right of current column

    ;     CMP rP,  24          ; Check if new index is getting off screen
    ;     JNE next21
        
    ;         MOV rP, 0       ; Wrap index around screen

    ;     next21:
    ;     CMP cP, 30          ; Check if new index is getting off screen
    ;     JNE next22
        
    ;         MOV cP, 0       ; Wrap index around screen

    ;     next22:
    ;     CMP rM, 0           ; Check if index is getting off screen
    ;     JGE next24
        
    ;         MOV rM, 24      ; Wrap index around screen

    ;     next24:
    ;     CMP cM, 0           ; Check if index is getting off screen
    ;     JGE next 24
        
    ;         MOV cM, 29      ; Wrap index around screen

    ;     next 24:

    ;     MOV DH, rM          ; Copy row index of pixel above segment into DH
    ;     MOV DL, tmpC        ; Copy column index of pixel above segment into DH
    ;     CALL accessIndex    ; Access pixel value in framebuffer
    ;     CMP BX, search      ; Check if pixel is the next segment of the snake
    ;     JNE elseif21
    ;         MOV tmpR, DH    ; Move index to new location, if it is
    ;         JMP endif2

    ;     elseif21:
    ;     MOV DH, rP          ; Copy row index of pixel below segment into DH
    ;     CALL accessIndex    ; Access pixel value in framebuffer
    ;     CMP BX, search      ; Check if pixel is the next segment of the snake
    ;     JNE elseif22
    ;         MOV tmpR, DH    ; Move index to new location, if it is
    ;         JMP endif2

    ;     elseif22:
    ;     MOV DH, tmpR        ; Copy row index of pixel left of segment into DH
    ;     MOV DL, cM          ; Copy column index of pxl left of segment into DL
    ;     CALL accessIndex    ; Access pixel value in framebuffer
    ;     CMP BX, search      ; Check if pixel is the next segment of the snake
    ;     JNE else2
    ;         MOV tmpC, DL    ; Move index to new location if it is
    ;         JMP endif2

    ;     else2:
    ;         MOV DL, cP      ; Move index to pixel right of segment
    ;         MOV tmpC, DL

    ;     endif2:
    ;     JMP whileTrue       ; Continue loop until the snake head is reached

    ; break:

    MOV AL, hR              ; Copy head row index into AL
    DEC AL                  ; Get index of row above head row
    MOV rM, AL              ; Save index of row above head row
    ADD AL, 2               ; Get index of row below head row
    MOV rP, AL              ; Save index of row below head row

    MOV AL, hC              ; Copy head column index into AL
    DEC AL                  ; Get index of column left of head column
    MOV cM, AL              ; Save index of column left of head column
    ADD AL, 2               ; Get index of column right of head column
    MOV cP, AL              ; Save index of column right of head column

    cmp d,'s'
    jne next31
    CMP rP,  24              ; Check if new index is getting off screen
    JNE next31
    mov newD,'n'
    mov d,'n'
    mov wall,'s'
    jmp next34
        ;MOV rP, 0           ; Wrap index around screen


    next31:
    cmp d,'d'
    jne next32
    CMP cP, 30              ; Chekc if new index is getting off screen
    JNE next32
    mov newD,'n'
    mov d,'n'
    mov wall,'d'
    jmp next34
       ; MOV cP, 0           ; Wrap index around screen

    
    next32:
    cmp d,'w'
    jne next33
    CMP rM, 0               ; Check if new index is getting off sreen
    JGE next33
    mov newD,'n'
    mov d,'n'
    mov wall,'w'
    jmp next34
        ;MOV rM, 24          ; Wrap index around screen

    next33:
    cmp d,'a'
    jne next34
    CMP cM, 0               ; Check if new index is getting off screen
    JGE next34
        mov newD,'n'
        mov d,'n'
        mov wall,'a'
        ;MOV cM, 29          ; Wrap index around screen

    next34:

    CMP d, 'w'              ; Check if input direction is up
    JNE elseif3
        MOV AL, rM          ; Move head row index to new location,
        MOV hR, AL          ; above current location
        JMP endif3

    elseif3:
    CMP d, 's'              ; Check if input direction is down
    JNE elseif32
        MOV AL, rP          ; Move head row index to new location,
        MOV hR, AL          ; below current location
        JMP endif3

    elseif32:
    CMP d, 'a'              ; Check if input direction is left
    JNE stop
        MOV AL, cM          ; Move head column index to new location,
        MOV hC, AL          ; left of current location
        JMP endif3

    stop:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    cmp d,'n'
    JNE else3
        ;do nothing~~
        JMP endif3

    else3:  ;right
        MOV AL, cP          ; Move head column index to new location,
        MOV hC, AL          ; right of current location

    endif3:

    MOV DH, hR              ; Copy new head row index into DH
    MOV DL, hC              ; Copy new head column index into DL

    CALL accessIndex        ; Get pixel value of new head location
    CMP BX, 0               ; Check if new head location is empty space
    JE NoHit                ; If the new head location is empty space, there
                            ; has been no collision
    JMP notdead
    ;dead
    ;MOV EAX, 4000           ; Set delay time to 4000ms
    ;MOV DH,  24              ; Move cursor to new location, to write game over
    ;MOV DL, 11              ; message
    ;CALL GotoXY
    ;MOV EDX, OFFSET hitS
    ;CALL WriteString

    ;CALL Delay              ; Call delay to pause game for 4 seconds
    ;MOV eGame, 1            ; Set end game flag

    ;RET                     ; Exit procedure

    NoHit:                  ; Part of procedure that handles the case where
    MOV BX, 1               ; there's been no collision
    CALL saveIndex          ; Write head value to new head location

    MOV cl, fC              ; Copy food column to memory
    MOV ch, fR              ; Copy food row to memory

    CMP cl, DL              ; Compare new head column and food column
    JNE foodNotGobbled      ; Food has not been eaten
    CMP ch, DH              ; Compare new head row and food row
    JNE foodNotGobbled      ; Food has not been eaten

    CALL createFood         ; Food has been eaten, create new food location
    MOV eTail, 0            ; Clear erase tail flag, so that snake grows in
                            ; next framebuffer update

    MOV EAX, white + (black * 16)
    CALL SetTextColor       ; Change background color to white on black

    PUSH EDX                ; Push EDX onto stack

    MOV DH,  24              ; Move cursor to new location, to update score
    MOV DL, 7
    CALL GotoXY
    MOV EAX, cScore         ; Move score to EAX and increment it
    INC EAX
    CALL WriteDec
    MOV cScore, EAX         ; Copy updated score value back into memory

    POP EDX                 ; Pop EDX off of stack

    foodNotGobbled:         ; Part of procedure that handles the case where
    CALL GotoXY             ; food has not been eaten (just adds head)
    MOV EAX, black + (white * 16);
    CALL setTextColor       ; Change text color to blue on white
    MOV AL, ' '             ; Write whitespace to new head location
    CALL WriteChar
    MOV DH,  24              ; Move cursor to bottom right side of screen
    MOV DL, 29
    CALL GotoXY
    RET

    notdead:
        MOV DH, tempr
        MOV DL, tempc
        CALL accessIndex
        MOV BX, 0FFFFh      ; Erase the value at current index from the
        CALL saveIndex      ; framebuffer (the snake tail)

        CALL GotoXY         ; Erase snake tail pixel from screen---->erase head
        MOV EAX, black + (white * 16)
        CALL SetTextColor
        MOV AL, ' '
        CALL WriteChar

        MOV DH, tempr
        MOV DL, tempc
        MOV hR, DH
        MOV hc, DL
        MOV DH, 24              ; Move cursor to bottom right side of screen
        MOV DL, 29
        CALL GotoXY
    RET                     ; Exit procedure

MoveSnake ENDP

createFood PROC USES EAX EBX EDX

; This procedure generates food for the snake. It uses a radnom nubmer to
; generate the row and column values for the location of the food. It also
; takes into account the position of the snake and obstacles, so that the food
; doesn't overlap with the snake or the obstacles.

    redo:                       ; Loop for food position generation
    MOV EAX,  24                 ; Generate a radnom integer in the
    CALL RandomRange            ; range 0 to numRows - 1
    MOV DH, AL

    MOV EAX, 30                 ; Generate a radnom integer in the
    CALL RandomRange            ; range 0 to numCol - 1
    MOV DL, AL

    CALL accessIndex            ; Get content of generated location

    CMP BX, 0                   ; Check if content is empty space
    JNE redo                    ; Loop until location is empty space

    MOV fR, DH                  ; Set food row value
    MOV fC, DL                  ; Set food column value

    MOV EAX, white + (black * 16); Set text color to white on cyan
    CALL setTextColor
    CALL GotoXY                 ; Move cursor to generated position
    MOV AL, '%'                 ; Write whitespace to terminal
    CALL WriteChar

    RET

createFood ENDP

accessIndex PROC USES EAX ESI EDX

; This procedure accesses the framebuffer and returns the value of the pixel
; specified by DH (row index) and DL (column index). The pixel value gets
; returned through the register BX.

    MOV BL, DH      ; Copy row index into BL
    MOV AL, 30      ; Copy multiplication constant for row number
    MUL BL          ; Mulitply row index by 30 to get framebuffer segment
    PUSH DX         ; Push DX onto stack
    MOV DH, 0       ; Clear upper byte of DX to get only column index
    ADD AX, DX      ; Add column offset to row segment to get pixel address
    POP DX          ; Pop DX off of stack
    MOV ESI, 0      ; Clear indexing register
    MOV SI, AX      ; Copy generated address into indexing register
    SHL SI, 1       ; Multiply address by 2 since the elements are of type WORD

    MOV BX, a[SI]   ; Copy framebuffer content into BX register

    RET

accessIndex ENDP

saveIndex PROC USES EAX ESI EDX

; This procedure accesses the framebuffer and writes a value to the pixel
; specified by DH (row index) and DL (column index). The pixel value has to be
; passed though the register BX.

    PUSH EBX        ; Save EBX on stack
    MOV BL, DH      ; Copy row number to BL
    MOV AL, 30      ; Copy multiplication constant for row number
    MUL BL          ; Multiply row index by 30 to get framebuffer segment
    PUSH DX         ; Push DX onto stack
    MOV DH, 0       ; Clear DH register, to access the column number
    ADD AX, DX      ; Add column offset to get the array index
    POP DX          ; Pop old address off of stack
    MOV ESI, 0      ; Clear indexing register
    MOV SI, AX      ; Move generated address into ESI register
    POP EBX         ; Pop EBX off of stack
    SHL SI, 1       ; Multiply address by two, because elements
                    ; are of type WORD
    MOV a[SI], BX   ; Save BX into array

    RET

saveIndex ENDP

Paint PROC USES EAX EDX EBX ESI

; This procedure reads the contents of the framebuffer, pixel by pixel, and
; puts them onto the terminal screen. This includes the snake and the walls.
; The color of the walls can be changed in this procedure. The color of the
; snake has to be changed here, as well as in the moveSnake procedure.

    MOV EAX, blue + (white * 16)    ; Set text color to blue on white
    CALL SetTextColor

    MOV DH, 0                       ; Set row number to 0

    loop1:                          ; Loop for indexing of the rows
        CMP DH,  24                  ; Check if the indexing has arrived
        JGE endLoop1                ; at the bottom of the screen

        MOV DL, 0                   ; Set column number to 0

        loop2:                      ; Loop for indexing of the columns
            CMP DL, 30              ; Check if the indexing has arrived
            JGE endLoop2            ; at the right side of the screen
            CALL GOTOXY             ; Set cursor to current pixel position

            MOV BL, DH              ; Generate the framebuffer address from
            MOV AL, 30              ; the row value stored in DH
            MUL BL
            PUSH DX                 ; Save DX on stack
            MOV DH, 0               ; Clear upper bite of DX
            ADD AX, DX              ; Add offset to row address (column adress)
            POP DX                  ; Restore old value of DX
            MOV ESI, 0              ; Clear indexing register
            MOV SI, AX              ; Move pixel address into indexing register
            SHL SI, 1               ; Multiply indexing address by 2, since
                                    ; we're using elements of type WORD in the
                                    ; framebuffer
            MOV BX, a[SI]           ; Get the pixel

            CMP BX, 0               ; Check if pixel is empty space,
            JE NoPrint              ; and don't print it if is

            CMP BX, 0FFFFh          ; Check if pixel is part of a wall
            JE PrintHurdle          ; Jump to segment for printing walls

            MOV AL, ' '             ; Pixel is part of the snake, so print
            CALL WriteChar          ; whitespace
            JMP NoPrint             ; Jump to end of loop

            PrintHurdle:            ; Segment for printing the walls
            MOV EAX, blue + (gray * 16) ; Change the text color to blue on gray
            CALL SetTextColor

            MOV AL, ' '             ; Print whitespace
            CALL WriteChar

            MOV EAX, blue + (white * 16)    ; Change the text color back to
            CALL SetTextColor               ; blue on white

            NoPrint:
            INC DL                  ; Increment the column number
            JMP loop2               ; Continue column indexing

    endLoop2:                       ; End of column loop
        INC DH                      ; Increment the row number
        JMP loop1                   ; Continue row indexing

endLoop1:                           ; End of row loop

RET

Paint ENDP

GenLevel PROC

; This procedure takes care of generating the level obstacles. There are three
; levels; a no obstacle level, a box level, and a level with four rooms. The
; level choice gets passed through the AL register (can be 1 to 3). Default
; level choice is without obstacles.
; Obstacles get written into the framebuffer, as 0FFFFh values.

    ;CMP AL, 1               ; Check if level choice is without obstacles
    ;JNE nextL               ; If not, jump to next level selection
    




    ;MOV newD, 'd'       ; Set the default direction to down, as not to run
    ;MOV DH, 1           ; immediately into a wall
    ;MOV DL, 1           ; Set row and column numbers to 11 and 0
    ;MOV BX, 0FFFFh      ; Set value for writing into framebuffer

    ;.while DL!=22
    ;    CALL saveIndex  ; Write obstacle value to framebuffer
    ;    INC DL
    ;.ENDW

    ;RET
    ;MOV newD, 'd'       ; Set the default direction to down, as not to run
    ;MOV DH, 1           ; immediately into a wall
    ;MOV DL, 1           ; Set row and column numbers to 11 and 0
    ;MOV BX, 0FFFFh      ; Set value for writing into framebuffer

    ;draw:
    ;    CALL saveIndex  ; Write obstacle value to framebuffer
    ;    INC DL          ; Increment column number
    ;    JMP L1
    ;L1:
    ;    CMP DL, 7
    ;    JGE L2
    ;    JMP draw
    ;L2:
    ;    INC DL
    ;    CMP DL, 14
    ;    JGE L3
    ;    DEC DL
    ;    JMP draw
    ;L3:
    ;    CMP DL, 22
    ;    JGE L4
    ;    JMP draw
    ;L4: 
    ;    CMP DL, 29
    ;    JGE endLoop
    ;endLoop:
    ;RET    
    ;draw map by CC-------------------------------------------------------------------------------
    nextL2:                 ; Section for generating rooms level

        MOV newD, 'd'       ; Set the default direction to down, as not to run
        MOV DH, 1           ; immediately into a wall
        MOV DL, 1           ; Set row and column numbers to 11 and 0
        MOV BX, 0FFFFh      ; Set value for writing into framebuffer

        ;first square
        cLoop2:             ; Loop for painting a horizontal line in the middle
                            ; of the screen (row 11)
            CMP DL, 7       ; Check if right side of screen was reached
            JE endCLoop2

            CALL saveIndex  ; Write obstacle value to framebuffer
            INC DL          ; Increment column number
            JMP cLoop2      ; Continue until right side of screen is reached

        endCloop2:          ; Prepare for vertical line painting
        MOV DH, 1           ; Start from top of screen
        MOV DL, 8           ; Vertical line will be at row 39

        cLoopb:             ; Loop for painting a horizontal line in the middle
                            ; of the screen (row 11)
            CMP DL, 14       ; Check if right side of screen was reached
            JE endCLoopb

            CALL saveIndex  ; Write obstacle value to framebuffer
            INC DL          ; Increment column number
            JMP cLoopb      ; Continue until right side of screen is reached

        endCloopb:          ; Prepare for vertical line painting
        MOV DH,  1          ; Start from top of screen
        MOV DL, 16          ; Vertical line will be at row 39

        cLoop2c:             ; Loop for painting a horizontal line in the middle
                            ; of the screen (row 11)
            CMP DL, 22       ; Check if right side of screen was reached
            JE endCLoop2c

            CALL saveIndex  ; Write obstacle value to framebuffer
            INC DL          ; Increment column number
            JMP cLoop2c      ; Continue until right side of screen is reached

        endCloop2c:          ; Prepare for vertical line painting
        MOV DH,  1          ; Start from top of screen
        MOV DL, 23          ; Vertical line will be at row 39

        cLoop2d:             ; Loop for painting a horizontal line in the middle
                            ; of the screen (row 11)
            CMP DL, 29       ; Check if right side of screen was reached
            JE endCLoop2d

            CALL saveIndex  ; Write obstacle value to framebuffer
            INC DL          ; Increment column number
            JMP cLoop2d      ; Continue until right side of screen is reached

        endCloop2d:          ; Prepare for vertical line painting
        MOV DH, 3
        MOV DL, 1

        cLoop3:             
                            
            CMP DL, 7       
            JE endCLoop3

            CALL saveIndex  
            INC DL          
            JMP cLoop3      

        endCloop3:          
        MOV DH, 3          
        MOV DL, 8     

        cLoop3b:             
                            
            CMP DL, 14       
            JE endCLoop3b

            CALL saveIndex  
            INC DL          
            JMP cLoop3b      

        endCloop3b:          
        MOV DH, 3          
        MOV DL, 16   

        cLoop3c:             
                            
            CMP DL, 22       
            JE endCLoop3c

            CALL saveIndex  
            INC DL          
            JMP cLoop3c      

        endCloop3c:          
        MOV DH, 3          
        MOV DL, 23

        cLoop3d:             
                            
            CMP DL, 29       
            JE endCLoop3d

            CALL saveIndex  
            INC DL          
            JMP cLoop3d      

        endCloop3d:
        
        ;first line
        MOV DH, 5          
        MOV DL, 1
        cLoop5:             
            CMP DL, 7       
            JE endCLoop5

            CALL saveIndex  
            INC DL          
            JMP cLoop5   
        endCloop5:          
        MOV DH, 5          
        MOV DL, 8

        cLoop5b:             
            CMP DL, 11       
            JE endCLoop5b

            CALL saveIndex  
            INC DL          
            JMP cLoop5b   
        endCloop5b:          
        MOV DH, 5          
        MOV DL, 12

        cLoop5c:             
            CMP DL, 18       
            JE endCLoop5c

            CALL saveIndex  
            INC DL          
            JMP cLoop5c   
        endCloop5c:          
        MOV DH, 5          
        MOV DL, 19

        cLoop5d:             
            CMP DL, 22       
            JE endCLoop5d

            CALL saveIndex  
            INC DL          
            JMP cLoop5d  
        endCloop5d:          
        MOV DH, 5          
        MOV DL, 23

        cLoop5e:             
            CMP DL, 29       
            JE endCLoop5e

            CALL saveIndex  
            INC DL          
            JMP cLoop5e   
        endCloop5e:          
       
        MOV DH, 7          
        MOV DL, 0
        cLoop7:             
            CMP DL, 9       
            JE endCLoop7

            CALL saveIndex  
            INC DL          
            JMP cLoop7   
        endCloop7:          
        MOV DH, 7          
        MOV DL, 10

        cLoop7b:             
            CMP DL, 20         
            JE endCLoop7b

            CALL saveIndex  
            INC DL          
            JMP cLoop7b   
        endCloop7b:          
        MOV DH, 7          
        MOV DL, 21

        cLoop7c:             
            CMP DL, 30       
            JE endCLoop7c

            CALL saveIndex  
            INC DL          
            JMP cLoop7c   
        endCloop7c:

        MOV DH, 2          
        MOV DL, 1
        cLoop22:             
            CMP DL, 7       
            JE endCLoop22

            CALL saveIndex  
            INC DL          
            JMP cLoop22   
        endCloop22: 
        
        MOV DH, 2          
        MOV DL, 23
        cLoop22b:             
            CMP DL, 29       
            JE endCLoop22b

            CALL saveIndex  
            INC DL          
            JMP cLoop22b   
        endCloop22b:   

        MOV DH, 8          
        MOV DL, 0
        cLoop8:             
            CMP DL, 9       
            JE endCLoop8

            CALL saveIndex  
            INC DL          
            JMP cLoop8   
        endCloop8:
        MOv DH, 8
        MOV Dl, 10

        MOV DH, 8          
        MOV DL, 21
        cLoop8b:             
            CMP DL, 30       
            JE endCLoop8b

            CALL saveIndex  
            INC DL          
            JMP cLoop8b   
        endCloop8b:

        MOV DH, 9          
        MOV DL, 0
        cLoop9:             
            CMP DL, 9       
            JE endCLoop9

            CALL saveIndex  
            INC DL          
            JMP cLoop9   
        endCloop9:
        MOv DH, 9
        MOV Dl, 21

        cLoop9b:             
            CMP DL, 30       
            JE endCLoop9b

            CALL saveIndex  
            INC DL          
            JMP cLoop9b   
        endCloop9b:
        
        MOV DH, 12          
        MOV DL, 0
        cLoop12:             
            CMP DL, 9       
            JE endCLoop12

            CALL saveIndex  
            INC DL          
            JMP cLoop12   
        endCloop12:
        MOv DH, 12
        MOV Dl, 21
        cLoop12b:             
            CMP DL, 30       
            JE endCLoop12b

            CALL saveIndex  
            INC DL          
            JMP cLoop12b   
        endCloop12b:

        MOV DH, 13
        MOV DL, 0
        cLoop13:             
            CMP DL, 9       
            JE endCLoop13

            CALL saveIndex  
            INC DL          
            JMP cLoop13   
        endCloop13:
        MOV DH, 13
        MOV DL, 21
        cLoop13b:             
            CMP DL, 30       
            JE endCLoop13b

            CALL saveIndex  
            INC DL          
            JMP cLoop13b   
        endCloop13b:

        MOV DH, 14
        MOV DL, 0
        cLoop14:             
            CMP DL, 9       
            JE endCLoop14

            CALL saveIndex  
            INC DL          
            JMP cLoop14 
        endCloop14:

        MOV DH, 14
        MOV DL, 21
        cLoop14b:             
            CMP DL, 30       
            JE endCLoop14b

            CALL saveIndex  
            INC DL          
            JMP cLoop14b 
        endCloop14b:

        MOV DH, 14
        MOV DL, 12
        cLoop14c:             
            CMP DL, 18       
            JE endCLoop14c

            CALL saveIndex  
            INC DL          
            JMP cLoop14c 
        endCloop14c:

        MOV DH, 16
        MOV DL, 1
        cLoop16:             
            CMP DL, 7       
            JE endCLoop16

            CALL saveIndex  
            INC DL          
            JMP cLoop16 
        endCloop16:

        MOV DH, 16
        MOV DL, 8
        cLoop16b:             
            CMP DL, 13       
            JE endCLoop16b

            CALL saveIndex  
            INC DL          
            JMP cLoop16b 
        endCloop16b:

        MOV DH, 16
        MOV DL, 17
        cLoop16c:             
            CMP DL, 22       
            JE endCLoop16c

            CALL saveIndex  
            INC DL          
            JMP cLoop16c 
        endCloop16c:

        MOV DH, 16
        MOV DL, 23
        cLoop16d:             
            CMP DL, 29       
            JE endCLoop16d

            CALL saveIndex  
            INC DL          
            JMP cLoop16d 
        endCloop16d:

        MOV DH, 18
        MOV DL, 1
        cLoop18:             
            CMP DL, 10      
            JE endCLoop18

            CALL saveIndex  
            INC DL          
            JMP cLoop18 
        endCloop18:

        MOV DH, 18
        MOV DL, 11
        cLoop18b:             
            CMP DL, 13      
            JE endCLoop18b

            CALL saveIndex  
            INC DL          
            JMP cLoop18b 
        endCloop18b:

        MOV DH, 18
        MOV DL, 17
        cLoop18c:             
            CMP DL, 19      
            JE endCLoop18c

            CALL saveIndex  
            INC DL          
            JMP cLoop18c 
        endCloop18c:

        MOV DH, 18
        MOV DL, 20
        cLoop18d:             
            CMP DL, 29      
            JE endCLoop18d

            CALL saveIndex  
            INC DL          
            JMP cLoop18d 
        endCloop18d:

        MOV DH, 20
        MOV DL, 0
        cLoop20:             
            CMP DL, 8      
            JE endCLoop20

            CALL saveIndex  
            INC DL          
            JMP cLoop20 
        endCloop20:

        MOV DH, 20
        MOV DL, 22
        cLoop20b:             
            CMP DL, 30      
            JE endCLoop20b

            CALL saveIndex  
            INC DL          
            JMP cLoop20b 
        endCloop20b:

        MOV DH, 22
        MOV DL, 2
        cLoop222:               ;22        
            CMP DL, 14      
            JE endCLoop222

            CALL saveIndex  
            INC DL          
            JMP cLoop222
        endCloop222:

        MOV DH, 22
        MOV DL, 16
        cLoop222b:              ;22            
            CMP DL, 29      
            JE endCLoop222b

            CALL saveIndex  
            INC DL          
            JMP cLoop222b
        endCloop222b:

        ;draw straight
        ;first square

        
        MOV DH, 8           
        MOV DL, 10          
        rLoop10:             
            CMP DH, 10      
            JE endRLoop10

            CALL saveIndex  
            INC DH          
            JMP rLoop10     
        endRLoop10:

        MOV DH, 8           
        MOV DL, 19          
        rLoop19:             
            CMP DH, 10      
            JE endRLoop19

            CALL saveIndex  
            INC DH          
            JMP rLoop19     
        endRLoop19:

        MOV DH, 12           
        MOV DL, 10          
        rLoop10b:             
            CMP DH, 15      
            JE endRLoop10b

            CALL saveIndex  
            INC DH          
            JMP rLoop10b    
        endRLoop10b:

        MOV DH, 12           
        MOV DL, 19          
        rLoop19b:             
            CMP DH, 15      
            JE endRLoop19b

            CALL saveIndex  
            INC DH          
            JMP rLoop19b     
        endRLoop19b:
        
        MOV DH, 15           
        MOV DL, 15          
        rLoop15:             
            CMP DH, 16      
            JE endRLoop15

            CALL saveIndex  
            INC DH          
            JMP rLoop15    
        endRLoop15:

        MOV DH, 15           
        MOV DL, 14          
        rLoop14:             
            CMP DH, 16      
            JE endRLoop14

            CALL saveIndex  
            INC DH          
            JMP rLoop14    
        endRLoop14:

        MOV DH, 17           
        MOV DL, 14          
        rLoop14b:             
            CMP DH, 21      
            JE endRLoop14b

            CALL saveIndex  
            INC DH          
            JMP rLoop14b   
        endRLoop14b:

        MOV DH, 17           
        MOV DL, 15          
        rLoop15b:             
            CMP DH, 21      
            JE endRLoop15b

            CALL saveIndex  
            INC DH          
            JMP rLoop15b    
        endRLoop15b:

        MOV DH, 19           
        MOV DL, 9          
        rLoop12:             
            CMP DH, 21      
            JE endRLoop12

            CALL saveIndex  
            INC DH          
            JMP rLoop12    
        endRLoop12:

        MOV DH, 19           
        MOV DL, 20          
        rLoop20:             
            CMP DH, 21      
            JE endRLoop20

            CALL saveIndex  
            INC DH          
            JMP rLoop20    
        endRLoop20:

        MOV DH, 19           
        MOV DL, 11          
        rLoop11:             
            CMP DH, 23      
            JE endRLoop11

            CALL saveIndex  
            INC DH          
            JMP rLoop11    
        endRLoop11:

        MOV DH, 19           
        MOV DL, 12          
        rLoop12b:             
            CMP DH, 23      
            JE endRLoop12b

            CALL saveIndex  
            INC DH          
            JMP rLoop12b    
        endRLoop12b:

        MOV DH, 19           
        MOV DL, 17          
        rLoop17:             
            CMP DH, 23      
            JE endRLoop17

            CALL saveIndex  
            INC DH          
            JMP rLoop17    
        endRLoop17:

        MOV DH, 19           
        MOV DL, 18          
        rLoop18:             
            CMP DH, 23      
            JE endRLoop18

            CALL saveIndex  
            INC DH          
            JMP rLoop18    
        endRLoop18:

    RET
    ;draw map by CC-----------------------------------------------------------------------------*/









































    nextL:                  ; Check if level choic is box level
    CMP AL, 2
    JNE nextL2              ; If not, jump to next level selection

    MOV DH, 0               ; Set row index to 0
    MOV BX, 0FFFFh          ; Set data to be written to framebuffer

    rLoop:                  ; Loop for generating vertical lines
        CMP DH,  24          ; Check if loop has reached bottom of screen
        JE endRLoop         ; Break loop if bottom of screen is reched

        MOV DL, 0           ; Set column index to 0 (left side of screen)
        CALL saveIndex      ; Write value stored in BX to framebuffer
        MOV DL, 29          ; Set column index to 29 (right side of screen)
        CALL saveIndex      ; Write value stored in BX to framebuffer
        INC DH              ; Increment row value
        JMP rLoop           ; Continue loop
    endRLoop:

    MOV DL, 0               ; Set column index to 0

    cLoop:                  ; Loop for generating horizontal lines
        CMP DL, 30          ; Check if loop has reached right side of screen
        JE endCLoop         ; Break loop if right side of screen is reached

        MOV DH, 0           ; Set row index to 0 (top of screen)
        CALL saveIndex      ; Write value stored in BX to framebuffer
        MOV DH, 24          ; Set row index to 24 (bottom of screen)
        CALL saveIndex      ; Write value stored in BX to framebuffer
        INC DL              ; Increment column value
        JMP cLoop           ; Continue loop

        endCLoop:

    RET

    

GenLevel ENDP

END main