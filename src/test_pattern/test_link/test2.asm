	link	sub1		; ˆê”Ôã‚Ìs
sub1:
			ld	a, 1
			ret
	endl

	call	sub1


hoge macro
	link	sub2
sub2:
			ld	a, 2
			ret
	endl
	endm

	hoge
