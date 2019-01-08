
STATE_1     EQU 1
STATE_1_LIGHT   EQU 10000001B
STATE_2     EQU 2
STATE_2_LIGHT   EQU 10000010B
STATE_3     EQU 3
STATE_3_LIGHT   EQU 00100100B
STATE_4     EQU 4
STATE_4_LIGHT   EQU 01000100B

TIME		EQU	1000

DATA	SEGMENT
DT	DB	100
ORG	DATA
MESG        DB  'TRAFFIC LIGHTS CONTROL$'
I8254DD0    DW  280H
I8254DD1    DW  281H
I8254TYPE   DW  283H                                                             

I8255TYPE   DW  28BH
I8255ADDA   DW  288H
I8255ADDB   DW  289H
I8255ADDC   DW  28AH

BUF         DB  4 DUP(0)    ; 数码管显示缓冲
TAB         DB  3FH, 06H, 5BH, 4FH, 66H, 6DH, 7DH, 07H, 7FH, 6FH    ; 数码管段码
BZ          DB  0F1H, 0F2H, 0F4H, 0F8H  ; 数码管位码, 对应S0-S3

STATE       DB  0
COUNT       DW  0
DATA	ENDS

STACK	SEGMENT
ST	DB	100	DUP(?)
STACK ENDS

CODE	SEGMENT
START:
    ASSUME 	CS:CODE,DS:DATA,SS:STACK
    MOV	AX, DATA
    MOV	DS, AX
    MOV	ES, AX
    MOV	AX, STACK
    MOV	SS, AX

    

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
    MOV     AX, TIME
    OUT     DX, AL
    MOV     AL, AH
    OUT     DX, AL

    MOV     DX, I8254TYPE
    MOV     AL, 01110000B
    OUT     DX, AL
    MOV     DX, I8254DD1
    MOV     AX, TIME
    OUT     DX, AL
    MOV     AL, AH
    OUT     DX, AL

    CALL    ENTER_STATE_1   ; ENTER STATE 1
WAIT_FOR_COUNT:             ; 等待1s到来
    MOV     DX, I8255ADDC
    IN      AL, DX
    TEST    AL, 10H
    
    JZ      NEXT   ; 1s COUNT NOT COME
    
    MOV     DX, I8254DD1 ; 1s COUNT COME   
    MOV     AX, TIME
    OUT     DX, AL
    MOV     AL, AH
    OUT     DX, AL

    MOV     BX, OFFSET COUNT 
    MOV     AX, [BX]
    DEC     AX
    CMP     AX, 0
    JE      COUNT_TO_0      ; COUNT TO 0, START CONVERSION

COUNT_ABOVE_0:
    MOV     [BX], AX
    CALL    BUF_MINUS_1     ; 数码管缓冲区-1
    JMP     NEXT

AFTER_CONVERSION:           ; AFTER CONVERSION
    JMP     NEXT

NEXT:
    CALL    DISPLAY
    ; RESET COUNTER 1
;    MOV     DX, I8254DD1    
;    MOV     AX, TIME
;    OUT     DX, AL
;    MOV     AL, AH
;    OUT     DX, AL

    JMP     WAIT_FOR_COUNT

COUNT_TO_0:                 ; 倒计时到0，判断状态转换
    MOV     BX, OFFSET STATE
    MOV     AL, [BX]
    CMP     AL, 1
    JE      CONVERT_TO_STATE_2
    CMP     AL, 2
    JE      CONVERT_TO_STATE_3
    CMP     AL, 3
    JE      CONVERT_TO_STATE_4
    CMP     AL, 4
    JE      CONVERT_TO_STATE_1

CONVERT_TO_STATE_2:
    CALL    ENTER_STATE_2
    JMP     AFTER_CONVERSION

CONVERT_TO_STATE_3:
    CALL    ENTER_STATE_3
    JMP     AFTER_CONVERSION

CONVERT_TO_STATE_4:
    CALL    ENTER_STATE_4
    JMP     AFTER_CONVERSION

CONVERT_TO_STATE_1:
    CALL    ENTER_STATE_1
    JMP     AFTER_CONVERSION


; 将数码管显示缓冲BUF的数值-1
BUF_MINUS_1     PROC    NEAR
    PUSH    AX
    PUSH    CX
    PUSH    SI

    MOV     SI, OFFSET BUF
    MOV     CX, 4
MINUS_L1:
    MOV     AL, [SI]
    DEC     AL
    CMP     AL, 0
    JGE     NOT_BELOW_0      
    ; AL < 0 AFTER DEC AL
    MOV     AL, 9
    MOV     [SI], AL
    INC     SI
    LOOP    MINUS_L1
    

NOT_BELOW_0:
    MOV     [SI], AL

    POP     SI
    POP     CX
    POP     AX
    RET
BUF_MINUS_1     ENDP
    

