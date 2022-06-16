; -----------------------------------------------------------------------------
;	test program
; -----------------------------------------------------------------------------

		org		0x100

		or		a, a
		xxx		a, a, a			; ERROR

l1:
		cp		l1
		xor		a
		or		a
		and		a
		ld		a, 1
		ld		b, 1
		jr		l1

		org		0x200

l2:
		cp		a
		xor		a
		or		a
		and		a
		ld		a, 1
		ld		b, 1
		ret
