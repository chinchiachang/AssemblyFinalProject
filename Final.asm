TITLE Snake.asm

INCLUDE Irvine32.inc

main  EQU start@0

.DATA

a WORD 720 DUP(0)  ; Framebuffer ( 24*30)
         ;12445678901244567890124456789012445678901244567890124456789012445678901244567890 
; map BYTE "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW"
;     BYTE "W                                                   W"
;     BYTE "W   WWWWWWWW   WWWWWWWW   W   WWWWWWWW   WWWWWWWW   W"
;     BYTE "W   W      W   W      W   W   W      W   W      W   W"
;     BYTE "W   WWWWWWWW   WWWWWWWW   W   WWWWWWWW   WWWWWWWW   W"
;     BYTE "W                                                   W"
;     BYTE "W   WWWWWWWW   W   WWWWWWWWWWWWWWW   W   WWWWWWWW   W"
;     BYTE "W                         W                         W"
;     BYTE "WWWWWWWWWWWW   WWWWWWWW   W   WWWWWWWW   WWWWWWWWWWWW"
;     BYTE "           W   W                     W   W           "
;     BYTE "WWWWWWWWWWWW   W   WWWWWWWWWWWWWWW   W   WWWWWWWWWWWW"
;     BYTE "                   W             W                   "
;     BYTE "WWWWWWWWWWWW   W   WWWWWWWWWWWWWWW   W   WWWWWWWWWWWW"
;     BYTE "           W   W                     W   W           "
;     BYTE "WWWWWWWWWWWW   W   WWWWWWWWWWWWWWW   W   WWWWWWWWWWWW"
;     BYTE "W                         W                         W"
;     BYTE "W   WWWWWWWW   WWWWWWWW   W   WWWWWWW    WWWWWWWW   W"
;     BYTE "W          W                         W              W"
;     BYTE "WWWWWWWW   W   W   WWWWWWWWWWWWWWW   W   W   WWWWWWWW"
;     BYTE "W              W                     W              W"
;     BYTE "W   WWWWWWWWWWWWWWWWWWW   W   WWWWWWWWWWWWWWWWWWW   W"
;     BYTE "W                         W                         W"
;     BYTE "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW", 0
  

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

d       BYTE    'w' 
wall    BYTE    'n' 
newD    BYTE    'w' 
delTime DWORD   110 

menustar BYTE "               *",0Dh,0Ah,0
menuS   BYTE " 	       ^",0Dh,0Ah,
             "              ^^^",0Dh,0Ah,
             "             ^.^.^",0Dh,0Ah,
             "            ^.^^^.^",0Dh,0Ah,
             "           ^.^^.^^.^",0Dh,0Ah,0
menutree BYTE "               H",0Dh,0Ah,
              "               H",0Dh,0Ah,0Dh,0Ah,0Dh,0Ah,0Dh,0Ah,0Dh,0Ah,0
menustart BYTE "           Start Game", 0Dh, 0Ah, 0

scoreS  BYTE "Score: 0", 0

myHandle DWORD ?    ; Variable for holding the terminal input handle
numInp   DWORD ?    ; Variable for holding number of bytes in input buffer
temp BYTE 16 DUP(?) ; Variable for holding data of type INPUT_RECORD
bRead    DWORD ?    ; Variable for holding number of read input bytes

.CODE

main PROC


    menu:
    CALL Randomize              
    CALL Clrscr  

    MOV EAX, yellow + (black * 16)
    CALL SetTextColor               
    MOV EDX, OFFSET menustar       
    CALL WriteString 

    MOV EAX, 10 + (black * 16)
    CALL SetTextColor
    MOV EDX, OFFSET menuS       
    CALL WriteString  

    MOV EAX, 6 + (black * 16)
    CALL SetTextColor
    MOV EDX, OFFSET menutree       
    CALL WriteString

    MOV EAX, white + (black * 16)
    CALL SetTextColor
    MOV EDX, OFFSET menustart       
    CALL WriteString       

    wait1:                      
    CALL ReadChar

    CMP AL, '1'                 
    JE startG
    EXIT


    startG:                    
    CALL GenLevel               
    MOV EAX, 0                 
    MOV EDX, 0
    CALL Clrscr                 
    CALL initSnake              
    CALL Paint                  
    CALL createFood             
    CALL startGame              
    MOV EAX, white + (black * 16)
    CALL SetTextColor          
    JMP menu                    

main ENDP

initSnake PROC USES EBX EDX


    MOV DH, 13     
    MOV DL, 20      
    MOV BX, 1       
    CALL saveIndex  


    RET

initSnake ENDP


