; -----------------------------------------------------------------------------
;	test program
; -----------------------------------------------------------------------------

;	IFの中で ENDSCOPE するのは不正
		SCOPE	AAA
		DEFB	1

		IF 1
			ENDSCOPE
		ENDIF

;	SCOPE にスコープ名の指定が無い
		SCOPE

;	余計な記述があってエラー
		SCOPE	BBB	CCC

		SCOPE	DDD
		ENDSCOPE	DDD
