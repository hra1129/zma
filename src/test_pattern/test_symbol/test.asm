; -----------------------------------------------------------------------------
;	test program
; -----------------------------------------------------------------------------

	symbol1 := 10
	symbol2 := "����"
	symbol3 equ 20
	symbol4 equ "����"
	symbol5 = 30
	symbol6 = "�\��"

	message		"�O��1"
	message		"SYMBOL1 = " + symbol1
	message		"SYMBOL2 = " + symbol2
	message		"SYMBOL3 = " + symbol3
	message		"SYMBOL4 = " + symbol4
	message		"SYMBOL5 = " + symbol5
	message		"SYMBOL6 = " + symbol6

	scope	local
		symbol1 = 100
		symbol2 = "MSX"

		message		"�X�R�[�v LOCAL �̒�"
		message		"SYMBOL1 = " + symbol1
		message		"SYMBOL2 = " + symbol2
		message		"SYMBOL3 = " + symbol3
		message		"SYMBOL4 = " + symbol4
		message		"SYMBOL5 = " + symbol5
		message		"SYMBOL6 = " + symbol6

	endscope

	message		"�O��2"
	message		"SYMBOL1 = " + symbol1
	message		"SYMBOL2 = " + symbol2
	message		"SYMBOL3 = " + symbol3
	message		"SYMBOL4 = " + symbol4
	message		"SYMBOL5 = " + symbol5
	message		"SYMBOL6 = " + symbol6
