; -----------------------------------------------------------------------------
;	test program
; -----------------------------------------------------------------------------

	include		"sub_test.asm"
	include		"sub_test.asm"

	add_include_path	"sub"
	add_include_path	"sub2/"

	include		"sub_test2.asm"
	include		"sub_test3.asm"

	ld			bc, 0x4523
	ret
