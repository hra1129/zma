; -----------------------------------------------------------------------------
;	test program
; -----------------------------------------------------------------------------

; �͈͊O�̒l
	ld		a, 1000
	ld		hl, 99999

; �s���Ȗ���
	ld		[ix+1],hl

	ld		a, 0A0h
	ld		a, 10h
	ld		a, 20h
	ld		a, A0h

; ����`���x��
	error	aaa
	message	aaa

; �l���m�肵�Ȃ��������x��
	error	bbb
	message	bbb

; �l���m�肵�Ȃ�
hoge = bbb
moge := bbb
s_hoge = "aaa" + bbb
s_moge := "aaa" + bbb

; �l���m�肵�Ȃ����x��
	xxx					; �s���Ȗ���
l1:
	error	l1

	space	bbb
bbb:
