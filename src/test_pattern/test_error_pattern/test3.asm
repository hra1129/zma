; -----------------------------------------------------------------------------
;	test program
; -----------------------------------------------------------------------------

; 範囲外の値
	ld		a, 1000
	ld		hl, 99999

; 不正な命令
	ld		[ix+1],hl

	ld		a, 0A0h
	ld		a, 10h
	ld		a, 20h
	ld		a, A0h

; 未定義ラベル
	error	aaa
	message	aaa

; 値が確定しない整数ラベル
	error	bbb
	message	bbb

; 値が確定しない
hoge = bbb
moge := bbb
s_hoge = "aaa" + bbb
s_moge := "aaa" + bbb

; 値が確定しないラベル
	xxx					; 不正な命令
l1:
	error	l1

	space	bbb
bbb:
