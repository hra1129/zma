	link	sub1		; 一番上の行
sub1:
			ld	a, 1
			ret
	endl

	call	sub1


hoge macro
	link	sub2
sub2:
			ld	a, 2
			ret
	endl
	endm

	hoge
