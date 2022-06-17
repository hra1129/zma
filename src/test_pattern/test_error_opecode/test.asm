; -----------------------------------------------------------------------------
;	test program
; -----------------------------------------------------------------------------

;	error命令でエラーが発生する
	error	"user error!!!"
	error
	error	+
	error	100
	error	hoge

;	message命令でエラーが発生する
	message
	message	+
	message	100
	message	monmon

;	ADD_INCLUDE_PATH命令でエラーが発生する
	add_include_path
	add_include_path	+
	add_include_path	100

;	存在しない命令の記述でエラーになる
	invalid_opecode

;	相対アドレッシングの範囲外
	ld		a, [ix - 129]
	ld		a, [ix + 128]
	ld		a, [iy - 129]
	ld		a, [iy + 128]
	ld		[ix - 129], a
	ld		[ix + 128], a
	ld		[iy - 129], a
	ld		[iy + 128], a
	inc		[ix - 129]
	inc		[ix + 128]
	inc		[iy - 129]
	inc		[iy + 128]

;	対になる記号が足りない
	ld		a, 
	ld		a, [
	ld		a, [hl
	ld		a, [ix
	ld		a, [iy
	ld		a, [ix+
	ld		a, [iy+
	ld		a, [ix-
	ld		a, [iy-
	ld		a, [ix+1
	ld		a, [iy+1
	ld		a, [ix-1
	ld		a, [iy-1
	inc		
	inc		[
	inc		[hl
	inc		[ix
	inc		[iy
	inc		[ix+
	inc		[iy+
	inc		[ix-
	inc		[iy-
	inc		[ix+1
	inc		[iy+1
	inc		[ix-1
	inc		[iy-1

;	余計な記述がある
	ld		a, [ix+1] aaa
	nop		aaa
	ccf		aaa
	muluw	bc, de	aaa
	mulub	c, d	aaa
	rrd		aaa
	rld		aaa
	daa		aaa
	otdr	aaa
	outd	aaa
	otir	aaa
	outi	aaa
	out		[c], a aaa
	indr	aaa
	ind		aaa
	inir	aaa
	ini		aaa
	in		a, [c]	aaa
	im0		aaa
	im1		aaa
	im2		aaa
	di		aaa
	ei		aaa
	halt	aaa
	rst		0x38	aaa
	retn	aaa
	reti	aaa
	ret		aaa
	call	0	aaa
	call	z,0	aaa
	djnz	0	aaa
	jr		0	aaa
	jr		z,0	aaa
	jp		0	aaa
	jp		z,0	aaa
	cp		a, b	aaa
	cp		a, 10	aaa
	cp		a, [hl]	aaa
	cp		a, [ix]	aaa
	cp		a, [ix+1]	aaa
	cpdr	aaa
	cpd		aaa
	cpir	aaa
	cpi		aaa
	set		1,a	aaa
	res		1,a	aaa
	bit		1,a	aaa
	scf		aaa
	neg		aaa
	cpl		aaa
	xor		a,a	aaa
	or		a,a	aaa
	and		a,a	aaa
	sbc		a,a	aaa
	sub		a,a	aaa
	adc		a,a	aaa
	add		a,a	aaa
	dec		a	aaa
	srl		a	aaa
	sra		a	aaa
	sla		a	aaa
	rr		a	aaa
	rrc		a	aaa
	rra		aaa
	rrca	aaa
	rl		a	aaa
	rlc		a	aaa
	rla		aaa
	rlca	aaa
	pop		hl	aaa
	push	hl	aaa
	ex		de, hl	aaa
	exx		aaa
	lddr	aaa
	ldd		aaa
	ldir	aaa
	ldi		aaa

;	RST命令でエラーになる
	rst
	rst		+
	rst		0x12345
	rst		"hoge"

;	ex命令でエラーになる
	ex		[sp], de

;	飛び先に文字列でエラー
	jr		"hoge"
	jp		"hoge"
	call	"hoge"

;	相対ジャンプの範囲外でエラー
	org		256
	jr		127
	jr		1000

;	ixh, ixl, iyh, iyl で存在しない組み合わせエラー
	ld		ixh, ixh
	ld		ixh, ixl
	ld		ixh, iyh
	ld		ixh, iyl
	ld		ixl, ixh
	ld		ixl, ixl
	ld		ixl, iyh
	ld		ixl, iyl
	ld		iyh, ixh
	ld		iyh, ixl
	ld		iyh, iyh
	ld		iyh, iyl
	ld		iyl, ixh
	ld		iyl, ixl
	ld		iyl, iyh
	ld		iyl, iyl
	ld		h, ixh
	ld		h, ixl
	ld		h, iyh
	ld		h, iyl
	ld		l, ixh
	ld		l, ixl
	ld		l, iyh
	ld		l, iyl

;	不正なオペランド
	ld		[ix+0], [hl]
	ld		[ix+0], [123]
	ld		[hl], [ix+0]
	ld		[123], [ix+0]
