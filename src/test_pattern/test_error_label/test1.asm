; -----------------------------------------------------------------------------
;	test program
; -----------------------------------------------------------------------------

	org		0x100

label_900 = label_999
label_901 := label_999
label_999:

;	�������O�̃��x���������錾����Ă���
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

;	���x���̒l���m�肹���ɃG���[
	defs	ll
ll:

label_1:
label_2::
label_3 = $
label_4 := FILE_ADDRESS

;	����������x�����Ƃ��ċL�q���ăG���[
	org		0x200
"����1":
"����2"::
"����3" = 1
"����4" := 2

;	�]�v�ȋL�q�������ăG���[
	org		0x300
label1_1:		aaa
label1_2::		aaa
label1_3 = $	aaa
label1_4 := $	aaa

;	�����m�肹���ɃG���[
	org		0x500
label2_3 = invalid_label
label2_4 := invalid_label

;	�s���Ȏ��ŃG���[
label2_5 = -
label2_6 := -

;	��ɕ�����Ő錾������ɃA�h���X���x���Ƃ��Đ錾���ăG���[
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
