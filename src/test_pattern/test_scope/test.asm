; -----------------------------------------------------------------------------
;	test program
; -----------------------------------------------------------------------------

	org		0

	ld		bc, label_0000			; この label_0000 は 8行目のやつ
label_0000:							; 0003番地
	ld		bc, label_0000			; この label_0000 は 8行目のやつ

;	scope
scope SCOPE1
		ld		bc, label_0000		; この label_0000 は 14行目のやつ
	label_0000:						; 0009番地
		ld		bc, label_0000		; この label_0000 は 14行目のやつ
endscope

;	scope
scope SCOPE2
	scope SCOPE3
			ld		bc, label_0000	; この label_0000 は 22行目のやつ
		label_0000:					; 000F番地
			ld		bc, label_0000	; この label_0000 は 22行目のやつ
	endscope
endscope

	ld		bc, label_0000			; この label_0000 は 8行目のやつ

;	scope
scope SCOPE1
		ld		bc, label_0000		; この label_0000 は 14行目のやつ
endscope

;	scope
scope SCOPE2
	scope SCOPE3
			ld		bc, label_0000	; この label_0000 は 22行目のやつ
	endscope
endscope

label_1234 = 0x1234
	ld		bc, label_1234

global_2345 := 0x2345
	ld		bc, global_2345

scope SCOPE1
		ld		bc, label_1234
label_1234 = 0x3456
		ld		bc, label_1234
		ld		bc, global_2345
endscope

			defb	0,1,2,3,4,5,6,7,8
			defw	0,1,2,3,4,5,6,7,8
			defd	0,1,2,3,4,5,6,7,8
			defs	"012345678"

title		= "game title"
			defs	title

			defs	"01234" * 3 + "5678"
			defs	"abcd" + 4 * "432"

ld_de_bc	macro
			ld		d, b			; 0x50
			ld		e, c			; 0x59
			endm

ld_a		macro	exp
			ld		a, exp
			endm

			defb	0xAA
			ld_de_bc
			defb	0x55
			ld_de_bc

			ld_a	10 + 6
			ld_a	[hl]

;			error	"hoge" + 10 + "moge"
