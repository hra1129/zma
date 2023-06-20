; -----------------------------------------------------------------------------
;	MSX ROM sample program
; =============================================================================
;	2019/07/06	t.hara
; -----------------------------------------------------------------------------

		include		"msx.asm"

		org			0x4000
		rom_header	entry_point

; -----------------------------------------------------------------------------
;	entry point
; -----------------------------------------------------------------------------
entry_point::
		ld			sp, [himem]
		call		initialize
		call		main
		jr			entry_point

; -----------------------------------------------------------------------------
;	initialize
; -----------------------------------------------------------------------------
		scope		sc_initialize
initialize::
		;	Initialize work area
		xor			a, a
		ld			[sec_counter], a
		ld			[music_index], a

		;	Initialize PSG
		call		GICINI

		;	Update timer hook
		di
		ld			hl, h_timi
		ld			de, old_h_timi
		ld			bc, 5
		ldir

		ld			hl, new_h_timi
		ld			de, h_timi
		ld			bc, 3
		ldir
		ei

		ret
		endscope

; -----------------------------------------------------------------------------
;	VSYNC interrupt hook
; -----------------------------------------------------------------------------
new_h_timi::
		jp			interrupt_handler

; -----------------------------------------------------------------------------
;	main
; -----------------------------------------------------------------------------
		scope		sc_main
main::
	end_loop:
		jp			end_loop
		endscope

; -----------------------------------------------------------------------------
;	interrupt handler
; -----------------------------------------------------------------------------
		scope		sc_interrupt_handler
interrupt_handler::
		push		hl
		push		af

		;	1秒をカウントするタイマー
		ld			a, [sec_counter]
		inc			a
		ld			[sec_counter], a
		cp			a, 60
		jp			nz, exit

		xor			a, a
		ld			[sec_counter], a

		;	1秒経過した
		push		bc
		push		de
		call		play_music
		pop			de
		pop			bc

	exit:
		pop			af
		pop			hl
		jp			old_h_timi
		endscope

; -----------------------------------------------------------------------------
;	音楽演奏
; -----------------------------------------------------------------------------
		scope		sc_play_music
play_music::
		;			a ← music_table[ music_index ]
		ld			a, [music_index]
		ld			c, a
		inc			a
		ld			[music_index], a
		ld			b, 0
		ld			hl, music_table
		add			hl, bc
		ld			a, [hl]
		cp			a, T_R
		jp			z, rest_process
		jp			nc, rewind_process
	tone_process:
		;			de ← tone_table[a]
		ld			c, a
		ld			hl, tone_table
		add			hl, bc
		add			hl, bc
		ld			e, [hl]
		inc			hl
		ld			d, [hl]
		;			sound 0, e: sound 1, d: sound 8, 15
		ld			c, IO_PSG_ADR
		xor			a, a
		out			[c], a
		inc			c
		out			[c], e
		dec			c

		inc			a
		out			[c], a
		inc			c
		out			[c], d
		dec			c

		ld			a, 8
		out			[c], a
		inc			c
		ld			a, 15
		out			[c], a
		dec			c
		ret
	rest_process:
		;			sound 8, 0
		ld			c, IO_PSG_ADR
		ld			a, 8
		out			[c], a
		inc			c
		ld			a, 0
		out			[c], a
		ret
	rewind_process:
		xor			a, a
		ld			[music_index], a
		jp			play_music
		endscope

; -----------------------------------------------------------------------------
;	音程設定値テーブル
; -----------------------------------------------------------------------------
tone_table::
		dw			0xD5C,	0xC9D,	0xBE7,	0xB3C,	0xA9B,	0xA02,	0x973,	0x8EB,	0x86B,	0x7F2,	0x780,	0x714
		dw			0x6AE,	0x64E,	0x5F4,	0x59E,	0x54D,	0x501,	0x4B9,	0x475,	0x435,	0x3F9,	0x3C0,	0x38A
		dw			0x357,	0x327,	0x2FA,	0x2CF,	0x2A7,	0x281,	0x25D,	0x23B,	0x21B,	0x1FC,	0x1E0,	0x1C5
		dw			0x1AC,	0x194,	0x17D,	0x168,	0x153,	0x140,	0x12E,	0x11D,	0x10D,	0xFE,	0xF0,	0xE2
		dw			0xD6,	0xCA,	0xBE,	0xB4,	0xAA,	0xA0,	0x97,	0x8F,	0x87,	0x7F,	0x78,	0x71
		dw			0x6B,	0x65,	0x5F,	0x5A,	0x55,	0x50,	0x4C,	0x47,	0x43,	0x40,	0x3C,	0x39
		dw			0x35,	0x32,	0x30,	0x2D,	0x2A,	0x28,	0x26,	0x24,	0x22,	0x20,	0x1E,	0x1C
		dw			0x1B,	0x19,	0x18,	0x16,	0x15,	0x14,	0x13,	0x12,	0x11,	0x10,	0xF,	0xE

T_C		:= 0
T_CS	:= 1
T_D		:= 2
T_DS	:= 3
T_E		:= 4
T_F		:= 5
T_FS	:= 6
T_G		:= 7
T_GS	:= 8
T_A		:= 9
T_AS	:= 10
T_B		:= 11
O1		:= 0 * 12
O2		:= 1 * 12
O3		:= 2 * 12
O4		:= 3 * 12
O5		:= 4 * 12
O6		:= 5 * 12
O7		:= 6 * 12
O8		:= 7 * 12
T_R		:= 254
T_END	:= 255

music_table::
		db			O4+T_C, O4+T_D, O4+T_E, T_R
		db			O4+T_C, O4+T_D, O4+T_E, T_R
		db			O4+T_G, O4+T_E, O4+T_D, O4+T_C
		db			O4+T_D, O4+T_E, O4+T_D, T_R, T_END

; -----------------------------------------------------------------------------
;	PADDING
; -----------------------------------------------------------------------------
		rom_align

; -----------------------------------------------------------------------------
;	work area
; -----------------------------------------------------------------------------
old_h_timi			:= 0xC000
sec_counter			:= old_h_timi + 5
music_index			:= sec_counter + 1
