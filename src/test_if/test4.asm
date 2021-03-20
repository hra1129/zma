; -----------------------------------------------------------------------------
;	test program
; -----------------------------------------------------------------------------

use_hoge	MACRO	flag
		if flag
			message	"aaaaaaaa"
		else
			message	"bbbbbbbb"
			message	"cccccccc"
		endif
	ENDM

			use_hoge	1
