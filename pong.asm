STACK SEGMENT PARA STACK
    DB 64 DUP (' ') ;define a stack segment with 64 bytes of uninitialized space
STACK ENDS

DATA SEGMENT PARA 'DATA'

    ;window dimensions
    WINDOW_WIDTH DW 140h   ;define the width of the window (320 pixels)
    WINDOW_HEIGHT DW 0C8h  ;define the height of the window (200 pixels)
    WINDOW_BOUNDS DW 6     ;define the bounds of the window (6 pixels from the edge)

    TIME_AUX DB 0          ;define a variable to store the system time

    ;ball
    BALL_ORIGINAL_X DW 0A0h
    BALL_ORIGINAL_Y DW 64h
    BALL_X DW 0Ah          ;define the x coordinate of the ball
    BALL_Y DW 0Ah          ;define the y coordinate of the ball
    BALL_SIZE DW 04h       ;define the size of the ball (pixels)
    BALL_VELOCITY_X DW 05h ;define the velocity of the ball in the x direction
    BALL_VELOCITY_Y DW 02h ;define the velocity of the ball in the y direction

    ;player paddles
    ;player 1
    PADDLE_LEFT_X DW 0Ah   ;define the x coordinate of the left paddle for player 1
    PADDLE_LEFT_Y DW 55h   ;define the y coordinate of the left paddle for player 1
    PLAYER_ONE_POINTS DB 0;define the points of player 1
    
    ;player 2
    PADDLE_RIGHT_X DW 130h ;define the x coordinate of the left paddle for player 2
    PADDLE_RIGHT_Y DW 55h  ;define the y coordinate of the left paddle for player 2
    PLAYER_TWO_POINTS DB 0;define the points of player 2

    ;common paddle attributes
    PADDLE_WIDTH DW 06h    ;define the width of the paddles (pixels)
    PADDLE_HEIGHT DW 1Fh   ;define the height of the paddles (pixels)
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

        CALL CLEAR_SCREEN           ;clear the screen

        CHECK_TIME:           
            MOV AH,2Ch        ;function to get the system time
            INT 21h           ;CH = hour, CL = minute, DH = second, DL = 1/100 second

            CMP DL,TIME_AUX 
            JE CHECK_TIME     ;if the time hasn't changed, keep checking
            
            ;time has changed at this point

            MOV TIME_AUX,DL   ;if the time has changed, update the auxiliary variable 
            
            CALL CLEAR_SCREEN ;clear the screen
            CALL MOVE_BALL    ;move the ball
            CALL DRAW_BALL    ;and draw the new position

            CALL MOVE_PADDLES ;move the player paddles
            CALL DRAW_PADDLES ;and draw the new positions

            JMP CHECK_TIME    ;check the time again

        RET

    MAIN ENDP

    MOVE_BALL PROC NEAR ;move the ball and check for collisions with the window edges

        ;horizontal movement
        MOV AX,BALL_VELOCITY_X 
        ADD BALL_X,AX           ;update the x coordinate of the ball

        ;horizontal collision detection
        ;BALL_X < 0 + WINDOW_BOUNDS ?
        MOV AX,WINDOW_BOUNDS
        CMP BALL_X,AX           ;check if the ball has reached the left edge of the window
        JL PLAYER_TWO_SCORES    ;if so, player two scores a point

        ;BALL_X > WINDOW_WIDTH - BALL_SIZE - WINDOW_BOUNDS ?
        MOV AX,WINDOW_WIDTH 
        SUB AX,BALL_SIZE
        SUB AX,WINDOW_BOUNDS
        CMP BALL_X,AX           ;check if the ball has reached the right edge of the window
        JG PLAYER_ONE_SCORES    ;if so, player one scores a point
        JMP MOVE_BALL_VERTICAL

        PLAYER_ONE_SCORES:
            INC PLAYER_ONE_POINTS ;increment the points of player one
            CALL RESET_POSITION   ;reset the ball position to the center of the window
            RET

        PLAYER_TWO_SCORES:
            INC PLAYER_TWO_POINTS ;increment the points of player two
            CALL RESET_POSITION   ;reset the ball position to the center of the window
            RET

        RESET_POSITION: ;reset the ball position to the center of the window
            CALL RESET_BALL_POSITION
            RET

        GAME_OVER:
            MOV PLAYER_ONE_POINTS,00h ;reset the points of player one
            MOV PLAYER_TWO_POINTS,00h ;reset the points of player two
            RET

        ;vertical movement
        MOVE_BALL_VERTICAL: 
            MOV AX,BALL_VELOCITY_Y
            ADD BALL_Y,AX           ;update the y coordinate of the ball

        ;vertical collision detection
        ;BALL_Y < 0 + WINDOW_BOUNDS ?
        MOV AX,WINDOW_BOUNDS
        CMP BALL_Y,AX           ;check if the ball has reached the top edge of the window
        JL REVERSE_Y            ;if so, reverse the y velocity

        ;BALL_Y > WINDOW_HEIGHT - BALL_SIZE - WINDOW_BOUNDS ?
        MOV AX,WINDOW_HEIGHT 
        SUB AX,BALL_SIZE
        SUB AX,WINDOW_BOUNDS
        CMP BALL_Y,AX           ;check if the ball has reached the bottom edge of the window
        JG REVERSE_Y            ;if so, reverse the y velocity

        ;collision with the paddles (axis aligned bounding box) 
        ;MAX_X1 > MIN_X2 && MIN_X1 < MAX_X2 && MAX_Y1 > MIN_Y2 && MIN_Y1 < MAX_Y2

        ;right paddle collision

        ;first condition: BALL_X + BALL_SIZE > PADDLE_RIGHT_X
        ;second condition: BALL_X < PADDLE_RIGHT_X + PADDLE_WIDTH
        ;third condition: BALL_Y + BALL_SIZE > PADDLE_RIGHT_Y
        ;fourth condition: BALL_Y < PADDLE_RIGHT_Y + PADDLE_HEIGHT

        MOV AX,BALL_x
        ADD AX,BALL_SIZE
        CMP AX,PADDLE_RIGHT_X
        JNG CHECK_COLLISION_WITH_LEFT_PADDLE

        MOV AX,PADDLE_RIGHT_X
        ADD AX,PADDLE_WIDTH
        CMP BALL_X,AX
        JNL CHECK_COLLISION_WITH_LEFT_PADDLE

        MOV AX,BALL_Y
        ADD AX,BALL_SIZE
        CMP AX,PADDLE_RIGHT_Y
        JNG CHECK_COLLISION_WITH_LEFT_PADDLE

        MOV AX,PADDLE_RIGHT_Y
        ADD AX,PADDLE_HEIGHT
        CMP BALL_Y,AX
        JNL CHECK_COLLISION_WITH_LEFT_PADDLE

        ;if all conditions above are met, a collision with the right paddle has occurred
        JMP REVERSE_X ;and the ball should reverse its x velocity             

        ;left paddle collision

        ;first condition: BALL_X + BALL_SIZE > PADDLE_LEFT_X
        ;second condition: BALL_X < PADDLE_LEFT_X + PADDLE_WIDTH
        ;third condition: BALL_Y + BALL_SIZE > PADDLE_LEFT_Y
        ;fourth condition: BALL_Y < PADDLE_LEFT_Y + PADDLE_HEIGHT

        CHECK_COLLISION_WITH_LEFT_PADDLE:

            MOV AX,BALL_x
            ADD AX,BALL_SIZE
            CMP AX,PADDLE_LEFT_X
            JNG EXIT_COLLISION

            MOV AX,PADDLE_LEFT_X
            ADD AX,PADDLE_WIDTH
            CMP BALL_X,AX
            JNL EXIT_COLLISION

            MOV AX,BALL_Y
            ADD AX,BALL_SIZE
            CMP AX,PADDLE_LEFT_Y
            JNG EXIT_COLLISION

            MOV AX,PADDLE_LEFT_Y
            ADD AX,PADDLE_HEIGHT
            CMP BALL_Y,AX
            JNL EXIT_COLLISION

            ;if all conditions above are met, a collision with the left paddle has occurred
            JMP REVERSE_X ;and the ball should reverse its x velocity

            REVERSE_Y:
                NEG BALL_VELOCITY_Y ;reverse the Y velocity
                RET
            
            REVERSE_X:
                NEG BALL_VELOCITY_X ;reverse the X velocity
                RET ;only one collision can occur at a time
            
            EXIT_COLLISION:
                RET

    MOVE_BALL ENDP

    MOVE_PADDLES PROC NEAR ;move the player paddles based on the key pressed

        ;left paddle movement

        MOV AH,01h                     ;function to check for a key press
        INT 16h                        ;execute the configuration
        JZ CHECK_RIGHT_PADDLE_MOVEMENT ;if no key is pressed, check the right paddle movement

        MOV AH,00h                     ;function to get the scan code of the key pressed
        INT 16h                        ;execute the configuration
        
        ;AL contains the ASCII code of the key pressed
        CMP AL,77h                     ;check if the key pressed is 'w' (move the left paddle up)
        JE MOVE_LEFT_PADDLE_UP
        CMP AL,57h                     ;check if the key pressed is 'W' (move the left paddle up)
        JE MOVE_LEFT_PADDLE_UP

        CMP AL,73h                     ;check if the key pressed is 's' (move the left paddle down)
        JE MOVE_LEFT_PADDLE_DOWN
        CMP AL,53h                     ;check if the key pressed is 'S' (move the left paddle down)
        JE MOVE_LEFT_PADDLE_DOWN
        JMP CHECK_RIGHT_PADDLE_MOVEMENT;if the key pressed is not 'W' or 'S', check the right paddle movement

        MOVE_LEFT_PADDLE_UP:
            MOV AX, PADDLE_VELOCITY
            SUB PADDLE_LEFT_Y,AX            ;move the left paddle up

            MOV AX,WINDOW_BOUNDS
            CMP PADDLE_LEFT_Y, AX           ;check if the paddle has reached the top edge of the window
            JL FIX_PADDLE_LEFT_TOP_POSITION ;if so, fix the paddle position
            JMP CHECK_RIGHT_PADDLE_MOVEMENT 

            FIX_PADDLE_LEFT_TOP_POSITION:
                MOV PADDLE_LEFT_Y,AX        ;set the paddle position to the top edge of the window
                JMP CHECK_RIGHT_PADDLE_MOVEMENT

        MOVE_LEFT_PADDLE_DOWN:
            MOV AX, PADDLE_VELOCITY
            ADD PADDLE_LEFT_Y,AX               ;move the left paddle down

            MOV AX,WINDOW_HEIGHT
            SUB AX,WINDOW_BOUNDS
            SUB AX,PADDLE_HEIGHT
            CMP PADDLE_LEFT_Y,AX               ;check if the paddle has reached the bottom edge of the window
            JG FIX_PADDLE_LEFT_BOTTOM_POSITION ;if so, fix the paddle position
            JMP CHECK_RIGHT_PADDLE_MOVEMENT 

            FIX_PADDLE_LEFT_BOTTOM_POSITION:
                MOV PADDLE_LEFT_Y,AX           ;set the paddle position to the bottom edge of the window
                JMP CHECK_RIGHT_PADDLE_MOVEMENT

        ;right paddle movement

        CHECK_RIGHT_PADDLE_MOVEMENT:

            ;AL contains the ASCII code of the key pressed
            CMP AL,6Fh               ;check if the key pressed is 'o' (move the right paddle up)
            JE MOVE_RIGHT_PADDLE_UP
            CMP AL,4Fh               ;check if the key pressed is 'O' (move the right paddle up)
            JE MOVE_RIGHT_PADDLE_UP

            CMP AL,6Ch               ;check if the key pressed is 'l' (move the right paddle down)
            JE MOVE_RIGHT_PADDLE_DOWN
            CMP AL,4Ch               ;check if the key pressed is 'L' (move the right paddle down)
            JE MOVE_RIGHT_PADDLE_DOWN
            JMP EXIT_PADDLE_MOVEMENT ;if the key pressed is not 'O' or 'L', check the right paddle movement

            MOVE_RIGHT_PADDLE_UP:
                MOV AX, PADDLE_VELOCITY
                SUB PADDLE_RIGHT_Y,AX           ;move the right paddle up

                MOV AX,WINDOW_BOUNDS
                CMP PADDLE_RIGHT_Y, AX           ;check if the paddle has reached the top edge of the window
                JL FIX_PADDLE_RIGHT_TOP_POSITION ;if so, fix the paddle position
                JMP EXIT_PADDLE_MOVEMENT

                FIX_PADDLE_RIGHT_TOP_POSITION:
                    MOV PADDLE_RIGHT_Y,AX        ;set the paddle position to the top edge of the window
                    JMP EXIT_PADDLE_MOVEMENT

            MOVE_RIGHT_PADDLE_DOWN: 
                MOV AX, PADDLE_VELOCITY
                ADD PADDLE_RIGHT_Y,AX               ;move the right paddle down

                MOV AX,WINDOW_HEIGHT
                SUB AX,WINDOW_BOUNDS
                SUB AX,PADDLE_HEIGHT
                CMP PADDLE_RIGHT_Y,AX               ;check if the paddle has reached the bottom edge of the window
                JG FIX_PADDLE_RIGHT_BOTTOM_POSITION ;if so, fix the paddle position
                JMP EXIT_PADDLE_MOVEMENT

                FIX_PADDLE_RIGHT_BOTTOM_POSITION:
                    MOV PADDLE_RIGHT_Y,AX           ;set the paddle position to the bottom edge of the window
                    JMP EXIT_PADDLE_MOVEMENT

            EXIT_PADDLE_MOVEMENT:
                
        RET
    MOVE_PADDLES ENDP

    RESET_BALL_POSITION PROC NEAR ;reset the position of the ball to the center of the window

        MOV AX,BALL_ORIGINAL_X
        MOV BALL_X,AX ;reset the x coordinate of the ball

        MOV AX,BALL_ORIGINAL_Y
        MOV BALL_Y,AX ;reset the y coordinate of the ball

        RET
    RESET_BALL_POSITION ENDP    

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
            INC DX                ;move to the next line

            MOV AX,DX   ;DX - PADDLE_LEFT-_Y > PADDLE_HEIGHT ? end : next line
            SUB AX,PADDLE_RIGHT_Y
            CMP AX,PADDLE_HEIGHT
            JNG DRAW_PADDLE_RIGHT_HORIZONTAL

        RET
    DRAW_PADDLES ENDP
    
    CLEAR_SCREEN PROC NEAR ;clear the screen by restarting the video mode

        MOV AH,00h  ;function to set video mode
        MOV AL,13h  ;set the video mode (320x200, 256 colors)
        INT 10h     ;execute the configuration
            
        MOV AH,0Bh  ;function to set background color
        MOV BH,00h  ;specify the display page number (page 0)
        MOV BL,00h  ;specify the background color (black)
        INT 10h     ;execute the configuration

        RET

    CLEAR_SCREEN ENDP

CODE ENDS
END MAIN