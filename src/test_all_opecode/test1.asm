; -----------------------------------------------------------------------------
;	test program
; -----------------------------------------------------------------------------

	org		0xC000

;	00 00 00 00
	nop
	nop
	nop
	nop

;	01 00 00 00
	ld		bc, 0x0000
	nop

;	02 00 00 00
	ld		[bc],a
	nop
	nop
	nop

;	03 00 00 00
	inc		bc
	nop
	nop
	nop

;	04 00 00 00
	inc		b
	nop
	nop
	nop

;	05 00 00 00
	dec		b
	nop
	nop
	nop

;	06 00 00 00
	ld		b, 0x00
	nop
	nop

;	07 00 00 00
	rlca
	nop
	nop
	nop

;	08 00 00 00
	ex		af, af'
	nop
	nop
	nop

;	09 00 00 00
	add		hl, bc
	nop
	nop
	nop

;	0A 00 00 00
	ld		a, [bc]
	nop
	nop
	nop

;	0B 00 00 00
	dec		bc
	nop
	nop
	nop

;	0c 00 00 00
	inc		c
	nop
	nop
	nop

;	0d 00 00 00
	dec		c
	nop
	nop
	nop

;	0e 00 00 00
	ld		c, 0x00
	nop
	nop

;	0f 00 00 00
	rrca
	nop
	nop
	nop

;	10 00 00 00
	djnz	label_djnz
label_djnz:
	nop
	nop

;	11 00 00 00
	ld		de, 0x0000
	nop

;	12 00 00 00
	ld		[de], a
	nop
	nop
	nop

;	13 00 00 00
	inc		de
	nop
	nop
	nop

;	14 00 00 00
	inc		d
	nop
	nop
	nop

;	15 00 00 00
	dec		d
	nop
	nop
	nop

;	16 00 00 00
	ld		d, 0x00
	nop
	nop

;	17 00 00 00
	rla
	nop
	nop
	nop

;	18 00 00 00
	jr		label_jr
label_jr:
	nop
	nop

;	19 00 00 00
	add		hl, de
	nop
	nop
	nop

;	1A 00 00 00
	ld		a, [de]
	nop
	nop
	nop

;	1B 00 00 00
	dec		de
	nop
	nop
	nop

;	1C 00 00 00
	inc		e
	nop
	nop
	nop

;	1D 00 00 00
	dec		e
	nop
	nop
	nop

;	1E 00 00 00
	ld		e, 0x00
	nop
	nop

;	1F 00 00 00
	rra
	nop
	nop
	nop

;	20 00 00 00
	jr		nz, label_jr_nz
label_jr_nz:
	nop
	nop

;	21 00 00 00
	ld		hl, 0x0000
	nop

;	22 00 00 00
	ld		[0x0000], hl
	nop

;	23 00 00 00
	inc		hl
	nop
	nop
	nop

;	24 00 00 00
	inc		h
	nop
	nop
	nop

;	25 00 00 00
	dec		h
	nop
	nop
	nop

;	26 00 00 00
	ld		h, 0x00
	nop
	nop

;	27 00 00 00
	daa
	nop
	nop
	nop

;	28 00 00 00
	jr		z, label_jr_z
label_jr_z:
	nop
	nop

;	29 00 00 00
	add		hl, hl
	nop
	nop
	nop

;	2A 00 00 00
	ld		hl, [0x0000]
	nop

;	2B 00 00 00
	dec		hl
	nop
	nop
	nop

;	2C 00 00 00
	inc		l
	nop
	nop
	nop

;	2D 00 00 00
	dec		l
	nop
	nop
	nop

;	2E 00 00 00
	ld		l, 0x00
	nop
	nop

;	2F 00 00 00
	cpl
	nop
	nop
	nop

;	30 00 00 00
	jr		nc, label_jr_nc
label_jr_nc:
	nop
	nop

;	31 00 00 00
	ld		sp, 0x0000
	nop

;	32 00 00 00
	ld		[0x0000], a
	nop

;	33 00 00 00
	inc		sp
	nop
	nop
	nop

;	34 00 00 00
	inc		[hl]
	nop
	nop
	nop

;	35 00 00 00
	dec		[hl]
	nop
	nop
	nop

;	36 00 00 00
	ld		[hl], 0x00
	nop
	nop

;	37 00 00 00
	scf
	nop
	nop
	nop

;	38 00 00 00
	jr		c, label_jr_c
label_jr_c:
	nop
	nop

;	39 00 00 00
	add		hl, sp
	nop
	nop
	nop

;	3A 00 00 00
	ld		a, [0x0000]
	nop

;	3B 00 00 00
	dec		sp
	nop
	nop
	nop

;	3C 00 00 00
	inc		a
	nop
	nop
	nop

;	3D 00 00 00
	dec		a
	nop
	nop
	nop

;	3E 00 00 00
	ld		a, 0x00
	nop
	nop

;	3F 00 00 00
	ccf
	nop
	nop
	nop

;	40 00 00 00
	ld		b, b
	nop
	nop
	nop

;	41 00 00 00
	ld		b, c
	nop
	nop
	nop

;	42 00 00 00
	ld		b, d
	nop
	nop
	nop

;	43 00 00 00
	ld		b, e
	nop
	nop
	nop

;	44 00 00 00
	ld		b, h
	nop
	nop
	nop

;	45 00 00 00
	ld		b, l
	nop
	nop
	nop

;	46 00 00 00
	ld		b, [hl]
	nop
	nop
	nop

;	47 00 00 00
	ld		b, a
	nop
	nop
	nop

;	48 00 00 00
	ld		c, b
	nop
	nop
	nop

;	49 00 00 00
	ld		c, c
	nop
	nop
	nop

;	4A 00 00 00
	ld		c, d
	nop
	nop
	nop

;	4B 00 00 00
	ld		c, e
	nop
	nop
	nop

;	4C 00 00 00
	ld		c, h
	nop
	nop
	nop

;	4D 00 00 00
	ld		c, l
	nop
	nop
	nop

;	4E 00 00 00
	ld		c, [hl]
	nop
	nop
	nop

;	4F 00 00 00
	ld		c, a
	nop
	nop
	nop

;	50 00 00 00
	ld		d, b
	nop
	nop
	nop

;	51 00 00 00
	ld		d, c
	nop
	nop
	nop

;	52 00 00 00
	ld		d, d
	nop
	nop
	nop

;	53 00 00 00
	ld		d, e
	nop
	nop
	nop

;	54 00 00 00
	ld		d, h
	nop
	nop
	nop

;	55 00 00 00
	ld		d, l
	nop
	nop
	nop

;	56 00 00 00
	ld		d, [hl]
	nop
	nop
	nop

;	57 00 00 00
	ld		d, a
	nop
	nop
	nop

;	58 00 00 00
	ld		e, b
	nop
	nop
	nop

;	59 00 00 00
	ld		e, c
	nop
	nop
	nop

;	5A 00 00 00
	ld		e, d
	nop
	nop
	nop

;	5B 00 00 00
	ld		e, e
	nop
	nop
	nop

;	5C 00 00 00
	ld		e, h
	nop
	nop
	nop

;	5D 00 00 00
	ld		e, l
	nop
	nop
	nop

;	5E 00 00 00
	ld		e, [hl]
	nop
	nop
	nop

;	5F 00 00 00
	ld		e, a
	nop
	nop
	nop

;	60 00 00 00
	ld		h, b
	nop
	nop
	nop

;	61 00 00 00
	ld		h, c
	nop
	nop
	nop

;	62 00 00 00
	ld		h, d
	nop
	nop
	nop

;	63 00 00 00
	ld		h, e
	nop
	nop
	nop

;	64 00 00 00
	ld		h, h
	nop
	nop
	nop

;	65 00 00 00
	ld		h, l
	nop
	nop
	nop

;	66 00 00 00
	ld		h, [hl]
	nop
	nop
	nop

;	67 00 00 00
	ld		l, a
	nop
	nop
	nop

;	68 00 00 00
	ld		l, b
	nop
	nop
	nop

;	69 00 00 00
	ld		l, c
	nop
	nop
	nop

;	6A 00 00 00
	ld		l, d
	nop
	nop
	nop

;	6B 00 00 00
	ld		l, e
	nop
	nop
	nop

;	6C 00 00 00
	ld		l, h
	nop
	nop
	nop

;	6D 00 00 00
	ld		l, l
	nop
	nop
	nop

;	6E 00 00 00
	ld		l, [hl]
	nop
	nop
	nop

;	6F 00 00 00
	ld		l, a
	nop
	nop
	nop

;	70 00 00 00
	ld		[hl], b
	nop
	nop
	nop

;	71 00 00 00
	ld		[hl], c
	nop
	nop
	nop

;	72 00 00 00
	ld		[hl], d
	nop
	nop
	nop

;	73 00 00 00
	ld		[hl], e
	nop
	nop
	nop

;	74 00 00 00
	ld		[hl], h
	nop
	nop
	nop

;	75 00 00 00
	ld		[hl], l
	nop
	nop
	nop

;	76 00 00 00
	halt
	nop
	nop
	nop

;	77 00 00 00
	ld		a, a
	nop
	nop
	nop

;	78 00 00 00
	ld		a, b
	nop
	nop
	nop

;	79 00 00 00
	ld		a, c
	nop
	nop
	nop

;	7A 00 00 00
	ld		a, d
	nop
	nop
	nop

;	7B 00 00 00
	ld		a, e
	nop
	nop
	nop

;	7C 00 00 00
	ld		a, h
	nop
	nop
	nop

;	7D 00 00 00
	ld		a, l
	nop
	nop
	nop

;	7E 00 00 00
	ld		a, [hl]
	nop
	nop
	nop

;	7F 00 00 00
	ld		a, a
	nop
	nop
	nop

;	80 00 00 00
	add		a, b
	nop
	nop
	nop

;	81 00 00 00
	add		a, c
	nop
	nop
	nop

;	82 00 00 00
	add		a, d
	nop
	nop
	nop

;	83 00 00 00
	add		a, e
	nop
	nop
	nop

;	84 00 00 00
	add		a, h
	nop
	nop
	nop

;	85 00 00 00
	add		a, l
	nop
	nop
	nop

;	86 00 00 00
	add		a, [hl]
	nop
	nop
	nop

;	87 00 00 00
	add		a, a
	nop
	nop
	nop

;	88 00 00 00
	adc		a, b
	nop
	nop
	nop

;	89 00 00 00
	adc		a, c
	nop
	nop
	nop

;	8A 00 00 00
	adc		a, d
	nop
	nop
	nop

;	8B 00 00 00
	adc		a, e
	nop
	nop
	nop

;	8C 00 00 00
	adc		a, h
	nop
	nop
	nop

;	8D 00 00 00
	adc		a, l
	nop
	nop
	nop

;	8E 00 00 00
	adc		a, [hl]
	nop
	nop
	nop

;	8F 00 00 00
	adc		a, a
	nop
	nop
	nop

;	90 00 00 00
	sub		a, b
	nop
	nop
	nop

;	91 00 00 00
	sub		a, c
	nop
	nop
	nop

;	92 00 00 00
	sub		a, d
	nop
	nop
	nop

;	93 00 00 00
	sub		a, e
	nop
	nop
	nop

;	94 00 00 00
	sub		a, h
	nop
	nop
	nop

;	95 00 00 00
	sub		a, l
	nop
	nop
	nop

;	96 00 00 00
	sub		a, [hl]
	nop
	nop
	nop

;	97 00 00 00
	sub		a, a
	nop
	nop
	nop

;	98 00 00 00
	sbc		a, b
	nop
	nop
	nop

;	99 00 00 00
	sbc		a, c
	nop
	nop
	nop

;	9A 00 00 00
	sbc		a, d
	nop
	nop
	nop

;	9B 00 00 00
	sbc		a, e
	nop
	nop
	nop

;	9C 00 00 00
	sbc		a, h
	nop
	nop
	nop

;	9D 00 00 00
	sbc		a, l
	nop
	nop
	nop

;	9E 00 00 00
	sbc		a, [hl]
	nop
	nop
	nop

;	9F 00 00 00
	sbc		a, a
	nop
	nop
	nop

;	A0 00 00 00
	and		a, b
	nop
	nop
	nop

;	A1 00 00 00
	and		a, c
	nop
	nop
	nop

;	A2 00 00 00
	and		a, d
	nop
	nop
	nop

;	A3 00 00 00
	and		a, e
	nop
	nop
	nop

;	A4 00 00 00
	and		a, h
	nop
	nop
	nop

;	A5 00 00 00
	and		a, l
	nop
	nop
	nop

;	A6 00 00 00
	and		a, [hl]
	nop
	nop
	nop

;	A7 00 00 00
	and		a, a
	nop
	nop
	nop

;	A8 00 00 00
	xor		a, b
	nop
	nop
	nop

;	A9 00 00 00
	xor		a, c
	nop
	nop
	nop

;	AA 00 00 00
	xor		a, d
	nop
	nop
	nop

;	AB 00 00 00
	xor		a, e
	nop
	nop
	nop

;	AC 00 00 00
	xor		a, h
	nop
	nop
	nop

;	AD 00 00 00
	xor		a, l
	nop
	nop
	nop

;	AE 00 00 00
	xor		a, [hl]
	nop
	nop
	nop

;	AF 00 00 00
	xor		a, a
	nop
	nop
	nop

;	B0 00 00 00
	or		a, b
	nop
	nop
	nop

;	B1 00 00 00
	or		a, c
	nop
	nop
	nop

;	B2 00 00 00
	or		a, d
	nop
	nop
	nop

;	B3 00 00 00
	or		a, e
	nop
	nop
	nop

;	B4 00 00 00
	or		a, h
	nop
	nop
	nop

;	B5 00 00 00
	or		a, l
	nop
	nop
	nop

;	B6 00 00 00
	or		a, [hl]
	nop
	nop
	nop

;	B7 00 00 00
	or		a, a
	nop
	nop
	nop

;	B8 00 00 00
	cp		a, b
	nop
	nop
	nop

;	B9 00 00 00
	cp		a, c
	nop
	nop
	nop

;	BA 00 00 00
	cp		a, d
	nop
	nop
	nop

;	BB 00 00 00
	cp		a, e
	nop
	nop
	nop

;	BC 00 00 00
	cp		a, h
	nop
	nop
	nop

;	BD 00 00 00
	cp		a, l
	nop
	nop
	nop

;	BE 00 00 00
	cp		a, [hl]
	nop
	nop
	nop

;	BF 00 00 00
	cp		a, a
	nop
	nop
	nop

;	C0 00 00 00
	ret		nz
	nop
	nop
	nop

;	C1 00 00 00
	pop		bc
	nop
	nop
	nop

;	C2 00 00 00
	jp		nz, 0x0000
	nop

;	C3 00 00 00
	jp		0x0000
	nop

;	C4 00 00 00
	call	nz, 0x0000
	nop

;	C5 00 00 00
	push	bc
	nop
	nop
	nop

;	C6 00 00 00
	add		a, 0x00
	nop
	nop

;	C7 00 00 00
	rst		0x00
	nop
	nop
	nop

;	C8 00 00 00
	ret		z
	nop
	nop
	nop

;	C9 00 00 00
	ret
	nop
	nop
	nop

;	CA 00 00 00
	jp		z, 0x0000
	nop

;	CB 00 00 00 (dummy)
	defb	0xCB
	nop
	nop
	nop

;	CC 00 00 00
	call	z, 0x0000
	nop

;	CD 00 00 00
	call	0x0000
	nop

;	CE 00 00 00
	adc		a, 0x00
	nop
	nop

;	CF 00 00 00
	rst		0x08
	nop
	nop
	nop

;	D0 00 00 00
	ret		nc
	nop
	nop
	nop

;	D1 00 00 00
	pop		de
	nop
	nop
	nop

;	D2 00 00 00
	jp		nc, 0x0000
	nop

;	D3 00 00 00
	out		[0x00], a
	nop
	nop

;	D4 00 00 00
	call	nc, 0x0000
	nop

;	D5 00 00 00
	push	de
	nop
	nop
	nop

;	D6 00 00 00
	sub		a, 0x00
	nop
	nop

;	D7 00 00 00
	rst		0x10
	nop
	nop
	nop

;	D8 00 00 00
	ret		c
	nop
	nop
	nop

;	D9 00 00 00
	exx
	nop
	nop
	nop

;	DA 00 00 00
	jp		c, 0x0000
	nop

;	DB 00 00 00
	in		a, [0x00]
	nop
	nop

;	DC 00 00 00
	call	c, 0x0000
	nop

;	DD 00 00 00 (dummy)
	defb	0xDD
	nop
	nop
	nop

;	DE 00 00 00
	sbc		a, 0x00
	nop
	nop

;	DF 00 00 00
	rst		0x18
	nop
	nop
	nop

;	E0 00 00 00
	ret		po
	nop
	nop
	nop

