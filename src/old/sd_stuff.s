;###################################################
;# ThatLolaSnail - github.com/ThatLolaSnail/Snail1 #
;###################################################
;#                                                 #
;#   N e w   S D   s t u f f                       #
;#                                                 #
;###################################################

;# Hardware:
;#           Bit         3       2        1        0
;# @00 OUT | SD/LCD  | LCD(1) | CS(1) | CLK(0) | MOSI(1)
;# @10  IN | SD      |        |       |        | MISO   
;# @20 OUT | LCD | bit 7-4 data

.equ SD_OUT,   0x00
.equ SD_IN,    0x10
.equ LCD_DATA, 0x20


;####################
;# SD_SEND_CMD@C0B0 #
;####################
org 0x000D ; 0xC0AD
SD_SEND_CMD:
	LD DE, 0x0006 ;send 6 bytes
;################
;# SD_SEND@C0B0 #
;################
org 0x0010 ; 0xC0B0
SD_SEND:
;DE = No. of bytes
;HL = Data
;(B=bit counter) (C=data shift)
	PUSH BC
	PUSH DE
	PUSH AF
	;LDA, 0b1001 ;EN Low
	;OUT 0x00, A
SD_SEND_NEXT_BYTE:
	  LD C, (HL)
	  INC HL
	  LD B, 0x08 ;count bits
SD_SEND_NEXT_BIT:
	    RL C ;bit in carry
	    LD A, 0b0100
	    RLA            ;0b100X ;Clock Low 
	    OUT (SD_OUT), A
	    OR 0b0010   ;0b101X ;Clock High
	    OUT (SD_OUT), A
	  DJNZ SD_SEND_NEXT_BIT
	  ;byte done
	  DEC DE;
	  LD A, D
	  OR E
	JR NZ, SD_SEND_NEXT_BYTE

	LD A, 0b1001 ; MOSI=1, SCK=0
	OUT (SD_OUT), A
	POP AF
	POP DE
	POP BC
	RET


;###########################
;# SD_REC_WAIT_SINGLE@C0B0 #
;###########################
org 0x0036 ; 0xc0d6
SD_REC_WAIT_SINGLE:
	LD DE,0x0001 ; 1 byte
	LD B, 7      ; 7 bits (and the start bit.)
;####################
;# SD_REC_WAIT@C0B0 #
;####################
org 0x003b ; 0xc0db
SD_REC_WAIT:
;HL = Data output
;B  = bits in first byte (after the leading 0)
;DE = Number of bytes
;C  = Error return (0=error)
;(C=data shift)
	PUSH AF
	LD C,0
SD_REC_WAIT_LOOP:
	  INC C
	  JR Z, SD_REC_END ;break
	  LD A, 0b1001     ;clock Low
	  OUT (SD_OUT), A
	  LD A, 0b1011     ;clock High
	  OUT (SD_OUT), A
	  IN A, (SD_IN)
	  BIT 0, A
	JR NZ, SD_REC_WAIT_LOOP
	POP AF
;###############
;# SD_REC@C0F0 #
;###############
org 0x0050 ; 0xc0f0
SD_REC:
	PUSH AF
	PUSH BC
	PUSH DE
SD_REC_NEXT_BYTE:
	  LD C, 0
SD_REC_NEXT_BIT:
	    LD A, 0b1001    ;clock low
	    OUT (SD_OUT), A
	    LD A, 0b1011    ;clock high
	    OUT (SD_OUT), A
	    IN A, (SD_IN)
	    RRA  ;bit is in carry
	    RL C ;add the bit to the byte
	  DJNZ SD_REC_NEXT_BIT
	  LD (HL), C ;save byte
	  INC HL     ;point to next byte
	  LD B, 8    ;next byte will have 8 bits
	  DEC DE     ;one byte less to receive
	  LD A, D
	  OR E       ;irgendein vergleich? von D und E???
	  JR NZ, SD_REC_NEXT_BYTE
	POP DE
	POP BC
SD_REC_END:
	POP AF
	RET

	





	

ld hl, SD_REC


