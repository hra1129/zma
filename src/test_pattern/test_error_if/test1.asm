; -----------------------------------------------------------------------------
;	test program
; -----------------------------------------------------------------------------

;	いきなり elseif でエラー
	elseif 0
		defb	1
	endif

;	いきなり else でエラー
	else
		defb	2
	endif

;	余計な記述があってエラー
	if	1
		defb	3
	endif	hogehoge

	if	0
		defb	4
	elseif 0
		defb	5
	else	hogehoge
		defb	6
	endif

	if	0
		defb	4
	elseif 0		hogehoge
		defb	5
	else
		defb	6
	endif

	if	0
		defb	4
	elseif 1		hogehoge
		defb	5
	else
		defb	6
	endif

	if	1		hogehoge
		defb	4
	elseif 0
		defb	5
	else
		defb	6
	endif

	if	0		hogehoge
		defb	4
	elseif 0
		defb	5
	else
		defb	6
	endif

;	条件が確定せずにエラー
	if	LABEL1 == 100
		defb	10
	else
		defb	11,12
	endif
LABEL1:

;	条件が確定せずにエラー
	if 1
		defs	" " * LABEL1
	else
		defs	" " * 3
	endif