;	E1 00 00 00
	pop		hl
	nop
	nop
	nop

;	E2 00 00 00
	jp		po, 0x0000
	nop

;	E3 00 00 00
	ex		[sp], hl
	nop
	nop
	nop

;	E4 00 00 00
	call	po, 0x0000
	nop

;	E5 00 00 00
	push	hl
	nop
	nop
	nop

;	E6 00 00 00
	and		a, 0x00
	nop
	nop

;	E7 00 00 00
	rst		0x20
	nop
	nop
	nop

;	E8 00 00 00
	ret		pe
	nop
	nop
	nop

;	E9 00 00 00
	jp		hl
	nop
	nop
	nop

;	EA 00 00 00
	jp		pe, 0x0000
	nop

;	EB 00 00 00
	ex		de, hl
	nop
	nop
	nop

;	EC 00 00 00
	call	pe, 0x0000
	nop

;	ED 00 00 00 (dummy)
	defb	0xED
	nop
	nop
	nop

;	EE 00 00 00
	xor		a, 0x00
	nop
	nop

;	EF 00 00 00
	rst		0x28
	nop
	nop
	nop

;	F0 00 00 00
	ret		p
	nop
	nop
	nop

;	F1 00 00 00
	pop		af
	nop
	nop
	nop

;	F2 00 00 00
	jp		p, 0x0000
	nop

;	F3 00 00 00
	di
	nop
	nop
	nop

;	F4 00 00 00
	call	p, 0x0000
	nop

;	F5 00 00 00
	push	af
	nop
	nop
	nop

;	F6 00 00 00
	or		a, 0x00
	nop
	nop

;	F7 00 00 00
	rst		0x30
	nop
	nop
	nop

;	F8 00 00 00
	ret		m
	nop
	nop
	nop

;	F9 00 00 00
	ld		sp, hl
	nop
	nop
	nop

;	FA 00 00 00
	jp		m, 0x0000
	nop

;	FB 00 00 00
	ei
	nop
	nop
	nop

;	FC 00 00 00
	call	m, 0x0000
	nop

;	FD 00 00 00 (dummy)
	defb	0xFD
	nop
	nop
	nop

;	FE 00 00 00
	cp		a, 0x00
	nop
	nop

;	FF 00 00 00
	rst		0x38
	nop
	nop
	nop

;==============================================================================
;	DD 00 00 00		未定義
	defb	0xDD, 0x00, 0, 0

;	DD 01 00 00		未定義
	defb	0xDD, 0x01, 0, 0

;	DD 02 00 00		未定義
	defb	0xDD, 0x02, 0, 0

;	DD 03 00 00		未定義
	defb	0xDD, 0x03, 0, 0

;	DD 04 00 00		未定義
	defb	0xDD, 0x04, 0, 0

;	DD 05 00 00		未定義
	defb	0xDD, 0x05, 0, 0

;	DD 06 00 00		未定義
	defb	0xDD, 0x06, 0, 0

;	DD 07 00 00		未定義
	defb	0xDD, 0x07, 0, 0

;	DD 08 00 00		未定義
	defb	0xDD, 0x08, 0, 0

;	DD 09 00 00
	add		ix, bc
	nop
	nop

;	DD 0A 00 00		未定義
	defb	0xDD, 0x0A, 0, 0

;	DD 0B 00 00		未定義
	defb	0xDD, 0x0B, 0, 0

;	DD 0C 00 00		未定義
	defb	0xDD, 0x0C, 0, 0

;	DD 0D 00 00		未定義
	defb	0xDD, 0x0D, 0, 0

;	DD 0E 00 00		未定義
	defb	0xDD, 0x0E, 0, 0

;	DD 0F 00 00		未定義
	defb	0xDD, 0x0F, 0, 0

;	DD 10 00 00		未定義
	defb	0xDD, 0x10, 0, 0

;	DD 11 00 00		未定義
	defb	0xDD, 0x11, 0, 0

;	DD 12 00 00		未定義
	defb	0xDD, 0x12, 0, 0

;	DD 13 00 00		未定義
	defb	0xDD, 0x13, 0, 0

;	DD 14 00 00		未定義
	defb	0xDD, 0x14, 0, 0

;	DD 15 00 00		未定義
	defb	0xDD, 0x15, 0, 0

;	DD 16 00 00		未定義
	defb	0xDD, 0x16, 0, 0

;	DD 17 00 00		未定義
	defb	0xDD, 0x17, 0, 0

;	DD 18 00 00		未定義
	defb	0xDD, 0x18, 0, 0

;	DD 19 00 00
	add		ix, de
	nop
	nop

;	DD 1A 00 00		未定義
	defb	0xDD, 0x1A, 0, 0

;	DD 1B 00 00		未定義
	defb	0xDD, 0x1B, 0, 0

;	DD 1C 00 00		未定義
	defb	0xDD, 0x1C, 0, 0

;	DD 1D 00 00		未定義
	defb	0xDD, 0x1D, 0, 0

;	DD 1E 00 00		未定義
	defb	0xDD, 0x1E, 0, 0

;	DD 1F 00 00		未定義
	defb	0xDD, 0x1F, 0, 0

;	DD 20 00 00		未定義
	defb	0xDD, 0x20, 0, 0

;	DD 21 00 00
	ld		ix, 0x0000

;	DD 22 00 00
	ld		[0x0000], ix

;	DD 23 00 00
	inc		ix
	nop
	nop

;	DD 24 00 00
	inc		ixh
	nop
	nop

;	DD 25 00 00
	dec		ixh
	nop
	nop

;	DD 26 00 00
	ld		ixh, 0
	nop

;	DD 27 00 00		未定義
	defb	0xDD, 0x27, 0, 0

;	DD 28 00 00		未定義
	defb	0xDD, 0x28, 0, 0

;	DD 29 00 00
	add		ix, hl
	nop
	nop

;	DD 2A 00 00
	ld		ix, [0x0000]

;	DD 2B 00 00
	dec		ix
	nop
	nop

;	DD 2C 00 00
	inc		ixl
	nop
	nop

;	DD 2D 00 00
	dec		ixl
	nop
	nop

;	DD 2E 00 00
	ld		ixl, 0
	nop

;	DD 2F 00 00		未定義
	defb	0xDD, 0x2F, 0, 0

;	DD 30 00 00		未定義
	defb	0xDD, 0x30, 0, 0

;	DD 31 00 00		未定義
	defb	0xDD, 0x31, 0, 0

;	DD 32 00 00		未定義
	defb	0xDD, 0x32, 0, 0

;	DD 33 00 00		未定義
	defb	0xDD, 0x33, 0, 0

;	DD 34 00 00
	inc		[ix+0x00]
	nop

;	DD 35 00 00
	dec		[ix+0x00]
	nop

;	DD 36 00 00
	ld		[ix+0x00], 0x00

;	DD 37 00 00		未定義
	defb	0xDD, 0x37, 0, 0

;	DD 38 00 00		未定義
	defb	0xDD, 0x38, 0, 0

;	DD 39 00 00
	add		ix, sp
	nop
	nop

;	DD 3A 00 00		未定義
	defb	0xDD, 0x3A, 0, 0

;	DD 3B 00 00		未定義
	defb	0xDD, 0x3B, 0, 0

;	DD 3C 00 00		未定義
	defb	0xDD, 0x3C, 0, 0

;	DD 3D 00 00		未定義
	defb	0xDD, 0x3D, 0, 0

;	DD 3E 00 00		未定義
	defb	0xDD, 0x3E, 0, 0

;	DD 3F 00 00		未定義
	defb	0xDD, 0x3F, 0, 0

;	DD 40 00 00		未定義
	defb	0xDD, 0x40, 0, 0

;	DD 41 00 00		未定義
	defb	0xDD, 0x41, 0, 0

;	DD 42 00 00		未定義
	defb	0xDD, 0x42, 0, 0

;	DD 43 00 00		未定義
	defb	0xDD, 0x43, 0, 0

;	DD 44 00 00
	ld		b, ixh
	nop
	nop

;	DD 45 00 00
	ld		b, ixl
	nop
	nop

;	DD 46 00 00
	ld		b, [ix+0x00]
	nop

;	DD 47 00 00		未定義
	defb	0xDD, 0x47, 0, 0

;	DD 48 00 00		未定義
	defb	0xDD, 0x48, 0, 0

;	DD 49 00 00		未定義
	defb	0xDD, 0x49, 0, 0

;	DD 4A 00 00		未定義
	defb	0xDD, 0x4A, 0, 0

;	DD 4B 00 00		未定義
	defb	0xDD, 0x4B, 0, 0

;	DD 4C 00 00
	ld		c, ixh
	nop
	nop

;	DD 4D 00 00
	ld		c, ixl
	nop
	nop

;	DD 4E 00 00
	ld		c, [ix+0x00]
	nop

;	DD 4F 00 00		未定義
	defb	0xDD, 0x4F, 0, 0

;	DD 50 00 00		未定義
	defb	0xDD, 0x50, 0, 0

;	DD 51 00 00		未定義
	defb	0xDD, 0x51, 0, 0

;	DD 52 00 00		未定義
	defb	0xDD, 0x52, 0, 0

;	DD 53 00 00		未定義
	defb	0xDD, 0x53, 0, 0

;	DD 54 00 00
	ld		d, ixh
	nop
	nop

;	DD 55 00 00
	ld		d, ixl
	nop
	nop

;	DD 56 00 00
	ld		d, [ix+0x00]
	nop

;	DD 57 00 00		未定義
	defb	0xDD, 0x57, 0, 0

;	DD 58 00 00		未定義
	defb	0xDD, 0x58, 0, 0

;	DD 59 00 00		未定義
	defb	0xDD, 0x59, 0, 0

;	DD 5A 00 00		未定義
	defb	0xDD, 0x5A, 0, 0

;	DD 5B 00 00		未定義
	defb	0xDD, 0x5B, 0, 0

;	DD 5C 00 00
	ld		e, ixh
	nop
	nop

;	DD 5D 00 00
	ld		e, ixl
	nop
	nop

;	DD 5E 00 00
	ld		e, [ix+0x00]
	nop

;	DD 5F 00 00		未定義
	defb	0xDD, 0x5F, 0, 0

;	DD 60 00 00
	ld		ixh, b
	nop
	nop

;	DD 61 00 00
	ld		ixh, c
	nop
	nop

;	DD 62 00 00
	ld		ixh, d
	nop
	nop

;	DD 63 00 00
	ld		ixh, e
	nop
	nop

;	DD 64 00 00
	ld		ixh, h
	nop
	nop

;	DD 65 00 00
	ld		ixh, l
	nop
	nop

;	DD 66 00 00
	ld		h, [ix+0x00]
	nop

;	DD 67 00 00
	ld		ixh, a
	nop
	nop

;	DD 68 00 00
	ld		ixl, b
	nop
	nop

;	DD 69 00 00
	ld		ixl, c
	nop
	nop

;	DD 6A 00 00
	ld		ixl, d
	nop
	nop

;	DD 6B 00 00
	ld		ixl, e
	nop
	nop

;	DD 6C 00 00
	ld		ixl, h
	nop
	nop

;	DD 6D 00 00
	ld		ixl, l
	nop
	nop

;	DD 6E 00 00
	ld		l, [ix+0x00]
	nop

;	DD 6F 00 00
	ld		ixl, a
	nop
	nop

;	DD 70 00 00
	ld		[ix+0x00], b
	nop

;	DD 71 00 00
	ld		[ix+0x00], c
	nop

;	DD 72 00 00
	ld		[ix+0x00], d
	nop

;	DD 73 00 00
	ld		[ix+0x00], e
	nop

;	DD 74 00 00
	ld		[ix+0x00], h
	nop

;	DD 75 00 00
	ld		[ix+0x00], l
	nop

;	DD 76 00 00		未定義
	defb	0xDD, 0x76, 0, 0

;	DD 77 00 00
	ld		[ix+0x00], a
	nop

;	DD 78 00 00		未定義
	defb	0xDD, 0x78, 0, 0

;	DD 79 00 00		未定義
	defb	0xDD, 0x79, 0, 0

;	DD 7A 00 00		未定義
	defb	0xDD, 0x7A, 0, 0

;	DD 7B 00 00		未定義
	defb	0xDD, 0x7B, 0, 0

;	DD 7C 00 00
	ld		a, ixh
	nop
	nop

;	DD 7D 00 00
	ld		a, ixl
	nop
	nop

;	DD 7E 00 00
	ld		a, [ix+0x00]
	nop

;	DD 7F 00 00		未定義
	defb	0xDD, 0x7F, 0, 0

;	DD 80 00 00		未定義
	defb	0xDD, 0x80, 0, 0

;	DD 81 00 00		未定義
	defb	0xDD, 0x81, 0, 0

;	DD 82 00 00		未定義
	defb	0xDD, 0x82, 0, 0

;	DD 83 00 00		未定義
	defb	0xDD, 0x83, 0, 0

;	DD 84 00 00
	add		a, ixh
	nop
	nop

;	DD 85 00 00
	add		a, ixl
	nop
	nop

;	DD 86 00 00
	add		a, [ix+0x00]
	nop

;	DD 87 00 00		未定義
	defb	0xDD, 0x87, 0, 0

;	DD 88 00 00		未定義
	defb	0xDD, 0x88, 0, 0

;	DD 89 00 00		未定義
	defb	0xDD, 0x89, 0, 0

;	DD 8A 00 00		未定義
	defb	0xDD, 0x8A, 0, 0

;	DD 8B 00 00		未定義
	defb	0xDD, 0x8B, 0, 0

;	DD 8C 00 00
	adc		a, ixh
	nop
	nop

;	DD 8D 00 00
	adc		a, ixl
	nop
	nop

;	DD 8E 00 00
	adc		a, [ix+0x00]
	nop

;	DD 8F 00 00		未定義
	defb	0xDD, 0x8F, 0, 0

;	DD 90 00 00		未定義
	defb	0xDD, 0x90, 0, 0

;	DD 91 00 00		未定義
	defb	0xDD, 0x91, 0, 0

;	DD 92 00 00		未定義
	defb	0xDD, 0x92, 0, 0

;	DD 93 00 00		未定義
	defb	0xDD, 0x93, 0, 0

;	DD 94 00 00
	sub		a, ixh
	nop
	nop

;	DD 95 00 00
	sub		a, ixl
	nop
	nop

;	DD 96 00 00
	sub		a, [ix+0x00]
	nop

;	DD 97 00 00		未定義
	defb	0xDD, 0x97, 0, 0

;	DD 98 00 00		未定義
	defb	0xDD, 0x98, 0, 0

;	DD 99 00 00		未定義
	defb	0xDD, 0x99, 0, 0

;	DD 9A 00 00		未定義
	defb	0xDD, 0x9A, 0, 0

;	DD 9B 00 00		未定義
	defb	0xDD, 0x9B, 0, 0

;	DD 9C 00 00
	sbc		a, ixh
	nop
	nop

;	DD 9D 00 00
	sbc		a, ixl
	nop
	nop

;	DD 9E 00 00
	sbc		a, [ix+0x00]
	nop

;	DD 9F 00 00		未定義
	defb	0xDD, 0x9F, 0, 0

;	DD A0 00 00		未定義
	defb	0xDD, 0xA0, 0, 0

;	DD A1 00 00		未定義
	defb	0xDD, 0xA1, 0, 0

;	DD A2 00 00		未定義
	defb	0xDD, 0xA2, 0, 0

;	DD A3 00 00		未定義
	defb	0xDD, 0xA3, 0, 0

;	DD A4 00 00
	and		a, ixh
	nop
	nop

;	DD A5 00 00
	and		a, ixl
	nop
	nop

;	DD A6 00 00
	and		a, [ix+0x00]
	nop

;	DD A7 00 00		未定義
	defb	0xDD, 0xA7, 0, 0

;	DD A8 00 00		未定義
	defb	0xDD, 0xA8, 0, 0

;	DD A9 00 00		未定義
	defb	0xDD, 0xA9, 0, 0

;	DD AA 00 00		未定義
	defb	0xDD, 0xAA, 0, 0

;	DD AB 00 00		未定義
	defb	0xDD, 0xAB, 0, 0

;	DD AC 00 00
	xor		a, ixh
	nop
	nop

;	DD AD 00 00
	xor		a, ixl
	nop
	nop

;	DD AE 00 00
	xor		a, [ix+0x00]
	nop

;	DD AF 00 00		未定義
	defb	0xDD, 0xAF, 0, 0

;	DD B0 00 00		未定義
	defb	0xDD, 0xB0, 0, 0

;	DD B1 00 00		未定義
	defb	0xDD, 0xB1, 0, 0

;	DD B2 00 00		未定義
	defb	0xDD, 0xB2, 0, 0

;	DD B3 00 00		未定義
	defb	0xDD, 0xB3, 0, 0

;	DD B4 00 00
	or		a, ixh
	nop
	nop

;	DD B5 00 00
	or		a, ixl
	nop
	nop

;	DD B6 00 00
	or		a, [ix+0x00]
	nop

;	DD B7 00 00		未定義
	defb	0xDD, 0xB7, 0, 0

;	DD B8 00 00		未定義
	defb	0xDD, 0xB8, 0, 0

;	DD B9 00 00		未定義
	defb	0xDD, 0xB9, 0, 0

;	DD BA 00 00		未定義
	defb	0xDD, 0xBA, 0, 0

;	DD BB 00 00		未定義
	defb	0xDD, 0xBB, 0, 0

;	DD BC 00 00
	cp		a, ixh
	nop
	nop

;	DD BD 00 00
	cp		a, ixl
	nop
	nop

;	DD BE 00 00
	cp		a, [ix+0x00]
	nop

;	DD BF 00 00		未定義
	defb	0xDD, 0xBF, 0, 0

;	DD C0 00 00		未定義
	defb	0xDD, 0xC0, 0, 0

;	DD C1 00 00		未定義
	defb	0xDD, 0xC1, 0, 0

;	DD C2 00 00		未定義
	defb	0xDD, 0xC2, 0, 0

;	DD C3 00 00		未定義
	defb	0xDD, 0xC3, 0, 0

;	DD C4 00 00		未定義
	defb	0xDD, 0xC4, 0, 0

;	DD C5 00 00		未定義
	defb	0xDD, 0xC5, 0, 0

;	DD C6 00 00		未定義
	defb	0xDD, 0xC6, 0, 0

;	DD C7 00 00		未定義
	defb	0xDD, 0xC7, 0, 0

;	DD C8 00 00		未定義
	defb	0xDD, 0xC8, 0, 0

;	DD C9 00 00		未定義
	defb	0xDD, 0xC9, 0, 0

;	DD CA 00 00		未定義
	defb	0xDD, 0xCA, 0, 0

;	DD CB 00 00 (dummy)
	defb	0xDD, 0xCB, 0, 0

;	DD CC 00 00		未定義
	defb	0xDD, 0xCC, 0, 0

;	DD CD 00 00		未定義
	defb	0xDD, 0xCD, 0, 0

;	DD CE 00 00		未定義
	defb	0xDD, 0xCE, 0, 0

;	DD CF 00 00		未定義
	defb	0xDD, 0xCF, 0, 0

;	DD D0 00 00		未定義
	defb	0xDD, 0xD0, 0, 0

;	DD D1 00 00		未定義
	defb	0xDD, 0xD1, 0, 0

;	DD D2 00 00		未定義
	defb	0xDD, 0xD2, 0, 0

;	DD D3 00 00		未定義
	defb	0xDD, 0xD3, 0, 0

;	DD D4 00 00		未定義
	defb	0xDD, 0xD4, 0, 0

;	DD D5 00 00		未定義
	defb	0xDD, 0xD5, 0, 0

;	DD D6 00 00		未定義
	defb	0xDD, 0xD6, 0, 0

;	DD D7 00 00		未定義
	defb	0xDD, 0xD7, 0, 0

;	DD D8 00 00		未定義
	defb	0xDD, 0xD8, 0, 0

;	DD D9 00 00		未定義
	defb	0xDD, 0xD9, 0, 0

;	DD DA 00 00		未定義
	defb	0xDD, 0xDA, 0, 0

;	DD DB 00 00		未定義
	defb	0xDD, 0xDB, 0, 0

;	DD DC 00 00		未定義
	defb	0xDD, 0xDC, 0, 0

;	DD DD 00 00		未定義
	defb	0xDD, 0xDD, 0, 0

;	DD DE 00 00		未定義
	defb	0xDD, 0xDE, 0, 0

;	DD DF 00 00		未定義
	defb	0xDD, 0xDF, 0, 0

;	DD E0 00 00		未定義
	defb	0xDD, 0xE0, 0, 0

;	DD E1 00 00
	pop		ix
	nop
	nop

;	DD E2 00 00		未定義
	defb	0xDD, 0xE2, 0, 0

;	DD E3 00 00
	ex		[sp], ix
	nop
	nop

;	DD E4 00 00		未定義
	defb	0xDD, 0xE4, 0, 0

;	DD E5 00 00
	push	ix
	nop
	nop

;	DD E6 00 00		未定義
	defb	0xDD, 0xE6, 0, 0

;	DD E7 00 00		未定義
	defb	0xDD, 0xE7, 0, 0

;	DD E8 00 00		未定義
	defb	0xDD, 0xE8, 0, 0

;	DD E9 00 00
	jp		ix
	nop
	nop

;	DD EA 00 00		未定義
	defb	0xDD, 0xEA, 0, 0

;	DD EB 00 00		未定義
	defb	0xDD, 0xEB, 0, 0

;	DD EC 00 00		未定義
	defb	0xDD, 0xEC, 0, 0

;	DD ED 00 00		未定義
	defb	0xDD, 0xED, 0, 0

;	DD EE 00 00		未定義
	defb	0xDD, 0xEE, 0, 0

;	DD EF 00 00		未定義
	defb	0xDD, 0xEF, 0, 0

;	DD F0 00 00		未定義
	defb	0xDD, 0xF0, 0, 0

;	DD F1 00 00		未定義
	defb	0xDD, 0xF1, 0, 0

;	DD F2 00 00		未定義
	defb	0xDD, 0xF2, 0, 0

;	DD F3 00 00		未定義
	defb	0xDD, 0xF3, 0, 0

;	DD F4 00 00		未定義
	defb	0xDD, 0xF4, 0, 0

;	DD F5 00 00		未定義
	defb	0xDD, 0xF5, 0, 0

;	DD F6 00 00		未定義
	defb	0xDD, 0xF6, 0, 0

;	DD F7 00 00		未定義
	defb	0xDD, 0xF7, 0, 0

;	DD F8 00 00		未定義
	defb	0xDD, 0xF8, 0, 0

;	DD F9 00 00
	ld		sp, ix
	nop
	nop

;	DD FA 00 00		未定義
	defb	0xDD, 0xFA, 0, 0

;	DD FB 00 00		未定義
	defb	0xDD, 0xFB, 0, 0

;	DD FC 00 00		未定義
	defb	0xDD, 0xFC, 0, 0

;	DD FD 00 00		未定義
	defb	0xDD, 0xFD, 0, 0

;	DD FE 00 00		未定義
	defb	0xDD, 0xFE, 0, 0

;	DD FF 00 00		未定義
	defb	0xDD, 0xFF, 0, 0


;==============================================================================
;	FD 00 00 00		未定義
	defb	0xFD, 0x00, 0, 0

;	FD 01 00 00		未定義
	defb	0xFD, 0x01, 0, 0

;	FD 02 00 00		未定義
	defb	0xFD, 0x02, 0, 0

;	FD 03 00 00		未定義
	defb	0xFD, 0x03, 0, 0

;	FD 04 00 00		未定義
	defb	0xFD, 0x04, 0, 0

;	FD 05 00 00		未定義
	defb	0xFD, 0x05, 0, 0

;	FD 06 00 00		未定義
	defb	0xFD, 0x06, 0, 0

;	FD 07 00 00		未定義
	defb	0xFD, 0x07, 0, 0

;	FD 08 00 00		未定義
	defb	0xFD, 0x08, 0, 0

;	FD 09 00 00
	add		iy, bc
	nop
	nop

;	FD 0A 00 00		未定義
	defb	0xFD, 0x0A, 0, 0

;	FD 0B 00 00		未定義
	defb	0xFD, 0x0B, 0, 0

;	FD 0C 00 00		未定義
	defb	0xFD, 0x0C, 0, 0

;	FD 0D 00 00		未定義
	defb	0xFD, 0x0D, 0, 0

;	FD 0E 00 00		未定義
	defb	0xFD, 0x0E, 0, 0

;	FD 0F 00 00		未定義
	defb	0xFD, 0x0F, 0, 0

;	FD 10 00 00		未定義
	defb	0xFD, 0x10, 0, 0

;	FD 11 00 00		未定義
	defb	0xFD, 0x11, 0, 0

;	FD 12 00 00		未定義
	defb	0xFD, 0x12, 0, 0

;	FD 13 00 00		未定義
	defb	0xFD, 0x13, 0, 0

;	FD 14 00 00		未定義
	defb	0xFD, 0x14, 0, 0

;	FD 15 00 00		未定義
	defb	0xFD, 0x15, 0, 0

;	FD 16 00 00		未定義
	defb	0xFD, 0x16, 0, 0

;	FD 17 00 00		未定義
	defb	0xFD, 0x17, 0, 0

;	FD 18 00 00		未定義
	defb	0xFD, 0x18, 0, 0

;	FD 19 00 00
	add		iy, de
	nop
	nop

;	FD 1A 00 00		未定義
	defb	0xFD, 0x1A, 0, 0

;	FD 1B 00 00		未定義
	defb	0xFD, 0x1B, 0, 0

;	FD 1C 00 00		未定義
	defb	0xFD, 0x1C, 0, 0

;	FD 1D 00 00		未定義
	defb	0xFD, 0x1D, 0, 0

;	FD 1E 00 00		未定義
	defb	0xFD, 0x1E, 0, 0

;	FD 1F 00 00		未定義
	defb	0xFD, 0x1F, 0, 0

;	FD 20 00 00		未定義
	defb	0xFD, 0x20, 0, 0

;	FD 21 00 00
	ld		iy, 0x0000

;	FD 22 00 00
	ld		[0x0000], iy

;	FD 23 00 00
	inc		iy
	nop
	nop

;	FD 24 00 00
	inc		iyh
	nop
	nop

;	FD 25 00 00
	dec		iyh
	nop
	nop

;	FD 26 00 00
	ld		iyh, 0
	nop

;	FD 27 00 00		未定義
	defb	0xFD, 0x27, 0, 0

;	FD 28 00 00		未定義
	defb	0xFD, 0x28, 0, 0

;	FD 29 00 00
	add		iy, hl
	nop
	nop

;	FD 2A 00 00
	ld		iy, [0x0000]

;	FD 2B 00 00
	dec		iy
	nop
	nop

;	FD 2C 00 00
	inc		iyl
	nop
	nop

;	FD 2D 00 00
	dec		iyl
	nop
	nop

;	FD 2E 00 00
	ld		iyl, 0
	nop

;	FD 2F 00 00		未定義
	defb	0xFD, 0x2F, 0, 0

;	FD 30 00 00		未定義
	defb	0xFD, 0x30, 0, 0

;	FD 31 00 00		未定義
	defb	0xFD, 0x31, 0, 0

;	FD 32 00 00		未定義
	defb	0xFD, 0x32, 0, 0

;	FD 33 00 00		未定義
	defb	0xFD, 0x33, 0, 0

;	FD 34 00 00
	inc		[iy+0x00]
	nop

;	FD 35 00 00
	dec		[iy+0x00]
	nop

;	FD 36 00 00
	ld		[iy+0x00], 0x00

;	FD 37 00 00		未定義
	defb	0xFD, 0x37, 0, 0

;	FD 38 00 00		未定義
	defb	0xFD, 0x38, 0, 0

;	FD 39 00 00
	add		iy, sp
	nop
	nop

;	FD 3A 00 00		未定義
	defb	0xFD, 0x3A, 0, 0

;	FD 3B 00 00		未定義
	defb	0xFD, 0x3B, 0, 0

;	FD 3C 00 00		未定義
	defb	0xFD, 0x3C, 0, 0

;	FD 3D 00 00		未定義
	defb	0xFD, 0x3D, 0, 0

;	FD 3E 00 00		未定義
	defb	0xFD, 0x3E, 0, 0

;	FD 3F 00 00		未定義
	defb	0xFD, 0x3F, 0, 0

;	FD 40 00 00		未定義
	defb	0xFD, 0x40, 0, 0

;	FD 41 00 00		未定義
	defb	0xFD, 0x41, 0, 0

;	FD 42 00 00		未定義
	defb	0xFD, 0x42, 0, 0

;	FD 43 00 00		未定義
	defb	0xFD, 0x43, 0, 0

;	FD 44 00 00
	ld		b, iyh
	nop
	nop

;	FD 45 00 00
	ld		b, iyl
	nop
	nop

;	FD 46 00 00
	ld		b, [iy+0x00]
	nop

;	FD 47 00 00		未定義
	defb	0xFD, 0x47, 0, 0

;	FD 48 00 00		未定義
	defb	0xFD, 0x48, 0, 0

;	FD 49 00 00		未定義
	defb	0xFD, 0x49, 0, 0

;	FD 4A 00 00		未定義
	defb	0xFD, 0x4A, 0, 0

;	FD 4B 00 00		未定義
	defb	0xFD, 0x4B, 0, 0

;	FD 4C 00 00
	ld		c, iyh
	nop
	nop

;	FD 4D 00 00
	ld		c, iyl
	nop
	nop

;	FD 4E 00 00
	ld		c, [iy+0x00]
	nop

;	FD 4F 00 00		未定義
	defb	0xFD, 0x4F, 0, 0

;	FD 50 00 00		未定義
	defb	0xFD, 0x50, 0, 0

;	FD 51 00 00		未定義
	defb	0xFD, 0x51, 0, 0

;	FD 52 00 00		未定義
	defb	0xFD, 0x52, 0, 0

;	FD 53 00 00		未定義
	defb	0xFD, 0x53, 0, 0

;	FD 54 00 00
	ld		d, iyh
	nop
	nop

;	FD 55 00 00
	ld		d, iyl
	nop
	nop

;	FD 56 00 00
	ld		d, [iy+0x00]
	nop

;	FD 57 00 00		未定義
	defb	0xFD, 0x57, 0, 0

;	FD 58 00 00		未定義
	defb	0xFD, 0x58, 0, 0

;	FD 59 00 00		未定義
	defb	0xFD, 0x59, 0, 0

;	FD 5A 00 00		未定義
	defb	0xFD, 0x5A, 0, 0

;	FD 5B 00 00		未定義
	defb	0xFD, 0x5B, 0, 0

;	FD 5C 00 00
	ld		e, iyh
	nop
	nop

;	FD 5D 00 00
	ld		e, iyl
	nop
	nop

;	FD 5E 00 00
	ld		e, [iy+0x00]
	nop

;	FD 5F 00 00		未定義
	defb	0xFD, 0x5F, 0, 0

;	FD 60 00 00
	ld		iyh, b
	nop
	nop

;	FD 61 00 00
	ld		iyh, c
	nop
	nop

;	FD 62 00 00
	ld		iyh, d
	nop
	nop

;	FD 63 00 00
	ld		iyh, e
	nop
	nop

;	FD 64 00 00
	ld		iyh, h
	nop
	nop

;	FD 65 00 00
	ld		iyh, l
	nop
	nop

;	FD 66 00 00
	ld		h, [iy+0x00]
	nop

;	FD 67 00 00
	ld		iyh, a
	nop
	nop

;	FD 68 00 00
	ld		iyl, b
	nop
	nop

;	FD 69 00 00
	ld		iyl, c
	nop
	nop

;	FD 6A 00 00
	ld		iyl, d
	nop
	nop

;	FD 6B 00 00
	ld		iyl, e
	nop
	nop

;	FD 6C 00 00
	ld		iyl, h
	nop
	nop

;	FD 6D 00 00
	ld		iyl, l
	nop
	nop

;	FD 6E 00 00
	ld		l, [iy+0x00]
	nop

;	FD 6F 00 00
	ld		iyl, a
	nop
	nop

;	FD 70 00 00
	ld		[iy+0x00], b
	nop

;	FD 71 00 00
	ld		[iy+0x00], c
	nop

;	FD 72 00 00
	ld		[iy+0x00], d
	nop

;	FD 73 00 00
	ld		[iy+0x00], e
	nop

;	FD 74 00 00
	ld		[iy+0x00], h
	nop

;	FD 75 00 00
	ld		[iy+0x00], l
	nop

;	FD 76 00 00		未定義
	defb	0xFD, 0x76, 0, 0

;	FD 77 00 00
	ld		[iy+0x00], a
	nop

;	FD 78 00 00		未定義
	defb	0xFD, 0x78, 0, 0

;	FD 79 00 00		未定義
	defb	0xFD, 0x79, 0, 0

;	FD 7A 00 00		未定義
	defb	0xFD, 0x7A, 0, 0

;	FD 7B 00 00		未定義
	defb	0xFD, 0x7B, 0, 0

;	FD 7C 00 00
	ld		a, iyh
	nop
	nop

;	FD 7D 00 00
	ld		a, iyl
	nop
	nop

;	FD 7E 00 00
	ld		a, [iy+0x00]
	nop

;	FD 7F 00 00		未定義
	defb	0xFD, 0x7F, 0, 0

;	FD 80 00 00		未定義
	defb	0xFD, 0x80, 0, 0

;	FD 81 00 00		未定義
	defb	0xFD, 0x81, 0, 0

;	FD 82 00 00		未定義
	defb	0xFD, 0x82, 0, 0

;	FD 83 00 00		未定義
	defb	0xFD, 0x83, 0, 0

;	FD 84 00 00
	add		a, iyh
	nop
	nop

;	FD 85 00 00
	add		a, iyl
	nop
	nop

;	FD 86 00 00
	add		a, [iy+0x00]
	nop

;	FD 87 00 00		未定義
	defb	0xFD, 0x87, 0, 0

;	FD 88 00 00		未定義
	defb	0xFD, 0x88, 0, 0

;	FD 89 00 00		未定義
	defb	0xFD, 0x89, 0, 0

;	FD 8A 00 00		未定義
	defb	0xFD, 0x8A, 0, 0

;	FD 8B 00 00		未定義
	defb	0xFD, 0x8B, 0, 0

;	FD 8C 00 00
	adc		a, iyh
	nop
	nop

;	FD 8D 00 00
	adc		a, iyl
	nop
	nop

;	FD 8E 00 00
	adc		a, [iy+0x00]
	nop

;	FD 8F 00 00		未定義
	defb	0xFD, 0x8F, 0, 0

;	FD 90 00 00		未定義
	defb	0xFD, 0x90, 0, 0

;	FD 91 00 00		未定義
	defb	0xFD, 0x91, 0, 0

;	FD 92 00 00		未定義
	defb	0xFD, 0x92, 0, 0

;	FD 93 00 00		未定義
	defb	0xFD, 0x93, 0, 0

;	FD 94 00 00
	sub		a, iyh
	nop
	nop

;	FD 95 00 00
	sub		a, iyl
	nop
	nop

;	FD 96 00 00
	sub		a, [iy+0x00]
	nop

;	FD 97 00 00		未定義
	defb	0xFD, 0x97, 0, 0

;	FD 98 00 00		未定義
	defb	0xFD, 0x98, 0, 0

;	FD 99 00 00		未定義
	defb	0xFD, 0x99, 0, 0

;	FD 9A 00 00		未定義
	defb	0xFD, 0x9A, 0, 0

;	FD 9B 00 00		未定義
	defb	0xFD, 0x9B, 0, 0

;	FD 9C 00 00
	sbc		a, iyh
	nop
	nop

;	FD 9D 00 00
	sbc		a, iyl
	nop
	nop

;	FD 9E 00 00
	sbc		a, [iy+0x00]
	nop

;	FD 9F 00 00		未定義
	defb	0xFD, 0x9F, 0, 0

;	FD A0 00 00		未定義
	defb	0xFD, 0xA0, 0, 0

;	FD A1 00 00		未定義
	defb	0xFD, 0xA1, 0, 0

;	FD A2 00 00		未定義
	defb	0xFD, 0xA2, 0, 0

;	FD A3 00 00		未定義
	defb	0xFD, 0xA3, 0, 0

;	FD A4 00 00
	and		a, iyh
	nop
	nop

;	FD A5 00 00
	and		a, iyl
	nop
	nop

;	FD A6 00 00
	and		a, [iy+0x00]
	nop

;	FD A7 00 00		未定義
	defb	0xFD, 0x97, 0, 0

;	FD A8 00 00		未定義
	defb	0xFD, 0x98, 0, 0

;	FD A9 00 00		未定義
	defb	0xFD, 0x99, 0, 0

;	FD AA 00 00		未定義
	defb	0xFD, 0x9A, 0, 0

;	FD AB 00 00		未定義
	defb	0xFD, 0x9B, 0, 0

;	FD AC 00 00
	xor		a, iyh
	nop
	nop

;	FD AD 00 00
	xor		a, iyl
	nop
	nop

;	FD AE 00 00
	xor		a, [iy+0x00]
	nop

;	FD AF 00 00		未定義
	defb	0xFD, 0xAF, 0, 0

;	FD B0 00 00		未定義
	defb	0xFD, 0xB0, 0, 0

;	FD B1 00 00		未定義
	defb	0xFD, 0xB1, 0, 0

;	FD B2 00 00		未定義
	defb	0xFD, 0xB2, 0, 0

;	FD B3 00 00		未定義
	defb	0xFD, 0xB3, 0, 0

;	FD B4 00 00
	or		a, iyh
	nop
	nop

;	FD B5 00 00
	or		a, iyl
	nop
	nop

;	FD B6 00 00
	or		a, [iy+0x00]
	nop

;	FD B7 00 00		未定義
	defb	0xFD, 0x97, 0, 0

;	FD B8 00 00		未定義
	defb	0xFD, 0x98, 0, 0

;	FD B9 00 00		未定義
	defb	0xFD, 0x99, 0, 0

;	FD BA 00 00		未定義
	defb	0xFD, 0x9A, 0, 0

;	FD BB 00 00		未定義
	defb	0xFD, 0x9B, 0, 0

;	FD BC 00 00
	cp		a, iyh
	nop
	nop

;	FD BD 00 00
	cp		a, iyl
	nop
	nop

;	FD BE 00 00
	cp		a, [iy+0x00]
	nop

;	FD BF 00 00		未定義
	defb	0xFD, 0xBF, 0, 0

;	FD C0 00 00		未定義
	defb	0xFD, 0xC0, 0, 0

;	FD C1 00 00		未定義
	defb	0xFD, 0xC1, 0, 0

;	FD C2 00 00		未定義
	defb	0xFD, 0xC2, 0, 0

;	FD C3 00 00		未定義
	defb	0xFD, 0xC3, 0, 0

;	FD C4 00 00		未定義
	defb	0xFD, 0xC4, 0, 0

;	FD C5 00 00		未定義
	defb	0xFD, 0xC5, 0, 0

;	FD C6 00 00		未定義
	defb	0xFD, 0xC6, 0, 0

;	FD C7 00 00		未定義
	defb	0xFD, 0xC7, 0, 0

;	FD C8 00 00		未定義
	defb	0xFD, 0xC8, 0, 0

;	FD C9 00 00		未定義
	defb	0xFD, 0xC9, 0, 0

;	FD CA 00 00		未定義
	defb	0xFD, 0xCA, 0, 0

;	FD CB 00 00 (dummy)
	defb	0xFD, 0xCB, 0, 0

;	FD CC 00 00		未定義
	defb	0xFD, 0xCC, 0, 0

;	FD CD 00 00		未定義
	defb	0xFD, 0xCD, 0, 0

;	FD CE 00 00		未定義
	defb	0xFD, 0xCE, 0, 0

;	FD CF 00 00		未定義
	defb	0xFD, 0xCF, 0, 0

;	FD E0 00 00		未定義
	defb	0xFD, 0xE0, 0, 0

;	FD E1 00 00
	pop		iy
	nop
	nop

;	FD E2 00 00		未定義
	defb	0xFD, 0xE2, 0, 0

;	FD E3 00 00
	ex		[sp], iy
	nop
	nop

;	FD E4 00 00		未定義
	defb	0xFD, 0xE4, 0, 0

;	FD E5 00 00
	push	iy
	nop
	nop

;	FD E6 00 00		未定義
	defb	0xFD, 0xE6, 0, 0

;	FD E7 00 00		未定義
	defb	0xFD, 0xE7, 0, 0

;	FD E8 00 00		未定義
	defb	0xFD, 0xE8, 0, 0

;	FD E9 00 00
	jp		iy
	nop
	nop

;	FD EA 00 00		未定義
	defb	0xFD, 0xEA, 0, 0

;	FD EB 00 00		未定義
	defb	0xFD, 0xEB, 0, 0

;	FD EC 00 00		未定義
	defb	0xFD, 0xEC, 0, 0

;	FD ED 00 00		未定義
	defb	0xFD, 0xED, 0, 0

;	FD EE 00 00		未定義
	defb	0xFD, 0xEE, 0, 0

;	FD EF 00 00		未定義
	defb	0xFD, 0xEF, 0, 0

;	FD F0 00 00		未定義
	defb	0xFD, 0xF0, 0, 0

;	FD F1 00 00		未定義
	defb	0xFD, 0xF1, 0, 0

;	FD F2 00 00		未定義
	defb	0xFD, 0xF2, 0, 0

;	FD F3 00 00		未定義
	defb	0xFD, 0xF3, 0, 0

;	FD F4 00 00		未定義
	defb	0xFD, 0xF4, 0, 0

;	FD F5 00 00		未定義
	defb	0xFD, 0xF5, 0, 0

;	FD F6 00 00		未定義
	defb	0xFD, 0xF6, 0, 0

;	FD F7 00 00		未定義
	defb	0xFD, 0xF7, 0, 0

;	FD F8 00 00		未定義
	defb	0xFD, 0xF8, 0, 0

;	FD F9 00 00
	ld		sp, iy
	nop
	nop

;	FD FA 00 00		未定義
	defb	0xFD, 0xFA, 0, 0

;	FD FB 00 00		未定義
	defb	0xFD, 0xFB, 0, 0

;	FD FC 00 00		未定義
	defb	0xFD, 0xFC, 0, 0

;	FD FD 00 00		未定義
	defb	0xFD, 0xFD, 0, 0

;	FD FE 00 00		未定義
	defb	0xFD, 0xFE, 0, 0

;	FD FF 00 00		未定義
	defb	0xFD, 0xFF, 0, 0

;==============================================================================
;	ED 00 00 00		未定義
	defb	0xED, 0x00, 0, 0

;	ED 01 00 00		未定義
	defb	0xED, 0x01, 0, 0

;	ED 02 00 00		未定義
	defb	0xED, 0x02, 0, 0

;	ED 03 00 00		未定義
	defb	0xED, 0x03, 0, 0

;	ED 04 00 00		未定義
	defb	0xED, 0x04, 0, 0

;	ED 05 00 00		未定義
	defb	0xED, 0x05, 0, 0

;	ED 06 00 00		未定義
	defb	0xED, 0x06, 0, 0

;	ED 07 00 00		未定義
	defb	0xED, 0x07, 0, 0

;	ED 08 00 00		未定義
	defb	0xED, 0x08, 0, 0

;	ED 09 00 00		未定義
	defb	0xED, 0x09, 0, 0

;	ED 0A 00 00		未定義
	defb	0xED, 0x0A, 0, 0

;	ED 0B 00 00		未定義
	defb	0xED, 0x0B, 0, 0

;	ED 0C 00 00		未定義
	defb	0xED, 0x0C, 0, 0

;	ED 0D 00 00		未定義
	defb	0xED, 0x0D, 0, 0

;	ED 0E 00 00		未定義
	defb	0xED, 0x0E, 0, 0

;	ED 0F 00 00		未定義
	defb	0xED, 0x0F, 0, 0

;	ED 10 00 00		未定義
	defb	0xED, 0x10, 0, 0

;	ED 11 00 00		未定義
	defb	0xED, 0x11, 0, 0

;	ED 12 00 00		未定義
	defb	0xED, 0x12, 0, 0

;	ED 13 00 00		未定義
	defb	0xED, 0x13, 0, 0

;	ED 14 00 00		未定義
	defb	0xED, 0x14, 0, 0

;	ED 15 00 00		未定義
	defb	0xED, 0x15, 0, 0

;	ED 16 00 00		未定義
	defb	0xED, 0x16, 0, 0

;	ED 17 00 00		未定義
	defb	0xED, 0x17, 0, 0

;	ED 18 00 00		未定義
	defb	0xED, 0x18, 0, 0

;	ED 19 00 00		未定義
	defb	0xED, 0x19, 0, 0

;	ED 1A 00 00		未定義
	defb	0xED, 0x1A, 0, 0

;	ED 1B 00 00		未定義
	defb	0xED, 0x1B, 0, 0

;	ED 1C 00 00		未定義
	defb	0xED, 0x1C, 0, 0

;	ED 1D 00 00		未定義
	defb	0xED, 0x1D, 0, 0

;	ED 1E 00 00		未定義
	defb	0xED, 0x1E, 0, 0

;	ED 1F 00 00		未定義
	defb	0xED, 0x1F, 0, 0

;	ED 20 00 00		未定義
	defb	0xED, 0x20, 0, 0

;	ED 21 00 00		未定義
	defb	0xED, 0x21, 0, 0

;	ED 22 00 00		未定義
	defb	0xED, 0x22, 0, 0

;	ED 23 00 00		未定義
	defb	0xED, 0x23, 0, 0

;	ED 24 00 00		未定義
	defb	0xED, 0x24, 0, 0

;	ED 25 00 00		未定義
	defb	0xED, 0x25, 0, 0

;	ED 26 00 00		未定義
	defb	0xED, 0x26, 0, 0

;	ED 27 00 00		未定義
	defb	0xED, 0x27, 0, 0

;	ED 28 00 00		未定義
	defb	0xED, 0x28, 0, 0

;	ED 29 00 00		未定義
	defb	0xED, 0x29, 0, 0

;	ED 2A 00 00		未定義
	defb	0xED, 0x2A, 0, 0

;	ED 2B 00 00		未定義
	defb	0xED, 0x2B, 0, 0

;	ED 2C 00 00		未定義
	defb	0xED, 0x2C, 0, 0

;	ED 2D 00 00		未定義
	defb	0xED, 0x2D, 0, 0

;	ED 2E 00 00		未定義
	defb	0xED, 0x2E, 0, 0

;	ED 2F 00 00		未定義
	defb	0xED, 0x2F, 0, 0

;	ED 30 00 00		未定義
	defb	0xED, 0x30, 0, 0

;	ED 31 00 00		未定義
	defb	0xED, 0x31, 0, 0

;	ED 32 00 00		未定義
	defb	0xED, 0x32, 0, 0

;	ED 33 00 00		未定義
	defb	0xED, 0x33, 0, 0

;	ED 34 00 00		未定義
	defb	0xED, 0x34, 0, 0

;	ED 35 00 00		未定義
	defb	0xED, 0x35, 0, 0

;	ED 36 00 00		未定義
	defb	0xED, 0x36, 0, 0

;	ED 37 00 00		未定義
	defb	0xED, 0x37, 0, 0

;	ED 38 00 00		未定義
	defb	0xED, 0x38, 0, 0

;	ED 39 00 00		未定義
	defb	0xED, 0x39, 0, 0

;	ED 3A 00 00		未定義
	defb	0xED, 0x3A, 0, 0

;	ED 3B 00 00		未定義
	defb	0xED, 0x3B, 0, 0

;	ED 3C 00 00		未定義
	defb	0xED, 0x3C, 0, 0

;	ED 3D 00 00		未定義
	defb	0xED, 0x3D, 0, 0

;	ED 3E 00 00		未定義
	defb	0xED, 0x3E, 0, 0

;	ED 3F 00 00		未定義
	defb	0xED, 0x3F, 0, 0

;	ED 40 00 00
	in		b, [c]
	nop
	nop

;	ED 41 00 00
	out		[c], b
	nop
	nop

;	ED 42 00 00
	sbc		hl, bc
	nop
	nop

;	ED 43 00 00
	ld		[0x0000], bc

;	ED 44 00 00
	neg
	nop
	nop

;	ED 45 00 00
	retn
	nop
	nop

;	ED 46 00 00
	im0
	nop
	nop

;	ED 47 00 00
	ld		i, a
	nop
	nop

;	ED 48 00 00
	in		c, [c]
	nop
	nop

;	ED 49 00 00
	out		[c], c
	nop
	nop

;	ED 4A 00 00
	adc		hl, bc
	nop
	nop

;	ED 4B 00 00
	ld		bc, [0x0000]

;	ED 4C 00 00		未定義
	defb	0xED, 0x4C, 0, 0

;	ED 4D 00 00
	reti
	nop
	nop

;	ED 4E 00 00		未定義
	defb	0xED, 0x4E, 0, 0

;	ED 4F 00 00
	ld		r, a
	nop
	nop

;	ED 50 00 00
	in		d, [c]
	nop
	nop

;	ED 51 00 00
	out		[c], d
	nop
	nop

;	ED 52 00 00
	sbc		hl, de
	nop
	nop

;	ED 53 00 00
	ld		[0x0000], de

;	ED 54 00 00		未定義
	defb	0xED, 0x54, 0, 0

;	ED 55 00 00		未定義
	defb	0xED, 0x55, 0, 0

;	ED 56 00 00
	im1
	nop
	nop

;	ED 57 00 00
	ld		a, i
	nop
	nop

;	ED 58 00 00
	in		e, [c]
	nop
	nop

;	ED 59 00 00
	out		[c], e
	nop
	nop

;	ED 5A 00 00
	adc		hl, de
	nop
	nop

;	ED 5B 00 00
	ld		de, [0x0000]

;	ED 5C 00 00		未定義
	defb	0xED, 0x5C, 0, 0

