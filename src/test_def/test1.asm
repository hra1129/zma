; -----------------------------------------------------------------------------
;	test program
; -----------------------------------------------------------------------------

label0:
	defb	10, 20, 30, label0, label1
	defw	10, 20, 30, label0, label1
	defd	10, 20, 30, label0, label1
	defs	"aaa" + "bbb"
label1:
	defs	10

	db		10, 20, 30, label0, label1
	dw		10, 20, 30, label0, label1
	dd		10, 20, 30, label0, label1
	ds		"aaa" + "bbb"
	db		'a'
	db		'\n'
	ds		"string\r\n"
