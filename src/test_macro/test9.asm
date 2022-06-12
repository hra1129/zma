out_rgb	macro	r, g, b
		ld		a, r << 4 | b
		out		[c], a
		ld		a, g
		out		[c], a
		endm

		org		0x100

		out_rgb	7,7,7
		out_rgb	1,2,3
		out_rgb	4,4,4