;	ED 5D 00 00		未定義
	defb	0xED, 0x5D, 0, 0

;	ED 5E 00 00
	im2
	nop
	nop

;	ED 5F 00 00
	ld		a, r
	nop
	nop

;	ED 60 00 00
	in		h, [c]
	nop
	nop

;	ED 61 00 00
	out		[c], h
	nop
	nop

;	ED 62 00 00
	sbc		hl, hl
	nop
	nop

;	ED 63 00 00		未定義
	defb	0xED, 0x63, 0, 0

;	ED 64 00 00		未定義
	defb	0xED, 0x64, 0, 0

;	ED 65 00 00		未定義
	defb	0xED, 0x65, 0, 0

;	ED 66 00 00		未定義
	defb	0xED, 0x66, 0, 0

;	ED 67 00 00
	rrd
	nop
	nop

;	ED 68 00 00
	in		l, [c]
	nop
	nop

;	ED 69 00 00
	out		[c], l
	nop
	nop

;	ED 6A 00 00
	adc		hl, hl
	nop
	nop

;	ED 6B 00 00		未定義
	defb	0xED, 0x6B, 0, 0

;	ED 6C 00 00		未定義
	defb	0xED, 0x6C, 0, 0

;	ED 6D 00 00		未定義
	defb	0xED, 0x6D, 0, 0

;	ED 6E 00 00		未定義
	defb	0xED, 0x6E, 0, 0

;	ED 6F 00 00
	rld
	nop
	nop

;	ED 70 00 00		未定義
	defb	0xED, 0x70, 0, 0

;	ED 71 00 00		未定義
	defb	0xED, 0x71, 0, 0

;	ED 72 00 00
	sbc		hl, sp
	nop
	nop

;	ED 73 00 00
	ld		[0x0000], sp

;	ED 74 00 00		未定義
	defb	0xED, 0x74, 0, 0

;	ED 75 00 00		未定義
	defb	0xED, 0x75, 0, 0

;	ED 76 00 00		未定義
	defb	0xED, 0x76, 0, 0

;	ED 77 00 00		未定義
	defb	0xED, 0x77, 0, 0

;	ED 78 00 00
	in		a, [c]
	nop
	nop

;	ED 79 00 00
	out		[c], a
	nop
	nop

;	ED 7A 00 00
	adc		hl, sp
	nop
	nop

;	ED 7B 00 00
	ld		sp, [0x0000]

;	ED 7C 00 00		未定義
	defb	0xED, 0x7C, 0, 0

;	ED 7D 00 00		未定義
	defb	0xED, 0x7D, 0, 0

;	ED 7E 00 00		未定義
	defb	0xED, 0x7E, 0, 0

;	ED 7F 00 00		未定義
	defb	0xED, 0x7F, 0, 0

;	ED 80 00 00		未定義
	defb	0xED, 0x80, 0, 0

;	ED 81 00 00		未定義
	defb	0xED, 0x81, 0, 0

;	ED 82 00 00		未定義
	defb	0xED, 0x82, 0, 0

;	ED 83 00 00		未定義
	defb	0xED, 0x83, 0, 0

;	ED 84 00 00		未定義
	defb	0xED, 0x84, 0, 0

;	ED 85 00 00		未定義
	defb	0xED, 0x85, 0, 0

;	ED 86 00 00		未定義
	defb	0xED, 0x86, 0, 0

;	ED 87 00 00		未定義
	defb	0xED, 0x87, 0, 0

;	ED 88 00 00		未定義
	defb	0xED, 0x88, 0, 0

;	ED 89 00 00		未定義
	defb	0xED, 0x89, 0, 0

;	ED 8A 00 00		未定義
	defb	0xED, 0x8A, 0, 0

;	ED 8B 00 00		未定義
	defb	0xED, 0x8B, 0, 0

;	ED 8C 00 00		未定義
	defb	0xED, 0x8C, 0, 0

;	ED 8D 00 00		未定義
	defb	0xED, 0x8D, 0, 0

;	ED 8E 00 00		未定義
	defb	0xED, 0x8E, 0, 0

;	ED 8F 00 00		未定義
	defb	0xED, 0x8F, 0, 0

;	ED 90 00 00		未定義
	defb	0xED, 0x90, 0, 0

;	ED 91 00 00		未定義
	defb	0xED, 0x91, 0, 0

;	ED 92 00 00		未定義
	defb	0xED, 0x92, 0, 0

;	ED 93 00 00		未定義
	defb	0xED, 0x93, 0, 0

;	ED 94 00 00		未定義
	defb	0xED, 0x94, 0, 0

;	ED 95 00 00		未定義
	defb	0xED, 0x95, 0, 0

;	ED 96 00 00		未定義
	defb	0xED, 0x96, 0, 0

;	ED 97 00 00		未定義
	defb	0xED, 0x97, 0, 0

;	ED 98 00 00		未定義
	defb	0xED, 0x98, 0, 0

;	ED 99 00 00		未定義
	defb	0xED, 0x99, 0, 0

;	ED 9A 00 00		未定義
	defb	0xED, 0x9A, 0, 0

;	ED 9B 00 00		未定義
	defb	0xED, 0x9B, 0, 0

;	ED 9C 00 00		未定義
	defb	0xED, 0x9C, 0, 0

;	ED 9D 00 00		未定義
	defb	0xED, 0x9D, 0, 0

;	ED 9E 00 00		未定義
	defb	0xED, 0x9E, 0, 0

;	ED 9F 00 00		未定義
	defb	0xED, 0x9F, 0, 0

;	ED A0 00 00
	ldi
	nop
	nop

;	ED A1 00 00
	cpi
	nop
	nop

;	ED A2 00 00
	ini
	nop
	nop

;	ED A3 00 00
	outi
	nop
	nop

;	ED A4 00 00		未定義
	defb	0xED, 0xA4, 0, 0

;	ED A5 00 00		未定義
	defb	0xED, 0xA5, 0, 0

;	ED A6 00 00		未定義
	defb	0xED, 0xA6, 0, 0

;	ED A7 00 00		未定義
	defb	0xED, 0xA7, 0, 0

;	ED A8 00 00
	ldd
	nop
	nop

;	ED A9 00 00
	cpd
	nop
	nop

;	ED AA 00 00
	ind
	nop
	nop

;	ED AB 00 00
	outd
	nop
	nop

;	ED AC 00 00		未定義
	defb	0xED, 0xAC, 0, 0

;	ED AD 00 00		未定義
	defb	0xED, 0xAD, 0, 0

;	ED AE 00 00		未定義
	defb	0xED, 0xAE, 0, 0

;	ED AF 00 00		未定義
	defb	0xED, 0xAF, 0, 0

;	ED B0 00 00
	ldir
	nop
	nop

;	ED B1 00 00
	cpir
	nop
	nop

;	ED B2 00 00
	inir
	nop
	nop

;	ED B3 00 00
	otir
	nop
	nop

;	ED B4 00 00		未定義
	defb	0xED, 0xB4, 0, 0

;	ED B5 00 00		未定義
	defb	0xED, 0xB5, 0, 0

;	ED B6 00 00		未定義
	defb	0xED, 0xB6, 0, 0

;	ED B7 00 00		未定義
	defb	0xED, 0xB7, 0, 0

;	ED B8 00 00
	lddr
	nop
	nop

;	ED B9 00 00
	cpdr
	nop
	nop

;	ED BA 00 00
	indr
	nop
	nop

;	ED BB 00 00
	otdr
	nop
	nop

;	ED BC 00 00		未定義
	defb	0xED, 0xBC, 0, 0

;	ED BD 00 00		未定義
	defb	0xED, 0xBD, 0, 0

;	ED BE 00 00		未定義
	defb	0xED, 0xBE, 0, 0

;	ED BF 00 00		未定義
	defb	0xED, 0xBF, 0, 0

;	ED C0 00 00		未定義
	defb	0xED, 0xC0, 0, 0

;	ED C1 00 00
	mulub	a, b
	nop
	nop

;	ED C2 00 00		未定義
	defb	0xED, 0xC2, 0, 0

;	ED C3 00 00
	muluw	hl, bc
	nop
	nop

;	ED C4 00 00		未定義
	defb	0xED, 0xC4, 0, 0

;	ED C5 00 00
	muluw	hl, sp
	nop
	nop

;	ED C6 00 00		未定義
	defb	0xED, 0xC6, 0, 0

;	ED C7 00 00		未定義
	defb	0xED, 0xC7, 0, 0

;	ED C8 00 00		未定義
	defb	0xED, 0xC8, 0, 0

;	ED C9 00 00
	mulub	a, c
	nop
	nop

;	ED CA 00 00		未定義
	defb	0xED, 0xCA, 0, 0

;	ED CB 00 00		未定義
	defb	0xED, 0xCB, 0, 0

;	ED CC 00 00		未定義
	defb	0xED, 0xCC, 0, 0

;	ED CD 00 00		未定義
	defb	0xED, 0xCD, 0, 0

;	ED CE 00 00		未定義
	defb	0xED, 0xCE, 0, 0

;	ED CF 00 00		未定義
	defb	0xED, 0xCF, 0, 0

;	ED D0 00 00		未定義
	defb	0xED, 0xD0, 0, 0

;	ED D1 00 00
	mulub	a, d
	nop
	nop

;	ED D2 00 00		未定義
	defb	0xED, 0xD2, 0, 0

;	ED D3 00 00		未定義
	defb	0xED, 0xD3, 0, 0

;	ED D4 00 00		未定義
	defb	0xED, 0xD4, 0, 0

;	ED D5 00 00		未定義
	defb	0xED, 0xD5, 0, 0

;	ED D6 00 00		未定義
	defb	0xED, 0xD6, 0, 0

;	ED D7 00 00		未定義
	defb	0xED, 0xD7, 0, 0

;	ED D8 00 00		未定義
	defb	0xED, 0xD8, 0, 0

;	ED D9 00 00
	mulub	a, e
	nop
	nop

;	ED DA 00 00		未定義
	defb	0xED, 0xDA, 0, 0

;	ED DB 00 00		未定義
	defb	0xED, 0xDB, 0, 0

;	ED DC 00 00		未定義
	defb	0xED, 0xDC, 0, 0

;	ED DD 00 00		未定義
	defb	0xED, 0xDD, 0, 0

;	ED DE 00 00		未定義
	defb	0xED, 0xDE, 0, 0

;	ED DF 00 00		未定義
	defb	0xED, 0xDF, 0, 0

;	ED E0 00 00		未定義
	defb	0xED, 0xE0, 0, 0

;	ED E1 00 00		未定義
	defb	0xED, 0xE1, 0, 0

;	ED E2 00 00		未定義
	defb	0xED, 0xE2, 0, 0

;	ED E3 00 00		未定義
	defb	0xED, 0xE3, 0, 0

;	ED E4 00 00		未定義
	defb	0xED, 0xE4, 0, 0

;	ED E5 00 00		未定義
	defb	0xED, 0xE5, 0, 0

;	ED E6 00 00		未定義
	defb	0xED, 0xE6, 0, 0

;	ED E7 00 00		未定義
	defb	0xED, 0xE7, 0, 0

;	ED E8 00 00		未定義
	defb	0xED, 0xE8, 0, 0

;	ED E9 00 00		未定義
	defb	0xED, 0xE9, 0, 0

;	ED EA 00 00		未定義
	defb	0xED, 0xEA, 0, 0

;	ED EB 00 00		未定義
	defb	0xED, 0xEB, 0, 0

;	ED EC 00 00		未定義
	defb	0xED, 0xEC, 0, 0

;	ED ED 00 00		未定義
	defb	0xED, 0xED, 0, 0

;	ED EE 00 00		未定義
	defb	0xED, 0xEE, 0, 0

;	ED EF 00 00		未定義
	defb	0xED, 0xEF, 0, 0

;	ED F0 00 00		未定義
	defb	0xED, 0xF0, 0, 0

;	ED F1 00 00		未定義
	defb	0xED, 0xF1, 0, 0

;	ED F2 00 00		未定義
	defb	0xED, 0xF2, 0, 0

;	ED F3 00 00		未定義
	defb	0xED, 0xF3, 0, 0

;	ED F4 00 00		未定義
	defb	0xED, 0xF4, 0, 0

;	ED F5 00 00		未定義
	defb	0xED, 0xF5, 0, 0

;	ED F6 00 00		未定義
	defb	0xED, 0xF6, 0, 0

;	ED F7 00 00		未定義
	defb	0xED, 0xF7, 0, 0

;	ED F8 00 00		未定義
	defb	0xED, 0xF8, 0, 0

;	ED F9 00 00		未定義
	defb	0xED, 0xF9, 0, 0

;	ED FA 00 00		未定義
	defb	0xED, 0xFA, 0, 0

;	ED FB 00 00		未定義
	defb	0xED, 0xFB, 0, 0

;	ED FC 00 00		未定義
	defb	0xED, 0xFC, 0, 0

;	ED FD 00 00		未定義
	defb	0xED, 0xFD, 0, 0

;	ED FE 00 00		未定義
	defb	0xED, 0xFE, 0, 0

;	ED FF 00 00		未定義
	defb	0xED, 0xFF, 0, 0

;==============================================================================
;	CB 00 00 00
	rlc		b
	nop
	nop

;	CB 01 00 00
	rlc		c
	nop
	nop

;	CB 02 00 00
	rlc		d
	nop
	nop

;	CB 03 00 00
	rlc		e
	nop
	nop

;	CB 04 00 00
	rlc		h
	nop
	nop

;	CB 05 00 00
	rlc		l
	nop
	nop

;	CB 06 00 00
	rlc		[hl]
	nop
	nop

;	CB 07 00 00
	rlc		a
	nop
	nop

;	CB 08 00 00
	rrc		b
	nop
	nop

;	CB 09 00 00
	rrc		c
	nop
	nop

;	CB 0A 00 00
	rrc		d
	nop
	nop

;	CB 0B 00 00
	rrc		e
	nop
	nop

;	CB 0C 00 00
	rrc		h
	nop
	nop

;	CB 0D 00 00
	rrc		l
	nop
	nop

;	CB 0E 00 00
	rrc		[hl]
	nop
	nop

;	CB 0F 00 00
	rrc		a
	nop
	nop

;	CB 10 00 00
	rl		b
	nop
	nop

;	CB 11 00 00
	rl		c
	nop
	nop

;	CB 12 00 00
	rl		d
	nop
	nop

;	CB 13 00 00
	rl		e
	nop
	nop

;	CB 14 00 00
	rl		h
	nop
	nop

;	CB 15 00 00
	rl		l
	nop
	nop

;	CB 16 00 00
	rl		[hl]
	nop
	nop

;	CB 17 00 00
	rl		a
	nop
	nop

;	CB 18 00 00
	rr		b
	nop
	nop

;	CB 19 00 00
	rr		c
	nop
	nop

;	CB 1A 00 00
	rr		d
	nop
	nop

;	CB 1B 00 00
	rr		e
	nop
	nop

;	CB 1C 00 00
	rr		h
	nop
	nop

;	CB 1D 00 00
	rr		l
	nop
	nop

;	CB 1E 00 00
	rr		[hl]
	nop
	nop

;	CB 1F 00 00
	rr		a
	nop
	nop

;	CB 20 00 00
	sla		b
	nop
	nop

;	CB 21 00 00
	sla		c
	nop
	nop

;	CB 22 00 00
	sla		d
	nop
	nop

;	CB 23 00 00
	sla		e
	nop
	nop

;	CB 24 00 00
	sla		h
	nop
	nop

;	CB 25 00 00
	sla		l
	nop
	nop

;	CB 26 00 00
	sla		[hl]
	nop
	nop

;	CB 27 00 00
	sla		a
	nop
	nop

;	CB 28 00 00
	sra		b
	nop
	nop

;	CB 29 00 00
	sra		c
	nop
	nop

;	CB 2A 00 00
	sra		d
	nop
	nop

;	CB 2B 00 00
	sra		e
	nop
	nop

;	CB 2C 00 00
	sra		h
	nop
	nop

;	CB 2D 00 00
	sra		l
	nop
	nop

;	CB 2E 00 00
	sra		[hl]
	nop
	nop

;	CB 2F 00 00
	sra		a
	nop
	nop

;	CB 30 00 00		未定義
	defb	0xCB, 0x30, 0, 0

;	CB 31 00 00		未定義
	defb	0xCB, 0x31, 0, 0

;	CB 32 00 00		未定義
	defb	0xCB, 0x32, 0, 0

;	CB 33 00 00		未定義
	defb	0xCB, 0x33, 0, 0

;	CB 34 00 00		未定義
	defb	0xCB, 0x34, 0, 0

;	CB 35 00 00		未定義
	defb	0xCB, 0x35, 0, 0

;	CB 36 00 00		未定義
	defb	0xCB, 0x36, 0, 0

;	CB 37 00 00		未定義
	defb	0xCB, 0x37, 0, 0

