; -----------------------------------------------------------------------------
;	test program
; -----------------------------------------------------------------------------

	if 0
		defb	1
	else
		defb	2
	endif

	if 1
		defb	3
	endif

	if 0
		defb	4
	elseif 1
		defb	5
	endif

	if 0
		defb	6
	elseif 0
		defb	7
	else
		defb	8
	endif

	if	1
		if	1
			defb	9
		endif
	endif

	if 0
		defb	10
	elseif 0
		defb	11,12
	else
		defb	11,12,13
	endif

	if 0
		defb	14
	endif
