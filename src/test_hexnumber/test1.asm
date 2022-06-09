; -----------------------------------------------------------------------------
;	test program
; -----------------------------------------------------------------------------

	org		0x100

	ld		hl, 0x1234
	ld		hl, 0xDEAD

	ld		hl, 1234H
	ld		hl, 0DEADH

	ld		hl, 1234h
	ld		hl, 0DEADh

	ld		hl, $1234
	ld		hl, $DEAD

	ld		a, 0x12
	ld		a, 0xDE

	ld		a, 12H
	ld		a, 0DH

	ld		a, 12h
	ld		a, 0Dh

	ld		a, $12
	ld		a, $DE

	ld		hl, $
	ld		hl, $$

	ld		hl, CODE_ADDRESS
	ld		hl, FILE_ADDRESS
