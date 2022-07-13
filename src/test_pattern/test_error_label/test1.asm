; -----------------------------------------------------------------------------
;	test program
; -----------------------------------------------------------------------------

	org		0x100

label_900 = label_999
label_901 := label_999
label_999:

;	同じ名前のラベルが複数宣言されている
label_0x100:
label_0x100:

label_0x200:
label_0x200::

label_0x300:
label_0x300 = 2
label_0x300 = "2"

label_0x400:
label_0x400 := 2
label_0x400 := "2"

label_0x500::
label_0x500 = 2
label_0x500 = "2"

label_0x600::
label_0x600 := 2
label_0x600 := "2"

label_0x700::
label_0x700::

label_0x800 := "2"
label_0x800 := "2"

label_0x900 = "2"
label_0x900 = "2"

label_0xA00 := 2
label_0xA00 := 2

;	ラベルの値が確定せずにエラー
	defs	ll
ll:

label_1:
label_2::
label_3 = $
label_4 := FILE_ADDRESS

;	文字列をラベル名として記述してエラー
	org		0x200
"漢字1":
"漢字2"::
"漢字3" = 1
"漢字4" := 2

;	余計な記述があってエラー
	org		0x300
label1_1:		aaa
label1_2::		aaa
label1_3 = $	aaa
label1_4 := $	aaa

;	式が確定せずにエラー
	org		0x500
label2_3 = invalid_label
label2_4 := invalid_label

;	不正な式でエラー
label2_5 = -
label2_6 := -

;	先に文字列で宣言した後にアドレスラベルとして宣言してエラー
label3	= "abcd"
label3:
label3::
label3	= 10

label4	= 10
label4	= "abcd"
label4:
label4::

	space	invalid_label2
invalid_label2:
