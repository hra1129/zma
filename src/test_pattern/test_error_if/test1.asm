; -----------------------------------------------------------------------------
;	test program
; -----------------------------------------------------------------------------

;	�����Ȃ� elseif �ŃG���[
	elseif 0
		defb	1
	endif

;	�����Ȃ� else �ŃG���[
	else
		defb	2
	endif

;	�]�v�ȋL�q�������ăG���[
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

;	�������m�肹���ɃG���[
	if	LABEL1 == 100
		defb	10
	else
		defb	11,12
	endif
LABEL1:

;	�������m�肹���ɃG���[
	if 1
		defs	" " * LABEL1
	else
		defs	" " * 3
	endif
