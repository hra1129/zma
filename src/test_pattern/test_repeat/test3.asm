; -----------------------------------------------------------------------------
;	test program
; -----------------------------------------------------------------------------

; 繰り返しカウンター値が、repeat より後で定義されている
	repeat i, label
		defb	i + label
	endr

label = 5
