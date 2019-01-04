.MODEL  SMALL
.STACK  100H

STATE_1     EQU 1
STATE_1_LIGHT   EQU 100001B
STATE_2     EQU 2
STATE_2_LIGHT   EQU 100010B
STATE_3     EQU 3
STATE_3_LIGHT   EQU 001100B
STATE_4     EQU 4
STATE_4_LIGHT   EQU 010100B

.DATA
MESG        DB  'TRAFFIC LIGHTS CONTROL'
I8254DD0    DW  280H
I8254DD1    DW  281H
I8254TYPE   DW  283H                                                             

I8255TYPE   DW  28BH
I8255ADDA   DW  288H
I8255ADDB   DW  289H
I8255ADDC   DW  28AH

BUF         DB  4 DUP(0)    ; 数码管显示缓冲
TAB         DB  3FH, 06H, 5BH, 4FH, 66H, 6DH, 7DH, 07H, 7FH, 6FH    ; 数码管段码
BZ          DB  0F1H, 0F2H, 0F4H, 0F8H  ; 数码管位码

STATE       DB  0


.CODE
.STARTUP
    MOV     DX, OFFSET MESG ; 显示信息
    MOV     AH, 9
    INT     21H

    MOV     DX, I8255TYPE
    MOV     AL, 10001000B
    OUT     DX, AL

    MOV     DX, I8254TYPE
    MOV     AL, 00110110B
    OUT     DX, AL
    MOV     DX, I8254DD0
    MOV     AX, 1000
    OUT     DX, AL
    MOV     AL, AH
    OUT     DX, AL

    MOV     DX, I8254TYPE
    MOV     AL, 01110000B
    OUT     DX, AL
    MOV     DX, I8254DD1
    MOV     AX, 1000
    OUT     DX, AL
    MOV     AL, AH
    OUT     DX, AL

ENTER_STATE_1   PROC    NEAR
    MOV     BX, OFFSET STATE
    MOV     [BX], STATE_1
    MOV     AL, STATE_1_LIGHT
    MOV     DX, I8255ADDB
    OUT     DX, AL
    
