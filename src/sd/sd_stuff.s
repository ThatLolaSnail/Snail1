.equ BASE, 0xC0A0
#.equ BASE, 0x0000
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
;# SD_SEND_CMD@C0AD #
;####################
;send 6 bytes, used for sending commands (which are 6 bytes)
org 0xC0AD-BASE ; 0xC0AD
SD_SEND_CMD:
	LD DE, 0x0006 ;send 6 bytes
;################
;# SD_SEND@C0B0 #
;################
;send DE bytes of data to the sd card.
org 0xC0B0-BASE ; 0xC0B0
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
;# SD_REC_WAIT_SINGLE@C0D6 #
;###########################
;pulse clock until the card sends the normal response and receive the response.
org 0xC0D6-BASE ; 0xc0d6
SD_REC_WAIT_SINGLE:
	LD DE,0x0001 ; 1 byte
	LD B, 7      ; 7 bits (and the start bit.)
;####################
;# SD_REC_WAIT@C0DB #
;####################
;pulse clock until the card sends data, and then receive the specified amount.
org 0xC0DB-BASE ; 0xc0db
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
;receive card data, assume it starts with the first clock cycle. (used when we already received using the SD_REC_WAIT)
org 0xC0F0-BASE ; 0xc0f0
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
	  OR E       ;if DE==0 then D OR E will set 0-bit
	  JR NZ, SD_REC_NEXT_BYTE
	POP DE
	POP BC
SD_REC_END:
	POP AF
	RET


;################
;# SD_INIT@C120 #
;################
;send the commands needed for initializing the card. call this when the computer starts (or the card is changed)
org 0xC120-BASE
SD_INIT:
	PUSH BC
	PUSH DE
	PUSH HL
	PUSH AF
	LD B, 0x50 ; 80 is more than the required 74 empty cycles.
SD_INIT_LOOP:
	  LD A, 0b1111 ;clock high
	  OUT (SD_OUT), A
	  LD A, 0b1101 ;clock low
	  OUT (SD_OUT), A
	DJNZ SD_INIT_LOOP

SD_INIT_RETRY_RESET:
	LD HL, CMD0
	  CALL SD_SEND_CMD	  ;send cmd0
	  CALL SD_REC_WAIT_SINGLE ;receive 7-bit answer
	  LD A, C
	  OR A			  ;test if successfull
	JR Z, SD_INIT_RETRY_RESET ;and retry if not

	nop ;because it was there in my handwritten program...

;send ACMD41
	LD a, 0xff
	LD (RESP41), A ;assume not ready, and write this there.
SD_INIT_RETRY_ACMD41:
	  LD HL, CMD55
	  CALL SD_SEND_CMD		;send CMD55
	  CALL SD_REC_WAIT_SINGLE
	  LD A, C
	  OR A
	JR Z, SD_INIT_RETRY_ACMD41	;retry if error

	  CALL SD_SEND_CMD		;send CMD41
	  CALL SD_REC_WAIT_SINGLE

	  LD A, (RESP41)		;this will be either the result
	  OR A				;(or the ff we wrote there before)
	JR NZ, SD_INIT_RETRY_ACMD41	;Retry if not successfull

	;Select block size
	CALL SD_SEND_CMD	;CMD16
	CALL SD_REC_WAIT_SINGLE

	;return
	POP AF
	POP HL
	POP DE
	POP BC
	RET

;sd commands
CMD0:	;reset
	db 0x40 db 0x00  db 0x00 db 0x00  db 0x00 db 0x95
RESP0:
	db 0xFF
CMD55:	;extended commands
	db 0x77 db 0x00  db 0x00 db 0x00  db 0x00 db 0xFF
RESP55:
	db 0xFF
CMD41:	;in combination with 55: ACM41: INIT
	db 0x69 db 0x00  db 0x00 db 0x00  db 0x00 db 0xFF
RESP41:
	db 0xFF
CMD16:	;change blocksize to 512 (default)
	db 0x50 db 0x00  db 0x00 db 0x02  db 0x00 db 0xFF
RESP16:
	db 0XFF



;now the stuff from the next page...

;more sd commands
org 0xC183-BASE
CMD18:	db 0x52 db 0x00  db 0x00 db 0x00  db 0x00 db 0xFF	  ;Read Multiple
RESP18:	db 0xFF
CMD12:	db 0x4C db 0x00  db 0x00 db 0x00  db 0x00 db 0xFF db 0xFF ;Stop Read (and clock empty FF byte)
RESP12:	db 0xFF
CMD25:	db 0x59 db 0x00  db 0x00 db 0x00  db 0x00 db 0xFF	  ;Write Multiple
RESP25:	db 0xFF
DATA_TOKEN: db 0xFF db 0xFC	    ;Data Token for CMD25 ; including the wait before that
STOP_TOKEN: db 0xFF db 0xFD db 0xFF ;Stop Token for CMD25 ; including the wait before and after (aka empty FF byte)

