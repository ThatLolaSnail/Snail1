#.equ BASE, 0xC0A0
.equ BASE, 0x0000
;###################################################
;# ThatLolaSnail - github.com/ThatLolaSnail/Snail1 #
;###################################################
;#                                                 #
;#   S e r i a l   C o m m u n i c a t i o n       #
;#                                                 #
;###################################################

; Hardware:
;      Bit    3     2     1     0
; @00 OUT  |  -  |  -  |  -  | TX(1) |
; @10  IN  |  -  |  -  |  -  | Rx    |

; Memory map
; ff00 - ffff | Stack
; fe00 - feff | Serial input Buffer
; 0100 - 01ff | Serial input Buffer just as a test...

;.equ ser_buffer, 0xfe00
.equ ser_buffer, 0x0100

equ SER_PORT, 0x00
equ SER_IN,   0x10



;boot code
	nop 	; needed because the first instruction is executed before the busrq is acknowledged
	;set up stack
	ld sp, 0x0000
	;set up interrupt stuff
	ld hl, ser_buffer ;load int the register HL
	EXX               ;and exchange it into HL'
	;turn on interrupts
	im 1 	; an interrupt in mode 1 will do a call to 0x38
	ei      ; turn on interrupts

main_loop:
	nop
	nop
	nop
	jr main_loop

text:
	db "Hello!"


; example of the send:
; ld hl, text
; ld e, 6
; call send_bytes


;send a byte with 38400 baud (104.16 clock cycles per byte)
send_bytes:
	; a  temp
	; b  wait counter
	; c  current byte
	; d  bit counter
	; e  byte counter
	; hl pointer to next byte

	;load next byte
	ld c, (HL)
	inc hl

	;send these bits: 0aaaaaaaa1 - 0 is the start bit, 1 is the stop bit
	ld d, 10            ; send 10 bits
	ld a, 0b11111110    ; 0 start bit
	scf ;set carry flag ; 1 stop  bit
send_byte_loop:
	out (SER_PORT), a  ; 11 output this bit (start bit)
	;load the next bit
	ld a, 0xff          ;  7
	rr c                ;  8 shift next bit of c into the carry & shift stop bit into highest bit
	rla                 ;  4 shift the bit from the carry into the output
	;wait loop
	nop                 ;  4
	ld b, 4             ;  7 wait time
send_wait_loop:
	djnz send_wait_loop ;  8 + 13*3 waitloop times

	dec d               ;  4
	jr nz, send_byte_loop;12
	                   ;-----
			    ;104
	;go to the next byte
	dec e
	jr nz, send_bytes

	ret





;interrupt handler
;receive a byte with 38400 baud
org 0x38
interrupt:
	di
	EX AF, AF'
	EXX
	   ;we're gonna receive 10 bits: 0xxxxxxxx1
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
	inc l ;only increment l to wrap around after 256 bytes.

	EX AF, AF'
	EXX
	ei
	;halt
	ret
	;reti

