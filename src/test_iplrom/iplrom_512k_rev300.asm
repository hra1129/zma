; ==============================================================================
;	IPL-ROM v3.00 for OCM-PLD v3.9 or later
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
; IPL-ROM Revision 2.00 for 512 kB unpacked with Dual-EPBIOS support
; EPCS16 [or higher] start adr 100000h - Optimized by KdL 2020.01.09
;
; Coded in TWZ'CA3 w/ TASM80 v3.2ud for OCM-PLD Pack v3.4 or later
;
; SDHC support by Yuukun-OKEI, thanks to MAX
; ------------------------------------------------------------------------------
; History:
;   2021/Aug/11st	v3.00	t.hara	Overall revision.
; ==============================================================================

JIS2_ENABLE						:= 1					; 0: disable, 1: enable

; --------------------------------------------------------------------
;	EPBIOS address
; --------------------------------------------------------------------
epcs_bios1_start_address		:= 0x100000 >> 9
epcs_bios2_start_address		:= 0x180000 >> 9

; --------------------------------------------------------------------
;	MegaSD Information
; --------------------------------------------------------------------
megasd_sd_register				:= 0x4000				; MegaSD MemoryMappedRegisterAddress
eseram8k_bank0					:= 0x6000				; 4000h~5FFFh bank selector
eseram8k_bank1					:= 0x6800				; 6000h~7FFFh bank selector
eseram8k_bank2					:= 0x7000				; 8000h~9FFFh bank selector
eseram8k_bank3					:= 0x7800				; A000h~BFFFh bank selector

; --------------------------------------------------------------------
;	I/O
; --------------------------------------------------------------------
primary_slot_register			:= 0xA8

; --------------------------------------------------------------------
;	Expanded I/O
; --------------------------------------------------------------------
exp_io_vendor_id_port			:= 0x40					; Vendor ID register for Expanded I/O
exp_io_1chipmsx_id				:= 212					; KdL's switch device ID

; --------------------------------------------------------------------
;	Work area
; --------------------------------------------------------------------
buffer							:= 0xC000				; read buffer (!! Expect the lower 8 bits to be 0 !!)
fat_buffer						:= 0xC200				; read buffer for FAT entry
dram_code_address				:= 0xF800				; program code address on DRAM (!! Expect the lower 8 bits to be 0 !!)

; --------------------------------------------------------------------
			org			dram_code_address
begin_of_code:											; !!!! Address 0x0000 and ROM !!!!

self_copy::
			di
			ld			bc, end_of_code - begin_of_code
			ld			de, begin_of_code
			ld			h, e
			ld			l, e
			ldir
			jp			init_stack						; jump to PAGE3

; --------------------------------------------------------------------
init_stack::
			ld			sp, 0xFFFF
			call		init_vdp

init_switch_io::
			ld			a, exp_io_1chipmsx_id
			out			[exp_io_vendor_id_port], a

;;check_force_bios_load::
;;			ld			a, 0xF7							; Key scan code = Y7
;;			out			[0xAA], a
;;			in			a, [0xA9]
;;			and			a, 4							; check [ESC] key
;;			jr			z, force_bios_load

check_already_loaded::
			ld			a, 0x80
			ld			[eseram8k_bank2], a				; BANK# 80h
			ld			hl, [0x8000]
			ld			de, ('B' << 8) + 'A'
			sbc			hl, de
			jr			z, set_f4_device

force_bios_load::
			call		load_from_sdcard				; load BIOS from SD card
			call		load_from_epcs					; load BIOS from EPCS serial ROM

			ld			a, 3
			call		vdp_put_icon
			halt										; error

; --------------------------------------------------------------------
;	[C][C][B][B][B][B][B][B]
epbios_image_table::
sdbios_image_table::
			db			32								; ALL
			db			0xFF

; --------------------------------------------------------------------
			include		"../subroutine/ocm_iplrom_serial_rom.asm"
			include		"../subroutine/ocm_iplrom_load_bios.asm"
			include		"../subroutine/ocm_iplrom_fat_driver.asm"
			include 	"../subroutine/ocm_iplrom_sd_driver.asm"
			include		"../subroutine/ocm_iplrom_vdp_standard_icon.asm"
end_of_code:

			if (end_of_code - begin_of_code) > 2048
				error "The size is too BIG. (" + (end_of_code - begin_of_code) + "byte)"
			else
				message "Size is not a problem. (" + (end_of_code - begin_of_code) + "byte)"
			endif