;	CB 38 00 00
	srl		b
	nop
	nop

;	CB 39 00 00
	srl		c
	nop
	nop

;	CB 3A 00 00
	srl		d
	nop
	nop

;	CB 3B 00 00
	srl		e
	nop
	nop

;	CB 3C 00 00
	srl		h
	nop
	nop

;	CB 3D 00 00
	srl		l
	nop
	nop

;	CB 3E 00 00
	srl		[hl]
	nop
	nop

;	CB 3F 00 00
	srl		a
	nop
	nop

;	CB 40 00 00
	bit		0, b
	nop
	nop

;	CB 41 00 00
	bit		0, c
	nop
	nop

;	CB 42 00 00
	bit		0, d
	nop
	nop

;	CB 43 00 00
	bit		0, e
	nop
	nop

;	CB 44 00 00
	bit		0, h
	nop
	nop

;	CB 45 00 00
	bit		0, l
	nop
	nop

;	CB 46 00 00
	bit		0, [hl]
	nop
	nop

;	CB 47 00 00
	bit		0, a
	nop
	nop

;	CB 48 00 00
	bit		1, b
	nop
	nop

;	CB 49 00 00
	bit		1, c
	nop
	nop

;	CB 4A 00 00
	bit		1, d
	nop
	nop

;	CB 4B 00 00
	bit		1, e
	nop
	nop

;	CB 4C 00 00
	bit		1, h
	nop
	nop

;	CB 4D 00 00
	bit		1, l
	nop
	nop

;	CB 4E 00 00
	bit		1, [hl]
	nop
	nop

;	CB 4F 00 00
	bit		1, a
	nop
	nop

;	CB 50 00 00
	bit		2, b
	nop
	nop

;	CB 51 00 00
	bit		2, c
	nop
	nop

;	CB 52 00 00
	bit		2, d
	nop
	nop

;	CB 53 00 00
	bit		2, e
	nop
	nop

;	CB 54 00 00
	bit		2, h
	nop
	nop

;	CB 55 00 00
	bit		2, l
	nop
	nop

;	CB 56 00 00
	bit		2, [hl]
	nop
	nop

;	CB 57 00 00
	bit		2, a
	nop
	nop

;	CB 58 00 00
	bit		3, b
	nop
	nop

;	CB 59 00 00
	bit		3, c
	nop
	nop

;	CB 5A 00 00
	bit		3, d
	nop
	nop

;	CB 5B 00 00
	bit		3, e
	nop
	nop

;	CB 5C 00 00
	bit		3, h
	nop
	nop

;	CB 5D 00 00
	bit		3, l
	nop
	nop

;	CB 5E 00 00
	bit		3, [hl]
	nop
	nop

;	CB 5F 00 00
	bit		3, a
	nop
	nop

;	CB 60 00 00
	bit		4, b
	nop
	nop

;	CB 61 00 00
	bit		4, c
	nop
	nop

;	CB 62 00 00
	bit		4, d
	nop
	nop

;	CB 63 00 00
	bit		4, e
	nop
	nop

;	CB 64 00 00
	bit		4, h
	nop
	nop

;	CB 65 00 00
	bit		4, l
	nop
	nop

;	CB 66 00 00
	bit		4, [hl]
	nop
	nop

;	CB 67 00 00
	bit		4, a
	nop
	nop

;	CB 68 00 00
	bit		5, b
	nop
	nop

;	CB 69 00 00
	bit		5, c
	nop
	nop

;	CB 6A 00 00
	bit		5, d
	nop
	nop

;	CB 6B 00 00
	bit		5, e
	nop
	nop

;	CB 6C 00 00
	bit		5, h
	nop
	nop

;	CB 6D 00 00
	bit		5, l
	nop
	nop

;	CB 6E 00 00
	bit		5, [hl]
	nop
	nop

;	CB 6F 00 00
	bit		5, a
	nop
	nop

;	CB 70 00 00
	bit		6, b
	nop
	nop

;	CB 71 00 00
	bit		6, c
	nop
	nop

;	CB 72 00 00
	bit		6, d
	nop
	nop

;	CB 73 00 00
	bit		6, e
	nop
	nop

;	CB 74 00 00
	bit		6, h
	nop
	nop

;	CB 75 00 00
	bit		6, l
	nop
	nop

;	CB 76 00 00
	bit		6, [hl]
	nop
	nop

;	CB 77 00 00
	bit		6, a
	nop
	nop

;	CB 78 00 00
	bit		7, b
	nop
	nop

;	CB 79 00 00
	bit		7, c
	nop
	nop

;	CB 7A 00 00
	bit		7, d
	nop
	nop

;	CB 7B 00 00
	bit		7, e
	nop
	nop

;	CB 7C 00 00
	bit		7, h
	nop
	nop

;	CB 7D 00 00
	bit		7, l
	nop
	nop

;	CB 7E 00 00
	bit		7, [hl]
	nop
	nop

;	CB 7F 00 00
	bit		7, a
	nop
	nop

;	CB 80 00 00
	res		0, b
	nop
	nop

;	CB 81 00 00
	res		0, c
	nop
	nop

;	CB 82 00 00
	res		0, d
	nop
	nop

;	CB 83 00 00
	res		0, e
	nop
	nop

;	CB 84 00 00
	res		0, h
	nop
	nop

;	CB 85 00 00
	res		0, l
	nop
	nop

;	CB 86 00 00
	res		0, [hl]
	nop
	nop

;	CB 87 00 00
	res		0, a
	nop
	nop

;	CB 88 00 00
	res		1, b
	nop
	nop

;	CB 89 00 00
	res		1, c
	nop
	nop

;	CB 8A 00 00
	res		1, d
	nop
	nop

;	CB 8B 00 00
	res		1, e
	nop
	nop

;	CB 8C 00 00
	res		1, h
	nop
	nop

;	CB 8D 00 00
	res		1, l
	nop
	nop

;	CB 8E 00 00
	res		1, [hl]
	nop
	nop

;	CB 8F 00 00
	res		1, a
	nop
	nop

;	CB 90 00 00
	res		2, b
	nop
	nop

;	CB 91 00 00
	res		2, c
	nop
	nop

;	CB 92 00 00
	res		2, d
	nop
	nop

;	CB 93 00 00
	res		2, e
	nop
	nop

;	CB 94 00 00
	res		2, h
	nop
	nop

;	CB 95 00 00
	res		2, l
	nop
	nop

;	CB 96 00 00
	res		2, [hl]
	nop
	nop

;	CB 97 00 00
	res		2, a
	nop
	nop

;	CB 98 00 00
	res		3, b
	nop
	nop

;	CB 99 00 00
	res		3, c
	nop
	nop

;	CB 9A 00 00
	res		3, d
	nop
	nop

;	CB 9B 00 00
	res		3, e
	nop
	nop

;	CB 9C 00 00
	res		3, h
	nop
	nop

;	CB 9D 00 00
	res		3, l
	nop
	nop

;	CB 9E 00 00
	res		3, [hl]
	nop
	nop

;	CB 9F 00 00
	res		3, a
	nop
	nop

;	CB A0 00 00
	res		4, b
	nop
	nop

;	CB A1 00 00
	res		4, c
	nop
	nop

;	CB A2 00 00
	res		4, d
	nop
	nop

;	CB A3 00 00
	res		4, e
	nop
	nop

;	CB A4 00 00
	res		4, h
	nop
	nop

;	CB A5 00 00
	res		4, l
	nop
	nop

;	CB A6 00 00
	res		4, [hl]
	nop
	nop

;	CB A7 00 00
	res		4, a
	nop
	nop

;	CB A8 00 00
	res		5, b
	nop
	nop

;	CB A9 00 00
	res		5, c
	nop
	nop

;	CB AA 00 00
	res		5, d
	nop
	nop

;	CB AB 00 00
	res		5, e
	nop
	nop

;	CB AC 00 00
	res		5, h
	nop
	nop

;	CB AD 00 00
	res		5, l
	nop
	nop

;	CB AE 00 00
	res		5, [hl]
	nop
	nop

;	CB AF 00 00
	res		5, a
	nop
	nop

;	CB B0 00 00
	res		6, b
	nop
	nop

;	CB B1 00 00
	res		6, c
	nop
	nop

;	CB B2 00 00
	res		6, d
	nop
	nop

;	CB B3 00 00
	res		6, e
	nop
	nop

;	CB B4 00 00
	res		6, h
	nop
	nop

;	CB B5 00 00
	res		6, l
	nop
	nop

;	CB B6 00 00
	res		6, [hl]
	nop
	nop

;	CB B7 00 00
	res		6, a
	nop
	nop

;	CB B8 00 00
	res		7, b
	nop
	nop

;	CB B9 00 00
	res		7, c
	nop
	nop

;	CB BA 00 00
	res		7, d
	nop
	nop

;	CB BB 00 00
	res		7, e
	nop
	nop

;	CB BC 00 00
	res		7, h
	nop
	nop

;	CB BD 00 00
	res		7, l
	nop
	nop

;	CB BE 00 00
	res		7, [hl]
	nop
	nop

;	CB BF 00 00
	res		7, a
	nop
	nop

;	CB C0 00 00
	set		0, b
	nop
	nop

;	CB C1 00 00
	set		0, c
	nop
	nop

;	CB C2 00 00
	set		0, d
	nop
	nop

;	CB C3 00 00
	set		0, e
	nop
	nop

;	CB C4 00 00
	set		0, h
	nop
	nop

;	CB C5 00 00
	set		0, l
	nop
	nop

;	CB C6 00 00
	set		0, [hl]
	nop
	nop

;	CB C7 00 00
	set		0, a
	nop
	nop

;	CB C8 00 00
	set		1, b
	nop
	nop

;	CB C9 00 00
	set		1, c
	nop
	nop

;	CB CA 00 00
	set		1, d
	nop
	nop

;	CB CB 00 00
	set		1, e
	nop
	nop

;	CB CC 00 00
	set		1, h
	nop
	nop

;	CB CD 00 00
	set		1, l
	nop
	nop

;	CB CE 00 00
	set		1, [hl]
	nop
	nop

;	CB CF 00 00
	set		1, a
	nop
	nop

;	CB D0 00 00
	set		2, b
	nop
	nop

;	CB D1 00 00
	set		2, c
	nop
	nop

;	CB D2 00 00
	set		2, d
	nop
	nop

;	CB D3 00 00
	set		2, e
	nop
	nop

;	CB D4 00 00
	set		2, h
	nop
	nop

;	CB D5 00 00
	set		2, l
	nop
	nop

;	CB D6 00 00
	set		2, [hl]
	nop
	nop

;	CB D7 00 00
	set		2, a
	nop
	nop

;	CB D8 00 00
	set		3, b
	nop
	nop

;	CB D9 00 00
	set		3, c
	nop
	nop

;	CB DA 00 00
	set		3, d
	nop
	nop

;	CB DB 00 00
	set		3, e
	nop
	nop

;	CB DC 00 00
	set		3, h
	nop
	nop

;	CB DD 00 00
	set		3, l
	nop
	nop

;	CB DE 00 00
	set		3, [hl]
	nop
	nop

;	CB DF 00 00
	set		3, a
	nop
	nop

;	CB E0 00 00
	set		4, b
	nop
	nop

;	CB E1 00 00
	set		4, c
	nop
	nop

;	CB E2 00 00
	set		4, d
	nop
	nop

;	CB E3 00 00
	set		4, e
	nop
	nop

;	CB E4 00 00
	set		4, h
	nop
	nop

;	CB E5 00 00
	set		4, l
	nop
	nop

;	CB E6 00 00
	set		4, [hl]
	nop
	nop

;	CB E7 00 00
	set		4, a
	nop
	nop

;	CB E8 00 00
	set		5, b
	nop
	nop

;	CB E9 00 00
	set		5, c
	nop
	nop

;	CB EA 00 00
	set		5, d
	nop
	nop

;	CB EB 00 00
	set		5, e
	nop
	nop

;	CB EC 00 00
	set		5, h
	nop
	nop

;	CB ED 00 00
	set		5, l
	nop
	nop

;	CB EE 00 00
	set		5, [hl]
	nop
	nop

;	CB EF 00 00
	set		5, a
	nop
	nop

;	CB F0 00 00
	set		6, b
	nop
	nop

;	CB F1 00 00
	set		6, c
	nop
	nop

;	CB F2 00 00
	set		6, d
	nop
	nop

;	CB F3 00 00
	set		6, e
	nop
	nop

;	CB F4 00 00
	set		6, h
	nop
	nop

;	CB F5 00 00
	set		6, l
	nop
	nop

;	CB F6 00 00
	set		6, [hl]
	nop
	nop

;	CB F7 00 00
	set		6, a
	nop
	nop

;	CB F8 00 00
	set		7, b
	nop
	nop

;	CB F9 00 00
	set		7, c
	nop
	nop

;	CB FA 00 00
	set		7, d
	nop
	nop

;	CB FB 00 00
	set		7, e
	nop
	nop

;	CB FC 00 00
	set		7, h
	nop
	nop

;	CB FD 00 00
	set		7, l
	nop
	nop

;	CB FE 00 00
	set		7, [hl]
	nop
	nop

;	CB FF 00 00
	set		7, a
	nop
	nop

;==============================================================================
;	DD CB 00 00 ... DD CB 00 05	未定義
	defb	0xDD, 0xCB, 0x00, 0x00
	defb	0xDD, 0xCB, 0x00, 0x01
	defb	0xDD, 0xCB, 0x00, 0x02
	defb	0xDD, 0xCB, 0x00, 0x03
	defb	0xDD, 0xCB, 0x00, 0x04
	defb	0xDD, 0xCB, 0x00, 0x05

;	DD CB 00 06
	rlc		[ix+0x00]

;	DD CB 00 07 ... DD CB 00 0D	未定義
	defb	0xDD, 0xCB, 0x00, 0x07
	defb	0xDD, 0xCB, 0x00, 0x08
	defb	0xDD, 0xCB, 0x00, 0x09
	defb	0xDD, 0xCB, 0x00, 0x0A
	defb	0xDD, 0xCB, 0x00, 0x0B
	defb	0xDD, 0xCB, 0x00, 0x0C
	defb	0xDD, 0xCB, 0x00, 0x0D

;	DD CB 00 0E
	rrc		[ix+0x00]

;	DD CB 0F 00	未定義
	defb	0xDD, 0xCB, 0x00, 0x0F

;	DD CB 00 10 ... DD CB 00 15	未定義
	defb	0xDD, 0xCB, 0x00, 0x10
	defb	0xDD, 0xCB, 0x00, 0x11
	defb	0xDD, 0xCB, 0x00, 0x12
	defb	0xDD, 0xCB, 0x00, 0x13
	defb	0xDD, 0xCB, 0x00, 0x14
	defb	0xDD, 0xCB, 0x00, 0x15

;	DD CB 00 16
	rl		[ix+0x00]

;	DD CB 00 17 ... DD CB 00 1D	未定義
	defb	0xDD, 0xCB, 0x00, 0x17
	defb	0xDD, 0xCB, 0x00, 0x18
	defb	0xDD, 0xCB, 0x00, 0x19
	defb	0xDD, 0xCB, 0x00, 0x1A
	defb	0xDD, 0xCB, 0x00, 0x1B
	defb	0xDD, 0xCB, 0x00, 0x1C
	defb	0xDD, 0xCB, 0x00, 0x1D

;	DD CB 00 1E
	rr		[ix+0x00]

;	DD CB 00 1F	未定義
	defb	0xDD, 0xCB, 0x00, 0x1F

;	DD CB 00 20 ... DD CB 00 25	未定義
	defb	0xDD, 0xCB, 0x00, 0x20
	defb	0xDD, 0xCB, 0x00, 0x21
	defb	0xDD, 0xCB, 0x00, 0x22
	defb	0xDD, 0xCB, 0x00, 0x23
	defb	0xDD, 0xCB, 0x00, 0x24
	defb	0xDD, 0xCB, 0x00, 0x25

;	DD CB 00 26
	sla		[ix+0x00]

;	DD CB 00 27 ... DD CB 00 2D	未定義
	defb	0xDD, 0xCB, 0x00, 0x27
	defb	0xDD, 0xCB, 0x00, 0x28
	defb	0xDD, 0xCB, 0x00, 0x29
	defb	0xDD, 0xCB, 0x00, 0x2A
	defb	0xDD, 0xCB, 0x00, 0x2B
	defb	0xDD, 0xCB, 0x00, 0x2C
	defb	0xDD, 0xCB, 0x00, 0x2D

;	DD CB 00 2E
	sra		[ix+0x00]

;	DD CB 00 2F	未定義
	defb	0xDD, 0xCB, 0x00, 0x2F

