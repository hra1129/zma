; -----------------------------------------------------------------------------
;	test program
; -----------------------------------------------------------------------------

	include		"test_inc.asm"

	defw	end_of_program

	TITLE_COLOR = 0

	if TITLE_COLOR == 0
		LD		A, 0
	endif

end_of_program:
