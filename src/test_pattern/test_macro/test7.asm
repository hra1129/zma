GOTO	macro	label
			if label - $ + 2 < -128
				jp	label
			else
				jr	label
			endif
		endm

		org		0x100
l1:
		goto	l1
		space	256
		goto	l1
