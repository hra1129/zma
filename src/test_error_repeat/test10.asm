; -----------------------------------------------------------------------------
;	test program
; -----------------------------------------------------------------------------

;	repeat の引数を評価できずにエラー
	REPEAT	I, "hoge"
		DEFB	2
	ENDR
