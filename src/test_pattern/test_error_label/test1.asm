; -----------------------------------------------------------------------------
;	test program
; -----------------------------------------------------------------------------

	org		0x100

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

;	�]�v�ȋL�q�������ăG���[
	org		0x500
label2_3 = invalid_label
label2_4 := invalid_label

;	��ɕ�����Ő錾������ɃA�h���X���x���Ƃ��Đ錾���ăG���[
label3	= "abcd"
label3:
label3::
label3	= 10

label4	= 10
label4	= "abcd"
label4:
label4::
