; -----------------------------------------------------------------------------
;	test program
; -----------------------------------------------------------------------------

def_space macro num
		message	num + "バイトの領域を確保する"
		repeat i, num
			defb	0
		endr
	endm

	message "Current Address = " + $
	message "Current Address = " + CODE_ADDRESS
	message "File Address    = " + FILE_ADDRESS

	defb		0xFF
	def_space	2

	message "Current Address = " + $
	message "Current Address = " + CODE_ADDRESS
	message "File Address    = " + FILE_ADDRESS

	defb		0xFF
	def_space	5

	org			0
	message "Current Address = " + $
	message "Current Address = " + CODE_ADDRESS
	message "File Address    = " + FILE_ADDRESS

	defb		0xFF
	def_space	4
