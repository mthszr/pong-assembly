STACK SEGMENT PARA STACK
    DB 64 DUP (' ') ;define a stack segment with 64 bytes of uninitialized space
STACK ENDS

DATA SEGMENT PARA 'DATA'

    BALL_X DW 0Ah
    BALL_Y DW 0Ah

DATA ENDS

CODE SEGMENT PARA 'CODE'

    MAIN PROC FAR
    ASSUME CS:CODE,DS:DATA,SS:STACK ;assume CS points to CODE, DS to DATA, and SS to STACK
    PUSH DS                         ;save the data segment address
    SUB AX,AX                       ;clear the AX register (set AX to 0)
    PUSH AX                         ;push AX (0) onto the stack to initialize SS:SP
    MOV AX,DATA                     ;load the adress of the DATA segment into AX
    MOV DS,AX                       ;move the address in AX to DS to set up the data segment
    POP AX                          ;restore the original value of AX from the stack
    POP AX                          ;restore the original value of DS from the stack

        MOV AH,00h  ;function to set video mode
        MOV AL,13h  ;set the video mode (320x200, 256 colors)
        INT 10h     ;execute the configuration

        MOV AH,0Bh  ;function to set background color
        MOV BH,00h  ;specify the display page number (page 0)
        MOV BL,00h  ;specify the background color (black)
        INT 10h     ;execute the configuration

        MOV AH,0Ch  ;function to draw a pixel
        MOV AL,0Fh  ;choose white as the pixel color (white)
        MOV BH,00h  ;specify the display page number (page 0)
        MOV CX,BALL_X ;set the x coordinate
        MOV DX,BALL_Y ;set the y coordinate
        INT 10H     ;execute the configuration
         
        RET

    MAIN ENDP

CODE ENDS
END MAIN