; 状态转换
; 更新STATE
; 将6个二极管更新成新状态
; 设置新的倒计时COUNT
; 更新数码管显示缓存BUF并调用DISPLAY更新数码管
ENTER_STATE_1   PROC    NEAR
    PUSH    AX
    PUSH    BX
    PUSH    DX

    MOV     BX, OFFSET STATE
    MOV     [BX], STATE_1
    ; SET LIGHT
    MOV     AL, STATE_1_LIGHT
    MOV     DX, I8255ADDB
    OUT     DX, AL
    ; SET COUNTDOWN
    MOV     BX, OFFSET COUNT
    MOV     AX, 30
    MOV     [BX], AX    

    MOV     BX, OFFSET BUF
    MOV     AL, 0
    MOV     [BX], AL
    MOV     AL, 3
    MOV     [BX + 1], AL
    MOV     AL, 0
    MOV     [BX + 2], AL
    MOV     AL, 0
    MOV     [BX + 3], AL
    CALL    DISPLAY

    POP     DX
    POP     BX
    POP     AX
    RET
ENTER_STATE_1   ENDP

ENTER_STATE_2   PROC    NEAR
    PUSH    AX
    PUSH    BX
    PUSH    DX


    MOV     BX, OFFSET STATE

    MOV     [BX], STATE_2
    ; SET LIGHT
    MOV     AL, STATE_2_LIGHT
    MOV     DX, I8255ADDB
    OUT     DX, AL
    ; SET COUNTDOWN
    MOV     BX, OFFSET COUNT
    MOV     AX, 3
    MOV     [BX], AX    

    MOV     BX, OFFSET BUF
    MOV     AL, 3
    MOV     [BX], AL
    MOV     AL, 0
    MOV     [BX + 1], AL
    MOV     AL, 0
    MOV     [BX + 2], AL
    MOV     AL, 0
    MOV     [BX + 3], AL
    CALL    DISPLAY

    POP     DX
    POP     BX
    POP     AX
    RET
ENTER_STATE_2   ENDP

ENTER_STATE_3   PROC    NEAR
    PUSH    AX
    PUSH    BX
    PUSH    DX

    MOV     BX, OFFSET STATE
    MOV     [BX], STATE_2
    ; SET LIGHT
    MOV     AL, STATE_2_LIGHT
    MOV     DX, I8255ADDB
    OUT     DX, AL
    ; SET COUNTDOWN
    MOV     BX, OFFSET COUNT
    MOV     AX, 30
    MOV     [BX], AX    

    MOV     BX, OFFSET BUF
    MOV     AL, 0
    MOV     [BX], AL
    MOV     AL, 3
    MOV     [BX + 1], AL
    MOV     AL, 0
    MOV     [BX + 2], AL
    MOV     AL, 0
    MOV     [BX + 3], AL
    CALL    DISPLAY

    POP     DX
    POP     BX
    POP     AX
    RET
ENTER_STATE_3   ENDP

ENTER_STATE_4   PROC    NEAR
    PUSH    AX
    PUSH    BX
    PUSH    DX

    MOV     BX, OFFSET STATE
    MOV     [BX], STATE_3
    ; SET LIGHT
    MOV     AL, STATE_3_LIGHT
    MOV     DX, I8255ADDB
    OUT     DX, AL
    ; SET COUNTDOWN
    MOV     BX, OFFSET COUNT
    MOV     AX, 3
    MOV     [BX], AX    

    MOV     BX, OFFSET BUF
    MOV     AL, 3
    MOV     [BX], AL
    MOV     AL, 0
    MOV     [BX + 1], AL
    MOV     AL, 0
    MOV     [BX + 2], AL
    MOV     AL, 0
    MOV     [BX + 3], AL
    CALL    DISPLAY

    POP     DX
    POP     BX
    POP     AX
    RET
ENTER_STATE_4   ENDP

; 根据数码管显示缓存更新数码管显示
; BUF -- S0
; BUF+1 -- S1
; BUF+2 -- S2
; BUF+3 -- S3
DISPLAY     PROC    NEAR    ; 数码管显示数值，四位数值存放在BUF中
    PUSH    AX
    PUSH    BX
    PUSH    CX
    PUSH    DX
    PUSH    SI
    PUSH    DI

    MOV     SI, OFFSET BUF
    MOV     DI, OFFSET BZ
    MOV     CX, 4
DISP_L1:
    MOV     AL, [SI]
    MOV     BX, OFFSET TAB
    XLAT
    MOV     DX, I8255ADDA
    OUT     DX, AL
    MOV     AL, [DI]
    MOV     DX, I8255ADDC
    OUT     DX, AL
    CALL    DELAY
    INC     SI
    INC     DI
    MOV     DX, I8255ADDC
    MOV     AL, 0F0H
    OUT     DX, AL
    LOOP    DISP_L1

    POP     DI
    POP     SI
    POP     DX
    POP     CX
    POP     BX
    POP     AX
    RET
DISPLAY     ENDP


; DELAY
DELAY   PROC    NEAR
    PUSH    CX
    MOV     CX, 07FFH
LOP1:
    LOOP    LOP1
    POP     CX
    RET
DELAY   ENDP
CODE	ENDS
END START


