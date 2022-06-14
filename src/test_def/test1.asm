; -----------------------------------------------------------------------------
;	test program
; -----------------------------------------------------------------------------

label0:
	defb	10, 20, 30, label0, label1, "mojiretsu"
label1:
	db		10, 20, 30, label0, label1, "mojiretsu"

label2:
	defw	10, 20, 30, label2, label3
label3:
	dw		10, 20, 30, label2, label3

label4:
	defd	10, 20, 30, label4, label5
label5:
	dd		10, 20, 30, label4, label5

	defs	"mojiretsu"
	ds		"mojiretsu"
