; -----------------------------------------------------------------------------
;	test program
; -----------------------------------------------------------------------------

;	IF�̒��� ENDSCOPE ����͕̂s��
		SCOPE	AAA
		DEFB	1

		IF 1
			ENDSCOPE
		ENDIF

;	SCOPE �ɃX�R�[�v���̎w�肪����
		SCOPE

;	�]�v�ȋL�q�������ăG���[
		SCOPE	BBB	CCC

		SCOPE	DDD
		ENDSCOPE	DDD
