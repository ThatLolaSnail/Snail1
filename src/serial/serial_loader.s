#.equ BASE, 0xC0A0
.equ BASE, 0x0000
;###################################################
;# ThatLolaSnail - github.com/ThatLolaSnail/Snail1 #
;###################################################
;#                                                 #
;#   S e r i a l   L o a d e r                     #
;#                                                 #
;###################################################

; Hardware:
;      Bit    3     2     1     0
; @00 OUT  |  -  |  -  |  -  | TX(1) |
; @10  IN  |  -  |  -  |  -  | Rx    |

; Memory map
; ff00 - ffff | Stack
; 0100 - feff | Serial input Buffer (for programs and stuff)
.equ ser_buffer, 0x0100

#equ SER_PORT, 0x00
equ SER_IN,   0x10


;set up registers code
	nop
	ld sp, 0x0000 ;set up stack
	ld hl, ser_buffer ;load serial buffer address in HL
	im 1 	; an interrupt in mode 1 will do a call to 0x38
	ei      ; turn on interrupts

main_loop:
	jp main_loop


;interrupt handler
;receive a byte with 38400 baud
org 0x38
interrupt:
	di ;disable interrupts
	   ;we're gonna receive 10 bits: 0xxxxxxxx1 (but ignore the last)
	ld d, 9 ; we have to receive the start bit and 8 data bits.
rec_loop:
	;read a bit
	in a, (SER_IN)      ; 11
	in a, (SER_IN)      ; 11
	rra                 ;  4 shift the bit into the carry flag
	rr c                ;  8 shift the bit into c
	;wait for next bit
	ld b, 4             ;  7
rec_wait_loop:
	djnz rec_wait_loop  ;  8 + 13*3

	dec d               ;  4
	jr nz, rec_loop     ; 12
	                   ;-----
			    ;104
	;store result
	ld (hl), c
	inc hl 

	ei ;enable interrupts
	ret

