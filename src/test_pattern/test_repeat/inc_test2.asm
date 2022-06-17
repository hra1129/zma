SHOT_ATTRIBUTE	macro
	db			0				; 0: disable, 1: enable
	dw			0				; delta X
	dw			0				; X position
	dw			0				; delta Y
	dw			0				; Y position
	db			0				; animation counter 0...15
	dw			0				; reserved
	dw			0				; reserved
	dw			0				; reserved
			endm

shot_table:
	repeat I, 32
		SHOT_ATTRIBUTE
	endr

	dw			1
