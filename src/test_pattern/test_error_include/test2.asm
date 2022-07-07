; -----------------------------------------------------------------------------
;	test program
; -----------------------------------------------------------------------------

	include		"sub_repeat.asm"
	endr							; include内の repeat を、include外で閉じるのは禁止

	include		"sub_macro.asm"
	endm							; include内の macro を、include外で閉じるのは禁止

	include		"sub_if.asm"
	endif							; include内の if を、include外で閉じるのは禁止

	include		"sub_scope.asm"
	endscope
