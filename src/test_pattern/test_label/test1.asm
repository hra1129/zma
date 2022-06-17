; -----------------------------------------------------------------------------
;	test program
; -----------------------------------------------------------------------------

	org		0x100
label_0x100:
	if label_0x100 == 0x100
		message "LABEL_0x100 is OK."
	else
		error   "LABEL_0x100 is failed."
	endif

label_0x200 = 0x200
	if label_0x200 == 0x200
		message "LABEL_0x200 is OK."
	else
		error   "LABEL_0x200 is failed."
	endif

	org		0x300
label_0x300::
	if label_0x300 == 0x300
		message "LABEL_0x300 is OK."
	else
		error   "LABEL_0x300 is failed."
	endif

label_0x400 := 0x400
	if label_0x400 == 0x400
		message "LABEL_0x400 is OK."
	else
		error   "LABEL_0x400 is failed."
	endif

	scope	sub1
		ld	a, d

		label_0x300 = 300
		if label_0x300 == 300
			message "sub1:LABEL_0x300 is OK."
			ld a, b
		else
			error   "sub1:LABEL_0x300 is failed."
			ld b, c
		endif

		label_0x400 = 400
		if label_0x400 == 400
			message "sub1:LABEL_0x400 is OK."
		else
			error   "sub1:LABEL_0x400 is failed."
		endif
	endscope
