; ==============================================================================
;	IPL-ROM for OCM-PLD v3.9 or later
;	VDP initializer
; ------------------------------------------------------------------------------
; Copyright (c) 2006 Kazuhiro Tsujikawa (ESE Artists' factory)
; All rights reserved.
;
; Redistribution and use of this source code or any derivative works, are
; permitted provided that the following conditions are met:
;
; 1. Redistributions of source code must retain the above copyright notice,
;	 this list of conditions and the following disclaimer.
; 2. Redistributions in binary form must reproduce the above copyright
;	 notice, this list of conditions and the following disclaimer in the
;	 documentation and/or other materials provided with the distribution.
; 3. Redistributions may not be sold, nor may they be used in a commercial
;	 product or activity without specific prior written permission.
;
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
; "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
; TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
; PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
; CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
; EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
; PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
; WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
; OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
; ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
; ------------------------------------------------------------------------------
; History:
;   2021/Aug/12th  t.hara  Overall revision.
; ==============================================================================

; --------------------------------------------------------------------
;	I/O
; --------------------------------------------------------------------
vdp_port0						:= 0x98
vdp_port1						:= 0x99
vdp_port2						:= 0x9A
vdp_port3						:= 0x9B

; --------------------------------------------------------------------
;	Initialize VDP
;	input:
;		none
;	output:
;		none
;	break:
;		B,C,H,L
;	comment:
;		MSX2 and later BIOS initialize the palette in the BIOS.
;		However, the MSX1 BIOS does not initialize the palette.
;		In this section, we will initialize the palette to get MSX1-like 
;		hues when trying MSX1-BIOS with SDBIOS.
; --------------------------------------------------------------------
			scope		init_vdp
init_vdp::
			ld			hl, vdp_control_regs
			ld			bc, ((vdp_control_regs_end - vdp_control_regs) << 8) | vdp_port1
			otir
			ld			bc, ((vdp_msx1_palette_regs_end - vdp_msx1_palette_regs) << 8) | vdp_port2
			otir

			; clear pattern generator table and name table
			ld			hl, 0
			call		vdp_set_vram_address
			ld			de, 256 * 8 + 768
			xor			a, a
			call		vdp_fill_vram

			; clear color table
			ld			h, 0x0B
			call		vdp_set_vram_address
			ld			de, 32
			ld			a, 0xF0
			call		vdp_fill_vram

			; set icon pattern to pattern generator table
			ld			hl, 1 * 8
			call		vdp_set_vram_address
			dec			c
			ld			hl, icon_pattern
			ld			b, icon_pattern_end - icon_pattern
			otir

;;			; set FONT pattern
;;			ld		hl, 0x0000 + 32*8
;;			call	vdp_set_vram_address
;;			ld		hl, font_data
;;			ld		bc, (0x00 << 8) | vdp_port0
;;			otir
;;			otir
;;			otir
;;			ld		hl, 0x0800 + 32 * 2
;;			call	vdp_set_vram_address
			ret

			; VDP port 99h [set register]
vdp_control_regs:
			db		0x00, 0x80				; 0x00 -> R#0 : SCREEN1 (GRAPHIC1 Mode)
			db		0x40, 0x81				; 0x40 -> R#1 : SCREEN1 (GRAPHIC1 Mode)
			db		0x02, 0x82				; 0x02 -> R#2 : Pattern Name Table is 0x0800
			db		0x2C, 0x83				; 0x2C -> R#3 : Color Table is 0x0B00
			db		0x00, 0x84				; 0x00 -> R#4 : Pattern Generator Table is 0x0000
			db		0x03, 0x85				; 0x03 -> R#5 : Sprite Attribute Table is 0x0180
			db		0xF1, 0x87				; 0xF4 -> R#7 : Set Color (White on Black)
			db		0x00, 0x90				; 0x00 -> R#16: Palette selector #0
vdp_control_regs_end:

vdp_msx1_palette_regs:						; MSX1 like colors
			db		0x00, 0x00				; 0
			db		0x00, 0x00				; 1
			db		0x33, 0x05				; 2
			db		0x44, 0x06				; 3
			db		0x37, 0x02				; 4
			db		0x47, 0x03				; 5
			db		0x52, 0x03				; 6
			db		0x36, 0x05				; 7
			db		0x62, 0x03				; 8
			db		0x63, 0x04				; 9
			db		0x53, 0x06				; 10
			db		0x64, 0x06				; 11
			db		0x21, 0x04				; 12
			db		0x55, 0x03				; 13
			db		0x55, 0x05				; 14
			db		0x77, 0x07				; 15
vdp_msx1_palette_regs_end:

vdp_msx2_palette_regs::						; MSX2 colors
			db		0x11, 0x06				; 2
			db		0x33, 0x07				; 3
			db		0x17, 0x01				; 4
			db		0x27, 0x03				; 5
			db		0x51, 0x01				; 6
			db		0x27, 0x06				; 7
			db		0x71, 0x01				; 8
			db		0x73, 0x03				; 9
			db		0x61, 0x06				; 10
			db		0x64, 0x06				; 11
			db		0x11, 0x04				; 12
			db		0x65, 0x02				; 13
vdp_msx2_palette_regs_end::

icon_pattern:
			; SD card
			db		0x00, 0x00, 0x7F, 0x80, 0x8F, 0xD0, 0xCF, 0xC3
			db		0x00, 0x00, 0xFE, 0x01, 0xB9, 0x05, 0x05, 0x0D
			db		0xDF, 0xDE, 0xC0, 0x80, 0x83, 0x7C, 0x00, 0x00
			db		0x79, 0xF1, 0x01, 0x3E, 0x40, 0x80, 0x00, 0x00

			; EPCS1
			db		0x66, 0x66, 0x66, 0xFF, 0x80, 0x83, 0x83, 0x81
			db		0x66, 0x66, 0x66, 0xFF, 0x01, 0x81, 0x81, 0x81
			db		0x81, 0x81, 0x83, 0x80, 0xFF, 0x66, 0x66, 0x66
			db		0x81, 0x81, 0xC1, 0x01, 0xFF, 0x66, 0x66, 0x66

			; EPCS2
			db		0x66, 0x66, 0x66, 0xFF, 0x80, 0x87, 0x80, 0x81
			db		0x66, 0x66, 0x66, 0xFF, 0x01, 0xC1, 0x61, 0xC1
			db		0x83, 0x86, 0x87, 0x80, 0xFF, 0x66, 0x66, 0x66
			db		0x81, 0x01, 0xE1, 0x01, 0xFF, 0x66, 0x66, 0x66

			; Err.
			db		0xFF, 0xFF, 0x00, 0x78, 0x40, 0x40, 0x40, 0x7A
			db		0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0xD6
			db		0x43, 0x42, 0x42, 0x42, 0x7A, 0x00, 0xFF, 0xFF
			db		0x18, 0x10, 0x10, 0x10, 0x12, 0x00, 0xFF, 0xFF
icon_pattern_end:
			endscope

; --------------------------------------------------------------------
;	set_msx2_palette
;	input:
;		none
;	output:
;		none
;	break:
;		B,C,D,E
;	comment:
;
; --------------------------------------------------------------------
			scope	set_msx2_palette
set_msx2_palette::
			push	af
			ld		a, 2
			out		[ vdp_port1 ], a
			ld		a, 0x90
			out		[ vdp_port1 ], a
			ld		bc, ((vdp_msx2_palette_regs_end - vdp_msx2_palette_regs) << 8) | vdp_port2
			ld		hl, vdp_msx2_palette_regs
			otir
			pop		af
			ret
			endscope

; --------------------------------------------------------------------
;	Put icon
;	input:
;		A .... ICON Number 0: SD card, 1: EPCS1, 2: EPCS2, 3: Err.
;	output:
;		none
;	break:
;		A,B,C,H,L
;	comment:
;
; --------------------------------------------------------------------
			scope	vdp_put_icon
vdp_put_icon::
			add		a, a
			add		a, a
			inc		a
			ld		b, a
			ld		hl, 0x0800
			call	sub_code
			ld		l, 32
sub_code:
			call	vdp_set_vram_address
			dec		c
			out		[c], b
			inc		b
			out		[c], b
			inc		b
			ret
			endscope

; --------------------------------------------------------------------
;	set VRAM address for write
;	input)
;		hl .... target VRAM address
;	output)
;		none
;	break)
;		af, c
; --------------------------------------------------------------------
			scope	vdp_set_vram_address
