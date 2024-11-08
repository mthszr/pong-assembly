STACK SEGMENT PARA STACK
    DB 64 DUP (' ') ;define a stack segment with 64 bytes of uninitialized space
STACK ENDS

DATA SEGMENT PARA 'DATA'

    ;window dimensions
    WINDOW_WIDTH DW 140h   ;define the width of the window (320 pixels)
    WINDOW_HEIGHT DW 0C8h  ;define the height of the window (200 pixels)
    WINDOW_BOUNDS DW 6     ;define the bounds of the window (6 pixels from the edge)

    ;game state variables
    TIME_AUX DB 0          ;define a variable to store the system time
    GAME_ACTIVE DB 1       ;define a flag to indicate if the game is active
    EXITING_GAME DB 0      ;define a flag to indicate if the game is exiting
    WINNER_INDEX DB 0      ;define a variable to store the index of the winner 
    CURRENT_SCENE DB 0     ;define a variable to store the current scene (1 = game, 0 = main menu)

    ;user interface text
    TEXT_PLAYER_ONE_SCORE DB '0','$' 
    TEXT_PLAYER_TWO_SCORE DB '0','$'
    TEXT_GAME_OVER DB 'GAME OVER','$'
    TEXT_GAME_WINNER DB 'Player 0 wins!','$'
    TEXT_PLAY_AGAIN DB 'Press R to play again','$'
    TEXT_MAIN_MENU DB 'Press E to exit to the menu','$'
    TEXT_MENU_TITLE DB 'PONG','$'
    TEXT_MENU_SINGLEPLAYER DB 'SINGLEPLAYER - S KEY','$'
    TEXT_MENU_MULTIPLAYER DB 'MULTIPLAYER - M KEY','$'
    TEXT_MENU_EXIT DB 'EXIT GAME - E KEY','$'
    
    ;ball
    BALL_ORIGINAL_X DW 0A0h
    BALL_ORIGINAL_Y DW 64h
    BALL_X DW 0Ah          ;define the x coordinate of the ball
    BALL_Y DW 0Ah          ;define the y coordinate of the ball
    BALL_SIZE DW 04h       ;define the size of the ball (pixels)
    BALL_VELOCITY_X DW 05h ;define the velocity of the ball in the x direction
    BALL_VELOCITY_Y DW 02h ;define the velocity of the ball in the y direction

    ;players/paddles
    ;left paddle/player 1
    PADDLE_LEFT_X DW 0Ah   ;define the x coordinate of the left paddle for player 1
    PADDLE_LEFT_Y DW 55h   ;define the y coordinate of the left paddle for player 1
    PLAYER_ONE_POINTS DB 0;define the points of player 1
    
    ;right paddle/player 2
    PADDLE_RIGHT_X DW 130h ;define the x coordinate of the left paddle for player 2
    PADDLE_RIGHT_Y DW 55h  ;define the y coordinate of the left paddle for player 2
    PLAYER_TWO_POINTS DB 0;define the points of player 2

    ;common players/paddle attributes
    PADDLE_WIDTH DW 06h    ;define the width of the paddles (pixels)
    PADDLE_HEIGHT DW 1Fh   ;define the height of the paddles (pixels)
    PADDLE_VELOCITY DW 05h ;define the velocity of the paddles
    WIN_POINTS DW 05h      ;define the winning score

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

            CMP EXITING_GAME,01h ;check if the game is exiting
            JE START_EXIT_GAME   ;if so, exit the game

            CMP CURRENT_SCENE,00h ;check the current scene
            JE SHOW_MAIN_MENU     ;if the current scene is the main menu, draw the main menu
            
            CMP GAME_ACTIVE,00h ;check if the game is active   
            JE SHOW_GAME_OVER_MENU ;if not, show the game over menu

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

            CALL DRAW_UI      ;draw the user interface

            JMP CHECK_TIME    ;check the time again

            SHOW_GAME_OVER_MENU:
                CALL DRAW_GAME_OVER_MENU ;draw the game over menu
                JMP CHECK_TIME
            
            SHOW_MAIN_MENU:
                CALL DRAW_MAIN_MENU ;draw the main menu
                JMP CHECK_TIME

            START_EXIT_GAME:
                CALL CONCLUDE_EXIT_GAME ;conclude the game and exit
        
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

            CALL UPDATE_PLAYER_ONE_SCORE
            
            CMP PLAYER_ONE_POINTS,01h ;check if player one has reached the winning score
            JGE GAME_OVER             ;if so, the game is over

            RET

        PLAYER_TWO_SCORES:
            INC PLAYER_TWO_POINTS ;increment the points of player two
            CALL RESET_POSITION   ;reset the ball position to the center of the window
            
            CALL UPDATE_PLAYER_TWO_SCORE

            CMP PLAYER_TWO_POINTS,05h ;check if player one has reached the winning score  
            JGE GAME_OVER             ;if so, the game is over

            RET

        RESET_POSITION: ;reset the ball position to the center of the window
            CALL RESET_BALL_POSITION
            RET

        GAME_OVER:

            ;determine the winner
            CMP PLAYER_ONE_POINTS,00h
            JNL WINNER_IS_PLAYER_ONE
            JMP WINNER_IS_PLAYER_TWO

            WINNER_IS_PLAYER_ONE:
                MOV WINNER_INDEX,00h ;set the winner index to player one
                JMP CONTINUE_GAME_OVER
            WINNER_IS_PLAYER_TWO:
                MOV WINNER_INDEX,02h ;set the winner index to player two
                JMP CONTINUE_GAME_OVER

            CONTINUE_GAME_OVER:
                MOV PLAYER_ONE_POINTS,00h ;reset the points of player one
                MOV PLAYER_TWO_POINTS,00h ;reset the points of player two
                CALL UPDATE_PLAYER_ONE_SCORE
                CALL UPDATE_PLAYER_TWO_SCORE
                MOV GAME_ACTIVE,00h       ;set the game flag to inactive
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

    DRAW_UI PROC NEAR

        ;player 1 points
        MOV AH,02h  ;function to set the cursor position
        MOV BH,00h  ;specify the display page number (page 0)
        MOV DH,04h  ;set the row position (4)
        MOV DL,06h  ;set the column position (6)
        INT 10h     ;execute the configuration

        MOV AH,09h  ;function to display a string
        LEA DX,TEXT_PLAYER_ONE_SCORE ;load the address of the string
        INT 21h     ;execute the configuration

        ;player 2 points
        MOV AH,02h  ;function to set the cursor position
        MOV BH,00h  ;specify the display page number (page 0)
        MOV DH,04h  ;set the row position (4)
        MOV DL,1Fh  ;set the column position (6)
        INT 10h     ;execute the configuration

        MOV AH,09h  ;function to display a string
        LEA DX,TEXT_PLAYER_TWO_SCORE ;load the address of the string
        INT 21h     ;execute the configuration

        RET

    DRAW_UI ENDP

    UPDATE_PLAYER_ONE_SCORE PROC NEAR

        XOR AX,AX 
        MOV AL,PLAYER_ONE_POINTS 

        ;convert the ascii character to the corresponding number
        ADD AL,30h
        MOV [TEXT_PLAYER_ONE_SCORE],AL

        RET

    UPDATE_PLAYER_ONE_SCORE ENDP

    UPDATE_PLAYER_TWO_SCORE PROC NEAR

        XOR AX,AX 
        MOV AL,PLAYER_TWO_POINTS 

        ;convert the ascii character to the corresponding number
        ADD AL,30h
        MOV [TEXT_PLAYER_TWO_SCORE],AL

        RET

    UPDATE_PLAYER_TWO_SCORE ENDP

    DRAW_GAME_OVER_MENU PROC NEAR

        CALL CLEAR_SCREEN
        
       ;show the game over message
        MOV AH,02h  ;function to set the cursor position
        MOV BH,00h  ;specify the display page number (page 0)
        MOV DH,04h  ;set the row position 
        MOV DL,04h  ;set the column position
        INT 10h     ;execute the configuration

        MOV AH,09h  ;function to display a string
        LEA DX,TEXT_GAME_OVER ;load the address of the string
        INT 21h     ;execute the configuration

        ;shows the winner message
        MOV AH,02h  ;function to set the cursor position
        MOV BH,00h  ;specify the display page number (page 0)
        MOV DH,06h  ;set the row position 
        MOV DL,04h  ;set the column position
        INT 10h     ;execute the configuration

        CALL UPDATE_WINNER_TEXT

        MOV AH,09h  ;function to display a string
        LEA DX,TEXT_GAME_WINNER ;load the address of the string
        INT 21h     ;execute the configuration

        ;show the play again message
        MOV AH,02h  ;function to set the cursor position
        MOV BH,00h  ;specify the display page number (page 0)
        MOV DH,08h  ;set the row position 
        MOV DL,04h   ;set the column position
        INT 10h     ;execute the configuration

        MOV AH,09h  ;function to display a string
        LEA DX,TEXT_PLAY_AGAIN ;load the address of the string
        INT 21h     ;execute the configuration

        ;show the main menu message
        MOV AH,02h  ;function to set the cursor position
        MOV BH,00h  ;specify the display page number (page 0)
        MOV DH,0Ah  ;set the row position 
        MOV DL,04h   ;set the column position
        INT 10h     ;execute the configuration

        MOV AH,09h  ;function to display a string
        LEA DX,TEXT_MAIN_MENU ;load the address of the string
        INT 21h     ;execute the configuration

        ;wait for a key press to restart the game
        MOV AH,00h  ;function to check for a key press
        INT 16h     ;execute the configuration

        CMP AL,'R'  ;check if the key pressed is 'R' (restart the game)
        JE RESTART_GAME
        CMP AL,'r'  ;check if the key pressed is 'r' (restart the game)
        JE RESTART_GAME
        CMP AL,'E'  ;check if the key pressed is 'E' (exit to the main menu)
        JE EXIT_TO_MAIN_MENU
        CMP AL,'e'  ;check if the key pressed is 'e' (exit to the main menu)
        JE EXIT_TO_MAIN_MENU

        RET

        RESTART_GAME:
            MOV GAME_ACTIVE,01h ;set the game flag to active
            CALL CLEAR_SCREEN   ;clear the screen
            CALL RESET_POSITION ;reset the ball position
            RET

        EXIT_TO_MAIN_MENU:
            MOV GAME_ACTIVE,00h ;set the game flag to inactive
            MOV CURRENT_SCENE,00h ;set the current scene to the main menu
            RET
        

        RET

    DRAW_GAME_OVER_MENU ENDP

    DRAW_MAIN_MENU PROC NEAR

        CALL CLEAR_SCREEN

        ;show the menu title
        MOV AH,02h  ;function to set the cursor position
        MOV BH,00h  ;specify the display page number (page 0)
        MOV DH,04h  ;set the row position 
        MOV DL,04h  ;set the column position
        INT 10h     ;execute the configuration

        MOV AH,09h  ;function to display a string
        LEA DX,TEXT_MENU_TITLE ;load the address of the string
        INT 21h     ;execute the configuration

        ;show the singleplayer option
        MOV AH,02h  ;function to set the cursor position
        MOV BH,00h  ;specify the display page number (page 0)
        MOV DH,06h  ;set the row position 
        MOV DL,04h  ;set the column position
        INT 10h     ;execute the configuration

        MOV AH,09h  ;function to display a string
        LEA DX,TEXT_MENU_SINGLEPLAYER ;load the address of the string
        INT 21h     ;execute the configuration

        ;show the multiplayer option
        MOV AH,02h  ;function to set the cursor position
        MOV BH,00h  ;specify the display page number (page 0)
        MOV DH,08h  ;set the row position 
        MOV DL,04h  ;set the column position
        INT 10h     ;execute the configuration

        MOV AH,09h  ;function to display a string
        LEA DX,TEXT_MENU_MULTIPLAYER ;load the address of the string
        INT 21h     ;execute the configuration

        ;show the exit option
        MOV AH,02h  ;function to set the cursor position
        MOV BH,00h  ;specify the display page number (page 0)
        MOV DH,0Ah  ;set the row position 
        MOV DL,04h  ;set the column position
        INT 10h     ;execute the configuration

        MOV AH,09h  ;function to display a string
        LEA DX,TEXT_MENU_EXIT ;load the address of the string
        INT 21h     ;execute the configuration

        MAIN_MENU_WAIT_FOR_KEY_PRESS:
            ;wait for a key press 
            MOV AH,00h  ;function to check for a key press
            INT 16h     ;execute the configuration

            ;check the key pressed
            CMP AL,'S'  ;check if the key pressed is 'S' (singleplayer)
            JE START_SINGLEPLAYER
            CMP AL,'s'  ;check if the key pressed is 's' (singleplayer)
            JE START_SINGLEPLAYER
            CMP AL,'M'  ;check if the key pressed is 'M' (multiplayer)
            JE START_MULTIPLAYER
            CMP AL,'m'  ;check if the key pressed is 'm' (multiplayer)
            JE START_MULTIPLAYER
            CMP AL,'E'  ;check if the key pressed is 'E' (exit)
            JE EXIT_GAME
            CMP AL,'e'  ;check if the key pressed is 'e' (exit)
            JE EXIT_GAME
            JMP MAIN_MENU_WAIT_FOR_KEY_PRESS

        START_SINGLEPLAYER:
            MOV CURRENT_SCENE,01h ;set the current scene to the game
            MOV GAME_ACTIVE,01h   ;set the game flag to active
            RET
        
        START_MULTIPLAYER:
            JMP MAIN_MENU_WAIT_FOR_KEY_PRESS

        EXIT_GAME:
            MOV EXITING_GAME,01h ;set the flag to exit the game
            RET
        RET
    
    DRAW_MAIN_MENU ENDP

    UPDATE_WINNER_TEXT PROC NEAR

        MOV AL,WINNER_INDEX
        ADD AL,30h
        MOV [TEXT_GAME_WINNER + 7],AL ;update the winner index in the string

        RET

    UPDATE_WINNER_TEXT ENDP

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

    CONCLUDE_EXIT_GAME PROC NEAR ;goees back to text mode

        MOV AH,00h  ;function to set video mode
        MOV AL,02h  ;set the video mode (text mode)
        INT 10h     ;execute the configuration

        MOV AH,4Ch  ;function to exit the program
        INT 21h     ;execute the configuration

        RET

    CONCLUDE_EXIT_GAME ENDP

CODE ENDS
END MAIN