;	DD CB 00 30 ... DD CB 00 3D	未定義
	defb	0xDD, 0xCB, 0x00, 0x30
	defb	0xDD, 0xCB, 0x00, 0x31
	defb	0xDD, 0xCB, 0x00, 0x32
	defb	0xDD, 0xCB, 0x00, 0x33
	defb	0xDD, 0xCB, 0x00, 0x34
	defb	0xDD, 0xCB, 0x00, 0x35
	defb	0xDD, 0xCB, 0x00, 0x36
	defb	0xDD, 0xCB, 0x00, 0x37
	defb	0xDD, 0xCB, 0x00, 0x38
	defb	0xDD, 0xCB, 0x00, 0x39
	defb	0xDD, 0xCB, 0x00, 0x3A
	defb	0xDD, 0xCB, 0x00, 0x3B
	defb	0xDD, 0xCB, 0x00, 0x3C
	defb	0xDD, 0xCB, 0x00, 0x3D

;	DD CB 00 3E
	srl		[ix+0x00]

;	DD CB 00 3F	未定義
	defb	0xDD, 0xCB, 0x00, 0x3F

;	DD CB 00 40 ... DD CB 00 45	未定義
	defb	0xDD, 0xCB, 0x00, 0x40
	defb	0xDD, 0xCB, 0x00, 0x41
	defb	0xDD, 0xCB, 0x00, 0x42
	defb	0xDD, 0xCB, 0x00, 0x43
	defb	0xDD, 0xCB, 0x00, 0x44
	defb	0xDD, 0xCB, 0x00, 0x45

;	DD CB 00 46
	bit		0, [ix+0]

;	DD CB 00 47 ... DD CB 00 4D	未定義
	defb	0xDD, 0xCB, 0x00, 0x47
	defb	0xDD, 0xCB, 0x00, 0x48
	defb	0xDD, 0xCB, 0x00, 0x49
	defb	0xDD, 0xCB, 0x00, 0x4A
	defb	0xDD, 0xCB, 0x00, 0x4B
	defb	0xDD, 0xCB, 0x00, 0x4C
	defb	0xDD, 0xCB, 0x00, 0x4D

;	DD CB 00 4E
	bit		1, [ix+0]

;	DD CB 00 4F	未定義
	defb	0xDD, 0xCB, 0x4F, 0x00

;	DD CB 00 50 ... DD CB 00 55	未定義
	defb	0xDD, 0xCB, 0x00, 0x50
	defb	0xDD, 0xCB, 0x00, 0x51
	defb	0xDD, 0xCB, 0x00, 0x52
	defb	0xDD, 0xCB, 0x00, 0x53
	defb	0xDD, 0xCB, 0x00, 0x54
	defb	0xDD, 0xCB, 0x00, 0x55

;	DD CB 00 56
	bit		2, [ix+0]

;	DD CB 00 57 ... DD CB 00 5D	未定義
	defb	0xDD, 0xCB, 0x00, 0x57
	defb	0xDD, 0xCB, 0x00, 0x58
	defb	0xDD, 0xCB, 0x00, 0x59
	defb	0xDD, 0xCB, 0x00, 0x5A
	defb	0xDD, 0xCB, 0x00, 0x5B
	defb	0xDD, 0xCB, 0x00, 0x5C
	defb	0xDD, 0xCB, 0x00, 0x5D

;	DD CB 00 5E
	bit		3, [ix+0]

;	DD CB 00 5F	未定義
	defb	0xDD, 0xCB, 0x00, 0x5F

;	DD CB 00 60 ... DD CB 00 65	未定義
	defb	0xDD, 0xCB, 0x00, 0x60
	defb	0xDD, 0xCB, 0x00, 0x61
	defb	0xDD, 0xCB, 0x00, 0x62
	defb	0xDD, 0xCB, 0x00, 0x63
	defb	0xDD, 0xCB, 0x00, 0x64
	defb	0xDD, 0xCB, 0x00, 0x65

;	DD CB 00 66
	bit		4, [ix+0]

;	DD CB 00 67 ... DD CB 00 6D	未定義
	defb	0xDD, 0xCB, 0x00, 0x67
	defb	0xDD, 0xCB, 0x00, 0x68
	defb	0xDD, 0xCB, 0x00, 0x69
	defb	0xDD, 0xCB, 0x00, 0x6A
	defb	0xDD, 0xCB, 0x00, 0x6B
	defb	0xDD, 0xCB, 0x00, 0x6C
	defb	0xDD, 0xCB, 0x00, 0x6D

;	DD CB 00 6E
	bit		5, [ix+0]

;	DD CB 00 6F	未定義
	defb	0xDD, 0xCB, 0x00, 0x6F

;	DD CB 00 70 ... DD CB 00 75	未定義
	defb	0xDD, 0xCB, 0x00, 0x70
	defb	0xDD, 0xCB, 0x00, 0x71
	defb	0xDD, 0xCB, 0x00, 0x72
	defb	0xDD, 0xCB, 0x00, 0x73
	defb	0xDD, 0xCB, 0x00, 0x74
	defb	0xDD, 0xCB, 0x00, 0x75

;	DD CB 00 76
	bit		6, [ix+0]

;	DD CB 00 77 ... DD CB 00 7D	未定義
	defb	0xDD, 0xCB, 0x00, 0x77
	defb	0xDD, 0xCB, 0x00, 0x78
	defb	0xDD, 0xCB, 0x00, 0x79
	defb	0xDD, 0xCB, 0x00, 0x7A
	defb	0xDD, 0xCB, 0x00, 0x7B
	defb	0xDD, 0xCB, 0x00, 0x7C
	defb	0xDD, 0xCB, 0x00, 0x7D

;	DD CB 00 7E
	bit		7, [ix+0]

;	DD CB 00 7F	未定義
	defb	0xDD, 0xCB, 0x00, 0x7F

;	DD CB 00 80 ... DD CB 00 85	未定義
	defb	0xDD, 0xCB, 0x00, 0x80
	defb	0xDD, 0xCB, 0x00, 0x81
	defb	0xDD, 0xCB, 0x00, 0x82
	defb	0xDD, 0xCB, 0x00, 0x83
	defb	0xDD, 0xCB, 0x00, 0x84
	defb	0xDD, 0xCB, 0x00, 0x85

;	DD CB 00 86
	res		0, [ix+0]

;	DD CB 00 87 ... DD CB 00 8D	未定義
	defb	0xDD, 0xCB, 0x00, 0x87
	defb	0xDD, 0xCB, 0x00, 0x88
	defb	0xDD, 0xCB, 0x00, 0x89
	defb	0xDD, 0xCB, 0x00, 0x8A
	defb	0xDD, 0xCB, 0x00, 0x8B
	defb	0xDD, 0xCB, 0x00, 0x8C
	defb	0xDD, 0xCB, 0x00, 0x8D

;	DD CB 00 8E
	res		1, [ix+0]

;	DD CB 00 8F	未定義
	defb	0xDD, 0xCB, 0x00, 0x8F

;	DD CB 00 90 ... DD CB 00 95	未定義
	defb	0xDD, 0xCB, 0x00, 0x90
	defb	0xDD, 0xCB, 0x00, 0x91
	defb	0xDD, 0xCB, 0x00, 0x92
	defb	0xDD, 0xCB, 0x00, 0x93
	defb	0xDD, 0xCB, 0x00, 0x94
	defb	0xDD, 0xCB, 0x00, 0x95

;	DD CB 00 96
	res		2, [ix+0]

;	DD CB 00 97 ... DD CB 00 9D	未定義
	defb	0xDD, 0xCB, 0x00, 0x97
	defb	0xDD, 0xCB, 0x00, 0x98
	defb	0xDD, 0xCB, 0x00, 0x99
	defb	0xDD, 0xCB, 0x00, 0x9A
	defb	0xDD, 0xCB, 0x00, 0x9B
	defb	0xDD, 0xCB, 0x00, 0x9C
	defb	0xDD, 0xCB, 0x00, 0x9D

;	DD CB 9E 00
	res		3, [ix+0]

;	DD CB 00 9F	未定義
	defb	0xDD, 0xCB, 0x00, 0x9F

;	DD CB 00 A0 ... DD CB 00 A5	未定義
	defb	0xDD, 0xCB, 0x00, 0xA0
	defb	0xDD, 0xCB, 0x00, 0xA1
	defb	0xDD, 0xCB, 0x00, 0xA2
	defb	0xDD, 0xCB, 0x00, 0xA3
	defb	0xDD, 0xCB, 0x00, 0xA4
	defb	0xDD, 0xCB, 0x00, 0xA5

;	DD CB A6 00
	res		4, [ix+0]

;	DD CB 00 A7 ... DD CB 00 AD	未定義
	defb	0xDD, 0xCB, 0x00, 0xA7
	defb	0xDD, 0xCB, 0x00, 0xA8
	defb	0xDD, 0xCB, 0x00, 0xA9
	defb	0xDD, 0xCB, 0x00, 0xAA
	defb	0xDD, 0xCB, 0x00, 0xAB
	defb	0xDD, 0xCB, 0x00, 0xAC
	defb	0xDD, 0xCB, 0x00, 0xAD

;	DD CB 00 AE
	res		5, [ix+0]

;	DD CB AF 00	未定義
	defb	0xDD, 0xCB, 0xAF, 0x00

;	DD CB B0 00 ... DD CB B5 00	未定義
	defb	0xDD, 0xCB, 0x00, 0xB0
	defb	0xDD, 0xCB, 0x00, 0xB1
	defb	0xDD, 0xCB, 0x00, 0xB2
	defb	0xDD, 0xCB, 0x00, 0xB3
	defb	0xDD, 0xCB, 0x00, 0xB4
	defb	0xDD, 0xCB, 0x00, 0xB5

;	DD CB 00 B6
	res		6, [ix+0]

;	DD CB 00 B7 ... DD CB 00 BD	未定義
	defb	0xDD, 0xCB, 0x00, 0xB7
	defb	0xDD, 0xCB, 0x00, 0xB8
	defb	0xDD, 0xCB, 0x00, 0xB9
	defb	0xDD, 0xCB, 0x00, 0xBA
	defb	0xDD, 0xCB, 0x00, 0xBB
	defb	0xDD, 0xCB, 0x00, 0xBC
	defb	0xDD, 0xCB, 0x00, 0xBD

;	DD CB BE 00
	res		7, [ix+0]

;	DD CB BF 00	未定義
	defb	0xDD, 0xCB, 0xBF, 0x00

;	DD CB 00 C0 ... DD CB 00 C5	未定義
	defb	0xDD, 0xCB, 0x00, 0xC0
	defb	0xDD, 0xCB, 0x00, 0xC1
	defb	0xDD, 0xCB, 0x00, 0xC2
	defb	0xDD, 0xCB, 0x00, 0xC3
	defb	0xDD, 0xCB, 0x00, 0xC4
	defb	0xDD, 0xCB, 0x00, 0xC5

;	DD CB C6 00
	set		0, [ix+0]

;	DD CB 00 C7 ... DD CB 00 CD	未定義
	defb	0xDD, 0xCB, 0x00, 0xC7
	defb	0xDD, 0xCB, 0x00, 0xC8
	defb	0xDD, 0xCB, 0x00, 0xC9
	defb	0xDD, 0xCB, 0x00, 0xCA
	defb	0xDD, 0xCB, 0x00, 0xCB
	defb	0xDD, 0xCB, 0x00, 0xCC
	defb	0xDD, 0xCB, 0x00, 0xCD

;	DD CB 00 CE
	set		1, [ix+0]

;	DD CB 00 CF	未定義
	defb	0xDD, 0xCB, 0x00, 0xCF

;	DD CB 00 D0 ... DD CB 00 D5	未定義
	defb	0xDD, 0xCB, 0x00, 0xD0
	defb	0xDD, 0xCB, 0x00, 0xD1
	defb	0xDD, 0xCB, 0x00, 0xD2
	defb	0xDD, 0xCB, 0x00, 0xD3
	defb	0xDD, 0xCB, 0x00, 0xD4
	defb	0xDD, 0xCB, 0x00, 0xD5

;	DD CB 00 D6
	set		2, [ix+0]

;	DD CB 00 D7 ... DD CB 00 DD	未定義
	defb	0xDD, 0xCB, 0x00, 0xD7
	defb	0xDD, 0xCB, 0x00, 0xD8
	defb	0xDD, 0xCB, 0x00, 0xD9
	defb	0xDD, 0xCB, 0x00, 0xDA
	defb	0xDD, 0xCB, 0x00, 0xDB
	defb	0xDD, 0xCB, 0x00, 0xDC
	defb	0xDD, 0xCB, 0x00, 0xDD

;	DD CB 00 DE
	set		3, [ix+0]

;	DD CB 00 DF	未定義
	defb	0xDD, 0xCB, 0x00, 0xDF

;	DD CB 00 E0 ... DD CB 00 E5	未定義
	defb	0xDD, 0xCB, 0x00, 0xE0
	defb	0xDD, 0xCB, 0x00, 0xE1
	defb	0xDD, 0xCB, 0x00, 0xE2
	defb	0xDD, 0xCB, 0x00, 0xE3
	defb	0xDD, 0xCB, 0x00, 0xE4
	defb	0xDD, 0xCB, 0x00, 0xE5

;	DD CB 00 E6
	set		4, [ix+0]

;	DD CB 00 E7 ... DD CB 00 ED	未定義
	defb	0xDD, 0xCB, 0x00, 0xE7
	defb	0xDD, 0xCB, 0x00, 0xE8
	defb	0xDD, 0xCB, 0x00, 0xE9
	defb	0xDD, 0xCB, 0x00, 0xEA
	defb	0xDD, 0xCB, 0x00, 0xEB
	defb	0xDD, 0xCB, 0x00, 0xEC
	defb	0xDD, 0xCB, 0x00, 0xED

;	DD CB EE 00
	set		5, [ix+0]

;	DD CB EF 00	未定義
	defb	0xDD, 0xCB, 0x00, 0xEF

;	DD CB 00 F0 ... DD CB 00 F5	未定義
	defb	0xDD, 0xCB, 0x00, 0xF0
	defb	0xDD, 0xCB, 0x00, 0xF1
	defb	0xDD, 0xCB, 0x00, 0xF2
	defb	0xDD, 0xCB, 0x00, 0xF3
	defb	0xDD, 0xCB, 0x00, 0xF4
	defb	0xDD, 0xCB, 0x00, 0xF5

;	DD CB 00 F6
	set		6, [ix+0]

;	DD CB 00 F7 ... DD CB 00 FD	未定義
	defb	0xDD, 0xCB, 0x00, 0xF7
	defb	0xDD, 0xCB, 0x00, 0xF8
	defb	0xDD, 0xCB, 0x00, 0xF9
	defb	0xDD, 0xCB, 0x00, 0xFA
	defb	0xDD, 0xCB, 0x00, 0xFB
	defb	0xDD, 0xCB, 0x00, 0xFC
	defb	0xDD, 0xCB, 0x00, 0xFD

;	DD CB FE 00
	set		7, [ix+0]

;	DD CB FF 00	未定義
	defb	0xDD, 0xCB, 0xFF, 0x00

;==============================================================================
;	FD CB 00 00 ... FD CB 00 05	未定義
	defb	0xFD, 0xCB, 0x00, 0x00
	defb	0xFD, 0xCB, 0x00, 0x01
	defb	0xFD, 0xCB, 0x00, 0x02
	defb	0xFD, 0xCB, 0x00, 0x03
	defb	0xFD, 0xCB, 0x00, 0x04
	defb	0xFD, 0xCB, 0x00, 0x05

;	FD CB 00 06
	rlc		[iy+0x00]

;	FD CB 00 07 ... FD CB 00 0D	未定義
	defb	0xFD, 0xCB, 0x00, 0x07
	defb	0xFD, 0xCB, 0x00, 0x08
	defb	0xFD, 0xCB, 0x00, 0x09
	defb	0xFD, 0xCB, 0x00, 0x0A
	defb	0xFD, 0xCB, 0x00, 0x0B
	defb	0xFD, 0xCB, 0x00, 0x0C
	defb	0xFD, 0xCB, 0x00, 0x0D

;	FD CB 00 0E
	rrc		[iy+0x00]

;	FD CB 00 0F	未定義
	defb	0xFD, 0xCB, 0x00, 0x0F

;	FD CB 00 10 ... FD CB 00 15	未定義
	defb	0xFD, 0xCB, 0x00, 0x10
	defb	0xFD, 0xCB, 0x00, 0x11
	defb	0xFD, 0xCB, 0x00, 0x12
	defb	0xFD, 0xCB, 0x00, 0x13
	defb	0xFD, 0xCB, 0x00, 0x14
	defb	0xFD, 0xCB, 0x00, 0x15

;	FD CB 00 16
	rl		[iy+0x00]

