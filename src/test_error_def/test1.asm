; -----------------------------------------------------------------------------
;	test program
; -----------------------------------------------------------------------------

;	文字列が指定されてエラー
	defb	"aaa"
	defw	"aaa"
	defd	"aaa"

;	余計な記述があってエラー
	defb	10 20 30
	defw	10 20 30
	defd	10 20 30
	defs	"aaa" "bbb"

;	確定しない式があってエラー
	defb	invalid_label1
	defw	invalid_label2
	defd	invalid_label3
	defs	invalid_label4

;	カンマで終わっていてエラー
	defb	10,
	defw	10,
	defd	10,

;	カンマが連なっていて終わっていてエラー
	defb	10,,20
	defw	10,,20
	defd	10,,20
