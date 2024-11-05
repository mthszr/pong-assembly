STACK SEGMENT PARA STACK
    DB 64 DUP (' ')
STACK ENDS

DATA SEGMENT PARA 'DATA'

DATA ENDS

CODE SEGMENT PARA 'CODE'

    ASSUME CS:CODE, DS:CODE

    MAIN PROC FAR

        MOV AH,00h ;function to set video mode
        MOV AL,13h ;set the video mode (320x200, 256 colors)
        INT 10h ;execute the configuration

        MOV AH,0Bh ;function to set background color
        MOV BH,00h ;specify the display page number (page 0)
        MOV BL,00h ;specify the background color (black)
        INT 10h ;execute the configuration

        MOV AH,0Ch ;function to draw a pixel
        MOV AL,0Fh ;choose white as the pixel color (white)
        MOV BH,00h ;specify the display page number (page 0)
        MOV CX,0Ah ;set the x coordinate
        MOV DX,0Ah ;set the y coordinate
        INT 10H ;execute the configuration
        
        RET

    MAIN ENDP

CODE ENDS
END MAIN