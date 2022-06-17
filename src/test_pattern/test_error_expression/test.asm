; -----------------------------------------------------------------------------
;	test program
; -----------------------------------------------------------------------------

;	+ (plus) の右側に数値がないのは不正
	ld		bc, +

;	- (minus) の右側に数値がないのは不正
	ld		bc, -

;	! の右側に数値がないのは不正
	ld		bc, !

;	~ の右側に数値がないのは不正
	ld		bc, ~

;	( の右側に数値がないのは不正
	ld		bc, ()

;	( の右側に数値はあるが ) がないのは不正
	ld		bc, ( 100

;	数字の記述が不正
	ld		bc, 0xABCDEFG
	ld		bc, 012345678
	ld		bc, 0b1234567
	ld		bc, 1234ABCD

;	演算子の右側がない
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

;	不正な演算項
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