vdp_set_vram_address::
			ld		c, vdp_port1
			out		[c], l
			ld		a, h
			or		a, 0x40
			out		[c], a
			ret
			endscope

; --------------------------------------------------------------------
;	fill VRAM
;	input)
;		de .... target area size (bytes)
;		a ..... fill data
;	output)
;		none
;	break)
;		af, bc, de, hl
; --------------------------------------------------------------------
			scope	vdp_fill_vram
vdp_fill_vram::
			ld		b, e
			inc		d
loop:
			out		[vdp_port0], a
			djnz	loop
			dec		d
			jr		nz, loop
			ret
			endscope

; --------------------------------------------------------------------
;	puts
;	input)
;		de .... target string
;	output)
;		none
;	break)
;		af, de
; --------------------------------------------------------------------
;;		scope	puts
;;puts::
;;		ld		a, [de]
;;		or		a, a
;;		ret		z
;;		out		[vdp_port0], a
;;		inc		de
;;		jr		puts
;;		endscope

; --------------------------------------------------------------------
;	dump_byte
;	input)
;		a .... target value
;	output)
;		none
;	break)
;		af, de
; --------------------------------------------------------------------
;;		scope	dump_byte
;;dump_byte::
;;		push	bc
;;		ld		b, a
;;		rrca
;;		rrca
;;		rrca
;;		rrca
;;		and		a, 0x0F
;;		add		a, '0'
;;		cp		a, '9' + 1
;;		jr		c, skip1
;;		add		a, 'A' - '0' - 10
;;skip1:
;;		out		[vdp_port0], a
;;
;;		ld		a, b
;;		and		a, 0x0F
;;		add		a, '0'
;;		cp		a, '9' + 1
;;		jr		c, skip2
;;		add		a, 'A' - '0' - 10
;;skip2:
;;		out		[vdp_port0], a
;;		ld		a, ' '
;;		out		[vdp_port0], a
;;		pop		bc
;;		ret
;;		endscope
;;
;;; include Caro's design font
;;include "../subroutine/ocm_iplrom_zg6x8_font.asm"
