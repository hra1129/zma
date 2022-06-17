palette	macro		palette_no, red, green, blue
		ld			b, palette_no
		ld			de, ((green) << 8) | ((red) << 4) | (blue)
		endm
		palette		 0, 0, 0, 0
		palette		 1, 1, 0, 0
		palette		 2, 2, 0, 0
		palette		 3, 3, 0, 0
