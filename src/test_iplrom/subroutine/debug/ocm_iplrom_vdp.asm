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
;			ld			hl, vdp_control_regs
;			ld			bc, (0x02 << 8) | vdp_port1
;			otir
;			ld			bc, (0x20 << 8) | vdp_port2
;			otir
;			ret
;
;			; VDP port 99h [set register]
;vdp_control_regs:
;			db		0x00, 0x90				; 0x00 -> R#16: Palette selector #0
;
;vdp_palette_regs:
;			db		0x00, 0x00				; 0
;			db		0x00, 0x00				; 1
;			db		0x33, 0x05				; 2
;			db		0x44, 0x06				; 3
;			db		0x37, 0x02				; 4
;			db		0x47, 0x03				; 5
;			db		0x52, 0x03				; 6
;			db		0x36, 0x05				; 7
;			db		0x62, 0x03				; 8
;			db		0x63, 0x04				; 9
;			db		0x53, 0x06				; 10
;			db		0x64, 0x06				; 11
;			db		0x21, 0x04				; 12
;			db		0x55, 0x03				; 13
;			db		0x55, 0x05				; 14
;			db		0x77, 0x07				; 15

; ====================================================================
;  for DEBUG
		;	Set VDP mode and color palette
		ld		hl, vdp_control_regs
		ld		bc, ((vdp_control_regs_end - vdp_control_regs) << 8) | vdp_port1
		otir
		ld		bc, ((vdp_palette_regs_end - vdp_palette_regs) << 8) | vdp_port2
		otir

		;	Initialize the first 16KB of VRAM.
		ld		hl, 0x0000
		call	vdp_set_vram_address

		ld		bc, 0x4000
		xor		a, a
		call	vdp_fill_vram

		ld		hl, 0x0800 + 32*8
		call	vdp_set_vram_address
		ld		hl, font_data
		ld		bc, (0x00 << 8) | vdp_port0
		otir
		otir
		otir
		ld		hl, 0x0000
		call	vdp_set_vram_address
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
		ld		c, vdp_port0
		ld		b, e
		dec		b
		inc		b
		jr		z, skip1
loop1:
		out		[c], a
		djnz	loop1
skip1:
		inc		d
loop2:
		dec		d
		ret		z
loop3:
		out		[c], a
		djnz	loop3
		jr		loop2
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
		scope	puts
puts::
		ld		a, [de]
		or		a, a
		ret		z
		out		[vdp_port0], a
		inc		de
		jr		puts
		endscope

; --------------------------------------------------------------------
;	dump_byte
;	input)
;		a .... target value
;	output)
;		none
;	break)
;		af, de
; --------------------------------------------------------------------
		scope	dump_byte
dump_byte::
		push	bc
		ld		b, a
		rrca
		rrca
		rrca
		rrca
		and		a, 0x0F
		add		a, '0'
		cp		a, '9' + 1
		jr		c, skip1
		add		a, 'A' - '0' - 10
skip1:
		out		[vdp_port0], a

		ld		a, b
		and		a, 0x0F
		add		a, '0'
		cp		a, '9' + 1
		jr		c, skip2
		add		a, 'A' - '0' - 10
skip2:
		out		[vdp_port0], a
		ld		a, ' '
		out		[vdp_port0], a
		pop		bc
		ret
		endscope

; --------------------------------------------------------------------
;	VDP datas
; --------------------------------------------------------------------
vdp_control_regs:
		db		0x00, 0x80				; 0x00 -> R#0 : SCREEN0 (40X24, TEXT Mode)
		db		0x50, 0x81				; 0x50 -> R#1 : SCREEN0 (40X24, TEXT Mode)
		db		0x00, 0x82				; 0x00 -> R#2 : Pattern Name Table is 0x0000
		db		0x01, 0x84				; 0x01 -> R#4 : Pattern Generator Table is 0x0800
		db		0xF4, 0x87				; 0xF4 -> R#7 : Set Color (White on Blue)
		db		0x00, 0x90				; 0x00 -> R#16: Palette selector #0
vdp_control_regs_end:

vdp_palette_regs:
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
vdp_palette_regs_end:

; include Caro's design font
include "../subroutine/ocm_iplrom_zg6x8_font.asm"
; ====================================================================
