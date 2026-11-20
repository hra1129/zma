; =============================================================================
;	ZMA for MSX-DOS2  --  Z80 macro assembler, MSX-DOS2 native version
;	Phase 1 core increment: skeleton / expressions / symbols / encoder core
;	Build: cross ZMA  (zma zma.asm ZMA.COM)
; =============================================================================

		org		0x0100

; BDOS entry and DOS2 function numbers
bdos		:= 0x0005
_conout		:= 0x02			; BDOS console output (DOS1 compatible)
_open		:= 0x43			; DOS2 handle API
_create		:= 0x44
_close		:= 0x45
_read		:= 0x48
_write		:= 0x49
_seek		:= 0x4A
_term		:= 0x62			; DOS2 terminate with code (B = code)
_getdver	:= 0x6F			; DOS2 get DOS version (kernel) -> HL

extbio		:= 0xFFCA		; EXTBIO hook

; -----------------------------------------------------------------------------
;	Entry point
; -----------------------------------------------------------------------------
start:
		; DOS version check (need DOS2 kernel >= 2.00)
		; _DOSVER returns BC = kernel version (BCD), DE = MSXDOS2.SYS ver
		ld		c, _getdver
		call	bdos
		ld		a, b
		cp		a, 2
		jr		nc, dos_ok
		ld		hl, s_need_dos2
		call	puts
		ld		b, 1
		jp		term_raw
dos_ok:
		ld		hl, s_banner
		call	puts
		call	mapper_init		; get jump table, remember orig page2 seg
		call	arena_init		; P3: reserve arena segments (pool top)
		call	parse_cmdline		; fills in_name / out_name / options
		jr		c, usage_exit
		call	asm_main		; returns A = error count != 0 -> failure
		; ---- cleanup: close files, free segments ----
		push	af
		call	close_all_files
		call	mapper_free_all
		pop		af
		ld		b, a			; exit code 0/1 in B (nonzero -> 1)
		ld		a, b
		or		a, a
		jr		z, term_raw
		ld		b, 1
term_raw:
		ld		c, _term
		jp		bdos
usage_exit:
		ld		hl, s_usage
		call	puts
		ld		b, 1
		jr		term_raw

s_banner:
		db		"ZMA for MSX-DOS2 v1.0.22", 13, 10, 0
s_need_dos2:
		db		"Needs MSX-DOS2.", 13, 10, 0
s_usage:
		db		"Usage: ZMA [-options] <input.asm> <output.bin>", 13, 10
		db		"  -DEFS  -I<path>  -D<name>=<value>  -HEX", 13, 10, 0

; -----------------------------------------------------------------------------
;	Console output: puts (HL = NUL-terminated string), putc (A = char)
; -----------------------------------------------------------------------------
puts:
		ld		a, [hl]
		or		a, a
		ret		z
		call	putc
		inc		hl
		jr		puts
putc:
		push	hl
		push	de
		push	bc
		ld		e, a
		ld		c, _conout
		call	bdos
		pop		bc
		pop		de
		pop		hl
		ret

;	print decimal number in HL (unsigned 16-bit), no padding
print_dec16:
		ld		de, pd_powers
		ld		b, 0			; B = "any digit printed" flag
pd_next_pow:
		ld		a, [de]
		inc		de
		ld		c, a
		ld		a, [de]
		inc		de
		push	de
		ld		d, a
		ld		e, c			; DE = power
		ld		c, 0			; digit count
pd_sub:
		ld		a, l
		sub		a, e
		ld		a, h
		sbc		a, d
		jr		c, pd_digit_done
		ld		h, a
		ld		a, l
		sub		a, e
		ld		l, a
		inc		c
		jr		pd_sub
pd_digit_done:
		pop		de
		ld		a, c
		or		a, b
		jr		z, pd_skip
		ld		a, c
		add		a, '0'
		call	putc
		ld		b, 1
pd_skip:
		ld		a, [de]
		or		a, a
		jr		nz, pd_next_pow
		ld		a, b
		or		a, a
		ret		nz
		ld		a, '0'
		call	putc
		ret

pd_powers:
		dw		10000, 1000, 100, 10, 1, 0

; -----------------------------------------------------------------------------
;	Command line parsing
;	command tail at 0080h: [len][text...]
;	results: opt_defs (0/1), opt_hex (0/1), inc_paths, d_symbols,
;	         in_name / out_name (NUL-terminated, 8.3 checked by DOS on open)
;	returns CY=1 on usage error
; -----------------------------------------------------------------------------
parse_cmdline:
		ld		hl, 0x0081
		ld		a, [0x0080]
		ld		b, a
		ld		de, tail_buf
pc_copy:
		ld		a, b
		or		a, a
		jr		z, pc_copy_done
		ld		a, [hl]
		inc		hl
		ld		[de], a
		inc		de
		dec		b
		jr		pc_copy
pc_copy_done:
		xor		a, a
		ld		[de], a
		; token scan
		ld		hl, tail_buf
		ld		[cmd_ptr], hl
		ld		hl, in_name
		ld		[fn_slot], hl		; first plain token -> input, second -> output
pc_next:
		call	cmd_skip_sp
		ld		a, [hl]
		or		a, a
		jp		z, pc_eol
		cp		a, '-'
		jr		z, pc_option
		; plain token = filename
		ld		de, [fn_slot]
		call	cmd_read_token_to	; HL advances past token, DE = dest (NUL term)
		ld		hl, in_name
		ld		de, [fn_slot]
		or		a, a
		sbc		hl, de
		jr		nz, pc_was_output
		ld		hl, out_name
		ld		[fn_slot], hl
		jr		pc_next2
pc_was_output:
		ld		hl, 0xFFFF
		ld		[fn_slot], hl
pc_next2:
		ld		hl, [cmd_ptr]
		jr		pc_next
pc_option:
		inc		hl			; skip '-'
		ld		[cmd_ptr], hl
		; compare option word (up to space or NUL)
		ld		hl, [cmd_ptr]
		ld		de, opt_defs_s
		call	opt_match		; CY=1 if matched (HL advanced)
		jr		c, pc_set_defs
		ld		hl, [cmd_ptr]
		ld		de, opt_hex_s
		call	opt_match
		jr		c, pc_set_hex
		ld		hl, [cmd_ptr]
		ld		a, [hl]
		cp		a, 'I'
		jr		z, pc_opt_i
		cp		a, 'i'
		jr		z, pc_opt_i
		cp		a, 'D'
		jr		z, pc_opt_d
		cp		a, 'd'
		jr		z, pc_opt_d
		cp		a, 'H'
		jr		z, pc_help
		cp		a, 'h'
		jr		z, pc_help
		scf
		ret
pc_set_defs:
		ld		a, 1
		ld		[opt_defs], a
		ld		[cmd_ptr], hl
		jr		pc_next
pc_set_hex:
		ld		a, 1
		ld		[opt_hex], a
		ld		[cmd_ptr], hl
		jr		pc_next
pc_help:
		scf
		ret
pc_opt_i:
		inc		hl			; skip 'I'; rest of token = path
		ld		de, inc_path_buf
		call	cmd_read_token_to
		ld		a, 1
		ld		[inc_path_valid], a
		jr		pc_next2
pc_opt_d:
		inc		hl			; skip 'D'; token = name=value (value may be 'str')
		ld		[dopt_start], hl
		; '=' must exist inside the token (cross: invalid option)
		push	hl
dopt_scan:
		ld		a, [hl]
		or		a, a
		jr		z, dopt_noeq
		cp		a, ' '
		jr		z, dopt_noeq
		cp		a, 9
		jr		z, dopt_noeq
		cp		a, '='
		jr		z, dopt_haseq
		inc		hl
		jr		dopt_scan
dopt_noeq:
		pop		hl
		jp		dopt_invalid_tok
dopt_haseq:
		pop		hl
		ld		de, d_name_buf
		call	cmd_read_until_eq	; name -> d_name_buf, HL at char after '='
		ld		de, d_val_buf
		call	cmd_read_token_to
		; validate: name and value non-empty; quoted value must be
		; closed by a quote as its last character
		ld		a, [d_name_buf]
		or		a, a
		jr		z, dopt_invalid
		ld		a, [d_val_buf]
		or		a, a
		jr		z, dopt_invalid
		cp		a, 0x27
		jr		nz, dopt_ok
		ld		hl, d_val_buf
		ld		b, 0			; length counter
dopt_vl:
		ld		a, [hl]
		or		a, a
		jr		z, dopt_vend
		inc		hl
		inc		b
		jr		dopt_vl
dopt_vend:
		ld		a, b
		cp		a, 2
		jr		c, dopt_invalid	; need at least '' (open+close)
		dec		hl				; last char
		ld		a, [hl]
		cp		a, 0x27
		jr		nz, dopt_invalid
dopt_ok:
		call	register_d_symbol
		jp		pc_next2
dopt_invalid:
		; "Invalid command line option [-D<name>=<value>]."
		ld		hl, s_dopt_inv1
		call	puts
		ld		hl, d_name_buf
		call	puts
		ld		a, '='
		call	putc
		ld		hl, d_val_buf
		call	puts
		ld		hl, s_dopt_inv2
		call	puts
		jp		pc_next2
dopt_invalid_tok:
		; no '=' in token; HL = token start
		ld		[cmd_ptr], hl
		ld		hl, s_dopt_inv1
		call	puts
		ld		hl, [cmd_ptr]
dopt_itl:
		ld		a, [hl]
		or		a, a
		jr		z, dopt_itdone
		cp		a, ' '
		jr		z, dopt_itdone
		cp		a, 9
		jr		z, dopt_itdone
		inc		hl
		push	hl
		call	putc
		pop		hl
		jr		dopt_itl
dopt_itdone:
		ld		[cmd_ptr], hl
		ld		hl, s_dopt_inv2
		call	puts
		jp		pc_next2
dopt_start:
		dw		0
s_dopt_inv1:
		db		"Invalid command line option [-D", 0
s_dopt_inv2:
		db		"].", 13, 10, 0
pc_eol:
		ld		a, [in_name]
		or		a, a
		scf
		ret		z
		ld		a, [out_name]
		or		a, a
		scf
		ret		z
		or		a, a			; CY=0 ok
		ret

;	skip spaces/tabs at [cmd_ptr] (HL updated)
cmd_skip_sp:
		ld		hl, [cmd_ptr]
css_l:
		ld		a, [hl]
		cp		a, ' '
		jr		z, css_n
		cp		a, 9
		jr		nz, css_done
css_n:
		inc		hl
		jr		css_l
css_done:
		ld		[cmd_ptr], hl
		ret

;	read token (to space/tab/NUL) from HL into DE, NUL-terminate.
;	on return HL = char after token, [cmd_ptr] updated.
cmd_read_token_to:
		ld		b, 60			; safety cap
crt_l:
		ld		a, [hl]
		or		a, a
		jr		z, crt_done
		cp		a, ' '
		jr		z, crt_done
		cp		a, 9
		jr		z, crt_done
		ld		[de], a
		inc		hl
		inc		de
		djnz		crt_l
crt_done:
		xor		a, a
		ld		[de], a
		ld		[cmd_ptr], hl
		ret

;	read until '=' (or token end) from HL into DE; HL ends after '='
cmd_read_until_eq:
		ld		b, 60
crue_l:
		ld		a, [hl]
		or		a, a
		jr		z, crue_done
		cp		a, '='
		jr		z, crue_eq
		cp		a, ' '
		jr		z, crue_done
		ld		[de], a
		inc		hl
		inc		de
		djnz		crue_l
		jr		crue_done
crue_eq:
		inc		hl
crue_done:
		xor		a, a
		ld		[de], a
		ld		[cmd_ptr], hl
		ret

;	match NUL-terminated option text at DE against token at HL (case-insens.)
;	if match and next char is space/tab/NUL: CY=1, HL advanced past text
opt_match:
		push	hl
		push	de
om_l:
		ld		a, [de]
		or		a, a
		jr		z, om_end
		ld		a, [hl]
		call	toupper_a
		ld		b, a
		ld		a, [de]
		cp		a, b
		jr		nz, om_no
		inc		hl
		inc		de
		jr		om_l
om_end:
		ld		a, [hl]
		or		a, a
		jr		z, om_yes
		cp		a, ' '
		jr		z, om_yes
		cp		a, 9
		jr		nz, om_no
om_yes:
		pop		de
		pop		bc			; discard saved HL, keep advanced HL
		scf
		ret
om_no:
		pop		de
		pop		hl
		or		a, a
		ret

opt_defs_s:
		db		"DEFS", 0
opt_hex_s:
		db		"HEX", 0

toupper_a:
		cp		a, 'a'
		ret		c
		cp		a, 'z' + 1
		ret		nc
		sub		a, 0x20
		ret

;	-D name=value : appended to d_list (name + raw value string);
;	the actual evaluation/definition happens in register_d_list
;	(asm_main, after hash_clear).  Entry: 32B name + 32B value string.
D_LIST_MAX	:= 16
d_list:
		space	D_LIST_MAX * 64
d_list_count:
		db		0
register_d_symbol:
		ld		a, [d_list_count]
		cp		a, D_LIST_MAX
		ret		nc
		; entry ptr = d_list + count*64
		ld		l, a
		ld		h, 0
		add		hl, hl
		add		hl, hl
		add		hl, hl
		add		hl, hl
		add		hl, hl
		add		hl, hl			; *64
		ld		de, d_list
		add		hl, de
		ex		de, hl			; DE = entry
		push	de
		ld		hl, d_name_buf
		ld		bc, 32
		ldir				; name (32 bytes, NUL-padded source)
		pop		de
		ld		hl, 32
		add		hl, de
		ex		de, hl			; DE = entry+32
		ld		hl, d_val_buf
		ld		bc, 32
		ldir				; value string
		ld		a, [d_list_count]
		inc		a
		ld		[d_list_count], a
		ret

register_d_list:
		ld		a, [d_list_count]
		or		a, a
		ret		z
		ld		b, a
		ld		hl, d_list
rdl_l:
		push	bc
		push	hl
		; copy name -> d_name_buf
		ld		de, d_name_buf
		ld		bc, 32
		ldir
		pop		hl
		push	hl
		ld		de, 32
		add		hl, de
		; copy value string -> d_val_buf
		ld		de, d_val_buf
		ld		bc, 32
		ldir
		; define with cross -D semantics
		ld		hl, d_val_buf
		ld		a, [hl]
		cp		a, 0x27			; '...' -> string value
		jr		z, rdl_string
		call	d_stoi			; DE:HL = stoi-prefix value
		ld		a, SYM_F_ASSIGN | SYM_F_GLOBAL
		ld		[d_flags], a
		jr		rdl_store
rdl_string:
		; content between the quotes, uppercased (cross uppercases
		; the whole option), interned as a string value
		inc		hl				; skip opening quote
		ld		de, sbuf_a
		ld		b, 0
rds_cp:
		ld		a, [hl]
		cp		a, 0x27
		jr		z, rds_done
		or		a, a
		jr		z, rds_done
		call	upcase
		ld		[de], a
		inc		hl
		inc		de
		inc		b
		jr		rds_cp
rds_done:
		ld		c, b
		ld		b, 0			; BC = content length
		ld		hl, sbuf_a
		call	str_intern		; DE:HL = pool offset
		ld		a, SYM_F_ASSIGN | SYM_F_GLOBAL | SYM_F_STRING
		ld		[d_flags], a
rdl_store:
		ld		[d_tmp_val], hl
		ld		[d_tmp_val + 2], de
		call	sym_define_d
		pop		hl
		ld		de, 64
		add		hl, de
		pop		bc
		djnz	rdl_l
		ret

;	d_stoi: HL = string -> DE:HL = value, std::stoi prefix semantics
;	(optional sign, decimal digits; no digits -> 0)
dsi_val:
		space	4
dsi_neg:
		db		0
d_stoi:
		xor		a, a
		ld		[dsi_val], a
		ld		[dsi_val + 1], a
		ld		[dsi_val + 2], a
		ld		[dsi_val + 3], a
		ld		[dsi_neg], a
		ld		a, [hl]
		cp		a, '-'
		jr		z, dsi_sign
		cp		a, '+'
		jr		nz, dsi_digits
		jr		dsi_sign2
dsi_sign:
		ld		a, 1
		ld		[dsi_neg], a
dsi_sign2:
		inc		hl
dsi_digits:
		ld		a, [hl]
		cp		a, '0'
		jr		c, dsi_done
		cp		a, '9' + 1
		jr		nc, dsi_done
		inc		hl
		sub		a, '0'
		ld		[dsi_dig], a
		push	hl
		; dsi_val = dsi_val * 10 + digit (via mul32)
		ld		hl, dsi_val
		ld		de, lv
		ld		bc, 4
		ldir
		ld		hl, rv
		xor		a, a
		ld		[hl], a
		inc		hl
		ld		[hl], a
		inc		hl
		ld		[hl], a
		inc		hl
		ld		[hl], a
		ld		a, 10
		ld		[rv], a
		call	mul32			; resv = dsi_val * 10
		ld		hl, resv
		ld		de, dsi_val
		ld		bc, 4
		ldir
		ld		a, [dsi_dig]
		ld		hl, dsi_val
		add		a, [hl]
		ld		[hl], a
		jr		nc, dsi_nc
		inc		hl
		inc		[hl]
		jr		nz, dsi_nc
		inc		hl
		inc		[hl]
		jr		nz, dsi_nc
		inc		hl
		inc		[hl]
dsi_nc:
		pop		hl
		jr		dsi_digits
dsi_done:
		ld		a, [dsi_neg]
		or		a, a
		jr		z, dsi_pos
		ld		hl, dsi_val
		call	neg_cell
dsi_pos:
		ld		hl, [dsi_val]
		ld		de, [dsi_val + 2]
		ret
dsi_dig:
		db		0

; -----------------------------------------------------------------------------
;	DOS2 handle API wrappers
; -----------------------------------------------------------------------------
;	DOS2 handle API conventions (MSX-Datapack Vol.3 ch.17):
;	  _OPEN/_CREATE: DE = filename (ASCIIZ), A = open mode
;	    (bit0: write-inhibit, bit1: read-inhibit, bit2: inherit)
;	    _CREATE also: B = attributes (bit7: create-new-only; 0 =
;	    create or truncate).  Returns A = error (0 = OK), B = handle.
;	  _READ/_WRITE: B = handle, HL = buffer, DE = length
;	    Returns A = error, HL = bytes actually transferred.
;	  _SEEK: B = handle, A = method (0 = from start), DE:HL = offset
;
;	dos_open_read: HL = filename -> A = handle, CY=1 on error
dos_open_read:
		ex		de, hl
		ld		a, 1			; read access (write inhibited)
		ld		c, _open
		call	bdos
		or		a, a
		jr		nz, dor_err
		ld		a, b			; handle returned in B
		or		a, a
		ret
dor_err:
		scf
		ret

;	dos_create: HL = filename -> A = handle, CY=1 on error
dos_create:
		ex		de, hl
		ld		a, 2			; write access (read inhibited)
		ld		b, 0			; attributes 0, create-or-truncate
		ld		c, _create
		call	bdos
		or		a, a
		jr		nz, dor_err
		ld		a, b
		or		a, a
		ret

;	dos_close: A = handle
dos_close:
		ld		b, a
		ld		c, _close
		call	bdos
		ret

;	dos_read: A=handle, HL=buf, DE=len -> HL = bytes read, CY=1 error
;	NOTE: MSX-DOS2 _READ/_WRITE take DE=buffer, HL=count (proven on
;	openMSX 2026-11-11; the Datapack OCR summary had them swapped).
dos_read:
		ld		b, a
		ex		de, hl			; DE = buffer, HL = count
		ld		c, _read
		call	bdos
		or		a, a
		jr		nz, dor_err
		; HL = actual bytes read
		or		a, a
		ret

;	dos_write: A=handle, HL=buf, DE=len -> CY=1 error
dos_write:
		ld		b, a
		ex		de, hl			; DE = buffer, HL = count
		ld		c, _write
		call	bdos
		or		a, a
		jr		nz, dor_err
		ret

;	dos_seek0: A=handle -> rewind to 0
dos_seek0:
		ld		b, a
		ld		c, _seek
		ld		de, 0
		ld		l, 0			; seek mode 0 = absolute (HL:DE? DOS2: DE:HL offset)
		ld		h, 0
		ld		a, 0			; A = method 0 (from start); offset in DE:HL
		call	bdos
		ret

; =============================================================================
;	Mapper support + segment pool
;	Pool = linear byte space across up to POOL_MAXSEG mapper segments.
;	All pool access goes through the memory-held pointer "pio" (4 bytes,
;	little-endian offset) using RD_SEG / WR_SEG byte access.
; =============================================================================
POOL_MAXSEG	:= 8				; 8 x 16KB = 128KB pool

mapper_init:
		ld		a, 0
		ld		d, 4			; EXTBIO device 4 = mapper support
		ld		e, 2			; function 2 = get jump table
		call	extbio
		or		a, a
		jr		z, mi_nomap		; A=0 -> no mapper support
		ld		[map_jtab], hl
		ld		b, POOL_MAXSEG
		ld		hl, pool_segs
mi_alloc:
		push	bc
		push	hl
		xor		a, a			; ALL_SEG: user segment
		ld		b, 0			; primary mapper
		call	map_all_seg
		pop		hl
		jr		c, mi_af
		ld		[hl], a
		inc		hl
		pop		bc
		djnz		mi_alloc
		ld		a, POOL_MAXSEG
		ld		[pool_nsegs], a
		ret
mi_af:
		pop		bc
		; adaptive pool: keep however many segments we could allocate
		ld		a, POOL_MAXSEG
		sub		a, b
		ld		[pool_nsegs], a
		cp		a, 2
		jr		nc, mi_have		; >= 2 segments (32KB) is workable
		call	mapper_free_all
		ld		hl, s_nomem
		call	puts
		ld		b, 1
		jp		term_raw
mi_have:
		ret
mi_nomap:
		ld		hl, s_nomap
		call	puts
		ld		b, 1
		jp		term_raw
s_nomap:
		db		"No mapper support.", 13, 10, 0
s_nomem:
		db		"Out of mapper segments.", 13, 10, 0

mapper_free_all:
		ld		a, [pool_nsegs]
		or		a, a
		ret		z
		ld		b, a
		ld		hl, pool_segs
mf_l:
		push	bc
		push	hl
		ld		a, [hl]
		ld		b, 0			; primary mapper
		call	map_fre_seg
		pop		hl
		inc		hl
		pop		bc
		djnz		mf_l
		xor		a, a
		ld		[pool_nsegs], a
		; the arena shares the pool segments: nothing extra to free,
		; just forget the arena reservation
		xor		a, a
		ld		[arena_nsegs], a
		ret

;	map_all_seg: A=mode, B=slot -> tail jump to ALL_SEG (+0)
map_all_seg:
		ld		hl, [map_jtab]
		jp		hl
;	map_fre_seg: A=seg, B=slot -> tail jump to FRE_SEG (+3); destroys HL
map_fre_seg:
		ld		hl, [map_jtab]
		inc		hl
		inc		hl
		inc		hl
		jp		hl
;	map_rd_seg: segment in [prs_seg], HL = intra-segment address
;	-> A = byte read (RD_SEG, +6).  All other registers preserved.
map_rd_seg:
		ld		[mrs_a1 + 1], hl	; stash address
		ld		hl, [map_jtab]
		ld		a, l
		add		a, 6
		ld		[mrs_jp + 1], a
		ld		a, h
		adc		a, 0
		ld		[mrs_jp + 2], a
		ld		a, [prs_seg]
mrs_a1:
		ld		hl, 0			; patched: address
mrs_jp:
		jp		0				; patched: RD_SEG entry
;	map_wr_seg: segment in [prs_seg], HL = address, E = byte (WR_SEG, +9)
map_wr_seg:
		ld		[mws_a1 + 1], hl
		ld		hl, [map_jtab]
		ld		a, l
		add		a, 9
		ld		[mws_jp + 1], a
		ld		a, h
		adc		a, 0
		ld		[mws_jp + 2], a
		ld		a, [prs_seg]
mws_a1:
		ld		hl, 0
mws_jp:
		jp		0

prs_seg:
		db		0
map_jtab:
		dw		0
pool_segs:
		space	POOL_MAXSEG
pool_limit_segs:
		db		0
pool_nsegs:
		db		0
pool_top:
		dw		16, 0			; offsets 0..15 reserved (0 = nil)

;	pio = current pool offset (4 bytes LE)
pio:
		space	4
pio_tmp:
		space	4

;	pio_setup: compute [prs_seg] and HL = intra-segment address from pio
pio_setup:
		ld		a, [pio + 1]
		rlca
		rlca
		and		a, 3			; index bits 0-1 (offset bits 14-15)
		ld		b, a
		ld		a, [pio + 2]
		and		a, 1			; offset bit 16
		rlca
		rlca					; index bit 2
		or		a, b			; segment index 0..7
		ld		hl, pool_segs
		add		a, l
		ld		l, a
		jr		nc, ps_nc
		inc		h
ps_nc:
		ld		a, [hl]
		ld		[prs_seg], a
		ld		a, [pio]
		ld		l, a
		ld		a, [pio + 1]
		and		a, 0x3F
		or		a, 0x80			; page-2 window address for RD_SEG/WR_SEG
		ld		h, a
		ret

;	pio_read8: A = byte at pio (only A/F destroyed)
pio_read8:
		push	hl
		push	bc
		call	pio_setup
		call	map_rd_seg
		pop		bc
		pop		hl
		ret

;	pio_write8: byte in [pw_val] written at pio (only A/F destroyed)
pw_val:
		db		0
pio_write8:
		push	hl
		push	de
		push	bc
		call	pio_setup
		ld		a, [pw_val]
		ld		e, a
		call	map_wr_seg
		pop		bc
		pop		de
		pop		hl
		ret

;	pio_inc: pio += 1
pio_inc:
		push	hl
		ld		hl, pio
		inc		[hl]
		jr		nz, pi_1
		inc		hl
		inc		[hl]
		jr		nz, pi_1
		inc		hl
		inc		[hl]
		jr		nz, pi_1
		inc		hl
		inc		[hl]
pi_1:
		pop		hl
		ret

;	pio_set: DE:HL -> pio
pio_set:
		ld		[pio], hl
		ld		[pio + 2], de
		ret

;	pio_get: pio -> DE:HL
pio_get:
		ld		hl, [pio]
		ld		de, [pio + 2]
		ret

;	off_copy_add: HL = ptr to 4-byte offset, A = displacement (0..127)
;	-> pio = *HL + A
off_copy_add:
		ld		e, [hl]
		inc		hl
		ld		d, [hl]
		inc		hl
		ld		c, [hl]
		inc		hl
		ld		b, [hl]			; BC:DE = offset
		add		a, e
		ld		e, a
		jr		nc, oca_1
		inc		d
		jr		nz, oca_1
		inc		c
		jr		nz, oca_1
		inc		b
oca_1:
		ld		[pio], de
		ld		[pio + 2], bc
		ret

;	off_is_zero: HL = ptr to 4-byte offset -> Z if zero
off_is_zero:
		ld		a, [hl]
		inc		hl
		or		a, [hl]
		inc		hl
		or		a, [hl]
		inc		hl
		or		a, [hl]
		ret

;	pool_alloc: HL = size -> DE:HL = old pool_top (the new block offset)
;	fatal on overflow
pool_alloc:
		ld		de, [pool_top]
		ld		bc, [pool_top + 2]	; BC:DE = old top
		push	bc
		push	de			; save result (high, low)
		add		hl, de
		ex		de, hl			; DE = new low word
		jr		nc, pa_nc
		inc		bc
pa_nc:
		ld		[pool_top], de
		ld		[pool_top + 2], bc
		; limit check: top must be <= limit_segs << 14
		; (pool_limit_segs excludes the arena segments at the top)
		ld		a, [pool_limit_segs]
		ld		l, a
		ld		h, 0
		add		hl, hl
		add		hl, hl			; HL = nsegs << 2 = high word of limit
		ld		a, c
		cp		a, l			; compare new-top high word (BC) with limit high
		jr		c, pa_ok		; (high word of limit fits in L since nsegs<=8)
		jr		nz, pa_over
		ld		a, b
		cp		a, h			; H=0
		jr		nz, pa_over
		; high words equal: low words: limit low = (nsegs&3)<<14
		ld		a, [pool_limit_segs]
		and		a, 3
		rrca
		rrca					; (nsegs&3) -> bits 6-7 = <<14 high byte
		ld		h, a
		ld		l, 0			; HL = limit low word
		ld		a, d
		cp		a, h
		jr		c, pa_ok
		jr		nz, pa_over
		ld		a, e
		cp		a, l
		jr		c, pa_ok
		jr		z, pa_ok
pa_over:
		ld		hl, s_pool_over
		call	puts
		jp		fatal_exit
pa_ok:
		pop		hl				; HL = old top low word (pushed last)
		pop		de				; DE = old top high word
		ret
s_pool_over:
		db		"Symbol pool overflow.", 13, 10, 0

;	fatal_exit: free mapper segments and exit(1); also used by cleanup path
fatal_exit:
		call	close_all_files
		call	mapper_free_all
		ld		b, 1
		jp		term_raw

; =============================================================================
;	Symbol table
;	record in pool: [next:4][value:4][flags:1][namelen:1][name bytes...]
;	hash: 1024 buckets resident, 4-byte pool offsets (0 = nil)
;	lookup name: name_buf (upcased), name_len
;	current record offset kept in sym_off (4 bytes)
; =============================================================================
SYM_VALUE	:= 4
SYM_FLAGS	:= 8
SYM_NLEN	:= 9
SYM_DEFL	:= 10			; definer line no (assignments, P2)
SYM_DEFID	:= 12			; definer file-id (assignments, P2)
SYM_NAME	:= 14
SYM_F_DEFINED	:= 1
SYM_F_GLOBAL	:= 2
SYM_F_ASSIGN	:= 4
SYM_F_STRING	:= 8			; value field = pool offset of string block

sym_off:
		space	4
bkt_off:
		space	4
name_buf:
		space	64
name_len:
		db		0
qname_buf:
		space	64
qname_len:
		db		0

hash_clear:
		ld		hl, hash_table
		ld		de, hash_table + 1
		ld		bc, 4096 - 1
		xor		a, a
		ld		[hl], a
		ldir
		ret

;	name_hash: hash name_buf -> HL = bucket byte address in hash_table
name_hash:
		ld		hl, 0
		ld		de, name_buf
		ld		a, [name_len]
		ld		b, a
		or		a, a
		jr		z, nh_done
nh_l:
		ld		a, [de]
		inc		de
		push	bc
		ld		b, h
		ld		c, l			; BC = h
		add		hl, hl
		add		hl, hl
		add		hl, hl
		add		hl, hl
		add		hl, hl			; h << 5
		add		hl, bc			; h*33
		ld		c, a
		ld		b, 0
		add		hl, bc			; + char
		pop		bc
		djnz		nh_l
nh_done:
		ld		a, h
		and		a, 3
		ld		h, a			; bucket index = h & 1023
		add		hl, hl
		add		hl, hl			; *4
		ld		de, hash_table
		add		hl, de
		ret

;	sym_find: name_buf -> found: sym_off set, NZ; not found: Z
sym_find:
		call	name_hash		; HL = &bucket
		ld		[bkt_ptr], hl		; remember bucket address (resident ptr)
		ld		e, [hl]
		inc		hl
		ld		d, [hl]
		inc		hl
		ld		c, [hl]
		inc		hl
		ld		b, [hl]			; BC:DE = head offset
		ld		hl, sym_off
		ld		[hl], e
		inc		hl
		ld		[hl], d
		inc		hl
		ld		[hl], c
		inc		hl
		ld		[hl], b
sf_loop:
		ld		hl, sym_off
		call	off_is_zero
		ret		z				; not found (Z)
		; compare name length
		ld		hl, sym_off
		ld		a, SYM_NLEN
		call	off_copy_add
		call	pio_read8
		ld		b, a
		ld		a, [name_len]
		cp		a, b
		jr		nz, sf_next
		; compare bytes
		ld		hl, sym_off
		ld		a, SYM_NAME
		call	off_copy_add		; pio = &name in record
		ld		de, name_buf
		ld		a, [name_len]
		ld		b, a
		or		a, a
		jr		z, sf_found
sf_cmp:
		call	pio_read8
		ld		c, a
		ld		a, [de]
		cp		a, c
		jr		nz, sf_next
		inc		de
		call	pio_inc
		djnz		sf_cmp
sf_found:
		or		a, 1			; NZ = found
		ret
sf_next:
		ld		hl, sym_off
		xor		a, a
		call	off_copy_add		; pio = &next
		ld		hl, sym_off
		ld		b, 4
sf_rd4:
		call	pio_read8
		ld		[hl], a
		inc		hl
		call	pio_inc
		djnz		sf_rd4
		jr		sf_loop
bkt_ptr:
		dw		0

;	sym_create: create record for name_buf, link at bucket head.
;	-> sym_off = new record (flags=0, value=0, undefined)
sym_create:
		call	name_hash
		ld		[bkt_ptr], hl
		; size = SYM_NAME + name_len
		ld		a, [name_len]
		add		a, SYM_NAME
		ld		l, a
		ld		h, 0
		call	pool_alloc		; DE:HL = new offset
		ld		[sym_off], hl
		ld		[sym_off + 2], de
		; read old bucket head
		ld		hl, [bkt_ptr]
		ld		e, [hl]
		inc		hl
		ld		d, [hl]
		inc		hl
		ld		c, [hl]
		inc		hl
		ld		b, [hl]			; BC:DE = old head
		; write next field = old head
		; (off_copy_add loads the offset into BC:DE, destroying the
		; old head held there -- preserve it across the call)
		push	bc
		push	de
		ld		hl, sym_off
		xor		a, a
		call	off_copy_add		; pio = record+0
		pop		de
		pop		bc
		ld		a, e
		ld		[pw_val], a
		call	pio_write8
		call	pio_inc
		ld		a, d
		ld		[pw_val], a
		call	pio_write8
		call	pio_inc
		ld		a, c
		ld		[pw_val], a
		call	pio_write8
		call	pio_inc
		ld		a, b
		ld		[pw_val], a
		call	pio_write8
		call	pio_inc
		; value (4 bytes) = 0
		ld		b, 4
		xor		a, a
		ld		[pw_val], a
sc_zv:
		call	pio_write8
		call	pio_inc
		djnz		sc_zv
		; flags = 0
		call	pio_write8
		call	pio_inc
		; name length
		ld		a, [name_len]
		ld		[pw_val], a
		call	pio_write8
		call	pio_inc
		; definer line/id = 0 (P2)
		xor		a, a
		ld		[pw_val], a
		ld		b, 4
sc_zd:
		call	pio_write8
		call	pio_inc
		djnz	sc_zd
		; name bytes
		ld		de, name_buf
		ld		a, [name_len]
		ld		b, a
		or		a, a
		jr		z, sc_link
sc_nb:
		ld		a, [de]
		inc		de
		ld		[pw_val], a
		call	pio_write8
		call	pio_inc
		djnz		sc_nb
sc_link:
		; bucket head = sym_off
		ld		hl, [bkt_ptr]
		ld		de, [sym_off]
		ld		[hl], e
		inc		hl
		ld		[hl], d
		inc		hl
		ld		de, [sym_off + 2]
		ld		[hl], e
		inc		hl
		ld		[hl], d
		ret

;	sym_get: sym_off record -> val_tmp (4 bytes), A = flags
val_tmp:
		space	4
sym_get:
		ld		hl, sym_off
		ld		a, SYM_VALUE
		call	off_copy_add
		ld		hl, val_tmp
		ld		b, 4
sg_l:
		call	pio_read8
		ld		[hl], a
		inc		hl
		call	pio_inc
		djnz		sg_l
		ld		hl, sym_off
		ld		a, SYM_FLAGS
		call	off_copy_add
		call	pio_read8
		ret

;	sym_put: write val_tmp + flags in A to sym_off record
sym_put:
		push	af
		ld		hl, sym_off
		ld		a, SYM_VALUE
		call	off_copy_add
		ld		hl, val_tmp
		ld		b, 4
sp_l:
		ld		a, [hl]
		inc		hl
		ld		[pw_val], a
		call	pio_write8
		call	pio_inc
		djnz		sp_l
		ld		hl, sym_off
		ld		a, SYM_FLAGS
		call	off_copy_add
		pop		af
		ld		[pw_val], a
		call	pio_write8
		ret

;	sym_define: define name_buf = val_tmp with extra flags in A.
;	Sets pass_changed if value/defined-state changed.
;	Uses: find or create; compare; store.
def_extra:
		db		0
sym_define:
		ld		[def_extra], a
		call	sym_find
		jr		nz, sd_have
		call	sym_create
		; fresh record: undefined -> definition always a change
		ld		hl, new_val
		ld		de, val_tmp
		ld		bc, 4
		ldir
		ld		a, 1
		ld		[pass_changed], a
		ld		hl, [dict_chg]		; P4: IF candidate detection
		inc		hl
		ld		[dict_chg], hl
		ld		a, [def_extra]
		or		a, SYM_F_DEFINED
		jp		sym_put
sd_have:
		push	af				; (A unused here, keep stack balanced)
		pop		af
		call	sym_get			; val_tmp = old, A = old flags
		ld		b, a
		bit		0, b
		jr		z, sd_set		; was undefined -> change
		bit		3, b			; old value is a string?
		jr		nz, sd_oldstr
		; old is integer: new string -> type change
		ld		a, [def_extra]
		and		a, SYM_F_STRING
		jr		nz, sd_set
		; compare old val_tmp with new value in new_val
		ld		hl, val_tmp
		ld		de, new_val
		ld		b, 4
sd_cmp:
		ld		a, [de]
		cp		a, [hl]
		jr		nz, sd_set
		inc		hl
		inc		de
		djnz		sd_cmp
		jr		sd_same
sd_oldstr:
		; old is string: new must be string with equal contents
		ld		a, [def_extra]
		and		a, SYM_F_STRING
		jr		z, sd_set		; type change -> changed
		ld		hl, val_tmp
		ld		de, new_val
		call	str_cmp_cells	; Z if contents equal
		jr		nz, sd_set
sd_same:
		; same value: still ensure flags updated (defined|extra)
		ld		a, [new_flg]
		ld		b, a
		jr		sd_put2
sd_set:
		ld		a, 1
		ld		[pass_changed], a
		ld		hl, [dict_chg]		; P4: IF candidate detection
		inc		hl
		ld		[dict_chg], hl
		; copy new_val -> val_tmp
		ld		hl, new_val
		ld		de, val_tmp
		ld		bc, 4
		ldir
sd_put2:
		; flags = old flags | defined | extra(from def_extra)
		; NOTE: sym_get_flags_only (via off_copy_add) destroys BC, so the
		; new-flags byte must not be kept in C across the call.
		ld		a, [def_extra]
		or		a, SYM_F_DEFINED
		ld		[sd_newflg], a
		call	sym_get_flags_only	; A = old flags
		ld		b, a
		ld		a, [sd_newflg]
		or		a, b
		jp		sym_put
sd_newflg:
		db		0
new_val:
		space	4
new_flg:
		db		0

;	sym_get_flags_only: A = flags of sym_off record
sym_get_flags_only:
		ld		hl, sym_off
		ld		a, SYM_FLAGS
		call	off_copy_add
		call	pio_read8
		ret

;	sym_define_d: define global symbol: name in d_name_buf (NUL-term),
;	value in d_tmp_val.  Used for -D options (before assembly starts).
d_name_buf:
		space	64
d_val_buf:
		space	40
d_tmp_val:
		space	4
sym_define_d:
		; copy name (upcased) into name_buf
		ld		hl, d_name_buf
		ld		de, name_buf
		ld		b, 0
sdd_cp:
		ld		a, [hl]
		or		a, a
		jr		z, sdd_done
		call	upcase
		ld		[de], a
		inc		hl
		inc		de
		inc		b
		jr		sdd_cp
sdd_done:
		ld		a, b
		ld		[name_len], a
		xor		a, a
		ld		[de], a
		ld		hl, d_tmp_val
		ld		de, new_val
		ld		bc, 4
		ldir
		ld		a, [d_flags]
		call	sym_define
		ret
d_flags:
		db		SYM_F_ASSIGN | SYM_F_GLOBAL

;	upcase: A -> uppercase (ASCII + a few)
upcase:
		cp		a, 'a'
		ret		c
		cp		a, 'z' + 1
		ret		nc
		sub		a, 0x20
		ret

; =============================================================================
;	String values (P2)
;	A string value is a pool block: [len:2][bytes...]; a symbol with
;	SYM_F_STRING holds the block's 32-bit pool offset in its value field.
;	Expression values: DE:HL = int32 or pool offset, plus [val_type]
;	(0 = integer, 1 = string) and [val_undef], maintained by
;	parse_primary / parse_unary / parse_expr / apply_op.
; =============================================================================
STR_MAX	:= 1024
val_type:
		db		0
val_undef:
		db		0
resv_type:
		db		0
resv_undef:
		db		0
lv_type:
		db		0
lv_undef:
		db		0
rv_type:
		db		0
rv_undef:
		db		0
expr_errkind:
		db		0			; 0 syntax, 1 illegal expression, 2 div by zero
sbuf_a:
		space	STR_MAX + 8
sbuf_b:
		space	STR_MAX + 8
intern_off:
		space	4
sf_len:
		dw		0

;	intern_begin: BC = total length -> allocate block, write header,
;	pio left at first data byte.  Length > STR_MAX -> expr_error.
intern_begin:
		ld		a, b
		cp		a, (STR_MAX >> 8) + 1
		jr		c, ib_lenok
		jr		nz, si_toolong
		ld		a, c
		or		a, a
		jr		nz, si_toolong
ib_lenok:
		push	bc
		ld		l, c
		ld		h, b
		inc		hl
		inc		hl				; size = len + 2
		call	pool_alloc		; DE:HL = offset
		ld		[intern_off], hl
		ld		[intern_off + 2], de
		call	pio_set			; pio = offset
		pop		bc
		ld		a, c
		ld		[pw_val], a
		call	pio_write8
		call	pio_inc
		ld		a, b
		ld		[pw_val], a
		call	pio_write8
		call	pio_inc
		ret

;	intern_write: HL = source, BC = length -> copy bytes to pool at pio
intern_write:
		ld		a, b
		or		a, c
		ret		z
iw_l:
		ld		a, [hl]
		inc		hl
		ld		[pw_val], a
		call	pio_write8
		call	pio_inc
		dec		bc
		ld		a, b
		or		a, c
		jr		nz, iw_l
		ret

;	str_intern: HL = RAM source, BC = length -> DE:HL = pool offset
str_intern:
		push	hl				; intern_begin destroys HL (size arg)
		call	intern_begin
		pop		hl
		call	intern_write
		ld		hl, [intern_off]
		ld		de, [intern_off + 2]
		ret
si_toolong:
		ld		a, 1
		ld		[expr_error], a
		ld		[expr_errkind], a
		ld		de, 0
		ld		hl, 0
		ret

;	str_fetch: HL = ptr to 4-byte pool offset, DE = RAM dest
;	-> bytes copied (NUL-terminated), BC = length
str_fetch:
		push	de
		xor		a, a
		call	off_copy_add	; pio = offset
		pop		de
		call	pio_read8
		ld		[sf_len], a
		call	pio_inc
		call	pio_read8
		ld		[sf_len + 1], a
		call	pio_inc
		ld		bc, [sf_len]
		ld		a, b
		or		a, c
		jr		z, sf_fin
sf_l:
		call	pio_read8
		ld		[de], a
		inc		de
		call	pio_inc
		dec		bc
		ld		a, b
		or		a, c
		jr		nz, sf_l
sf_fin:
		xor		a, a
		ld		[de], a
		ld		bc, [sf_len]
		ret

;	str_cmp_cells: HL = offset cell A, DE = offset cell B
;	-> Z if string contents are equal
str_cmp_cells:
		push	hl
		push	de
		ld		de, sbuf_b
		pop		hl				; cell B
		push	hl
		call	str_fetch		; B-string in sbuf_b, BC = len
		ld		[sf_len], bc
		pop		de				; (stack tidy) cell B discarded
		pop		hl				; cell A
		ld		de, sbuf_a
		call	str_fetch		; BC = len A
		ld		hl, [sf_len]
		ld		a, l
		cp		a, c
		jr		nz, scc_ne
		ld		a, h
		cp		a, b
		jr		nz, scc_ne
		ld		a, b
		or		a, c
		jr		z, scc_eq
		ld		hl, sbuf_a
		ld		de, sbuf_b
scc_l:
		ld		a, [de]
		cp		a, [hl]
		jr		nz, scc_ne
		inc		hl
		inc		de
		dec		bc
		ld		a, b
		or		a, c
		jr		nz, scc_l
scc_eq:
		xor		a, a				; Z
		ret
scc_ne:
		ld		a, 1
		or		a, a				; NZ
		ret

;	dec32_to_buf: HL = ptr to 4-byte signed cell, DE = dest
;	-> decimal ASCII (NUL-terminated), BC = number of chars
dec_cell:
		space	4
dec_rem:
		db		0
dec_cnt:
		db		0
dec_rev:
		space	12
dec32_to_buf:
		ld		[dec_dest], de
		ld		de, dec_cell
		ld		bc, 4
		ldir					; dec_cell = *HL
		ld		hl, dec_cell
		ld		a, [dec_cell + 3]
		and		a, 0x80
		ld		[dec_sign], a
		jr		z, dc_pos
		ld		hl, dec_cell
		call	neg_cell		; magnitude
dc_pos:
		ld		de, [dec_dest]
		ld		a, [dec_sign]
		or		a, a
		jr		z, dc_digits
		ld		a, '-'
		ld		[de], a
		inc		de
dc_digits:
		push	de				; digit area start
		ld		hl, dec_rev
		xor		a, a
		ld		[dec_cnt], a	; digit count (B is div10u's counter!)
dc_dloop:
		push	hl				; save digit pointer (div10u leaves HL=dec_cell)
		call	div10u			; dec_cell /= 10, A = remainder
		pop		hl
		add		a, '0'
		ld		[hl], a
		inc		hl
		ld		a, [dec_cnt]
		inc		a
		ld		[dec_cnt], a
		push	hl
		ld		hl, dec_cell
		call	is_zero32
		pop		hl
		jr		nz, dc_dloop
		; copy reversed digits out
		pop		de
		ld		a, [dec_cnt]
		ld		c, a				; C = digit count
		ld		a, [dec_sign]
		or		a, a
		jr		z, dc_nosign
		ld		b, 1				; total includes sign ('-' already emitted)
		jr		dc_copy
dc_nosign:
		ld		b, 0
dc_copy:
		dec		hl				; dec_rev end-1
		ld		a, [hl]
		ld		[de], a
		inc		de
		inc		b
		dec		c
		jr		nz, dc_copy
		xor		a, a
		ld		[de], a
		ld		c, b
		ld		b, 0				; BC = total length
		ret
dec_sign:
		db		0
dec_dest:
		dw		0

;	div10u: dec_cell (unsigned 32-bit) /= 10; A = remainder
div10u:
		xor		a, a
		ld		[dec_rem], a
		ld		b, 32
d10_l:
		ld		hl, dec_cell
		sla		[hl]
		inc		hl
		rl		[hl]
		inc		hl
		rl		[hl]
		inc		hl
		rl		[hl]				; carry = old bit31
		ld		a, [dec_rem]
		rla						; rem = rem*2 + carry
		ld		[dec_rem], a
		cp		a, 10
		jr		c, d10_nosub
		sub		a, 10
		ld		[dec_rem], a
		ld		hl, dec_cell
		inc		[hl]				; quotient bit0 = 1 (was shifted in as 0)
d10_nosub:
		djnz	d10_l
		ld		a, [dec_rem]
		ret

;	str_of_value: HL = value cell ptr, A = type (0 int / 1 string),
;	DE = dest buffer -> BC = length of the string form
str_of_value:
		or		a, a
		jr		nz, sov_str
		ld		[dec_dest], de
		jp		dec32_to_buf
sov_str:
		jp		str_fetch

;	emit_str_bytes: HL = ptr to 4-byte pool offset -> emit all bytes
emit_str_bytes:
		xor		a, a
		call	off_copy_add	; pio = offset
		call	pio_read8
		ld		[sf_len], a
		call	pio_inc
		call	pio_read8
		ld		[sf_len + 1], a
		call	pio_inc
		ld		bc, [sf_len]
		ld		a, b
		or		a, c
		ret		z
esb_l:
		call	pio_read8
		push	bc
		call	emit8
		pop		bc
		call	pio_inc
		dec		bc
		ld		a, b
		or		a, c
		jr		nz, esb_l
		ret

;	intern_default_str: intern "DEFAULT" for CHAR_SET_NAME (P2)
defstr_off:
		space	4
s_default_str:
		db		"DEFAULT", 0
intern_default_str:
		ld		hl, s_default_str
		ld		bc, 7
		call	str_intern
		ld		[defstr_off], hl
		ld		[defstr_off + 2], de
		ret

; =============================================================================
;	Scope stack (minimal SCOPE/ENDSCOPE pulled forward from P2 so the
;	baconlib corpus assembles: names are qualified prefix strings)
;	scope_names[d] = scope name at depth d (d = 0..depth-1)
; =============================================================================
SCOPE_MAX	:= 8
scope_depth:
		db		0
scope_names:
		space	SCOPE_MAX * 33		; 32 chars + NUL each

;	build_qname: HL = ptr to NUL-terminated plain name (in name_src_buf)
;	number of scope levels to apply in A (0..scope_depth)
;	-> qname_buf/qname_len = qualified name (levels joined with ':')
name_src_buf:
		space	64
bq_levels:
		db		0
build_qname:
		ld		[bq_levels], a
		ld		de, qname_buf
		ld		b, 0			; total length
		ld		c, 0			; level index
bq_lv:
		ld		a, [bq_levels]
		cp		a, c
		jr		z, bq_name
		; copy scope_names[c]
		push	bc
		ld		a, c
		ld		l, a
		ld		h, 0
		add		hl, hl
		add		hl, hl
		add		hl, hl
		add		hl, hl
		add		hl, hl			; *32
		ld		c, a
		ld		b, 0
		add		hl, bc			; *33 total
		ld		bc, scope_names
		add		hl, bc
		pop		bc
bq_sc:
		ld		a, [hl]
		or		a, a
		jr		z, bq_dot
		ld		[de], a
		inc		hl
		inc		de
		inc		b
		jr		bq_sc
bq_dot:
		ld		a, ':'
		ld		[de], a
		inc		de
		inc		b
		inc		c
		jr		bq_lv
bq_name:
		ld		hl, name_src_buf
bq_nc:
		ld		a, [hl]
		or		a, a
		jr		z, bq_fin
		ld		[de], a
		inc		hl
		inc		de
		inc		b
		jr		bq_nc
bq_fin:
		xor		a, a
		ld		[de], a
		ld		a, b
		ld		[qname_len], a
		ret

;	set_name_from_qname: name_buf = qname_buf
set_name_from_qname:
		ld		hl, qname_buf
		ld		de, name_buf
		ld		bc, 64
		ldir
		ld		a, [qname_len]
		ld		[name_len], a
		ret

;	sym_lookup_scoped: name in name_src_buf (plain, NUL-term).
;	Searches qualified names from deepest scope outwards, then plain.
;	If nothing found: creates a PLAIN undefined entry (reference stub).
;	-> sym_off set (found or stub), A = flags, val_tmp = value.
;	   expr_undef set (by caller via flags bit0 check).
sym_lookup_scoped:
		ld		a, [scope_depth]
		ld		[sl_d], a
sl_try:
		ld		a, [sl_d]
		call	build_qname		; qname with sl_d levels
		call	set_name_from_qname
		call	link_check_name	; P3: LINK trigger marking (cross check_link)
		call	sym_find
		jr		nz, sl_found
		ld		a, [sl_d]
		or		a, a
		jr		z, sl_stub
		dec		a
		ld		[sl_d], a
		jr		sl_try
sl_stub:
		; name_buf already holds plain name (levels=0)
		call	sym_create
sl_found:
		call	sym_get
		ret
sl_d:
		db		0

;	sym_define_scoped: define name in name_src_buf with value new_val,
;	extra flags in A.  If A has SYM_F_GLOBAL or depth==0: plain name.
;	Else qualified with all current scope levels.
sym_define_scoped:
		ld		[def_extra], a
		bit		1, a			; SYM_F_GLOBAL?
		jr		nz, sds_plain
		ld		a, [scope_depth]
		or		a, a
		jr		z, sds_plain
		call	build_qname		; A = depth (all levels)
		call	set_name_from_qname
		jr		sds_go
sds_plain:
		; name_buf = name_src_buf
		ld		hl, name_src_buf
		ld		de, name_buf
		ld		b, 0
sds_cp:
		ld		a, [hl]
		ld		[de], a
		or		a, a
		jr		z, sds_cpd
		inc		hl
		inc		de
		inc		b
		jr		sds_cp
sds_cpd:
		ld		a, b
		ld		[name_len], a
sds_go:
		ld		a, [def_extra]
		call	sym_define
		ret

; ---------------------------------------------------------------------------
;	sym_define_assign (P2): assignment definition with cross-ZMA
;	duplicate rejection.  Extra flags in A (SYM_F_ASSIGN set, plus
;	SYM_F_GLOBAL / SYM_F_STRING as applicable); target name in
;	name_src_buf, value in new_val.  If the symbol is already defined
;	by a DIFFERENT source line (or by a label), the first definition
;	wins and the final pass reports "Multiple definition.".
; ---------------------------------------------------------------------------
defl_tmp:
		space	4
defl_new:
		space	4
sda_extra:
		db		0
sym_define_assign:
		ld		[sda_extra], a
		bit		1, a			; SYM_F_GLOBAL?
		jr		nz, sda_plain
		ld		a, [scope_depth]
		or		a, a
		jr		z, sda_plain
		call	build_qname		; A = depth (all levels)
		call	set_name_from_qname
		jr		sda_have_name
sda_plain:
		ld		hl, name_src_buf
		ld		de, name_buf
		ld		b, 0
sda_cp:
		ld		a, [hl]
		ld		[de], a
		or		a, a
		jr		z, sda_cpd
		inc		hl
		inc		de
		inc		b
		jr		sda_cp
sda_cpd:
		ld		a, b
		ld		[name_len], a
sda_have_name:
		call	sym_find
		jr		z, sda_set		; no record yet -> define
		call	sym_get			; val_tmp = value, A = flags
		bit		0, a
		jr		z, sda_set		; undefined stub -> define
		bit		2, a			; SYM_F_ASSIGN?
		jr		z, sda_dup		; defined by a label -> duplicate
		push	af
		call	sym_get_definer	; defl_tmp = stored definer
		call	cur_definer		; defl_new = this line
		pop		af
		ld		hl, defl_tmp
		ld		de, defl_new
		ld		b, 4
sda_dcmp:
		ld		a, [de]
		cp		a, [hl]
		jr		nz, sda_dup
		inc		hl
		inc		de
		djnz	sda_dcmp
		jr		sda_set			; same line: normal (re)define
sda_dup:
		ld		a, [final_pass]
		or		a, a
		ret		z
		ld		hl, s_multdef
		jp		err_line
sda_set:
		call	log_set_info_assign	; reads sda_extra itself; clobbers A
		ld		a, [sda_extra]		; sym_define takes extra flags in A
		call	sym_define
		call	cur_definer
		jp		sym_put_definer

;	cur_definer: defl_new = [current line no (2), file-name hash (2)]
cur_definer:
		ld		hl, [cur_ent]
		ld		de, E_LINE
		add		hl, de
		ld		e, [hl]
		inc		hl
		ld		d, [hl]
		ld		[defl_new], de
		ld		hl, [cur_ent]
		ld		de, E_NAME
		add		hl, de
		ld		de, 0			; hash = 0
cd_hl:
		ld		a, [hl]
		or		a, a
		jr		z, cd_done
		inc		hl
		push	hl
		; DE = DE * 33 + A
		ld		h, d
		ld		l, e			; HL = hash
		push	hl				; save hash
		add		hl, hl
		add		hl, hl
		add		hl, hl
		add		hl, hl
		add		hl, hl			; hash * 32
		pop		de				; DE = hash
		add		hl, de			; hash * 33
		ld		e, a
		ld		d, 0
		add		hl, de			; + char
		ex		de, hl			; DE = new hash
		pop		hl
		jr		cd_hl
cd_done:
		ld		[defl_new + 2], de
		ret

;	sym_get_definer: defl_tmp = definer fields of sym_off record
sym_get_definer:
		ld		hl, sym_off
		ld		a, SYM_DEFL
		call	off_copy_add
		ld		hl, defl_tmp
		ld		b, 4
sgd_l:
		call	pio_read8
		ld		[hl], a
		inc		hl
		call	pio_inc
		djnz	sgd_l
		ret

;	sym_put_definer: definer fields of sym_off record = defl_new
sym_put_definer:
		ld		hl, sym_off
		ld		a, SYM_DEFL
		call	off_copy_add
		ld		hl, defl_new
		ld		b, 4
spd_l:
		ld		a, [hl]
		inc		hl
		ld		[pw_val], a
		call	pio_write8
		call	pio_inc
		djnz	spd_l
		ret

pass_changed:
		db		0

; =============================================================================
;	Input stack (main file + up to 4 INCLUDE levels), line reader,
;	output writer.
;	Entry layout: +0 handle, +1 eof, +2 buf_pos(2),
;	+4 buf_len(2), +6 line_no(2), +8 name(16), +24 buffer(E_BUFSZ)
;	P4: DOS refill chunk shrank 512 -> 128 (read_char is byte-
;	oriented with refill-on-empty, so chunk size is invisible to
;	semantics).  Frees 384 x 13 = 4,992 bytes of .COM image for
;	the P4 features (P3 size left only ~120 bytes of headroom
;	under the ~54,000-byte DOS2 .COM load limit).
; =============================================================================
E_HANDLE	:= 0
E_EOF		:= 1
E_BPOS		:= 2
E_BLEN		:= 4
E_LINE		:= 6
E_NAME		:= 8
E_BUF		:= 24
E_PB		:= E_BUF + E_BUFSZ			; per-entry pushback char (was a single global:
E_PBV		:= E_PB + 1			; a char peeked from the parent stream was
							; discarded by push_include, eating the first
							; char of the line after every INCLUDE)

; --- P3 text-source fields (macro expansion / repeat / link bodies) ---
E_KIND		:= E_PBV + 1			; 0=file, 1=macro text (RAM), 2=repeat (arena),
							; 3=link body (arena)
E_TPOS		:= E_KIND + 1			; text read cursor (RAM addr or arena offset)
E_TEND		:= E_TPOS + 4			; text end (exclusive)
E_TSTART	:= E_TEND + 4			; repeat: body start (arena offset)
E_TLEFT		:= E_TSTART + 4			; repeat: iterations remaining (32-bit)
E_CSYM		:= E_TLEFT + 4			; repeat: counter symbol record offset (pool)
E_CTX		:= E_CSYM + 4	; ctx stack slot index for this frame
ISTK_ENT	:= E_CTX + 1
E_BUFSZ		:= 48			; DOS read chunk per file entry

istk:
		space	ISTK_ENT * 13	; 5 file entries + 8 text entries
istk_depth:
		db		0			; current entry index (0 = main)
cur_ent:
		dw		istk
src_eof:
		db		0
src_pb:
		db		0
src_pb_valid:
		db		0
line_buf:
		space	258
line_len:
		db		0
line_too_long:
		db		0

;	ent_ptr: -> HL = cur_ent
ent_ptr:
		ld		hl, [cur_ent]
		ret

;	open_main_input: HL = filename -> CY on error
open_main_input:
		push	hl				; preserve filename pointer
		xor		a, a
		ld		[istk_depth], a
		ld		[text_depth], a
		ld		hl, istk
		ld		[cur_ent], hl
		ld		[src_frames], hl
		ld		a, 1
		ld		[src_nframes], a
		pop		hl
		; fallthrough to open_into_ent with filename in HL
;	open_into_ent: filename ptr in HL, current entry = cur_ent
;	-> CY on error; entry initialized
open_into_ent:
		ld		[oi_name], hl
		call	dos_open_read		; HL=name -> A=handle / CY
		ret		c
		ld		hl, [cur_ent]
		ld		[hl], a			; E_HANDLE
		xor		a, a
		inc		hl
		ld		[hl], a			; E_EOF = 0
		inc		hl
		ld		[hl], a			; bpos = 0
		inc		hl
		ld		[hl], a
		inc		hl
		ld		[hl], a			; blen = 0
		inc		hl
		ld		[hl], a
		inc		hl
		ld		[hl], a			; line_no = 0
		inc		hl
		ld		[hl], a
		inc		hl				; -> E_NAME
		ex		de, hl
		ld		hl, [oi_name]
		ld		b, 15
oi_nm:
		ld		a, [hl]
		ld		[de], a
		or		a, a
		jr		z, oi_nz
		inc		hl
		inc		de
		djnz		oi_nm
oi_nz:
		xor		a, a
		ld		[de], a
		ld		hl, [cur_ent]
		ld		de, E_PBV
		add		hl, de
		ld		[hl], 0			; no pushback char yet
		ld		hl, [cur_ent]
		ld		de, E_KIND
		add		hl, de
		ld		[hl], 0			; kind = file entry
		ret
oi_name:
		dw		0

;	push_include: HL = filename -> CY on error (incl. depth limit)
;	P3: file entries are depth-indexed (istk + depth*ISTK_ENT); the
;	source frame stack (src_frames) tracks the interleaved file/text
;	source order, cur_ent = top frame.
push_include:
		ld		a, [istk_depth]
		cp		a, 4
		jr		nc, pi_full
		push	hl				; preserve filename ptr
		; new entry = istk + (depth+1) * ISTK_ENT
		ld		hl, istk
		ld		b, a			; current depth
		inc		b			; target depth
		ld		de, ISTK_ENT
pi_mul:
		add		hl, de
		djnz	pi_mul
		ld		[pi_newent], hl
		ld		[cur_ent], hl		; open_into_ent works on cur_ent
		ld		a, [istk_depth]
		inc		a
		ld		[istk_depth], a
		pop		hl
		call	open_into_ent
		jr		nc, pi_pushed
		; open failed: roll back depth, restore cur_ent to top frame
		ld		a, [istk_depth]
		dec		a
		ld		[istk_depth], a
		call	src_sync_cur
		scf
		ret
pi_pushed:
		ld		hl, [pi_newent]
		call	src_push_frame
		or		a, a			; NC
		ret
pi_full:
		scf
		ret
pi_newent:
		dw		0

;	src_push_frame: HL = entry ptr; appends a source frame, cur_ent = HL
src_push_frame:
		push	hl
		ld		a, [src_nframes]
		ld		l, a
		ld		h, 0
		add		hl, hl
		ld		de, src_frames
		add		hl, de
		pop		de
		ld		[hl], e
		inc		hl
		ld		[hl], d
		ld		a, [src_nframes]
		inc		a
		ld		[src_nframes], a
		ld		[cur_ent], de
		ret

;	src_sync_cur: cur_ent = top source frame
src_sync_cur:
		ld		a, [src_nframes]
		dec		a
		ld		l, a
		ld		h, 0
		add		hl, hl
		ld		de, src_frames
		add		hl, de
		ld		e, [hl]
		inc		hl
		ld		d, [hl]
		ld		[cur_ent], de
		ret

;	src_pop_one: pop the top source frame (never the main frame).
;	File entry: close handle, istk_depth--.  Text entry (kind 1/2):
;	pop the auto scope + ctx slot; text_depth-- for kinds 1..3.
src_pop_one:
		ld		hl, [cur_ent]
		ld		de, E_KIND
		add		hl, de
		ld		a, [hl]
		or		a, a
		jr		z, spo_file
		; text entry
		push	af
		cp		a, 3
		jr		z, spo_noscope
		call	scope_pop		; kinds 1/2 own an auto scope
		ld		hl, ctx_sp
		dec		[hl]
spo_noscope:
		ld		hl, text_depth
		dec		[hl]
		pop		af
		jr		spo_done
spo_file:
		ld		hl, [cur_ent]
		ld		a, [hl]			; handle
		call	dos_close
		ld		hl, istk_depth
		dec		[hl]
spo_done:
		ld		hl, src_nframes
		dec		[hl]
		call	src_sync_cur
		ret

src_frames:
		space	32			; 16 frame pointers (file/text entries)
src_nframes:
		db		0
text_depth:
		db		0

;	pop_include: pop one source frame (the exhausted entry)
pop_include:
		jp		src_pop_one

;	rewind_source: close all include files, rewind main file to start
rewind_source:
		ld		a, [src_nframes]
		cp		a, 1
		jr		z, rw_main
		call	pop_include
		jr		rewind_source
rw_main:
		ld		hl, istk
		ld		[cur_ent], hl
		ld		a, [hl]			; main handle
		call	dos_seek0
		xor		a, a
		ld		[istk + E_EOF], a
		ld		[istk + E_BPOS], a
		ld		[istk + E_BPOS + 1], a
		ld		[istk + E_BLEN], a
		ld		[istk + E_BLEN + 1], a
		ld		[istk + E_LINE], a
		ld		[istk + E_LINE + 1], a
		ld		[src_eof], a
		ld		[istk + E_PBV], a	; stream reset: main entry pushback is stale
		ret

;	close_all_files: close every open input + the output file
close_all_files:
		ld		b, 5
		ld		hl, istk
caf_l:
		push	bc
		push	hl
		ld		a, [hl]
		cp		a, 0xFF
		jr		z, caf_skip
		call	dos_close
		pop		hl
		push	hl
		ld		a, 0xFF
		ld		[hl], a
caf_skip:
		pop		hl
		ld		de, ISTK_ENT
		add		hl, de
		pop		bc
		djnz		caf_l
		call	out_close
		ret

;	read_char: -> A = char; src_eof=1 at end of main file (A=0)
read_char:
		xor		a, a
		ld		[src_eof], a		; EOF is signalled per call (see rc_text)
		ld		hl, [cur_ent]
		ld		de, E_PBV
		add		hl, de
		ld		a, [hl]
		or		a, a
		jr		z, rc_stream
		ld		[hl], 0
		dec		hl				; E_PB = E_PBV - 1
		ld		a, [hl]
		ret
rc_stream:
		ld		hl, [cur_ent]
		ld		de, E_KIND
		add		hl, de
		ld		a, [hl]
		or		a, a
		jp		nz, rc_text		; P3: text entry (macro/repeat/link)
		ld		hl, [cur_ent]
		ld		a, [hl]			; +1 = E_EOF: hl+1
		inc		hl
		ld		a, [hl]
		or		a, a
		jr		nz, rc_next_file
		; check buf_pos vs buf_len
		ld		hl, [cur_ent]
		ld		de, E_BPOS
		add		hl, de
		ld		e, [hl]
		inc		hl
		ld		d, [hl]			; DE = buf_pos
		inc		hl
		ld		a, [hl]
		inc		hl
		ld		h, [hl]
		ld		l, a			; HL = buf_len
		ld		a, e
		cp		a, l
		jr		nz, rc_have
		ld		a, d
		cp		a, h
		jr		nz, rc_have
		; refill
		ld		hl, [cur_ent]
		ld		a, [hl]			; handle
		push	af
		ld		de, E_BUF
		add		hl, de			; HL = buffer address
		ld		de, E_BUFSZ
		pop		af
		call	dos_read		; -> HL = bytes read
		; store buf_len = HL, buf_pos = 0
		ex		de, hl
		ld		hl, [cur_ent]
		ld		bc, E_BLEN
		add		hl, bc
		ld		[hl], e
		inc		hl
		ld		[hl], d
		ld		hl, [cur_ent]
		ld		bc, E_BPOS
		add		hl, bc
		xor		a, a
		ld		[hl], a
		inc		hl
		ld		[hl], a
		ld		a, d
		or		a, e
		jr		z, rc_set_eof
		jr		read_char		; retry (pb_valid=0, stream)
rc_have:
		; A = buf[buf_pos]; buf_pos++
		ld		hl, [cur_ent]
		ld		bc, E_BUF
		add		hl, bc
		add		hl, de			; HL = &buf[buf_pos]
		ld		a, [hl]
		push	af
		ld		hl, [cur_ent]
		ld		bc, E_BPOS
		add		hl, bc
		ld		e, [hl]
		inc		hl
		ld		d, [hl]
		inc		de
		ld		[hl], d
		dec		hl
		ld		[hl], e
		pop		af
		ret
rc_set_eof:
		ld		hl, [cur_ent]
		inc		hl				; E_EOF
		ld		a, 1
		ld		[hl], a
rc_next_file:
		ld		a, [src_nframes]
		cp		a, 1
		jr		z, rc_end
		call	pop_include
		jp		read_char
rc_end:
		ld		a, 1
		ld		[src_eof], a
		xor		a, a
		ret

;	unread_char: A = char to push back (single char)
unread_char:
		ld		hl, [cur_ent]
		ld		de, E_PB
		add		hl, de
		ld		[hl], a
		inc		hl
		ld		[hl], 1
		ret

;	get_line: read one line into line_buf (NUL-terminated, <=255 chars)
;	-> CY = no more lines (EOF before any char); NC = line read
;	increments current entry's line_no
get_line:
		xor		a, a
		ld		[line_len], a
		ld		[line_too_long], a
		ld		hl, line_buf
		ld		[gl_ptr], hl
gl_loop:
		call	read_char
		ld		b, a
		ld		a, [src_eof]
		or		a, a
		jr		nz, gl_eof
		ld		a, b
		cp		a, 13
		jr		z, gl_term
		cp		a, 10
		jr		z, gl_term
		ld		hl, line_len
		ld		a, [hl]
		cp		a, 255
		jr		nc, gl_long
		inc		[hl]
		ld		hl, [gl_ptr]
		ld		[hl], b
		inc		hl
		ld		[gl_ptr], hl
		jr		gl_loop
gl_long:
		ld		a, 1
		ld		[line_too_long], a
		jr		gl_loop
gl_term:
		; consume paired LF/CR if present
		ld		[gl_tc], a
		call	read_char
		ld		b, a
		ld		a, [src_eof]
		or		a, a
		jr		nz, gl_fin
		ld		a, [gl_tc]
		cp		a, 13
		jr		nz, gl_t2
		ld		a, b
		cp		a, 10
		jr		z, gl_fin
		jr		gl_pb
gl_t2:
		ld		a, b
		cp		a, 13
		jr		z, gl_fin
gl_pb:
		ld		a, b
		call	unread_char
gl_fin:
		; line_no++ (file entries only; text entries keep the
		; invocation line number, as cross reports expansion lines
		; at the invoking line)
		ld		hl, [cur_ent]
		ld		de, E_KIND
		add		hl, de
		ld		a, [hl]
		or		a, a
		jr		nz, gl_setnul
		ld		hl, [cur_ent]
		ld		de, E_LINE
		add		hl, de
		ld		e, [hl]
		inc		hl
		ld		d, [hl]
		inc		de
		ld		[hl], d
		dec		hl
		ld		[hl], e
gl_setnul:
		ld		hl, [gl_ptr]
		xor		a, a
		ld		[hl], a
		or		a, a			; NC
		ret
gl_eof:
		ld		a, [line_len]
		or		a, a
		jr		nz, gl_fin		; last line without terminator
		ld		a, [src_nframes]
		cp		a, 1
		jr		nz, gl_fin		; text-entry boundary (empty body):
								; an empty line; pop/rollover on next read
		scf
		ret
gl_ptr:
		dw		0
gl_tc:
		db		0

; ---------------------------------------------------------------------------
;	Output writer (only active when output_open flag set by driver)
; ---------------------------------------------------------------------------
out_handle:
		db		0xFF
out_buf:
		space	512
out_len:
		dw		0
out_err:
		db		0

;	out_open: HL = filename -> CY on error
out_open:
		call	dos_create
		ret		c
		ld		[out_handle], a
		call	hex_reset
		ld		hl, 0
		ld		[out_len], hl
		xor		a, a
		ld		[out_err], a
		ret

;	out_flush
out_flush:
		ld		hl, [out_len]
		ld		a, h
		or		a, l
		ret		z
		ex		de, hl			; DE = length
		ld		hl, out_buf
		ld		a, [out_handle]
		call	dos_write		; HL = written
		ld		a, 0
		ld		[out_len], a
		ld		[out_len + 1], a
		ret

;	out_byte: A = byte to write (buffered)
out_byte:
		push	af
		ld		hl, [out_len]
		ld		a, h
		cp		a, 2			; len >= 512?
		jr		c, ob_1
		call	out_flush
		ld		hl, 0
		ld		[out_len], hl
ob_1:
		ld		de, out_buf
		add		hl, de
		pop		af
		ld		[hl], a
		ld		hl, [out_len]
		inc		hl
		ld		[out_len], hl
		ret

;	out_close
out_close:
		ld		a, [out_handle]
		cp		a, 0xFF
		ret		z
		ld		a, [opt_hex]
		or		a, a
		call	nz, hex_flush
		call	out_flush
		ld		a, [out_handle]
		call	dos_close
		ld		a, 0xFF
		ld		[out_handle], a
		ret

; =============================================================================
;	Intel HEX writer (P2 leftover b).  Bytes arrive sequentially
;	(file offsets 0,1,2,...); records hold at most 32 bytes, never
;	cross a 64K boundary, and an extended-linear-address record is
;	emitted when the segment (address >> 16) changes.  No EOF record
;	(cross ZMA writes none).  Line ending is LF.
; =============================================================================
hx_addr:
		space	4			; address of the next byte
hx_rec_addr:
		space	4			; address of the first buffered byte
hx_seg:
		dw		0
hx_len:
		db		0
hx_buf:
		space	32
hx_sum:
		db		0
hex_reset:
		xor		a, a
		ld		[hx_addr], a
		ld		[hx_addr + 1], a
		ld		[hx_addr + 2], a
		ld		[hx_addr + 3], a
		ld		[hx_len], a
		ld		[hx_seg], a
		ld		[hx_seg + 1], a
		ret

;	hex_write: A = byte at [hx_addr] (sequential)
hx_byte:
		db		0
hex_write:
		ld		[hx_byte], a
		; flush on 64K boundary crossing (buffered run must not cross)
		ld		a, [hx_len]
		or		a, a
		jr		z, hw_nob
		ld		a, [hx_addr]
		ld		b, a
		ld		a, [hx_addr + 1]
		or		a, b
		jr		nz, hw_nob		; low 16 bits != 0 -> no crossing
		call	hex_flush
hw_nob:
		ld		a, [hx_len]
		or		a, a
		jr		nz, hw_have
		; start a new record at hx_addr
		ld		hl, [hx_addr]
		ld		[hx_rec_addr], hl
		ld		hl, [hx_addr + 2]
		ld		[hx_rec_addr + 2], hl
hw_have:
		ld		hl, hx_buf
		ld		a, [hx_len]
		ld		e, a
		ld		d, 0
		add		hl, de
		ld		a, [hx_byte]
		ld		[hl], a
		ld		a, [hx_len]
		inc		a
		ld		[hx_len], a
		; hx_addr++
		ld		hl, hx_addr
		inc		[hl]
		jr		nz, hw_adone
		inc		hl
		inc		[hl]
		jr		nz, hw_adone
		inc		hl
		inc		[hl]
		jr		nz, hw_adone
		inc		hl
		inc		[hl]
hw_adone:
		ld		a, [hx_len]
		cp		a, 32
		ret		nz
		jp		hex_flush

;	hex_flush: emit the buffered run as one record (segment record
;	first when the segment changed)
hex_flush:
		ld		a, [hx_len]
		or		a, a
		ret		z
		; segment changed?
		ld		hl, [hx_rec_addr + 2]
		ld		de, [hx_seg]
		ld		a, l
		cp		a, e
		jr		nz, hf_seg
		ld		a, h
		cp		a, d
		jr		z, hf_data
hf_seg:
		ld		[hx_seg], hl
		; ":02000004HHHHcc"
		xor		a, a
		ld		[hx_sum], a
		ld		a, ':'
		call	out_byte
		ld		a, 2
		call	hx_out2
		xor		a, a
		call	hx_out2
		xor		a, a
		call	hx_out2
		ld		a, 4
		call	hx_out2
		ld		a, [hx_seg + 1]
		call	hx_out2
		ld		a, [hx_seg]
		call	hx_out2
		call	hx_out_sum
		ld		a, 10
		call	out_byte
hf_data:
		xor		a, a
		ld		[hx_sum], a
		ld		a, ':'
		call	out_byte
		ld		a, [hx_len]
		call	hx_out2
		ld		a, [hx_rec_addr + 1]
		call	hx_out2
		ld		a, [hx_rec_addr]
		call	hx_out2
		xor		a, a
		call	hx_out2			; record type 00
		ld		hl, hx_buf
		ld		a, [hx_len]
		ld		b, a
hf_dl:
		ld		a, [hl]
		inc		hl
		push	hl
		push	bc
		call	hx_out2
		pop		bc
		pop		hl
		djnz	hf_dl
		call	hx_out_sum
		ld		a, 10
		call	out_byte
		xor		a, a
		ld		[hx_len], a
		ret

;	hx_out2: output A as two uppercase hex digits, adding to hx_sum
hx_out2:
		push	af
		ld		b, a
		ld		a, [hx_sum]
		add		a, b
		ld		[hx_sum], a
		ld		a, b
		rrca
		rrca
		rrca
		rrca
		call	hx_nib
		ld		a, b
		call	hx_nib
		pop		af
		ret
hx_nib:
		and		a, 0x0F
		cp		a, 10
		jr		c, hx_n09
		add		a, 'A' - 10
		jp		out_byte
hx_n09:
		add		a, '0'
		jp		out_byte

;	hx_out_sum: output the two's-complement checksum of hx_sum
hx_out_sum:
		ld		a, [hx_sum]
		neg
		; output without adding to the sum
		ld		b, a
		rrca
		rrca
		rrca
		rrca
		call	hx_nib
		ld		a, b
		jp		hx_nib

; =============================================================================
;	Expression evaluator (numeric, 32-bit signed)
;	Values are DE:HL (DE = high word, HL = low word).
;	expr_undef set when an undefined symbol participates.
;	expr_error set on syntax error / div-by-zero.
;	ev_ptr walks the current text (line_buf segment or other buffer).
; =============================================================================
OP_NONE		:= 0
OP_MUL		:= 1
OP_DIV		:= 2
OP_MOD		:= 3
OP_ADD		:= 4
OP_SUB		:= 5
OP_SHL		:= 6
OP_SHR		:= 7
OP_LT		:= 8
OP_GT		:= 9
OP_LE		:= 10
OP_GE		:= 11
OP_EQ		:= 12
OP_NE		:= 13
OP_AND		:= 14
OP_XOR		:= 15
OP_OR		:= 16
OP_LAND		:= 17
OP_LOR		:= 18

ev_ptr:
		dw		0
expr_undef:
		db		0
expr_error:
		db		0
lv:
		space	4			; apply_op left (LE)
rv:
		space	4			; apply_op right (LE)
resv:
		space	4			; apply_op result / scratch (LE)

; ---- 32-bit memory helpers (little-endian 4-byte cells) --------------------

;	add32: resv = lv + rv
a32_dst:
		dw		0
add32:
		ld		hl, resv
		ld		[a32_dst], hl
		ld		hl, lv
		ld		de, rv
		ld		b, 4
		or		a, a
a32_l:
		ld		a, [de]
		adc		a, [hl]
		push	hl
		ld		hl, [a32_dst]
		ld		[hl], a
		inc		hl
		ld		[a32_dst], hl
		pop		hl
		inc		hl
		inc		de
		djnz		a32_l
		ret

;	sub32: resv = lv - rv
sub32:
		ld		hl, resv
		ld		[a32_dst], hl
		ld		hl, lv
		ld		de, rv
		ld		b, 4
		or		a, a
s32_l:
		ld		a, [de]
		ld		c, a
		ld		a, [hl]
		sbc		a, c
		push	hl
		ld		hl, [a32_dst]
		ld		[hl], a
		inc		hl
		ld		[a32_dst], hl
		pop		hl
		inc		hl
		inc		de
		djnz		s32_l
		ret

;	neg32: resv = -lv
neg32:
		ld		hl, lv
		ld		de, resv
		ld		b, 4
		or		a, a
n32_l:
		ld		a, 0
		sbc		a, [hl]
		ld		[de], a
		inc		hl
		inc		de
		djnz		n32_l
		ret

;	shl32_1: lv <<= 1 (destroys rv? no; in place)
shl32_1:
		ld		hl, lv
		sla		[hl]
		inc		hl
		rl		[hl]
		inc		hl
		rl		[hl]
		inc		hl
		rl		[hl]
		ret

;	shr32_1_logical: lv >>= 1 logical
shr32_1l:
		ld		hl, lv + 3
		srl		[hl]
		dec		hl
		rr		[hl]
		dec		hl
		rr		[hl]
		dec		hl
		rr		[hl]
		ret

;	shr32_1_arith: lv >>= 1 arithmetic (sign extend)
shr32_1a:
		ld		hl, lv + 3
		sra		[hl]
		dec		hl
		rr		[hl]
		dec		hl
		rr		[hl]
		dec		hl
		rr		[hl]
		ret

;	cmp32_signed: compare lv vs rv -> flags like (lv - rv) signed:
;	returns A = -1 (lv<rv), 0 (eq), 1 (lv>rv) in [cmp_res]
cmp32s:
		; equality / sign shortcut: compare high bytes with sign handling
		ld		a, [lv + 3]
		ld		b, a
		ld		a, [rv + 3]
		cp		a, b
		jr		nz, c32_sign
		; same sign: unsigned compare of full 32 bits
		ld		b, 4
		ld		hl, lv + 3
		ld		de, rv + 3
c32_u:
		ld		a, [de]
		cp		a, [hl]
		jr		c, c32_gt		; rv byte < lv byte -> lv > rv
		jr		nz, c32_lt
		dec		hl
		dec		de
		djnz		c32_u
		xor		a, a
		ld		[cmp_res], a
		ret
c32_sign:
		; different signs (top bytes differ and signs differ, or same-sign
		; bytes differ handled by unsigned path above when bit7 equal;
		; here bit7 may differ or not: if top bytes differ but both same
		; sign, unsigned compare of top byte decides)
		ld		a, [rv + 3]
		xor		a, b			; B = lv top
		and		a, 0x80
		jr		z, c32_u_top	; same sign: unsigned top-byte compare
		; signs differ: negative < positive
		ld		a, b
		and		a, 0x80
		jr		nz, c32_lt
		jr		c32_gt
c32_u_top:
		ld		a, [rv + 3]
		cp		a, b
		jr		c, c32_gt
		jr		c32_lt
c32_lt:
		ld		a, -1
		ld		[cmp_res], a
		ret
c32_gt:
		ld		a, 1
		ld		[cmp_res], a
		ret
cmp_res:
		db		0

;	is_zero32: HL = cell ptr -> Z if all zero
is_zero32:
		ld		a, [hl]
		inc		hl
		or		a, [hl]
		inc		hl
		or		a, [hl]
		inc		hl
		or		a, [hl]
		ret

;	mul32: resv = lv * rv (low 32 bits)
mul32:
		ld		hl, resv
		xor		a, a
		ld		[hl], a
		inc		hl
		ld		[hl], a
		inc		hl
		ld		[hl], a
		inc		hl
		ld		[hl], a
		ld		b, 32
m32_l:
		; if rv bit0 set: resv += lv
		ld		a, [rv]
		and		a, 1
		jr		z, m32_no
		push	bc
		ld		hl, resv
		ld		de, lv
		ld		b, 4
		or		a, a
m32_a:
		ld		a, [de]
		adc		a, [hl]
		ld		[hl], a
		inc		hl
		inc		de
		djnz		m32_a
		pop		bc
m32_no:
		; rv >>= 1 (logical), lv <<= 1
		push	bc
		ld		hl, rv + 3
		srl		[hl]
		dec		hl
		rr		[hl]
		dec		hl
		rr		[hl]
		dec		hl
		rr		[hl]
		call	shl32_1
		pop		bc
		djnz		m32_l
		ret

;	divmod32u: unsigned: resv = lv / rv, remv = lv % rv. rv=0 -> expr_error
remv:
		space	4
divmod32u:
		ld		hl, rv
		call	is_zero32
		jr		nz, dm_ok
		ld		a, 1
		ld		[expr_error], a
		ld		a, 2
		ld		[expr_errkind], a
		ld		hl, resv
		xor		a, a
		ld		[hl], a
		inc		hl
		ld		[hl], a
		inc		hl
		ld		[hl], a
		inc		hl
		ld		[hl], a
		ld		hl, remv
		ld		[hl], a
		inc		hl
		ld		[hl], a
		inc		hl
		ld		[hl], a
		inc		hl
		ld		[hl], a
		ret
dm_ok:
		; shift-subtract algorithm; quotient accumulates in resv,
		; remainder in remv; dividend shifted through remv:lv chain
		ld		hl, resv
		xor		a, a
		ld		[hl], a
		inc		hl
		ld		[hl], a
		inc		hl
		ld		[hl], a
		inc		hl
		ld		[hl], a
		ld		hl, remv
		ld		[hl], a
		inc		hl
		ld		[hl], a
		inc		hl
		ld		[hl], a
		inc		hl
		ld		[hl], a
		ld		b, 32
dm_l:
		; shift (remv:lv) left by 1; quotient bit enters resv via carry chain:
		; standard: shift lv left (bit31 -> carry), shift remv left with carry
		push	bc
		ld		hl, lv
		sla		[hl]
		inc		hl
		rl		[hl]
		inc		hl
		rl		[hl]
		inc		hl
		rl		[hl]			; carry = old bit31
		ld		hl, remv
		rl		[hl]
		inc		hl
		rl		[hl]
		inc		hl
		rl		[hl]
		inc		hl
		rl		[hl]
		; shift resv left by 1 (quotient bits enter at bit0 later)
		ld		hl, resv
		sla		[hl]
		inc		hl
		rl		[hl]
		inc		hl
		rl		[hl]
		inc		hl
		rl		[hl]
		; trial: remv >= rv ?
		ld		hl, remv + 3
		ld		de, rv + 3
		ld		b, 4
		or		a, a
dm_cmp:
		ld		a, [de]
		cp		a, [hl]
		jr		c, dm_ge		; rv byte < remv byte -> ge
		jr		nz, dm_lt
		dec		hl
		dec		de
		djnz		dm_cmp
dm_ge:
		; remv -= rv; set quotient bit0
		ld		hl, remv
		ld		de, rv
		ld		b, 4
		or		a, a
dm_sub:
		ld		a, [de]
		ld		c, a
		ld		a, [hl]
		sbc		a, c
		ld		[hl], a
		inc		hl
		inc		de
		djnz		dm_sub
		ld		hl, resv
		set		0, [hl]
dm_lt:
		pop		bc
		djnz		dm_l
		ret

;	apply_op: A = op id; lv = left, rv = right -> result in DE:HL,
;	and also stored in resv.  expr_undef/expr_error untouched except div0.
apply_op:
		ld		[ao_op], a
		xor		a, a
		ld		[resv_type], a
		ld		[resv_undef], a
		ld		a, [lv_undef]
		ld		b, a
		ld		a, [rv_undef]
		or		a, b
		jp		nz, ao_undef_prop
		ld		a, [lv_type]
		ld		b, a
		ld		a, [rv_type]
		or		a, b
		jp		nz, ao_string
		ld		a, [ao_op]
		cp		a, OP_ADD
		jp		z, ao_add
		cp		a, OP_SUB
		jp		z, ao_sub
		cp		a, OP_MUL
		jp		z, ao_mul
		cp		a, OP_DIV
		jp		z, ao_div
		cp		a, OP_MOD
		jp		z, ao_mod
		cp		a, OP_SHL
		jp		z, ao_shl
		cp		a, OP_SHR
		jp		z, ao_shr
		cp		a, OP_AND
		jp		z, ao_and
		cp		a, OP_OR
		jp		z, ao_or
		cp		a, OP_XOR
		jp		z, ao_xor
		cp		a, OP_LAND
		jp		z, ao_land
		cp		a, OP_LOR
		jp		z, ao_lor
		; comparisons
		call	cmp32s
		ld		a, [ao_op]
		cp		a, OP_LT
		jr		z, ao_lt
		cp		a, OP_GT
		jr		z, ao_gt
		cp		a, OP_LE
		jr		z, ao_le
		cp		a, OP_GE
		jr		z, ao_ge
		cp		a, OP_EQ
		jr		z, ao_eq
		; OP_NE
		ld		a, [cmp_res]
		or		a, a
		jr		z, ao_zero
		jr		ao_one
ao_lt:
		ld		a, [cmp_res]
		cp		a, -1
		jr		z, ao_one
		jr		ao_zero
ao_gt:
		ld		a, [cmp_res]
		cp		a, 1
		jr		z, ao_one
		jr		ao_zero
ao_le:
		ld		a, [cmp_res]
		cp		a, 1
		jr		z, ao_zero
		jr		ao_one
ao_ge:
		ld		a, [cmp_res]
		cp		a, -1
		jr		z, ao_zero
		jr		ao_one
ao_eq:
		ld		a, [cmp_res]
		or		a, a
		jr		z, ao_one
ao_zero:
		ld		de, 0
		ld		hl, 0
		jp		ao_store
ao_one:
		ld		de, 0
		ld		hl, 1
		jp		ao_store
ao_add:
		call	add32
		jp		ao_ret_resv
ao_sub:
		call	sub32
		jp		ao_ret_resv
ao_mul:
		call	mul32
		jp		ao_ret_resv
ao_and:
		ld		hl, lv
		ld		de, rv
		ld		bc, resv
		ld		a, 4
		ld		[ao_cnt], a
ao_and_l:
		ld		a, [de]
		and		a, [hl]
		ld		[bc], a
		inc		hl
		inc		de
		inc		bc
		ld		a, [ao_cnt]
		dec		a
		ld		[ao_cnt], a
		jr		nz, ao_and_l
		jp		ao_ret_resv
ao_or:
		ld		hl, lv
		ld		de, rv
		ld		bc, resv
		ld		a, 4
		ld		[ao_cnt], a
ao_or_l:
		ld		a, [de]
		or		a, [hl]
		ld		[bc], a
		inc		hl
		inc		de
		inc		bc
		ld		a, [ao_cnt]
		dec		a
		ld		[ao_cnt], a
		jr		nz, ao_or_l
		jp		ao_ret_resv
ao_xor:
		ld		hl, lv
		ld		de, rv
		ld		bc, resv
		ld		a, 4
		ld		[ao_cnt], a
ao_xor_l:
		ld		a, [de]
		xor		a, [hl]
		ld		[bc], a
		inc		hl
		inc		de
		inc		bc
		ld		a, [ao_cnt]
		dec		a
		ld		[ao_cnt], a
		jr		nz, ao_xor_l
		jp		ao_ret_resv
shift_cnt:
		db		0
ao_shl:
		ld		a, [rv]
		and		a, 31
		ld		[shift_cnt], a
		or		a, a
		jr		z, ao_shr_zero		; result = lv (copy to resv)
		ld		b, a
ao_shl_l:
		call	shl32_1			; lv <<= 1
		djnz		ao_shl_l
		jp		ao_ret_lv_to_resv
ao_shr:
		ld		a, [rv]
		and		a, 31
		ld		[shift_cnt], a
		or		a, a
		jr		z, ao_shr_zero
		ld		b, a
ao_shr_l:
		call	shr32_1a			; lv >>= 1 arithmetic
		djnz		ao_shr_l
		jp		ao_ret_lv_to_resv
ao_shr_zero:
		ld		hl, lv
		ld		de, resv
		ld		bc, 4
		ldir
		jp		ao_ret_resv
ao_div:
		; signed divide: compute signs, unsigned divide on abs values
		call	div_prep_sign		; sets [div_neg_q], [div_neg_r]; lv,rv = abs
		call	divmod32u
		ld		a, [div_neg_q]
		or		a, a
		jp		z, ao_ret_resv
		ld		hl, resv
		call	neg_cell
		jp		ao_ret_resv
ao_mod:
		call	div_prep_sign
		call	divmod32u
		; result = remainder, sign = dividend sign ([div_neg_r])
		ld		hl, remv
		ld		de, resv
		ld		bc, 4
		ldir
		ld		a, [div_neg_r]
		or		a, a
		jp		z, ao_ret_resv
		ld		hl, resv
		call	neg_cell
		jp		ao_ret_resv
ao_land:
		ld		hl, lv
		call	is_zero32
		jp		z, ao_zero
		ld		hl, rv
		call	is_zero32
		jp		z, ao_zero
		jp		ao_one
ao_lor:
		ld		hl, lv
		call	is_zero32
		jp		nz, ao_one
		ld		hl, rv
		call	is_zero32
		jp		nz, ao_one
		jp		ao_zero
ao_ret_lv_to_resv:
		ld		hl, lv
		ld		de, resv
		ld		bc, 4
		ldir
ao_ret_resv:
		ld		hl, [resv]
		ld		de, [resv + 2]
		ret
ao_store:
		ld		[resv], hl
		ld		[resv + 2], de
		ret
ao_op:
		db		0
ao_cnt:
		db		0

;	ao_undef_prop: an operand is undefined -> undefined result (0).
;	Result type is string only for +/* with a string operand (cross rules).
ao_undef_prop:
		ld		a, [ao_op]
		cp		a, OP_ADD
		jr		z, ao_up_t
		cp		a, OP_MUL
		jr		nz, ao_up_int
ao_up_t:
		ld		a, [lv_type]
		ld		b, a
		ld		a, [rv_type]
		or		a, b
		jr		z, ao_up_int
		ld		a, 1
		ld		[resv_type], a
ao_up_int:
		ld		a, 1
		ld		[resv_undef], a
		ld		de, 0
		ld		hl, 0
		ret

;	ao_string: at least one operand is a (defined) string.
ao_string:
		ld		a, [ao_op]
		cp		a, OP_ADD
		jp		z, ao_concat
		cp		a, OP_MUL
		jp		z, ao_repeat
		cp		a, OP_EQ
		jp		z, ao_strcmp_op
		cp		a, OP_NE
		jp		z, ao_strcmp_op
		; any other operator on a string: illegal expression
		ld		a, 1
		ld		[expr_error], a
		ld		[expr_errkind], a
		ld		de, 0
		ld		hl, 0
		ret

ac_lena:
		dw		0
ac_lenb:
		dw		0
;	ao_concat: string-form(lv) ++ string-form(rv), interned
ao_concat:
		ld		hl, lv
		ld		a, [lv_type]
		ld		de, sbuf_a
		call	str_of_value	; BC = len A
		ld		[ac_lena], bc
		ld		hl, rv
		ld		a, [rv_type]
		ld		de, sbuf_b
		call	str_of_value	; BC = len B
		ld		[ac_lenb], bc
		ld		hl, [ac_lena]
		add		hl, bc			; total length
		ld		b, h
		ld		c, l
		call	intern_begin
		ld		hl, sbuf_a
		ld		bc, [ac_lena]
		call	intern_write
		ld		hl, sbuf_b
		ld		bc, [ac_lenb]
		call	intern_write
		ld		a, 1
		ld		[resv_type], a
		ld		hl, [intern_off]
		ld		de, [intern_off + 2]
		ret

ar_cnt:
		space	4
ar_patlen:
		dw		0
;	ao_repeat: string * count or count * string, interned
ao_repeat:
		ld		a, [lv_type]
		ld		b, a
		ld		a, [rv_type]
		and		a, b
		jp		nz, ao_str_illegal	; string * string
		ld		a, [lv_type]
		or		a, a
		jr		z, ao_rep_rstr
		; pattern = lv, count = rv
		ld		hl, lv
		ld		de, sbuf_a
		call	str_fetch		; BC = pattern length
		ld		hl, rv
		jr		ao_rep_have
ao_rep_rstr:
		; pattern = rv, count = lv
		ld		hl, rv
		ld		de, sbuf_a
		call	str_fetch
		ld		hl, lv
ao_rep_have:
		ld		[ar_patlen], bc
		; count cell (HL = count cell ptr) -> ar_cnt
		ld		de, ar_cnt
		ld		bc, 4
		ldir
		; negative or zero count -> empty string
		ld		a, [ar_cnt + 3]
		and		a, 0x80
		jr		nz, ao_rep_empty
		ld		hl, ar_cnt
		call	is_zero32
		jr		z, ao_rep_empty
		ld		hl, [ar_patlen]
		ld		a, h
		or		a, l
		jr		z, ao_rep_empty
		; total = patlen * count (via mul32 on lv/rv cells; the
		; original operands are already consumed into sbuf_a/ar_cnt)
		ld		hl, [ar_patlen]
		ld		[lv], hl
		xor		a, a
		ld		[lv + 2], a
		ld		[lv + 3], a
		ld		hl, ar_cnt
		ld		de, rv
		ld		bc, 4
		ldir
		call	mul32			; resv = total
		ld		a, [resv + 2]
		ld		b, a
		ld		a, [resv + 3]
		or		a, b
		jr		nz, ao_rep_huge
		ld		hl, [resv]
		ld		a, h
		cp		a, (STR_MAX >> 8) + 1
		jr		nc, ao_rep_huge		; total >= 1280
		cp		a, STR_MAX >> 8
		jr		c, ao_rep_totalok	; total < 1024
		ld		a, l
		or		a, a
		jr		nz, ao_rep_huge		; 1025..1279
ao_rep_totalok:
		ld		b, h
		ld		c, l			; BC = total length
		call	intern_begin
		; write pattern ar_cnt times (count fits: total <= STR_MAX
		; and patlen >= 1, so count <= STR_MAX)
		ld		hl, [ar_cnt]
		ld		[ac_lena], hl	; loop counter (16-bit is enough here)
ao_rep_wl:
		ld		hl, [ac_lena]
		ld		a, h
		or		a, l
		jr		z, ao_rep_done
		dec		hl
		ld		[ac_lena], hl
		ld		hl, sbuf_a
		ld		bc, [ar_patlen]
		call	intern_write
		jr		ao_rep_wl
ao_rep_done:
		ld		a, 1
		ld		[resv_type], a
		ld		hl, [intern_off]
		ld		de, [intern_off + 2]
		ret
ao_rep_empty:
		ld		bc, 0
		call	intern_begin
		jp		ao_rep_done
ao_rep_huge:
		ld		bc, 0xFFFF
		call	intern_begin	; raises the too-long error
		jp		ao_rep_done
ao_str_illegal:
		ld		a, 1
		ld		[expr_error], a
		ld		[expr_errkind], a
		ld		de, 0
		ld		hl, 0
		ret

sc_equal:
		db		0
;	ao_strcmp_op: == / != on strings (mixed types are never equal)
ao_strcmp_op:
		xor		a, a
		ld		[sc_equal], a
		ld		a, [lv_type]
		ld		b, a
		ld		a, [rv_type]
		cp		a, b
		jr		nz, asc_fin		; mixed -> not equal
		ld		hl, lv
		ld		de, rv
		call	str_cmp_cells
		jr		nz, asc_fin
		ld		a, 1
		ld		[sc_equal], a
asc_fin:
		ld		a, [ao_op]
		cp		a, OP_NE
		jr		z, asc_ne
		ld		a, [sc_equal]
		jr		asc_out
asc_ne:
		ld		a, [sc_equal]
		xor		a, 1
asc_out:
		ld		l, a
		ld		h, 0
		ld		de, 0
		ret

;	neg_cell: HL = ptr to 4-byte cell -> cell = -cell (in place)
neg_cell:
		ld		b, 4
		or		a, a
negc_l:
		ld		a, 0
		sbc		a, [hl]
		ld		[hl], a
		inc		hl
		djnz		negc_l
		ret

;	div_prep_sign: lv/rv -> abs values; div_neg_q = sign(lv)^sign(rv),
;	div_neg_r = sign(lv)
div_neg_q:
		db		0
div_neg_r:
		db		0
div_prep_sign:
		ld		a, [lv + 3]
		rlca
		ld		c, 0
		jr		nc, dps_lpos
		ld		c, 1
		ld		hl, lv
		call	neg_cell
dps_lpos:
		ld		a, c
		ld		[div_neg_r], a
		ld		a, [rv + 3]
		rlca
		ld		b, 0
		jr		nc, dps_rpos
		ld		b, 1
		ld		hl, rv
		call	neg_cell
dps_rpos:
		ld		a, b
		xor		a, c
		ld		[div_neg_q], a
		ret

; ---- parser ----------------------------------------------------------------

;	ev_skip_spaces: advance ev_ptr past spaces/tabs
ev_skip_spaces:
		ld		hl, [ev_ptr]
ess_l:
		ld		a, [hl]
		cp		a, ' '
		jr		z, ess_1
		cp		a, 9
		jr		nz, ess_done
ess_1:
		inc		hl
		jr		ess_l
ess_done:
		ld		[ev_ptr], hl
		ret

;	peek_binop: at ev_ptr (spaces already skipped).
;	-> A = op id (0 = none), B = char length, C = precedence
pb_c0:
		db		0
pb_c1:
		db		0
peek_binop:
		ld		hl, [ev_ptr]
		ld		a, [hl]
		ld		[pb_c0], a
		inc		hl
		ld		a, [hl]
		ld		[pb_c1], a
		; two-char operators first
		ld		a, [pb_c0]
		cp		a, '<'
		jr		nz, pb_2
		ld		a, [pb_c1]
		cp		a, '<'
		jr		z, pb_op_shl
		cp		a, '='
		jr		z, pb_op_le
		jr		pb_lt
pb_2:
		cp		a, '>'
		jr		nz, pb_3
		ld		a, [pb_c1]
		cp		a, '>'
		jr		z, pb_op_shr
		cp		a, '='
		jr		z, pb_op_ge
		jr		pb_gt
pb_3:
		cp		a, '='
		jr		nz, pb_4
		ld		a, [pb_c1]
		cp		a, '='
		jr		z, pb_op_eq
		jr		pb_none
pb_4:
		cp		a, '!'
		jr		nz, pb_5
		ld		a, [pb_c1]
		cp		a, '='
		jr		z, pb_op_ne
		jr		pb_none
pb_5:
		cp		a, '&'
		jr		nz, pb_6
		ld		a, [pb_c1]
		cp		a, '&'
		jr		z, pb_op_land
		jr		pb_and
pb_6:
		cp		a, '|'
		jr		nz, pb_7
		ld		a, [pb_c1]
		cp		a, '|'
		jr		z, pb_op_lor
		jr		pb_or
pb_7:
		cp		a, '*'
		jr		z, pb_mul
		cp		a, '/'
		jr		z, pb_div
		cp		a, '%'
		jr		z, pb_mod
		cp		a, '+'
		jr		z, pb_add
		cp		a, '-'
		jr		z, pb_sub
		cp		a, '^'
		jr		z, pb_xor
pb_none:
		xor		a, a
		ret
pb_op_shl:
		ld		a, OP_SHL
		ld		b, 2
		ld		c, 16
		ret
pb_op_shr:
		ld		a, OP_SHR
		ld		b, 2
		ld		c, 16
		ret
pb_op_le:
		ld		a, OP_LE
		ld		b, 2
		ld		c, 15
		ret
pb_lt:
		ld		a, OP_LT
		ld		b, 1
		ld		c, 15
		ret
pb_op_ge:
		ld		a, OP_GE
		ld		b, 2
		ld		c, 15
		ret
pb_gt:
		ld		a, OP_GT
		ld		b, 1
		ld		c, 15
		ret
pb_op_eq:
		ld		a, OP_EQ
		ld		b, 2
		ld		c, 14
		ret
pb_op_ne:
		ld		a, OP_NE
		ld		b, 2
		ld		c, 14
		ret
pb_op_land:
		ld		a, OP_LAND
		ld		b, 2
		ld		c, 10
		ret
pb_and:
		ld		a, OP_AND
		ld		b, 1
		ld		c, 13
		ret
pb_op_lor:
		ld		a, OP_LOR
		ld		b, 2
		ld		c, 9
		ret
pb_or:
		ld		a, OP_OR
		ld		b, 1
		ld		c, 11
		ret
pb_xor:
		ld		a, OP_XOR
		ld		b, 1
		ld		c, 12
		ret
pb_mul:
		ld		a, OP_MUL
		ld		b, 1
		ld		c, 18
		ret
pb_div:
		ld		a, OP_DIV
		ld		b, 1
		ld		c, 18
		ret
pb_mod:
		ld		a, OP_MOD
		ld		b, 1
		ld		c, 18
		ret
pb_add:
		ld		a, OP_ADD
		ld		b, 1
		ld		c, 17
		ret
pb_sub:
		ld		a, OP_SUB
		ld		b, 1
		ld		c, 17
		ret

;	parse_expr: A = min_prec -> DE:HL = value
;	IX frame: [ix-1] = min_prec; left value bytes: L@[ix-4], H@[ix-3],
;	E@[ix-6], D@[ix-5]
parse_expr:
		push	ix
		ld		ix, 0
		add		ix, sp
		push	af				; min_prec -> [ix-1] (A of pushed AF)
		call	parse_unary		; DE:HL
		push	hl
		push	de			; left value on frame
		ld		a, [val_undef]
		push	af				; [ix-7] = left undef flag
		ld		a, [val_type]
		push	af				; [ix-9] = left type
pe_loop:
		call	ev_skip_spaces
		call	peek_binop		; A=id, B=len, C=prec
		or		a, a
		jr		z, pe_done
		ld		[pe_opid], a
		ld		a, [ix - 1]		; min_prec
		cp		a, c
		jr		z, pe_take		; equal prec: take (left assoc via prec+1)
		jr		nc, pe_done		; min_prec > op prec -> stop
pe_take:
		; consume operator chars (B = length, still valid)
		ld		hl, [ev_ptr]
		ld		e, b
		ld		d, 0
		add		hl, de
		ld		[ev_ptr], hl
		ld		a, [pe_opid]
		push	af
		ld		a, c
		inc		a				; right side min_prec = prec + 1
		call	parse_expr		; DE:HL = right
		ld		[rv], hl
		ld		[rv + 2], de
		ld		a, [val_type]
		ld		[rv_type], a
		ld		a, [val_undef]
		ld		[rv_undef], a
		pop		af				; op id
		push	af				; keep it across the flag loads below
		; load left from frame into lv
		ld		l, [ix - 4]
		ld		h, [ix - 3]
		ld		[lv], hl
		ld		l, [ix - 6]
		ld		h, [ix - 5]
		ld		[lv + 2], hl
		ld		a, [ix - 9]
		ld		[lv_type], a
		ld		a, [ix - 7]
		ld		[lv_undef], a
		pop		af				; op id restored
		call	apply_op		; DE:HL = result (lv op rv)
		; store back to frame left
		ld		[ix - 4], l
		ld		[ix - 3], h
		ld		[ix - 6], e
		ld		[ix - 5], d
		ld		a, [resv_type]
		ld		[ix - 9], a
		ld		a, [resv_undef]
		ld		[ix - 7], a
		jr		pe_loop
pe_done:
		ld		a, [ix - 9]
		ld		[val_type], a
		ld		a, [ix - 7]
		ld		[val_undef], a
		ld		l, [ix - 4]
		ld		h, [ix - 3]
		ld		e, [ix - 6]
		ld		d, [ix - 5]
		ld		sp, ix
		pop		ix
		ret
pe_opid:
		db		0

;	parse_unary -> DE:HL
parse_unary:
		call	ev_skip_spaces
		ld		hl, [ev_ptr]
		ld		a, [hl]
		cp		a, '-'
		jr		z, pu_neg
		cp		a, '+'
		jr		z, pu_plus
		cp		a, '!'
		jr		z, pu_not
		cp		a, '~'
		jr		z, pu_inv
		jp		parse_primary
pu_neg:
		inc		hl
		ld		[ev_ptr], hl
		call	parse_unary
		call	pu_chk_str
		; negate DE:HL
		ld		a, l
		cpl
		ld		l, a
		ld		a, h
		cpl
		ld		h, a
		ld		a, e
		cpl
		ld		e, a
		ld		a, d
		cpl
		ld		d, a
		ld		bc, 1
		add		hl, bc			; +1 low (BC=1: careful: add hl,bc adds 1)
		ret		nc
		inc		de
		ret
pu_plus:
		inc		hl
		ld		[ev_ptr], hl
		call	parse_unary
		call	pu_chk_str
		ret
;	pu_chk_str: unary operator applied to a string -> illegal expression
pu_chk_str:
		ld		a, [val_type]
		or		a, a
		ret		z
		ld		a, 1
		ld		[expr_error], a
		ld		[expr_errkind], a
		xor		a, a
		ld		[val_type], a
		ld		[val_undef], a
		ld		de, 0
		ld		hl, 0
		ret
pu_not:
		inc		hl
		ld		[ev_ptr], hl
		call	parse_unary
		call	pu_chk_str
		ld		a, l
		or		a, h
		or		a, e
		or		a, d
		ld		de, 0
		ld		hl, 1
		ret		z
		ld		hl, 0
		ret
pu_inv:
		inc		hl
		ld		[ev_ptr], hl
		call	parse_unary
		call	pu_chk_str
		ld		a, l
		cpl
		ld		l, a
		ld		a, h
		cpl
		ld		h, a
		ld		a, e
		cpl
		ld		e, a
		ld		a, d
		cpl
		ld		d, a
		ret

;	parse_primary -> DE:HL
parse_primary:
		xor		a, a
		ld		[val_type], a
		ld		[val_undef], a
		call	ev_skip_spaces
		ld		hl, [ev_ptr]
		ld		a, [hl]
		cp		a, '"'
		jp		z, pp_string
		cp		a, '('
		jr		z, pp_paren
		cp		a, '$'
		jp		z, pp_dollar
		cp		a, 0x27			; ' char literal
		jp		z, pp_char
		cp		a, '0'
		jr		c, pp_notnum
		cp		a, '9' + 1
		jp		c, pp_number
pp_notnum:
		; identifier?
		call	is_ident_start
		jp		c, pp_ident
		; unknown char -> error, value 0, advance 1 to avoid infinite loop
		ld		a, 1
		ld		[expr_error], a
		inc		hl
		ld		[ev_ptr], hl
		ld		de, 0
		ld		hl, 0
		ret
pp_string:
		; string literal: reuse parse_string_lp on ev_ptr (via lp)
		ld		hl, [lp]
		push	hl
		ld		hl, [ev_ptr]
		ld		[lp], hl
		call	parse_string_lp
		ld		hl, [lp]
		ld		[ev_ptr], hl
		pop		hl
		ld		[lp], hl
		jr		nc, pp_str_ok
		ld		a, 1
		ld		[expr_error], a
		ld		de, 0
		ld		hl, 0
		ret
pp_str_ok:
		call	cs_map_strbuf	; P4: character-set conversion
		ld		hl, str_buf
		ld		bc, [str_len]
		call	str_intern		; DE:HL = pool offset
		ld		a, 1
		ld		[val_type], a
		ret
pp_paren:
		inc		hl
		ld		[ev_ptr], hl
		xor		a, a			; min_prec = 0
		call	parse_expr
		push	de
		push	hl
		call	ev_skip_spaces
		ld		hl, [ev_ptr]
		ld		a, [hl]
		cp		a, ')'
		jr		nz, pp_paren_err
		inc		hl
		ld		[ev_ptr], hl
		pop		hl
		pop		de
		ret
pp_paren_err:
		ld		a, 1
		ld		[expr_error], a
		pop		hl
		pop		de
		ret
pp_dollar:
		; '$' : $$ = file offset; $+hexdigit = hex number; else code address
		inc		hl
		ld		a, [hl]
		cp		a, '$'
		jr		z, pp_fileoff
		call	is_hex_digit
		jr		c, pp_hexnum		; HL points at first hex digit
		; plain $ = line start PC
		ld		[ev_ptr], hl
		ld		hl, [line_start_pc]
		ld		de, [line_start_pc + 2]
		ret
pp_fileoff:
		inc		hl
		ld		[ev_ptr], hl
		ld		hl, [line_start_fileoff]
		ld		de, [line_start_fileoff + 2]
		ret
pp_hexnum:
		; parse hex digits at HL
		ld		de, 0
		ld		[pp_hv], de
		ld		[pp_hv + 2], de
pp_hl:
		ld		a, [hl]
		cp		a, '_'
		jr		z, pp_hskip
		call	hex_digit_val	; A = val, CY if hex digit
		jr		nc, pp_hdone
		push	hl
		ld		hl, [pp_hv]
		ld		de, [pp_hv + 2]
		add		hl, hl
		rl		e
		rl		d
		add		hl, hl
		rl		e
		rl		d
		add		hl, hl
		rl		e
		rl		d
		add		hl, hl
		rl		e
		rl		d
		or		a, l
		ld		l, a
		ld		[pp_hv], hl
		ld		[pp_hv + 2], de
		pop		hl
pp_hskip:
		inc		hl
		jr		pp_hl
pp_hdone:
		ld		[ev_ptr], hl
		ld		hl, [pp_hv]
		ld		de, [pp_hv + 2]
		ret
pp_hv:
		space	4
pp_char:
		; 'x' char literal: value = char code (single byte; multi-byte
		; packed little-endian up to 4 bytes)
		inc		hl				; past '
		ld		de, 0
		ld		[pp_hv], de
		ld		[pp_hv + 2], de
		ld		b, 0			; byte count
pp_cl:
		ld		a, [hl]
		cp		a, 0x27
		jr		z, pp_cdone
		or		a, a
		jr		z, pp_cerr
		cp		a, 0x5C			; backslash escape
		jr		nz, pp_cst
		inc		hl
		ld		a, [hl]
		or		a, a
		jr		z, pp_cerr
		call	esc_char
pp_cst:
		; store byte at position B in pp_hv
		push	hl
		push	bc
		ld		hl, pp_hv
		ld		c, b
		ld		b, 0
		add		hl, bc
		ld		[hl], a
		pop		bc
		pop		hl
		inc		hl
		inc		b
		ld		a, b
		cp		a, 4
		jr		c, pp_cl
		; too many chars: keep consuming until '
pp_cskip:
		ld		a, [hl]
		cp		a, 0x27
		jr		z, pp_cdone
		or		a, a
		jr		z, pp_cerr
		inc		hl
		jr		pp_cskip
pp_cdone:
		push	hl
		call	cs_map_char		; P4: character-set conversion
		pop		hl
		inc		hl				; past closing '
		ld		[ev_ptr], hl
		ld		hl, [pp_hv]
		ld		de, [pp_hv + 2]
		ret
pp_cerr:
		ld		a, 1
		ld		[expr_error], a
		ld		[ev_ptr], hl
		ld		de, 0
		ld		hl, 0
		ret
pp_number:
		jp		parse_number
pp_ident:
		; copy identifier (upcased) into name_src_buf
		ld		de, name_src_buf
		ld		b, 0
pp_idl:
		ld		a, [hl]
		call	is_ident_char
		jr		nc, pp_iddone
		call	upcase
		ld		c, a
		ld		a, b
		cp		a, 63
		jr		nc, pp_idskip	; too long: consume but don't store
		ld		a, c
		ld		[de], a
		inc		de
		inc		b
pp_idskip:
		inc		hl
		jr		pp_idl
pp_iddone:
		xor		a, a
		ld		[de], a
		ld		[ev_ptr], hl
		; keyword constants
		ld		hl, name_src_buf
		ld		de, kw_code_addr
		call	str_eq
		jr		z, pp_kw_pc
		ld		hl, name_src_buf
		ld		de, kw_file_addr
		call	str_eq
		jr		z, pp_kw_fo
		ld		hl, name_src_buf
		ld		de, kw_charset
		call	str_eq
		jr		z, pp_kw_cs
		; symbol lookup (scoped)
		call	sym_lookup_scoped	; val_tmp + flags in A
		bit		0, a
		jr		nz, pp_sym_ok
		ld		a, 1
		ld		[expr_undef], a
		ld		[val_undef], a
		ld		de, 0
		ld		hl, 0
		ret
pp_sym_ok:
		and		a, SYM_F_STRING
		jr		z, pp_sym_int
		ld		a, 1
		ld		[val_type], a
pp_sym_int:
		ld		hl, [val_tmp]
		ld		de, [val_tmp + 2]
		ret
pp_kw_cs:
		ld		a, 1
		ld		[val_type], a
		ld		hl, [cs_name_off]
		ld		de, [cs_name_off + 2]
		ret
pp_kw_pc:
		ld		hl, [line_start_pc]
		ld		de, [line_start_pc + 2]
		ret
pp_kw_fo:
		ld		hl, [line_start_fileoff]
		ld		de, [line_start_fileoff + 2]
		ret
kw_code_addr:
		db		"CODE_ADDRESS", 0
kw_file_addr:
		db		"FILE_ADDRESS", 0
kw_charset:
		db		"CHAR_SET_NAME", 0

;	str_eq: HL, DE = NUL-terminated strings -> Z if equal
str_eq:
		ld		a, [de]
		cp		a, [hl]
		ret		nz
		or		a, a
		ret		z
		inc		hl
		inc		de
		jr		str_eq

;	is_ident_start: A = char -> CY if [A-Za-z_@?]
is_ident_start:
		cp		a, 'A'
		jr		c, iis_1
		cp		a, 'Z' + 1
		jr		c, iis_yes
iis_1:
		cp		a, 'a'
		jr		c, iis_2
		cp		a, 'z' + 1
		jr		c, iis_yes
iis_2:
		cp		a, '_'
		jr		z, iis_yes
		cp		a, '@'
		jr		z, iis_yes
		cp		a, '?'
		jr		z, iis_yes
		or		a, a			; CY clear
		ret
iis_yes:
		scf
		ret

;	is_ident_char: A = char -> CY if ident char (start chars + digits)
is_ident_char:
		cp		a, '0'
		jr		c, is_ident_start
		cp		a, '9' + 1
		jr		c, iis_yes
		jr		is_ident_start

;	is_hex_digit: A = char -> CY if hex digit
is_hex_digit:
		cp		a, '0'
		jr		c, ihd_no
		cp		a, '9' + 1
		jr		c, iis_yes
		cp		a, 'A'
		jr		c, ihd_no
		cp		a, 'F' + 1
		jr		c, iis_yes
		cp		a, 'a'
		jr		c, ihd_no
		cp		a, 'f' + 1
		jr		c, iis_yes
ihd_no:
		or		a, a
		ret

;	hex_digit_val: A = char -> A = 0..15, CY if not hex
hex_digit_val:
		cp		a, '0'
		jr		c, ihd_no
		cp		a, '9' + 1
		jr		c, hdv_09
		cp		a, 'A'
		jr		c, ihd_no
		cp		a, 'F' + 1
		jr		c, hdv_af
		cp		a, 'a'
		jr		c, ihd_no
		cp		a, 'f' + 1
		jr		nc, ihd_no
		sub		a, 'a' - 10
		scf
		ret
hdv_09:
		sub		a, '0'
		scf
		ret
hdv_af:
		sub		a, 'A' - 10
		scf
		ret

;	parse_number: ev_ptr at first digit -> DE:HL = value
;	formats: 0x.. hex, 0b.. binary, 0.. octal (leading 0), ..h hex suffix,
;	decimal. '_' separators ignored.
pn_buf:
		space	36
parse_number:
		ld		hl, [ev_ptr]
		; 0x / 0b prefix?
		ld		a, [hl]
		cp		a, '0'
		jr		nz, pn_collect
		inc		hl
		ld		a, [hl]
		cp		a, 'x'
		jp		z, pn_hex_pfx
		cp		a, 'X'
		jp		z, pn_hex_pfx
		cp		a, 'b'
		jp		z, pn_bin_pfx
		cp		a, 'B'
		jp		z, pn_bin_pfx
		dec		hl				; back to '0'
pn_collect:
		; collect run of [0-9A-Za-z_] into pn_buf
		ld		de, pn_buf
		ld		b, 0
pn_cl:
		ld		a, [hl]
		call	is_alnum_us
		jr		nc, pn_cd
		ld		c, a
		ld		a, b
		cp		a, 34
		jr		nc, pn_cs
		ld		a, c
		ld		[de], a
		inc		de
		inc		b
pn_cs:
		inc		hl
		jr		pn_cl
pn_cd:
		xor		a, a
		ld		[de], a
		ld		[ev_ptr], hl
		; trailing H/h + all-hex -> hex
		ld		a, b
		or		a, a
		jp		z, pn_err
		dec		de				; last char
		ld		a, [de]
		cp		a, 'H'
		jr		z, pn_sfxh
		cp		a, 'h'
		jr		z, pn_sfxh
		; leading 0 and all digits and length>1 -> octal (if digits <=7)
		ld		a, [pn_buf]
		cp		a, '0'
		jr		nz, pn_dec
		ld		a, b
		cp		a, 2
		jr		c, pn_dec
		; check all digits are 0-7
		push	bc
		ld		hl, pn_buf
		ld		b, 0			; B = "has 8/9" flag via C? use C
		ld		c, 0
pn_ock:
		ld		a, [hl]
		or		a, a
		jr		z, pn_ockd
		cp		a, '_'
		jr		z, pn_ockn
		cp		a, '0'
		jr		c, pn_ockbad
		cp		a, '9' + 1
		jr		c, pn_ockd2
		cp		a, '8'
		jr		nc, pn_ock89
		jr		pn_ockn
pn_ockd2:
		cp		a, '8'
		jr		c, pn_ockn
pn_ock89:
		ld		c, 1
		jr		pn_ockn
pn_ockbad:
		pop		bc
		jr		pn_err
pn_ockn:
		inc		hl
		jr		pn_ock
pn_ockd:
		ld		a, c			; flag: set if any 8/9 seen (keep before pop:
		ld		[pn_dig], a		; pop bc would restore a stale C)
		pop		bc
		ld		a, [pn_dig]
		or		a, a
		jr		nz, pn_dec		; contains 8/9 -> decimal
		ld		a, 8
		ld		hl, pn_buf
		jp		pn_eval_radix
pn_sfxh:
		xor		a, a
		ld		[de], a			; strip H
		ld		a, 16
		ld		hl, pn_buf
		jp		pn_eval_radix
pn_dec:
		ld		a, 10
		ld		hl, pn_buf
		jp		pn_eval_radix
pn_hex_pfx:
		inc		hl				; past x
		ld		[ev_ptr], hl
		jp		pp_hexnum_body
pn_bin_pfx:
		inc		hl
		ld		[ev_ptr], hl
		ld		de, 0
		ld		[pp_hv], de
		ld		[pp_hv + 2], de
pn_bl:
		ld		a, [hl]
		cp		a, '_'
		jr		z, pn_bskip
		cp		a, '0'
		jr		c, pn_bdone
		cp		a, '1' + 1
		jr		nc, pn_bdone
		sub		a, '0'
		push	hl
		push	af
		ld		hl, [pp_hv]
		ld		de, [pp_hv + 2]
		add		hl, hl
		rl		e
		rl		d
		pop		af
		or		a, l
		ld		l, a
		ld		[pp_hv], hl
		ld		[pp_hv + 2], de
		pop		hl
pn_bskip:
		inc		hl
		jr		pn_bl
pn_bdone:
		ld		[ev_ptr], hl
		ld		hl, [pp_hv]
		ld		de, [pp_hv + 2]
		ret
pn_err:
		ld		a, 1
		ld		[expr_error], a
		ld		de, 0
		ld		hl, 0
		ret

;	pp_hexnum_body: ev_ptr at hex digits -> DE:HL (shared with $hex path
;	by setting HL first); entry: HL = ptr
pp_hexnum_body:
		ld		de, 0
		ld		[pp_hv], de
		ld		[pp_hv + 2], de
		jp		pp_hl

;	pn_eval_radix: A = radix, HL = digit string (NUL-term) -> DE:HL value
pn_eval_radix:
		ld		[pn_radix], a
		ld		de, 0
		ld		[pp_hv], de
		ld		[pp_hv + 2], de
pn_ev_l:
		ld		a, [hl]
		or		a, a
		jr		z, pn_ev_done
		inc		hl
		cp		a, '_'
		jr		z, pn_ev_l
		push	hl
		call	hex_digit_val	; A = digit value
		jr		nc, pn_ev_bad
		ld		[pn_dig], a
		; value = value * radix + digit
		ld		a, [pn_radix]
		ld		b, a
		ld		hl, [pp_hv]
		ld		de, [pp_hv + 2]
		ld		[pn_acc], hl
		ld		[pn_acc + 2], de
		xor		a, a
		ld		[pp_hv], a
		ld		[pp_hv + 1], a
		ld		[pp_hv + 2], a
		ld		[pp_hv + 3], a
pn_mul_l:
		push	bc
		ld		hl, pn_acc
		ld		de, pp_hv
		ld		b, 4
		or		a, a
pn_mul_b:
		ld		a, [de]
		adc		a, [hl]
		ld		[de], a
		inc		hl
		inc		de
		djnz		pn_mul_b
		pop		bc
		djnz		pn_mul_l
		ld		a, [pn_dig]
		ld		c, a
		ld		a, [pp_hv]
		add		a, c
		ld		[pp_hv], a
		jr		nc, pn_ev_nc
		ld		hl, pp_hv + 1
		inc		[hl]
		jr		nz, pn_ev_nc
		inc		hl
		inc		[hl]
		jr		nz, pn_ev_nc
		inc		hl
		inc		[hl]
pn_ev_nc:
		pop		hl
		jr		pn_ev_l
pn_ev_done:
		ld		hl, [pp_hv]
		ld		de, [pp_hv + 2]
		ret
pn_ev_bad:
		pop		hl
		jp		pn_err
pn_radix:
		db		0
pn_dig:
		db		0
pn_acc:
		space	4

;	is_alnum_us: A -> CY if [0-9A-Za-z_]
is_alnum_us:
		cp		a, '0'
		jr		c, iau_1
		cp		a, '9' + 1
		jp		c, iis_yes
iau_1:
		cp		a, 'A'
		jr		c, iau_2
		cp		a, 'Z' + 1
		jp		c, iis_yes
iau_2:
		cp		a, 'a'
		jr		c, iau_3
		cp		a, 'z' + 1
		jp		c, iis_yes
iau_3:
		cp		a, '_'
		jp		z, iis_yes
		or		a, a
		ret

;	expr_eval_cstr: HL = C string -> DE:HL value; expr_undef/expr_error set
expr_eval_cstr:
		xor		a, a
		ld		[expr_undef], a
		ld		[expr_error], a
		ld		[expr_errkind], a
		ld		[val_type], a
		ld		[val_undef], a
		ld		[ev_ptr], hl
		xor		a, a
		call	parse_expr
		ret

;	expr_eval_line: evaluate expression at ev_ptr (already positioned);
;	clears undef/error first. -> DE:HL
expr_eval:
		xor		a, a
		ld		[expr_undef], a
		ld		[expr_error], a
		ld		[expr_errkind], a
		ld		[val_type], a
		ld		[val_undef], a
		call	parse_expr
		ret

; =============================================================================
;	zma.log / zma.sym writers.  Since the author ruling of
;	2026-11-13 (DESIGN.md section 7 item 8) the DOS2 zma.log
;	is the ABBREVIATED form -- an intentional divergence
;	from cross ZMA's full log.  Contents are only:
;	(1) for each line that raised an error, its line number
;	and content (the source line, then the error record);
;	(2) the defined-symbol list (the << label >> section).
;	No header block, no per-line listing, no byte dumps, no
;	definition info lines, no << character map >> section.
;	zma.sym is unchanged.
; =============================================================================
lw_handle:
		db		0xFF
lw_buf:
		space	256
lw_len:
		dw		0
lw_name_log:
		db		"ZMA.LOG", 0
lw_name_sym:
		db		"ZMA.SYM", 0

;	lw_open: HL = filename -> CY on error
lw_open:
		call	dos_create
		ret		c
		ld		[lw_handle], a
		xor		a, a
		ld		[lw_len], a
		ld		[lw_len + 1], a
		ret
lw_flush:
		ld		hl, [lw_len]
		ld		a, h
		or		a, l
		ret		z
		ex		de, hl
		ld		hl, lw_buf
		ld		a, [lw_handle]
		call	dos_write
		xor		a, a
		ld		[lw_len], a
		ld		[lw_len + 1], a
		ret
lw_close:
		ld		a, [lw_handle]
		cp		a, 0xFF
		ret		z
		call	lw_flush
		ld		a, [lw_handle]
		call	dos_close
		ld		a, 0xFF
		ld		[lw_handle], a
		ret
;	lw_putc: A = char
lw_putc:
		push	hl
		push	de
		push	bc
		ld		hl, [lw_len]
		ld		de, lw_buf
		add		hl, de
		ld		[hl], a
		ld		hl, [lw_len]
		inc		hl
		ld		[lw_len], hl
		ld		a, h
		cp		a, 1			; 256 bytes buffered?
		jr		nz, lwp_ok
		ld		a, l
		or		a, a
		jr		nz, lwp_ok
		call	lw_flush
lwp_ok:
		pop		bc
		pop		de
		pop		hl
		ret
;	lw_puts: HL = NUL-terminated string
lw_puts:
		ld		a, [hl]
		or		a, a
		ret		z
		inc		hl
		push	hl
		call	lw_putc
		pop		hl
		jr		lw_puts
;	lw_write: HL = ptr, BC = length
lw_write:
		ld		a, b
		or		a, c
		ret		z
		ld		a, [hl]
		inc		hl
		dec		bc
		push	hl
		push	bc
		call	lw_putc
		pop		bc
		pop		hl
		jr		lw_write
;	lw_nl: newline (CRLF, the MSX-DOS convention; post-
;	completion fix 2026-11-14: LF-only line endings made
;	TYPE ZMA.LOG display without carriage returns)
lw_nl:
		ld		a, 13
		call	lw_putc
		ld		a, 10
		jp		lw_putc

;	lw_dec6: HL = 16-bit value -> decimal, right-aligned in 6 columns
lw_dec6:
		ld		[lwn_cell], hl
		xor		a, a
		ld		[lwn_cell + 2], a
		ld		[lwn_cell + 3], a
		ld		hl, lwn_cell
		ld		de, sbuf_a
		call	dec32_to_buf	; BC = length
		; pad spaces to 6
		ld		a, 6
		sub		a, c
		jr		z, lw_d6w
		jr		c, lw_d6w
		ld		b, a
lw_d6p:
		ld		a, ' '
		push	bc
		call	lw_putc
		pop		bc
		djnz	lw_d6p
lw_d6w:
		ld		hl, sbuf_a
		jp		lw_write
;	lw_dec: HL = 16-bit value -> decimal, no padding
lw_dec:
		ld		[lwn_cell], hl
		xor		a, a
		ld		[lwn_cell + 2], a
		ld		[lwn_cell + 3], a
		ld		hl, lwn_cell
		ld		de, sbuf_a
		call	dec32_to_buf
		ld		hl, sbuf_a
		jp		lw_write
lwn_cell:
		space	4

;	lw_hex2: A = byte -> 2 uppercase hex digits
lw_hex2:
		push	af
		rrca
		rrca
		rrca
		rrca
		call	lw_nib_up
		pop		af
		jp		lw_nib_up
lw_nib_up:
		and		a, 0x0F
		cp		a, 10
		jr		c, lwn_09
		add		a, 'A' - 10
		jp		lw_putc
lwn_09:
		add		a, '0'
		jp		lw_putc
;	lw_hex4: HL = value -> 4 uppercase hex digits
lw_hex4:
		ld		a, h
		call	lw_hex2
		ld		a, l
		jp		lw_hex2
;	lw_hex6: HL = ptr to 4-byte cell -> 6 uppercase hex digits (low 24)
lw_hex6:
		inc		hl
		inc		hl				; byte 2
		ld		a, [hl]
		call	lw_hex2
		dec		hl
		ld		a, [hl]
		call	lw_hex2
		dec		hl
		ld		a, [hl]
		jp		lw_hex2
;	lw_hexl: HL = ptr to 4-byte cell -> lowercase hex, minimal digits
lw_hexl:
		ld		[lhl_base], hl
		xor		a, a
		ld		[lhl_n], a
		ld		[lhl_started], a
lhl_l:
		ld		a, [lhl_n]
		cp		a, 8
		jr		z, lhl_end
		srl		a					; byte index from the top = i>>1
		ld		e, a
		ld		a, 3
		sub		a, e				; cell offset (LE)
		ld		e, a
		ld		d, 0
		ld		hl, [lhl_base]
		add		hl, de
		ld		d, [hl]				; the byte
		ld		a, [lhl_n]
		and		a, 1
		jr		nz, lhl_low
		ld		a, d
		rrca
		rrca
		rrca
		rrca
		jr		lhl_got
lhl_low:
		ld		a, d
lhl_got:
		and		a, 0x0F
		jr		nz, lhl_pr
		ld		e, a				; remember the zero digit
		ld		a, [lhl_started]
		or		a, a
		jr		z, lhl_skip
		ld		a, e
lhl_pr:
		ld		e, a
		ld		a, 1
		ld		[lhl_started], a
		ld		a, e
		push	de
		call	lw_nib_lo_a
		pop		de
lhl_skip:
		ld		a, [lhl_n]
		inc		a
		ld		[lhl_n], a
		jr		lhl_l
lhl_end:
		ld		a, [lhl_started]
		or		a, a
		ret		nz
		ld		a, '0'
		jp		lw_putc
lhl_n:
		db		0
lhl_started:
		db		0
lhl_base:
		dw		0

;	lw_hex6l: HL = ptr to 4-byte cell -> 6 lowercase hex digits (low 24)
lw_hex6l:
		inc		hl
		inc		hl
		ld		a, [hl]
		call	lw_hex2l
		dec		hl
		ld		a, [hl]
		call	lw_hex2l
		dec		hl
		ld		a, [hl]
		jp		lw_hex2l
lw_hex2l:
		push	af
		rrca
		rrca
		rrca
		rrca
		call	lw_nib_lo_a
		pop		af
		jp		lw_nib_lo_a
;	lw_nib_lo: A = nibble (0..15) -> lowercase hex digit
lw_nib_lo:
		cp		a, 10
		jr		c, lnl_09
		add		a, 'a' - 10
		jp		lw_putc
lnl_09:
		add		a, '0'
		jp		lw_putc
lw_nib_lo_a:
		and		a, 0x0F
		jp		lw_nib_lo

; ---------------------------------------------------------------------------
;	Log state + per-line machinery
; ---------------------------------------------------------------------------
log_active:
		db		0
log_src_shown:
		db		0			; this line's source text already logged
log_info_kind:
		db		0			; written by log_set_info_* (kept;
						; no reader since the abbreviated log)
log_info_name:
		space	64
log_info_val:
		space	4

s_log_labelsec:
		db		"<< label >>", 13, 10, 0

;	log_open_write_header: create ZMA.LOG and mark the log
;	active.  The abbreviated log has no header block.
log_open_write_header:
		ld		hl, lw_name_log
		call	lw_open
		jr		c, loh_fail
		ld		a, 1
		ld		[log_active], a
		ret
loh_fail:
		xor		a, a
		ld		[log_active], a
		ret

;	log_line_begin: per-line setup for the abbreviated log.
;	Nothing is written per line; only the flag that tracks
;	whether this line's source text has been logged (on its
;	first error) is cleared.
log_line_begin:
		xor		a, a
		ld		[log_src_shown], a
		ret

;	log_line_end: no per-line log output anymore.
log_line_end:
		ret

;	log_capture: byte dumps are not part of the abbreviated
;	log.  Kept as a no-op (emit8 calls it for every byte).
log_capture:
		ret

;	lw_src_line: write the current source line once per line,
;	"<line6>|      |    |<raw text>".  Called from the
;	error-line writers before the error record itself.
;	line_buf holds exactly this line's text whenever a
;	log-reaching error fires (inside process_line).
lw_src_line:
		ld		a, [log_src_shown]
		or		a, a
		ret		nz
		ld		a, 1
		ld		[log_src_shown], a
		ld		hl, [cur_ent]
		ld		de, E_LINE
		add		hl, de
		ld		e, [hl]
		inc		hl
		ld		d, [hl]
		ex		de, hl
		call	lw_dec6
		ld		a, '|'
		call	lw_putc
		ld		hl, s_log_mainline
		call	lw_puts			; "      |    |"
		ld		hl, line_buf
		ld		a, [line_len]
		ld		c, a
		ld		b, 0
		call	lw_write
		jp		lw_nl
s_log_mainline:
		db		"      |    |", 0

;	lw_error_line: HL = NUL-terminated message -> cross log error line
;	"<line6>|ERROR |    |<msg>: <file>(<line>)"
lw_error_line:
		ld		a, [log_active]
		or		a, a
		ret		z
		push	hl
		call	lw_src_line	; source line first (abbreviated log)
		ld		hl, [cur_ent]
		ld		de, E_LINE
		add		hl, de
		ld		e, [hl]
		inc		hl
		ld		d, [hl]
		ex		de, hl
		call	lw_dec6
		ld		hl, s_log_errpfx	; "|ERROR |    |"
		call	lw_puts
		pop		hl
		call	lw_puts
		call	lw_file_line_suffix
		jp		lw_nl
s_log_errpfx:
		db		"|ERROR |    |", 0

;	lw_msg_error_line: message in msg_buf/[msg_len] -> log error line
lw_msg_error_line:
		ld		a, [log_active]
		or		a, a
		ret		z
		call	lw_src_line	; source line first (abbreviated log)
		ld		hl, [cur_ent]
		ld		de, E_LINE
		add		hl, de
		ld		e, [hl]
		inc		hl
		ld		d, [hl]
		ex		de, hl
		call	lw_dec6
		ld		hl, s_log_errpfx
		call	lw_puts
		ld		hl, msg_buf
		ld		bc, [msg_len]
		call	lw_write
		call	lw_file_line_suffix
		jp		lw_nl

;	lw_file_line_suffix: ": <file>(<line>)" (log version)
lw_file_line_suffix:
		ld		a, ':'
		call	lw_putc
		ld		a, ' '
		call	lw_putc
		ld		hl, [cur_ent]
		ld		de, E_NAME
		add		hl, de
		call	lw_puts
		ld		a, '('
		call	lw_putc
		ld		hl, [cur_ent]
		ld		de, E_LINE
		add		hl, de
		ld		e, [hl]
		inc		hl
		ld		d, [hl]
		ex		de, hl
		call	lw_dec
		ld		a, ')'
		jp		lw_putc

;	lw_message_line: MESSAGE output is console-only under
;	the abbreviated log (a MESSAGE is not an error).
lw_message_line:
		ret

; ---------------------------------------------------------------------------
;	Label section (log) + zma.sym: stream defined symbols in
;	storage order (hash bucket / chain order).  No sort and
;	no count cap: every defined symbol is dumped.  (Author
;	ruling 2026-11-15 -- completeness over sorted order;
;	the former SYMTAB_MAX = 2,048 cap silently dropped the
;	overflow from both dumps.)
; ---------------------------------------------------------------------------
st_count:
		dw		0
st_maxlen:
		db		0
st_rec:
		space	4
st_nbuf_a:
		space	64

;	st_fetch_name: record offset in st_rec, DE = dest -> copies name,
;	A = name length
st_fetch_name:
		ld		[stfn_dst], de	; keep dest in a cell (DE unsafe across pio)
		ld		hl, st_rec
		ld		a, SYM_NLEN
		call	off_copy_add
		call	pio_read8		; A = namelen
		ld		b, a
		push	bc
		ld		hl, st_rec
		ld		a, SYM_NAME
		call	off_copy_add	; pio = name
		pop		bc
		ld		hl, [stfn_dst]	; HL = dest (pio_read8 preserves HL)
		ld		a, b
		or		a, a
		jr		z, stfn_done
stfn_l:
		call	pio_read8
		ld		[hl], a
		inc		hl
		call	pio_inc
		djnz	stfn_l
stfn_done:
		xor		a, a
		ld		[hl], a
		; A = length again
		ld		hl, st_rec
		ld		a, SYM_NLEN
		call	off_copy_add
		call	pio_read8
		ret
stfn_dst:
		dw		0

;	st_walk: visit every DEFINED record in storage order and
;	call [st_cb] for each.  The callback runs with st_rec =
;	record offset and must preserve st_rec, st_bkt and st_nx
;	(the walker reads the chain link from st_rec after the
;	callback returns).
st_walk:
		ld		hl, 0		; bucket index in HL via st_bkt cell
		ld		[st_bkt], hl
stw_bl:
		ld		hl, [st_bkt]
		ld		a, l
		cp		a, 0x00
		jr		nz, stw_bgo
		ld		a, h
		cp		a, 4			; 1024 buckets = 0x400
		ret		nc
stw_bgo:
		; chain head = hash_table[bucket]
		ld		hl, [st_bkt]
		add		hl, hl
		add		hl, hl
		ld		de, hash_table
		add		hl, de
		ld		e, [hl]
		inc		hl
		ld		d, [hl]
		inc		hl
		ld		c, [hl]
		inc		hl
		ld		b, [hl]			; BC:DE = record offset
		ld		[st_rec], de
		ld		[st_rec + 2], bc
stw_chain:
		ld		hl, st_rec
		call		off_is_zero
		jp		z, stw_nextb
		; flags
		ld		hl, st_rec
		ld		a, SYM_FLAGS
		call		off_copy_add
		call		pio_read8
		bit		0, a			; DEFINED?
		jr		z, stw_skip
		call		st_call_cb
stw_skip:
		; next = record[0..3]
		ld		hl, st_rec
		xor		a, a
		call		off_copy_add
		call		pio_read8
		ld		[st_nx], a
		call		pio_inc
		call		pio_read8
		ld		[st_nx + 1], a
		call		pio_inc
		call		pio_read8
		ld		[st_nx + 2], a
		call		pio_inc
		call		pio_read8
		ld		[st_nx + 3], a
		ld		hl, [st_nx]
		ld		[st_rec], hl
		ld		hl, [st_nx + 2]
		ld		[st_rec + 2], hl
		jp		stw_chain
stw_nextb:
		ld		hl, [st_bkt]
		inc		hl
		ld		[st_bkt], hl
		jp		stw_bl
st_call_cb:
		ld		hl, [st_cb]
		jp		hl
st_cb:
		dw		0
st_bkt:
		dw		0
st_nx:
		space	4

;	stc_count: pre-pass callback -- count DEFINED records and
;	track the longest name (log rows pad names to maxlen + 3).
stc_count:
		ld		hl, [st_count]
		inc		hl
		ld		[st_count], hl
		ld		hl, st_rec
		ld		a, SYM_NLEN
		call		off_copy_add
		call		pio_read8
		ld		b, a
		ld		a, [st_maxlen]
		cp		a, b
		ret		nc
		ld		a, b
		ld		[st_maxlen], a
		ret

;	st_load_rec: sym_get for the record in st_rec
;	-> val_tmp, [st_flg]
st_load_rec:
		ld		hl, [st_rec]
		ld		[sym_off], hl
		ld		hl, [st_rec + 2]
		ld		[sym_off + 2], hl
		call		sym_get		; val_tmp = value, A = flags
		ld		[st_flg], a
		ret

;	std_log: ZMA.LOG label-section row for the record in st_rec
std_log:
		call		st_load_rec	; sym_get done
		ld		de, st_nbuf_a
		call		st_fetch_name	; A = len
		ld		[st_nl], a
		ld		hl, st_nbuf_a
		call		lw_puts
		ld		a, ' '
		call		lw_putc
		; dots: (maxlen + 3) - len
		ld		a, [st_maxlen]
		add		a, 3
		ld		b, a
		ld		a, [st_nl]
		ld		c, a
		ld		a, b
		sub		a, c
		jr		z, lf_val
		ld		b, a
lf_dots:
		ld		a, '.'
		push		bc
		call		lw_putc
		pop		bc
		djnz		lf_dots
lf_val:
		ld		a, ' '
		call		lw_putc
		; value by flags (A from sym_get was saved to st_flg)
		ld		a, [st_flg]
		bit		3, a			; string?
		jr		nz, lf_vstr
		ld		hl, val_tmp
		ld		de, sbuf_a
		call		dec32_to_buf
		ld		hl, sbuf_a
		call		lw_write
		ld		hl, s_lf_hexp		; " ( 0x" (label section format)
		call		lw_puts
		ld		hl, val_tmp
		call		lw_hexl
		ld		hl, s_log_rp	; ")"
		call		lw_puts
		jp		lw_nl
lf_vstr:
		ld		a, '"'
		call		lw_putc
		ld		hl, val_tmp
		ld		de, sbuf_a
		call		str_fetch
		ld		hl, sbuf_a
		call		lw_write
		ld		a, '"'
		call		lw_putc
		jp		lw_nl

;	std_sym: ZMA.SYM row for the record in st_rec
;	(strings are not listed in zma.sym)
std_sym:
		call		st_load_rec
		ld		a, [st_flg]
		bit		3, a			; string?
		ret		nz
		ld		de, st_nbuf_a
		call		st_fetch_name
		ld		hl, st_nbuf_a
		call		lw_puts
		ld		hl, s_sym_equ	; " equ 0"
		call		lw_puts
		ld		hl, val_tmp
		call		lw_hexl
		ld		a, 'h'
		call		lw_putc
		jp		lw_nl
s_log_rp:
		db		" )", 0
s_lf_hexp:
		db		" ( 0x", 0
s_sym_equ:
		db		" equ 0", 0
st_nl:
		db		0
st_flg:
		db		0

;	log_finish: label section into ZMA.LOG, close it, write ZMA.SYM
log_finish:
		; pre-pass: count DEFINED records + longest name
		xor		a, a
		ld		[st_count], a
		ld		[st_count + 1], a
		ld		[st_maxlen], a
		ld		hl, stc_count
		ld		[st_cb], hl
		call		st_walk
		ld		a, [log_active]
		or		a, a
		jp		z, lf_sym
		ld		hl, [st_count]
		ld		a, h
		or		a, l
		jp		z, lf_nosec
		ld		hl, s_log_labelsec
		call		lw_puts
		ld		hl, std_log
		ld		[st_cb], hl
		call		st_walk
lf_nosec:
		call		lw_close
		xor		a, a
		ld		[log_active], a
lf_sym:
		; ---- zma.sym ----
		ld		hl, lw_name_sym
		call		lw_open
		ret		c
		ld		hl, std_sym
		ld		[st_cb], hl
		call		st_walk
		jp		lw_close


;	lw_scope_enter / lw_scope_exit: scope enter/exit lines
;	were part of the full listing and are not emitted by
;	the abbreviated log.  No-ops (a bare ret preserves
;	every register, which keeps all callers' contracts).
lw_scope_enter:
		ret
lw_scope_exit:
		ret

;	log_set_info_assign: called from sym_define_assign after a define;
;	A = flags (GLOBAL/STRING bits) -- records the pending info line
log_set_info_assign:
		ld		a, [final_pass]
		or		a, a
		ret		z
		ld		a, [expr_error]
		or		a, a
		ret		nz
		ld		a, [sda_extra]
		ld		b, 1			; kind base
		bit		1, a			; SYM_F_GLOBAL
		jr		z, lsia_1
		inc		b
lsia_1:
		bit		3, a			; SYM_F_STRING
		jr		z, lsia_2
		inc		b
		inc		b
lsia_2:
		ld		a, b
		ld		[log_info_kind], a
		jr		log_set_info_common
;	log_set_info_label: A = flags (GLOBAL bit) for a code label
lsi_flg:
		db		0
log_set_info_label:
		ld		[lsi_flg], a
		ld		a, [final_pass]
		or		a, a
		ret		z
		ld		a, [lsi_flg]
		bit		1, a
		jr		nz, lsil_g
		ld		a, 5
		jr		lsil_s
lsil_g:
		ld		a, 6
lsil_s:
		ld		[log_info_kind], a
log_set_info_common:
		ld		hl, name_buf
		ld		de, log_info_name
		ld		bc, 64
		ldir
		ld		hl, new_val
		ld		de, log_info_val
		ld		bc, 4
		ldir
		ret

; =============================================================================
;	Assembler driver + line processor
;	pc_val / file_off: 32-bit assembler state.
;	final_pass: 1 during the output-producing pass.
;	output_active: 1 when bytes should go to the output file.
; =============================================================================
pc_val:
		space	4
file_off:
		space	4
line_start_pc:
		space	4
line_start_fileoff:
		space	4
final_pass:
		db		0
output_active:
		db		0
err_count:
		dw		0
iter_count:
		db		0

hash_table:
		space	4096

asm_main:
		call	hash_clear
		xor		a, a
		ld		[scope_depth], a
		ld		[err_count], a
		ld		[err_count + 1], a
		ld		[iter_count], a
		call	p3_init			; P3: macro/link/repeat tables
		; open main input
		ld		hl, in_name
		call	open_main_input
		jr		nc, am_opened
		ld		hl, s_cantopen
		call	puts
		ld		hl, in_name
		call	puts
		ld		hl, s_crlf
		call	puts
		ld		a, 1
		ret
am_opened:
		; -D symbols were registered before mapper_init? No: -D parsing
		; happened in parse_cmdline, before pool exists.  They are held in
		; d_list (chunk A stored name+value pairs); register them now.
		call	register_d_list
		call	intern_default_str	; "DEFAULT" block for CHAR_SET_NAME
		call	if_snapshot		; P4: IF search snapshot
am_iter:
		ld		a, [iter_count]
		inc		a
		ld		[iter_count], a
		cp		a, 33
		jr		nc, am_noconv
		xor		a, a
		ld		[pass_changed], a
		ld		[final_pass], a
		ld		[output_active], a
		call	rewind_source
		call	reset_asm_state
		call	run_pass
		call	link_force_check	; cross set_evaluated_for_all_links
		ld		a, [pass_changed]
		or		a, a
		jr		nz, am_iter
		; converged: an IF candidate search may take over the
		; ending; otherwise the normal final pass runs
		call	if_pre_final
		jr		nc, am_nf
		or		a, a
		jp		nz, am_outerr
		jr		am_tail
am_nf:
		call	do_final_pass
		jp		c, am_outerr
am_tail:
		; unclosed SCOPE at end of source (cross: scope not closed)
		ld		a, [scope_depth]
		or		a, a
		jr		z, am_scope_ok
		ld		hl, s_scopeopen
		call	err_line
am_scope_ok:
		ld		hl, [err_count]
		ld		a, h
		or		a, l
		ret		z				; A=0 success
		ld		a, 1
		ret
am_outerr:
		ld		hl, s_cantcreate
		call	puts
		ld		hl, out_name
		call	puts
		ld		hl, s_crlf
		call	puts
		ld		a, 1
		ret
am_noconv:
		ld		hl, s_noconv
		call	puts
		ld		a, 1
		ret
s_cantopen:
		db		"Can't open: ", 0
s_cantcreate:
		db		"Can't create: ", 0
s_crlf:
		db		13, 10, 0
s_noconv:
		db		"Error: symbols did not converge.", 13, 10, 0

reset_asm_state:
		xor		a, a
		ld		[arena_top], a		; P3: capture arena is per-pass
		ld		[arena_top + 1], a
		ld		[arena_top + 2], a
		ld		[arena_top + 3], a
		ld		[ctx_sp], a
		ld		[pc_val], a
		ld		[pc_val + 1], a
		ld		[pc_val + 2], a
		ld		[pc_val + 3], a
		ld		[file_off], a
		ld		[file_off + 1], a
		ld		[file_off + 2], a
		ld		[file_off + 3], a
		ld		[scope_depth], a
		ld		[if_depth], a		; P4: IF runtime state
		ld		[if_swallow], a
		ld		[dict_chg], a
		ld		[dict_chg + 1], a
		ld		a, 1
		ld		[rep_armed], a
		xor		a, a
		ld		[cs_cur], a			; P4: no current char set at
		ld		[cs_cur + 1], a		; pass start; name = "DEFAULT"
		ld		[cs_cur + 2], a
		ld		[cs_cur + 3], a
		ld		hl, [defstr_off]
		ld		[cs_name_off], hl
		ld		hl, [defstr_off + 2]
		ld		[cs_name_off + 2], hl
		ret				; #62: charset tables PERSIST
						; across passes (see below)

run_pass:
		call	get_line
		ret		c
		ld		hl, [pc_val]
		ld		[line_start_pc], hl
		ld		hl, [pc_val + 2]
		ld		[line_start_pc + 2], hl
		ld		hl, [file_off]
		ld		[line_start_fileoff], hl
		ld		hl, [file_off + 2]
		ld		[line_start_fileoff + 2], hl
		call	if_gate			; P4: drop lines in inactive branches
		jr		c, run_pass
		call	log_line_begin
		call	process_line
		call	log_line_end
		jr		run_pass

;	emit8: A = byte. Advances pc/file_off; writes when output_active.
emit8:
		push	af
		ld		hl, pc_val
		inc		[hl]
		jr		nz, em_1
		inc		hl
		inc		[hl]
		jr		nz, em_1
		inc		hl
		inc		[hl]
		jr		nz, em_1
		inc		hl
		inc		[hl]
em_1:
		ld		hl, file_off
		inc		[hl]
		jr		nz, em_2
		inc		hl
		inc		[hl]
		jr		nz, em_2
		inc		hl
		inc		[hl]
		jr		nz, em_2
		inc		hl
		inc		[hl]
em_2:
		ld		a, [output_active]
		or		a, a
		jr		z, em_3
		pop		af
		ld		b, a			; byte preserved in B
		call	log_capture
		ld		a, [opt_hex]
		or		a, a
		ld		a, b
		jp		z, out_byte
		jp		hex_write
em_3:
		pop		af
		ret

;	emit16: HL = value (LE)
emit16:
		push	hl
		ld		a, l
		call	emit8
		pop		hl
		ld		a, h
		call	emit8
		ret

;	emit32: DE:HL = value (LE)
emit32:
		push	de
		call	emit16
		pop		hl
		call	emit16
		ret

;	err_line: HL = message (NUL-term). Counted/printed only in final pass.
err_line:
		ld		a, [trial_mode]		; P4: trials count silently
		or		a, a
		jr		z, el_norm
		ld		hl, [trial_err]
		inc		hl
		ld		[trial_err], hl
		ret
el_norm:
		ld		a, [final_pass]
		or		a, a
		ret		z
		ld		[el_msg], hl
		ld		hl, [err_count]
		inc		hl
		ld		[err_count], hl
		; print "name(line): msg"
		ld		hl, [cur_ent]
		ld		de, E_NAME
		add		hl, de
		call	puts
		ld		a, '('
		call	putc
		ld		hl, [cur_ent]
		ld		de, E_LINE
		add		hl, de
		ld		e, [hl]
		inc		hl
		ld		d, [hl]
		ex		de, hl
		call	print_dec16
		ld		a, ')'
		call	putc
		ld		a, ':'
		call	putc
		ld		a, ' '
		call	putc
		ld		hl, [el_msg]
		call	puts
		ld		hl, s_crlf
		call	puts
		ld		hl, [el_msg]
		call	lw_error_line
		ret
el_msg:
		dw		0

;	check_undef: if expr_undef -> "undefined symbol" error (final pass)
check_undef:
		ld		a, [expr_undef]
		or		a, a
		ret		z
		ld		hl, s_undef
		call	err_line
		ret
s_undef:
		db		"Cannot evaluate the expression.", 0
s_syntax:
		db		"Syntax error.", 0
s_badop:
		db		"Illegal operand.", 0
s_illegal_expr:
		db		"Illegal expression.", 0
s_divzero:
		db		"Divided by zero.", 0
s_multdef:
		db		"Multiple definition.", 0
s_notimpl:
		db		"not supported (P1).", 0

;	check_expr_err: expr_error -> message selected by expr_errkind
check_expr_err:
		ld		a, [expr_error]
		or		a, a
		ret		z
		ld		a, [expr_errkind]
		cp		a, 1
		jr		z, cee_ill
		cp		a, 2
		jr		z, cee_div
		ld		hl, s_syntax
		jp		err_line
cee_ill:
		ld		hl, s_illegal_expr
		jp		err_line
cee_div:
		ld		hl, s_divzero
		jp		err_line

; ---------------------------------------------------------------------------
;	process_line: parse line_buf.
;	[lp] walks the line.
; ---------------------------------------------------------------------------
lp:
		dw		0
mnem_buf:
		space	16

;	skip_lp_spaces: advance lp past spaces/tabs
skip_lp_spaces:
		ld		hl, [lp]
sls_l:
		ld		a, [hl]
		cp		a, ' '
		jr		z, sls_1
		cp		a, 9
		jr		nz, sls_done
sls_1:
		inc		hl
		jr		sls_l
sls_done:
		ld		[lp], hl
		ret

;	lp_char: A = current char at lp
lp_char:
		ld		hl, [lp]
		ld		a, [hl]
		ret

;	lp_at_end: -> Z if at end (NUL or ';')
lp_at_end:
		call	lp_char
		or		a, a
		ret		z
		cp		a, ';'
		ret

;	scan_ident_lp: if lp at ident start: copy upcased ident to
;	name_src_buf, advance lp past it, return CY. Else NC.
scan_ident_lp:
		ld		hl, [lp]
		ld		a, [hl]
		call	is_ident_start
		ret		nc
		ld		de, name_src_buf
		ld		b, 0
si_l:
		ld		a, [hl]
		call	is_ident_char
		jr		nc, si_done
		call	upcase
		ld		c, a
		ld		a, b
		cp		a, 63
		jr		nc, si_skip
		ld		a, c
		ld		[de], a
		inc		de
		inc		b
si_skip:
		inc		hl
		jr		si_l
si_done:
		xor		a, a
		ld		[de], a
		ld		[lp], hl
		scf
		ret

process_line:
		ld		hl, line_buf
		ld		[lp], hl
		ld		a, [line_too_long]
		or		a, a
		jr		z, pl_0
		ld		hl, s_line_long
		call	err_line
pl_0:
		call	skip_lp_spaces
		call	lp_at_end
		ret		z
		call	lp_char
		cp		a, ';'
		ret		z				; comment-only line
		; label definitions (possibly several)
pl_label:
		ld		hl, [lp]
		ld		[pl_save], hl
		call	scan_ident_lp
		jp		nc, pl_stmt
		call	skip_lp_spaces		; allow space before ':'
		call	lp_char
		cp		a, ':'
		jr		nz, pl_notlabel
		; label found: name in name_src_buf
		ld		hl, [lp]
		inc		hl
		ld		[lp], hl
		call	lp_char
		cp		a, '='			; ':=' -> global assignment
		jp		z, pl_assign_coloneq
		cp		a, ':'
		jr		z, pl_glob
		xor		a, a			; extra flags = 0
		jr		pl_lab1
pl_glob:
		ld		hl, [lp]
		inc		hl
		ld		[lp], hl
		ld		a, SYM_F_GLOBAL
pl_lab1:
		ld		[pl_labflg], a
		ld		hl, [pc_val]
		ld		[new_val], hl
		ld		hl, [pc_val + 2]
		ld		[new_val + 2], hl
		ld		a, [pl_labflg]
		push	af
		call	sym_define_scoped
		pop		af
		call	log_set_info_label
		call	skip_lp_spaces
		call	lp_at_end
		ret		z
		jr		pl_label
pl_notlabel:
		; 'EQU' keyword?  (cross: NAME EQU expr is a global assignment)
		ld		hl, name_src_buf
		ld		de, assign_name
		ld		bc, 64
		ldir					; save LHS name
		ld		hl, [lp]
		ld		[pl_save], hl
		call	scan_ident_lp
		jr		nc, pl_not_equ
		ld		hl, name_src_buf
		ld		de, kw_equ
		call	str_eq
		jr		nz, pl_not_equ
		ld		hl, assign_name
		ld		de, name_src_buf
		ld		bc, 64
		ldir					; restore LHS name
		ld		a, SYM_F_GLOBAL
		ld		[pl_labflg], a
		jr		pl_assign_rhs
pl_not_equ:
		ld		hl, assign_name
		ld		de, name_src_buf
		ld		bc, 64
		ldir					; restore LHS name
		ld		hl, [pl_save]
		ld		[lp], hl
		; assignment?  ident already scanned; look for '=' (':=' was
		; handled in the label path above).
		call	lp_char
		cp		a, '='
		jr		z, pl_assign_eq
		; not a label/assignment: it's a statement starting with ident
		jr		pl_stmt_from_ident
pl_assign_eq:
		; plain '=' assignment (scoped): consume '='
		xor		a, a
		ld		[pl_labflg], a
		ld		hl, [lp]
		inc		hl
		ld		[lp], hl
		jr		pl_assign_rhs
pl_assign_coloneq:
		; ':=' assignment (global): consume '='
		ld		a, SYM_F_GLOBAL
		ld		[pl_labflg], a
		ld		hl, [lp]
		inc		hl
		ld		[lp], hl
		jr		pl_assign_rhs
pl_stmt:
		; statement does not start with an identifier: clear the word
		; buffer so dispatch reports an error instead of re-running a
		; stale mnemonic from a previous line.
		xor		a, a
		ld		[name_src_buf], a
		jr		pl_mnem
pl_stmt_from_ident:
		; name_src_buf holds the first word (directive or mnemonic)
		jr		pl_mnem
pl_assign_rhs:
		; [pl_labflg] = GLOBAL flag or 0; lp is just past '='
		; Preserve the LHS name: expr_eval's identifier lookups overwrite
		; name_src_buf with the last RHS identifier resolved.
		ld		hl, name_src_buf
		ld		de, assign_name
		ld		bc, 64
		ldir
		ld		hl, [lp]
		ld		[ev_ptr], hl
		call	expr_eval		; DE:HL value
		ld		[new_val], hl
		ld		[new_val + 2], de
		ld		hl, assign_name
		ld		de, name_src_buf
		ld		bc, 64
		ldir
		call	check_expr_err
		ld		a, [expr_undef]
		or		a, a
		jr		z, pl_assign_def
		; undefined RHS: skipped in dry passes (fixpoint retry); in
		; the final pass it is an error (cross: label indeterminate)
		ld		a, [final_pass]
		or		a, a
		jr		z, pl_assign_skip
		ld		hl, s_indet
		call	err_line
		jr		pl_assign_skip
pl_assign_def:
		ld		a, [pl_labflg]
		or		a, SYM_F_ASSIGN
		ld		b, a
		ld		a, [val_type]
		or		a, a
		jr		z, pl_assign_go
		ld		a, b
		or		a, SYM_F_STRING
		ld		b, a
pl_assign_go:
		ld		a, b
		call	sym_define_assign
		jr		pl_assign_skip
pl_assign_skip:
		ret							; assignment consumes the line
pl_mnem:
		; P3: macro definition / invocation dispatch comes before
		; directives and mnemonics (cross create() order)
		call	p3_mnem_hook		; CY = handled
		ret		c
		; copy mnemonic word (upcased) into mnem_buf
		ld		hl, name_src_buf
		ld		de, mnem_buf
		ld		bc, 15
pl_mcp:
		ld		a, [hl]
		ld		[de], a
		or		a, a
		jr		z, pl_mdone
		inc		hl
		inc		de
		dec		bc
		ld		a, b
		or		a, c
		jr		nz, pl_mcp
pl_mdone:
		xor		a, a
		ld		[de], a
		call	dispatch_stmt
		ret
pl_save:
		dw		0
pl_labflg:
		db		0
assign_name:
		space	64
kw_equ:
		db		"EQU", 0
s_indet:
		db		"Label is indeterminate.", 0
s_line_long:
		db		"line too long.", 0

; ---------------------------------------------------------------------------
;	dispatch_stmt: mnemonic in mnem_buf, operands at lp.
;	Directives first, then instruction encoder (chunk E3).
; ---------------------------------------------------------------------------
dispatch_stmt:
		ld		hl, mnem_buf
		ld		de, d_org
		call	str_eq
		jp		z, dir_org
		ld		hl, mnem_buf
		ld		de, d_defb
		call	str_eq
		jp		z, dir_defb
		ld		hl, mnem_buf
		ld		de, d_db
		call	str_eq
		jp		z, dir_defb
		ld		hl, mnem_buf
		ld		de, d_defw
		call	str_eq
		jp		z, dir_defw
		ld		hl, mnem_buf
		ld		de, d_dw
		call	str_eq
		jp		z, dir_defw
		ld		hl, mnem_buf
		ld		de, d_defd
		call	str_eq
		jp		z, dir_defd
		ld		hl, mnem_buf
		ld		de, d_dd
		call	str_eq
		jp		z, dir_defd
		ld		hl, mnem_buf
		ld		de, d_defs
		call	str_eq
		jp		z, dir_defs
		ld		hl, mnem_buf
		ld		de, d_space
		call	str_eq
		jp		z, dir_space
		ld		hl, mnem_buf
		ld		de, d_align
		call	str_eq
		jp		z, dir_align
		ld		hl, mnem_buf
		ld		de, d_include
		call	str_eq
		jp		z, dir_include
		ld		hl, mnem_buf
		ld		de, d_scope
		call	str_eq
		jp		z, dir_scope
		ld		hl, mnem_buf
		ld		de, d_endscope
		call	str_eq
		jp		z, dir_endscope
		ld		hl, mnem_buf
		ld		de, d_repeat
		call	str_eq
		jp		z, dir_repeat
		ld		hl, mnem_buf
		ld		de, d_link
		call	str_eq
		jp		z, dir_link
		ld		hl, mnem_buf
		ld		de, d_endr
		call	str_eq
		jp		z, p3_stray_kw
		ld		hl, mnem_buf
		ld		de, d_endm
		call	str_eq
		jp		z, p3_stray_kw
		ld		hl, mnem_buf
		ld		de, d_endl
		call	str_eq
		jp		z, p3_stray_kw
		ld		hl, mnem_buf
		ld		de, d_message
		call	str_eq
		jp		z, dir_message
		ld		hl, mnem_buf
		ld		de, d_error
		call	str_eq
		jp		z, dir_error
		ld		hl, mnem_buf
		ld		de, d_chg_char_set
		call	str_eq
		jp		z, dir_chg_char_set
		ld		hl, mnem_buf
		ld		de, d_mapping_char
		call	str_eq
		jp		z, dir_mapping_char
		ld		hl, mnem_buf
		ld		de, d_binary_link
		call	str_eq
		jp		z, dir_binary_link
		ld		hl, mnem_buf
		ld		de, d_if
		call	str_eq
		jp		z, dir_if
		ld		hl, mnem_buf
		ld		de, d_elseif
		call	str_eq
		jp		z, dir_elseif
		ld		hl, mnem_buf
		ld		de, d_else
		call	str_eq
		jp		z, dir_else
		ld		hl, mnem_buf
		ld		de, d_endif
		call	str_eq
		jp		z, dir_endif
		jp		encode_instruction
d_org:
		db		"ORG", 0
d_defb:
		db		"DEFB", 0
d_db:
		db		"DB", 0
d_defw:
		db		"DEFW", 0
d_dw:
		db		"DW", 0
d_defd:
		db		"DEFD", 0
d_dd:
		db		"DD", 0
d_defs:
		db		"DEFS", 0
d_space:
		db		"SPACE", 0
d_align:
		db		"ALIGN", 0
d_include:
		db		"INCLUDE", 0
d_scope:
		db		"SCOPE", 0
d_endscope:
		db		"ENDSCOPE", 0
d_repeat:
		db		"REPEAT", 0
d_link:
		db		"LINK", 0
d_endr:
		db		"ENDR", 0
d_endm:
		db		"ENDM", 0
d_endl:
		db		"ENDL", 0
d_message:
		db		"MESSAGE", 0
d_error:
		db		"ERROR", 0
d_chg_char_set:
		db		"CHG_CHAR_SET", 0
d_mapping_char:
		db		"MAPPING_CHAR", 0
d_binary_link:
		db		"BINARY_LINK", 0
d_if:
		db		"IF", 0
d_elseif:
		db		"ELSEIF", 0
d_else:
		db		"ELSE", 0
d_endif:
		db		"ENDIF", 0

;	eval_at_lp: evaluate expr at lp; leave lp at ev_ptr end position
eval_at_lp:
		ld		hl, [lp]
		ld		[ev_ptr], hl
		call	expr_eval
		push	hl
		ld		hl, [ev_ptr]
		ld		[lp], hl
		pop		hl
		ret

;	dir_org: ORG expr
dir_org:
		call	eval_at_lp
		call	check_expr_err
		call	check_undef
		ld		[pc_val], hl
		ld		[pc_val + 2], de
		ret

;	emit_expr_list: size in A (1,2,4): loop over comma-separated exprs
;	(text at lp)
eel_size:
		db		0
emit_expr_list:
		ld		[eel_size], a
eel_item:
		call	skip_lp_spaces
		call	eval_at_lp		; DE:HL
		ld		a, [val_type]
		or		a, a
		jr		z, eel_nostr
		ld		hl, s_illegal_expr
		call	err_line
eel_nostr:
		call	check_expr_err
		call	check_undef
		ld		a, [eel_size]
		cp		a, 1
		jr		z, eel_1
		cp		a, 2
		jr		z, eel_2
		call	emit32
		jr		eel_next
eel_2:
		call	emit16
		jr		eel_next
eel_1:
		ld		a, l
		call	emit8
eel_next:
		call	skip_lp_spaces
		call	lp_char
		cp		a, ','
		ret		nz
		ld		hl, [lp]
		inc		hl
		ld		[lp], hl
		jr		eel_item

;	dir_defb: items are expressions; a string result emits its
;	bytes, an integer result emits one byte (cross-ZMA semantics)
dir_defb:
dfb_item:
		call	skip_lp_spaces
		call	eval_at_lp		; DE:HL value, val_type set
		call	check_expr_err
		call	check_undef
		ld		a, [val_type]
		or		a, a
		jr		nz, dfb_strval
		ld		a, l
		call	emit8
		jr		dfb_next
dfb_strval:
		ld		a, [val_undef]
		or		a, a
		jr		nz, dfb_next	; undefined string: no size in a dry pass
		ld		[dfb_off], hl
		ld		[dfb_off + 2], de
		ld		hl, dfb_off
		call	emit_str_bytes
dfb_next:
		call	skip_lp_spaces
		call	lp_char
		cp		a, ','
		ret		nz
		ld		hl, [lp]
		inc		hl
		ld		[lp], hl
		jr		dfb_item
dfb_off:
		space	4

dir_defw:
		ld		a, 2
		jp		emit_expr_list
dir_defd:
		ld		a, 4
		jp		emit_expr_list

;	esc_char: A = char after a backslash -> A = escaped value.
;	Cross-ZMA rules: a=07 b=08 f=0C n=0A r=0D t=09, any other char
;	(including \ ' ") maps to itself. Only A/F destroyed.
esc_char:
		cp		a, 'a'
		jr		nz, ec_1
		ld		a, 7
		ret
ec_1:
		cp		a, 'b'
		jr		nz, ec_2
		ld		a, 8
		ret
ec_2:
		cp		a, 'f'
		jr		nz, ec_3
		ld		a, 12
		ret
ec_3:
		cp		a, 'n'
		jr		nz, ec_4
		ld		a, 10
		ret
ec_4:
		cp		a, 'r'
		jr		nz, ec_5
		ld		a, 13
		ret
ec_5:
		cp		a, 't'
		ret		nz				; other: char itself
		ld		a, 9
		ret

;	sjis_lead: A = byte -> CY if Shift_JIS lead byte (81-9F, E0-FC).
;	A preserved.
sjis_lead:
		cp		a, 0x81
		jr		c, sjl_no
		cp		a, 0xA0
		jr		c, sjl_yes
		cp		a, 0xE0
		jr		c, sjl_no
		cp		a, 0xFD
		jr		nc, sjl_no
sjl_yes:
		scf
		ret
sjl_no:
		or		a, a			; NC (A nonzero at call sites)
		ret

;	parse_string_lp: lp at '"' -> copy literal bytes to str_buf,
;	[str_len] = length; lp advanced past closing quote. CY if no quote.
str_buf:
		space	256
str_len:
		dw		0
parse_string_lp:
		call	skip_lp_spaces
		call	lp_char
		cp		a, '"'
		jr		nz, psl_no
		ld		hl, [lp]
		inc		hl
		ld		de, str_buf
		ld		bc, 0
psl_l:
		ld		a, [hl]
		or		a, a
		jr		z, psl_done
		cp		a, '"'
		jr		z, psl_done
		cp		a, 0x5C			; backslash escape
		jr		z, psl_esc
		call	sjis_lead		; SJIS lead byte -> pair verbatim
		jr		c, psl_pair
		ld		[de], a
		inc		hl
		inc		de
		inc		bc
		jr		psl_l
psl_esc:
		inc		hl
		ld		a, [hl]
		or		a, a
		jr		z, psl_done
		call	esc_char
		ld		[de], a
		inc		hl
		inc		de
		inc		bc
		jr		psl_l
psl_pair:
		ld		[de], a
		inc		hl
		inc		de
		inc		bc
		ld		a, [hl]
		or		a, a
		jr		z, psl_done
		ld		[de], a
		inc		hl
		inc		de
		inc		bc
		jr		psl_l
psl_done:
		ld		a, [hl]
		cp		a, '"'
		jr		nz, psl_2
		inc		hl
psl_2:
		ld		[lp], hl
		ld		[str_len], bc
		xor		a, a
		ld		[de], a
		or		a, a			; NC
		ret
psl_no:
		scf
		ret

;	dir_defs: DEFS string-expr  (or DEFS size[,fill] when -DEFS option)
;	An integer expression is converted to its decimal string (cross).
dir_defs:
		ld		a, [opt_defs]
		or		a, a
		jr		nz, dir_space	; reserve form
		call	skip_lp_spaces
		call	eval_at_lp		; DE:HL value, val_type set
		call	check_expr_err
		call	check_undef
		ld		[dds_cell], hl
		ld		[dds_cell + 2], de
		ld		a, [val_type]
		or		a, a
		jr		nz, dds_strval
		; integer -> decimal ASCII
		ld		hl, dds_cell
		ld		de, sbuf_a
		call	dec32_to_buf	; BC = length
		ld		hl, sbuf_a
		jr		dds_emit
dds_strval:
		ld		a, [val_undef]
		or		a, a
		ret		nz			; dry pass: size not known yet
		ld		hl, dds_cell
		jp		emit_str_bytes
dds_emit:
		ld		a, b
		or		a, c
		ret		z
		ld		a, [hl]
		inc		hl
		push	hl
		push	bc
		call	emit8
		pop		bc
		pop		hl
		dec		bc
		jr		dds_emit
dds_cell:
		space	4
dds_err:
		ld		hl, s_syntax
		call	err_line
		ret

;	dir_space: SPACE size [, fill]
dir_space:
		call	eval_at_lp		; DE:HL = size
		call	check_expr_err
		call	check_undef
		ld		[sp_count], hl
		xor		a, a
		ld		[sp_fill], a
		call	skip_lp_spaces
		call	lp_char
		cp		a, ','
		jr		nz, dsp_go
		ld		hl, [lp]
		inc		hl
		ld		[lp], hl
		call	eval_at_lp
		ld		a, l
		ld		[sp_fill], a
dsp_go:
		ld		hl, [sp_count]
dsp_l:
		ld		a, h
		or		a, l
		ret		z
		push	hl
		ld		a, [sp_fill]
		call	emit8
		pop		hl
		dec		hl
		jr		dsp_l
sp_count:
		dw		0
sp_fill:
		db		0

;	dir_align: ALIGN n -> pad 0 until pc % n == 0 (16-bit pc, n <= 32768)
dir_align:
		call	eval_at_lp
		call	check_expr_err
		call	check_undef
		ld		a, h
		or		a, l
		ret		z				; n=0: nothing
		ld		[al_n], hl
		; remainder = pc_low % n
dal_l:
		ld		hl, [pc_val]
		ld		de, [al_n]
		; HL % DE via repeated subtraction (pc < 64K typical)
		or		a, a
dal_mod:
		ld		a, l
		sub		a, e
		ld		a, h
		sbc		a, d
		jr		c, dal_chk
		; HL -= DE
		ld		a, l
		sub		a, e
		ld		l, a
		ld		a, h
		sbc		a, d
		ld		h, a
		jr		dal_mod
dal_chk:
		ld		a, h
		or		a, l
		ret		z				; aligned
		xor		a, a
		call	emit8
		jr		dal_l
al_n:
		dw		0

;	dir_include: INCLUDE "name"
dir_include:
		call	parse_string_lp
		jr		c, dds_err
		; str_buf = filename (NUL-term)
		ld		hl, str_buf
		call	push_include
		jr		nc, di_ok
		; try include path prefix
		ld		a, [inc_path_valid]
		or		a, a
		jr		z, di_fail
		; build inc_path + "/" + name in inc_full (reuse str staging)
		ld		hl, inc_path_buf
		ld		de, inc_full
		call	strcpy_de		; copy incl NUL handling: returns DE at NUL
		ld		a, '/'
		ld		[de], a
		inc		de
		ld		hl, str_buf
		call	strcpy_de
		ld		hl, inc_full
		call	push_include
		jr		c, di_fail
di_ok:
		ret
di_fail:
		ld		hl, s_inc_fail
		call	err_line
		ld		a, 1
		ld		[pass_changed], a	; keep iterating? no: make it sticky:
		; treat as fatal-ish: set err in final pass and exit code via
		; err_count already incremented by err_line (final pass only).
		; In dry passes, missing include would corrupt everything;
		; abort assembly:
		jp		fatal_exit
s_inc_fail:
		db		"include file not found.", 0
inc_full:
		space	80

;	strcpy_de: copy NUL-term string HL -> DE (incl NUL); DE ends at NUL
strcpy_de:
		ld		a, [hl]
		ld		[de], a
		or		a, a
		ret		z
		inc		hl
		inc		de
		jr		strcpy_de

;	;	dir_scope: SCOPE name
dir_scope:
		call	skip_lp_spaces
		call	scan_ident_lp
		jr		nc, dsc_noname
		; extra parameter -> error (cross: "Too many parameters.")
		call	skip_lp_spaces
		call	lp_at_end
		jr		nz, dsc_toomany
		ld		a, [scope_depth]
		cp		a, SCOPE_MAX
		jr		nc, dsc_deep
		; copy name_src_buf into scope_names[depth]
		ld		l, a
		ld		h, 0
		add		hl, hl
		add		hl, hl
		add		hl, hl
		add		hl, hl
		add		hl, hl			; *32
		ld		c, a
		ld		b, 0
		add		hl, bc			; *33
		ld		bc, scope_names
		add		hl, bc
		ex		de, hl
		ld		hl, name_src_buf
		ld		bc, 33
		ldir
		ld		a, [scope_depth]
		inc		a
		ld		[scope_depth], a
		call	lw_scope_enter
		ret
dsc_noname:
		ld		hl, s_mustname
		jp		err_line
dsc_toomany:
		ld		hl, s_toomany
		jp		err_line
dsc_deep:
		ld		hl, s_scope_deep
		jp		err_line
s_mustname:
		db		"Must be set name.", 0
s_scope_deep:
		db		"Scope nesting too deep.", 0

;	dir_endscope: ENDSCOPE (no parameter; scope must be open)
dir_endscope:
		call	skip_lp_spaces
		call	lp_at_end
		jr		nz, dsc_toomany
		ld		a, [scope_depth]
		or		a, a
		jr		z, des_bad
		; cross: ENDSCOPE against an auto (@MACRO/@REPEAT) scope is
		; "Invalid command." and does not pop
		dec		a
		ld		l, a
		ld		h, 0
		add		hl, hl
		add		hl, hl
		add		hl, hl
		add		hl, hl
		add		hl, hl			; *32
		ld		e, a
		ld		d, 0
		add		hl, de			; *33
		ld		de, scope_names
		add		hl, de
		ld		a, [hl]
		cp		a, '@'
		jr		z, des_bad
		ld		a, [scope_depth]
		call	lw_scope_exit
		dec		a
		ld		[scope_depth], a
		ret
des_bad:
		ld		hl, s_invalid_cmd
		jp		err_line
s_invalid_cmd:
		db		"Invalid command.", 0
s_scopeopen:
		db		"Scope is not closed.", 0

; ---------------------------------------------------------------------------
;	MESSAGE / ERROR directives (P2).  Both take one expression operand;
;	an integer value is printed as decimal, a string as itself.
;	Console forms match cross ZMA: "MESSAGE: <text>: <file>(<line>)"
;	and "ERROR:<text>: <file>(<line>)".  Final pass only.
; ---------------------------------------------------------------------------
msg_buf:
		space	STR_MAX + 16
msg_len:
		dw		0
msg_val:
		space	4
s_msg_pfx:
		db		"MESSAGE: ", 0
s_err_pfx:
		db		"ERROR:", 0
s_toomany:
		db		"Too many parameters.", 0
s_illegal_param:
		db		"Illegal parameter.", 0

;	eval_msg_operand: evaluate the operand at lp into its string form
;	in msg_buf/[msg_len].  CY set if there is no operand.  On success
;	expr_error/expr_undef/val_undef reflect the evaluation.
eval_msg_operand:
		call	skip_lp_spaces
		call	lp_at_end
		jr		nz, emo_have
		scf
		ret
emo_have:
		call	eval_at_lp		; DE:HL value, val_type set
		ld		[msg_val], hl
		ld		[msg_val + 2], de
		ld		hl, msg_val
		ld		a, [val_type]
		ld		de, msg_buf
		call	str_of_value	; BC = length
		ld		[msg_len], bc
		or		a, a			; NC
		ret

;	msg_bad_operand: Z if the operand evaluation failed somehow
msg_bad_operand:
		ld		a, [expr_error]
		ld		b, a
		ld		a, [expr_undef]
		or		a, b
		ld		b, a
		ld		a, [val_undef]
		or		a, b
		ret

;	print_file_line_suffix: ": <file>(<line>)" for MESSAGE/ERROR
print_file_line_suffix:
		ld		a, ':'
		call	putc
		ld		a, ' '
		call	putc
		ld		hl, [cur_ent]
		ld		de, E_NAME
		add		hl, de
		call	puts
		ld		a, '('
		call	putc
		ld		hl, [cur_ent]
		ld		de, E_LINE
		add		hl, de
		ld		e, [hl]
		inc		hl
		ld		d, [hl]
		ex		de, hl
		call	print_dec16
		ld		a, ')'
		call	putc
		ret

;	print_msg_escaped: MESSAGE text with control chars escaped
;	(\a \b \f \n \r \t), as cross ZMA's put_message does.
print_msg_escaped:
		ld		hl, msg_buf
		ld		bc, [msg_len]
pme_l:
		ld		a, b
		or		a, c
		ret		z
		ld		a, [hl]
		inc		hl
		dec		bc
		cp		a, 7
		jr		z, pme_a
		cp		a, 8
		jr		z, pme_b
		cp		a, 12
		jr		z, pme_f
		cp		a, 10
		jr		z, pme_n
		cp		a, 13
		jr		z, pme_r
		cp		a, 9
		jr		z, pme_t
		push	hl
		push	bc
		call	putc
		pop		bc
		pop		hl
		jr		pme_l
pme_esc:
		ld		[pme_ch], a		; putc clobbers A; save the letter
		push	hl
		push	bc
		ld		a, 0x5C			; backslash
		call	putc
		ld		a, [pme_ch]
		call	putc
		pop		bc
		pop		hl
		jr		pme_l
pme_ch:
		db		0
pme_a:
		ld		a, 'a'
		jr		pme_esc
pme_b:
		ld		a, 'b'
		jr		pme_esc
pme_f:
		ld		a, 'f'
		jr		pme_esc
pme_n:
		ld		a, 'n'
		jr		pme_esc
pme_r:
		ld		a, 'r'
		jr		pme_esc
pme_t:
		ld		a, 't'
		jr		pme_esc

;	print_msg_raw: ERROR text, unescaped
print_msg_raw:
		ld		hl, msg_buf
		ld		bc, [msg_len]
pmr_l:
		ld		a, b
		or		a, c
		ret		z
		ld		a, [hl]
		inc		hl
		dec		bc
		push	hl
		push	bc
		call	putc
		pop		bc
		pop		hl
		jr		pmr_l

;	report_cross_error: HL = NUL-terminated message; prints
;	"ERROR:<msg>: <file>(<line>)" and counts the error (final pass).
report_cross_error:
		ld		a, [trial_mode]		; P4: trials count silently
		or		a, a
		jr		z, rce_norm
		ld		hl, [trial_err]
		inc		hl
		ld		[trial_err], hl
		ret
rce_norm:
		ld		a, [final_pass]
		or		a, a
		ret		z
		push	hl
		ld		hl, [err_count]
		inc		hl
		ld		[err_count], hl
		ld		hl, s_err_pfx
		call	puts
		pop		hl
		; copy message into msg_buf so the suffix printer is shared
		ld		de, msg_buf
		ld		bc, 0
rce_cp:
		ld		a, [hl]
		ld		[de], a
		or		a, a
		jr		z, rce_done
		inc		hl
		inc		de
		inc		bc
		jr		rce_cp
rce_done:
		ld		[msg_len], bc
		call	print_msg_raw
		call	print_file_line_suffix
		call	lw_msg_error_line
		ld		hl, s_crlf
		jp		puts

dir_message:
		call	skip_lp_spaces
		call	lp_at_end
		jr		z, dmsg_noarg
		ld		a, 1
		ld		[cs_suppress], a	; P4: MESSAGE operand is unmapped
		call	eval_msg_operand
		xor		a, a
		ld		[cs_suppress], a
		jr		c, dmsg_noarg
		call	msg_bad_operand
		jr		nz, dmsg_illegal
		ld		a, [final_pass]
		or		a, a
		ret		z
		ld		a, [trial_mode]		; P4: no MESSAGE output in trials
		or		a, a
		ret		nz
		ld		hl, s_msg_pfx
		call	puts
		call	print_msg_escaped
		call	print_file_line_suffix
		call	lw_message_line
		ld		hl, s_crlf
		jp		puts
dmsg_noarg:
		ld		hl, s_toomany
		jp		report_cross_error
dmsg_illegal:
		ld		hl, s_illegal_param
		jp		report_cross_error

dir_error:
		call	skip_lp_spaces
		call	lp_at_end
		jr		z, derr_noarg
		ld		a, 1
		ld		[cs_suppress], a	; P4: ERROR operand is unmapped
		call	eval_msg_operand
		xor		a, a
		ld		[cs_suppress], a
		jr		c, derr_noarg
		call	msg_bad_operand
		jr		nz, derr_illegal
		ld		a, [final_pass]
		or		a, a
		ret		z
		ld		a, [trial_mode]		; P4: trials count silently
		or		a, a
		jr		z, derr_norm
		ld		hl, [trial_err]
		inc		hl
		ld		[trial_err], hl
		ret
derr_norm:
		ld		hl, [err_count]
		inc		hl
		ld		[err_count], hl
		ld		hl, s_err_pfx
		call	puts
		call	print_msg_raw
		call	print_file_line_suffix
		call	lw_msg_error_line
		ld		hl, s_crlf
		jp		puts
derr_noarg:
		ld		hl, s_toomany
		jp		report_cross_error
derr_illegal:
		ld		hl, s_illegal_param
		jp		report_cross_error

; =============================================================================
;	Operand parser
;	Operand block (12 bytes): +0 kind, +1 code, +2 disp, +3 pfx,
;	+4 paren flag, +5..8 value (LE 32-bit)
; =============================================================================
OPK_NONE	:= 0
OPK_REG8	:= 1				; code: 0B 1C 2D 3E 4H 5L 6(HL) 7A
OPK_IMM		:= 2
OPK_PAIR	:= 3				; code: 0BC 1DE 2HL 3SP 4AF 5IX 6IY
OPK_MEMNN	:= 4
OPK_IXD		:= 5				; (IX+d)/(IY+d): disp byte, pfx 1/2
OPK_MEMBCDE	:= 6				; code 0=(BC) 1=(DE)
OPK_PORTC	:= 7				; (C)
OPK_SPI		:= 9				; I
OPK_SPR		:= 10				; R
OPK_AFS		:= 11				; AF'
OK_KIND		:= 0
OK_CODE		:= 1
OK_DISP		:= 2
OK_PFX		:= 3
OK_PAREN	:= 4
OK_VAL		:= 5
OP_BLKSZ	:= 12

op1_blk:
		space	OP_BLKSZ
op2_blk:
		space	OP_BLKSZ
opw_buf:
		space	16
op_dst:
		dw		0

;	blk_clear: HL = block -> zero 12 bytes
blk_clear:
		ld		b, OP_BLKSZ
		xor		a, a
bc_l:
		ld		[hl], a
		inc		hl
		djnz		bc_l
		ret

;	blk_set: HL = block, B = offset, A = value
blk_set:
		ld		e, b
		ld		d, 0
		add		hl, de
		ld		[hl], a
		ret

;	blk_get: HL = block, B = offset -> A
blk_get:
		ld		e, b
		ld		d, 0
		add		hl, de
		ld		a, [hl]
		ret

;	scan_opw_lp: scan ident at lp into opw_buf (upcased); CY if ident
scan_opw_lp:
		ld		hl, [lp]
		ld		a, [hl]
		call	is_ident_start
		ret		nc
		ld		de, opw_buf
		ld		b, 0
so_l:
		ld		a, [hl]
		call	is_ident_char
		jr		nc, so_done
		call	upcase
		ld		c, a
		ld		a, b
		cp		a, 14
		jr		nc, so_skip
		ld		a, c
		ld		[de], a
		inc		de
		inc		b
so_skip:
		inc		hl
		jr		so_l
so_done:
		xor		a, a
		ld		[de], a
		ld		[lp], hl
		scf
		ret

;	opw_is: DE = literal string -> Z if opw_buf equals it
opw_is:
		ld		hl, opw_buf
		jp		str_eq

;	expect_rparen: skip spaces; consume ')' if present, else expr_error
expect_rparen:
		call	skip_lp_spaces
		call	lp_char
		ld		b, a
		ld		a, [po_bracket]
		or		a, a
		ld		a, ')'
		jr		z, erp_cmp
		ld		a, ']'
erp_cmp:
		cp		a, b
		jr		nz, erp_err
		ld		hl, [lp]
		inc		hl
		ld		[lp], hl
		ret
erp_err:
		ld		a, 1
		ld		[expr_error], a
		ret

;	parse_operand: parse one operand at lp into block [op_dst]
parse_operand:
		ld		hl, [op_dst]
		call	blk_clear
		xor		a, a
		ld		[po_bracket], a
		call	skip_lp_spaces
		call	lp_char
		cp		a, '['
		jr		nz, po_notbrk
		ld		a, 1
		ld		[po_bracket], a
		jp		po_paren
po_notbrk:
		cp		a, '('
		jp		z, po_paren
		; try register word first
		ld		hl, [lp]
		ld		[po_save], hl
		call	scan_opw_lp
		jp		nc, po_expr		; not an ident -> expression
		; register names?
		ld		de, w_a
		call	opw_is
		jp		z, po_reg7
		ld		de, w_b
		call	opw_is
		jp		z, po_reg0
		ld		de, w_c
		call	opw_is
		jp		z, po_reg1
		ld		de, w_d
		call	opw_is
		jp		z, po_reg2
		ld		de, w_e
		call	opw_is
		jp		z, po_reg3
		ld		de, w_h
		call	opw_is
		jp		z, po_reg4
		ld		de, w_l
		call	opw_is
		jp		z, po_reg5
		ld		de, w_i
		call	opw_is
		jp		z, po_spi
		ld		de, w_r
		call	opw_is
		jp		z, po_spr
		ld		de, w_af
		call	opw_is
		jp		z, po_af
		ld		de, w_bc
		call	opw_is
		jp		z, po_pair0
		ld		de, w_de
		call	opw_is
		jp		z, po_pair1
		ld		de, w_hl
		call	opw_is
		jp		z, po_pair2
		ld		de, w_sp
		call	opw_is
		jp		z, po_pair3
		ld		de, w_ix
		call	opw_is
		jp		z, po_pair5
		ld		de, w_iy
		call	opw_is
		jp		z, po_pair6
		ld		de, w_ixh
		call	opw_is
		jp		z, po_ixh
		ld		de, w_ixl
		call	opw_is
		jp		z, po_ixl
		ld		de, w_iyh
		call	opw_is
		jp		z, po_iyh
		ld		de, w_iyl
		call	opw_is
		jp		z, po_iyl
		; not a register: expression starting with that ident
		ld		hl, [po_save]
		ld		[lp], hl
po_expr:
		ld		hl, [lp]
		ld		[ev_ptr], hl
		call	expr_eval		; DE:HL
		ld		bc, [ev_ptr]
		ld		[lp], bc
		ld		[po_val], hl
		ld		[po_val + 2], de
		ld		hl, [op_dst]
		ld		b, OK_KIND
		ld		a, OPK_IMM
		call	blk_set
		ld		hl, [op_dst]
		ld		bc, OK_VAL
		add		hl, bc
		ex		de, hl
		ld		hl, po_val
		ld		bc, 4
		ldir
		ret
po_save:
		dw		0

;	-- register result helpers (block ptr in [op_dst]) --
po_set_reg8:	; A = code
		ld		c, a
		ld		hl, [op_dst]
		ld		b, OK_KIND
		ld		a, OPK_REG8
		call	blk_set
		ld		hl, [op_dst]
		ld		b, OK_CODE
		ld		a, c
		call	blk_set
		ret
po_reg0:
		xor		a, a
		jp		po_set_reg8
po_reg1:
		ld		a, 1
		jp		po_set_reg8
po_reg2:
		ld		a, 2
		jp		po_set_reg8
po_reg3:
		ld		a, 3
		jp		po_set_reg8
po_reg4:
		ld		a, 4
		jp		po_set_reg8
po_reg5:
		ld		a, 5
		jp		po_set_reg8
po_reg7:
		ld		a, 7
		jp		po_set_reg8
po_set_pair:	; A = code
		ld		c, a
		ld		hl, [op_dst]
		ld		b, OK_KIND
		ld		a, OPK_PAIR
		call	blk_set
		ld		hl, [op_dst]
		ld		b, OK_CODE
		ld		a, c
		call	blk_set
		ret
po_pair0:
		xor		a, a
		jp		po_set_pair
po_pair1:
		ld		a, 1
		jp		po_set_pair
po_pair2:
		ld		a, 2
		jp		po_set_pair
po_pair3:
		ld		a, 3
		jp		po_set_pair
po_pair5:
		ld		a, 5
		jp		po_set_pair
po_pair6:
		ld		a, 6
		jp		po_set_pair
po_af:
		; AF or AF'
		call	lp_char
		cp		a, 0x27			; '
		jr		nz, po_af_plain
		ld		hl, [lp]
		inc		hl
		ld		[lp], hl
		ld		hl, [op_dst]
		ld		b, OK_KIND
		ld		a, OPK_AFS
		call	blk_set
		ret
po_af_plain:
		ld		a, 4
		jp		po_set_pair
po_spi:
		ld		hl, [op_dst]
		ld		b, OK_KIND
		ld		a, OPK_SPI
		call	blk_set
		ret
po_spr:
		ld		hl, [op_dst]
		ld		b, OK_KIND
		ld		a, OPK_SPR
		call	blk_set
		ret
po_set_reg8_pfx:	; A = code, C = pfx
		ld		[po_tmpc], a
		ld		hl, [op_dst]
		ld		b, OK_KIND
		ld		a, OPK_REG8
		call	blk_set
		ld		hl, [op_dst]
		ld		b, OK_CODE
		ld		a, [po_tmpc]
		call	blk_set
		ld		hl, [op_dst]
		ld		b, OK_PFX
		ld		a, c
		call	blk_set
		ret
po_tmpc:
		db		0
po_ixh:
		ld		a, 4
		ld		c, 1
		jp		po_set_reg8_pfx
po_ixl:
		ld		a, 5
		ld		c, 1
		jp		po_set_reg8_pfx
po_iyh:
		ld		a, 4
		ld		c, 2
		jp		po_set_reg8_pfx
po_iyl:
		ld		a, 5
		ld		c, 2
		jp		po_set_reg8_pfx

;	po_paren: '(' forms
po_paren:
		ld		hl, [lp]
		ld		[po_open], hl	; position of '(' or '['
		inc		hl
		ld		[lp], hl
		call	skip_lp_spaces
		ld		hl, [lp]
		ld		[po_save], hl
		call	scan_opw_lp
		jr		nc, po_paren_expr
		ld		de, w_bc
		call	opw_is
		jp		z, po_membc
		ld		de, w_de
		call	opw_is
		jp		z, po_memde
		ld		de, w_hl
		call	opw_is
		jp		z, po_memhl
		ld		de, w_c
		call	opw_is
		jp		z, po_portc
		ld		de, w_sp
		call	opw_is
		jp		z, po_memsp
		ld		de, w_ix
		call	opw_is
		jp		z, po_ixd1
		ld		de, w_iy
		call	opw_is
		jp		z, po_ixd2
		; expression in parens
po_paren_expr:
		ld		a, [po_bracket]
		or		a, a
		jr		nz, po_pe_mem	; '[expr]' = memory reference (OPK_MEMNN)
		; '(expr)' is a parenthesized expression in ZMA syntax: re-evaluate
		; the whole operand (including operators after the close paren,
		; e.g. (16 << 4) | vdpport0) as an immediate value.
		ld		hl, [po_open]
		ld		[lp], hl
		jp		po_expr
po_pe_mem:
		ld		hl, [po_save]
		ld		[lp], hl
		ld		hl, [lp]
		ld		[ev_ptr], hl
		call	expr_eval
		ld		bc, [ev_ptr]
		ld		[lp], bc
		; store value: DE:HL
		ld		[po_val], hl
		ld		[po_val + 2], de
		call	expect_rparen
		ld		hl, [op_dst]
		ld		b, OK_KIND
		ld		a, OPK_MEMNN
		call	blk_set
		ld		hl, [op_dst]
		ld		bc, OK_VAL
		add		hl, bc
		ex		de, hl
		ld		hl, po_val
		ld		bc, 4
		ldir
		ret
po_val:
		space	4
po_open:
		dw		0
po_bracket:
		db		0
po_membc:
		ld		a, 0
		jr		po_membcde
po_memde:
		ld		a, 1
po_membcde:
		ld		[po_tmpc], a
		call	expect_rparen
		ld		hl, [op_dst]
		ld		b, OK_KIND
		ld		a, OPK_MEMBCDE
		call	blk_set
		ld		hl, [op_dst]
		ld		b, OK_CODE
		ld		a, [po_tmpc]
		call	blk_set
		ret
po_memhl:
		call	expect_rparen
		ld		a, 6
		call	po_set_reg8
		ld		hl, [op_dst]
		ld		b, OK_PAREN
		ld		a, 1
		call	blk_set
		ret
po_memsp:
		call	expect_rparen
		ld		a, 3
		call	po_set_pair
		ld		hl, [op_dst]
		ld		b, OK_PAREN
		ld		a, 1
		call	blk_set
		ret
po_portc:
		call	expect_rparen
		ld		hl, [op_dst]
		ld		b, OK_KIND
		ld		a, OPK_PORTC
		call	blk_set
		ret
po_ixd1:
		ld		a, 1
		jr		po_ixd
po_ixd2:
		ld		a, 2
po_ixd:
		ld		[po_tmpc], a		; pfx
		; optional +/- expr; no expr when the closer follows
		; immediately ((IX) / [IX] = displacement 0)
		call	skip_lp_spaces
		call	lp_char
		ld		b, a			; B = current char
		ld		a, [po_bracket]
		or		a, a
		ld		a, ')'
		jr		z, po_ixd_zc
		ld		a, ']'
po_ixd_zc:
		cp		a, b
		jr		z, po_ixd_zero
		; expression includes the sign: evaluate from here
		ld		hl, [lp]
		ld		[ev_ptr], hl
		call	expr_eval		; DE:HL = disp value
		ld		bc, [ev_ptr]
		ld		[lp], bc
		ld		a, l
		ld		[po_tmpd], a
		jr		po_ixd_st
po_ixd_zero:
		xor		a, a
		ld		[po_tmpd], a
po_ixd_st:
		call	expect_rparen
		ld		hl, [op_dst]
		ld		b, OK_KIND
		ld		a, OPK_IXD
		call	blk_set
		ld		hl, [op_dst]
		ld		b, OK_DISP
		ld		a, [po_tmpd]
		call	blk_set
		ld		hl, [op_dst]
		ld		b, OK_PFX
		ld		a, [po_tmpc]
		call	blk_set
		ret
po_tmpd:
		db		0

w_a:
		db		"A", 0
w_b:
		db		"B", 0
w_c:
		db		"C", 0
w_d:
		db		"D", 0
w_e:
		db		"E", 0
w_h:
		db		"H", 0
w_l:
		db		"L", 0
w_i:
		db		"I", 0
w_r:
		db		"R", 0
w_af:
		db		"AF", 0
w_bc:
		db		"BC", 0
w_de:
		db		"DE", 0
w_hl:
		db		"HL", 0
w_sp:
		db		"SP", 0
w_ix:
		db		"IX", 0
w_iy:
		db		"IY", 0
w_ixh:
		db		"IXH", 0
w_ixl:
		db		"IXL", 0
w_iyh:
		db		"IYH", 0
w_iyl:
		db		"IYL", 0

;	parse_two_operands: parse op1; if ',' then parse op2.
;	-> [n_ops] = 1 or 2
n_ops:
		db		0
parse_two_operands:
		ld		hl, op1_blk
		ld		[op_dst], hl
		call	parse_operand
		ld		a, 1
		ld		[n_ops], a
		call	skip_lp_spaces
		call	lp_char
		cp		a, ','
		ret		nz
		ld		hl, [lp]
		inc		hl
		ld		[lp], hl
		ld		hl, op2_blk
		ld		[op_dst], hl
		call	parse_operand
		ld		a, 2
		ld		[n_ops], a
		ret

; =============================================================================
;	Instruction encoder
; =============================================================================

;	emit_pfx: A = pfx (0/1/2): emit DD/FD if needed
emit_pfx:
		cp		a, 1
		jr		z, ep_dd
		cp		a, 2
		jr		z, ep_fd
		ret
ep_dd:
		ld		a, 0xDD
		jp		emit8
ep_fd:
		ld		a, 0xFD
		jp		emit8

;	emit_pfx1 / emit_pfx2: prefix from op1/op2 block
emit_pfx1:
		ld		a, [op1_blk + OK_PFX]
		jr		emit_pfx
emit_pfx2:
		ld		a, [op2_blk + OK_PFX]
		jr		emit_pfx

bad_op:
		ld		hl, s_badop
		call	err_line
		ret

;	val1 -> DE:HL ; val2 -> DE:HL (clobbers)
load_val1:
		ld		hl, [op1_blk + OK_VAL]
		ld		de, [op1_blk + OK_VAL + 2]
		ret
load_val2:
		ld		hl, [op2_blk + OK_VAL]
		ld		de, [op2_blk + OK_VAL + 2]
		ret

;	emit_imm16_of: block value (op in HL) low 16 bits
emit_val16:
		; HL = block ptr
		ld		bc, OK_VAL
		add		hl, bc
		ld		a, [hl]
		inc		hl
		push	hl
		call	emit8
		pop		hl
		ld		a, [hl]
		call	emit8
		ret

;	try_parse_cond: if lp at a condition word followed by ',' (or EOL
;	when [tpc_eol_ok]=1): consume word (and ',' if present for JP/JR/
;	CALL), return CY with code in [tpc_code]. Else NC, lp unchanged.
tpc_code:
		db		0
tpc_eol_ok:
		db		0
tpc_save:
		dw		0
try_parse_cond:
		ld		hl, [lp]
		ld		[tpc_save], hl
		call	scan_opw_lp
		jr		nc, tpc_no
		ld		de, cw_nz
		call	opw_is
		jr		z, tpc_0
		ld		de, cw_z
		call	opw_is
		jr		z, tpc_1
		ld		de, cw_nc
		call	opw_is
		jr		z, tpc_2
		ld		de, cw_c
		call	opw_is
		jr		z, tpc_3
		ld		de, cw_po
		call	opw_is
		jr		z, tpc_4
		ld		de, cw_pe
		call	opw_is
		jr		z, tpc_5
		ld		de, cw_p
		call	opw_is
		jr		z, tpc_6
		ld		de, cw_m
		call	opw_is
		jr		z, tpc_7
tpc_no:
		ld		hl, [tpc_save]
		ld		[lp], hl
		or		a, a
		ret
tpc_0:
		xor		a, a
		jr		tpc_have
tpc_1:
		ld		a, 1
		jr		tpc_have
tpc_2:
		ld		a, 2
		jr		tpc_have
tpc_3:
		ld		a, 3
		jr		tpc_have
tpc_4:
		ld		a, 4
		jr		tpc_have
tpc_5:
		ld		a, 5
		jr		tpc_have
tpc_6:
		ld		a, 6
		jr		tpc_have
tpc_7:
		ld		a, 7
tpc_have:
		ld		[tpc_code], a
		; next char must be ',' for JP/JR/CALL; when tpc_eol_ok also
		; allow end of line (RET cc)
		call	skip_lp_spaces
		call	lp_char
		cp		a, ','
		jr		z, tpc_comma
		ld		a, [tpc_eol_ok]
		or		a, a
		jr		z, tpc_no
		call	lp_at_end
		jr		nz, tpc_no
		scf
		ret
tpc_comma:
		ld		hl, [lp]
		inc		hl
		ld		[lp], hl
		scf
		ret
cw_nz:
		db		"NZ", 0
cw_z:
		db		"Z", 0
cw_nc:
		db		"NC", 0
cw_c:
		db		"C", 0
cw_po:
		db		"PO", 0
cw_pe:
		db		"PE", 0
cw_p:
		db		"P", 0
cw_m:
		db		"M", 0

;	check_ops_ok: after operand parsing, convert expr flags to errors
check_ops_ok:
		call	check_expr_err
		call	check_undef
		ret

;	encode_instruction: mnem_buf dispatch
encode_instruction:
		; fixed two-byte/one-byte no-operand instructions via table
		ld		hl, fixed_table
ei_ft:
		ld		a, [hl]
		or		a, a
		jr		z, ei_not_fixed
		; compare name at HL with mnem_buf
		push	hl
		ld		de, mnem_buf
		call	str_eq
		pop		hl
		jr		z, ei_fixed_found
		; skip entry: name (NUL-term) + count + bytes
ei_skip:
		ld		a, [hl]
		inc		hl
		or		a, a
		jr		nz, ei_skip
		ld		a, [hl]			; count
		inc		hl
		ld		b, a
		ld		e, b
		ld		d, 0
		add		hl, de
		jr		ei_ft
ei_fixed_found:
		; HL points at name start; find its end
ei_ff:
		ld		a, [hl]
		inc		hl
		or		a, a
		jr		nz, ei_ff
		ld		a, [hl]			; count
		inc		hl
		ld		b, a
ei_ffl:
		ld		a, [hl]
		inc		hl
		push	hl
		push	bc
		call	emit8
		pop		bc
		pop		hl
		djnz		ei_ffl
		ret
ei_not_fixed:
		; mnemonic dispatch chain
		ld		hl, mnem_buf
		ld		de, m_mulub
		call	str_eq
		jp		z, enc_mulub
		ld		hl, mnem_buf
		ld		de, m_muluw
		call	str_eq
		jp		z, enc_muluw
		ld		hl, mnem_buf
		ld		de, m_ld
		call	str_eq
		jp		z, enc_ld
		ld		hl, mnem_buf
		ld		de, m_push
		call	str_eq
		jp		z, enc_push
		ld		hl, mnem_buf
		ld		de, m_pop
		call	str_eq
		jp		z, enc_pop
		ld		hl, mnem_buf
		ld		de, m_add
		call	str_eq
		jp		z, ei_add
		ld		hl, mnem_buf
		ld		de, m_adc
		call	str_eq
		jp		z, ei_adc
		ld		hl, mnem_buf
		ld		de, m_sub
		call	str_eq
		jp		z, ei_sub
		ld		hl, mnem_buf
		ld		de, m_sbc
		call	str_eq
		jp		z, ei_sbc
		ld		hl, mnem_buf
		ld		de, m_and
		call	str_eq
		jp		z, ei_and
		ld		hl, mnem_buf
		ld		de, m_or
		call	str_eq
		jp		z, ei_or
		ld		hl, mnem_buf
		ld		de, m_xor
		call	str_eq
		jp		z, ei_xor
		ld		hl, mnem_buf
		ld		de, m_cp
		call	str_eq
		jp		z, ei_cp
		ld		hl, mnem_buf
		ld		de, m_inc
		call	str_eq
		jp		z, enc_inc
		ld		hl, mnem_buf
		ld		de, m_dec
		call	str_eq
		jp		z, enc_dec
		ld		hl, mnem_buf
		ld		de, m_jp
		call	str_eq
		jp		z, enc_jp
		ld		hl, mnem_buf
		ld		de, m_jr
		call	str_eq
		jp		z, enc_jr
		ld		hl, mnem_buf
		ld		de, m_djnz
		call	str_eq
		jp		z, enc_djnz
		ld		hl, mnem_buf
		ld		de, m_call
		call	str_eq
		jp		z, enc_call
		ld		hl, mnem_buf
		ld		de, m_ret
		call	str_eq
		jp		z, enc_ret
		ld		hl, mnem_buf
		ld		de, m_rst
		call	str_eq
		jp		z, enc_rst
		ld		hl, mnem_buf
		ld		de, m_in
		call	str_eq
		jp		z, enc_in
		ld		hl, mnem_buf
		ld		de, m_out
		call	str_eq
		jp		z, enc_out
		ld		hl, mnem_buf
		ld		de, m_ex
		call	str_eq
		jp		z, enc_ex
		ld		hl, mnem_buf
		ld		de, m_im
		call	str_eq
		jp		z, enc_im
		ld		hl, mnem_buf
		ld		de, m_bit
		call	str_eq
		jp		z, ei_bit
		ld		hl, mnem_buf
		ld		de, m_res
		call	str_eq
		jp		z, ei_res
		ld		hl, mnem_buf
		ld		de, m_set
		call	str_eq
		jp		z, ei_set
		ld		hl, mnem_buf
		ld		de, m_rlc
		call	str_eq
		jp		z, ei_rlc
		ld		hl, mnem_buf
		ld		de, m_rrc
		call	str_eq
		jp		z, ei_rrc
		ld		hl, mnem_buf
		ld		de, m_rl
		call	str_eq
		jr		z, ei_rl
		ld		hl, mnem_buf
		ld		de, m_rr
		call	str_eq
		jr		z, ei_rr
		ld		hl, mnem_buf
		ld		de, m_sla
		call	str_eq
		jr		z, ei_sla
		ld		hl, mnem_buf
		ld		de, m_sra
		call	str_eq
		jr		z, ei_sra
		ld		hl, mnem_buf
		ld		de, m_sll
		call	str_eq
		jr		z, ei_sll
		ld		hl, mnem_buf
		ld		de, m_srl
		call	str_eq
		jr		z, ei_srl
		; unknown mnemonic
		ld		hl, s_badmnem
		call	err_line
		ret
ei_add:
		ld		a, 0
		jp		enc_alu
ei_adc:
		ld		a, 1
		jp		enc_alu
ei_sub:
		ld		a, 2
		jp		enc_alu
ei_sbc:
		ld		a, 3
		jp		enc_alu
ei_and:
		ld		a, 4
		jp		enc_alu
ei_xor:
		ld		a, 5
		jp		enc_alu
ei_or:
		ld		a, 6
		jp		enc_alu
ei_cp:
		ld		a, 7
		jp		enc_alu
ei_bit:
		ld		a, 0x40
		jp		enc_bit
ei_res:
		ld		a, 0x80
		jp		enc_bit
ei_set:
		ld		a, 0xC0
		jp		enc_bit
ei_rlc:
		ld		a, 0x00
		jp		enc_shift
ei_rrc:
		ld		a, 0x08
		jp		enc_shift
ei_rl:
		ld		a, 0x10
		jp		enc_shift
ei_rr:
		ld		a, 0x18
		jp		enc_shift
ei_sla:
		ld		a, 0x20
		jp		enc_shift
ei_sra:
		ld		a, 0x28
		jp		enc_shift
ei_sll:
		ld		a, 0x30
		jp		enc_shift
ei_srl:
		ld		a, 0x38
		jp		enc_shift
s_badmnem:
		db		"bad mnemonic.", 0

;	fixed_table: entries of: name, 0, count, bytes... ; end: single 0
fixed_table:
		db		"NOP", 0, 1, 0x00
		db		"HALT", 0, 1, 0x76
		db		"DI", 0, 1, 0xF3
		db		"EI", 0, 1, 0xFB
		db		"EXX", 0, 1, 0xD9
		db		"CPL", 0, 1, 0x2F
		db		"CCF", 0, 1, 0x3F
		db		"SCF", 0, 1, 0x37
		db		"DAA", 0, 1, 0x27
		db		"RLCA", 0, 1, 0x07
		db		"RLA", 0, 1, 0x17
		db		"RRCA", 0, 1, 0x0F
		db		"RRA", 0, 1, 0x1F
		db		"NEG", 0, 2, 0xED, 0x44
		db		"RETI", 0, 2, 0xED, 0x4D
		db		"RETN", 0, 2, 0xED, 0x45
		db		"RLD", 0, 2, 0xED, 0x6F
		db		"RRD", 0, 2, 0xED, 0x67
		db		"LDI", 0, 2, 0xED, 0xA0
		db		"LDIR", 0, 2, 0xED, 0xB0
		db		"LDD", 0, 2, 0xED, 0xA8
		db		"LDDR", 0, 2, 0xED, 0xB8
		db		"CPI", 0, 2, 0xED, 0xA1
		db		"CPIR", 0, 2, 0xED, 0xB1
		db		"CPD", 0, 2, 0xED, 0xA9
		db		"CPDR", 0, 2, 0xED, 0xB9
		db		"INI", 0, 2, 0xED, 0xA2
		db		"INIR", 0, 2, 0xED, 0xB2
		db		"IND", 0, 2, 0xED, 0xAA
		db		"INDR", 0, 2, 0xED, 0xBA
		db		"OUTI", 0, 2, 0xED, 0xA3
		db		"OTIR", 0, 2, 0xED, 0xB3
		db		"OUTD", 0, 2, 0xED, 0xAB
		db		"OTDR", 0, 2, 0xED, 0xBB
		db		0

m_mulub:
		db		"MULUB", 0
m_muluw:
		db		"MULUW", 0

;	enc_mulub: MULUB A, r (r = B/C/D/E) -> ED C1|(r<<3)   [R800]
;	enc_muluw: MULUW HL, BC -> ED C3 ; MULUW HL, SP -> ED C5
enc_mulub:
		call	parse_two_operands
		call	check_ops_ok
		ld		a, [n_ops]
		cp		a, 2
		jp		nz, bad_op
		ld		a, [op1_blk + OK_KIND]
		cp		a, OPK_REG8
		jp		nz, bad_op
		ld		a, [op1_blk + OK_PFX]
		or		a, a
		jp		nz, bad_op
		ld		a, [op1_blk + OK_CODE]
		cp		a, 7				; A
		jp		nz, bad_op
		ld		a, [op2_blk + OK_KIND]
		cp		a, OPK_REG8
		jp		nz, bad_op
		ld		a, [op2_blk + OK_PFX]
		or		a, a
		jp		nz, bad_op
		ld		a, [op2_blk + OK_CODE]
		cp		a, 4				; B/C/D/E only
		jp		nc, bad_op
		rlca
		rlca
		rlca					; code << 3
		or		a, 0xC1
		ld		[mul_b2], a		; emit8 clobbers B; keep byte in a cell
		ld		a, 0xED
		call	emit8
		ld		a, [mul_b2]
		jp		emit8
mul_b2:
		db		0
enc_muluw:
		call	parse_two_operands
		call	check_ops_ok
		ld		a, [n_ops]
		cp		a, 2
		jp		nz, bad_op
		ld		a, [op1_blk + OK_KIND]
		cp		a, OPK_PAIR
		jp		nz, bad_op
		ld		a, [op1_blk + OK_CODE]
		cp		a, 2				; HL
		jp		nz, bad_op
		ld		a, [op2_blk + OK_KIND]
		cp		a, OPK_PAIR
		jp		nz, bad_op
		ld		a, [op2_blk + OK_CODE]
		or		a, a
		jr		z, emw_bc			; BC -> ED C3
		cp		a, 3				; SP -> ED C5
		jp		nz, bad_op
		ld		a, 0xED
		call	emit8
		ld		a, 0xC5
		jp		emit8
emw_bc:
		ld		a, 0xED
		call	emit8
		ld		a, 0xC3
		jp		emit8
m_ld:
		db		"LD", 0
m_push:
		db		"PUSH", 0
m_pop:
		db		"POP", 0
m_add:
		db		"ADD", 0
m_adc:
		db		"ADC", 0
m_sub:
		db		"SUB", 0
m_sbc:
		db		"SBC", 0
m_and:
		db		"AND", 0
m_or:
		db		"OR", 0
m_xor:
		db		"XOR", 0
m_cp:
		db		"CP", 0
m_inc:
		db		"INC", 0
m_dec:
		db		"DEC", 0
m_jp:
		db		"JP", 0
m_jr:
		db		"JR", 0
m_djnz:
		db		"DJNZ", 0
m_call:
		db		"CALL", 0
m_ret:
		db		"RET", 0
m_rst:
		db		"RST", 0
m_in:
		db		"IN", 0
m_out:
		db		"OUT", 0
m_ex:
		db		"EX", 0
m_im:
		db		"IM", 0
m_bit:
		db		"BIT", 0
m_res:
		db		"RES", 0
m_set:
		db		"SET", 0
m_rlc:
		db		"RLC", 0
m_rrc:
		db		"RRC", 0
m_rl:
		db		"RL", 0
m_rr:
		db		"RR", 0
m_sla:
		db		"SLA", 0
m_sra:
		db		"SRA", 0
m_sll:
		db		"SLL", 0
m_srl:
		db		"SRL", 0


; =============================================================================
;	P3: MACRO / REPEAT / LINK implementation.
;
;	Semantics oracle: cross ZMA v1.0.20 C++ sources.
;	- Macros register in a persistent pool table; bodies are captured
;	  per pass into the arena (dedicated mapper segments, reset each
;	  pass).  An invocation expands the body with word-level parameter
;	  substitution into xbuf and pushes a kind-1 text source entry.
;	  '@' parameters stringify their argument tokens (uppercased,
;	  single-space joined) into one string literal; plain parameters
;	  splice their token sequence verbatim.
;	- REPEAT captures its body into the arena and pushes a kind-2
;	  text entry that re-reads the region N times.  The count
;	  expression freezes at its first successful evaluation (cross
;	  is_counter_end_fixed) in a persistent site record.
;	- LINK registers trigger names (persistent pool table); a symbol
;	  lookup candidate equal to a trigger marks the block used
;	  (cross check_link).  The body is captured per pass and replayed
;	  (kind-3 entry) only when used.
;	- SCOPE + @MACRO + @REPEAT share scope_depth/scope_names, capped
;	  at SCOPE_MAX = 8 (author decision, 2026-11-10).
;
;	Register discipline: rr8/rr16/rr32/rw8/rw16/rw32 and off_copy_add
;	destroy BC/DE/HL.  pio_read8/pio_write8/apio_read8 preserve
;	HL/BC (pio_write8 also DE).  Callers keep live values in cells.
; =============================================================================

; ---------------------------------------------------------------------------
;	p3_init: clear P3 tables/counters (called once from asm_main)
; ---------------------------------------------------------------------------
p3_init:
		ld		hl, 0
		ld		a, l
		ld		[if_any_flagged], a	; P4: audit trigger memory
		ld		[if_head], hl		; P4: IF head-record chain
		ld		[if_head + 2], hl
		ld		[cs_head], hl		; P4: character-set chain
		ld		[cs_head + 2], hl
		ld		[mac_head], hl
		ld		[mac_head + 2], hl
		ld		[macsite_head], hl
		ld		[macsite_head + 2], hl
		ld		[rep_head], hl
		ld		[rep_head + 2], hl
		ld		[lnk_blk_head], hl
		ld		[lnk_blk_head + 2], hl
		ld		[lnk_trg_head], hl
		ld		[lnk_trg_head + 2], hl
		ld		[mac_inst_ctr], hl
		ld		[rep_scope_ctr], hl
		ret

mac_head:
		space	4
macsite_head:
		space	4
rep_head:
		space	4
lnk_blk_head:
		space	4
lnk_trg_head:
		space	4
mac_inst_ctr:
		dw		0
rep_scope_ctr:
		dw		0

; ---------------------------------------------------------------------------
;	Arena: ARENA_MAXSEG dedicated mapper segments (64 KB) holding
;	per-pass captured texts.  apio is a pio-like 32-bit cursor.
; ---------------------------------------------------------------------------
ARENA_MAXSEG	:= 4
arena_segs:
		space	ARENA_MAXSEG
arena_nsegs:
		db		0
arena_top:
		space	4
apio:
		space	4
apw_val:
		db		0

arena_init:
		; The capture arena lives in the TOP segments of the symbol
		; pool's mapper allocation (this machine class has too few
		; free segments for a separate allocation): the pool's
		; allocation limit is lowered by the arena segment count.
		; arena_nsegs = 2 (pool >= 5), 1 (pool 3-4), 0 (pool <= 2).
		ld		a, [pool_nsegs]
		cp		a, 5
		jr		c, ai_small
		ld		a, 2
		jr		ai_set
ai_small:
		cp		a, 3
		jr		c, ai_none
		ld		a, 1
		jr		ai_set
ai_none:
		xor		a, a
ai_set:
		ld		[arena_nsegs], a
		ld		b, a
		ld		a, [pool_nsegs]
		sub		a, b
		ld		[arena_seg0], a		; first pool segment used by arena
		ld		[pool_limit_segs], a
		ret
arena_seg0:
		db		0

;	apio_setup:
apio_setup:
		ld		a, [apio + 1]
		rlca
		rlca
		and		a, 3				; arena segment index (offset bits 14-15)
		ld		hl, arena_seg0
		add		a, [hl]			; + first arena segment in the pool
		ld		hl, pool_segs
		add		a, l
		ld		l, a
		jr		nc, aps_nc
		inc		h
aps_nc:
		ld		a, [hl]
		ld		[prs_seg], a
		ld		a, [apio]
		ld		l, a
		ld		a, [apio + 1]
		and		a, 0x3F
		or		a, 0x80
		ld		h, a
		ret

;	apio_read8: A = byte at apio (only A/F destroyed)
apio_read8:
		push	hl
		push	bc
		call	apio_setup
		call	map_rd_seg
		pop		bc
		pop		hl
		ret

;	apio_write8: byte in [apw_val] written at apio (only A/F destroyed)
apio_write8:
		push	hl
		push	de
		push	bc
		call	apio_setup
		ld		a, [apw_val]
		ld		e, a
		call	map_wr_seg
		pop		bc
		pop		de
		pop		hl
		ret

;	apio_inc: apio += 1
apio_inc:
		push	hl
		ld		hl, apio
		inc		[hl]
		jr		nz, api_1
		inc		hl
		inc		[hl]
		jr		nz, api_1
		inc		hl
		inc		[hl]
api_1:
		pop		hl
		ret

;	apio_set: DE:HL -> apio ; apio_get: apio -> DE:HL
apio_set:
		ld		[apio], hl
		ld		[apio + 2], de
		ret
apio_get:
		ld		hl, [apio]
		ld		de, [apio + 2]
		ret

;	arena_put8: A = byte appended at arena_top; fatal if full
arena_put8:
		ld		[apw_val], a
		ld		a, [arena_nsegs]
		or		a, a
		jr		z, ap8_full
		ld		a, [arena_top + 2]
		ld		b, a
		ld		a, [arena_top + 3]
		or		a, b
		jr		nz, ap8_full		; offset >= 64 KB
		ld		a, [arena_top + 1]
		and		a, 0xC0
		rlca
		rlca						; current segment index (0..3)
		ld		e, a
		ld		a, [arena_nsegs]
		cp		a, e				; full if nsegs <= segment
		jr		c, ap8_full
		jr		z, ap8_full
		ld		hl, [arena_top]
		ld		de, [arena_top + 2]
		call	apio_set
		call	apio_write8
		call	apio_inc
		call	apio_get
		ld		[arena_top], hl
		ld		[arena_top + 2], de
		ret
ap8_full:
		ld		hl, s_arena_full
		call	puts
		jp		fatal_exit
s_arena_full:
		db		"Out of memory (capture arena).", 13, 10, 0

;	arena_get_top: DE:HL = arena_top
arena_get_top:
		ld		hl, [arena_top]
		ld		de, [arena_top + 2]
		ret

; ---------------------------------------------------------------------------
;	Pool record field access via rec_cur (4-byte record offset).
;	rr8: A=disp -> A=byte.  rr16: A=disp -> HL.  ;	rr32x: A=disp -> value in rr32_buf (4 bytes LE); destroys BC/DE/HL
rr32_buf:
		space	4
rec_cur:
		space	4
rwv:
		db		0
rr16_lo:
		db		0

;	rr8: A = disp -> A = byte at rec_cur + disp
rr8:
		ld		hl, rec_cur
		call	off_copy_add
		call	pio_read8
		ret

;	rr16: A = disp -> HL = word at rec_cur + disp
rr16:
		ld		hl, rec_cur
		call	off_copy_add
		call	pio_read8
		ld		[rr16_lo], a
		call	pio_inc
		call	pio_read8
		ld		h, a
		ld		a, [rr16_lo]
		ld		l, a
		ret

rr32x:
		ld		hl, rec_cur
		call	off_copy_add
		ld		hl, rr32_buf
		ld		b, 4
rr32x_l:
		call	pio_read8
		ld		[hl], a
		inc		hl
		call	pio_inc
		djnz	rr32x_l
		ret

rw8:
		ld		hl, rec_cur
		call	off_copy_add
		ld		a, [rwv]
		ld		[pw_val], a
		call	pio_write8
		ret

rw16:
		ld		[rwv16], hl
		ld		hl, rec_cur
		call	off_copy_add
		ld		a, [rwv16]
		ld		[pw_val], a
		call	pio_write8
		call	pio_inc
		ld		a, [rwv16 + 1]
		ld		[pw_val], a
		call	pio_write8
		ret
rwv16:
		dw		0

rw32:
		ld		[rwv32], hl
		ld		[rwv32 + 2], de
		ld		hl, rec_cur
		call	off_copy_add
		ld		hl, rwv32
		ld		b, 4
rw32_l:
		ld		a, [hl]
		inc		hl
		ld		[pw_val], a
		push	hl
		push	bc
		call	pio_write8
		call	pio_inc
		pop		bc
		pop		hl
		djnz	rw32_l
		ret
rwv32:
		space	4

;	rec_new: HL = size -> new zeroed pool record; rec_cur = DE:HL
;	= its offset.  Destroys BC/DE/HL.
rec_new:
		ld		[rn_size], hl
		call	pool_alloc			; DE:HL = old top
		ld		[rec_cur], hl
		ld		[rec_cur + 2], de
		push	hl
		push	de
		ld		bc, [rn_size]
		call	pool_zero			; DE:HL = offset, BC = count
		pop		de
		pop		hl
		ret
rn_size:
		dw		0

;	pool_zero: DE:HL = offset, BC = count -> zero-fill via pio
pool_zero:
		call	pio_set
		xor		a, a
		ld		[pw_val], a
pz_l:
		ld		a, b
		or		a, c
		ret		z
		push	bc
		call	pio_write8
		call	pio_inc
		pop		bc
		dec		bc
		jr		pz_l

; ---------------------------------------------------------------------------
;	Scope stack helpers (SCOPE / @MACRO / @REPEAT share the stack)
; ---------------------------------------------------------------------------

;	scope_push_name: HL = NUL-terminated name -> CY if nesting cap
;	reached (error reported).  Name truncated to 32 chars.
scope_push_name:
		ld		[spn_src], hl		; (the offset math below destroys HL)
		ld		a, [scope_depth]
		cp		a, SCOPE_MAX
		jr		nc, spn_deep
		ld		l, a
		ld		h, 0
		add		hl, hl
		add		hl, hl
		add		hl, hl
		add		hl, hl
		add		hl, hl				; *32
		ld		e, a
		ld		d, 0
		add		hl, de				; *33
		ld		de, scope_names
		add		hl, de
		ex		de, hl				; DE = destination slot
		ld		hl, [spn_src]		; HL = source name
		ld		b, 32
spn_cp:
		ld		a, [hl]
		ld		[de], a
		or		a, a
		jr		z, spn_cpd
		inc		hl
		inc		de
		djnz	spn_cp
		xor		a, a
		ld		[de], a
spn_cpd:
		ld		a, [scope_depth]
		inc		a
		ld		[scope_depth], a
		call	lw_scope_enter
		or		a, a				; NC
		ret
spn_src:
		dw		0
spn_deep:
		push	hl
		ld		hl, s_scope_deep
		call	err_line
		pop		hl
		scf
		ret

;	scope_pop: log exit line, then depth--
scope_pop:
		call	lw_scope_exit
		ld		hl, scope_depth
		dec		[hl]
		ret

;	make_auto_name: prefix (HL, NUL string) + decimal index (BC)
;	-> p3_sname (NUL-terminated)
p3_sname:
		space	40
sn_num:
		space	4
make_auto_name:
		ld		de, p3_sname
man_cp:
		ld		a, [hl]
		ld		[de], a
		or		a, a
		jr		z, man_num
		inc		hl
		inc		de
		jr		man_cp
man_num:
		ld		[sn_num], bc
		ld		hl, 0
		ld		[sn_num + 2], hl
		ld		[man_de], de			; digits destination
		ld		hl, sn_num
		call	dec32_to_buf		; digits at DE, BC = count
		ld		hl, [man_de]
		add		hl, bc
		ld		[hl], 0
		ret
man_de:
		dw		0

; ---------------------------------------------------------------------------
;	Context stack + site identity
; ---------------------------------------------------------------------------
ctx_stack:
		space	32				; 16 words
ctx_sp:
		db		0

;	ctx_push: HL = marker word
ctx_tmp:
		dw		0
ctx_push:
		ld		[ctx_tmp], hl
		ld		a, [ctx_sp]
		cp		a, 16
		ret		nc
		ld		l, a
		ld		h, 0
		add		hl, hl
		ld		de, ctx_stack
		add		hl, de
		ld		a, [ctx_tmp]
		ld		[hl], a
		inc		hl
		ld		a, [ctx_tmp + 1]
		ld		[hl], a
		ld		a, [ctx_sp]
		inc		a
		ld		[ctx_sp], a
		ret

;	ctx_hash: -> HL = hash over the context stack
ctx_hash:
		ld		hl, 0
		ld		a, [ctx_sp]
		or		a, a
		ret		z
		ld		b, a
		ld		de, ctx_stack
ch_l:
		push	bc
		push	de
		ld		c, l
		ld		b, h				; BC = hash
		add		hl, hl
		add		hl, hl
		add		hl, hl
		add		hl, hl
		add		hl, hl				; hash*32
		add		hl, bc				; hash*33
		ex		de, hl				; DE = hash*33, HL = stack ptr
		ld		c, [hl]
		inc		hl
		ld		b, [hl]				; BC = marker word
		ex		de, hl
		add		hl, bc
		pop		de
		inc		de
		inc		de
		pop		bc
		djnz	ch_l
		ret

site_fhash:
		dw		0
site_line:
		dw		0
site_ctx:
		dw		0

;	cur_site: site identity of the line currently being processed
cur_site:
		ld		hl, [cur_ent]
		ld		de, E_LINE
		add		hl, de
		ld		e, [hl]
		inc		hl
		ld		d, [hl]
		ld		[site_line], de
		; P4 bug #63: inside a text entry (MACRO/REPEAT/LINK
		; body) every line shares the invocation E_LINE, so
		; IF/ELSEIF/ELSE lines of one block collapsed onto a
		; single site: if_find_rec matched the IF branch's own
		; record for the ELSE branch and dir_else linked its
		; BR_BNEXT to itself, looping if_close_block forever.
		; Text-entry lines are identified by their distance
		; from the body end (TEND - TPOS): distinct per line,
		; stable across passes and replays.
		ld		hl, [cur_ent]
		ld		de, E_KIND
		add		hl, de
		ld		a, [hl]
		or		a, a
		jr		z, cs_nam
		inc		hl
		ld		e, [hl]
		inc		hl
		ld		d, [hl]
		inc		hl
		inc		hl
		inc		hl
		ld		c, [hl]
		inc		hl
		ld		b, [hl]
		ld		h, b
		ld		l, c
		or		a, a
		sbc		hl, de
		ld		[site_line], hl
cs_nam:
		ld		hl, [cur_ent]
		ld		de, E_NAME
		add		hl, de
		ld		de, 0
cs_hl:
		ld		a, [hl]
		or		a, a
		jr		z, cs_done
		inc		hl
		push	hl
		ld		h, d
		ld		l, e
		push	hl
		add		hl, hl
		add		hl, hl
		add		hl, hl
		add		hl, hl
		add		hl, hl
		pop		de
		add		hl, de
		ld		e, a
		ld		d, 0
		add		hl, de
		ex		de, hl
		pop		hl
		jr		cs_hl
cs_done:
		ld		[site_fhash], de
		call	ctx_hash
		ld		[site_ctx], hl
		ret

;	site_match: compares the 6 site bytes at rec_cur + [se_disp]
;	site_match: HL = rec base offset ptr cell is rec_cur;
;	compares the 6 site bytes at rec_cur + [se_disp] with cur_site.
;	-> Z if equal.  Destroys BC/DE/HL.
se_disp:
		db		0
site_match:
		ld		hl, rec_cur
		ld		a, [se_disp]
		call	off_copy_add
		ld		hl, site_fhash
		ld		b, 6
sm_l:
		call	pio_read8
		cp		a, [hl]
		ret		nz
		inc		hl
		call	pio_inc
		djnz	sm_l
		xor		a, a				; all equal: force Z (pio_inc clobbers F)
		ret

;	site_store: write cur_site 6 bytes at rec_cur + [se_disp]
site_store:
		ld		hl, rec_cur
		ld		a, [se_disp]
		call	off_copy_add
		ld		hl, site_fhash
		ld		b, 6
ss_l:
		ld		a, [hl]
		inc		hl
		ld		[pw_val], a
		push	hl
		push	bc
		call	pio_write8
		call	pio_inc
		pop		bc
		pop		hl
		djnz	ss_l
		ret

; ---------------------------------------------------------------------------
;	Tokenizer (cross get_word_split compatible, over a RAM line).
;	Token entry (4 bytes): +0 span ptr (dw), +2 length (db),
;	+3 type (db): 0 = word/operator, 1 = string literal, 2 = char.
;	A ';' at a token boundary ends the stream.  Strings and chars
;	keep their raw source span (quotes included).
; ---------------------------------------------------------------------------
TOK_MAX		:= 64
tok_tab:
		space	TOK_MAX * 4
tok_count:
		db		0
tok_tab_ptr:
		dw		0
tok_type:
		db		0
tok_len:
		db		0

;	tok_one: HL = anywhere in a line -> skip spaces; if a token
;	follows: CY, HL = end of token, tok_type set, HL_start preserved
;	by caller via push.  If none (NUL/';'): NC.
tok_one:
to_skip:
		ld		a, [hl]
		cp		a, ' '
		jr		z, to_sk1
		cp		a, 9
		jr		nz, to_at
to_sk1:
		inc		hl
		jr		to_skip
to_at:
		or		a, a
		ret		z				; NC (Z implies no token; caller tests CY)
		ld		[tok_start_ptr], hl
		cp		a, ';'
		jr		z, to_none
		cp		a, '"'
		jr		z, to_str
		cp		a, 0x27			; single quote
		jp		z, to_chr
		; word chars start? [A-Za-z0-9_]
		call	tok_is_word_start
		jr		c, to_word
		cp		a, '$'
		jr		z, to_dollar
		; operator: try 2-char operators
		push	hl
		inc		hl
		ld		a, [hl]
		ld		[to_op2], a
		pop		hl
		ld		a, [hl]
		call	tok_op2_match		; CY if [hl],[to_op2] is a 2-char op
		jr		nc, to_op1
		inc		hl
to_op1:
		inc		hl
		xor		a, a
		ld		[tok_type], a
		scf
		ret
to_none:
		or		a, a				; NC
		ret
to_word:
		; consume [A-Za-z0-9_']
tw_l:
		inc		hl
		ld		a, [hl]
		call	tok_is_word_char
		jr		c, tw_l
		xor		a, a
		ld		[tok_type], a
		scf
		ret
to_dollar:
		inc		hl
		ld		a, [hl]
		cp		a, '$'
		jr		z, to_op1			; "$$" token (type 0)
		; $hex: consume [0-9A-Fa-f_]
td_l:
		ld		a, [hl]
		call	tok_is_hex_char
		jr		nc, td_done
		inc		hl
		jr		td_l
td_done:
		xor		a, a
		ld		[tok_type], a
		scf
		ret
to_str:
		ld		a, 1
		ld		[tok_type], a
		inc		hl				; past opening quote
ts_l:
		ld		a, [hl]
		or		a, a
		jr		z, ts_ret			; unterminated: ends at NUL
		cp		a, '"'
		jr		z, ts_end
		cp		a, 0x5C			; backslash
		jr		z, ts_esc
		call	tok_is_sjis1
		jr		nc, ts_n1
		inc		hl				; SJIS lead: consume pair
		ld		a, [hl]
		or		a, a
		jr		z, ts_ret
ts_n1:
		inc		hl
		jr		ts_l
ts_esc:
		inc		hl
		ld		a, [hl]
		or		a, a
		jr		z, ts_ret
		inc		hl
		jr		ts_l
ts_end:
		inc		hl				; past closing quote
ts_ret:
		scf
		ret
to_chr:
		ld		a, 2
		ld		[tok_type], a
		inc		hl				; -> s[1]
		ld		a, [hl]
		or		a, a
		jr		z, tc_ret			; lone quote: end here
		cp		a, 0x5C
		jr		z, tc_esc
		inc		hl				; -> s[2]
		ld		a, [hl]
		cp		a, 0x27
		jr		nz, tc_ret			; no closing quote: end at s[2]
		inc		hl
		jr		tc_ret
tc_esc:
		inc		hl				; -> escaped char
		ld		a, [hl]
		or		a, a
		jr		z, tc_ret
		inc		hl				; -> s[3]
		ld		a, [hl]
		cp		a, 0x27
		jr		nz, tc_ret
		inc		hl
tc_ret:
		scf
		ret

to_op2:
		db		0
tok_start_ptr:
		dw		0

;	tok_op2_match: A = first char, [to_op2] = second -> CY if pair
;	is one of << >> != == <= >= :: && || :=
tok_op2_match:
		push	hl					; preserve caller's text pointer
		ld		b, a
		ld		hl, op2_list
tom_l:
		ld		a, [hl]
		or		a, a
		jr		z, tom_no		; NC
		cp		a, b
		jr		nz, tom_nxt
		inc		hl
		ld		a, [hl]
		ld		c, a
		ld		a, [to_op2]
		cp		a, c
		jr		z, tom_yes
		jr		tom_nxt2
tom_nxt:
		inc		hl
tom_nxt2:
		inc		hl
		jr		tom_l
tom_yes:
		pop		hl
		scf
		ret
tom_no:
		pop		hl
		or		a, a
		ret
op2_list:
		db		"<", "<", ">", ">", "!", "=", "=", "=", "<", "="
		db		">", "=", ":", ":", "&", "&", "|", "|", ":", "=", 0

;	char classes (A = char)
tok_is_word_start:
		; independent range tests (an early bail on the 'A' test
		; would make digits and '_' unreachable)
		cp		a, 'A'
		jr		c, tiws_digit
		cp		a, 'Z' + 1
		jr		c, tiws_yes
		cp		a, 'a'
		jr		c, tiws_under
		cp		a, 'z' + 1
		jr		c, tiws_yes
		jr		tiws_no
tiws_digit:
		cp		a, '0'
		jr		c, tiws_no
		cp		a, '9' + 1
		jr		c, tiws_yes
		jr		tiws_no
tiws_under:
		cp		a, '_'
		jr		z, tiws_yes
tiws_no:
		or		a, a
		ret
tiws_yes:
		scf
		ret

tok_is_word_char:
		cp		a, 0x27			; apostrophe is a word char (cross)
		jr		z, tiws_yes
		jr		tok_is_word_start

tok_is_hex_char:
		cp		a, '0'
		jr		c, tiws_no
		cp		a, '9' + 1
		jr		c, tiws_yes
		cp		a, 'A'
		jr		c, tiws_no
		cp		a, 'F' + 1
		jr		c, tiws_yes
		cp		a, 'a'
		jr		c, tiws_no
		cp		a, 'f' + 1
		jr		c, tiws_yes
		cp		a, '_'
		jr		z, tiws_yes
		jr		tiws_no

tok_is_sjis1:
		cp		a, 0x81
		jr		c, tiws_no
		cp		a, 0xA0
		jr		c, tiws_yes
		cp		a, 0xE0
		jr		c, tiws_no
		cp		a, 0xFD
		jr		c, tiws_yes
		jr		tiws_no

;	tok_scan: HL = line start -> tokenize whole line into tok_tab
tok_scan:
		xor		a, a
		ld		[tok_count], a
		ld		de, tok_tab
		ld		[tok_tab_ptr], de
tsc_loop:
		call	tok_one				; HL = end, CY if a token was read
		ret		nc
		ld		a, [tok_count]
		cp		a, TOK_MAX
		ret		nc
		push	hl					; save end
		ld		hl, [tok_start_ptr]	; HL = start
		ex		de, hl				; DE = start
		pop		hl					; HL = end
		ld		a, l
		sub		a, e
		ld		[tok_len], a
		push	hl					; save end again
		ld		hl, [tok_tab_ptr]
		ld		[hl], e
		inc		hl
		ld		[hl], d
		inc		hl
		ld		a, [tok_len]
		ld		[hl], a
		inc		hl
		ld		a, [tok_type]
		ld		[hl], a
		inc		hl
		ld		[tok_tab_ptr], hl
		ld		hl, tok_count
		inc		[hl]
		pop		hl					; HL = end = next scan position
		jr		tsc_loop

;	tok_get: A = index -> HL = span ptr, B = length, C = type
tok_get:
		ld		l, a
		ld		h, 0
		add		hl, hl
		add		hl, hl
		ld		de, tok_tab
		add		hl, de
		ld		e, [hl]
		inc		hl
		ld		d, [hl]
		inc		hl
		ld		b, [hl]
		inc		hl
		ld		c, [hl]
		ex		de, hl
		ret

;	tok_eq: A = index, HL = NUL-terminated (uppercase) string
;	-> Z if token text (uppercased) equals the string
tok_eq:
		ld		[te_str], hl
		call	tok_get				; HL = span, B = len, C = type
		ld		a, b
		ld		[te_len], a
		ld		[te_ptr], hl
		ld		hl, [te_str]
		ld		b, 0				; string length counter
te_len_l:
		ld		a, [hl]
		or		a, a
		jr		z, te_len_d
		inc		hl
		inc		b
		jr		te_len_l
te_len_d:
		ld		a, [te_len]
		cp		a, b
		ret		nz
		ld		hl, [te_ptr]
		ld		de, [te_str]
		ld		a, b
		or		a, a
		jr		z, te_eq_z			; both empty -> equal
		ld		b, a
te_cmp_l:
		ld		a, [hl]
		call	upcase
		ld		c, a
		ld		a, [de]
		cp		a, c
		ret		nz
		inc		hl
		inc		de
		djnz	te_cmp_l
te_eq_z:
		xor		a, a				; Z
		ret
te_str:
		dw		0
te_len:
		db		0
te_ptr:
		dw		0

;	tok_copy: A = index, DE = dest -> copy token text (type 0
;	uppercased, types 1/2 raw), NUL-terminate; BC = length.
;	[tok_raw] != 0 forces raw copy for all types.
tok_raw:
		db		0
tok_copy:
		push	de					; tok_get clobbers DE (dest)
		call	tok_get				; HL = span, B = len, C = type
		pop		de
		ld		a, b
		ld		[tc_len], a
		ld		b, a
		ld		a, b
		or		a, a
		jr		z, tc_done
tc_l:
		ld		a, [hl]
		inc		hl
		push	hl
		push	bc
		ld		b, a
		ld		a, [tok_raw]
		or		a, a
		jr		nz, tc_raw
		ld		a, c				; type
		or		a, a
		jr		nz, tc_raw			; string/char: raw
		ld		a, b
		call	upcase
		ld		b, a
tc_raw:
		ld		a, b
		ld		[de], a
		inc		de
		pop		bc
		pop		hl
		djnz	tc_l
tc_done:
		xor		a, a
		ld		[de], a
		ld		bc, [tc_len]
		ld		b, 0
		ret
tc_len:
		dw		0

;	p3_scan_word: HL = ptr -> skip spaces; cross-ident word
;	[A-Za-z_][A-Za-z0-9_']* uppercased into p3_word; HL = end.
;	-> CY if a word was scanned, NC otherwise (HL preserved-ish)
p3_word:
		space	64
p3_scan_word:
		ld		[psw_save], hl
psw_skip:
		ld		a, [hl]
		cp		a, ' '
		jr		z, psw_sk1
		cp		a, 9
		jr		nz, psw_at
psw_sk1:
		inc		hl
		jr		psw_skip
psw_at:
		call	tok_is_word_start
		jr		nc, psw_no
		; digits cannot START a name for our uses; cross words can,
		; but a leading digit means a number token -> reject
		cp		a, '0'
		jr		c, psw_yes0
		cp		a, '9' + 1
		jr		c, psw_no
psw_yes0:
		ld		de, p3_word
		ld		b, 0
psw_l:
		ld		a, [hl]
		call	tok_is_word_char
		jr		nc, psw_done
		call	upcase
		ld		c, a
		ld		a, b
		cp		a, 63
		jr		nc, psw_skipc
		ld		a, c
		ld		[de], a
		inc		de
		inc		b
psw_skipc:
		inc		hl
		jr		psw_l
psw_done:
		xor		a, a
		ld		[de], a
		ld		[lp], hl			; success: advance [lp], NC
		ret
psw_no:
		ld		hl, [psw_save]
		scf						; failure: CY
		ret
psw_save:
		dw		0

; ---------------------------------------------------------------------------
;	Literal decoders for '@' stringification.
;	str_decode: HL = string span (starts with '"'), B = span length
;	-> decoded content in dec_buf, BC = decoded length.
;	Escape mapping follows cross's tokenizer (\a\b\f\n\r\t\\\'\"
;	and default = the char itself; SJIS pairs copied verbatim).
;	chr_decode: HL = char span (starts with '\''), B = length
;	-> A = decoded byte.
; ---------------------------------------------------------------------------
dec_buf:
		space	260
dec_len:
		dw		0

str_decode:
		ld		[sd_ptr], hl
		ld		a, b
		ld		[sd_rem], a
		ld		hl, 0
		ld		[dec_len], hl
		; skip opening quote
		ld		hl, [sd_ptr]
		inc		hl
		ld		[sd_ptr], hl
		ld		a, [sd_rem]
		dec		a
		ld		[sd_rem], a
sd_l:
		ld		a, [sd_rem]
		or		a, a
		jp		z, sd_done
		ld		hl, [sd_ptr]
		ld		a, [hl]
		cp		a, '"'
		jp		z, sd_done			; closing quote ends content
		cp		a, 0x5C
		jr		z, sd_esc
		; plain char; SJIS lead consumes its trail byte atomically
		call	tok_is_sjis1
		jr		nc, sd_plain
		call	sd_emit
		call	sd_next
		ld		a, [sd_rem]
		or		a, a
		jr		z, sd_done
		ld		hl, [sd_ptr]
		ld		a, [hl]
sd_plain:
		call	sd_emit
		call	sd_next
		jr		sd_l
sd_esc:
		call	sd_next				; consume backslash
		ld		a, [sd_rem]
		or		a, a
		jr		z, sd_done
		ld		hl, [sd_ptr]
		ld		a, [hl]
		call	esc_map				; A = decoded byte
		call	sd_emit
		call	sd_next
		jr		sd_l
sd_done:
		ld		bc, [dec_len]
		ret
sd_ptr:
		dw		0
sd_rem:
		db		0

;	sd_emit: A = byte -> append to dec_buf, dec_len++
sd_emit:
		push	hl
		push	de
		ld		hl, [dec_len]
		ld		de, dec_buf
		add		hl, de
		ld		[hl], a
		ld		hl, [dec_len]
		inc		hl
		ld		[dec_len], hl
		pop		de
		pop		hl
		ret

;	sd_next: advance sd_ptr, sd_rem--
sd_next:
		ld		hl, [sd_ptr]
		inc		hl
		ld		[sd_ptr], hl
		ld		hl, sd_rem
		dec		[hl]
		ret

;	esc_map: A = char after backslash -> A = decoded byte
esc_map:
		cp		a, 'a'
		jr		nz, esc_1
		ld		a, 7
		ret
esc_1:
		cp		a, 'b'
		jr		nz, esc_2
		ld		a, 8
		ret
esc_2:
		cp		a, 'f'
		jr		nz, esc_3
		ld		a, 12
		ret
esc_3:
		cp		a, 'n'
		jr		nz, esc_4
		ld		a, 10
		ret
esc_4:
		cp		a, 'r'
		jr		nz, esc_5
		ld		a, 13
		ret
esc_5:
		cp		a, 't'
		jr		nz, esc_6
		ld		a, 9
		ret
esc_6:
		ret							; \\ \' \" and default: the char itself

chr_decode:
		inc		hl					; -> s[1]
		dec		b
		ld		a, b
		or		a, a
		jr		z, cd_0
		ld		a, [hl]
		cp		a, 0x5C
		jr		nz, cd_ret
		inc		hl
		ld		a, [hl]
		jp		esc_map
cd_0:
		xor		a, a
		ret
cd_ret:
		ret

; ---------------------------------------------------------------------------
;	line_block_word: HL = line -> A = structural role of the line:
;	0 none, 1 REPEAT, 2 ENDR, 3 MACRODEF, 4 ENDM, 5 LINK, 6 ENDL.
;	Leading labels (name ':' / name '::') are skipped, mirroring
;	cross's load-time label splitting.
; ---------------------------------------------------------------------------
lbw_i:
		db		0
line_block_word:
		call	tok_scan
		xor		a, a
		ld		[lbw_i], a
lbw_skip:
		ld		a, [tok_count]
		ld		b, a
		ld		a, [lbw_i]
		inc		a
		cp		a, b
		jr		nc, lbw_word			; need at least 2 tokens for a label
		; tok[i+1] == ":" or "::" ?
		ld		a, [lbw_i]
		inc		a
		ld		hl, s_tok_colon
		call	tok_eq
		jr		z, lbw_islab
		ld		a, [lbw_i]
		inc		a
		ld		hl, s_tok_colon2
		call	tok_eq
		jr		nz, lbw_word
lbw_islab:
		ld		a, [lbw_i]
		add		a, 2
		ld		[lbw_i], a
		jr		lbw_skip
lbw_word:
		ld		a, [tok_count]
		ld		b, a
		ld		a, [lbw_i]
		cp		a, b
		jr		nc, lbw_none
		ld		a, [lbw_i]
		ld		hl, s_kw_repeat
		call	tok_eq
		jr		z, lbw_1
		ld		a, [lbw_i]
		ld		hl, s_kw_endr
		call	tok_eq
		jr		z, lbw_2
		ld		a, [lbw_i]
		ld		hl, s_kw_endm
		call	tok_eq
		jr		z, lbw_4
		ld		a, [lbw_i]
		ld		hl, s_kw_link
		call	tok_eq
		jr		z, lbw_5
		ld		a, [lbw_i]
		ld		hl, s_kw_endl
		call	tok_eq
		jr		z, lbw_6
		; MACRODEF: tok[i+1] == "MACRO"
		ld		a, [tok_count]
		ld		b, a
		ld		a, [lbw_i]
		inc		a
		cp		a, b
		jr		nc, lbw_none
		ld		a, [lbw_i]
		inc		a
		ld		hl, s_kw_macro
		call	tok_eq
		jr		z, lbw_3
lbw_none:
		xor		a, a
		ret
lbw_1:
		ld		a, 1
		ret
lbw_2:
		ld		a, 2
		ret
lbw_3:
		ld		a, 3
		ret
lbw_4:
		ld		a, 4
		ret
lbw_5:
		ld		a, 5
		ret
lbw_6:
		ld		a, 6
		ret
s_tok_colon:
		db		":", 0
s_tok_colon2:
		db		"::", 0
s_kw_repeat:
		db		"REPEAT", 0
s_kw_endr:
		db		"ENDR", 0
s_kw_endm:
		db		"ENDM", 0
s_kw_macro:
		db		"MACRO", 0
s_kw_link:
		db		"LINK", 0
s_kw_endl:
		db		"ENDL", 0

; ---------------------------------------------------------------------------
;	capture_block: capture following lines into the arena until the
;	terminator matching A (2=ENDR, 4=ENDM, 6=ENDL) at block depth 0.
;	Nested blocks (REPEAT/LINK/MACRODEF) are tracked on cap_stack
;	with their terminator codes; mismatched terminators are stored
;	as ordinary lines.  The terminator line itself is consumed but
;	not stored.  EOF ends the capture silently.
;	-> cap_start (arena offset), cap_len set.  Arena keeps the data;
;	callers who discard must restore arena_top themselves.
; ---------------------------------------------------------------------------
cap_stack:
		space	16
cap_sp:
		db		0
cap_term:
		db		0
cap_start:
		space	4
cap_len:
		space	4

capture_block:
		ld		[cap_term], a
		xor		a, a
		ld		[cap_sp], a
		call	arena_get_top
		ld		[cap_start], hl
		ld		[cap_start + 2], de
cb_loop:
		call	get_line
		jp		c, cb_eof
		ld		hl, line_buf
		call	line_block_word		; A = role
		or		a, a
		jr		z, cb_store
		cp		a, 1				; REPEAT opener
		jr		z, cb_open2
		cp		a, 5				; LINK opener
		jr		z, cb_open6
		cp		a, 3				; MACRODEF opener
		jr		z, cb_open4
		; terminators 2/4/6
		ld		b, a
		ld		a, [cap_sp]
		or		a, a
		jr		z, cb_top_term
		; stack nonempty: match top?
		ld		hl, cap_stack
		ld		e, a
		ld		d, 0
		add		hl, de
		dec		hl					; &cap_stack[sp-1]
		ld		a, [hl]
		cp		a, b
		jr		nz, cb_store		; mismatched: ordinary line
		ld		hl, cap_sp
		dec		[hl]
		jr		cb_store
cb_top_term:
		ld		a, [cap_term]
		cp		a, b
		jr		z, cb_done			; matching terminator at depth 0
		jr		cb_store			; other terminator: ordinary line
cb_open2:
		ld		a, 2
		jr		cb_push
cb_open4:
		ld		a, 4
		jr		cb_push
cb_open6:
		ld		a, 6
cb_push:
		ld		[cap_push_v], a
		ld		a, [cap_sp]
		cp		a, 16
		jr		nc, cb_store		; stack full: treat as ordinary
		ld		l, a
		ld		h, 0
		ld		de, cap_stack
		add		hl, de
		ld		a, [cap_push_v]
		ld		[hl], a
		ld		hl, cap_sp
		inc		[hl]
		jr		cb_store
cap_push_v:
		db		0
cb_store:
		; append line_buf (line_len bytes) + LF to the arena
		ld		a, [line_len]
		or		a, a
		jr		z, cb_stlf
		ld		b, a
		ld		hl, line_buf
cb_stl:
		ld		a, [hl]
		inc		hl
		push	hl
		push	bc
		call	arena_put8
		pop		bc
		pop		hl
		djnz	cb_stl
cb_stlf:
		ld		a, 10
		call	arena_put8
		jp		cb_loop
cb_eof:
cb_done:
		; cap_len = arena_top - cap_start
		ld		hl, [arena_top]
		ld		de, [cap_start]
		or		a, a
		sbc		hl, de
		ld		[cap_len], hl
		ld		hl, [arena_top + 2]
		ld		de, [cap_start + 2]
		sbc		hl, de
		ld		[cap_len + 2], hl
		ret

;	capture_discard: capture_block + restore arena_top
capture_discard:
		call	capture_block
		ld		hl, [cap_start]
		ld		[arena_top], hl
		ld		hl, [cap_start + 2]
		ld		[arena_top + 2], hl
		ret

; ---------------------------------------------------------------------------
;	xbuf: expansion build area, kept in the capture arena.  xb_pos
;	(32-bit) is the write cursor; a build starts at arena_top and
;	the region is committed by advancing arena_top when the macro
;	frame is pushed.
; ---------------------------------------------------------------------------
xb_pos:
		space	4
xb_ovf:
		db		0
xb_c:
		db		0

xb_reset:
		ld		hl, [arena_top]
		ld		[xb_pos], hl
		ld		hl, [arena_top + 2]
		ld		[xb_pos + 2], hl
		xor		a, a
		ld		[xb_ovf], a
		ret

;	xb_put8: A = byte -> append at xb_pos (sets xb_ovf past the arena)
xb_put8:
		ld		[apw_val], a
		ld		hl, [xb_pos]
		ld		de, [xb_pos + 2]
		call	apio_set
		call	apio_write8
		ld		hl, xb_pos
		ld		[v32_base], hl
		call	v32_inc_hl
		ld		a, [xb_pos + 1]
		and		a, 0xC0
		rlca
		rlca					; segment index of xb_pos
		ld		e, a
		ld		a, [arena_nsegs]
		cp		a, e			; CY: nsegs < seg (over); Z: == (full)
		jr		c, xb_ovf_now
		ret		nz				; nsegs > segment: still room
xb_ovf_now:
		ld		a, 1				; nsegs <= segment: full
		ld		[xb_ovf], a
		ret

;	xb_copy_are: copy DE bytes from arena offset [xca_src] to xb_pos
xca_src:
		space	4
xb_copy_are:
		ld		a, e
		or		a, d
		ret		z
xca_l:
		ld		hl, [xca_src]
		push	de
		ld		de, [xca_src + 2]
		call	apio_set
		call	apio_read8		; A = byte
		pop		de
		push	de
		call	xb_put8
		pop		de
		dec		de
		ld		hl, xca_src
		ld		[v32_base], hl
		call	v32_inc_hl
		ld		a, e
		or		a, d
		jr		nz, xca_l
		ret

;	xb_put_span: HL = src, B = length
xb_put_span:
		ld		a, b
		or		a, a
		ret		z
xps_l:
		ld		a, [hl]
		inc		hl
		push	hl
		push	bc
		call	xb_put8
		pop		bc
		pop		hl
		djnz	xps_l
		ret

;	xb_put_str: HL = NUL-terminated string
xb_put_str:
		ld		a, [hl]
		or		a, a
		ret		z
		inc		hl
		push	hl
		call	xb_put8
		pop		hl
		jr		xb_put_str

; ---------------------------------------------------------------------------
;	Text source entries (kinds 1..3 in istk slots 5..12)
; ---------------------------------------------------------------------------
ate_kind:
		db		0
ate_ent:
		dw		0
fth_ent:
		dw		0
ent_v32:
		space	4
ent_v32b:
		space	4

;	alloc_text_entry: A = kind -> HL = entry, NC; CY if no slot
;	(error reported).  Increments text_depth.
alloc_text_entry:
		ld		[ate_kind], a
		ld		a, [text_depth]
		cp		a, 8
		jr		nc, ate_full
		add		a, 5
		ld		b, a
		ld		hl, istk
		ld		de, ISTK_ENT
ate_mul:
		add		hl, de
		djnz	ate_mul
		ld		[ate_ent], hl
		push	hl
		ld		de, E_KIND
		add		hl, de
		ld		a, [ate_kind]
		ld		[hl], a
		pop		hl
		push	hl
		ld		de, E_PBV
		add		hl, de
		ld		[hl], 0
		pop		hl
		push	hl
		inc		hl					; E_EOF (+1) = text pending flag
		ld		[hl], 0
		pop		hl
		ld		a, [text_depth]
		inc		a
		ld		[text_depth], a
		ld		hl, [ate_ent]
		or		a, a				; NC
		ret
ate_full:
		ld		hl, s_scope_deep
		call	err_line
		scf
		ret

;	fill_text_hdr: HL = new entry; copy E_NAME/E_LINE from cur_ent
fill_text_hdr:
		ld		[fth_ent], hl
		ld		de, E_NAME
		add		hl, de
		ex		de, hl
		ld		hl, [cur_ent]
		ld		bc, E_NAME
		add		hl, bc
		ld		bc, 16
		ldir
		ld		hl, [cur_ent]
		ld		de, E_LINE
		add		hl, de
		ld		e, [hl]
		inc		hl
		ld		d, [hl]
		ld		hl, [fth_ent]
		ld		bc, E_LINE
		add		hl, bc
		ld		[hl], e
		inc		hl
		ld		[hl], d
		ld		hl, [fth_ent]		; return HL = entry (callers push it)
		ret

;	ent_set32: HL = entry, BC = disp; ent_v32 -> field
ent_set32:
		add		hl, bc
		ex		de, hl
		ld		hl, ent_v32
		ld		bc, 4
		ldir
		ret

;	ent_get32: HL = entry, BC = disp; field -> ent_v32
ent_get32:
		add		hl, bc
		ld		de, ent_v32
		ld		bc, 4
		ldir
		ret

;	ent_get32b: HL = entry, BC = disp; field -> ent_v32b
ent_get32b:
		add		hl, bc
		ld		de, ent_v32b
		ld		bc, 4
		ldir
		ret

;	v32_dec_hl: [v32_base] LE32 -= 1 -> Z if result is zero
v32_base:
		dw		0
v32_dec_hl:
		ld		hl, [v32_base]
		ld		a, [hl]
		sub		a, 1
		ld		[hl], a
		jr		nc, v32_zchk
		inc		hl
		ld		a, [hl]
		sub		a, 1
		ld		[hl], a
		jr		nc, v32_zchk
		inc		hl
		ld		a, [hl]
		sub		a, 1
		ld		[hl], a
		jr		nc, v32_zchk
		inc		hl
		ld		a, [hl]
		sub		a, 1
		ld		[hl], a
v32_zchk:
		ld		hl, [v32_base]
		ld		a, [hl]
		inc		hl
		or		a, [hl]
		inc		hl
		or		a, [hl]
		inc		hl
		or		a, [hl]
		ret

;	v32_inc_hl: [v32_base] LE32 += 1
v32_inc_hl:
		ld		hl, [v32_base]
		ld		a, [hl]
		add		a, 1
		ld		[hl], a
		ret		nc
		inc		hl
		ld		a, [hl]
		add		a, 1
		ld		[hl], a
		ret		nc
		inc		hl
		ld		a, [hl]
		add		a, 1
		ld		[hl], a
		ret		nc
		inc		hl
		ld		a, [hl]
		add		a, 1
		ld		[hl], a
		ret

; ---------------------------------------------------------------------------
;	rc_text:
rc_text:
		; A text entry boundary (end of body / end of one REPEAT
		; iteration) must not fire inside get_line's terminator
		; probe: the probe read only ARMS the boundary (E_EOF byte
		; of the entry = pending flag, one-shot src_eof), and the
		; next real read performs the pop / rollover.  This keeps
		; the body's last line in its own scope and the REPEAT
		; counter aligned with the line being processed.
		ld		hl, [cur_ent]
		inc		hl					; E_EOF (+1): pending flag for text entries
		ld		a, [hl]
		or		a, a
		jp		z, rct_fresh
		ld		[hl], 0				; clear pending
		ld		hl, [cur_ent]
		ld		de, E_KIND
		add		hl, de
		ld		a, [hl]
		cp		a, 2
		jr		z, rct_roll_do
		call	src_pop_one			; kinds 1/3: boundary = pop the frame
		jp		read_char
rct_roll_do:
		; REPEAT rollover: TLEFT -= 1
		ld		hl, [cur_ent]
		ld		bc, E_TLEFT
		call	ent_get32			; ent_v32 = TLEFT
		ld		hl, ent_v32
		ld		[v32_base], hl
		call	v32_dec_hl
		push	af					; Z if exhausted
		ld		hl, [cur_ent]
		ld		bc, E_TLEFT
		call	ent_set32
		pop		af
		jr		nz, rct_roll_rew
		call	src_pop_one
		jp		read_char
rct_roll_rew:
		; TPOS = TSTART
		ld		hl, [cur_ent]
		ld		bc, E_TSTART
		call	ent_get32
		ld		hl, [cur_ent]
		ld		bc, E_TPOS
		call	ent_set32
		; counter symbol += 1
		ld		hl, [cur_ent]
		ld		bc, E_CSYM
		call	ent_get32			; ent_v32 = counter record offset
		ld		hl, [ent_v32]
		ld		[rec_cur], hl
		ld		hl, [ent_v32 + 2]
		ld		[rec_cur + 2], hl
		ld		a, SYM_VALUE
		call	rr32x				; rr32_buf = old value
		ld		hl, rr32_buf
		ld		[v32_base], hl
		call	v32_inc_hl
		ld		hl, [rr32_buf]
		ld		de, [rr32_buf + 2]
		ld		a, SYM_VALUE
		call	rw32
		; ctx slot marker += 1 (distinguishes iterations in site keys)
		ld		hl, [cur_ent]
		ld		de, E_CTX
		add		hl, de
		ld		l, [hl]
		ld		h, 0
		add		hl, hl
		ld		de, ctx_stack
		add		hl, de
		inc		[hl]
		jp		nz, rc_text
		inc		hl
		inc		[hl]
		jp		rc_text
rct_fresh:
		call	rct_cmp_pos_end
		jp		nz, rct_are_read
		; at the end: arm the boundary, signal a one-shot EOF
		ld		hl, [cur_ent]
		inc		hl					; E_EOF (+1) pending flag
		ld		[hl], 1
		ld		a, 1
		ld		[src_eof], a
		xor		a, a
		ret

rct_are_read:
		; apio = TPOS; read byte; TPOS = apio + 1
		ld		hl, [cur_ent]
		ld		bc, E_TPOS
		call	ent_get32
		ld		hl, [ent_v32]
		ld		de, [ent_v32 + 2]
		call	apio_set
		call	apio_read8
		ld		[rct_ch], a
		call	apio_inc
		call	apio_get
		ld		[ent_v32], hl
		ld		[ent_v32 + 2], de
		ld		hl, [cur_ent]
		ld		bc, E_TPOS
		call	ent_set32
		ld		a, [rct_ch]
		ret
rct_ch:
		db		0

;	rct_cmp_pos_end: Z if entry TPOS == TEND (32-bit)
rct_cmp_pos_end:
		ld		hl, [cur_ent]
		ld		bc, E_TPOS
		call	ent_get32
		ld		hl, [cur_ent]
		ld		bc, E_TEND
		call	ent_get32b
		ld		hl, ent_v32
		ld		de, ent_v32b
		ld		b, 4
rct_cmp_l:
		ld		a, [de]
		cp		a, [hl]
		ret		nz
		inc		hl
		inc		de
		djnz	rct_cmp_l
		xor		a, a
		ret

; ---------------------------------------------------------------------------
;	Macro table (pool, persistent across passes).
;	MACREC (84 bytes): +0 name(64), +64 def site fhash(2), +66 line(2),
;	+68 ctx(2), +70 params block offset(4), +74 param count(1),
;	+75 body arena offset(2), +77 body length(2), +79 body pass(1),
;	+80 next(4).  Params block: per param 65 bytes: +0 name(64),
;	+64 through flag(1).
; ---------------------------------------------------------------------------
M_NAME		:= 0
M_DEFSITE	:= 64
M_PARAMS	:= 70
M_NPARAMS	:= 74
M_BODYOFF	:= 75
M_BODYLEN	:= 77
M_BODYPASS	:= 79
M_NEXT		:= 80
MACREC_SZ	:= 84
PARAM_SZ	:= 65
P_THROUGH	:= 64

p3_name:
		space	64
mac_walk:
		space	4
pse_ram:
		dw		0

;	pool_str_eq: pio at pool string, HL = RAM NUL string -> Z if equal
pool_str_eq:
		ld		[pse_ram], hl
pse_l:
		call	pio_read8
		ld		b, a
		ld		hl, [pse_ram]
		ld		a, [hl]
		cp		a, b
		ret		nz
		or		a, a
		ret		z
		inc		hl
		ld		[pse_ram], hl
		call	pio_inc
		jr		pse_l

;	pool_put_str: pio set; HL = RAM NUL string -> write incl NUL
pool_put_str:
		ld		a, [hl]
		inc		hl
		ld		[pw_val], a
		push	hl
		push	af					; pio_write8 destroys A: save the char
		call	pio_write8
		call	pio_inc
		pop		af
		pop		hl
		or		a, a
		jr		nz, pool_put_str
		ret

;	mac_find: p3_name -> NC + rec_cur = record if found; CY if not
mac_find:
		ld		hl, [mac_head]
		ld		[mac_walk], hl
		ld		hl, [mac_head + 2]
		ld		[mac_walk + 2], hl
mf_loop:
		ld		hl, [mac_walk]
		ld		de, [mac_walk + 2]
		ld		a, l
		or		a, h
		or		a, e
		or		a, d
		scf
		ret		z				; empty: CY (not found)
		ld		hl, [mac_walk]
		ld		[rec_cur], hl
		ld		hl, [mac_walk + 2]
		ld		[rec_cur + 2], hl
		ld		hl, rec_cur
		ld		a, M_NAME
		call	off_copy_add
		ld		hl, p3_name
		call	pool_str_eq
		jr		z, mf_found
		ld		a, M_NEXT
		call	rr32x
		ld		hl, [rr32_buf]
		ld		[mac_walk], hl
		ld		hl, [rr32_buf + 2]
		ld		[mac_walk + 2], hl
		jr		mf_loop
mf_found:
		or		a, a				; NC
		ret

;	link_rec: A = next-field disp, HL = head cell (RAM 4 bytes):
;	rec_cur.next = head; head = rec_cur
lr_head:
		dw		0
lr_buf:
		space	4
link_rec:
		ld		[lr_head], hl
		ld		[lr_disp], a
		ld		de, lr_buf
		ld		bc, 4
		ldir					; lr_buf = old head value (HL was head ptr)
		ld		hl, [lr_buf]
		ld		de, [lr_buf + 2]
		ld		a, [lr_disp]
		call	rw32
		ld		hl, [lr_head]
		ld		de, rec_cur
		ex		de, hl
		ld		bc, 4
		ldir					; head = rec_cur (HL=rec_cur, DE=head)
		ret
lr_disp:
		db		0

; ---------------------------------------------------------------------------
;	Site records for macro invocations (12 bytes): +0 site(6),
;	+6 instance index(2), +8 next(4)
; ---------------------------------------------------------------------------
macsite_find_or_create:
		ld		hl, [macsite_head]
		ld		[mac_walk], hl
		ld		hl, [macsite_head + 2]
		ld		[mac_walk + 2], hl
msf_loop:
		ld		hl, [mac_walk]
		ld		de, [mac_walk + 2]
		ld		a, l
		or		a, h
		or		a, e
		or		a, d
		jr		z, msf_new
		ld		hl, [mac_walk]
		ld		[rec_cur], hl
		ld		hl, [mac_walk + 2]
		ld		[rec_cur + 2], hl
		xor		a, a
		ld		[se_disp], a
		call	site_match
		jr		z, msf_have
		ld		a, 8
		call	rr32x
		ld		hl, [rr32_buf]
		ld		[mac_walk], hl
		ld		hl, [rr32_buf + 2]
		ld		[mac_walk + 2], hl
		jr		msf_loop
msf_have:
		ld		a, 6
		call	rr16				; HL = instance index
		ret
msf_new:
		ld		hl, 12
		call	rec_new
		xor		a, a
		ld		[se_disp], a
		call	site_store
		ld		hl, [mac_inst_ctr]
		push	hl
		ld		a, 6
		call	rw16
		ld		hl, [mac_inst_ctr]
		inc		hl
		ld		[mac_inst_ctr], hl
		ld		a, 8
		ld		hl, macsite_head
		call	link_rec
		ld		a, 1
		ld		[pass_changed], a
		pop		hl
		ret

; ---------------------------------------------------------------------------
;	dir_macro: NAME MACRO [@]param [, [@]param ...]  + body capture.
;	Called from p3_mnem_hook; line_buf holds the whole line,
;	name_src_buf the macro name.
; ---------------------------------------------------------------------------
pstage:
		space	16 * PARAM_SZ
pstage_n:
		db		0
dm_j:
		db		0
dm_idx:
		db		0
dm_through:
		db		0

dir_macro:
		ld		hl, line_buf
		call	tok_scan			; tokenize the whole line
		; find j: tok[j] == "MACRO" (j >= 1) and tok[j-1] == name
		ld		a, 1
		ld		[dm_j], a
dm_find:
		ld		a, [tok_count]
		ld		b, a
		ld		a, [dm_j]
		cp		a, b
		jp		nc, dm_ret			; not found (defensive)
		ld		a, [dm_j]
		ld		hl, s_kw_macro
		call	tok_eq
		jr		nz, dm_find_nx
		; check tok[j-1] text == name_src_buf
		ld		a, [dm_j]
		dec		a
		ld		de, p3_name
		call	tok_copy			; p3_name = candidate (upcased)
		ld		hl, p3_name
		ld		de, name_src_buf
		call	str_eq
		jr		z, dm_params
dm_find_nx:
		ld		a, [dm_j]
		inc		a
		ld		[dm_j], a
		jr		dm_find
dm_params:
		xor		a, a
		ld		[pstage_n], a
		ld		a, [dm_j]
		inc		a
		ld		[dm_idx], a			; idx = j+1
dm_ploop:
		ld		a, [tok_count]
		ld		b, a
		ld		a, [dm_idx]
		cp		a, b
		jp		nc, dm_register
		xor		a, a
		ld		[dm_through], a
		ld		a, [dm_idx]
		ld		hl, s_at_sign
		call	tok_eq
		jr		nz, dm_pname
		ld		a, 1
		ld		[dm_through], a
		ld		a, [dm_idx]
		inc		a
		ld		[dm_idx], a		; idx = token after '@'
		ld		b, a
		ld		a, [tok_count]
		cp		a, b			; need idx < tok_count
		jp		z, dm_illarg
		jp		c, dm_illarg
dm_pname:
		; token type must be 0
		ld		a, [dm_idx]
		call	tok_get				; C = type
		ld		a, c
		or		a, a
		jp		nz, dm_illarg
		; stage the name
		ld		a, [pstage_n]
		cp		a, 16
		jp		nc, dm_illarg
		ld		l, a
		ld		h, 0
		ld		e, a				; HL = DE = index for *65
		ld		d, 0
		add		hl, hl
		add		hl, hl
		add		hl, hl
		add		hl, hl
		add		hl, hl
		add		hl, hl				; *64
		add		hl, de				; *65
		ld		de, pstage
		add		hl, de
		ex		de, hl				; DE = stage entry
		ld		[dm_stage], de
		ld		a, [dm_idx]
		call	tok_copy			; name into stage entry
		; through flag at entry+64
		ld		hl, [dm_stage]
		ld		bc, P_THROUGH
		add		hl, bc
		ld		a, [dm_through]
		ld		[hl], a
		; separator check: next token must be "," or end
		ld		a, [tok_count]
		ld		b, a
		ld		a, [dm_idx]
		inc		a
		cp		a, b
		jr		nc, dm_pok
		ld		a, [dm_idx]
		inc		a
		ld		hl, s_comma
		call	tok_eq
		jp		nz, dm_illarg
dm_pok:
		; duplicate param name?
		ld		a, [pstage_n]
		or		a, a
		jr		z, dm_pnext
		ld		[dm_dup_i], a
		xor		a, a
		ld		[dm_dup_j], a
dm_dup_l:
		ld		a, [dm_dup_j]
		ld		l, a
		ld		h, 0
		ld		e, a
		ld		d, 0
		add		hl, hl
		add		hl, hl
		add		hl, hl
		add		hl, hl
		add		hl, hl
		add		hl, hl
		add		hl, de
		ld		de, pstage
		add		hl, de				; HL = earlier entry
		ld		de, [dm_stage]
		call	str_eq
		jp		z, dm_multdef
		ld		a, [dm_dup_j]
		inc		a
		ld		a, [dm_dup_i]
		ld		b, a
		ld		[dm_dup_j], a
		cp		a, b
		jr		c, dm_dup_l
dm_pnext:
		ld		a, [pstage_n]
		inc		a
		ld		[pstage_n], a
		ld		a, [dm_idx]
		add		a, 2
		ld		[dm_idx], a
		jp		dm_ploop
dm_stage:
		dw		0
dm_dup_i:
		db		0
dm_dup_j:
		db		0

dm_illarg:
		ld		hl, s_illarg
		call	err_line
		ld		a, 4
		jp		capture_discard
dm_multdef:
		ld		hl, s_multdef
		call	err_line
		ld		a, 4
		jp		capture_discard
dm_ret:
		ret

s_at_sign:
		db		"@", 0
s_comma:
		db		",", 0
s_illarg:
		db		"Illegal argument.", 0

;	dm_register: params staged OK.  Register/update + capture body.
dm_rec:
		space	4
dm_pblk:
		space	4
dm_wpi:
		db		0

dm_register:
		call	cur_site
		call	mac_find
		jr		c, dm_new_rec
		; existing record: rec_cur = macrec; save it
		ld		hl, [rec_cur]
		ld		[dm_rec], hl
		ld		hl, [rec_cur + 2]
		ld		[dm_rec + 2], hl
		ld		a, M_DEFSITE
		ld		[se_disp], a
		call	site_match
		jr		nz, dm_redef
		; same site: rewrite the params block in place
		ld		a, M_PARAMS
		call	rr32x
		ld		hl, [rr32_buf]
		ld		[dm_pblk], hl
		ld		hl, [rr32_buf + 2]
		ld		[dm_pblk + 2], hl
		call	dm_write_params
		jp		dm_capture
dm_redef:
		ld		hl, s_multdef
		call	err_line
		ld		a, 4
		jp		capture_discard
dm_new_rec:
		ld		hl, MACREC_SZ
		call	rec_new				; rec_cur = macrec
		ld		hl, [rec_cur]
		ld		[dm_rec], hl
		ld		hl, [rec_cur + 2]
		ld		[dm_rec + 2], hl
		ld		a, M_NEXT
		ld		hl, mac_head
		call	link_rec
		; name at +0
		ld		hl, rec_cur
		ld		a, M_NAME
		call	off_copy_add
		ld		hl, p3_name
		call	pool_put_str
		; def site
		ld		a, M_DEFSITE
		ld		[se_disp], a
		call	site_store
		; params block
		ld		a, [pstage_n]
		or		a, a
		jr		z, dm_np0
		call	i65					; HL = n * 65
		call	rec_new				; rec_cur = params block
		ld		hl, [rec_cur]
		ld		[dm_pblk], hl
		ld		hl, [rec_cur + 2]
		ld		[dm_pblk + 2], hl
		call	dm_write_params
		; restore macrec and store block offset + count
		ld		hl, [dm_rec]
		ld		[rec_cur], hl
		ld		hl, [dm_rec + 2]
		ld		[rec_cur + 2], hl
		ld		hl, [dm_pblk]
		ld		de, [dm_pblk + 2]
		ld		a, M_PARAMS
		call	rw32
		ld		a, [pstage_n]
		ld		[rwv], a
		ld		a, M_NPARAMS
		call	rw8
		jp		dm_capture
dm_np0:
		ld		hl, 0
		ld		[dm_pblk], hl
		ld		[dm_pblk + 2], hl
		ld		hl, [dm_pblk]
		ld		de, [dm_pblk + 2]
		ld		a, M_PARAMS
		call	rw32
		xor		a, a
		ld		[rwv], a
		ld		a, M_NPARAMS
		call	rw8
		jp		dm_capture

;	i65: A = index -> HL = index * 65 (destroys DE)
i65:
		ld		l, a
		ld		h, 0
		ld		e, a
		ld		d, 0
		add		hl, hl
		add		hl, hl
		add		hl, hl
		add		hl, hl
		add		hl, hl
		add		hl, hl				; *64
		add		hl, de				; *65
		ret

;	dm_write_params: copy staged params into the block at [dm_pblk]
dm_write_params:
		xor		a, a
		ld		[dm_wpi], a
dm_wp_l:
		ld		a, [pstage_n]
		ld		b, a
		ld		a, [dm_wpi]
		cp		a, b
		ret		nc
		; pio = dm_pblk + i*65
		call	i65					; HL = i*65
		ex		de, hl
		ld		hl, [dm_pblk]
		add		hl, de
		ld		[pio], hl
		ld		hl, [dm_pblk + 2]
		jr		nc, dm_wp_nc
		inc		hl
dm_wp_nc:
		ld		[pio + 2], hl
		; write the name (stage entry at pstage + i*65)
		ld		a, [dm_wpi]
		call	i65
		ld		de, pstage
		add		hl, de				; HL = stage entry
		call	pool_put_str
		; through flag at block + i*65 + 64
		ld		a, [dm_wpi]
		call	i65
		ex		de, hl
		ld		hl, [dm_pblk]
		add		hl, de
		ld		[pio], hl
		ld		hl, [dm_pblk + 2]
		jr		nc, dm_wp_nc2
		inc		hl
dm_wp_nc2:
		ld		[pio + 2], hl
		ld		hl, [pio]
		ld		de, P_THROUGH
		add		hl, de
		ld		[pio], hl
		ld		hl, [pio + 2]
		jr		nc, dm_wp_nc3
		inc		hl
		ld		[pio + 2], hl
dm_wp_nc3:
		; stage through byte -> pw_val
		ld		a, [dm_wpi]
		call	i65
		ld		de, pstage + P_THROUGH
		add		hl, de
		ld		a, [hl]
		ld		[pw_val], a
		call	pio_write8
		ld		a, [dm_wpi]
		inc		a
		ld		[dm_wpi], a
		jr		dm_wp_l

dm_capture:
		; rec_cur = macrec (dm_rec)
		ld		hl, [dm_rec]
		ld		[rec_cur], hl
		ld		hl, [dm_rec + 2]
		ld		[rec_cur + 2], hl
		ld		a, 4				; ENDM
		call	capture_block
		ld		hl, [cap_start]
		ld		a, M_BODYOFF
		call	rw16
		ld		hl, [cap_len]
		ld		a, M_BODYLEN
		call	rw16
		ld		a, [iter_count]
		ld		[rwv], a
		ld		a, M_BODYPASS
		call	rw8
		ret

; ---------------------------------------------------------------------------
;	Macro invocation / expansion
; ---------------------------------------------------------------------------
mc_rec:
		space	4
mc_pblk:
		space	4
mc_np:
		db		0
mc_k:
		db		0
mc_ti:
		db		0
mc_gs:
		db		0
mc_tj:
		db		0
mc_first:
		db		0
mc_through:
		db		0
mc_arg_start:
		space	4
mc_inst:
		dw		0
mac_argtab:
		space	16 * 6			; per param: addr(4), len(2)

arg_tok:
		space	258
val_buf:
		space	640
val_ptr:
		dw		0
val_ovf:
		db		0

val_reset:
		ld		hl, val_buf
		ld		[val_ptr], hl
		xor		a, a
		ld		[val_ovf], a
		ret

val_put8:
		ld		[vp_c], a
		ld		hl, [val_ptr]
		ld		de, val_buf + 640
		or		a, a
		sbc		hl, de
		jr		nc, vp_full
		add		hl, de
		ld		a, [vp_c]
		ld		[hl], a
		inc		hl
		ld		[val_ptr], hl
		ret
vp_full:
		ld		a, 1
		ld		[val_ovf], a
		ret
vp_c:
		db		0

;	val_put_span: HL = src, B = length
val_put_span:
		ld		a, b
		or		a, a
		ret		z
vps_l:
		ld		a, [hl]
		inc		hl
		push	hl
		push	bc
		call	val_put8
		pop		bc
		pop		hl
		djnz	vps_l
		ret

;	pblk_pio: A = param index -> pio = [mc_pblk] + index*65
pblk_pio:
		call	i65
		ex		de, hl
		ld		hl, [mc_pblk]
		add		hl, de
		ld		[pio], hl
		ld		hl, [mc_pblk + 2]
		jr		nc, pp_done
		inc		hl
pp_done:
		ld		[pio + 2], hl
		ret

;	macro_call: rec_cur = macrec, name in name_src_buf, args at [lp].
;	Always returns (handled); errors are reported inline.
macro_call:
		ld		hl, [rec_cur]
		ld		[mc_rec], hl
		ld		hl, [rec_cur + 2]
		ld		[mc_rec + 2], hl
		ld		a, M_NPARAMS
		call	rr8
		ld		[mc_np], a
		ld		a, M_PARAMS
		call	rr32x
		ld		hl, [rr32_buf]
		ld		[mc_pblk], hl
		ld		hl, [rr32_buf + 2]
		ld		[mc_pblk + 2], hl
		call	xb_reset
		; tokenize the argument text
		ld		hl, [lp]
		call	tok_scan
		xor		a, a
		ld		[mc_ti], a
		ld		[mc_k], a
mc_arg_loop:
		ld		a, [mc_np]
		ld		b, a
		ld		a, [mc_k]
		cp		a, b
		jr		nc, mc_args_done
		; an argument must start here
		ld		a, [tok_count]
		ld		b, a
		ld		a, [mc_ti]
		cp		a, b
		jp		nc, mc_toomany
		ld		[mc_gs], a
mc_adv:
		ld		a, [tok_count]
		ld		b, a
		ld		a, [mc_ti]
		cp		a, b
		jr		nc, mc_grp_done
		ld		a, [mc_ti]
		ld		hl, s_comma
		call	tok_eq
		jr		z, mc_grp_done
		ld		a, [mc_ti]
		inc		a
		ld		[mc_ti], a
		jr		mc_adv
mc_grp_done:
		call	mc_build_arg
		; skip the separating comma if present
		ld		a, [tok_count]
		ld		b, a
		ld		a, [mc_ti]
		cp		a, b
		jr		nc, mc_no_comma
		inc		a
		ld		[mc_ti], a
mc_no_comma:
		ld		a, [mc_k]
		inc		a
		ld		[mc_k], a
		jr		mc_arg_loop
mc_args_done:
		ld		a, [tok_count]
		ld		b, a
		ld		a, [mc_ti]
		cp		a, b
		jp		c, mc_toomany		; leftover tokens
		call	mc_expand
		ld		a, [xb_ovf]
		or		a, a
		jr		nz, mc_ovf_err
		; instance for this invocation site
		call	cur_site
		call	macsite_find_or_create	; HL = instance index
		ld		[mc_inst], hl
		ld		bc, [mc_inst]
		ld		hl, s_pfx_macro
		call	make_auto_name		; p3_sname = "@MACRO<n>"
		ld		hl, p3_sname
		call	scope_push_name
		ret		c					; error already reported
		ld		hl, [mc_inst]
		call	ctx_push
		ld		a, 1
		call	alloc_text_entry
		jr		c, mc_cleanup
		; entry: TPOS = exp_start, TEND = exp_end (arena offsets)
		ld		hl, [exp_start]
		ld		[ent_v32], hl
		ld		hl, [exp_start + 2]
		ld		[ent_v32 + 2], hl
		ld		hl, [ate_ent]
		ld		bc, E_TPOS
		call	ent_set32
		ld		hl, [exp_end]
		ld		[ent_v32], hl
		ld		hl, [exp_end + 2]
		ld		[ent_v32 + 2], hl
		ld		hl, [ate_ent]
		ld		bc, E_TEND
		call	ent_set32
		; commit the build region: arena_top = exp_end
		ld		hl, [exp_end]
		ld		[arena_top], hl
		ld		hl, [exp_end + 2]
		ld		[arena_top + 2], hl
		ld		hl, [ate_ent]
		call	fill_text_hdr
		jp		src_push_frame
mc_cleanup:
		call	scope_pop
		ld		hl, ctx_sp
		dec		[hl]
		ret
mc_toomany:
		ld		hl, s_toomany
		call	err_line
		ret
mc_ovf_err:
		ld		hl, s_illegal_param
		call	err_line
		ret

s_pfx_macro:
		db		"@MACRO", 0

;	mc_build_arg: build argtext for param [mc_k] from token group
;	[mc_gs, mc_ti); record mac_argtab entry.
mc_build_arg:
		ld		hl, [xb_pos]
		ld		[mc_arg_start], hl
		ld		hl, [xb_pos + 2]
		ld		[mc_arg_start + 2], hl
		ld		a, [mc_k]
		call	pblk_pio			; pio = param entry
		ld		hl, [pio]
		ld		de, P_THROUGH
		add		hl, de
		ld		[pio], hl
		ld		hl, [pio + 2]
		jr		nc, mba_nc
		inc		hl
		ld		[pio + 2], hl
mba_nc:
		call	pio_read8
		ld		[mc_through], a
		ld		a, [mc_through]
		or		a, a
		jr		nz, mba_through
		; plain: tokens joined with single spaces (content normalized)
		ld		a, [mc_gs]
		ld		[mc_tj], a
		xor		a, a
		ld		[mc_first], a
mba_pl:
		ld		a, [mc_ti]
		ld		b, a
		ld		a, [mc_tj]
		cp		a, b
		jp		nc, mba_fin
		ld		a, [mc_first]
		or		a, a
		jr		z, mba_pnospace
		ld		a, ' '
		call	xb_put8
mba_pnospace:
		ld		a, 1
		ld		[mc_first], a
		ld		a, [mc_tj]
		ld		de, arg_tok
		call	tok_copy			; BC = length
		ld		b, c
		ld		hl, arg_tok
		call	xb_put_span
		ld		a, [mc_tj]
		inc		a
		ld		[mc_tj], a
		jr		mba_pl
mba_through:
		; value = tokens as one expression text (strings/chars decoded)
		call	val_reset
		ld		a, [mc_gs]
		ld		[mc_tj], a
		xor		a, a
		ld		[mc_first], a
mba_tl:
		ld		a, [mc_ti]
		ld		b, a
		ld		a, [mc_tj]
		cp		a, b
		jr		nc, mba_tval_done
		ld		a, [mc_first]
		or		a, a
		jr		z, mba_tnospace
		ld		a, ' '
		call	val_put8
mba_tnospace:
		ld		a, 1
		ld		[mc_first], a
		ld		a, [mc_tj]
		call	tok_get				; HL = span, B = len, C = type
		ld		a, c
		cp		a, 1
		jr		z, mba_tstr
		cp		a, 2
		jr		z, mba_tchr
		; word/operator: upcased text
		ld		a, [mc_tj]
		ld		de, arg_tok
		call	tok_copy
		ld		b, c
		ld		hl, arg_tok
		call	val_put_span
		jr		mba_tnext
mba_tstr:
		push	hl					; val_put8 destroys HL (the span)
		ld		a, '"'
		call	val_put8
		pop		hl
		call	str_decode			; HL = span -> dec_buf/dec_len
		ld		hl, [dec_len]
		ld		b, l				; (value strings < 256 in practice;
		ld		hl, dec_buf			; longer ones truncate: the pool
		call	val_put_span			; version would need 16-bit spans)
		jr		mba_tnext
mba_tchr:
		call	chr_decode			; HL = span -> A = byte
		push	af
		ld		a, 0x27
		call	val_put8
		pop		af
		call	val_put8
mba_tnext:
		ld		a, [mc_tj]
		inc		a
		ld		[mc_tj], a
		jr		mba_tl
mba_tval_done:
		ld		a, [val_ovf]
		or		a, a
		jr		z, mba_tv_ok
		ld		a, 1
		ld		[xb_ovf], a
mba_tv_ok:
		; emit '"' + escaped(value) + '"'
		ld		a, '"'
		call	xb_put8
		ld		hl, val_buf
		ld		[mba_vp], hl
mba_esc_l:
		ld		hl, [mba_vp]
		ld		de, [val_ptr]
		or		a, a
		sbc		hl, de
		jp		z, mba_esc_done
		ld		hl, [mba_vp]
		ld		a, [hl]
		inc		hl
		ld		[mba_vp], hl
		ld		[mba_ch], a
		cp		a, '"'
		jr		z, mba_e_q
		cp		a, 0x5C
		jr		z, mba_e_b
		cp		a, 7
		jr		z, mba_e_a
		cp		a, 8
		jr		z, mba_e_bk
		cp		a, 12
		jr		z, mba_e_f
		cp		a, 10
		jr		z, mba_e_n
		cp		a, 13
		jr		z, mba_e_r
		cp		a, 9
		jr		z, mba_e_t
		call	xb_put8
		jr		mba_esc_l
mba_e_q:
		ld		a, 0x5C
		call	xb_put8
		ld		a, '"'
		call	xb_put8
		jr		mba_esc_l
mba_e_b:
		ld		a, 0x5C
		call	xb_put8
		ld		a, 0x5C
		call	xb_put8
		jr		mba_esc_l
mba_e_a:
		ld		b, 'a'
		jr		mba_e_x
mba_e_bk:
		ld		b, 'b'
		jr		mba_e_x
mba_e_f:
		ld		b, 'f'
		jr		mba_e_x
mba_e_n:
		ld		b, 'n'
		jr		mba_e_x
mba_e_r:
		ld		b, 'r'
		jr		mba_e_x
mba_e_t:
		ld		b, 't'
mba_e_x:
		ld		a, 0x5C
		call	xb_put8
		ld		a, b
		call	xb_put8
		jp		mba_esc_l
mba_esc_done:
		ld		a, '"'
		call	xb_put8
mba_fin:
		; argtab[k] = (start32, len16); entry = 6 bytes
		ld		a, [mc_k]
		ld		l, a
		ld		h, 0
		add		hl, hl
		ld		e, l
		ld		d, h
		add		hl, hl
		add		hl, de				; HL = k * 6
		ld		de, mac_argtab
		add		hl, de				; HL = entry
		ex		de, hl				; DE = entry
		ld		hl, mc_arg_start
		ld		bc, 4
		ldir						; DE -> entry + 4
		ex		de, hl				; HL = entry + 4
		ld		de, [xb_pos]
		ld		bc, [mc_arg_start]
		ld		a, e
		sub		a, c
		ld		[hl], a
		inc		hl
		ld		a, d
		sbc		a, b
		ld		[hl], a
		ret
mba_vp:
		dw		0
mba_ch:
		db		0

; ---------------------------------------------------------------------------
;	mc_expand: expand the macro body (arena) into xbuf with argument
;	substitution.  exp_start/exp_end delimit the result inside xbuf.
; ---------------------------------------------------------------------------
exp_start:
		space	4
exp_end:
		space	4
mc_brem:
		dw		0
mce_pos:
		space	4
xline:
		space	258

mc_expand:
		ld		hl, [xb_pos]
		ld		[exp_start], hl
		ld		hl, [xb_pos + 2]
		ld		[exp_start + 2], hl
		; restore the macrec
		ld		hl, [mc_rec]
		ld		[rec_cur], hl
		ld		hl, [mc_rec + 2]
		ld		[rec_cur + 2], hl
		ld		a, M_BODYOFF
		call	rr16				; HL = body arena offset
		ld		[mce_pos], hl
		ld		hl, 0
		ld		[mce_pos + 2], hl
		ld		a, M_BODYLEN
		call	rr16
		ld		[mc_brem], hl
mce_l:
		ld		hl, [mc_brem]
		ld		a, l
		or		a, h
		jr		z, mce_done
		; read one body line into xline
		ld		hl, xline
		ld		[mce_xp], hl
mce_rd:
		ld		hl, [mc_brem]
		ld		a, l
		or		a, h
		jr		z, mce_eol
		dec		hl
		ld		[mc_brem], hl
		ld		hl, [mce_pos]
		ld		de, [mce_pos + 2]
		call	apio_set
		call	apio_read8
		ld		[mce_ch], a
		ld		hl, mce_pos
		ld		[v32_base], hl
		call	v32_inc_hl
		ld		a, [mce_ch]
		cp		a, 10
		jr		z, mce_eol
		ld		hl, [mce_xp]
		ld		de, xline + 255
		or		a, a
		sbc		hl, de
		jr		nc, mce_rd			; line buffer full: drop the char
		add		hl, de
		ld		[hl], a
		inc		hl
		ld		[mce_xp], hl
		jr		mce_rd
mce_ch:
		db		0
mce_eol:
		ld		hl, [mce_xp]
		ld		[hl], 0
		call	xline_subst
		jr		mce_l
mce_done:
		ld		hl, [xb_pos]
		ld		[exp_end], hl
		ld		hl, [xb_pos + 2]
		ld		[exp_end + 2], hl
		ret
mce_xp:
		dw		0

;	xline_subst: tokenize xline, copy with param substitution, + LF
xs_prev:
		dw		0
xs_i:
		db		0
xs_p:
		db		0
xs_tptr:
		dw		0
xs_tlen:
		db		0
xs_ttype:
		db		0
xs_tname:
		space	70

xline_subst:
		ld		hl, xline
		call	tok_scan
		ld		hl, xline
		ld		[xs_prev], hl
		xor		a, a
		ld		[xs_i], a
xs_l:
		ld		a, [tok_count]
		ld		b, a
		ld		a, [xs_i]
		cp		a, b
		jp		nc, xs_tail
		ld		a, [xs_i]
		call	tok_get
		ld		[xs_tptr], hl
		ld		a, b
		ld		[xs_tlen], a
		ld		a, c
		ld		[xs_ttype], a
		; gap before the token
		ld		hl, [xs_tptr]
		ld		de, [xs_prev]
		or		a, a
		sbc		hl, de
		ld		a, l
		or		a, h
		jr		z, xs_nogap
		ld		b, l
		ld		hl, [xs_prev]
		call	xb_put_span
xs_nogap:
		ld		a, [xs_ttype]
		or		a, a
		jr		nz, xs_copy_span
		; word token: param?
		ld		a, [xs_i]
		ld		de, xs_tname
		call	tok_copy
		xor		a, a
		ld		[xs_p], a
xs_pl:
		ld		a, [mc_np]
		ld		b, a
		ld		a, [xs_p]
		cp		a, b
		jr		nc, xs_copy_span
		ld		a, [xs_p]
		call	pblk_pio
		ld		hl, xs_tname
		call	pool_str_eq
		jr		z, xs_sub
		ld		a, [xs_p]
		inc		a
		ld		[xs_p], a
		jr		xs_pl
xs_sub:
		ld		a, [xs_p]
		ld		l, a
		ld		h, 0
		add		hl, hl
		ld		e, l
		ld		d, h
		add		hl, hl
		add		hl, de				; HL = p * 6
		ld		de, mac_argtab
		add		hl, de				; HL = entry
		ld		de, xca_src
		ld		bc, 4
		ldir						; xca_src = arg arena offset
		ld		e, [hl]
		inc		hl
		ld		d, [hl]				; DE = arg length
		call	xb_copy_are
		jr		xs_next
xs_copy_span:
		ld		hl, [xs_tptr]
		ld		a, [xs_tlen]
		ld		b, a
		call	xb_put_span
xs_next:
		ld		hl, [xs_tptr]
		ld		a, [xs_tlen]
		ld		e, a
		ld		d, 0
		add		hl, de
		ld		[xs_prev], hl
		ld		a, [xs_i]
		inc		a
		ld		[xs_i], a
		jp		xs_l
xs_tail:
		ld		hl, [xs_prev]
		call	xb_put_str
		ld		a, 10
		call	xb_put8
		ret

; ---------------------------------------------------------------------------
;	p3_mnem_hook: called at the start of pl_mnem with the first word
;	in name_src_buf and [lp] just past it.  CY = handled.
; ---------------------------------------------------------------------------
p3_mnem_hook:
		ld		a, [name_src_buf]
		or		a, a
		ret		z					; NC: nothing to do
		; peek the second token: "MACRO" ?
		ld		hl, [lp]
		call	tok_one
		jr		nc, pmh_lookup
		ld		de, [tok_start_ptr]
		ld		a, l
		sub		a, e
		cp		a, 5
		jr		nz, pmh_lookup
		ld		l, e
		ld		h, d				; HL = token start
		ld		de, s_kw_macro
		ld		b, 5
pmh_cmp:
		ld		a, [hl]
		call	upcase
		ld		c, a
		ld		a, [de]
		cp		a, c
		jr		nz, pmh_lookup
		inc		hl
		inc		de
		djnz	pmh_cmp
		call	dir_macro
		scf
		ret
pmh_lookup:
		ld		hl, name_src_buf
		ld		de, p3_name
		ld		bc, 64
		ldir
		call	mac_find
		jr		c, pmh_nc
		ld		a, M_BODYPASS
		call	rr8
		ld		b, a
		ld		a, [iter_count]
		cp		a, b
		jr		nz, pmh_nc			; stale definition (earlier pass)
		call	macro_call
		scf
		ret
pmh_nc:
		or		a, a
		ret

; ---------------------------------------------------------------------------
;	REPEAT: REPEAT var, count  ...  ENDR
;	REP_SITE record (18 bytes): +0 site fhash(2), +2 line(2), +4 ctx(2),
;	+6 frozen count(4), +10 scope index(2), +12 frozen flag(1),
;	+13 pad(1), +14 next(4)
; ---------------------------------------------------------------------------
RP_COUNT	:= 6
RP_SCOPE	:= 10
RP_FROZEN	:= 12
RP_NEXT		:= 14
REP_SITE_SZ	:= 18

rp_rec:
		space	4
rp_cnt32:
		space	4
rp_scopeidx:
		dw		0
rp_frz:
		db		0

dir_repeat:
		; counter variable name
		ld		hl, [lp]
		call	p3_scan_word
		jp		c, dr_illparam_cap
		; name_src_buf = var name (uppercase, canonical)
		ld		hl, p3_word
		ld		de, name_src_buf
		ld		bc, 64
		ldir
		; expect ','
		ld		hl, [lp]
dr_skipsp:
		ld		a, [hl]
		cp		a, ' '
		jr		nz, dr_nsp
		inc		hl
		jr		dr_skipsp
dr_nsp:
		cp		a, ','
		jp		nz, dr_illparam_cap
		inc		hl
		ld		[lp], hl
		; site: find; if already frozen, skip evaluation entirely
		call	cur_site
		call	rp_find
		jr		c, dr_eval
		ld		a, [rp_frz]
		or		a, a
		jp		nz, dr_have			; frozen values already in rp_*
dr_eval:
		; evaluate the count expression at [lp]
		call	eval_at_lp			; DE:HL = value
		ld		[rp_cnt32], hl
		ld		[rp_cnt32 + 2], de
		ld		a, [expr_error]
		or		a, a
		jp		nz, dr_illexpr_cap
		; trailing junk?
		call	skip_lp_spaces
		ld		hl, [lp]
		ld		a, [hl]
		or		a, a
		jp		nz, dr_illexpr_cap
		ld		a, [val_type]
		or		a, a
		jp		nz, dr_illparam_cap	; string count: Illegal parameter.
		jr		dr_freeze
dr_freeze:
		; create the site record (or complete the found one);
		; rp_find leaves rp_rec = 0 when the site is new
		ld		hl, [rp_rec]
		ld		de, [rp_rec + 2]
		ld		a, l
		or		a, h
		or		a, e
		or		a, d
		jr		nz, dr_complete
		ld		hl, REP_SITE_SZ
		call	rec_new				; rec_cur = new record
		ld		hl, [rec_cur]
		ld		[rp_rec], hl
		ld		hl, [rec_cur + 2]
		ld		[rp_rec + 2], hl
		xor		a, a
		ld		[se_disp], a
		call	site_store
		ld		a, RP_NEXT
		ld		hl, rep_head
		call	link_rec
dr_complete:
		; rec_cur = rp_rec
		ld		hl, [rp_rec]
		ld		[rec_cur], hl
		ld		hl, [rp_rec + 2]
		ld		[rec_cur + 2], hl
		; store the frozen count (rp_cnt32 was set by the evaluation)
		ld		hl, [rp_cnt32]
		ld		de, [rp_cnt32 + 2]
		ld		a, RP_COUNT
		call	rw32
		; scope index = next auto index
		ld		hl, [rep_scope_ctr]
		ld		[rp_scopeidx], hl
		inc		hl
		ld		[rep_scope_ctr], hl
		push	hl
		ld		hl, [rp_scopeidx]
		ld		a, RP_SCOPE
		call	rw16
		pop		hl
		ld		a, 1
		ld		[rwv], a
		ld		a, RP_FROZEN
		call	rw8
		ld		a, 1
		ld		[pass_changed], a
dr_have:
		; capture the body (always: consumes the source lines)
		ld		a, 2				; ENDR
		call	capture_block
		; count <= 0 -> done (no frame)
		ld		hl, [rp_cnt32 + 2]
		ld		a, h
		or		a, l
		jr		nz, dr_signchk
		ld		hl, [rp_cnt32]
		ld		a, l
		or		a, h
		ret		z					; count == 0
		jr		dr_go
dr_signchk:
		ld		a, [rp_cnt32 + 3]	; high byte sign
		bit		7, a
		ret		nz					; negative count
dr_go:
		; P4 author caps (2026-11-13 rulings; DOS2-only
		; divergences from cross, recorded in DESIGN.md):
		; REPEAT count <= 16384 and REPEAT nesting <= 2.
		ld		hl, [rp_cnt32 + 2]
		ld		a, l
		or		a, h
		jp		nz, dr_toomany		; count >= 65536
		ld		hl, [rp_cnt32]
		ld		de, 16384 + 1
		or		a, a
		sbc		hl, de
		jp		nc, dr_toomany		; count > 16384
		; nesting: count kind-2 (REPEAT) frames already
		; on the source frame stack (this frame is not
		; pushed yet).  Note the file-entry array (istk)
		; cannot be used here: text frames are tracked
		; only in src_frames.
		ld		hl, src_frames
		ld		a, [src_nframes]
		ld		b, a
		ld		c, 0
dr_nest_l:
		ld		e, [hl]
		inc		hl
		ld		d, [hl]
		inc		hl
		push	hl
		ex		de, hl
		ld		de, E_KIND
		add		hl, de
		ld		a, [hl]
		cp		a, 2
		jr		nz, dr_nest_nx
		inc		c
dr_nest_nx:
		pop		hl
		djnz		dr_nest_l
		ld		a, c
		cp		a, 2
		jp		nc, dr_tonest		; already 2 REPEATs deep
		; scope @REPEAT<n>
		ld		bc, [rp_scopeidx]
		ld		hl, s_pfx_repeat
		call	make_auto_name
		ld		hl, p3_sname
		call	scope_push_name
		ret		c
		; define the counter symbol (value 0) in the new scope
		; (name_src_buf still holds the var name: dir_repeat set it
		; before evaluation; scope pushes do not touch it).
		; On later passes the symbol already exists: write the
		; value directly (like cross's dict write) so the reset to
		; 0 does not count as a change and passes can converge.
		; (sym_lookup_scoped cannot be used here: it creates an
		; undefined stub instead of reporting "not found")
		ld		a, [scope_depth]
		call	build_qname		; qname_buf = qualified counter name
		call	set_name_from_qname
		call	sym_find			; NZ + sym_off if the record exists
		jr		z, dr_def_new
		ld		hl, [sym_off]
		ld		[rec_cur], hl
		ld		hl, [sym_off + 2]
		ld		[rec_cur + 2], hl
		ld		hl, 0
		ld		de, 0
		ld		a, SYM_VALUE
		call	rw32
		jr		dr_def_done
dr_def_new:
		ld		hl, 0
		ld		[new_val], hl
		ld		hl, 0
		ld		[new_val + 2], hl
		xor		a, a				; flags: none (local)
		call	sym_define_scoped	; sym_off = record offset
		jp		c, dr_cleanup
dr_def_done:
		; ctx marker
		ld		hl, [rp_scopeidx]
		ld		a, l
		xor		a, 0x5A
		ld		l, a				; marker differs from macro instances
		call	ctx_push
		; text entry kind 2
		ld		a, 2
		call	alloc_text_entry
		jr		c, dr_cleanup2
		; TSTART = TPOS = cap_start; TEND = cap_start + cap_len
		ld		hl, [cap_start]
		ld		[ent_v32], hl
		ld		hl, [cap_start + 2]
		ld		[ent_v32 + 2], hl
		ld		hl, [ate_ent]
		ld		bc, E_TSTART
		call	ent_set32
		ld		hl, [ate_ent]
		ld		bc, E_TPOS
		call	ent_set32
		ld		hl, [cap_start]
		ld		de, [cap_len]
		add		hl, de
		ld		[ent_v32], hl
		ld		hl, [cap_start + 2]
		ld		de, [cap_len + 2]
		adc		hl, de
		ld		[ent_v32 + 2], hl
		ld		hl, [ate_ent]
		ld		bc, E_TEND
		call	ent_set32
		; TLEFT = count
		ld		hl, [rp_cnt32]
		ld		[ent_v32], hl
		ld		hl, [rp_cnt32 + 2]
		ld		[ent_v32 + 2], hl
		ld		hl, [ate_ent]
		ld		bc, E_TLEFT
		call	ent_set32
		; CSYM = counter record offset
		ld		hl, [sym_off]
		ld		[ent_v32], hl
		ld		hl, [sym_off + 2]
		ld		[ent_v32 + 2], hl
		ld		hl, [ate_ent]
		ld		bc, E_CSYM
		call	ent_set32
		; E_CTX = ctx slot index (ctx_sp - 1 after push)
		ld		a, [ctx_sp]
		dec		a
		ld		hl, [ate_ent]
		ld		bc, E_CTX
		add		hl, bc
		ld		[hl], a
		ld		hl, [ate_ent]
		call	fill_text_hdr
		jp		src_push_frame
dr_cleanup2:
		ld		hl, ctx_sp
		dec		[hl]
dr_cleanup:
		call	scope_pop
		ret
dr_illparam_cap:
		ld		hl, s_illegal_param
		call	err_line
		ld		a, 2
		jp		capture_discard
dr_illexpr_cap:
		ld		hl, s_illegal_expr
		call	err_line
		ld		a, 2
		jp		capture_discard
dr_toomany:
		ld		hl, s_rep_many
		jp		err_line
dr_tonest:
		ld		hl, s_rep_nest
		jp		err_line
s_rep_many:
		db		"REPEAT count too large.", 0
s_rep_nest:
		db		"REPEAT nesting too deep.", 0
s_pfx_repeat:
		db		"@REPEAT", 0

;	rp_find: site lookup -> NC if found (rp_rec/rp_frz filled),
;	CY if not found (rp_rec = 0).
rp_find:
		ld		hl, 0
		ld		[rp_rec], hl
		ld		[rp_rec + 2], hl
		ld		hl, [rep_head]
		ld		[mac_walk], hl
		ld		hl, [rep_head + 2]
		ld		[mac_walk + 2], hl
rp_f_l:
		ld		hl, [mac_walk]
		ld		de, [mac_walk + 2]
		ld		a, l
		or		a, h
		or		a, e
		or		a, d
		scf
		ret		z					; not found
		ld		hl, [mac_walk]
		ld		[rec_cur], hl
		ld		hl, [mac_walk + 2]
		ld		[rec_cur + 2], hl
		xor		a, a
		ld		[se_disp], a
		call	site_match
		jr		z, rp_f_have
		ld		a, RP_NEXT
		call	rr32x
		ld		hl, [rr32_buf]
		ld		[mac_walk], hl
		ld		hl, [rr32_buf + 2]
		ld		[mac_walk + 2], hl
		jr		rp_f_l
rp_f_have:
		ld		hl, [rec_cur]
		ld		[rp_rec], hl
		ld		hl, [rec_cur + 2]
		ld		[rp_rec + 2], hl
		ld		a, RP_FROZEN
		call	rr8
		ld		[rp_frz], a
		or		a, a
		jr		z, rp_f_nc			; found but not frozen yet
		ld		a, RP_COUNT
		call	rr32x
		ld		hl, [rr32_buf]
		ld		[rp_cnt32], hl
		ld		hl, [rr32_buf + 2]
		ld		[rp_cnt32 + 2], hl
		ld		a, RP_SCOPE
		call	rr16
		ld		[rp_scopeidx], hl
rp_f_nc:
		or		a, a				; NC
		ret

; ---------------------------------------------------------------------------
;	LINK: LINK name [, name ...]  body  ENDL
;	LBLK record (11 bytes): +0 site(6), +6 next(4), +10 evaluated flag
;	LTRG record (73 bytes): +0 name(64), +64 block offset(4),
;	+68 used(1), +69 next(4)
; ---------------------------------------------------------------------------
LK_NEXT		:= 6
LK_EVAL		:= 10
LBLK_SZ		:= 11
LT_BLK		:= 64
LT_USED		:= 68
LT_NEXT		:= 69
LTRG_SZ		:= 73

lk_blk:
		space	4
lk_any_used:
		db		0
lk_first:
		space	4

dir_link:
		; site record for this LINK block
		call	cur_site
		ld		hl, LBLK_SZ
		call	rec_new
		ld		hl, [rec_cur]
		ld		[lk_blk], hl
		ld		hl, [rec_cur + 2]
		ld		[lk_blk + 2], hl
		xor		a, a
		ld		[se_disp], a
		; same-site re-registration: reuse the existing block record
		call	lk_find_site
		jr		c, lk_fresh
		; found: lk_blk = existing
		ld		hl, [rec_cur]
		ld		[lk_blk], hl
		ld		hl, [rec_cur + 2]
		ld		[lk_blk + 2], hl
		jr		lk_names
lk_fresh:
		; rec_cur must be the candidate record BEFORE link_rec:
		; lk_find_site's failed walk leaves rec_cur at the last
		; chain record, and linking that one created a self-loop.
		ld		hl, [lk_blk]
		ld		[rec_cur], hl
		ld		hl, [lk_blk + 2]
		ld		[rec_cur + 2], hl
		ld		a, LK_NEXT
		ld		hl, lnk_blk_head
		call	link_rec
		ld		hl, [lk_blk]
		ld		[rec_cur], hl
		ld		hl, [lk_blk + 2]
		ld		[rec_cur + 2], hl
		xor		a, a
		ld		[se_disp], a
		call	site_store
		xor		a, a
		ld		[rwv], a
		ld		a, LK_EVAL
		call	rw8				; evaluated = 0
lk_names:
		xor		a, a
		ld		[lk_any_used], a
		ld		hl, 0
		ld		[lk_first], hl
		ld		[lk_first + 2], hl
		; parse trigger names from [lp]
lk_nloop:
		call	skip_lp_spaces
		ld		hl, [lp]
		call	p3_scan_word
		jp		c, lk_illparam
		; qualified name at current scope depth (build_qname
		; takes the plain name from name_src_buf)
		ld		hl, p3_word
		ld		de, name_src_buf
		ld		bc, 64
		ldir
		ld		a, [scope_depth]
		call	build_qname			; qname_buf/qname_len
		call	set_name_from_qname	; -> name_buf/name_len
		call	lk_trg_find			; CY = not found; else trg current
		jr		c, lk_trg_new
		; existing trigger: same block?
		ld		a, LT_BLK
		call	rr32x
		ld		hl, [rr32_buf]
		ld		de, [lk_blk]
		or		a, a
		sbc		hl, de
		jr		nz, lk_dupchk
		ld		hl, [rr32_buf + 2]
		ld		de, [lk_blk + 2]
		or		a, a
		sbc		hl, de
		jr		nz, lk_dupchk
		jr		lk_trg_have			; same block: fine
lk_dupchk:
		; a different block record with same site? then it IS mine
		; (records are equal only if offsets are equal; lk_blk may be
		; a stale duplicate record from an earlier pass)
		ld		hl, s_multdef
		call	err_line
		jr		lk_next_tok
lk_trg_new:
		ld		hl, LTRG_SZ
		call	rec_new
		; name at +0
		ld		hl, rec_cur
		xor		a, a
		call	off_copy_add		; pio = rec + 0
		ld		hl, name_buf
		call	pool_put_str
		ld		hl, [lk_blk]
		ld		de, [lk_blk + 2]
		ld		a, LT_BLK
		call	rw32
		xor		a, a
		ld		[rwv], a
		ld		a, LT_USED
		call	rw8
		ld		a, LT_NEXT
		ld		hl, lnk_trg_head
		call	link_rec
lk_trg_have:
		; check used flag of this trigger (rec_cur = trigger record
		; for existing; for new it is 0)
		ld		a, LT_USED
		call	rr8
		or		a, a
		jr		z, lk_next_tok
		ld		a, 1
		ld		[lk_any_used], a
lk_next_tok:
		call	skip_lp_spaces
		ld		hl, [lp]
		ld		a, [hl]
		cp		a, ','
		jr		nz, lk_names_done
		inc		hl
		ld		[lp], hl
		jp		lk_nloop
lk_names_done:
		ld		hl, [lp]
		ld		a, [hl]
		or		a, a
		jp		nz, lk_illparam		; junk after the name list
		; capture the body (ENDL)
		ld		a, 6
		call	capture_block
		ld		a, [lk_any_used]
		or		a, a
		ret		z					; unused: body discarded
		; replay the body now (kind 3)
		ld		a, 3
		call	alloc_text_entry
		ret		c
		ld		hl, [cap_start]
		ld		[ent_v32], hl
		ld		hl, [cap_start + 2]
		ld		[ent_v32 + 2], hl
		ld		hl, [ate_ent]
		ld		bc, E_TPOS
		call	ent_set32
		ld		hl, [cap_start]
		ld		de, [cap_len]
		add		hl, de
		ld		[ent_v32], hl
		ld		hl, [cap_start + 2]
		ld		de, [cap_len + 2]
		adc		hl, de
		ld		[ent_v32 + 2], hl
		ld		hl, [ate_ent]
		ld		bc, E_TEND
		call	ent_set32
		ld		hl, [ate_ent]
		call	fill_text_hdr
		jp		src_push_frame
lk_illparam:
		ld		hl, s_illegal_param
		call	err_line
		ld		a, 6
		jp		capture_discard

;	lk_find_site: site lookup in LBLK chain -> NC + rec_cur if found
lk_find_site:
		ld		hl, [lnk_blk_head]
		ld		[mac_walk], hl
		ld		hl, [lnk_blk_head + 2]
		ld		[mac_walk + 2], hl
lk_fs_l:
		ld		hl, [mac_walk]
		ld		de, [mac_walk + 2]
		ld		a, l
		or		a, h
		or		a, e
		or		a, d
		scf
		ret		z
		ld		hl, [mac_walk]
		ld		[rec_cur], hl
		ld		hl, [mac_walk + 2]
		ld		[rec_cur + 2], hl
		xor		a, a
		ld		[se_disp], a
		call	site_match
		jr		z, lk_fs_have
		ld		a, LK_NEXT
		call	rr32x
		ld		hl, [rr32_buf]
		ld		[mac_walk], hl
		ld		hl, [rr32_buf + 2]
		ld		[mac_walk + 2], hl
		jr		lk_fs_l
lk_fs_have:
		or		a, a
		ret

;	lk_trg_find: name_buf/name_len -> NC + rec_cur if a trigger with
;	that qualified name exists; CY otherwise
lk_trg_find:
		ld		hl, [lnk_trg_head]
		ld		[mac_walk], hl
		ld		hl, [lnk_trg_head + 2]
		ld		[mac_walk + 2], hl
lk_tf_l:
		ld		hl, [mac_walk]
		ld		de, [mac_walk + 2]
		ld		a, l
		or		a, h
		or		a, e
		or		a, d
		scf
		ret		z
		ld		hl, [mac_walk]
		ld		[rec_cur], hl
		ld		hl, [mac_walk + 2]
		ld		[rec_cur + 2], hl
		ld		hl, rec_cur
		xor		a, a
		call	off_copy_add		; pio = name
		ld		hl, name_buf
		call	pool_str_eq
		jr		z, lk_tf_have
		ld		a, LT_NEXT
		call	rr32x
		ld		hl, [rr32_buf]
		ld		[mac_walk], hl
		ld		hl, [rr32_buf + 2]
		ld		[mac_walk + 2], hl
		jr		lk_tf_l
lk_tf_have:
		or		a, a
		ret

;	link_check_name: called from sym_lookup_scoped for every scoped
;	candidate name (in name_buf/name_len).  Marks matching triggers
;	used.  Preserves all registers.
link_check_name:
		push	af
		push	bc
		push	de
		push	hl
		push	ix
		ld		hl, [lnk_trg_head]
		ld		[lcn_walk], hl
		ld		hl, [lnk_trg_head + 2]
		ld		[lcn_walk + 2], hl
		; save the pool cursor + rec_cur
		ld		hl, [pio]
		ld		[lcn_pio], hl
		ld		hl, [pio + 2]
		ld		[lcn_pio + 2], hl
		ld		hl, [rec_cur]
		ld		[lcn_rec], hl
		ld		hl, [rec_cur + 2]
		ld		[lcn_rec + 2], hl
lcn_l:
		ld		hl, [lcn_walk]
		ld		de, [lcn_walk + 2]
		ld		a, l
		or		a, h
		or		a, e
		or		a, d
		jr		z, lcn_done
		ld		hl, [lcn_walk]
		ld		[rec_cur], hl
		ld		hl, [lcn_walk + 2]
		ld		[rec_cur + 2], hl
		ld		hl, rec_cur
		xor		a, a
		call	off_copy_add
		ld		hl, name_buf
		call	pool_str_eq
		jr		nz, lcn_next
		; match: used = 1 (and request another pass)
		ld		a, LT_USED
		call	rr8
		or		a, a
		jr		nz, lcn_next
		ld		a, 1
		ld		[rwv], a
		ld		a, LT_USED
		call	rw8
		ld		a, 1
		ld		[pass_changed], a
lcn_next:
		ld		a, LT_NEXT
		call	rr32x
		ld		hl, [rr32_buf]
		ld		[lcn_walk], hl
		ld		hl, [rr32_buf + 2]
		ld		[lcn_walk + 2], hl
		jr		lcn_l
lcn_done:
		ld		hl, [lcn_pio]
		ld		[pio], hl
		ld		hl, [lcn_pio + 2]
		ld		[pio + 2], hl
		ld		hl, [lcn_rec]
		ld		[rec_cur], hl
		ld		hl, [lcn_rec + 2]
		ld		[rec_cur + 2], hl
		pop		ix
		pop		hl
		pop		de
		pop		bc
		pop		af
		ret
lcn_walk:
		space	4
lcn_pio:
		space	4
lcn_rec:
		space	4

;	link_force_check: cross set_evaluated_for_all_links equivalent.
;	Called after each pass: a LINK block that has never been
;	"evaluated" (a full pass has not completed since it was
;	registered) forces one more pass, because references earlier
;	than the LINK line in the file could not mark its triggers
;	during the registration pass.  Marks every block evaluated.
link_force_check:
		ld		hl, [pio]
		ld		[lcn_pio], hl
		ld		hl, [pio + 2]
		ld		[lcn_pio + 2], hl
		ld		hl, [rec_cur]
		ld		[lcn_rec], hl
		ld		hl, [rec_cur + 2]
		ld		[lcn_rec + 2], hl
		ld		hl, [lnk_blk_head]
		ld		[lfc_walk], hl
		ld		hl, [lnk_blk_head + 2]
		ld		[lfc_walk + 2], hl
		xor		a, a
		ld		[lfc_forced], a
lfc_l:
		ld		hl, [lfc_walk]
		ld		de, [lfc_walk + 2]
		ld		a, l
		or		a, h
		or		a, e
		or		a, d
		jr		z, lfc_done
		ld		hl, [lfc_walk]
		ld		[rec_cur], hl
		ld		hl, [lfc_walk + 2]
		ld		[rec_cur + 2], hl
		ld		a, LK_EVAL
		call	rr8
		or		a, a
		jr		nz, lfc_next
		ld		a, 1
		ld		[rwv], a
		ld		a, LK_EVAL
		call	rw8
		ld		a, 1
		ld		[lfc_forced], a
lfc_next:
		ld		a, LK_NEXT
		call	rr32x
		ld		hl, [rr32_buf]
		ld		[lfc_walk], hl
		ld		hl, [rr32_buf + 2]
		ld		[lfc_walk + 2], hl
		jr		lfc_l
lfc_done:
		ld		a, [lfc_forced]
		or		a, a
		jr		z, lfc_x
		ld		a, 1
		ld		[pass_changed], a
lfc_x:
		ld		hl, [lcn_pio]
		ld		[pio], hl
		ld		hl, [lcn_pio + 2]
		ld		[pio + 2], hl
		ld		hl, [lcn_rec]
		ld		[rec_cur], hl
		ld		hl, [lcn_rec + 2]
		ld		[rec_cur + 2], hl
		ret
lfc_walk:
		space	4
lfc_forced:
		db		0

;	p3_stray_kw: ENDR / ENDM / ENDL reached dispatch directly
p3_stray_kw:
		ld		hl, s_syntax
		jp		err_line


; =============================================================================
;	Command-line / global data (referenced by chunk A parser)
; =============================================================================
tail_buf:
		space	130
cmd_ptr:
		dw		0
fn_slot:
		dw		0
in_name:
		space	64
out_name:
		space	64
opt_defs:
		db		0
opt_hex:
		db		0
inc_path_buf:
		space	64
inc_path_valid:
		db		0

;	cleanup_exit: fatal exit path (close files, free mapper, exit 1)
cleanup_exit:
		call	close_all_files
		call	mapper_free_all
		ld		b, 1
		jp		term_raw

; =============================================================================
;	Group encoders
; =============================================================================

; ---- LD --------------------------------------------------------------------
enc_ld:
		call	parse_two_operands
		call	check_ops_ok
		ld		a, [op1_blk + OK_KIND]
		cp		a, OPK_REG8
		jp		z, ld_r8
		cp		a, OPK_IXD
		jp		z, ld_ixd
		cp		a, OPK_PAIR
		jp		z, ld_pair
		cp		a, OPK_MEMNN
		jp		z, ld_memnn
		cp		a, OPK_MEMBCDE
		jp		z, ld_membcde
		cp		a, OPK_SPI
		jp		z, ld_i_a
		cp		a, OPK_SPR
		jp		z, ld_r_a
		jp		bad_op

;	op1 = REG8
ld_r8:
		ld		a, [op2_blk + OK_KIND]
		cp		a, OPK_REG8
		jr		z, ld_r8_r8
		cp		a, OPK_IMM
		jr		z, ld_r8_n
		cp		a, OPK_IXD
		jp		z, ld_r8_ixd
		cp		a, OPK_MEMNN
		jp		z, ld_r8_memnn
		cp		a, OPK_MEMBCDE
		jp		z, ld_r8_membcde
		cp		a, OPK_SPI
		jp		z, ld_a_i
		cp		a, OPK_SPR
		jp		z, ld_a_r
		jp		bad_op
ld_r8_r8:
		; (HL) with an index half-reg operand does not exist
		ld		a, [op1_blk + OK_CODE]
		cp		a, 6
		jr		nz, ld_r8r8_x1
		ld		a, [op2_blk + OK_PFX]
		or		a, a
		jp		nz, bad_op
ld_r8r8_x1:
		ld		a, [op2_blk + OK_CODE]
		cp		a, 6
		jr		nz, ld_r8r8_x2
		ld		a, [op1_blk + OK_PFX]
		or		a, a
		jp		nz, bad_op
ld_r8r8_x2:
		; (HL),(HL) is HALT encoding -> error
		ld		a, [op1_blk + OK_CODE]
		cp		a, 6
		jr		nz, ld_r8r8_go
		ld		a, [op2_blk + OK_CODE]
		cp		a, 6
		jr		z, ld_r8r8_halt
		; pfx from half-reg operand
ld_r8r8_go:
		ld		a, [op1_blk + OK_PFX]
		or		a, a
		jr		nz, ld_r8r8_p1
		ld		a, [op2_blk + OK_PFX]
ld_r8r8_p1:
		call	emit_pfx
		ld		a, [op1_blk + OK_CODE]
		rlca
		rlca
		rlca
		or		a, 0x40
		ld		b, a
		ld		a, [op2_blk + OK_CODE]
		or		a, b
		call	emit8
		ret
ld_r8r8_halt:
		; if either has IX/IY pfx it is (ixh)... code6 has no pfx here;
		; plain (hl),(hl): error
		jp		bad_op
ld_r8_n:
		ld		a, [op1_blk + OK_CODE]
		cp		a, 6
		jr		z, ld_hl_n
		call	emit_pfx1
		ld		a, [op1_blk + OK_CODE]
		rlca
		rlca
		rlca
		or		a, 0x06
		call	emit8
		ld		a, [op2_blk + OK_VAL]
		call	emit8
		ret
ld_hl_n:
		ld		a, 0x36
		call	emit8
		ld		a, [op2_blk + OK_VAL]
		call	emit8
		ret
ld_r8_ixd:
		; dst must not be (HL)
		ld		a, [op1_blk + OK_CODE]
		cp		a, 6
		jp		z, bad_op
		; dst half-reg prefix must match the memory prefix
		ld		a, [op1_blk + OK_PFX]
		or		a, a
		jr		z, ld_r8_ixd_ok
		ld		b, a
		ld		a, [op2_blk + OK_PFX]
		cp		a, b
		jp		nz, bad_op
ld_r8_ixd_ok:
		call	emit_pfx2
		ld		a, [op1_blk + OK_CODE]
		rlca
		rlca
		rlca
		or		a, 0x46
		call	emit8
		ld		a, [op2_blk + OK_DISP]
		call	emit8
		ret
ld_r8_memnn:
		ld		a, [op1_blk + OK_CODE]
		cp		a, 7
		jp		nz, bad_op
		ld		a, 0x3A
		call	emit8
		ld		hl, op2_blk
		call	emit_val16
		ret
ld_r8_membcde:
		ld		a, [op1_blk + OK_CODE]
		cp		a, 7
		jp		nz, bad_op
		ld		a, [op2_blk + OK_CODE]
		or		a, a
		ld		a, 0x0A
		jr		z, ld_rm_1
		ld		a, 0x1A
ld_rm_1:
		call	emit8
		ret
ld_a_i:
		ld		a, [op1_blk + OK_CODE]
		cp		a, 7
		jp		nz, bad_op
		ld		a, 0xED
		call	emit8
		ld		a, 0x57
		call	emit8
		ret
ld_a_r:
		ld		a, [op1_blk + OK_CODE]
		cp		a, 7
		jp		nz, bad_op
		ld		a, 0xED
		call	emit8
		ld		a, 0x5F
		call	emit8
		ret
ld_i_a:
		ld		a, [op2_blk + OK_KIND]
		cp		a, OPK_REG8
		jp		nz, bad_op
		ld		a, [op2_blk + OK_CODE]
		cp		a, 7
		jp		nz, bad_op
		ld		a, 0xED
		call	emit8
		ld		a, 0x47
		call	emit8
		ret
ld_r_a:
		ld		a, [op2_blk + OK_KIND]
		cp		a, OPK_REG8
		jp		nz, bad_op
		ld		a, [op2_blk + OK_CODE]
		cp		a, 7
		jp		nz, bad_op
		ld		a, 0xED
		call	emit8
		ld		a, 0x4F
		call	emit8
		ret

;	op1 = (IX+d)/(IY+d)
ld_ixd:
		ld		a, [op2_blk + OK_KIND]
		cp		a, OPK_REG8
		jr		z, ld_ixd_r8
		cp		a, OPK_IMM
		jr		z, ld_ixd_n
		jp		bad_op
ld_ixd_r8:
		ld		a, [op2_blk + OK_CODE]
		cp		a, 6
		jp		z, bad_op
		; src half-reg prefix must match the memory prefix
		ld		a, [op2_blk + OK_PFX]
		or		a, a
		jr		z, ld_ixd_r8_ok
		ld		b, a
		ld		a, [op1_blk + OK_PFX]
		cp		a, b
		jp		nz, bad_op
ld_ixd_r8_ok:
		call	emit_pfx1
		ld		a, [op2_blk + OK_CODE]
		or		a, 0x70
		call	emit8
		ld		a, [op1_blk + OK_DISP]
		call	emit8
		ret
ld_ixd_n:
		call	emit_pfx1
		ld		a, 0x36
		call	emit8
		ld		a, [op1_blk + OK_DISP]
		call	emit8
		ld		a, [op2_blk + OK_VAL]
		call	emit8
		ret

;	op1 = PAIR
ld_pair:
		ld		a, [op2_blk + OK_KIND]
		cp		a, OPK_IMM
		jr		z, ld_pair_nn
		cp		a, OPK_MEMNN
		jr		z, ld_pair_memnn
		cp		a, OPK_PAIR
		jp		z, ld_sp_hl
		jp		bad_op
ld_pair_nn:
		ld		a, [op1_blk + OK_CODE]
		cp		a, 5
		jr		z, ld_ix_nn
		cp		a, 6
		jr		z, ld_iy_nn
		cp		a, 4
		jp		z, bad_op		; AF has no imm load
		rlca
		rlca
		rlca
		rlca
		or		a, 0x01
		call	emit8
		ld		hl, op2_blk
		call	emit_val16
		ret
ld_ix_nn:
		ld		a, 0xDD
		jr		ld_pnn_1
ld_iy_nn:
		ld		a, 0xFD
ld_pnn_1:
		call	emit8
		ld		a, 0x21
		call	emit8
		ld		hl, op2_blk
		call	emit_val16
		ret
ld_pair_memnn:
		ld		a, [op1_blk + OK_CODE]
		cp		a, 2
		jr		z, ld_hl_memnn
		cp		a, 5
		jr		z, ld_ix_memnn
		cp		a, 6
		jr		z, ld_iy_memnn
		cp		a, 4
		jp		z, bad_op
		; ED form for BC/DE/SP: code 0,1,3 -> 0x4B + code<<4
		rlca
		rlca
		rlca
		rlca
		or		a, 0x4B
		ld		[ld_tmp], a
		ld		a, 0xED
		call	emit8
		ld		a, [ld_tmp]
		call	emit8
		ld		hl, op2_blk
		call	emit_val16
		ret
ld_tmp:
		db		0
ld_hl_memnn:
		ld		a, 0x2A
		call	emit8
		ld		hl, op2_blk
		call	emit_val16
		ret
ld_ix_memnn:
		ld		a, 0xDD
		jr		ld_pm_1
ld_iy_memnn:
		ld		a, 0xFD
ld_pm_1:
		call	emit8
		ld		a, 0x2A
		call	emit8
		ld		hl, op2_blk
		call	emit_val16
		ret
ld_sp_hl:
		; only LD SP, HL/IX/IY
		ld		a, [op1_blk + OK_CODE]
		cp		a, 3
		jp		nz, bad_op
		ld		a, [op2_blk + OK_CODE]
		cp		a, 2
		jr		z, ld_sphl_0
		cp		a, 5
		jr		z, ld_sphl_dd
		cp		a, 6
		jr		z, ld_sphl_fd
		jp		bad_op
ld_sphl_0:
		ld		a, 0xF9
		call	emit8
		ret
ld_sphl_dd:
		ld		a, 0xDD
		jr		ld_sphl_1
ld_sphl_fd:
		ld		a, 0xFD
ld_sphl_1:
		call	emit8
		ld		a, 0xF9
		call	emit8
		ret

;	op1 = (nn)
ld_memnn:
		ld		a, [op2_blk + OK_KIND]
		cp		a, OPK_PAIR
		jr		z, ld_memnn_pair
		cp		a, OPK_REG8
		jr		z, ld_memnn_a
		jp		bad_op
ld_memnn_a:
		ld		a, [op2_blk + OK_CODE]
		cp		a, 7
		jp		nz, bad_op
		ld		a, 0x32
		call	emit8
		ld		hl, op1_blk
		call	emit_val16
		ret
ld_memnn_pair:
		ld		a, [op2_blk + OK_CODE]
		cp		a, 2
		jr		z, ld_mn_hl
		cp		a, 5
		jr		z, ld_mn_ix
		cp		a, 6
		jr		z, ld_mn_iy
		cp		a, 4
		jp		z, bad_op
		rlca
		rlca
		rlca
		rlca
		or		a, 0x43
		ld		[ld_tmp], a
		ld		a, 0xED
		call	emit8
		ld		a, [ld_tmp]
		call	emit8
		ld		hl, op1_blk
		call	emit_val16
		ret
ld_mn_hl:
		ld		a, 0x22
		call	emit8
		ld		hl, op1_blk
		call	emit_val16
		ret
ld_mn_ix:
		ld		a, 0xDD
		jr		ld_mn_1
ld_mn_iy:
		ld		a, 0xFD
ld_mn_1:
		call	emit8
		ld		a, 0x22
		call	emit8
		ld		hl, op1_blk
		call	emit_val16
		ret

;	op1 = (BC)/(DE), op2 = A
ld_membcde:
		ld		a, [op2_blk + OK_KIND]
		cp		a, OPK_REG8
		jp		nz, bad_op
		ld		a, [op2_blk + OK_CODE]
		cp		a, 7
		jp		nz, bad_op
		ld		a, [op1_blk + OK_CODE]
		or		a, a
		ld		a, 0x02
		jr		z, ld_mb_1
		ld		a, 0x12
ld_mb_1:
		call	emit8
		ret

; ---- PUSH / POP --------------------------------------------------------------
enc_push:
		ld		a, 0xC5
		jr		enc_pushpop
enc_pop:
		ld		a, 0xC1
enc_pushpop:
		ld		[pp_base], a
		ld		hl, op1_blk
		ld		[op_dst], hl
		call	parse_operand
		call	check_ops_ok
		ld		a, [op1_blk + OK_KIND]
		cp		a, OPK_PAIR
		jp		nz, bad_op
		ld		a, [op1_blk + OK_CODE]
		cp		a, 5
		jr		z, pp_ix
		cp		a, 6
		jr		z, pp_iy
		cp		a, 4
		jr		z, pp_af
		cp		a, 3
		jp		z, bad_op		; SP cannot be pushed
		rlca
		rlca
		rlca
		rlca
		ld		c, a
		ld		a, [pp_base]
		or		a, c
		call	emit8
		ret
pp_af:
		ld		a, [pp_base]
		cp		a, 0xC5
		ld		a, 0xF5
		jr		z, pp_af_1
		ld		a, 0xF1
pp_af_1:
		call	emit8
		ret
pp_ix:
		ld		a, 0xDD
		jr		pp_ixy
pp_iy:
		ld		a, 0xFD
pp_ixy:
		call	emit8
		ld		a, [pp_base]
		cp		a, 0xC5
		ld		a, 0xE5
		jr		z, pp_ixy_1
		ld		a, 0xE1
pp_ixy_1:
		call	emit8
		ret
pp_base:
		db		0

; ---- ALU ---------------------------------------------------------------------
;	A = alu index (0 ADD,1 ADC,2 SUB,3 SBC,4 AND,5 XOR,6 OR,7 CP)
alu_idx:
		db		0
enc_alu:
		ld		[alu_idx], a
		call	parse_two_operands
		call	check_ops_ok
		ld		a, [n_ops]
		cp		a, 2
		jr		z, alu_two
		; single operand: the A-form operand is op1
		ld		hl, op1_blk
		ld		[alu_src], hl
		jp		alu_emit
alu_two:
		; if op1 is a pair (HL/IX/IY) and mnemonic allows pair form:
		ld		a, [op1_blk + OK_KIND]
		cp		a, OPK_PAIR
		jr		z, alu_pair_form
		; else op1 must be A; src = op2
		ld		a, [op1_blk + OK_KIND]
		cp		a, OPK_REG8
		jp		nz, bad_op
		ld		a, [op1_blk + OK_CODE]
		cp		a, 7
		jp		nz, bad_op
		ld		hl, op2_blk
		ld		[alu_src], hl
		jp		alu_emit
alu_src:
		dw		0
alu_pair_form:
		ld		a, [alu_idx]
		or		a, a				; ADD?
		jr		z, alu_add_pair
		cp		a, 1				; ADC?
		jr		z, alu_adc_pair
		cp		a, 3				; SBC?
		jp		z, alu_sbc_pair
		jp		bad_op
alu_add_pair:
		ld		a, [op2_blk + OK_KIND]
		cp		a, OPK_PAIR
		jp		nz, bad_op
		; op1 code: 2=HL (no pfx), 5=IX (DD), 6=IY (FD)
		ld		a, [op1_blk + OK_CODE]
		cp		a, 2
		jr		z, aap_hl
		cp		a, 5
		jr		z, aap_ix
		cp		a, 6
		jr		z, aap_iy
		jp		bad_op
aap_hl:
		ld		a, [op2_blk + OK_CODE]
		cp		a, 4
		jp		z, bad_op
		cp		a, 5
		jp		z, bad_op
		cp		a, 6
		jp		z, bad_op
		rlca
		rlca
		rlca
		rlca
		or		a, 0x09
		call	emit8
		ret
aap_ix:
		ld		a, 0xDD
		jr		aap_ixy
aap_iy:
		ld		a, 0xFD
aap_ixy:
		call	emit8
		ld		a, [op2_blk + OK_CODE]
		; for IX: pair codes map: BC0 DE1 IX2 SP3 (IY similar)
		cp		a, 5
		jr		z, aap_c2
		cp		a, 6
		jr		z, aap_c2
		cp		a, 4
		jp		z, bad_op
		jr		aap_emit
aap_c2:
		ld		a, 2
aap_emit:
		rlca
		rlca
		rlca
		rlca
		or		a, 0x09
		call	emit8
		ret
alu_adc_pair:
		ld		a, [op1_blk + OK_CODE]
		cp		a, 2
		jp		nz, bad_op
		ld		a, [op2_blk + OK_KIND]
		cp		a, OPK_PAIR
		jp		nz, bad_op
		ld		a, [op2_blk + OK_CODE]
		cp		a, 4
		jp		z, bad_op
		cp		a, 5
		jp		z, bad_op
		cp		a, 6
		jp		z, bad_op
		rlca
		rlca
		rlca
		rlca
		or		a, 0x4A
		ld		[ld_tmp], a
		ld		a, 0xED
		call	emit8
		ld		a, [ld_tmp]
		call	emit8
		ret
alu_sbc_pair:
		ld		a, [op1_blk + OK_CODE]
		cp		a, 2
		jp		nz, bad_op
		ld		a, [op2_blk + OK_KIND]
		cp		a, OPK_PAIR
		jp		nz, bad_op
		ld		a, [op2_blk + OK_CODE]
		cp		a, 4
		jp		z, bad_op
		cp		a, 5
		jp		z, bad_op
		cp		a, 6
		jp		z, bad_op
		rlca
		rlca
		rlca
		rlca
		or		a, 0x42
		ld		[ld_tmp], a
		ld		a, 0xED
		call	emit8
		ld		a, [ld_tmp]
		call	emit8
		ret
alu_emit:
		; src block in [alu_src]
		ld		hl, [alu_src]
		ld		b, OK_KIND
		call	blk_get
		cp		a, OPK_REG8
		jr		z, ale_reg8
		cp		a, OPK_IXD
		jr		z, ale_ixd
		cp		a, OPK_IMM
		jr		z, ale_imm
		jp		bad_op
ale_reg8:
		ld		hl, [alu_src]
		ld		b, OK_PFX
		call	blk_get
		call	emit_pfx
		ld		a, [alu_idx]
		rlca
		rlca
		rlca
		or		a, 0x80
		ld		b, a
		ld		hl, [alu_src]
		push	bc
		ld		b, OK_CODE
		call	blk_get
		pop		bc
		or		a, b
		call	emit8
		ret
ale_ixd:
		ld		hl, [alu_src]
		ld		b, OK_PFX
		call	blk_get
		call	emit_pfx
		ld		a, [alu_idx]
		rlca
		rlca
		rlca
		or		a, 0x86
		call	emit8
		ld		hl, [alu_src]
		ld		b, OK_DISP
		call	blk_get
		call	emit8
		ret
ale_imm:
		ld		a, [alu_idx]
		rlca
		rlca
		rlca
		or		a, 0xC6
		call	emit8
		ld		hl, [alu_src]
		ld		b, OK_VAL
		call	blk_get
		call	emit8
		ret

; ---- INC / DEC ----------------------------------------------------------------
enc_inc:
		ld		a, 0x04
		jr		enc_incdec
enc_dec:
		ld		a, 0x05
enc_incdec:
		ld		[id_base], a
		ld		hl, op1_blk
		ld		[op_dst], hl
		call	parse_operand
		call	check_ops_ok
		ld		a, [op1_blk + OK_KIND]
		cp		a, OPK_REG8
		jr		z, id_reg8
		cp		a, OPK_IXD
		jr		z, id_ixd
		cp		a, OPK_PAIR
		jr		z, id_pair
		jp		bad_op
id_reg8:
		call	emit_pfx1
		ld		a, [op1_blk + OK_CODE]
		rlca
		rlca
		rlca
		ld		c, a
		ld		a, [id_base]
		or		a, c
		call	emit8
		ret
id_ixd:
		call	emit_pfx1
		ld		a, [id_base]
		cp		a, 0x04
		ld		a, 0x34
		jr		z, id_ixd_1
		ld		a, 0x35
id_ixd_1:
		call	emit8
		ld		a, [op1_blk + OK_DISP]
		call	emit8
		ret
id_pair:
		ld		a, [op1_blk + OK_CODE]
		cp		a, 5
		jr		z, id_ix
		cp		a, 6
		jr		z, id_iy
		cp		a, 4
		jp		z, bad_op
		rlca
		rlca
		rlca
		rlca
		ld		b, a
		ld		a, [id_base]
		cp		a, 0x04
		ld		a, 0x03
		jr		z, id_p_1
		ld		a, 0x0B
id_p_1:
		or		a, b
		call	emit8
		ret
id_ix:
		ld		a, 0xDD
		jr		id_ixy
id_iy:
		ld		a, 0xFD
id_ixy:
		call	emit8
		ld		a, [id_base]
		cp		a, 0x04
		ld		a, 0x23
		jr		z, id_ixy_1
		ld		a, 0x2B
id_ixy_1:
		call	emit8
		ret
id_base:
		db		0

; ---- Relative branch helper -----------------------------------------------------
;	emit_rel8: target value in DE:HL (from op1_blk); instruction size
;	already partially emitted: rel = target - (pc_at_entry + 2).
;	[rel_base] must hold pc at instruction start (set by caller).
rel_base:
		space	4
emit_rel8:
		; diff = target(32) - (rel_base + 2), signed
		ld		[rel_tgt], hl
		ld		[rel_tgt + 2], de
		ld		hl, [rel_base]
		inc		hl
		inc		hl
		ld		[lv], hl
		ld		hl, [rel_base + 2]
		ld		[lv + 2], hl
		jr		nc, er_nc
		inc		hl
		ld		[lv + 2], hl
er_nc:
		ld		hl, [rel_tgt]
		ld		[rv], hl
		ld		hl, [rel_tgt + 2]
		ld		[rv + 2], hl
		; resv = rv - lv  (note sub32 computes lv - rv; swap roles)
		ld		hl, lv
		ld		de, rv
		ld		b, 4
er_swap:
		ld		a, [hl]
		ld		c, a
		ld		a, [de]
		ld		[hl], a
		ld		a, c
		ld		[de], a
		inc		hl
		inc		de
		djnz		er_swap
		call	sub32			; resv = lv(now target) - rv(now base+2)
		; range check in final pass: resv must be -128..127
		ld		a, [final_pass]
		or		a, a
		jr		z, er_emit
		ld		hl, resv + 1
		ld		a, [resv + 3]
		and		a, 0x80
		jr		nz, er_neg
		; positive: bytes 1..3 must be 0 and byte0 <= 127
		ld		a, [hl]
		or		a, a
		jr		nz, er_range
		inc		hl
		ld		a, [hl]
		or		a, a
		jr		nz, er_range
		inc		hl
		ld		a, [hl]
		or		a, a
		jr		nz, er_range
		ld		a, [resv]
		and		a, 0x80
		jr		nz, er_range
		jr		er_emit
er_neg:
		; negative: bytes 1..3 must be 0xFF,0xFF,0xFF... resv+1..3 = FF
		ld		a, [hl]
		cp		a, 0xFF
		jr		nz, er_range
		inc		hl
		ld		a, [hl]
		cp		a, 0xFF
		jr		nz, er_range
		inc		hl
		ld		a, [hl]
		cp		a, 0xFF
		jr		nz, er_range
		ld		a, [resv]
		and		a, 0x80
		jr		z, er_range
er_emit:
		ld		a, [resv]
		call	emit8
		ret
er_range:
		ld		hl, s_relrang
		call	err_line
		jr		er_emit
s_relrang:
		db		"relative jump out of range.", 0
rel_tgt:
		space	4

;	set_rel_base: rel_base = pc_val
set_rel_base:
		ld		hl, [pc_val]
		ld		[rel_base], hl
		ld		hl, [pc_val + 2]
		ld		[rel_base + 2], hl
		ret

; ---- JP / JR / DJNZ / CALL / RET / RST ------------------------------------------
enc_jp:
		xor		a, a
		ld		[tpc_eol_ok], a
		call	try_parse_cond
		jr		c, jp_cc
		; no condition
		ld		hl, op1_blk
		ld		[op_dst], hl
		call	parse_operand
		call	check_ops_ok
		ld		a, [op1_blk + OK_KIND]
		cp		a, OPK_IMM
		jr		z, jp_nn
		cp		a, OPK_REG8
		jr		z, jp_hl
		cp		a, OPK_IXD
		jr		z, jp_ixd
		cp		a, OPK_PAIR
		jr		z, jp_pair
		jp		bad_op
jp_pair:
		; jp hl / jp ix / jp iy (ZMA syntax for jp (hl) etc.)
		ld		a, [op1_blk + OK_CODE]
		cp		a, 2
		jr		z, jp_pair_hl
		cp		a, 5
		jr		z, jp_pair_dd
		cp		a, 6
		jr		z, jp_pair_fd
		jp		bad_op
jp_pair_hl:
		ld		a, 0xE9
		call	emit8
		ret
jp_pair_dd:
		ld		a, 0xDD
		jr		jp_pair_1
jp_pair_fd:
		ld		a, 0xFD
jp_pair_1:
		call	emit8
		ld		a, 0xE9
		call	emit8
		ret
jp_nn:
		ld		a, 0xC3
		call	emit8
		ld		hl, op1_blk
		call	emit_val16
		ret
jp_hl:
		ld		a, [op1_blk + OK_CODE]
		cp		a, 6
		jp		nz, bad_op
		ld		a, 0xE9
		call	emit8
		ret
jp_ixd:
		call	emit_pfx1
		ld		a, 0xE9
		call	emit8
		ret
jp_cc:
		ld		hl, op1_blk
		ld		[op_dst], hl
		call	parse_operand
		call	check_ops_ok
		ld		a, [op1_blk + OK_KIND]
		cp		a, OPK_IMM
		jp		nz, bad_op
		ld		a, [tpc_code]
		rlca
		rlca
		rlca
		or		a, 0xC2
		call	emit8
		ld		hl, op1_blk
		call	emit_val16
		ret

enc_jr:
		call	set_rel_base
		xor		a, a
		ld		[tpc_eol_ok], a
		call	try_parse_cond
		jr		c, jr_cc
		ld		hl, op1_blk
		ld		[op_dst], hl
		call	parse_operand
		call	check_ops_ok
		ld		a, [op1_blk + OK_KIND]
		cp		a, OPK_IMM
		jp		nz, bad_op
		ld		a, 0x18
		call	emit8
		call	load_val1
		call	emit_rel8
		ret
jr_cc:
		; only NZ/Z/NC/C allowed
		ld		a, [tpc_code]
		cp		a, 4
		jp		nc, bad_op
		ld		[jr_cc_code], a
		ld		hl, op1_blk
		ld		[op_dst], hl
		call	parse_operand
		call	check_ops_ok
		ld		a, [jr_cc_code]
		rlca
		rlca
		rlca
		or		a, 0x20
		call	emit8
		call	load_val1
		call	emit_rel8
		ret
jr_cc_code:
		db		0

enc_djnz:
		call	set_rel_base
		ld		hl, op1_blk
		ld		[op_dst], hl
		call	parse_operand
		call	check_ops_ok
		ld		a, 0x10
		call	emit8
		call	load_val1
		call	emit_rel8
		ret

enc_call:
		xor		a, a
		ld		[tpc_eol_ok], a
		call	try_parse_cond
		jr		c, call_cc
		ld		hl, op1_blk
		ld		[op_dst], hl
		call	parse_operand
		call	check_ops_ok
		ld		a, [op1_blk + OK_KIND]
		cp		a, OPK_IMM
		jp		nz, bad_op
		ld		a, 0xCD
		call	emit8
		ld		hl, op1_blk
		call	emit_val16
		ret
call_cc:
		ld		hl, op1_blk
		ld		[op_dst], hl
		call	parse_operand
		call	check_ops_ok
		ld		a, [tpc_code]
		rlca
		rlca
		rlca
		or		a, 0xC4
		call	emit8
		ld		hl, op1_blk
		call	emit_val16
		ret

enc_ret:
		call	skip_lp_spaces
		call	lp_at_end
		jr		z, ret_plain
		ld		a, 1
		ld		[tpc_eol_ok], a
		call	try_parse_cond
		jp		nc, bad_op
		ld		a, [tpc_code]
		rlca
		rlca
		rlca
		or		a, 0xC0
		call	emit8
		ret
ret_plain:
		ld		a, 0xC9
		call	emit8
		ret

enc_rst:
		ld		hl, op1_blk
		ld		[op_dst], hl
		call	parse_operand
		call	check_ops_ok
		ld		a, [op1_blk + OK_KIND]
		cp		a, OPK_IMM
		jp		nz, bad_op
		ld		a, [op1_blk + OK_VAL]
		and		a, 0x38
		or		a, 0xC7
		call	emit8
		ret

; ---- IN / OUT -------------------------------------------------------------------
enc_in:
		call	parse_two_operands
		call	check_ops_ok
		ld		a, [op2_blk + OK_KIND]
		cp		a, OPK_PORTC
		jr		z, in_c
		cp		a, OPK_MEMNN
		jr		z, in_n
		jp		bad_op
in_c:
		ld		a, [op1_blk + OK_KIND]
		cp		a, OPK_REG8
		jp		nz, bad_op
		ld		a, 0xED
		call	emit8
		ld		a, [op1_blk + OK_CODE]
		rlca
		rlca
		rlca
		or		a, 0x40
		call	emit8
		ret
in_n:
		ld		a, [op1_blk + OK_KIND]
		cp		a, OPK_REG8
		jp		nz, bad_op
		ld		a, [op1_blk + OK_CODE]
		cp		a, 7
		jp		nz, bad_op
		ld		a, 0xDB
		call	emit8
		ld		a, [op2_blk + OK_VAL]
		call	emit8
		ret

enc_out:
		call	parse_two_operands
		call	check_ops_ok
		ld		a, [op1_blk + OK_KIND]
		cp		a, OPK_PORTC
		jr		z, out_c
		cp		a, OPK_MEMNN
		jr		z, out_n
		jp		bad_op
out_c:
		ld		a, [op2_blk + OK_KIND]
		cp		a, OPK_REG8
		jp		nz, bad_op
		ld		a, 0xED
		call	emit8
		ld		a, [op2_blk + OK_CODE]
		rlca
		rlca
		rlca
		or		a, 0x41
		call	emit8
		ret
out_n:
		ld		a, [op2_blk + OK_KIND]
		cp		a, OPK_REG8
		jp		nz, bad_op
		ld		a, [op2_blk + OK_CODE]
		cp		a, 7
		jp		nz, bad_op
		ld		a, 0xD3
		call	emit8
		ld		a, [op1_blk + OK_VAL]
		call	emit8
		ret

; ---- EX / IM ----------------------------------------------------------------------
enc_ex:
		call	parse_two_operands
		call	check_ops_ok
		; (SP), HL/IX/IY
		ld		a, [op1_blk + OK_KIND]
		cp		a, OPK_PAIR
		jp		nz, bad_op
		ld		a, [op1_blk + OK_PAREN]
		or		a, a
		jr		nz, ex_sp
		; DE, HL
		ld		a, [op1_blk + OK_CODE]
		cp		a, 1
		jr		z, ex_dehl
		; AF, AF'
		cp		a, 4
		jr		z, ex_af
		jp		bad_op
ex_dehl:
		ld		a, [op2_blk + OK_KIND]
		cp		a, OPK_PAIR
		jp		nz, bad_op
		ld		a, [op2_blk + OK_CODE]
		cp		a, 2
		jp		nz, bad_op
		ld		a, 0xEB
		call	emit8
		ret
ex_af:
		ld		a, [op2_blk + OK_KIND]
		cp		a, OPK_AFS
		jp		nz, bad_op
		ld		a, 0x08
		call	emit8
		ret
ex_sp:
		ld		a, [op1_blk + OK_CODE]
		cp		a, 3
		jp		nz, bad_op
		ld		a, [op2_blk + OK_KIND]
		cp		a, OPK_PAIR
		jp		nz, bad_op
		ld		a, [op2_blk + OK_CODE]
		cp		a, 2
		jr		z, ex_sp_hl
		cp		a, 5
		jr		z, ex_sp_dd
		cp		a, 6
		jr		z, ex_sp_fd
		jp		bad_op
ex_sp_hl:
		ld		a, 0xE3
		call	emit8
		ret
ex_sp_dd:
		ld		a, 0xDD
		jr		ex_sp_1
ex_sp_fd:
		ld		a, 0xFD
ex_sp_1:
		call	emit8
		ld		a, 0xE3
		call	emit8
		ret

enc_im:
		ld		hl, op1_blk
		ld		[op_dst], hl
		call	parse_operand
		call	check_ops_ok
		ld		a, [op1_blk + OK_VAL]
		ld		hl, im_table
		ld		e, a
		ld		d, 0
		add		hl, de
		ld		a, e
		cp		a, 3
		jp		nc, bad_op
		ld		a, [hl]
		ld		[ld_tmp], a
		ld		a, 0xED
		call	emit8
		ld		a, [ld_tmp]
		call	emit8
		ret
im_table:
		db		0x46, 0x56, 0x5E

; ---- BIT / RES / SET -----------------------------------------------------------------
enc_bit:
		ld		[bit_base], a
		call	parse_two_operands
		call	check_ops_ok
		ld		a, [op1_blk + OK_KIND]
		cp		a, OPK_IMM
		jp		nz, bad_op
		ld		a, [op1_blk + OK_VAL]
		and		a, 7
		rlca
		rlca
		rlca
		ld		c, a
		ld		a, [bit_base]
		or		a, c
		ld		[bit_opc], a
		ld		a, [op2_blk + OK_KIND]
		cp		a, OPK_REG8
		jr		z, bit_reg8
		cp		a, OPK_IXD
		jr		z, bit_ixd
		jp		bad_op
bit_reg8:
		; plain (HL) with CB has pfx=0; half regs not allowed with CB
		ld		a, 0xCB
		call	emit8
		ld		a, [op2_blk + OK_CODE]
		ld		c, a
		ld		a, [bit_opc]
		or		a, c
		call	emit8
		ret
bit_ixd:
		call	emit_pfx2
		ld		a, 0xCB
		call	emit8
		ld		a, [op2_blk + OK_DISP]
		call	emit8
		ld		a, [bit_opc]
		or		a, 6
		call	emit8
		ret
bit_base:
		db		0
bit_opc:
		db		0

; ---- CB shifts ------------------------------------------------------------------------
enc_shift:
		ld		[bit_base], a		; CB base bits (0x00..0x38)
		ld		hl, op1_blk
		ld		[op_dst], hl
		call	parse_operand
		call	check_ops_ok
		ld		a, [op1_blk + OK_KIND]
		cp		a, OPK_REG8
		jr		z, sh_reg8
		cp		a, OPK_IXD
		jr		z, sh_ixd
		jp		bad_op
sh_reg8:
		ld		a, 0xCB
		call	emit8
		ld		a, [op1_blk + OK_CODE]
		ld		c, a
		ld		a, [bit_base]
		or		a, c
		call	emit8
		ret
sh_ixd:
		call	emit_pfx1
		ld		a, 0xCB
		call	emit8
		ld		a, [op1_blk + OK_DISP]
		call	emit8
		ld		a, [bit_base]
		or		a, 6
		call	emit8
		ret

; =============================================================================
;	PHASE 4a: character sets -- CHG_CHAR_SET / MAPPING_CHAR /
;	CHAR_SET_NAME (cross: zma_parse_process_chg_char_set.cpp,
;	zma_information.cpp, zma_parse_expression.cpp)
;
;	A set is a 256-byte translation table.  CHG_CHAR_SET selects a
;	set by (uppercased) name, creating it with an identity table
;	when new.  Before any CHG_CHAR_SET the current set is null:
;	no conversion happens and MAPPING_CHAR is an error ("Default
;	character set cannot be mapped and changed.").  Conversion
;	applies to string/char literals when they are evaluated,
;	except on the do_char_map=false paths (CHG_CHAR_SET's own
;	name, MESSAGE/ERROR operands, INCLUDE -- the latter never
;	goes through the expression literal hooks --, BINARY_LINK).
;	Set records live in the pool: +0 next(4), +4 name string
;	offset(4), +8 table(256).  cs_head = chain head (RAM cell),
;	cs_cur = current record pool offset (0 = none), cs_name_off =
;	pool offset of the current set's name (CHAR_SET_NAME value).
;	cs_cur/cs_name_off are per-pass state (reset_asm_state).
; =============================================================================
cs_head:
		space	4
cs_cur:
		space	4
cs_name_off:
		space	4
cs_suppress:
		db		0
cs_rec:
		space	4
cs_val:
		space	4
cs_nlen:
		dw		0
cs_idx:
		db		0
cs_code:
		db		0
cs_di:
		db		0
cs_a1:
		space	4
cs_a2:
		space	4
cs_a3:
		space	4
cs_a4:
		space	4
cs_best:
		space	4
cs_walk:
		space	4
cs_havelast:
		db		0
cs_row:
		dw		0
cs_hb:
		db		0

;	pio_add_a: pio += A (8-bit add with carry chain)
pio_add_a:
		ld		hl, pio
		add		a, [hl]
		ld		[hl], a
		ret		nc
		inc		hl
		inc		[hl]
		ret		nz
		inc		hl
		inc		[hl]
		ret		nz
		inc		hl
		inc		[hl]
		ret

;	cs_active: CY if literal conversion applies right now
cs_active:
		ld		a, [cs_suppress]
		or		a, a
		jr		nz, csa_no
		ld		hl, cs_cur
		call	off_is_zero
		jr		z, csa_no
		scf
		ret
csa_no:
		or		a, a
		ret

;	cs_map_byte: A = byte -> A = mapped byte (set must be active)
cs_map_byte:
		push	af				; #59: off_copy_add destroys BC:DE,
		ld		hl, cs_cur		; so the byte must ride the stack
		ld		a, 8
		call	off_copy_add	; pio = cs_cur + 8
		pop		af
		call	pio_add_a		; pio += index
		jp		pio_read8

;	cs_map_strbuf: map str_buf[0..str_len) in place when active
cs_map_strbuf:
		call	cs_active
		ret		nc
		ld		hl, str_buf
		ld		bc, [str_len]
		ld		a, b
		or		a, c
		ret		z
cms_l:
		ld		a, [hl]
		push	hl
		push	bc
		call	cs_map_byte
		pop		bc
		pop		hl
		ld		[hl], a
		inc		hl
		dec		bc
		ld		a, b
		or		a, c
		jr		nz, cms_l
		ret

;	cs_map_char: map the B packed bytes of pp_hv when active
cs_map_char:
		call	cs_active
		ret		nc
		ld		a, b
		or		a, a
		ret		z
		ld		hl, pp_hv
		ld		c, b
cmc_l:
		ld		a, [hl]
		push	hl
		push	bc
		call	cs_map_byte
		pop		bc
		pop		hl
		ld		[hl], a
		inc		hl
		dec		c
		jr		nz, cmc_l
		ret

;	cs_rec_ld32: A = disp -> cs_val = 4 bytes at cs_rec+disp
cs_rec_ld32:
		ld		hl, cs_rec
		call	off_copy_add
		ld		hl, cs_val
		ld		b, 4
cr32_l:
		call	pio_read8
		ld		[hl], a
		inc		hl
		call	pio_inc
		djnz	cr32_l
		ret

;	cs_rec_st32: A = disp -> 4 bytes of cs_val stored at cs_rec+disp
cs_rec_st32:
		ld		hl, cs_rec
		call	off_copy_add
		ld		hl, cs_val
		ld		b, 4
cs32_l:
		ld		a, [hl]
		ld		[pw_val], a
		push	hl
		push	bc
		call	pio_write8
		pop		bc
		pop		hl
		inc		hl
		call	pio_inc
		djnz	cs32_l
		ret

;	cs_fill_identity: write the identity table into the
;	record at cs_rec (+8..+263)
cs_fill_identity:
		ld		hl, cs_rec
		ld		a, 8
		call	off_copy_add	; pio = table base
		ld		c, 0
cfi_l:
		ld		a, c
		ld		[pw_val], a
		push	bc
		call	pio_write8
		call	pio_inc
		pop		bc
		inc		c
		jr		nz, cfi_l
		ret

;	#62: charset tables PERSIST across dry passes.  Cross
;	keeps char_set_list (and its tables) in CZMA_INFORMATION
;	for the whole assembly; info.clear() between analyze
;	iterations resets only the current-set selection, and
;	MAPPING_CHAR argument literals are evaluated through
;	the current table, so tables evolve across iterations.
;	Cross also freezes each line's emitted data at its
;	first determination (CZMA_PARSE::is_data_fixed), so
;	its output bytes reflect the FIRST analyze iteration's
;	table states, while its << character map >> dump shows
;	the tables after the output pass (analyze iterations
;	+ 1 executions).  DOS2 therefore: (a) lets tables
;	evolve across dry passes, (b) resets them at the final
;	pass (cs_reset_tables from do_final_pass) so emitted
;	bytes replay pass 1 exactly like cross's frozen data.
;	The earlier #61 reset at every pass start matched the
;	binaries but left the dump at pass-1 state (C2's
;	golden has a +0x20 band over 0x32..0x40 in set TEST
;	from cross-pass evolution).  The former step (c) --
;	rebuilding the dump state for the log's
;	<< character map >> section -- was deleted with the
;	abbreviated zma.log (author ruling 2026-11-13,
;	DESIGN.md section 7 item 8).
cs_reset_tables:
		ld		hl, cs_head
		ld		de, cs_rec
		ld		bc, 4
		ldir
csrt_l:
		ld		hl, cs_rec
		call	off_is_zero
		ret		z
		call	cs_fill_identity
		xor		a, a
		call	cs_rec_ld32		; cs_val = next
		ld		hl, cs_val
		ld		de, cs_rec
		ld		bc, 4
		ldir
		jr		csrt_l

;	(The cs_rebuild_dump_state routine was deleted with
;	the abbreviated zma.log -- see the #62 note above.)

;	cs_find_or_create: name = sbuf_b, length = [cs_nlen]
;	-> cs_cur / cs_name_off updated
cs_find_or_create:
		ld		hl, cs_head
		ld		de, cs_rec
		ld		bc, 4
		ldir
cfc_loop:
		ld		hl, cs_rec
		call	off_is_zero
		jr		z, cfc_create
		ld		a, 4
		call	cs_rec_ld32		; cs_val = name_off
		ld		hl, cs_val
		ld		de, sbuf_a
		call	str_fetch		; BC = name length
		ld		hl, [cs_nlen]
		ld		a, l
		cp		a, c
		jr		nz, cfc_next
		ld		a, h
		cp		a, b
		jr		nz, cfc_next
		ld		hl, sbuf_a
		ld		de, sbuf_b
		ld		a, b
		or		a, c
		jr		z, cfc_found
cfc_cmp:
		ld		a, [de]
		cp		a, [hl]
		jr		nz, cfc_next
		inc		hl
		inc		de
		dec		bc
		ld		a, b
		or		a, c
		jr		nz, cfc_cmp
cfc_found:
		ld		hl, cs_rec
		ld		de, cs_cur
		ld		bc, 4
		ldir
		ld		a, 4
		call	cs_rec_ld32
		ld		hl, cs_val
		ld		de, cs_name_off
		ld		bc, 4
		ldir
		ret
cfc_next:
		xor		a, a
		call	cs_rec_ld32		; cs_val = next
		ld		hl, cs_val
		ld		de, cs_rec
		ld		bc, 4
		ldir
		jp		cfc_loop
cfc_create:
		ld		hl, sbuf_b
		ld		bc, [cs_nlen]
		call	str_intern		; DE:HL = name offset
		push	de
		push	hl
		ld		hl, 264
		call	pool_alloc		; DE:HL = record offset
		ld		[cs_rec], hl
		ld		[cs_rec + 2], de
		ld		hl, cs_head
		ld		de, cs_val
		ld		bc, 4
		ldir
		xor		a, a
		call	cs_rec_st32		; next := old head
		pop		hl
		pop		de
		ld		[cs_val], hl
		ld		[cs_val + 2], de
		ld		a, 4
		call	cs_rec_st32		; name_off
		call	cs_fill_identity
		ld		hl, cs_rec
		ld		de, cs_head
		ld		bc, 4
		ldir
		ld		hl, cs_rec
		ld		de, cs_cur
		ld		bc, 4
		ldir
		ld		a, 4
		call	cs_rec_ld32
		ld		hl, cs_val
		ld		de, cs_name_off
		ld		bc, 4
		ldir
		ret

;	dir_chg_char_set: CHG_CHAR_SET expr
dir_chg_char_set:
		ld		a, 1
		ld		[cs_suppress], a
		call	eval_at_lp		; DE:HL = value
		ld		[cs_val], hl
		ld		[cs_val + 2], de
		xor		a, a
		ld		[cs_suppress], a
		ld		a, [expr_error]
		or		a, a
		jr		nz, dcc_illexpr
		ld		a, [expr_undef]
		ld		b, a
		ld		a, [val_undef]
		or		a, b
		jr		nz, dcc_illexpr
		call	skip_lp_spaces
		call	lp_at_end
		jr		nz, dcc_illparam
		ld		hl, cs_val
		ld		a, [val_type]
		ld		de, sbuf_b
		call	str_of_value	; BC = length of string form
		ld		[cs_nlen], bc
		ld		hl, sbuf_b
		ld		a, b
		or		a, c
		jr		z, dcc_go
dcc_upl:
		ld		a, [hl]
		call	upcase
		ld		[hl], a
		inc		hl
		dec		bc
		ld		a, b
		or		a, c
		jr		nz, dcc_upl
dcc_go:
		jp		cs_find_or_create
dcc_illexpr:
		ld		hl, s_illegal_expr
		jp		err_line
dcc_illparam:
		ld		hl, s_illegal_param
		jp		err_line

;	dmc_arg: evaluate one MAPPING_CHAR argument -> DE:HL integer.
;	CY on error (already reported).
dmc_arg:
		call	eval_at_lp
		ld		a, [expr_error]
		or		a, a
		jr		nz, dmca_err
		ld		a, [val_type]
		or		a, a
		jr		nz, dmca_err	; string result -> Illegal expression.
		ld		a, [expr_undef]
		ld		b, a
		ld		a, [val_undef]
		or		a, b
		jr		nz, dmca_err
		or		a, a			; NC
		ret
dmca_err:
		ld		hl, s_illegal_expr
		call	err_line
		scf
		ret

;	dmc_comma_req: mandatory comma at lp.  CY on error.
dmc_comma_req:
		call	skip_lp_spaces
		call	lp_char
		cp		a, ','
		jr		z, dmcr_ok
		ld		hl, s_illegal_expr
		call	err_line
		scf
		ret
dmcr_ok:
		ld		hl, [lp]
		inc		hl
		ld		[lp], hl
		or		a, a
		ret

;	dmc_comma_opt: optional comma at lp.  CY if one was consumed.
dmc_comma_opt:
		call	skip_lp_spaces
		call	lp_char
		cp		a, ','
		jr		nz, dmco_no
		ld		hl, [lp]
		inc		hl
		ld		[lp], hl
		scf
		ret
dmco_no:
		or		a, a
		ret

;	dir_mapping_char: MAPPING_CHAR start, map [, end [, step]]
dir_mapping_char:
		ld		hl, cs_cur
		call	off_is_zero
		jr		nz, dmc_have
		ld		hl, s_cs_defmap
		jp		err_line
dmc_have:
		call	dmc_arg
		ret		c
		ld		[cs_a1], hl
		ld		[cs_a1 + 2], de
		call	dmc_comma_req
		ret		c
		call	dmc_arg
		ret		c
		ld		[cs_a2], hl
		ld		[cs_a2 + 2], de
		ld		hl, cs_a1
		ld		de, cs_a3
		ld		bc, 4
		ldir					; end := start
		ld		hl, 1
		ld		[cs_a4], hl
		ld		hl, 0
		ld		[cs_a4 + 2], hl	; step := 1
		call	dmc_comma_opt
		jr		nc, dmc_apply
		call	dmc_arg
		ret		c
		ld		[cs_a3], hl
		ld		[cs_a3 + 2], de
		call	dmc_comma_opt
		jr		nc, dmc_apply
		call	dmc_arg
		ret		c
		ld		[cs_a4], hl
		ld		[cs_a4 + 2], de
dmc_apply:
		; direction: signed compare end (cs_a3) vs start (cs_a1)
		ld		hl, [cs_a3 + 2]
		ld		de, [cs_a1 + 2]
		ld		a, h
		xor		a, d
		and		a, 0x80
		jr		nz, dmc_dsign	; sign bits differ
		or		a, a
		sbc		hl, de
		jr		nz, dmc_dhi
		ld		hl, [cs_a3]
		ld		de, [cs_a1]
		or		a, a
		sbc		hl, de
		jr		z, dmc_pos		; equal -> +1
dmc_dhi:
		jr		c, dmc_neg		; end < start
		jr		dmc_pos
dmc_dsign:
		ld		a, [cs_a3 + 3]
		and		a, 0x80
		jr		nz, dmc_neg		; end negative -> end < start
dmc_pos:
		ld		a, 1
		ld		[cs_di], a
		jr		dmc_loop_init
dmc_neg:
		ld		a, 0xFF
		ld		[cs_di], a
dmc_loop_init:
		ld		a, [cs_a1]
		ld		[cs_idx], a
		ld		a, [cs_a2]
		ld		[cs_code], a
dmc_wl:
		ld		hl, cs_cur
		ld		a, 8
		call	off_copy_add
		ld		a, [cs_idx]
		call	pio_add_a
		ld		a, [cs_code]
		ld		[pw_val], a
		call	pio_write8
		ld		a, [cs_idx]
		ld		hl, cs_a3
		cp		a, [hl]
		ret		z				; idx == end byte -> done
		ld		a, [cs_di]
		ld		hl, cs_idx
		add		a, [hl]
		ld		[hl], a
		ld		a, [cs_a4]
		ld		hl, cs_code
		add		a, [hl]
		ld		[hl], a
		jr		dmc_wl
s_cs_defmap:
		db		"Default character set cannot be mapped and changed.", 0

;	cs_strcmp: HL vs DE NUL-terminated strings -> CY if HL < DE,
;	Z if equal, NC/NZ if HL > DE (unsigned byte order)
cs_strcmp:
		ld		a, [de]
		ld		b, a
		ld		a, [hl]
		cp		a, b
		ret		nz				; CY/NZ reflect A-B
		or		a, a
		ret		z				; both NUL -> equal
		inc		hl
		inc		de
		jr		cs_strcmp

;	cs_name_of: HL = ptr to record offset cell -> fetch the
;	record's name into sbuf_a (via cs_val); BC = length
cs_name_of:
		ld		de, cs_rec
		ld		bc, 4
		ldir				; #60: cs_rec = record offset,
		ld		a, 4			; then dereference its name field
		call	cs_rec_ld32		; cs_val = name_off
		ld		hl, cs_val
		ld		de, sbuf_a
		jp		str_fetch

;	(The charmap log section and its helpers were deleted
;	with the abbreviated zma.log -- DESIGN.md section 7
;	item 8.)

; =============================================================================
;	PHASE 4b: BINARY_LINK (cross: zma_parse_process_binary_link.cpp)
;
;	BINARY_LINK <string expression>: the file's bytes become the
;	line's code.  The path expression is evaluated unmapped
;	(do_char_map=false).  Errors (cross): missing/unparseable
;	operand -> "Illegal expression.", non-string result ->
;	"Illegal parameter.", trailing words -> "Too many
;	parameters.", and (quirk) an unopenable file also reports
;	"Too many parameters." in the output process.
;	DOS2 passes: dry passes open the file and take its size via
;	_SEEK-from-end (an unopenable file silently sizes 0, so the
;	assembly converges; the error surfaces in the final pass).
;	The final pass streams the file through emit8 (which
;	also drives the Intel HEX formatting).
; =============================================================================
bl_handle:
		db		0
bl_cnt:
		dw		0

;	bl_seek_end: A = handle -> DE:HL = file size, CY on error
bl_seek_end:
		ld		b, a
		ld		de, 0
		ld		hl, 0
		ld		a, 2			; method 2 = from end
		ld		c, _seek
		call	bdos
		or		a, a
		jr		nz, bse_err
		or		a, a
		ret
bse_err:
		scf
		ret

;	bl_advance: DE:HL added to pc_val and file_off
bl_advance:
		ld		[cs_val], hl
		ld		[cs_val + 2], de
		ld		hl, [pc_val]
		ld		de, [cs_val]
		add		hl, de
		ld		[pc_val], hl
		ld		hl, [pc_val + 2]
		ld		de, [cs_val + 2]
		adc		hl, de
		ld		[pc_val + 2], hl
		ld		hl, [file_off]
		ld		de, [cs_val]
		add		hl, de
		ld		[file_off], hl
		ld		hl, [file_off + 2]
		ld		de, [cs_val + 2]
		adc		hl, de
		ld		[file_off + 2], hl
		ret

dir_binary_link:
		ld		a, 1
		ld		[cs_suppress], a
		call	skip_lp_spaces
		call	lp_at_end
		jp		z, dbl_noarg
		call	eval_at_lp		; DE:HL = value
		ld		[cs_val], hl
		ld		[cs_val + 2], de
		xor		a, a
		ld		[cs_suppress], a
		ld		a, [expr_error]
		or		a, a
		jp		nz, dbl_illexpr
		ld		a, [val_type]
		or		a, a
		jp		z, dbl_illparam	; integer result
		ld		a, [expr_undef]
		ld		b, a
		ld		a, [val_undef]
		or		a, b
		jp		nz, dbl_illparam	; undefined string value
		call	skip_lp_spaces
		call	lp_at_end
		jp		nz, dbl_toomany
		ld		hl, cs_val
		ld		de, sbuf_a
		call	str_fetch		; path bytes -> sbuf_a
		ld		hl, sbuf_a
		ld		de, inc_full	; stage the DOS name (79 max)
		ld		b, 79
dbl_cp:
		ld		a, [hl]
		ld		[de], a
		or		a, a
		jr		z, dbl_cpd
		inc		hl
		inc		de
		djnz	dbl_cp
		xor		a, a
		ld		[de], a
dbl_cpd:
		ld		a, [final_pass]
		or		a, a
		jp		nz, dbl_final
		; dry pass: size probe only
		ld		hl, inc_full
		call	dos_open_read
		ret		c				; silent size 0
		ld		[bl_handle], a
		call	bl_seek_end		; DE:HL = size
		push	de
		push	hl
		ld		a, [bl_handle]
		call	dos_close
		pop		hl
		pop		de
		jp		bl_advance
dbl_final:
		ld		hl, inc_full
		call	dos_open_read
		jp		c, dbl_openerr
		ld		[bl_handle], a
dbl_rd:
		ld		a, [bl_handle]
		ld		hl, str_buf
		ld		de, 256
		call	dos_read		; HL = bytes read
		jr		c, dbl_done
		ld		[bl_cnt], hl
		ld		a, h
		or		a, l
		jr		z, dbl_done
		ld		b, h
		ld		c, l
		ld		hl, str_buf
dbl_em:
		ld		a, [hl]
		push	hl
		push	bc
		call	emit8
		pop		bc
		pop		hl
		inc		hl
		dec		bc
		ld		a, b
		or		a, c
		jr		nz, dbl_em
		ld		hl, [bl_cnt]
		ld		de, 256
		or		a, a
		sbc		hl, de
		jr		z, dbl_rd		; full chunk -> more may follow
dbl_done:
		ld		a, [bl_handle]
		jp		dos_close
dbl_noarg:
		xor		a, a
		ld		[cs_suppress], a
dbl_illexpr:
		ld		hl, s_illegal_expr
		jp		err_line
dbl_illparam:
		ld		hl, s_illegal_param
		jp		err_line
dbl_toomany:
		ld		hl, s_toomany
		jp		err_line
dbl_openerr:
		ld		hl, s_toomany
		jp		err_line

; =============================================================================
;	PHASE 4c: IF / ELSEIF / ELSE / ENDIF -- cross-style sticky
;	conditions and candidate detection (the search is in 4d).
;
;	Branch head records live in the pool (24 bytes):
;	  +0 next(4)     global chain of all head records
;	  +4 site(6)     (file hash, line, ctx hash)
;	  +10 kind(1)    0 IF, 1 ELSEIF, 2 ELSE
;	  +11 cond(1)    sticky condition: 0 unknown, 1 false, 2 true
;	                 (ELSE heads are born 2, never evaluated)
;	  +12 flags(1)   bit0 has_else, bit1 candidate, bit2 unresolved
;	  +13 nbranch(1) branch head count of the block (set at ENDIF)
;	  +14 sel(1)     runtime: selected branch index (0xFF = none)
;	  +15 pad
;	  +16 bnext(4)   next branch head of the same block
;	  +20 size(4)    this branch's size in the current pass
;	                 (0xFFFFFFFF = branch not processed this pass)
;	The runtime stack holds one 20-byte entry per open block:
;	+0 head(4), +4 cur_rec(4), +8 blk_pc(4), +12 blk_file(4),
;	+16 dict_snap(2), +18 state(1), +19 bidx(1).
;	state bits: 0 parent-active, 1 taken, 2 active, 3 choice-mode,
;	4 val-open, 5 val-error, 6 emit, 7 parent-emit.
;
;	Dry passes process every candidate branch (head not
;	sticky-false, stopping after the first sticky-true), with
;	pc/file reset to the block start at each head -- the streaming
;	equivalent of the cross parse-object analyze.  The final pass
;	streams only the selected branch (first sticky-true; ELSE
;	counts as true), so branch heads never reset pc there.
; =============================================================================
BR_NEXT		:= 0
BR_SITE		:= 4
BR_KIND		:= 10
BR_COND		:= 11
BR_FLAGS	:= 12
BR_NBR		:= 13
BR_SEL		:= 14
BR_BNEXT	:= 16
BR_SIZE		:= 20
BR_SZ		:= 24
IE_HEAD		:= 0
IE_REC		:= 4
IE_PC		:= 8
IE_FILE		:= 12
IE_DICT		:= 16
IE_STATE	:= 18
IE_BIDX		:= 19
IE_SZ		:= 20
IF_MAX		:= 10
ST_PACT		:= 0x01
ST_TAKEN	:= 0x02
ST_ACT		:= 0x04
ST_CHM		:= 0x08
ST_VOPEN	:= 0x10
ST_VERR		:= 0x20
ST_EMIT		:= 0x40
ST_PEM		:= 0x80
FR_SZ		:= 8
FR_MAX		:= 24

if_head:
		space	4
if_depth:
		db		0
if_swallow:
		db		0
if_stack:
		space	IF_MAX * IE_SZ
if_ent:
		dw		0
if_state:
		db		0
if_pstate:
		db		0
if_rec:
		space	4
if_walk:
		space	4
if_kind:
		db		0
if_lp_save:
		dw		0
if_sel:
		db		0
if_fresh:
		db		0
if_cond:
		db		0
if_sub:
		space	4
if_bp:
		dw		0
if_pp:
		dw		0
if_dp:
		dw		0
dict_chg:
		dw		0
search_mode:
		db		0
validate_mode:
		db		0
trial_mode:
		db		0
trial_err:
		dw		0
if_any_flagged:
		db		0
if_fail_mode:
		db		0
oa_base:
		db		0
rep_armed:
		db		0
rep_line:
		dw		0
rep_name:
		space	16
gate_tok:
		space	16
frames:
		space	FR_SZ * FR_MAX
nframes:
		db		0

;	if_ent_at: A = depth index -> if_ent = that entry
if_ent_at:
		ld		l, a
		ld		h, 0
		add		hl, hl
		add		hl, hl			; *4
		ld		e, l
		ld		d, h
		add		hl, hl
		add		hl, hl			; *16
		add		hl, de			; *20
		ld		de, if_stack
		add		hl, de
		ld		[if_ent], hl
		ret

;	if_ent_top: if_ent = current top entry (depth > 0)
if_ent_top:
		ld		a, [if_depth]
		dec		a
		jp		if_ent_at

;	if_ld_state / if_st_state: top state <-> [if_state]
if_ld_state:
		call	if_ent_top
		ld		de, IE_STATE
		add		hl, de
		ld		a, [hl]
		ld		[if_state], a
		ret
if_st_state:
		call	if_ent_top
		ld		de, IE_STATE
		add		hl, de
		ld		a, [if_state]
		ld		[hl], a
		ret

;	if_ent_fld: A = disp -> rec_cur = 4-byte field of top entry
;	P4 bug #64: if_ent_top clobbers A with (if_depth - 1), so
;	the displacement must be preserved across the call --
;	without this, every caller silently read the field at
;	disp (depth-1) (IE_HEAD at depth 1) instead of the
;	requested one, e.g. ihc_nok read the head record's
;	BR_COND for ELSEIF/ELSE branches and their content was
;	never emitted.
if_ent_fld:
		push	af
		call	if_ent_top
		pop		af
		ld		e, a
		ld		d, 0
		add		hl, de
		ld		e, [hl]
		inc		hl
		ld		d, [hl]
		inc		hl
		ld		c, [hl]
		inc		hl
		ld		b, [hl]
		ld		[rec_cur], de
		ld		[rec_cur + 2], bc
		ret

;	if_set_rec: rec_cur := if_rec
if_set_rec:
		ld		hl, [if_rec]
		ld		[rec_cur], hl
		ld		hl, [if_rec + 2]
		ld		[rec_cur + 2], hl
		ret

;	if_find_rec: A = kind -> rec_cur = head record for cur_site
;	(created and chained when new)
if_find_rec:
		ld		[if_kind], a
		call	cur_site
		ld		hl, if_head
		ld		de, if_walk
		ld		bc, 4
		ldir
ifr_l:
		ld		hl, if_walk
		call	off_is_zero
		jr		z, ifr_new
		ld		hl, [if_walk]
		ld		[rec_cur], hl
		ld		hl, [if_walk + 2]
		ld		[rec_cur + 2], hl
		ld		a, BR_SITE
		ld		[se_disp], a
		call	site_match
		ret		z
		ld		a, BR_NEXT
		call	rr32x
		ld		hl, rr32_buf
		ld		de, if_walk
		ld		bc, 4
		ldir
		jr		ifr_l
ifr_new:
		ld		hl, BR_SZ
		call	rec_new			; rec_cur = new zeroed record
		ld		a, BR_SITE
		ld		[se_disp], a
		call	site_store
		ld		a, [if_kind]
		ld		[rwv], a
		ld		a, BR_KIND
		call	rw8
		ld		a, 0xFF
		ld		[rwv], a
		ld		a, BR_SEL
		call	rw8
		ld		hl, 0xFFFF
		ld		de, 0xFFFF
		ld		a, BR_SIZE
		call	rw32
		ld		a, [if_kind]
		cp		a, 2
		jr		nz, ifn_link
		ld		a, 2			; ELSE heads are born true
		ld		[rwv], a
		ld		a, BR_COND
		call	rw8
ifn_link:
		ld		a, BR_NEXT
		ld		hl, if_head
		jp		link_rec

;	if_choice_for: -> A = choice assigned to cur_site by the
;	search frames, or 0xFF when none
if_choice_for:
		ld		a, [search_mode]
		or		a, a
		jr		z, icf_none
		ld		a, [nframes]
		or		a, a
		jr		z, icf_none
		ld		hl, frames
		ld		b, a
icf_l:
		push	bc
		push	hl
		ld		de, site_fhash
		ld		b, 6
icf_c:
		ld		a, [de]
		cp		a, [hl]
		jr		nz, icf_nx
		inc		de
		inc		hl
		djnz	icf_c
		pop		hl
		ld		de, 6
		add		hl, de
		ld		a, [hl]
		pop		bc
		ret
icf_nx:
		pop		hl
		ld		de, FR_SZ
		add		hl, de
		pop		bc
		djnz	icf_l
icf_none:
		ld		a, 0xFF
		ret

;	if_eval_cond: evaluate the condition at lp -> A:
;	0 unknown (undefined / string / error), 1 false, 2 true
if_eval_cond:
		call	eval_at_lp		; DE:HL = value
		ld		a, [expr_error]
		or		a, a
		jr		nz, iec_unk
		ld		a, [val_type]
		or		a, a
		jr		nz, iec_unk		; string result -> unknown
		ld		a, [expr_undef]
		ld		b, a
		ld		a, [val_undef]
		or		a, b
		jr		nz, iec_unk
		ld		a, l
		or		a, h
		or		a, e
		or		a, d
		jr		z, iec_f
		ld		a, 2
		ret
iec_f:
		ld		a, 1
		ret
iec_unk:
		xor		a, a
		ret

;	if_report: HL = message; validation error channel
;	(counted silently during trials)
if_report:
		ld		a, [trial_mode]
		or		a, a
		jr		z, ir_real
		push	hl
		ld		hl, [trial_err]
		inc		hl
		ld		[trial_err], hl
		pop		hl
		ret
ir_real:
		jp		report_cross_error

;	if_chain_sel: -> A = index of the first sticky-true branch
;	of block if_rec, or the branch count when none is true
if_chain_sel:
		call	if_set_rec
		ld		b, 0
ics_l:
		ld		a, BR_COND
		call	rr8
		cp		a, 2
		jr		z, ics_hit
		ld		a, BR_BNEXT
		call	rr32x
		ld		hl, rr32_buf
		call	off_is_zero
		jr		z, ics_none
		ld		hl, rr32_buf
		ld		de, rec_cur
		ld		bc, 4
		ldir
		inc		b
		jr		ics_l
ics_hit:
		ld		a, b
		ret
ics_none:
		ld		a, b
		inc		a
		ret

;	if_fin_branch: record the ending branch's size (or the
;	not-processed sentinel) into entry.rec's record
if_fin_branch:
		ld		a, IE_REC
		call	if_ent_fld		; rec_cur = entry.rec
		ld		a, [if_state]
		and		a, ST_ACT
		jr		z, ifb_sent
		call	if_ent_top
		ld		de, IE_PC
		add		hl, de
		ld		[if_bp], hl		; blk_pc pointer
		ld		hl, pc_val
		ld		[if_pp], hl
		ld		hl, if_sub
		ld		[if_dp], hl
		ld		b, 4
		or		a, a			; borrow = 0
ifb_l:
		push	bc
		ld		hl, [if_pp]
		ld		a, [hl]
		inc		hl
		ld		[if_pp], hl
		ld		hl, [if_bp]
		sbc		a, [hl]
		inc		hl
		ld		[if_bp], hl
		ld		hl, [if_dp]
		ld		[hl], a
		inc		hl
		ld		[if_dp], hl
		pop		bc
		djnz	ifb_l
		ld		hl, [if_sub]
		ld		de, [if_sub + 2]
		ld		a, BR_SIZE
		jp		rw32
ifb_sent:
		ld		hl, 0xFFFF
		ld		de, 0xFFFF
		ld		a, BR_SIZE
		jp		rw32

;	if_apply_oa: output_active := oa_base AND (no open block OR
;	the top block's current branch is the emitting one)
if_apply_oa:
		ld		a, [oa_base]
		or		a, a
		jr		z, iao_z
		ld		a, [if_depth]
		or		a, a
		jr		z, iao_one
		call	if_ent_top
		ld		de, IE_STATE
		add		hl, de
		ld		a, [hl]
		and		a, ST_EMIT
		jr		z, iao_z
iao_one:
		ld		a, 1
		ld		[output_active], a
		ret
iao_z:
		xor		a, a
		ld		[output_active], a
		ret

;	if_head_common: process one branch head.  On entry: top entry
;	is the block's, [if_state] mirrors its state, entry.rec is the
;	head's record, [if_kind] its kind, [if_sel] the selection,
;	[if_lp_save] the operand pointer.  Updates [if_state].
if_head_common:
		; ---- validation (winner / trial validation passes) ----
		ld		a, [validate_mode]
		or		a, a
		jr		z, ihc_proc
		ld		a, [final_pass]
		or		a, a
		jr		z, ihc_proc
		ld		a, [if_state]
		and		a, ST_PACT
		jr		z, ihc_proc
		ld		a, [if_state]
		and		a, ST_VOPEN
		jr		z, ihc_proc
		ld		a, [if_kind]
		cp		a, 2
		jr		z, ihc_f2
		ld		hl, [if_lp_save]
		ld		[lp], hl
		call	if_eval_cond
		ld		[if_fresh], a
		jr		ihc_fchk
ihc_f2:
		ld		a, 2
		ld		[if_fresh], a
ihc_fchk:
		or		a, a
		jr		nz, ihc_fnz
		ld		hl, s_if_notres
		call	if_report
		ld		a, [if_state]
		or		a, ST_VERR
		ld		[if_state], a
		jr		ihc_proc
ihc_fnz:
		cp		a, 2
		jr		nz, ihc_ff
		; fresh true: the selection must be this branch; the
		; validation scan closes either way
		ld		a, [if_state]
		and		a, 0xEF			; clear ST_VOPEN
		ld		[if_state], a
		call	if_ld_bidx
		ld		hl, if_sel
		cp		a, [hl]
		jr		z, ihc_proc
		ld		hl, s_if_illcond
		call	if_report
		ld		a, [if_state]
		or		a, ST_VERR
		ld		[if_state], a
		jr		ihc_proc
ihc_ff:
		; fresh false: the selection must not be this branch
		call	if_ld_bidx
		ld		hl, if_sel
		cp		a, [hl]
		jr		nz, ihc_proc
		ld		hl, s_if_illcond
		call	if_report
		ld		a, [if_state]
		or		a, ST_VERR
		ld		[if_state], a
		; ---- processing ----
ihc_proc:
		ld		a, [if_state]
		and		a, ST_PACT
		jp		z, ihc_inact
		ld		a, [if_state]
		and		a, ST_CHM
		jr		z, ihc_nat
		; choice mode: active iff sel == bidx
		call	if_ld_bidx
		ld		hl, if_sel
		cp		a, [hl]
		jp		nz, ihc_inact
		ld		a, [if_state]
		or		a, ST_ACT | ST_TAKEN
		ld		[if_state], a
		and		a, ST_PEM
		ret		z
		ld		a, [if_state]
		or		a, ST_EMIT
		ld		[if_state], a
		ret
ihc_nat:
		ld		a, [if_fail_mode]
		or		a, a
		jr		z, ihc_nok
		ld		a, [final_pass]
		or		a, a
		jr		z, ihc_nok
		; search-failure final pass: like the cross analyze
		; state, no condition counts as fixed except ELSE
		ld		a, [if_kind]
		cp		a, 2
		jp		z, ihc_fsel
		jp		ihc_inact
ihc_nok:
		ld		a, IE_REC
		call	if_ent_fld
		ld		a, BR_COND
		call	rr8
		ld		[if_cond], a	; sticky state
		ld		a, [final_pass]
		or		a, a
		jr		nz, ihc_nfin
		; ---- dry pass ----
		ld		a, [if_state]
		and		a, ST_TAKEN
		jp		nz, ihc_inact	; after a true branch: not processed
		ld		a, [if_cond]
		or		a, a
		jr		nz, ihc_ndry2
		ld		hl, [if_lp_save]
		ld		[lp], hl
		call	if_eval_cond
		or		a, a
		jr		z, ihc_ndry2	; stays unknown (cond = 0)
		ld		[if_cond], a
		ld		[rwv], a
		call	if_ent_rec2		; rec_cur = entry.rec again
		ld		a, BR_COND
		call	rw8				; stick it
		ld		a, [if_cond]
ihc_ndry2:
		cp		a, 1
		jp		z, ihc_inact	; false: branch skipped
		ld		a, [if_state]
		or		a, ST_ACT
		ld		[if_state], a
		ld		a, [if_cond]
		cp		a, 2
		ret		nz				; candidate: not taken yet
		ld		a, [if_state]
		or		a, ST_TAKEN
		ld		[if_state], a
		ret
		; ---- final pass ----
ihc_nfin:
		ld		a, [if_state]
		and		a, ST_TAKEN
		jp		nz, ihc_inact
		ld		a, [if_cond]
		cp		a, 2
		jr		z, ihc_fsel
		cp		a, 1
		jp		z, ihc_inact
		; unknown: evaluate now; definite outcomes stick
		ld		hl, [if_lp_save]
		ld		[lp], hl
		call	if_eval_cond
		or		a, a
		jp		z, ihc_inact	; unknown: not selected
		ld		[if_cond], a
		ld		[rwv], a
		call	if_ent_rec2
		ld		a, BR_COND
		call	rw8
		ld		a, [if_cond]
		cp		a, 2
		jp		nz, ihc_inact
ihc_fsel:
		ld		a, [if_state]
		or		a, ST_ACT | ST_TAKEN
		ld		[if_state], a
		and		a, ST_PEM
		ret		z
		ld		a, [if_state]
		or		a, ST_EMIT
		ld		[if_state], a
		ret
ihc_inact:
		ld		a, [if_state]
		and		a, 0xBB			; clear ST_ACT | ST_EMIT
		ld		[if_state], a
		ret

;	if_ld_bidx: -> A = top entry's branch index
if_ld_bidx:
		call	if_ent_top
		ld		de, IE_BIDX
		add		hl, de
		ld		a, [hl]
		ret

;	if_ent_rec2: rec_cur := top entry's cur_rec
if_ent_rec2:
		ld		a, IE_REC
		jp		if_ent_fld

;	if_close_block: ENDIF bookkeeping for the block whose head
;	record is the top entry's head and whose state is [if_state].
;	Computes branch count / has_else / resolved / candidate from
;	the sticky conditions and this pass's branch sizes, and
;	updates the head record (called on dry passes only).
icb_cnt:
		db		0
icb_flg:
		db		0			; bit0 has_else, bit1 resolved,
							; bit2 still scanning conditions
if_close_block:
		; ---- walk 1: count, has_else, resolved ----
		ld		a, IE_HEAD
		call	if_ent_fld		; rec_cur = head
		xor		a, a
		ld		[icb_cnt], a
		ld		a, 0x04
		ld		[icb_flg], a
icb_w1:
		ld		hl, icb_cnt
		inc		[hl]
		ld		a, BR_KIND
		call	rr8
		cp		a, 2
		jr		nz, icb_k
		ld		a, [icb_flg]
		or		a, 0x01
		ld		[icb_flg], a
icb_k:
		ld		a, [icb_flg]
		and		a, 0x04
		jr		z, icb_nx1
		ld		a, BR_COND
		call	rr8
		cp		a, 2
		jr		z, icb_res
		cp		a, 1
		jr		z, icb_nx1		; false: keep scanning
		ld		a, [icb_flg]	; unknown: unresolved, stop
		and		a, 0xFB
		ld		[icb_flg], a
		jr		icb_nx1
icb_res:
		ld		a, [icb_flg]
		or		a, 0x02
		and		a, 0xFB
		ld		[icb_flg], a
icb_nx1:
		ld		a, BR_BNEXT
		call	rr32x
		ld		hl, rr32_buf
		call	off_is_zero
		jr		z, icb_w1d
		ld		hl, rr32_buf
		ld		de, rec_cur
		ld		bc, 4
		ldir
		jr		icb_w1
icb_w1d:
		ld		a, [icb_flg]
		and		a, 0x04
		jr		z, icb_rs2
		ld		a, [icb_flg]	; all branches false: resolved
		or		a, 0x02
		ld		[icb_flg], a
icb_rs2:
		ld		a, [if_state]
		and		a, ST_CHM
		jr		z, icb_nchm
		ld		a, [icb_flg]	; choice-forced blocks are fixed
		or		a, 0x02
		ld		[icb_flg], a
icb_nchm:
		; ---- write nbranch ----
		ld		a, IE_HEAD
		call	if_ent_fld
		ld		a, [icb_cnt]
		ld		[rwv], a
		ld		a, BR_NBR
		call	rw8
		; ---- walk 2: sizes ----
		ld		a, IE_HEAD
		call	if_ent_fld
		xor		a, a
		ld		[if_szflg], a	; bit0 any processed, bit1
		ld		[if_cmpf], a	; disagree, bit2 any nonzero
icb_w2:
		ld		a, BR_SIZE
		call	rr32x			; rr32_buf = size
		ld		hl, rr32_buf
		ld		a, [hl]
		inc		hl
		or		a, [hl]
		inc		hl
		or		a, [hl]
		inc		hl
		or		a, [hl]
		inc		a				; 0xFFFFFFFF + 1 wraps to 0
		jr		z, icb_nx2		; sentinel: not processed
		ld		a, [if_szflg]
		or		a, 0x01
		ld		[if_szflg], a
		ld		hl, rr32_buf
		ld		a, [hl]
		inc		hl
		or		a, [hl]
		inc		hl
		or		a, [hl]
		inc		hl
		or		a, [hl]
		jr		z, icb_fchk
		ld		a, [if_szflg]
		or		a, 0x04			; nonzero size seen
		ld		[if_szflg], a
icb_fchk:
		ld		a, [if_cmpf]
		or		a, a
		jr		nz, icb_docmp
		ld		a, 1
		ld		[if_cmpf], a
		ld		hl, rr32_buf
		ld		de, if_fstsz
		ld		bc, 4
		ldir
		jr		icb_nx2
icb_docmp:
		ld		hl, rr32_buf
		ld		de, if_fstsz
		ld		b, 4
icb_cl:
		ld		a, [de]
		cp		a, [hl]
		jr		nz, icb_dis
		inc		hl
		inc		de
		djnz	icb_cl
		jr		icb_nx2
icb_dis:
		ld		a, [if_szflg]
		or		a, 0x02
		ld		[if_szflg], a
icb_nx2:
		ld		a, BR_BNEXT
		call	rr32x
		ld		hl, rr32_buf
		call	off_is_zero
		jr		z, icb_w2d
		ld		hl, rr32_buf
		ld		de, rec_cur
		ld		bc, 4
		ldir
		jr		icb_w2
icb_w2d:
		; ---- flags update on the head record ----
		ld		a, IE_HEAD
		call	if_ent_fld
		ld		a, BR_FLAGS
		call	rr8
		and		a, 0x02			; candidate bit is sticky
		ld		[if_flg], a
		ld		a, [icb_flg]
		and		a, 0x01			; has_else
		ld		hl, if_flg
		or		a, [hl]
		ld		[if_flg], a
		ld		a, [if_state]
		and		a, ST_PACT
		jr		z, icb_wflg
		ld		a, [icb_flg]
		and		a, 0x02			; resolved?
		jr		nz, icb_wflg
		ld		a, [if_flg]		; unresolved this pass
		or		a, 0x04
		ld		[if_flg], a
		; undetermined size?
		ld		a, [if_szflg]
		and		a, 0x02
		jr		nz, icb_und
		ld		a, [icb_flg]
		and		a, 0x01			; has_else?
		jr		nz, icb_wflg	; else + agreeing sizes: fixed
		ld		a, [if_szflg]
		and		a, 0x04			; any nonzero processed size
		jr		z, icb_wflg
icb_und:
		ld		a, [if_flg]		; #65c: unresolved this pass and
		and		a, 0x04			; size-dependent: candidate too
		jr		nz, icb_cand	; (cross enumerates unresolved
							; conditions as well as candidates)
		ld		hl, [dict_chg]
		ld		de, [if_dict_snap]
		or		a, a
		sbc		hl, de
		jr		z, icb_wflg
icb_cand:
		ld		a, [if_flg]		; speculative symbols: candidate
		or		a, 0x02
		ld		[if_flg], a
icb_wflg:
		ld		a, [if_flg]
		ld		[rwv], a
		ld		a, BR_FLAGS
		call	rw8
		ld		a, [if_flg]
		and		a, 0x06
		jr		z, icb_wf2
		ld		a, 1
		ld		[if_any_flagged], a
icb_wf2:
		; ---- representative capture for search reporting ----
		ld		a, [if_flg]
		and		a, 0x06
		ret		z
		ld		a, [rep_armed]
		or		a, a
		ret		z
		ld		a, [if_state]
		and		a, ST_PACT
		ret		z
		xor		a, a
		ld		[rep_armed], a
		ld		a, IE_HEAD
		call	if_ent_fld
		ld		a, BR_SITE + 2
		call	rr16
		ld		[rep_line], hl
		ld		hl, [cur_ent]
		ld		de, E_NAME
		add		hl, de
		ld		de, rep_name
		ld		bc, 15
		ldir
		xor		a, a
		ld		[de], a
		ret
if_szflg:
		db		0
if_flg:
		db		0
if_fstsz:
		space	4
if_cmpf:
		db		0
if_dict_snap:
		dw		0

;	dir_if: IF <condition>
dir_if:
		ld		hl, [lp]
		ld		[if_lp_save], hl
		xor		a, a
		call	if_find_rec		; rec_cur = head record
		ld		hl, [rec_cur]
		ld		[if_rec], hl
		ld		hl, [rec_cur + 2]
		ld		[if_rec + 2], hl
		; parent context
		ld		a, [if_depth]
		or		a, a
		jr		z, dif_root
		call	if_ld_state
		ld		a, [if_state]
		ld		[if_pstate], a
		jr		dif_push
dif_root:
		ld		a, ST_ACT | ST_EMIT
		ld		[if_pstate], a
dif_push:
		ld		a, [if_depth]
		cp		a, IF_MAX
		jp		nc, dif_deep
		call	if_ent_at		; entry at index depth
		; entry.head := if_rec, entry.rec := if_rec
		ld		hl, [if_ent]
		ld		de, IE_HEAD
		add		hl, de
		ld		de, [if_rec]
		ld		[hl], e
		inc		hl
		ld		[hl], d
		inc		hl
		ld		de, [if_rec + 2]
		ld		[hl], e
		inc		hl
		ld		[hl], d
		ld		hl, [if_ent]
		ld		de, IE_REC
		add		hl, de
		ld		de, [if_rec]
		ld		[hl], e
		inc		hl
		ld		[hl], d
		inc		hl
		ld		de, [if_rec + 2]
		ld		[hl], e
		inc		hl
		ld		[hl], d
		; entry.pc := pc_val, entry.file := file_off
		ld		hl, [if_ent]
		ld		de, IE_PC
		add		hl, de
		ex		de, hl
		ld		hl, pc_val
		ld		bc, 4
		ldir
		ld		hl, [if_ent]
		ld		de, IE_FILE
		add		hl, de
		ex		de, hl
		ld		hl, file_off
		ld		bc, 4
		ldir
		; entry.dict := dict_chg; entry.bidx := 0
		ld		hl, [if_ent]
		ld		de, IE_DICT
		add		hl, de
		ld		de, [dict_chg]
		ld		[hl], e
		inc		hl
		ld		[hl], d
		ld		hl, [if_ent]
		ld		de, IE_BIDX
		add		hl, de
		xor		a, a
		ld		[hl], a
		; entry.state
		ld		b, a			; B = state under construction
		ld		a, [if_pstate]
		and		a, ST_ACT
		jr		z, dif_s1
		set		0, b
dif_s1:
		ld		a, [if_pstate]
		and		a, ST_EMIT
		jr		z, dif_s2
		set		7, b
dif_s2:
		ld		a, [validate_mode]
		or		a, a
		jr		z, dif_s3
		set		4, b
dif_s3:
		ld		hl, [if_ent]
		ld		de, IE_STATE
		add		hl, de
		ld		[hl], b
		ld		a, [if_depth]
		inc		a
		ld		[if_depth], a
		; selection
		call	if_choice_for	; A = choice or 0xFF
		ld		[if_sel], a
		cp		a, 0xFF
		jr		z, dif_nat
		call	if_ld_state
		ld		a, [if_state]
		or		a, ST_CHM
		ld		[if_state], a
		call	if_st_state
		jr		dif_selset
dif_nat:
		ld		a, [validate_mode]
		or		a, a
		jr		z, dif_selset
		call	if_chain_sel	; A = first sticky-true index/count
		ld		[if_sel], a
dif_selset:
		call	if_set_rec		; rec_cur = head
		ld		a, [if_sel]
		ld		[rwv], a
		ld		a, BR_SEL
		call	rw8
		ld		hl, 0xFFFF		; branch 0 size := sentinel
		ld		de, 0xFFFF
		ld		a, BR_SIZE
		call	rw32
		call	if_ld_state
		call	if_head_common
		call	if_st_state
		jp		if_apply_oa
dif_deep:
		ld		a, [if_swallow]
		inc		a
		ld		[if_swallow], a
		cp		a, 1
		ret		nz				; report only the first level
		ld		hl, s_scope_deep
		jp		err_line

;	dir_elseif / dir_else (kind in A at the shared body)
dir_elseif:
		ld		a, 1
		jr		dle_go
dir_else:
		ld		a, 2
dle_go:
		ld		[if_kind], a
		ld		hl, [lp]
		ld		[if_lp_save], hl
		ld		a, [if_swallow]
		or		a, a
		ret		nz				; swallowed block: nothing
		ld		a, [if_depth]
		or		a, a
		jp		z, dle_stray
		call	if_ld_state
		call	if_fin_branch	; size of the ending branch
		; pc/file reset (dry passes only; in the final pass pc
		; stays at the selected branch's end)
		ld		a, [final_pass]
		or		a, a
		jr		nz, dle_nores
		call	if_ent_top
		ld		de, IE_PC
		add		hl, de			; HL = &blk_pc
		ex		de, hl			; DE = &blk_pc
		ld		hl, pc_val
		ex		de, hl			; HL = &blk_pc, DE = &pc_val
		ld		bc, 4
		ldir					; pc_val := blk_pc
		call	if_ent_top
		ld		de, IE_FILE
		add		hl, de
		ex		de, hl
		ld		hl, file_off
		ex		de, hl
		ld		bc, 4
		ldir					; file_off := blk_file
dle_nores:
		; bidx++
		call	if_ent_top
		ld		de, IE_BIDX
		add		hl, de
		inc		[hl]
		; this head's record
		ld		a, [if_kind]
		call	if_find_rec		; rec_cur = branch record
		ld		hl, [rec_cur]
		ld		[if_rec], hl
		ld		hl, [rec_cur + 2]
		ld		[if_rec + 2], hl
		; prev.bnext := this record (when not already linked)
		ld		a, IE_REC
		call	if_ent_fld		; rec_cur = prev branch
		ld		a, BR_BNEXT
		call	rr32x
		ld		hl, rr32_buf
		ld		de, if_rec
		ld		b, 4
dle_lc:
		ld		a, [de]
		cp		a, [hl]
		jr		nz, dle_link
		inc		hl
		inc		de
		djnz	dle_lc
		jr		dle_linked
dle_link:
		ld		hl, [if_rec]
		ld		de, [if_rec + 2]
		ld		a, BR_BNEXT
		call	rw32
dle_linked:
		; entry.rec := if_rec
		call	if_ent_top
		ld		de, IE_REC
		add		hl, de
		ld		de, [if_rec]
		ld		[hl], e
		inc		hl
		ld		[hl], d
		inc		hl
		ld		de, [if_rec + 2]
		ld		[hl], e
		inc		hl
		ld		[hl], d
		; has_else flag on the head record
		ld		a, [if_kind]
		cp		a, 2
		jr		nz, dle_hc
		ld		a, IE_HEAD
		call	if_ent_fld
		ld		a, BR_FLAGS
		call	rr8
		or		a, 0x01
		ld		[rwv], a
		ld		a, BR_FLAGS
		call	rw8
dle_hc:
		; new branch: inactive until evaluated
		ld		a, [if_state]
		and		a, 0xBB			; clear ST_ACT | ST_EMIT
		ld		[if_state], a
		call	if_head_common
		call	if_st_state
		jp		if_apply_oa
dle_stray:
		ld		hl, s_syntax
		jp		err_line

;	dir_endif: ENDIF
dir_endif:
		ld		a, [if_swallow]
		or		a, a
		jr		z, den_1
		dec		a
		ld		[if_swallow], a
		ret
den_1:
		ld		a, [if_depth]
		or		a, a
		jp		z, dle_stray
		call	if_ld_state
		call	if_fin_branch
		ld		a, [final_pass]
		or		a, a
		jr		nz, den_pop
		; dict snapshot for the candidate test
		call	if_ent_top
		ld		de, IE_DICT
		add		hl, de
		ld		e, [hl]
		inc		hl
		ld		d, [hl]
		ld		[if_dict_snap], de
		call	if_close_block
den_pop:
		ld		hl, if_depth
		dec		[hl]
		jp		if_apply_oa

;	if_gate: -> CY when the line in line_buf must be dropped
;	(inside an inactive IF branch and not itself structural).
;	One label prefix is skipped before the keyword test.
if_gate:
		ld		a, [if_depth]
		or		a, a
		ret		z				; NC: keep
		ld		hl, line_buf
		call	gate_scan		; token -> gate_tok, [gate_delim]
		call	gate_is_struct
		jr		c, ig_keep
		ld		a, [gate_delim]
		cp		a, ':'
		jr		nz, ig_drop
		call	gate_scan		; token after the label
		call	gate_is_struct
		jr		c, ig_keep
ig_drop:
		call	if_ld_state
		ld		a, [if_state]
		and		a, ST_ACT
		jr		nz, ig_keep
		scf
		ret
ig_keep:
		or		a, a			; NC
		ret

;	gate_tok: HL = text -> one upcased token into gate_tok;
;	HL ends at the delimiter, [gate_delim] = the delimiter.
;	Re-entry resumes at HL (used for the post-label token).
gate_scan:
		ld		a, [hl]
		cp		a, ' '
		jr		z, gt_skip
		cp		a, 0x09
		jr		nz, gt_go
gt_skip:
		inc		hl
		jr		gate_scan
gt_go:
		ld		de, gate_tok
		ld		b, 15
gt_l:
		ld		a, [hl]
		call	is_ident_char
		jr		nc, gt_end
		call	upcase
		ld		[de], a
		inc		de
		inc		hl
		djnz	gt_l
gt_end:
		xor		a, a
		ld		[de], a
		ld		a, [hl]
		ld		[gate_delim], a
		ret
gate_delim:
		db		0

;	gate_is_struct: CY when gate_tok is IF/ELSEIF/ELSE/ENDIF
gate_is_struct:
		ld		hl, gate_tok
		ld		de, d_if
		call	str_eq
		jr		z, gis_y
		ld		hl, gate_tok
		ld		de, d_elseif
		call	str_eq
		jr		z, gis_y
		ld		hl, gate_tok
		ld		de, d_else
		call	str_eq
		jr		z, gis_y
		ld		hl, gate_tok
		ld		de, d_endif
		call	str_eq
		jr		z, gis_y
		or		a, a			; NC
		ret
gis_y:
		scf
		ret

s_if_notres:
		db		"No consistent, valid IF layout could be determined.", 0
s_if_illcond:
		db		"Illegal condition.", 0
s_if_limit:
		db		"IF layout search exceeded 1024 candidates; minimum size is not guaranteed.", 0

; =============================================================================
;	PHASE 4d: IF candidate search (cross: resolve_conditions).
;
;	After the fixpoint converges, if any IF head record carries
;	the candidate or unresolved flag, the assembly is re-run
;	under trial branch assignments (DFS in first-encounter order,
;	choices tried 0,1,2,...; a trial = restore + analyze passes
;	+ one validating final pass).  A snapshot of the symbol hash
;	and the pool watermark, taken after -D registration, makes
;	each trial start from identical state.  The winner is the
;	consistent assignment with the smallest output; the search
;	stops with the cross LIMIT error after 1024 evaluations.
;	On failure the cross NOT_RESOLVED / LIMIT error is reported
;	at the representative head and a natural final pass still
;	writes the output (cross writes its analyze-state image).
; =============================================================================
snap_hash:
		space	4
snap_ptop:
		space	4
if_pcnt:
		db		0
if_evals:
		dw		0
best_found:
		db		0
best_nframes:
		db		0
best_size:
		space	4
best_frames:
		space	FR_SZ * FR_MAX
srep_line:
		dw		0
srep_name:
		space	16
if_swap_nm:
		space	16
if_swap_ln:
		dw		0
site6_buf:
		space	6

;	if_snapshot: reserve the hash copy area and record the
;	pool watermark (called once from asm_main, after -D and
;	the DEFAULT string are registered)
if_snapshot:
		ld		hl, 4096
		call	pool_alloc		; DE:HL = block offset
		ld		[snap_hash], hl
		ld		[snap_hash + 2], de
		call	pio_set
		ld		hl, hash_table
		ld		bc, 4096
snap_cp:
		ld		a, [hl]
		ld		[pw_val], a
		push	hl
		push	bc
		call	pio_write8
		call	pio_inc
		pop		bc
		pop		hl
		inc		hl
		dec		bc
		ld		a, b
		or		a, c
		jr		nz, snap_cp
		ld		hl, [pool_top]
		ld		[snap_ptop], hl
		ld		hl, [pool_top + 2]
		ld		[snap_ptop + 2], hl
		ret

;	if_restore: symbol hash and pool back to the snapshot;
;	pool-resident tables are re-initialised (p3_init)
if_restore:
		ld		hl, [snap_hash]
		ld		de, [snap_hash + 2]
		call	pio_set
		ld		hl, hash_table
		ld		bc, 4096
rst_cp:
		call	pio_read8
		ld		[hl], a
		inc		hl
		call	pio_inc
		dec		bc
		ld		a, b
		or		a, c
		jr		nz, rst_cp
		ld		hl, [snap_ptop]
		ld		[pool_top], hl
		ld		hl, [snap_ptop + 2]
		ld		[pool_top + 2], hl
		jp		p3_init

;	if_passes: dry fixpoint passes (max 32) -> CY if converged
if_passes:
		ld		a, 32
		ld		[if_pcnt], a
ifp_l:
		xor		a, a
		ld		[pass_changed], a
		ld		[final_pass], a
		ld		[output_active], a
		call	rewind_source
		call	reset_asm_state
		call	run_pass
		call	link_force_check
		ld		a, [pass_changed]
		or		a, a
		jr		z, ifp_conv
		ld		hl, if_pcnt
		dec		[hl]
		jr		nz, ifp_l
		or		a, a			; NC: did not converge
		ret
ifp_conv:
		scf
		ret

;	if_valpass: one validating final pass (no output file;
;	trial_mode/validate_mode are set by the caller).  Validity
;	is read from [trial_err] and [scope_depth] afterwards.
if_valpass:
		ld		hl, 0
		ld		[trial_err], hl
		ld		a, 1
		ld		[final_pass], a
		xor		a, a
		ld		[output_active], a
		call	rewind_source
		call	reset_asm_state
		jp		run_pass

;	if_scan_flags: -> CY when any head record (kind 0) has the
;	candidate or unresolved flag set
if_scan_flags:
		ld		hl, if_head
		ld		de, if_walk
		ld		bc, 4
		ldir
isf_l:
		ld		hl, if_walk
		call	off_is_zero
		jr		z, isf_no
		ld		hl, [if_walk]
		ld		[rec_cur], hl
		ld		hl, [if_walk + 2]
		ld		[rec_cur + 2], hl
		ld		a, BR_KIND
		call	rr8
		or		a, a
		jr		nz, isf_nx
		ld		a, BR_FLAGS
		call	rr8
		and		a, 0x06
		jr		nz, isf_yes
isf_nx:
		ld		a, BR_NEXT
		call	rr32x
		ld		hl, rr32_buf
		ld		de, if_walk
		ld		bc, 4
		ldir
		jr		isf_l
isf_yes:
		scf
		ret
isf_no:
		or		a, a
		ret

;	if_find_undecided: -> CY + if_rec = first head record that
;	is flagged and not decided by the frames; [site6_buf] =
;	its site.  NC when there is none.
if_find_undecided:
		ld		hl, if_head
		ld		de, if_walk
		ld		bc, 4
		ldir
ifu_l:
		ld		hl, if_walk
		call	off_is_zero
		jr		z, ifu_no
		ld		hl, [if_walk]
		ld		[rec_cur], hl
		ld		hl, [if_walk + 2]
		ld		[rec_cur + 2], hl
		ld		a, BR_KIND
		call	rr8
		or		a, a
		jr		nz, ifu_nx
		ld		a, BR_FLAGS
		call	rr8
		and		a, 0x06
		jr		z, ifu_nx
		; copy the site into site6_buf
		ld		a, BR_SITE
		call	rr16
		ld		[site6_buf], hl
		ld		a, BR_SITE + 2
		call	rr16
		ld		[site6_buf + 2], hl
		ld		a, BR_SITE + 4
		call	rr16
		ld		[site6_buf + 4], hl
		; decided by a frame already?
		ld		a, [nframes]
		or		a, a
		jr		z, ifu_found
		ld		hl, frames
		ld		b, a
ifu_m:
		push	bc
		push	hl
		ld		de, site6_buf
		ld		b, 6
ifu_mc:
		ld		a, [de]
		cp		a, [hl]
		jr		nz, ifu_mn
		inc		de
		inc		hl
		djnz	ifu_mc
		pop		hl
		pop		bc
		jr		ifu_nx			; decided: skip this head
ifu_mn:
		pop		hl
		ld		de, FR_SZ
		add		hl, de
		pop		bc
		djnz	ifu_m
ifu_found:
		ld		hl, [rec_cur]
		ld		[if_rec], hl
		ld		hl, [rec_cur + 2]
		ld		[if_rec + 2], hl
		scf
		ret
ifu_nx:
		ld		a, BR_NEXT
		call	rr32x
		ld		hl, rr32_buf
		ld		de, if_walk
		ld		bc, 4
		ldir
		jp		ifu_l
ifu_no:
		or		a, a
		ret

;	if_rep_fallback: srep := first flagged head (chain order)
;	with the main input file's name
if_rep_fallback:
		ld		hl, if_head
		ld		de, if_walk
		ld		bc, 4
		ldir
irf_l:
		ld		hl, if_walk
		call	off_is_zero
		jr		z, irf_done
		ld		hl, [if_walk]
		ld		[rec_cur], hl
		ld		hl, [if_walk + 2]
		ld		[rec_cur + 2], hl
		ld		a, BR_KIND
		call	rr8
		or		a, a
		jr		nz, irf_nx
		ld		a, BR_FLAGS
		call	rr8
		and		a, 0x06
		jr		z, irf_nx
		ld		a, BR_SITE + 2
		call	rr16
		ld		[srep_line], hl
		jr		irf_done
irf_nx:
		ld		a, BR_NEXT
		call	rr32x
		ld		hl, rr32_buf
		ld		de, if_walk
		ld		bc, 4
		ldir
		jr		irf_l
irf_done:
		ld		hl, in_name
		ld		de, srep_name
		ld		bc, 15
		ldir
		xor		a, a
		ld		[de], a
		ret

;	if_report_at: HL = message; report it in cross format at
;	the representative head (srep_name / srep_line)
if_report_at:
		push	hl
		ld		hl, istk + E_NAME
		ld		de, if_swap_nm
		ld		bc, 16
		ldir
		ld		hl, [istk + E_LINE]
		ld		[if_swap_ln], hl
		ld		hl, srep_name
		ld		de, istk + E_NAME
		ld		bc, 16
		ldir
		ld		hl, [srep_line]
		ld		[istk + E_LINE], hl
		ld		a, 1
		ld		[final_pass], a
		pop		hl
		call	report_cross_error
		xor		a, a
		ld		[final_pass], a
		ld		hl, if_swap_nm
		ld		de, istk + E_NAME
		ld		bc, 16
		ldir
		ld		hl, [if_swap_ln]
		ld		[istk + E_LINE], hl
		ret

;	fr_ptr: A = frame index -> HL = frame address
fr_ptr:
		ld		l, a
		ld		h, 0
		add		hl, hl
		add		hl, hl
		add		hl, hl
		ld		de, frames
		add		hl, de
		ret

;	do_final_pass: the normal final pass (output + log).
;	-> CY when the output file cannot be created.
do_final_pass:
		ld		a, 1
		ld		[final_pass], a
		ld		[output_active], a
		ld		[oa_base], a
		ld		hl, out_name
		call	out_open
		ret		c
		call	rewind_source
		call	reset_asm_state
		call	cs_reset_tables	; #62(b): final pass replays
						; pass-1 table evolution
		call	log_open_write_header
		call	run_pass
		call	out_close
		call	log_finish
		or		a, a
		ret

;	if_pre_final: called at fixpoint convergence.  Returns NC
;	when no IF search is needed (caller runs do_final_pass).
;	Returns CY + A=0 when the search took over the ending
;	(winner or failure final pass already ran); CY + A=1 when
;	the output file could not be created.
if_pre_final:
		call	if_scan_flags
		jr		c, ipf_search
		ld		a, [if_any_flagged]
		or		a, a
		ret		z			; NC: nothing ever flagged
		; Self-consistency audit: one validating pass over the
		; converged state.  A speculatively frozen condition
		; whose value changed afterwards (the paradox pattern)
		; disagrees with the fresh evaluation and fails here.
		ld		a, 1
		ld		[trial_mode], a
		xor		a, a			; #67e: pass A lays the converged
		ld		[validate_mode], a	; state out with real addresses
		call	if_valpass
		ld		a, 1			; pass B validates against them
		ld		[validate_mode], a
		call	if_valpass
		xor		a, a
		ld		[trial_mode], a
		ld		[validate_mode], a
		ld		hl, [trial_err]
		ld		a, h
		or		a, l
		jr		nz, ipf_search	; #65b: an inconsistent converged
							; state must escalate to the search
		ld		a, [scope_depth]
		or		a, a
		ret		z			; consistent: NC
ipf_search:
		; representative for error reporting
		ld		a, [rep_armed]
		or		a, a
		jr		nz, ipf_fb
		ld		hl, rep_name
		ld		de, srep_name
		ld		bc, 16
		ldir
		ld		hl, [rep_line]
		ld		[srep_line], hl
		jr		ipf_go
ipf_fb:
		call	if_rep_fallback
ipf_go:
		xor		a, a
		ld		[nframes], a
		ld		[best_found], a
		ld		[if_evals], a
		ld		[if_evals + 1], a
		ld		hl, 0xFFFF
		ld		[best_size], hl
		ld		[best_size + 2], hl
		ld		a, 1
		ld		[search_mode], a
dfs_loop:
		ld		hl, [if_evals]
		ld		de, 1024
		or		a, a
		sbc		hl, de
		jp		nc, dfs_limit
		call	if_restore
		call	if_passes
		ld		hl, [if_evals]
		inc		hl
		ld		[if_evals], hl
		jp		nc, dfs_backtrack	; trial did not converge
		call	if_find_undecided
		jr		c, dfs_branch
		; complete assignment: validate it over the
		; trial's converged dict (#65d: restoring first
		; wipes the labels the conditions reference, so
		; every label-referencing assignment failed)
		ld		a, 1
		ld		[trial_mode], a
		xor		a, a			; #67e: pass A lays the framed
		ld		[validate_mode], a	; choice out with real
		call	if_valpass		; addresses (dry-pass dict values
		ld		a, 1			; past a block are blk-relative);
		ld		[validate_mode], a	; pass B validates against them
		call	if_valpass
		xor		a, a
		ld		[trial_mode], a
		ld		[validate_mode], a
		ld		hl, [trial_err]
		ld		a, h
		or		a, l
		jp		nz, dfs_backtrack
		ld		a, [scope_depth]
		or		a, a
		jp		nz, dfs_backtrack
		; strictly smaller than the best so far?
		ld		hl, [file_off + 2]
		ld		de, [best_size + 2]
		or		a, a
		sbc		hl, de
		jr		nz, dfs_szc
		ld		hl, [file_off]
		ld		de, [best_size]
		or		a, a
		sbc		hl, de
dfs_szc:
		jp		nc, dfs_backtrack	; not smaller
		; record the best assignment
		ld		a, 1
		ld		[best_found], a
		ld		hl, [file_off]
		ld		[best_size], hl
		ld		hl, [file_off + 2]
		ld		[best_size + 2], hl
		ld		a, [nframes]
		ld		[best_nframes], a
		or		a, a
		jp		z, dfs_backtrack
		ld		l, a
		ld		h, 0
		add		hl, hl
		add		hl, hl
		add		hl, hl			; *8 = frame bytes
		ld		c, l
		ld		b, h
		ld		hl, frames
		ld		de, best_frames
		ldir
		jp		dfs_backtrack
dfs_branch:
		ld		a, [nframes]
		cp		a, FR_MAX
		jp		nc, dfs_backtrack
dfs_branch2:
		; fill the frame: site, cur = 0, nchoices
		ld		a, [nframes]
		call	fr_ptr			; HL = frame
		push	hl
		ld		de, site6_buf
		ex		de, hl			; HL = site6_buf, DE = frame
		ld		bc, 6
		ldir					; frame.site := site
		pop		hl				; HL = frame
		ld		de, 6
		add		hl, de
		xor		a, a
		ld		[hl], a			; cur := 0
		inc		hl
		push	hl				; -> nch slot
		call	if_set_rec		; rec_cur = undecided head
		ld		a, BR_FLAGS
		call	rr8
		and		a, 0x01			; has_else?
		push	af				; #66: rr8 clobbers BC (off_copy_add
		ld		a, BR_NBR		; loads BC:DE with the record
		call	rr8				; offset), so nbr must not be
		ld		b, a			; kept in B across the call
		pop		af
		jr		nz, dfs_nhe
		inc		b				; + the none choice
dfs_nhe:
		pop		hl
		ld		[hl], b			; nch := B
		ld		hl, nframes
		inc		[hl]
		jp		dfs_loop
dfs_backtrack:
		ld		a, [nframes]
		or		a, a
		jr		z, dfs_done
		dec		a
		call	fr_ptr			; HL = top frame
		ld		de, 6
		add		hl, de			; -> cur
		ld		a, [hl]
		inc		a
		ld		[hl], a			; cur++
		inc		hl				; -> nch
		cp		a, [hl]
		jp		c, dfs_loop		; cur < nch: retry this frame
		ld		hl, nframes
		dec		[hl]			; exhausted: pop
		jp		dfs_backtrack
dfs_done:
		xor		a, a
		ld		[search_mode], a
		ld		a, [best_found]
		or		a, a
		jr		nz, dfs_winner
		ld		hl, s_if_notres
		call	if_report_at
		jr		dfs_failfinal
dfs_limit:
		xor		a, a
		ld		[search_mode], a
		ld		hl, s_if_limit
		call	if_report_at
dfs_failfinal:
		call	if_restore
		xor		a, a
		ld		[nframes], a
		call	if_passes
		ld		a, 1
		ld		[if_fail_mode], a
		call	do_final_pass
		ld		a, 0
		jr		c, ipf_outerr
		scf
		ret
dfs_winner:
		call	if_restore
		ld		a, [best_nframes]
		ld		[nframes], a
		or		a, a
		jr		z, dfs_w2
		ld		l, a
		ld		h, 0
		add		hl, hl
		add		hl, hl
		add		hl, hl
		ld		c, l
		ld		b, h
		ld		hl, best_frames
		ld		de, frames
		ldir
dfs_w2:
		ld		a, 1
		ld		[search_mode], a
		call	if_passes
		xor		a, a			; #67f: already validated; the
		ld		[validate_mode], a	; dry dict here is blk-relative
		call	do_final_pass
		push	af
		xor		a, a
		ld		[search_mode], a
		ld		[validate_mode], a
		pop		af
		ld		a, 0
		jr		c, ipf_outerr
		scf
		ret
ipf_outerr:
		ld		a, 1
		scf
		ret