SCRATCHPAD: db 0xFF db 0xFF ;2 usless bytes, scrap values will be stored here (CRC and stuff)

EQU CRC, SCRATCHPAD-2 ;use the 2 bytes before the cratchpad, the FDFF from the stop token, as the fake CRC

;##########################
;# SD_WAIT_RESP_WAIT@C1A0 #
;##########################
;pulse clock until sd card sends response, receive it, and wait for the card to finish processing
org 0xC1A0-BASE
SD_WAIT_RESP_WAIT:
	PUSH AF
	PUSH BC	
	PUSH DE
	CALL SD_REC_WAIT_SINGLE ;read 7 bit response
	POP DE
	POP BC
	POP AF ;JR SD_WAIT_AFTER_PUSH initially I just jumped over the PUSH, now I just POP, so I don't have to jump over the PUSH
;################
;# SD_WAIT@C1AA #
;################
;pulse clock until the sd card has finished processing
org 0xC1AA-BASE
SD_WAIT:
	PUSH AF
SD_WAIT_LOOP:
	  LD A, 0b1001
	  OUT (SD_OUT), A
	  LD A, 0b1011	;clock in next bit 
	  OUT (SD_OUT), A
	  IN A,(SD_IN)
	  BIT 0,A
	JR Z, SD_WAIT_LOOP
	POP AF
	RET

;########################
;# SD_READ_SECTORS@C1C0 #
;########################
;read A sectors from disk at BCDE to HL in RAM
org 0xC1C0-BASE
SD_READ_SECTORS:
;HL   = Dest
;BCDE = Sector
;A    = No. of sectors
	PUSH BC
	PUSH DE
	PUSH AF
	PUSH HL

	LD HL, CMD18+1
	LD (HL),B 
	INC HL
	LD (HL),C 
	INC HL
	LD (HL),D 
	INC HL
	LD (HL),E

	LD HL, CMD18
	CALL SD_SEND_CMD ;send CMD18
	CALL SD_REC_WAIT_SINGLE ;response

	;now read next data block
SD_READ_BLOCK:
	  POP HL
	  LD DE, 0x0200	 ;512 bytes
	  LD B, 8		 ;first byte has 8 bit (after the 0)
	  CALL SD_REC_WAIT ;Get Data
	  PUSH HL
	  LD DE, 0x0002
	  LD HL, SCRATCHPAD
	  CALL SD_REC	;Get CRC :-) ... And discard it...
	
	  DEC A
	JR NZ, SD_READ_BLOCK

	LD HL, CMD12
	LD DE, 0x0007 ;send CMD12 and wait a byte (0xFF until the sd card actually stops the data)
	CALL SD_SEND
	CALL SD_WAIT_RESP_WAIT ;Get the response and wait for Ready

	POP HL
	POP AF
	POP DE
	POP BC
	RET


;#########################
;# SD_WRITE_SECTORS@C200 #
;#########################
;write A sectors from RAM at HL to adress BCDE on the disk
org 0xC200-BASE
SD_WRITE_SECTORS:
;HL   = Source
;BCDE = Sector
;A    = No. of sectors
	PUSH BC
	PUSH DE
	PUSH AF
	PUSH HL

	LD HL, CMD25+1
	LD (HL),B 
	INC HL
	LD (HL),C 
	INC HL
	LD (HL),D 
	INC HL
	LD (HL),E

	;send the command to the sd card and get the response
	LD HL, CMD25
	CALL SD_SEND_CMD
	CALL SD_REC_WAIT_SINGLE

	;now write next data block
SD_WRITE_NEXT_BLOCK:
	  ;first the start token
	  LD HL, DATA_TOKEN ;address of the data token
	  LD DE, 0x0002     ;length, 2 bytes in this case
	  CALL SD_SEND      ;Send the data token
	  
	  ;then the data
	  POP HL
	  LD DE, 0x0200
	  CALL SD_SEND
	  PUSH HL

	  ;send fake CRC
	  LD HL, CRC
	  LD DE, 0x0002
	  CALL SD_SEND

	  ;now receive data response: 0xxxx where the xxxx is the 4-bit response (either 0101=accepted or 1XX1=error)
	  LD B,4		;4 bits
	  LD DE, 0x0001	;1 byte (which has 4 bits)
	  CALL SD_REC_WAIT
	  ;and wait for the card to finish processing
	  CALL SD_WAIT

	;decrement counter and repeat
	DEC A
	JR NZ, SD_WRITE_NEXT_BLOCK

	;tell the card to stop
	LD HL, STOP_TOKEN
	LD DE, 0x0003 ;send 3 bytes, one byte as a wait, the actual stop token, and one more for wait.
	CALL SD_SEND
	;wait for the sd card to finish processing
	CALL SD_WAIT

	POP HL
	POP AF
	POP DE
	POP BC
	RET









