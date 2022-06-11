; -----------------------------------------------------------------------------
;	test program
; -----------------------------------------------------------------------------

	message	"Current char set is [" + CHAR_SET_NAME + "]"

	ld		a, 'A'
	db		'A'
	ds		"ABCDEFG"

	chg_char_set	"HOGEHOGE_SET"
	mapping_char	'A', 10, 'F', 2
	mapping_char	'G', 20
	mapping_char	'O', 30, 'H'
	mapping_char	'P', 40, 'Z', -1
	message	"Current char set is [" + CHAR_SET_NAME + "]"

	ld		a, 'A'
	db		'A'
	ds		"ABCDEFG"

	chg_char_set	"DEFAULT"
	message	"Current char set is [" + CHAR_SET_NAME + "]"

	ld		a, 'A'
	db		'A'
	ds		"ABCDEFG"

	chg_char_set	"HOGEHOGE_SET"
	message	"Current char set is [" + CHAR_SET_NAME + "]"

	ld		a, 'A'
	db		'A'
	ds		"ABCDEFG"
