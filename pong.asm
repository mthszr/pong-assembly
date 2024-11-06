STACK SEGMENT PARA STACK
    DB 64 DUP (' ') ;define a stack segment with 64 bytes of uninitialized space
STACK ENDS

DATA SEGMENT PARA 'DATA'

    WINDOW_WIDTH DW 140h  ;define the width of the window (320 pixels)
    WINDOW_HEIGHT DW 0C8h ;define the height of the window (200 pixels)
    WINDOW_BOUNDS DW 6    ;define the bounds of the window (6 pixels from the edge)

    TIME_AUX DB 0 ;define a variable to store the system time

    BALL_ORIGINAL_X DW 0A0h
    BALL_ORIGINAL_Y DW 64h
    BALL_X DW 0Ah ;define the x coordinate of the ball
    BALL_Y DW 0Ah ;define the y coordinate of the ball
    BALL_SIZE DW 04h ;define the size of the ball (pixels)
    BALL_VELOCITY_X DW 05h ;define the velocity of the ball in the x direction
    BALL_VELOCITY_Y DW 02h ;define the velocity of the ball in the y direction

    ;player paddles
    ;player 1
    PADDLE_LEFT_X DW 0Ah ;define the x coordinate of the left paddle for player 1
    PADDLE_LEFT_Y DW 55h ;define the y coordinate of the left paddle for player 1

    PADDLE_RIGHT_X DW 130h ;define the x coordinate of the left paddle for player 2
    PADDLE_RIGHT_Y DW 55h ;define the y coordinate of the left paddle for player 2
    
    PADDLE_WIDTH DW 06h ;define the width of the paddles (pixels)
    PADDLE_HEIGHT DW 1Fh ;define the height of the paddles (pixels)
    PADDLE_VELOCITY DW 05h ;define the velocity of the paddles

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

        CALL CLEAR_SCREEN  ;clear the screen

        CHECK_TIME:
            MOV AH,2Ch        ;function to get the system time
            INT 21h           ;CH = hour, CL = minute, DH = second, DL = 1/100 second

            CMP DL,TIME_AUX 
            JE CHECK_TIME     ;if the time hasn't changed, keep checking
            
            MOV TIME_AUX,DL   ;update the time_aux variable
            
            CALL CLEAR_SCREEN ;clear the screen
            CALL MOVE_BALL    ;move the ball based on the current time
            CALL DRAW_BALL    ;if the time has changed, draw the ball

            CALL MOVE_PADDLES
            CALL DRAW_PADDLES ;draw the player paddles

            JMP CHECK_TIME    ;keep checking the time

        RET

    MAIN ENDP

    MOVE_BALL PROC NEAR

        MOV AX,BALL_VELOCITY_X 
        ADD BALL_X,AX           ;update the x coordinate of the ball

        MOV AX,WINDOW_BOUNDS
        CMP BALL_X,AX           ;check if the ball has reached the left edge of the window
        JL RESET_POSITION       ;if so, reset the ball position

        MOV AX,WINDOW_WIDTH 
        SUB AX,BALL_SIZE
        SUB AX,WINDOW_BOUNDS
        CMP BALL_X,AX           ;check if the ball has reached the right edge of the window
        JG RESET_POSITION       ;if so, reset the ball position

        MOV AX,BALL_VELOCITY_Y
        ADD BALL_Y,AX           ;update the y coordinate of the ball

        MOV AX,WINDOW_BOUNDS
        CMP BALL_Y,AX           ;check if the ball has reached the top edge of the window
        JL REVERSE_Y            ;if so, reverse the y velocity

        MOV AX,WINDOW_HEIGHT 
        SUB AX,BALL_SIZE
        SUB AX,WINDOW_BOUNDS
        CMP BALL_Y,AX           ;check if the ball has reached the bottom edge of the window
        JG REVERSE_Y            ;if so, reverse the y velocity

        RET

        RESET_POSITION:
            CALL RESET_BALL_POSITION
            RET

        REVERSE_Y:
            NEG BALL_VELOCITY_Y ;reverse the Y velocity
            RET

    MOVE_BALL ENDP

    MOVE_PADDLES PROC NEAR

        MOV AH,01h  ;function to check for a key press
        INT 16h     ;execute the configuration
        JZ CHECK_RIGHT_PADDLE_MOVEMENT ;if no key is pressed, check the right paddle movement

        MOV AH,00h  ;function to get the scan code of the key pressed
        INT 16h     ;execute the configuration
        
        ;AL contains the ASCII code of the key pressed
        CMP AL,77h  ;check if the key pressed is 'w' (move the left paddle up)
        JE MOVE_LEFT_PADDLE_UP
        CMP AL,57h  ;check if the key pressed is 'W' (move the left paddle up)
        JE MOVE_LEFT_PADDLE_UP

        CMP AL,73h  ;check if the key pressed is 's' (move the left paddle down)
        JE MOVE_LEFT_PADDLE_DOWN
        CMP AL,53h  ;check if the key pressed is 'S' (move the left paddle down)
        JE MOVE_LEFT_PADDLE_DOWN
        JMP CHECK_RIGHT_PADDLE_MOVEMENT ;if the key pressed is not 'w' or 's', check the right paddle movement

        MOVE_LEFT_PADDLE_UP:
            MOV AX, PADDLE_VELOCITY
            SUB PADDLE_LEFT_Y,AX ;move the left paddle up

            MOV AX,WINDOW_BOUNDS
            CMP PADDLE_LEFT_Y, AX ;check if the paddle has reached the top edge of the window
            JL FIX_PADDLE_LEFT_TOP_POSITION ;if so, fix the paddle position
            JMP CHECK_RIGHT_PADDLE_MOVEMENT 

            FIX_PADDLE_LEFT_TOP_POSITION:
                MOV PADDLE_LEFT_Y,AX ;set the paddle position to the top edge of the window
                JMP CHECK_RIGHT_PADDLE_MOVEMENT

        MOVE_LEFT_PADDLE_DOWN:
            MOV AX, PADDLE_VELOCITY
            ADD PADDLE_LEFT_Y,AX ;move the left paddle down

            MOV AX,WINDOW_HEIGHT
            SUB AX,WINDOW_BOUNDS
            SUB AX,PADDLE_HEIGHT
            CMP PADDLE_LEFT_Y,AX ;check if the paddle has reached the bottom edge of the window
            JG FIX_PADDLE_LEFT_BOTTOM_POSITION ;if so, fix the paddle position
            JMP CHECK_RIGHT_PADDLE_MOVEMENT 

            FIX_PADDLE_LEFT_BOTTOM_POSITION:
                MOV PADDLE_LEFT_Y,AX ;set the paddle position to the bottom edge of the window
                JMP CHECK_RIGHT_PADDLE_MOVEMENT

        CHECK_RIGHT_PADDLE_MOVEMENT:
        RET
    MOVE_PADDLES ENDP

    RESET_BALL_POSITION PROC NEAR

        MOV AX,BALL_ORIGINAL_X
        MOV BALL_X,AX ;reset the x coordinate of the ball

        MOV AX,BALL_ORIGINAL_Y
        MOV BALL_Y,AX ;reset the y coordinate of the ball

        RET
    RESET_BALL_POSITION ENDP    

    CLEAR_SCREEN PROC NEAR

        MOV AH,00h  ;function to set video mode
        MOV AL,13h  ;set the video mode (320x200, 256 colors)
        INT 10h     ;execute the configuration
            
        MOV AH,0Bh  ;function to set background color
        MOV BH,00h  ;specify the display page number (page 0)
        MOV BL,00h  ;specify the background color (black)
        INT 10h     ;execute the configuration

        RET
    CLEAR_SCREEN ENDP

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
            INC DX        ;move to the next line (DY = DY + 1)

            MOV AX,DX     ;DX - BALL_Y > BALL_SIZE ? end : next line
            SUB AX,BALL_Y
            CMP AX,BALL_SIZE
            JNG DRAW_BALL_HORIZONTAL

        RET
    DRAW_BALL ENDP

    DRAW_PADDLES PROC NEAR

        MOV CX,PADDLE_LEFT_X 
        MOV DX,PADDLE_LEFT_Y

        DRAW_PADDLE_LEFT_HORIZONTAL:
            MOV AH,0Ch  ;function to draw a pixel
            MOV AL,0Fh  ;choose white as the pixel color
            MOV BH,00h  ;specify the display page number (page 0)
            INT 10H     ;execute the configuration

            INC CX      ;move to the next pixel
            MOV AX,CX   ;CX - PADDLE_LEFT_X > PADDLE_WIDTH ? nex line : next pixel
            SUB AX,PADDLE_LEFT_X
            CMP AX,PADDLE_WIDTH
            JNG DRAW_PADDLE_LEFT_HORIZONTAL

            MOV CX,PADDLE_LEFT_X ;reset the x coordinate
            INC DX               ;move to the next line

            MOV AX,DX   ;DX - PADDLE_LEFT-_Y > PADDLE_HEIGHT ? end : next line
            SUB AX,PADDLE_LEFT_Y
            CMP AX,PADDLE_HEIGHT
            JNG DRAW_PADDLE_LEFT_HORIZONTAL

        MOV CX,PADDLE_RIGHT_X 
        MOV DX,PADDLE_RIGHT_Y

        DRAW_PADDLE_RIGHT_HORIZONTAL:
            MOV AH,0Ch  ;function to draw a pixel
            MOV AL,0Fh  ;choose white as the pixel color
            MOV BH,00h  ;specify the display page number (page 0)
            INT 10H     ;execute the configuration

            INC CX      ;move to the next pixel
            MOV AX,CX   ;CX - PADDLE_LEFT_X > PADDLE_WIDTH ? nex line : next pixel
            SUB AX,PADDLE_RIGHT_X
            CMP AX,PADDLE_WIDTH
            JNG DRAW_PADDLE_RIGHT_HORIZONTAL

            MOV CX,PADDLE_RIGHT_X ;reset the x coordinate
            INC DX               ;move to the next line

            MOV AX,DX   ;DX - PADDLE_LEFT-_Y > PADDLE_HEIGHT ? end : next line
            SUB AX,PADDLE_RIGHT_Y
            CMP AX,PADDLE_HEIGHT
            JNG DRAW_PADDLE_RIGHT_HORIZONTAL
        RET
    DRAW_PADDLES ENDP

CODE ENDS
END MAIN