startGame PROC USES EAX EBX ECX EDX

        MOV EAX, white + (black * 16)       
        CALL SetTextColor
        MOV DH,  24                          
        MOV DL, 0                           
        CALL GotoXY                       
        MOV EDX, OFFSET scoreS
        CALL WriteString

        
        INVOKE getStdHandle, STD_INPUT_HANDLE
        MOV myHandle, EAX
        MOV ECX, 10

        
        INVOKE ReadConsoleInput, myHandle, ADDR temp, 1, ADDR bRead
        INVOKE ReadConsoleInput, myHandle, ADDR temp, 1, ADDR bRead

       
    more:

        
        INVOKE GetNumberOfConsoleInputEvents, myHandle, ADDR numInp
        MOV ECX, numInp

        CMP ECX, 0                          
        JE done                            

        
        INVOKE ReadConsoleInput, myHandle, ADDR temp, 1, ADDR bRead
        MOV DX, WORD PTR temp               
        CMP DX, 1                           
        JNE SkipEvent                       

            MOV DL, BYTE PTR [temp+4]       
            CMP DL, 0
            JE SkipEvent
                MOV DL, BYTE PTR [temp+10]  

                CMP DL, 1Bh                 
                JE quit                     

                    CMP DL, 25h             
                    JE case11
                    CMP DL, 27h             
                    JE case12
                    CMP DL, 26h             
                    JE case21
                    CMP DL, 28h             
                    JE case22
                    JMP SkipEvent           
                                            
                    case11:
                    cmp wall,'a'
                    je SkipEvent
                        MOV newD, 'a'       
                        mov wall,'n'
                        JMP SkipEvent
                    case12:
                    cmp wall,'d'
                    je SkipEvent
                        MOV newD, 'd'       
                        mov wall,'n'
                        JMP SkipEvent

                    case21:
                    cmp wall,'w'
                    je SkipEvent
                        MOV newD, 'w'       
                        mov wall,'n'
                        JMP SkipEvent
                    case22:
                    cmp wall,'s'
                    je SkipEvent
                        MOV newD, 's'       
                        mov wall,'n'
                        JMP SkipEvent

    SkipEvent:
        JMP more                            

    done:
        
        MOV BL, newD                        
                                            
        MOV d, BL
        CALL MoveSnake                      
        MOV EAX, DelTime                    
        CALL Delay                          

        MOV BL, d                           
        MOV newD, BL                        

        CMP eGame, 1                        
        JE quit                             

        JMP more                            

        quit:
        EXIT
       
    RET

startGame ENDP

MoveSnake PROC USES EBX EDX

        MOV DH, hR          
        MOV DL, hC          
        MOV tempr, DH
        MOV tempc, DL
        CALL accessIndex    
        DEC BX             
                            
        MOV search, BX      

        MOV BX, 0           
        CALL saveIndex      

        CALL GotoXY         
        MOV EAX, white + (black * 16)
        CALL SetTextColor
        MOV AL, ' '
        CALL WriteChar

        PUSH EDX            
        MOV DL, 29
        MOV DH, 24
        CALL GotoXY
        POP EDX

    
    MOV AL, hR              
    DEC AL                  
    MOV rM, AL              
    ADD AL, 2               
    MOV rP, AL              

    MOV AL, hC              
    DEC AL                  
    MOV cM, AL              

    ADD AL, 2               

    MOV cP, AL              
    

    cmp d,'s'
    jne next31
    CMP rP,  24              

    JNE next31
    mov newD,'n'
    mov d,'n'
    mov wall,'s'
    jmp next34
        
    next31:
    cmp d,'d'
    jne next32
    CMP cP, 30              
    JNE next32
    mov newD,'n'
    mov d,'n'
    mov wall,'d'
    jmp next34

    
    next32:
    cmp d,'w'
    jne next33
    CMP rM, 0               
    JGE next33
    mov newD,'n'
    mov d,'n'
    mov wall,'w'
    jmp next34
        

    next33:
    cmp d,'a'
    jne next34
    CMP cM, 0               
    JGE next34
        mov newD,'n'
        mov d,'n'
        mov wall,'a'
       

    next34:

    CMP d, 'w'              
    JNE elseif3
        MOV AL, rM          
        MOV hR, AL         
        JMP endif3

    elseif3:
    CMP d, 's'             
    JNE elseif32
        MOV AL, rP          
        MOV hR, AL          
        JMP endif3

    elseif32:
    CMP d, 'a'              
    JNE stop
        MOV AL, cM          
        MOV hC, AL          
        JMP endif3

    stop:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    cmp d,'n'
    JNE else3
        ;do nothing~~
        JMP endif3

    else3:  ;right
        MOV AL, cP          
        MOV hC, AL          

    endif3:

    MOV DH, hR              
    MOV DL, hC              

    CALL accessIndex       
    CMP BX, 0               
    JE NoHit                
                            
    JMP notdead

    NoHit:                  
    MOV BX, 1               
    CALL saveIndex         

    MOV cl, fC              
    MOV ch, fR              

    CMP cl, DL              
    JNE foodNotGobbled      
    CMP ch, DH              
    JNE foodNotGobbled      

    CALL createFood         
    MOV eTail, 0            
                           

    MOV EAX, white + (black * 16)
    CALL SetTextColor       

    PUSH EDX                

    MOV DH,  24              
    MOV DL, 7
    CALL GotoXY
    MOV EAX, cScore        
    INC EAX
    CALL WriteDec
    MOV cScore, EAX        

    POP EDX                 

    foodNotGobbled:        
    CALL GotoXY            
    MOV EAX, black + (12 * 16);
    CALL setTextColor       
    MOV AL, ' '             
    CALL WriteChar
    MOV DH,  24              
    MOV DL, 29
    CALL GotoXY
    RET

    notdead:
        MOV DH, tempr
        MOV DL, tempc
        CALL accessIndex
        MOV BX, 0FFFFh      
        CALL saveIndex      

        CALL GotoXY         
        MOV EAX, black + (12 * 16)
        CALL SetTextColor
        MOV AL, ' '
        CALL WriteChar

        MOV DH, tempr
        MOV DL, tempc
        MOV hR, DH
        MOV hc, DL
        MOV DH, 24             
        MOV DL, 29
        CALL GotoXY
    RET                     

