; -----------------------------------------------------------------------------
;	test program
; -----------------------------------------------------------------------------

	add		ix, bc
	add		ix, de
	add		ix, ix
	add		ix, sp

	add		iy, bc
	add		iy, de
	add		iy, iy
	add		iy, sp

	out		[c], 0
	in		f, [c]

	set		0, [ix+0], a
	res		0, [ix+0], a
	bit		0, [ix+0], a

	rr		[ix+1], a
	rl		[ix+1], a
	sra		[ix+1], a
	srl		[ix+1], a
	sll		[ix+1], a
