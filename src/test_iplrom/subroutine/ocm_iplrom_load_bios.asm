; ==============================================================================
;	IPL-ROM for OCM-PLD v3.9 or later
;	load BIOS image
; ------------------------------------------------------------------------------
; Copyright (c) 2021 Takayuki Hara
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
;   2021/Aug/15th  t.hara  First version.
; ==============================================================================

; --------------------------------------------------------------------
;	MegaSD Bank ID
; --------------------------------------------------------------------
DOS_ROM1_BANK					:= 0x80
DOS_ROM2_BANK					:= 0x82
DOS_ROM3_BANK					:= 0x84
DOS_ROM4_BANK					:= 0x86
DOS_ROM5_BANK					:= 0x88
DOS_ROM6_BANK					:= 0x8A
DOS_ROM7_BANK					:= 0x8C
DOS_ROM8_BANK					:= 0x8E
MAIN_ROM1_BANK					:= 0x90
MAIN_ROM2_BANK					:= 0x92
XBASIC2_BANK					:= 0x94
MSX_MUSIC_BANK					:= 0x96
SUB_ROM_BANK					:= 0x98
MSX_KANJI1_BANK					:= 0x9A
MSX_KANJI2_BANK					:= 0x9C
OPT_ROM_BANK					:= 0x9E
JIS1_KANJI1_BANK				:= 0xA0
JIS1_KANJI2_BANK				:= 0xA2
JIS1_KANJI3_BANK				:= 0xA4
JIS1_KANJI4_BANK				:= 0xA6
JIS1_KANJI5_BANK				:= 0xA8
JIS1_KANJI6_BANK				:= 0xAA
JIS1_KANJI7_BANK				:= 0xAC
JIS1_KANJI8_BANK				:= 0xAE
JIS2_KANJI1_BANK				:= 0xB0
JIS2_KANJI2_BANK				:= 0xB2
JIS2_KANJI3_BANK				:= 0xB4
JIS2_KANJI4_BANK				:= 0xB6
JIS2_KANJI5_BANK				:= 0xB8
JIS2_KANJI6_BANK				:= 0xBA
JIS2_KANJI7_BANK				:= 0xBC
JIS2_KANJI8_BANK				:= 0xBE

; ------------------------------------------------------------------------------
;	load_bios
;	input:
;		cde ... target sector number
;		hl .... bios image link table
;	output:
;		none
;	break:
;		all
;	comment:
;		Load the BIOS image, and if it loads successfully, boot the image.
; ------------------------------------------------------------------------------
			scope	load_bios
load_bios::
			; Load the BIOS image
			call		load_blocks
			ret			c								; error

			; set_f4_device
set_f4_device::
			ld			a, MAIN_ROM1_BANK
			ld			[eseram8k_bank2], a				; init ESE-RAM Bank#2
			ld			a, [ 0x8000 + 0x002D ]			; MainROM : 0=MSX1, 1=MSX2, 2=MSX2+, 3=MSXturboR
			or			a, a
			call		nz, set_msx2_palette
			sub			a, 3
			out			[ 0x4F ], a						; 0x0? = normal, 0xF? = inverted
			out			[ 0xF4 ], a						; force MSX logo = ON

			; KanjiROM JIS 2nd enabler
			ld			a, (1 - JIS2_ENABLE) << 7
			out			[0x4E], a

			; initialize ESE-RAM bank registers
			xor			a, a
			ld			[eseram8k_bank0], a				; init ESE-RAM Bank#0
			inc			a
			ld			[eseram8k_bank1], a				; init ESE-RAM Bank#1
			ld			[eseram8k_bank2], a				; init ESE-RAM Bank#2
			ld			[eseram8k_bank3], a				; init ESE-RAM Bank#3
			ld			a, 0xC0
			out			[primary_slot_register], a		; ff_ldbios_n <= '1' [sm_emsx_top.vhd]
			rst			00								; reset MSX BASIC
			endscope

