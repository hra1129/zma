add_hl_a	macro
		add		a, l
		ld		l, a
		jr		nc, add_hl_a1
		inc		h
add_hl_a1	:
			endm

		org		0x100

		add_hl_a
		add_hl_a
		add_hl_a
		add_hl_a