;	FD CB 00 17 ... FD CB 00 1D	未定義
	defb	0xFD, 0xCB, 0x00, 0x17
	defb	0xFD, 0xCB, 0x00, 0x18
	defb	0xFD, 0xCB, 0x00, 0x19
	defb	0xFD, 0xCB, 0x00, 0x1A
	defb	0xFD, 0xCB, 0x00, 0x1B
	defb	0xFD, 0xCB, 0x00, 0x1C
	defb	0xFD, 0xCB, 0x00, 0x1D

;	FD CB 00 1E
	rr		[iy+0x00]

;	FD CB 00 1F	未定義
	defb	0xFD, 0xCB, 0x00, 0x1F

;	FD CB 00 20 ... FD CB 00 25	未定義
	defb	0xFD, 0xCB, 0x00, 0x20
	defb	0xFD, 0xCB, 0x00, 0x21
	defb	0xFD, 0xCB, 0x00, 0x22
	defb	0xFD, 0xCB, 0x00, 0x23
	defb	0xFD, 0xCB, 0x00, 0x24
	defb	0xFD, 0xCB, 0x00, 0x25

;	FD CB 00 26
	sla		[iy+0x00]

;	FD CB 00 27 ... FD CB 00 2D	未定義
	defb	0xFD, 0xCB, 0x00, 0x27
	defb	0xFD, 0xCB, 0x00, 0x28
	defb	0xFD, 0xCB, 0x00, 0x29
	defb	0xFD, 0xCB, 0x00, 0x2A
	defb	0xFD, 0xCB, 0x00, 0x2B
	defb	0xFD, 0xCB, 0x00, 0x2C
	defb	0xFD, 0xCB, 0x00, 0x2D

;	FD CB 00 2E
	sra		[iy+0x00]

;	FD CB 00 2F	未定義
	defb	0xFD, 0xCB, 0x00, 0x2F

;	FD CB 00 30 ... FD CB 00 3D	未定義
	defb	0xFD, 0xCB, 0x00, 0x30
	defb	0xFD, 0xCB, 0x00, 0x31
	defb	0xFD, 0xCB, 0x00, 0x32
	defb	0xFD, 0xCB, 0x00, 0x33
	defb	0xFD, 0xCB, 0x00, 0x34
	defb	0xFD, 0xCB, 0x00, 0x35
	defb	0xFD, 0xCB, 0x00, 0x36
	defb	0xFD, 0xCB, 0x00, 0x37
	defb	0xFD, 0xCB, 0x00, 0x38
	defb	0xFD, 0xCB, 0x00, 0x39
	defb	0xFD, 0xCB, 0x00, 0x3A
	defb	0xFD, 0xCB, 0x00, 0x3B
	defb	0xFD, 0xCB, 0x00, 0x3C
	defb	0xFD, 0xCB, 0x00, 0x3D

;	FD CB 00 3E
	srl		[iy+0x00]

;	FD CB 00 3F	未定義
	defb	0xFD, 0xCB, 0x00, 0x3F

;	FD CB 00 40 ... FD CB 00 45	未定義
	defb	0xFD, 0xCB, 0x00, 0x40
	defb	0xFD, 0xCB, 0x00, 0x41
	defb	0xFD, 0xCB, 0x00, 0x42
	defb	0xFD, 0xCB, 0x00, 0x43
	defb	0xFD, 0xCB, 0x00, 0x44
	defb	0xFD, 0xCB, 0x00, 0x45

;	FD CB 46 00
	bit		0, [iy+0]

;	FD CB 00 47 ... FD CB 00 4D	未定義
	defb	0xFD, 0xCB, 0x00, 0x47
	defb	0xFD, 0xCB, 0x00, 0x48
	defb	0xFD, 0xCB, 0x00, 0x49
	defb	0xFD, 0xCB, 0x00, 0x4A
	defb	0xFD, 0xCB, 0x00, 0x4B
	defb	0xFD, 0xCB, 0x00, 0x4C
	defb	0xFD, 0xCB, 0x00, 0x4D

;	FD CB 00 4E
	bit		1, [iy+0]

;	FD CB 00 4F	未定義
	defb	0xFD, 0xCB, 0x00, 0x4F

;	FD CB 00 50 ... FD CB 00 55	未定義
	defb	0xFD, 0xCB, 0x00, 0x50
	defb	0xFD, 0xCB, 0x00, 0x51
	defb	0xFD, 0xCB, 0x00, 0x52
	defb	0xFD, 0xCB, 0x00, 0x53
	defb	0xFD, 0xCB, 0x00, 0x54
	defb	0xFD, 0xCB, 0x00, 0x55

;	FD CB 00 56
	bit		2, [iy+0]

;	FD CB 00 57 ... FD CB 00 5D	未定義
	defb	0xFD, 0xCB, 0x00, 0x57
	defb	0xFD, 0xCB, 0x00, 0x58
	defb	0xFD, 0xCB, 0x00, 0x59
	defb	0xFD, 0xCB, 0x00, 0x5A
	defb	0xFD, 0xCB, 0x00, 0x5B
	defb	0xFD, 0xCB, 0x00, 0x5C
	defb	0xFD, 0xCB, 0x00, 0x5D

;	FD CB 00 5E
	bit		3, [iy+0]

;	FD CB 00 5F	未定義
	defb	0xFD, 0xCB, 0x00, 0x5F

;	FD CB 00 60 ... FD CB 00 65	未定義
	defb	0xFD, 0xCB, 0x00, 0x60
	defb	0xFD, 0xCB, 0x00, 0x61
	defb	0xFD, 0xCB, 0x00, 0x62
	defb	0xFD, 0xCB, 0x00, 0x63
	defb	0xFD, 0xCB, 0x00, 0x64
	defb	0xFD, 0xCB, 0x00, 0x65

;	FD CB 00 66
	bit		4, [iy+0]

;	FD CB 00 67 ... FD CB 00 6D	未定義
	defb	0xFD, 0xCB, 0x00, 0x67
	defb	0xFD, 0xCB, 0x00, 0x68
	defb	0xFD, 0xCB, 0x00, 0x69
	defb	0xFD, 0xCB, 0x00, 0x6A
	defb	0xFD, 0xCB, 0x00, 0x6B
	defb	0xFD, 0xCB, 0x00, 0x6C
	defb	0xFD, 0xCB, 0x00, 0x6D

;	FD CB 00 6E
	bit		5, [iy+0]

;	FD CB 00 6F	未定義
	defb	0xFD, 0xCB, 0x00, 0x6F

;	FD CB 00 70 ... FD CB 00 75	未定義
	defb	0xFD, 0xCB, 0x00, 0x70
	defb	0xFD, 0xCB, 0x00, 0x71
	defb	0xFD, 0xCB, 0x00, 0x72
	defb	0xFD, 0xCB, 0x00, 0x73
	defb	0xFD, 0xCB, 0x00, 0x74
	defb	0xFD, 0xCB, 0x00, 0x75

;	FD CB 00 76
	bit		6, [iy+0]

;	FD CB 00 77 ... FD CB 00 7D	未定義
	defb	0xFD, 0xCB, 0x00, 0x77
	defb	0xFD, 0xCB, 0x00, 0x78
	defb	0xFD, 0xCB, 0x00, 0x79
	defb	0xFD, 0xCB, 0x00, 0x7A
	defb	0xFD, 0xCB, 0x00, 0x7B
	defb	0xFD, 0xCB, 0x00, 0x7C
	defb	0xFD, 0xCB, 0x00, 0x7D

;	FD CB 00 7E
	bit		7, [iy+0]

;	FD CB 00 7F	未定義
	defb	0xFD, 0xCB, 0x00, 0x7F

;	FD CB 00 80 ... FD CB 00 85	未定義
	defb	0xFD, 0xCB, 0x00, 0x80
	defb	0xFD, 0xCB, 0x00, 0x81
	defb	0xFD, 0xCB, 0x00, 0x82
	defb	0xFD, 0xCB, 0x00, 0x83
	defb	0xFD, 0xCB, 0x00, 0x84
	defb	0xFD, 0xCB, 0x00, 0x85

;	FD CB 00 86
	res		0, [iy+0]

;	FD CB 00 87 ... FD CB 00 8D	未定義
	defb	0xFD, 0xCB, 0x00, 0x87
	defb	0xFD, 0xCB, 0x00, 0x88
	defb	0xFD, 0xCB, 0x00, 0x89
	defb	0xFD, 0xCB, 0x00, 0x8A
	defb	0xFD, 0xCB, 0x00, 0x8B
	defb	0xFD, 0xCB, 0x00, 0x8C
	defb	0xFD, 0xCB, 0x00, 0x8D

;	FD CB 00 8E
	res		1, [iy+0]

;	FD CB 00 8F	未定義
	defb	0xFD, 0xCB, 0x00, 0x8F

;	FD CB 00 90 ... FD CB 00 95	未定義
	defb	0xFD, 0xCB, 0x00, 0x90
	defb	0xFD, 0xCB, 0x00, 0x91
	defb	0xFD, 0xCB, 0x00, 0x92
	defb	0xFD, 0xCB, 0x00, 0x93
	defb	0xFD, 0xCB, 0x00, 0x94
	defb	0xFD, 0xCB, 0x00, 0x95

;	FD CB 00 96
	res		2, [iy+0]

;	FD CB 00 97 ... FD CB 00 9D	未定義
	defb	0xFD, 0xCB, 0x00, 0x97
	defb	0xFD, 0xCB, 0x00, 0x98
	defb	0xFD, 0xCB, 0x00, 0x99
	defb	0xFD, 0xCB, 0x00, 0x9A
	defb	0xFD, 0xCB, 0x00, 0x9B
	defb	0xFD, 0xCB, 0x00, 0x9C
	defb	0xFD, 0xCB, 0x00, 0x9D

;	FD CB 00 9E
	res		3, [iy+0]

;	FD CB 00 9F	未定義
	defb	0xFD, 0xCB, 0x00, 0x9F

;	FD CB 00 A0 ... FD CB 00 A5	未定義
	defb	0xFD, 0xCB, 0x00, 0xA0
	defb	0xFD, 0xCB, 0x00, 0xA1
	defb	0xFD, 0xCB, 0x00, 0xA2
	defb	0xFD, 0xCB, 0x00, 0xA3
	defb	0xFD, 0xCB, 0x00, 0xA4
	defb	0xFD, 0xCB, 0x00, 0xA5

;	FD CB 00 A6
	res		4, [iy+0]

;	FD CB 00 A7 ... FD CB 00 AD	未定義
	defb	0xFD, 0xCB, 0x00, 0xA7
	defb	0xFD, 0xCB, 0x00, 0xA8
	defb	0xFD, 0xCB, 0x00, 0xA9
	defb	0xFD, 0xCB, 0x00, 0xAA
	defb	0xFD, 0xCB, 0x00, 0xAB
	defb	0xFD, 0xCB, 0x00, 0xAC
	defb	0xFD, 0xCB, 0x00, 0xAD

;	FD CB 00 AE
	res		5, [iy+0]

;	FD CB 00 AF	未定義
	defb	0xFD, 0xCB, 0x00, 0xAF

;	FD CB 00 B0 ... FD CB 00 B5	未定義
	defb	0xFD, 0xCB, 0x00, 0xB0
	defb	0xFD, 0xCB, 0x00, 0xB1
	defb	0xFD, 0xCB, 0x00, 0xB2
	defb	0xFD, 0xCB, 0x00, 0xB3
	defb	0xFD, 0xCB, 0x00, 0xB4
	defb	0xFD, 0xCB, 0x00, 0xB5

;	FD CB 00 B6
	res		6, [iy+0]

;	FD CB 00 B7 ... FD CB 00 BD	未定義
	defb	0xFD, 0xCB, 0x00, 0xB7
	defb	0xFD, 0xCB, 0x00, 0xB8
	defb	0xFD, 0xCB, 0x00, 0xB9
	defb	0xFD, 0xCB, 0x00, 0xBA
	defb	0xFD, 0xCB, 0x00, 0xBB
	defb	0xFD, 0xCB, 0x00, 0xBC
	defb	0xFD, 0xCB, 0x00, 0xBD

;	FD CB 00 BE
	res		7, [iy+0]

;	FD CB BF 00	未定義
	defb	0xFD, 0xCB, 0xBF, 0x00

;	FD CB 00 C0 ... FD CB 00 C5	未定義
	defb	0xFD, 0xCB, 0x00, 0xC0
	defb	0xFD, 0xCB, 0x00, 0xC1
	defb	0xFD, 0xCB, 0x00, 0xC2
	defb	0xFD, 0xCB, 0x00, 0xC3
	defb	0xFD, 0xCB, 0x00, 0xC4
	defb	0xFD, 0xCB, 0x00, 0xC5

;	FD CB 00 C6
	set		0, [iy+0]

;	FD CB C7 00 ... FD CB 00 CD	未定義
	defb	0xFD, 0xCB, 0x00, 0xC7
	defb	0xFD, 0xCB, 0x00, 0xC8
	defb	0xFD, 0xCB, 0x00, 0xC9
	defb	0xFD, 0xCB, 0x00, 0xCA
	defb	0xFD, 0xCB, 0x00, 0xCB
	defb	0xFD, 0xCB, 0x00, 0xCC
	defb	0xFD, 0xCB, 0x00, 0xCD

;	FD CB CE 00
	set		1, [iy+0]

;	FD CB CF 00	未定義
	defb	0xFD, 0xCB, 0x00, 0xCF

;	FD CB 00 D0 ... FD CB D5 00	未定義
	defb	0xFD, 0xCB, 0x00, 0xD0
	defb	0xFD, 0xCB, 0x00, 0xD1
	defb	0xFD, 0xCB, 0x00, 0xD2
	defb	0xFD, 0xCB, 0x00, 0xD3
	defb	0xFD, 0xCB, 0x00, 0xD4
	defb	0xFD, 0xCB, 0x00, 0xD5

;	FD CB 00 D6
	set		2, [iy+0]

;	FD CB 00 D7 ... FD CB FD 00	未定義
	defb	0xFD, 0xCB, 0x00, 0xD7
	defb	0xFD, 0xCB, 0x00, 0xD8
	defb	0xFD, 0xCB, 0x00, 0xD9
	defb	0xFD, 0xCB, 0x00, 0xDA
	defb	0xFD, 0xCB, 0x00, 0xDB
	defb	0xFD, 0xCB, 0x00, 0xDC
	defb	0xFD, 0xCB, 0x00, 0xFD

;	FD CB DE 00
	set		3, [iy+0]

;	FD CB 00 DF	未定義
	defb	0xFD, 0xCB, 0x00, 0xDF

;	FD CB 00 E0 ... FD CB E5 00	未定義
	defb	0xFD, 0xCB, 0x00, 0xE0
	defb	0xFD, 0xCB, 0x00, 0xE1
	defb	0xFD, 0xCB, 0x00, 0xE2
	defb	0xFD, 0xCB, 0x00, 0xE3
	defb	0xFD, 0xCB, 0x00, 0xE4
	defb	0xFD, 0xCB, 0x00, 0xE5

;	FD CB 00 E6
	set		4, [iy+0]

;	FD CB 00 E7 ... FD CB ED 00	未定義
	defb	0xFD, 0xCB, 0x00, 0xE7
	defb	0xFD, 0xCB, 0x00, 0xE8
	defb	0xFD, 0xCB, 0x00, 0xE9
	defb	0xFD, 0xCB, 0x00, 0xEA
	defb	0xFD, 0xCB, 0x00, 0xEB
	defb	0xFD, 0xCB, 0x00, 0xEC
	defb	0xFD, 0xCB, 0x00, 0xED

;	FD CB 00 EE
	set		5, [iy+0]

;	FD CB 00 EF	未定義
	defb	0xFD, 0xCB, 0x00, 0xEF

;	FD CB 00 F0 ... FD CB F5 00	未定義
	defb	0xFD, 0xCB, 0x00, 0xF0
	defb	0xFD, 0xCB, 0x00, 0xF1
	defb	0xFD, 0xCB, 0x00, 0xF2
	defb	0xFD, 0xCB, 0x00, 0xF3
	defb	0xFD, 0xCB, 0x00, 0xF4
	defb	0xFD, 0xCB, 0x00, 0xF5

;	FD CB 00 F6
	set		6, [iy+0]

;	FD CB 00 F7 ... FD CB FD 00	未定義
	defb	0xFD, 0xCB, 0x00, 0xF7
	defb	0xFD, 0xCB, 0x00, 0xF8
	defb	0xFD, 0xCB, 0x00, 0xF9
	defb	0xFD, 0xCB, 0x00, 0xFA
	defb	0xFD, 0xCB, 0x00, 0xFB
	defb	0xFD, 0xCB, 0x00, 0xFC
	defb	0xFD, 0xCB, 0x00, 0xFD

;	FD CB 00 FE
	set		7, [iy+0]

;	FD CB FF 00	未定義
	defb	0xFD, 0xCB, 0x00, 0xFF