; ------------------------------------------------------------------------------
;	load_blocks
;	input:
;		cde ... Target address of SD card or EPCS
;		hl .... bios image link table
;	output:
;		cde ... Next target address
;	break:
;		all
;	comment:
;		The sector size is 512 bytes only.
; ------------------------------------------------------------------------------
			scope		load_blocks
load_blocks::
			ld			a, DOS_ROM1_BANK			; target bank ID on ESE-RAM
			ld			[bank_id], a
load_block_loop::
			; get bios image link table
			ld			a, [hl]
			inc			hl
			cp			a, 0x40						; 0...63 : load bios image
			jr			c, load_bios_images
			jr			z, fill_ff_or_c9
			inc			a
			ret			z							; Return with Zf=0 and Cy=0, when finish code 0xFF.
			dec			a
			endscope

; ------------------------------------------------------------------------------
;	fill_zero
;	input:
;		a .... number of blocks
;	output:
;		none
;	break:
;		a, b, f
;	comment:
;
; ------------------------------------------------------------------------------
			scope		fill_zero
fill_zero::
			push		hl
			and			a, 0x3F
			ld			b, a
			xor			a, a
fill_zero_loop:
			call		set_bank
			call		fill_bank
			djnz		fill_zero_loop
			pop			hl
			jp			load_block_loop
			endscope

; ------------------------------------------------------------------------------
;	load_bios_images
;	input:
;		cde .. target sector address
;		a .... number of blocks
;	output:
;		cde .. next sector address
;	break:
;		a, b, f
;	comment:
;
; ------------------------------------------------------------------------------
			scope		load_bios_images
load_bios_images::
loop:
			; read sectors
			ld			[count], a
			call		set_bank
			push		hl
			ld			b, 16384 / 512					; Number of sectors equal to 16KB
			ld			hl, 0x8000
			read_sector_cbr := $ + 1
			call		0
			pop			hl
			ret			c								; error
			ld			a, [count]
			dec			a
			jr			nz, loop
			jr			load_block_loop
count:
			db			0
			endscope

; ------------------------------------------------------------------------------
;	fill_ff_or_c9
;	input:
;		none
;	output:
;		none
;	break:
;		af
;	comment:
;		If it is a turboR BIOS, it will fill the current bank with C9h. 
;		Otherwise, it will fill with FFh.
; ------------------------------------------------------------------------------
			scope		fill_ff_or_c9
fill_ff_or_c9::
			ld			a, MAIN_ROM1_BANK
			ld			[eseram8k_bank2], a

			ld			a, [0x8000 + 0x002D]
			cp			a, 3						; Is this turboR BIOS?
			ld			a, 0xFF						; -- No, fill 0xFF
			jr			c, fill_ff
			ld			a, 0xC9						; -- Yes, fill 0xC9
fill_ff:
			call		set_bank
			call		fill_bank
			jr			load_block_loop
			endscope

; ------------------------------------------------------------------------------
;	fill_bank
;	input:
;		a .... Fill data
;	output:
;		none
;	break:
;		none
;	comment:
;		Fill data by A into 0x8000-0xAFFF
; ------------------------------------------------------------------------------
			scope		fill_bank
fill_bank::
			push		de
			push		hl
			push		bc
			ld			hl, 0x8000
			ld			de, 0x8001
			ld			bc, 0x4000 - 1
			ld			[hl], a
			ldir
			pop			bc
			pop			hl
			pop			de
			ret
			endscope

; ------------------------------------------------------------------------------
;	set_bank
;	input:
;		bank_id ... Target bank ID
;	output:
;		none
;	break:
;		none
;	comment:
;		-
; ------------------------------------------------------------------------------
			scope		set_bank
set_bank::
			; set ESE-RAM bank ID for Bank2 and Bank3
			push		af
			ld			a, [bank_id]
			ld			[eseram8k_bank2], a
			inc			a
			ld			[eseram8k_bank3], a
			inc			a
			ld			[bank_id], a
			pop			af
			ret
bank_id::
			db			0
			endscope
