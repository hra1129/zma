; -----------------------------------------------------------------------------
;	test program
; -----------------------------------------------------------------------------

;	+ (plus) �̉E���ɐ��l���Ȃ��͕̂s��
	ld		bc, +

;	- (minus) �̉E���ɐ��l���Ȃ��͕̂s��
	ld		bc, -

;	! �̉E���ɐ��l���Ȃ��͕̂s��
	ld		bc, !

;	~ �̉E���ɐ��l���Ȃ��͕̂s��
	ld		bc, ~

;	( �̉E���ɐ��l���Ȃ��͕̂s��
	ld		bc, ()

;	( �̉E���ɐ��l�͂��邪 ) ���Ȃ��͕̂s��
	ld		bc, ( 100

;	�����̋L�q���s��
	ld		bc, 0xABCDEFG
	ld		bc, 012345678
	ld		bc, 0b1234567
	ld		bc, 1234ABCD

;	���Z�q�̉E�����Ȃ�
	ld		bc, 2*
	ld		bc, 2/
	ld		bc, 2%
	ld		bc, 2+
	ld		bc, 2-
	ld		bc, 2>>
	ld		bc, 2<<
	ld		bc, 2<
	ld		bc, 2>
	ld		bc, 2<=
	ld		bc, 2>=
	ld		bc, 2==
	ld		bc, 2!=
	ld		bc, 2&
	ld		bc, 2|
	ld		bc, 2^
	ld		bc, 2&&
	ld		bc, 2||

;	�s���ȉ��Z��
	ld		bc, 10 / 0
	ld		bc, 10 % 0
	message	"aa" * "bb"
	message	"aa" / "bb"
	message	"aa" % "bb"
	message	"aa" - "bb"
	message	"aa" | "bb"
	message	"aa" & "bb"
	message	"aa" ^ "bb"
	message	"aa" && "bb"
	message	"aa" || "bb"
	message	"aa" >> "bb"
	message	"aa" << "bb"
	message	"aa" > "bb"
	message	"aa" < "bb"
	message	"aa" >= "bb"
	message	"aa" <= "bb"
	message	20 * "bb"
	message	20 / "bb"
	message	20 % "bb"
	message	20 - "bb"
	message	20 | "bb"
	message	20 & "bb"
	message	20 ^ "bb"
	message	20 && "bb"
	message	20 || "bb"
	message	20 >> "bb"
	message	20 << "bb"
	message	20 > "bb"
	message	20 < "bb"
	message	20 >= "bb"
	message	20 <= "bb"
	ld		bc, 10 + INVALID_LABEL
