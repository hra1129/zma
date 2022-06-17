; -----------------------------------------------------------------------------
;	test program
; -----------------------------------------------------------------------------

	symbol1 := 10
	symbol2 := "漢字"
	symbol3 equ 20
	symbol4 equ "文字"
	symbol5 = 30
	symbol6 = "表示"

	message		"外側1"
	message		"SYMBOL1 = " + symbol1
	message		"SYMBOL2 = " + symbol2
	message		"SYMBOL3 = " + symbol3
	message		"SYMBOL4 = " + symbol4
	message		"SYMBOL5 = " + symbol5
	message		"SYMBOL6 = " + symbol6

	scope	local
		symbol1 = 100
		symbol2 = "MSX"

		message		"スコープ LOCAL の中"
		message		"SYMBOL1 = " + symbol1
		message		"SYMBOL2 = " + symbol2
		message		"SYMBOL3 = " + symbol3
		message		"SYMBOL4 = " + symbol4
		message		"SYMBOL5 = " + symbol5
		message		"SYMBOL6 = " + symbol6

	endscope

	message		"外側2"
	message		"SYMBOL1 = " + symbol1
	message		"SYMBOL2 = " + symbol2
	message		"SYMBOL3 = " + symbol3
	message		"SYMBOL4 = " + symbol4
	message		"SYMBOL5 = " + symbol5
	message		"SYMBOL6 = " + symbol6
