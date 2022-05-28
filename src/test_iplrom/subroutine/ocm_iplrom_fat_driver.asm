; ==============================================================================
;	IPL-ROM for OCM-PLD v3.9 or later
;	SD-Card Driver
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
;   2021/Aug/20th  t.hara  Overall revision.
; ==============================================================================

; ------------------------------------------------------------------------------
;	FAT directory entry
; ------------------------------------------------------------------------------
dir_name						:= 0		; 11bytes
dir_attribute					:= 11		; 1byte
	attr_read_only				:= 0x01
	attr_hidden					:= 0x02
	attr_system					:= 0x04
	attr_volume_id				:= 0x08
	attr_directory				:= 0x10
	attr_archive				:= 0x20
	attr_long_file_name			:= 0x0F
dir_nt_res						:= 12		; 1byte
dir_crt_time_tenth				:= 13		; 1byte
dir_crt_time					:= 14		; 2bytes
dir_crt_date					:= 16		; 2bytes
dir_lst_acc_date				:= 18		; 2bytes
dir_fst_clus_hi					:= 20		; 2bytes (always 0)
dir_wrt_time					:= 22		; 2bytes
dir_wrt_date					:= 24		; 2bytes
dir_fst_clus_lo					:= 26		; 2bytes
dir_file_size					:= 28		; 4bytes
dir_next_entry					:= 32
dir_entry_size					:= dir_next_entry

			scope		load_from_sdcard
load_from_sdcard::
			ld			a, 0x40
			ld			[eseram8k_bank0], a				; BANK 40h
			call		sd_first_process
			ret			c
			endscope

			scope		search_bios_name
search_bios_name::
			; get the FAT entry size
			ld			hl, [buffer + pbr_sectors_per_fat]
			ld			[ remain_fat_sectors ], hl

			; save data area sector address
			push		bc
			push		de
			; -- change root entries to sectors : HL = (pbr_root_entries + 15) / 16
			ld			hl, [buffer + pbr_root_entries]
			ld			a, l
			ld			b, 4
entries_to_sectors:
			srl			h
			rr			l
			djnz		entries_to_sectors
			and			a, 0x0F
			jr			z, skip_inc
			inc			hl
skip_inc:
			ld			a, c
			add			hl, de
			adc			a, 0

			ld			[data_area + 0], hl			; AHL = sector number of data area top
			ld			[data_area + 2], a
			pop			de
			pop			bc

get_next_sector:
			; get root entries
			ld			b, 1
			ld			hl, fat_buffer
			call		sd_read_sector				; read FAT entry

			; save next root_entries sector address
			ld			a, c
			ld			[root_entries + 0], de		; CDE = pbr_reserved_sectors
			ld			[root_entries + 2], a

			ld			b, 512 / dir_entry_size
			ld			hl, fat_buffer
search_loop:
			push		hl
			push		bc

			ld			b, 11
			ld			de, bios_name
strcmp:
			ld			a, [de]
			cp			a, [hl]
			jr			nz, no_match
			inc			de					; no flag change
			inc			hl					; no flag change
			djnz		strcmp				; no flag change
no_match:
			pop			bc					; no flag change
			pop			hl					; no flag change
			jr			z, found_bios_name

			ld			de, dir_entry_size
			add			hl, de
			djnz		search_loop

			ld			de, [ remain_fat_sectors ]
			dec			de
			ld			[ remain_fat_sectors ], de
			ld			a, d
			or			a, e
			scf
			ret			z

			ld			a, [root_entries + 2]
			ld			de, [root_entries + 0]
			ld			c, a
			jr			get_next_sector

bios_name:
			ds			"OCM-BIOSDAT"
remain_fat_sectors:
			dw			0
root_entries::
			space		3
data_area::
			space		3
			endscope

			scope		found_bios_name
found_bios_name::
			push		bc
			push		hl
			xor			a, a
			call		vdp_put_icon
			pop			hl
			pop			bc

			ld			de, dir_attribute
			add			hl, de

			; check attribute
			;     Exit with an error if it is a volume label, directory, or long file name entry
			ld			a, [hl]
			and			a, attr_volume_id | attr_directory
			scf
			ret			nz						; error

			; get sector address of the entry
			ld			de, -dir_attribute + dir_fst_clus_lo
			add			hl, de
			ld			e, [hl]
			inc			hl
			ld			d, [hl]					; DE = dir_fst_clus_lo [cluster]
			dec			de
			dec			de

			; convert to sector number
			ld			a, [buffer + pbr_sectors_per_cluster]
			ld			b, a

			xor			a, a
			ld			h, a
			ld			l, a
loop:
			add			hl, de
			adc			a, 0
			djnz		loop

			ld			de, [data_area + 0]
			add			hl, de
			ld			c, a
			ld			a, [data_area + 2]
			adc			a, c

			ld			c, a
			ex			de, hl					; CDE = sector number
			endscope

			scope		test_sdbios
test_sdbios::
			push		de
			push		bc
			ld			b, 1
			ld			hl, buffer
			call		sd_read_sector
			pop			bc
			pop			de
			ret			c						; error

			ld			hl, buffer
			ld			a, [hl]
			cp			a, 'A'
			jr			nz, no_match_exit
			inc			hl
			ld			a, [hl]
			cp			a, 'B'
			jr			z, match
no_match_exit:
			scf
			ret
match:
			endscope

			scope		load_sdbios
load_sdbios::
			ld			hl, sd_read_sector
			ld			[read_sector_cbr], hl

			ld			hl, sdbios_image_table
			jp			load_bios
			endscope
