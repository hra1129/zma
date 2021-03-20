; -----------------------------------------------------------------------------
;	test program
; -----------------------------------------------------------------------------

;	FILE_ADDRESS
	ld		bc, FILE_ADDRESS			; 01 00 00

;	decimal number
	ld		bc, 1234					; 01 D2 04
	ld		bc, 12_34					; 01 D2 04

;	hexadecimal number
	ld		bc, 0x1234					; 01 34 12
	ld		bc, 0x12_34					; 01 34 12

;	binary number
	ld		bc, 0b1100101011100110		; 01 E6 CA
	ld		bc, 0b1100_1010_1110_0110	; 01 E6 CA

;	octal number
	ld		bc, 01234					; 01 9C 02
	ld		bc, 012_34					; 01 9C 02

;	$
	org		0x1234
	ld		bc, $						; 01 34 12

;	CODE_ADDRESS
	org		0x1234
	ld		bc, CODE_ADDRESS			; 01 34 12

;	+ (plus)
	ld		bc, +1234					; 01 D2 04

;	- (minus)
	ld		bc, -1234					; 01 2E FB

;	( expression )
	ld		bc, ( 1 + 2 ) * 3			; 01 09 00

;	!
	ld		bc, !1234					; 01 00 00
	ld		bc, !0						; 01 01 00

;	~
	ld		bc, ~0x1234					; 01 CB ED

;	*
	ld		bc, 21 * 3					; 01 3F 00
	message	"moji" * 3
	message	3 * "moji"

;	/
	ld		bc, 21 / 3					; 01 07 00

;	%
	ld		bc, 22 % 5					; 01 02 00

;	+ (addition)
	ld		bc, 23 + 5					; 01 1C 00
	message	"moji = " + "moji"
	message	"moji = " + 123
	message	123 + " = moji"

;	- (subtruct)
	ld		bc, 24 - 9					; 01 0F 00

;	<<
	ld		bc, 5 << 1					; 01 0A 00

;	>>
	ld		bc, 10 >> 1					; 01 05 00

;	<
	ld		bc, 5 < 1					; 01 00 00
	ld		bc, 1 < 5					; 01 01 00

;	>
	ld		bc, 5 > 1					; 01 01 00
	ld		bc, 1 > 5					; 01 00 00

;	<=
	ld		bc, 5 <= 1					; 01 00 00
	ld		bc, 1 <= 5					; 01 01 00
	ld		bc, 3 <= 3					; 01 01 00

;	>=
	ld		bc, 5 >= 1					; 01 01 00
	ld		bc, 1 >= 5					; 01 00 00
	ld		bc, 3 >= 3					; 01 01 00

;	==
	ld		bc, 5 == 1					; 01 00 00
	ld		bc, 3 == 3					; 01 01 00
	ld		bc, "a" == "a"				; 01 01 00
	ld		bc, "b" == "a"				; 01 00 00
	ld		bc, "b" == 3				; 01 00 00

;	!=
	ld		bc, 5 != 1					; 01 01 00
	ld		bc, 3 != 3					; 01 00 00
	ld		bc, "a" != "a"				; 01 00 00
	ld		bc, "b" != "a"				; 01 01 00
	ld		bc, "b" != 3				; 01 01 00

;	&
	ld		bc, 5 & 1					; 01 01 00
	ld		bc, 9 & 1					; 01 00 00

;	|
	ld		bc, 2 | 1					; 01 03 00
	ld		bc, 4 | 1					; 01 05 00

;	^
	ld		bc, 2 ^ 1					; 01 03 00
	ld		bc, 1 ^ 1					; 01 00 00

;	&&
	ld		bc, 1 && 1					; 01 01 00
	ld		bc, 0 && 1					; 01 00 00
	ld		bc, 1 && 0					; 01 00 00
	ld		bc, 0 && 0					; 01 00 00

;	||
	ld		bc, 1 || 1					; 01 01 00
	ld		bc, 0 || 1					; 01 01 00
	ld		bc, 1 || 0					; 01 01 00
	ld		bc, 1 || 0					; 01 00 00

;	文字列中のエスケープシーケンス
	message	"\a\b\f\n\r\t\\\'\"\?"

;	漢字
	message	"漢字表示αβ１２３"
