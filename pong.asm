STACK SEGMENT PARA STACK
    DB 64 DUP (' ') ;define a stack segment with 64 bytes of uninitialized space
STACK ENDS

DATA SEGMENT PARA 'DATA'

    TIME_AUX DB 0 ;define a variable to store the system time

    BALL_X DW 0Ah ;define the x coordinate of the ball
    BALL_Y DW 0Ah ;define the y coordinate of the ball
    BALL_SIZE DW 04h ;define the size of the ball (pixels)

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

        CHECK_TIME:
            MOV AH,2Ch      ;function to get the system time
            INT 21h         ;CH = hour, CL = minute, DH = second, DL = 1/100 second

            CMP DL,TIME_AUX 
            JE CHECK_TIME   ;if the time hasn't changed, keep checking
            
            MOV TIME_AUX,DL ;update the time_aux variable
            INC BALL_X      ;move the ball to the right
            CALL DRAW_BALL  ;if the time has changed, draw the ball

            JMP CHECK_TIME  ;keep checking the time

        RET

    MAIN ENDP

    DRAW_BALL PROC NEAR

        MOV CX,BALL_X ;set the initial x coordinate
        MOV DX,BALL_Y ;set the initial y coordinate

        DRAW_BALL_HORIZONTAL:  
            MOV AH,0Ch  ;function to draw a pixel
            MOV AL,0Fh  ;choose white as the pixel color (white)
            MOV BH,00h  ;specify the display page number (page 0)
            INT 10H     ;execute the configuration

            INC CX      ;move to the next pixel (CX = CX + 1)
            MOV AX,CX   ;CX - BALL_X > BALL_SIZE ? nex line : next pixel
            SUB AX,BALL_X
            CMP AX,BALL_SIZE
            JNG DRAW_BALL_HORIZONTAL

            MOV CX,BALL_X ;reset the x coordinate
            INC DX      ;move to the next line (DY = DY + 1)

            MOV AX,DX   ;DX - BALL_Y > BALL_SIZE ? end : next line
            SUB AX,BALL_Y
            CMP AX,BALL_SIZE
            JNG DRAW_BALL_HORIZONTAL

        RET
    DRAW_BALL ENDP

CODE ENDS
END MAIN