; ==============================================================================
;	IPL-ROM for OCM-PLD v3.9 or later
;	EPCS Serial ROM Driver
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
;   2021/Aug/09th  t.hara  Overall revision.
; ==============================================================================

; --------------------------------------------------------------------
;	EPCS Operation Codes
; --------------------------------------------------------------------
EPCS_WRITE_ENABLE		:= 0b0000_0110
EPCS_WRITE_DISABLE		:= 0b0000_0100
EPCS_READ_STATUS		:= 0b0000_0101
EPCS_READ_BYTES			:= 0b0000_0011
EPCS_READ_SILICON_ID	:= 0b1010_1011			; require EPCS1/4/16/64
EPCS_FAST_READ			:= 0b0000_1011
EPCS_WRITE_STATUS		:= 0b0000_0001
EPCS_WRITE_BYTES		:= 0b0000_0010
EPCS_ERASE_BULK			:= 0b1100_0111
EPCS_ERASE_SECTOR		:= 0b1101_1000
EPCS_READ_DEVICE_ID		:= 0b1001_1111			; require EPCS128 or later

; ------------------------------------------------------------------------------
			scope		load_from_epcs
load_from_epcs::
			ld			hl, read_sector_from_epcs
			ld			[ read_sector_cbr ], hl

			; load BIOS image from EPCS serial ROM
			ld			a, 0x60
			ld			[ eseram8k_bank0 ], a

			; set EPBIOS1 address
			ld			de, epcs_bios1_start_address

			if epcs_bios1_start_address != epcs_bios2_start_address
				; Check DIP-SW7 and select DualBIOS
				in			a, [ 0x42 ]
				and			a, 0b01000000
				ld			a, 1							; no flag change
				jr			z, load_epbios_start

				inc			a
				ld			d, epcs_bios2_start_address >> 8
			endif
load_epbios_start::
			call		vdp_put_icon
			ld			hl, epbios_image_table
			jr			load_bios
			endscope

			if (epcs_bios1_start_address & 0x0FF) != (epcs_bios2_start_address & 0x0FF)
				error "Please set the same value for LSB 8bit of epcs_bios1_start_address and LSB 8bit of epcs_bios2_start_address."
			endif

; ------------------------------------------------------------------------------
;	read_sector_from_epcs
;	input:
;		DE .... target sector number
;		HL .... destination address
;		B ..... number of sectors (1-127)
;	output:
;		Cy .... 0: success, 1: error
;		DE .... next sector number
;	comment:
;		-
; ------------------------------------------------------------------------------
			scope		read_sector_from_epcs
read_sector_from_epcs::
			push		de
			sla			e
			rl			d								; de * 2
			xor			a, a							; dea = byte address, Cy = 0
			ld			c, b
			sla			c								; c = {number of sectors} * 2  : number of half sectors
			ld			b, a							; b = 256

			push		bc								; save number of half sectors
			push		hl
			ld			hl, megasd_sd_register|(0<<12)	; /CS=0 (address bit12)
			ld			[hl], EPCS_READ_BYTES			; command byte
			ld			[hl], d							; byte address b23-b16
			ld			[hl], e							; byte address b15-b8
			ld			[hl], a							; byte address b7-b0
			ld			a, [hl]
			pop			de								; de = adress of buffer

read_all:
read_half_sector:
			ld			a, [hl]							; read 1byte
			ld			[de], a							; write 1byte to buffer
			inc			de
			djnz		read_half_sector
			dec			c
			jr			nz, read_all

			ld			a, [megasd_sd_register|(1<<12)]	; /CS=1 (address bit12)

			pop			hl								; H = number of half sectors
			pop			de								; adress of sector
			srl			l
			ld			h, 0
			add			hl, de
			ex			de, hl							; next sector (512 byte)
			xor			a, a							; Cy = 0
			ret
			endscope