MoveSnake ENDP

createFood PROC USES EAX EBX EDX


    redo:                       
    MOV EAX,  24     
    CALL RandomRange            
    MOV DH, AL

    MOV EAX, 30                 
    CALL RandomRange            
    MOV DL, AL

    CALL accessIndex            

    CMP BX, 0                   
    JNE redo                    

    MOV fR, DH                  
    MOV fC, DL                  

    MOV EAX, 14 + (black * 16)
    CALL setTextColor
    CALL GotoXY 
    MOV AL, '*'                 
    CALL WriteChar

    RET

createFood ENDP

accessIndex PROC USES EAX ESI EDX

    MOV BL, DH      
    MOV AL, 30      
    MUL BL          
    PUSH DX        
    MOV DH, 0      
    ADD AX, DX      
    POP DX          
    MOV ESI, 0     
    MOV SI, AX      
    SHL SI, 1      

    MOV BX, a[SI]  

    RET

accessIndex ENDP

saveIndex PROC USES EAX ESI EDX

    PUSH EBX        
    MOV BL, DH     
    MOV AL, 30     
    MUL BL         
    PUSH DX         
    MOV DH, 0       
    ADD AX, DX      
    POP DX          
    MOV ESI, 0      
    MOV SI, AX      
    POP EBX         
    SHL SI, 1       
                    
    MOV a[SI], BX   

    RET

saveIndex ENDP

Paint PROC USES EAX EDX EBX ESI

    MOV EAX, blue + (white * 16)    
    CALL SetTextColor

    MOV DH, 0                       

    loop1:                         
        CMP DH,  24                 
        JGE endLoop1                

        MOV DL, 0                   

        loop2:                      
            CMP DL, 30              
            JGE endLoop2            
            CALL GOTOXY            

            MOV BL, DH              
            MOV AL, 30              
            MUL BL
            PUSH DX                 
            MOV DH, 0               
            ADD AX, DX              
            POP DX                  
            MOV ESI, 0              
            MOV SI, AX              
            SHL SI, 1               
                                    
                                    
            MOV BX, a[SI]           

            CMP BX, 0               
            JE NoPrint              

            CMP BX, 0FFFFh         
            JE PrintHurdle         

            MOV AL, ' '            
            CALL WriteChar         
            JMP NoPrint             

            PrintHurdle:           
            MOV EAX, 0 + (green * 16) 
            CALL SetTextColor

            MOV AL, ' '          
            CALL WriteChar

            MOV EAX, blue + (white * 16)    
            CALL SetTextColor             

            NoPrint:
            INC DL                  
            JMP loop2              

    endLoop2:                       
        INC DH                      
        JMP loop1                  

endLoop1:                          

RET

Paint ENDP

GenLevel PROC

    
  
    ;draw map-------------------------------------------------------------------------------
    nextL2:                 

        MOV newD, 'd'       
        MOV DH, 1           
        MOV DL, 1          
        MOV BX, 0FFFFh     

        cLoop2:            
                            
            CMP DL, 7       
            JE endCLoop2

            CALL saveIndex   
            INC DL          
            JMP cLoop2       

        endCloop2:           
        MOV DH, 1          
        MOV DL, 8           

        cLoopb:            
            CMP DL, 14       
            JE endCLoopb

            CALL saveIndex   
            INC DL          
            JMP cLoopb       

        endCloopb:           
        MOV DH,  1          
        MOV DL, 16          

        cLoop2c:             
                            
            CMP DL, 22       
            JE endCLoop2c

            CALL saveIndex   
            INC DL          
            JMP cLoop2c       

        endCloop2c:         
        MOV DH,  1          
        MOV DL, 23          

        cLoop2d:            
            CMP DL, 29       
            JE endCLoop2d

            CALL saveIndex  
            INC DL          
            JMP cLoop2d      

        endCloop2d:          
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
    ;draw map -----------------------------------------------------------------------------*/



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