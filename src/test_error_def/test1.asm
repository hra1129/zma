; -----------------------------------------------------------------------------
;	test program
; -----------------------------------------------------------------------------

;	�����񂪎w�肳��ăG���[
	defb	"aaa"
	defw	"aaa"
	defd	"aaa"

;	�]�v�ȋL�q�������ăG���[
	defb	10 20 30
	defw	10 20 30
	defd	10 20 30
	defs	"aaa" "bbb"

;	�m�肵�Ȃ����������ăG���[
	defb	invalid_label1
	defw	invalid_label2
	defd	invalid_label3
	defs	invalid_label4

;	�J���}�ŏI����Ă��ăG���[
	defb	10,
	defw	10,
	defd	10,

;	�J���}���A�Ȃ��Ă��ďI����Ă��ăG���[
	defb	10,,20
	defw	10,,20
	defd	10,,20
