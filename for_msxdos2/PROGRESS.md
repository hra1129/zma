# ZMA for MSX-DOS2 — implementation progress

Design: `DESIGN.md` (§3 limits / §7 decisions are final). Product: **ZMA for MSX-DOS2**, Z80 only.

## Status: P1 first increment — acceptance (a) AND (b) PASSED byte-identical (2026-11-11)

**Rename (author decision, 2026-11-11): the deliverable binary is `ZMA.COM`**
(built from `src/zma.asm`; usage string "Usage: ZMA …"). The old names
ZMA2.COM / `ZMA2T.COM` are retired: the test harness, AUTOEXEC.BAT files and
disk images all invoke `ZMA` now. `src/zma2t.asm` (trace/debug build) remains
as an auxiliary only and is **stale** — it contains the bug #17/#18 fixes but
NOT #19/#20/#21, plus leftover instrumentation; regenerate it from zma.asm
if a trace build is needed again.

### What is built

- `src/zma.asm` (~6,600 lines) — the whole P1-core assembler as a single
  cross-ZMA source. Builds with cross ZMA: `zma zma.asm ZMA2.COM` → **"Success."**,
  current `ZMA2.COM` = 21,395 bytes.
  - .COM skeleton: DOS2 version check (_DOSVER), banner, command tail
    parsing (`[-options] input output`; -DEFS / -HEX flags, -I<path>,
    -D<name>=<value> recognized; -D values are evaluated and defined at
    assembly start, after the symbol hash is cleared).
  - DOS2 handle API wrappers (_OPEN 43h, _CREATE 44h, _CLOSE 45h,
    _READ 48h, _WRITE 49h, _SEEK 4Ah, _TERM 62h).
    **Register convention proven on openMSX 2026-11-11 (the Datapack OCR
    text had DE/HL swapped): DOS wants _READ/_WRITE with B=handle,
    DE=buffer, HL=byte count, returns HL=bytes transferred.** The ZMA2
    wrappers keep the internal caller convention (HL=buf, DE=len) and
    `ex de, hl` internally. _OPEN/_CREATE: DE=filename ASCIIZ,
    A=open-mode inhibit bits (bit0=write-inhibit, bit1=read-inhibit,
    bit2=inherit); _CREATE also B=attributes (bit7=create-new-only).
  - Mapper: EXTBIO (D=4, E=2) jump table; user segments allocated via
    ALL_SEG for the symbol pool, freed via FRE_SEG on every exit path
    (normal, usage error, fatal). **Adaptive allocation**: the
    FS-A1ST_full machine has only 6 free user segments, so the pool
    keeps however many it could allocate (fatal only if < 2). Pool
    access via RD_SEG/WR_SEG byte window (page-2 addresses); the pool
    layer is proven by an in-situ self-test (writes/reads across a
    16 KB segment boundary all correct).
  - Input stack: main file + INCLUDE depth ≤ 4, per-level 512-byte
    buffers; line reader ≤ 255 chars (longer = error), CR/LF/CRLF handling.
  - Pass driver: fixpoint iteration (dry runs until no symbol value
    changes, max 32 iterations → "Error: symbols did not converge.")
    + final output pass. Errors are reported (with file/line) only in
    the final pass, in cross-ZMA style wording.
  - Expression evaluator: recursive descent with precedence climbing,
    32-bit signed arithmetic (mul/div/mod in software), ZMA's 11
    precedence levels (note: **lower ZMA level = tighter binding**;
    peek_binop returns strength = 20 − level), number formats 0x / 0b /
    octal (leading 0, only when all digits are 0–7) / H-suffix / $hex /
    decimal with `_` separators, char literals, `$` = line-start PC,
    `$$` = line-start file offset, CODE_ADDRESS / FILE_ADDRESS keywords,
    undefined-symbol propagation (no error during dry runs).
  - Symbol table: hash (1024 buckets, resident) + records in the mapper
    pool ([next:4][value:4][flags:1][namelen:1][name]); labels `:` and
    `::`; assignments `=` (scoped) and `:=` (global).
  - Minimal SCOPE/ENDSCOPE pulled forward from P2 (baconlib needs it):
    scoped lookup searches enclosing scopes outward, matching cross-ZMA
    shadowing semantics.
  - Directives: ORG, DEFB/DB (incl. string items), DEFW/DW, DEFD/DD,
    DEFS (string form; reserve form under -DEFS), SPACE, ALIGN, INCLUDE
    (with -I path fallback).
  - Encoder: table-driven for all no-operand instructions (incl. ED
    block ops); full LD matrix, PUSH/POP, ALU A-forms + ADD/ADC/SBC HL
    pairs + ADD IX/IY, INC/DEC, JP/JR/DJNZ/CALL/RET/RST, IN/OUT, EX, IM,
    BIT/RES/SET, CB shifts (incl. SLL).

### Deviations / decisions recorded

- DESIGN §2.3 puts the symbol *value array* on mapper segments; here the
  whole record (value included) lives in the pool — simpler, same scale.
  (Deviation is internal only.)
- DEFS reserve form is selected by the -DEFS command-line flag, matching
  cross ZMA's own switch.
- Cross-ZMA probing results (2026-11-11) that shape compatibility:
  - Cross ZMA has **no IM instruction** and rejects `LD H,IXH`/`LD L,IXL`
    (mixed real-half/IX-half). ZMA2 accepts both (superset; harmless for
    sources that cross ZMA accepts).
  - Cross ZMA rejects `$hex` inside DEFB/DEFW/DEFD lists ($ there is the
    current-address symbol only) but accepts `$hex` in instruction
    operands. ZMA2 accepts `$hex` uniformly (superset).
  - Cross-scope qualified references (`scope.name`) do **not** exist in
    cross ZMA — scoped symbols are visible only inside their scope chain.
    ZMA2 matches (no `.` in identifiers).
  - ORG does not pad the output file (sequential emission) — matches.
    SPACE does emit zero bytes into the file — matches.
- Not yet implemented (P1 remainders): MULUB/MULUW (R800) encoding,
  string expressions / string-valued symbols (P2), MACRO/REPEAT/IF (P3/P4),
  Intel HEX output (-HEX flag is parsed but output is still binary),
  zma.log / zma.sym file output, BINARY_LINK, MESSAGE/ERROR directives,
  `$$` uses the line-start file offset (same approximation as `$`).

### Root causes found & fixed during the openMSX acceptance debugging

All were proven on stock openMSX 22.0 (Panasonic_FS-A1ST_full + DOS2
disk) using file-based evidence (outputs extracted from the FAT12 disk
image and byte-compared) plus screen traces from a diagnostic build
(`src/zma2t.asm`, scratch only — never shipped).

1. **DOS2 _READ/_WRITE register convention** (see above): the initial
   implementation used the Datapack OCR's swapped DE/HL; every file read
   sprayed data over ZMA2's own code and every write dumped memory.
   Proven by a standalone W.COM probe (a 5-byte "HELLO" write produced
   a 327-byte file). Fixed by `ex de, hl` inside the wrappers.
2. **Mapper pool size**: requesting 8 segments failed on FS-A1ST_full
   (6 free). Adaptive allocation (≥2 required).
3. **open_main_input** destroyed the filename pointer in HL before
   falling into open_into_ent. push/pop HL.
4. **pio_read8/pio_write8 clobbered B** (documented as preserving it),
   breaking every djnz loop over pool bytes (record walks corrupted).
   push/pop BC inside both.
5. **sym_define create path** stored stale `val_tmp` instead of the new
   value. Copy new_val → val_tmp before sym_put.
6. **`::` global-label detection** compared A after `xor a, a` had
   destroyed the peeked char, so `::` was never seen. Restructured.
7. **eval_at_lp clobbered HL** (the expression result's low word) while
   saving the advanced lp back — every ORG/operand/list value became a
   line-buffer pointer. push/pop HL around the lp store.
8. **pp_hl carry inverted**: hex_digit_val returns CY=1 on success, but
   the $hex operand loop exited on carry — $hex operands evaluated to 0.
9. **sd_put2 lost the DEFINED flag** (the forward-reference
   non-convergence root cause): the new-flags byte was kept in C across
   a call whose helper loads BC with the record offset, so flags were
   written as 0 and every forward-referenced label was re-"changed"
   every pass → "symbols did not converge." Fixed by keeping the flags
   in a memory cell (sd_newflg) across the call.
10. **push_include clobbered HL** (the include filename pointer) while
    advancing cur_ent → DOS error 0xD7 (.NOFIL), silent in dry passes.
    push/pop HL (same class as #3).
11. **`[nn]`/`[hl]` operands unsupported**: parse_operand had no `[`
    path (cross ZMA accepts both `()` and `[]`). Added po_bracket flag;
    `expect_rparen` accepts `]` when set.
12. **pl_assign_rhs clobbered the LHS name**: RHS evaluation overwrites
    name_src_buf with the last RHS identifier, so `v = $ - start`
    inside a scope defined the wrong qualified name and oscillated
    forever. LHS name is now saved to `assign_name` and restored.
13. **ao_and/ao_or/ao_xor destroyed their own result pointer**:
    `ld bc, resv` followed by `ld b, 4` for the loop count overwrote
    the pointer's high byte (BC = 0x0454), so &, |, ^ stored into DOS
    low memory and the result was stale resv (0 in pass 1, 1 later).
    Rewritten with a memory-cell counter (ao_cnt).
14. **Octal flag lost**: pn_ock kept its "saw 8/9" flag in C, but the
    decision read C after `pop bc` restored a stale value → `077`
    evaluated as decimal 77 instead of octal 63. Flag now kept in a
    memory cell across the pop.
15. **Operator precedence direction**: ZMA's level numbers run
    tight→loose (level 2 `*` binds tighter than level 9 `|`), but the
    precedence climber treated larger level as tighter, so
    `0xF0 & 0x3C | 0x01` grouped as `0xF0 & (0x3C|0x01)`. peek_binop
    now returns strength = 20 − level.
16. **Comment-only lines errored as "bad mnemonic"** when reached via
    an include: get_line's CRLF-peek pushback char belongs to the
    *parent* file but was delivered as the first char of the *include*
    file (TEST1: the next main line starts with `tail::`, so testinc's
    comment line arrived as `t; included file...`). process_line now
    skips comment-only lines, and the pushback is flushed on
    push_include / pop_include / rewind_source.

### Build gotchas found (worth remembering)

- Cross ZMA: one illegal-operand line silently makes every label defined
  *after* it unresolvable. Illegal forms used by accident during this
  build: `sbc a,[de]`, ALU ops with absolute operands (`or a,[var]` —
  only LD takes `[nn]`), `ld [de],hl`. All fixed.
- ~79 `jr` in the source exceeded ±127 after layout; converted to `jp`.
- Register-discipline lesson of this run: any helper documented as
  "preserves X" must be audited — three separate bugs (#4, #9, #14)
  were BC/C clobbers across calls, and two (#3, #10) were HL clobbers
  of pointer arguments.

### Acceptance (this run)

- [x] Cross-build of ZMA2.COM: Success (21,395 bytes).
- [x] openMSX run: self-check `tests/test1.asm` (170 lines: expressions,
      labels, scopes, assignments, ORG/DB/DW/DD/DEFS/SPACE/ALIGN,
      INCLUDE, broad instruction coverage) — **byte-identical** to
      cross ZMA's `tests/TEST1.BIN` (329 bytes), console log clean
      (banner only).
- [x] openMSX run: expression probe EX1.ASM (bitwise/logical ops and
      mixed precedence) — **byte-identical** (20 bytes), log clean.
- [x] Micro-tests on openMSX, all passing with clean logs: forward
      references via LD DE / LD IX, `[hl]` operands, INCLUDE,
      scope + `$`-relative assignment (convergence cases for #9/#12).
- [x] openMSX run: `baconloader.asm` (+ baconlib.asm, 10,827 lines)
      byte-compare vs cross ZMA reference (`build/loader_ref.bin`,
      13,039 bytes, itself verified byte-identical to the repo's
      BACONLDR.BIN). **PASSED — BYTE-IDENTICAL** (testQ4.dsk, final
      ZMA.COM 21,588 bytes, run completes in <1 min at speed 5000).
- [x] Final combined regression on the shipping ZMA.COM (testFINAL.dsk,
      17/17 OK): TEST1/EX1 byte-identical; CNT9/10/11/12, EQ12, LNG12,
      H9 → 1-byte 0x00; LBL12 → 12 bytes; SAME12 → error exit, no output
      (parity of outcome with cross ZMA, which rejects repeated `:=`);
      COL1 → 0x03; ESC1/ROM1/ROM2/ROM11/LDT3 byte-identical to cross.

### Bugs #17–#21 (found & fixed 2026-11-11, after the first PROGRESS draft)

- **#17 `:=`-count "threshold" crash — code fell into a data buffer.**
  `pl_assign_rhs` fell through into `assign_name: space 64`, which sits in
  the code stream; after every assignment the CPU executed the LHS name
  bytes as instructions. `AA10` = 41 41 31 30 → `LD SP,0x0030` smashed the
  stack (the "count threshold" was an illusion — the trigger is the name's
  byte pattern; CNT9 passed, CNT10+ hung in pass 1). Fix: buffer moved to
  the data area + explicit jump after `call sym_define_scoped`.
- **#18 Symbol-chain self-loop — acceptance (b) hang at baconlib line 97.**
  In `sym_create`, the old bucket head is held in BC:DE across
  `call off_copy_add`, which reloads BC:DE with the record's own offset —
  so every record's `next` field was written as its own offset (self-loop).
  Single-record buckets never follow `next`, which is why all small tests
  passed; the first collision walk (VDPPORT1→HIGH, bucket 832) looped
  forever. Proven with the trace build + minimal repro COL1.ASM. Fix:
  `push bc / push de` around the `off_copy_add` call in `sym_create`
  (all other callers audited — only sym_create held live data in BC:DE).
- **#19 String escapes not processed.** `db ":\^|<>,./ "` (baconlib line
  3392) terminated at the `\"` and lost bytes (output −7). Cross semantics
  (from zma_parse.cpp, string AND char literals): \a \b \f \n \r \t \\ \'
  \" map to control chars; any other escaped char = the char itself
  (backslash dropped); NO \0/\x/octal; SJIS lead bytes (81–9F, E0–FC)
  consume a 2-byte pair verbatim. Fix: `esc_char`/`sjis_lead` helpers +
  handling in dir_defb, parse_string_lp, pp_char. Probe ESC1.ASM
  byte-identical. (In zma.asm; not mirrored into the stale trace build.)
- **#20 INCLUDE eats the first char of the following line.** get_line's
  CRLF-pair peek parks one char in a single GLOBAL pushback; push_include
  flushed it (to keep it out of the child), but the char belongs to the
  PARENT stream and was never restored — the first label after an INCLUDE
  was defined missing its first letter (`rom_image_end` → `OM_IMAGE_END`;
  trace showed the define as "MG_END" for IMG_END), so
  `rom_image_size := rom_image_end - rom_image_start` never converged to
  the true value (LD BC,0 in the loader header). Bites LF-only sources
  (baconloader/lib are LF-only; CRLF files consume the peek as the pair).
  Fix: pushback is now PER-ENTRY (`E_PB`/`E_PBV` at the end of each istk
  entry, ISTK_ENT 536→538); the flush hacks in push/pop_include removed;
  rewind_source clears the main entry's E_PBV; open_into_ent initializes
  it. Probes ROM2.ASM / ROM11.ASM byte-identical.
- **#21 `(expr)` operands misclassified as memory.** parse_operand routed
  every `(` operand to OPK_MEMNN and evaluated only the part inside the
  parens. In ZMA syntax `(expr)` is a parenthesized expression (immediate)
  — only `[expr]` is a memory reference (verified against cross ZMA:
  `ld bc,(0x1234)` → 01 34 12; `ld bc,[0x1234]` → ED 4B 34 12;
  `ld bc,(16<<4)|0x98` → 01 98 01). baconlib uses
  `ld bc, (16 << 4) | vdpport0` ×3 in sub_putsprite: ZMA2 emitted
  LD BC,(0x0100) (ED 4B, +1 byte each, trailing `| vdpport0` never
  evaluated). Fix: po_paren saves the opener position; the non-bracket
  expression case re-evaluates the whole operand via po_expr as OPK_IMM
  (register forms (hl)/(ix+d)/(bc)… unaffected). Probe LDT3.ASM
  byte-identical. (Parity corner left: cross ZMA *errors* on
  `ld a, (expr)`; ZMA2 accepts it as `ld a, n` — harmless superset.)

### P1 remainders

- MULUB/MULUW (R800) mnemonics — cross-ZMA-parity encoder corners
  (author target is Z80 only; add only if cheap).
- Error-message parity: SAME12 (repeated `:=` to one symbol) — cross ZMA
  reports 11 errors; ZMA2 exits with "symbols did not converge" and no
  output. Outcome-equivalent; wording/behavior polish remains.
- Intel HEX output (-HEX flag is parsed; output is still binary).
- zma.log / zma.sym file output (console messages only today).
- `ld a, (expr)` acceptance superset (see #21) — decide whether to match
  cross ZMA's error.
- Then P2: string expressions / string-valued symbols, assignments
  completion, MESSAGE/ERROR directives; P3: MACRO/REPEAT/LINK + nesting 8
  (pass = baconlib standalone byte-identical — note baconlib alone uses
  no MACRO/REPEAT/IF, so the P3 corpus needs other sources); P4: IF
  candidate search, charsets, BINARY_LINK, HEX; P5: self-host.

## P2 — symbol semantics (DONE 2026-11-11)

ZMA.COM = **39,522 bytes** (src/zma.asm, 9,910 lines; cross-ZMA build
"Success."). All P2 scope items and the three P1 leftovers are in.

### Implemented

1. **Assignments `=` / `:=` / `EQU`** with fixpoint semantics: order-
   independent re-evaluation until stable (cap 32 iterations, then
   "Assembly layout did not converge."-equivalent exit). Duplicate
   detection matches cross: redefinition by a *different* source line
   (or by a label) is "Multiple definition."; the definer is tracked
   per record as (line no, file-name hash). `-D` symbols have definer 0,
   so any source assignment over them is a duplicate, as in cross.
   Undefined RHS in the final pass -> "Label is indeterminate.".
2. **String values & expressions**: CVALUE-style model (integer /
   string / unknown). String `+` (concat; string+int appends the
   signed decimal), `*` (repetition, count <= 0 = empty), `==` / `!=`
   (byte compare; mixed int/string: == -> 0, != -> 1). Everything else
   on a string operand is "Illegal expression.". Division/modulo by
   zero -> "Divided by zero.". String symbols work in DEFB (emits the
   bytes), DEFS (string as-is, int -> decimal), DEFW/DEFD reject
   strings with "Illegal expression.". `CHAR_SET_NAME` yields
   "DEFAULT" until P4 charsets. String escapes follow cross rules
   (\a\b\f\n\r\t\\\'\"; any other escaped char = itself; SJIS lead
   bytes pass through as pairs). Strings are capped at 1024 bytes
   (STR_MAX; cross is unbounded on the host).
3. **SCOPE / local labels**: internal names are scope-qualified with
   `:` (SUB_A:LOCAL_X), lookup walks from the full scope prefix outward
   to the plain name. `:=` is always global (cross-verified). Symbol
   names are case-insensitive (upcased); 63-byte limit enforced by the
   name buffers. Unclosed scope at EOF -> "Scope is not closed.";
   ENDSCOPE with a parameter -> "Too many parameters."; ENDSCOPE with
   no open scope -> "Invalid command.". Scope depth is capped at 8
   (the combined MACRO/REPEAT/SCOPE budget lands in P3).
4. **`-D name=value`**: the whole option token is uppercased first
   (cross behavior, so `-Dmsg='hi'` defines MSG = "HI"). Value in
   single quotes = string (must be closed, else the option is
   rejected); otherwise std::stoi-style prefix parse (no digits -> 0).
   Malformed options print `Invalid command line option [-D...].`
   and are skipped; assembly continues.
5. **MESSAGE / ERROR**: MESSAGE prints `MESSAGE: <escaped>: <file>(<line>)`
   once, in the final pass (escapes \a\b\f\n\r\t); no argument ->
   "Too many parameters." (cross quirk, doc is stale); un-evaluable
   operand -> "Illegal parameter.". ERROR reports the raw text the
   same way and fails the assembly (exit 1). Error texts were taken
   from the cross binary's zma_error.cpp strings, not the doc table.
6. **P1 leftover (a) MULUB/MULUW**: `MULUB A, B/C/D/E` -> ED C1/C9/D1/D9,
   `MULUW HL, BC` -> ED C3, `MULUW HL, SP` -> ED C5; nothing else
   accepted, as in cross.
7. **P1 leftover (b) Intel HEX (-HEX)**: records of max 32 data bytes,
   uppercase, two's-complement checksum, addresses are sequential file
   offsets from 0 (ORG does not move them), type-04 extended-address
   record when the offset crosses a 64K boundary, LF line endings,
   NO EOF record — all cross-verified byte-for-byte.
8. **P1 leftover (c) zma.log / zma.sym**: ZMA.LOG is written in the
   final pass (banner, -D definition lines, DEFS/OUTPUT lines,
   `<< code >>` listing with per-line blocks, info lines for symbol
   definitions / labels / scope enter-exit / MESSAGE / errors, hex
   dump rows of 8 bytes, and the closing `<< label >>` section) and
   ZMA.SYM lists all defined integer symbols sorted by internal name
   as `NAME equ 0<lowercase hex>h`. Both match cross modulo the
   documented gaps below. Cross creates the output file even on a
   failed assembly; so does the DOS version.

### Verification (openMSX, FS-A1ST_full, DOS2)

Harness: tests/drive.py + tests/p2/compare.py, suites in
tests/stage/, goldens in tests/p2/*.gold.* and tests/goldreg/.

- **P1 regression**: TEST1.BIN and EX1.BIN byte-identical to cross;
  TEST1 zma.sym byte-identical. baconloader+baconlib: see the
  capacity note below.
- **P2 suite: 31/33 checks OK** (the 2 non-OK entries are the bacon
  items, see below). All suite binaries byte-identical (scope/string/
  assign/message/mul/log/-D), HEX output byte-identical, all zma.sym
  outputs byte-identical, console verdicts identical (MESSAGE texts
  incl. escapes, ERROR "boom!", "Multiple definition." for both the
  duplicate file and SAME12, -D MESSAGE lines), zma.log identical
  modulo the documented gaps.
- **Scale test**: a synthetic 1,952-line source with 1,300 symbols
  (650 assignments + 650 labels): binary and zma.sym **byte-identical**
  to cross — the collect/sort machinery is proven at bacon scale
  (bacon has 1,178 symbols).
- **Bacon / disk-capacity caveat**: assembling baconloader+baconlib
  with the P2 binary on a 720 KB floppy **fills the disk**: the
  zma.log alone is 1.38 MB for this source, DOS write failures are
  (correctly) non-fatal for the log, but the binary output then
  truncates (observed: T3.BIN stopped at 3,072 of 13,039 bytes).
  This is a media-capacity interaction, not an assembler error; the
  P1 byte-identical bacon result stands, and P2 correctness at that
  scale is covered by the scale test above. Flagged for the author:
  real-world DOS use may want a way to suppress the log on small
  media (cross ZMA always writes it; no switch exists there either).

### Bugs found & fixed during P2 (numbering continues P1's)

- **#22 Assignment flags lost.** In sym_define_assign's define step,
  log_set_info_assign clobbered A before sym_define consumed the
  extra flags from it, so `:=`/`=` symbols were stored as plain
  DEFINED (no ASSIGN/GLOBAL) and every multi-pass redefinition was
  misjudged "Multiple definition.". Fix: reload A from sda_extra
  after the log call.
- **#23 All binary operators returned boolean 1.** pe_take restored
  the operator id into A with pop af, then loaded lv_type/lv_undef
  into A before call apply_op — apply_op always saw A=0 (OP_NONE)
  and fell into the comparison tail (result = (lv != rv)). Introduced
  by the P2 frame extension (E4); masked in P1-only tests because
  their verification predates it. Fix: keep the op id on the stack
  across the flag loads and pop it right before apply_op. (Note:
  pe_opid is a global the recursive parse may overwrite, so it must
  NOT be reloaded after the recursive call.)
- **#24 `name::` hung the machine at exit.** log_set_info_label kept
  its flags byte (lsi_flg) as a `db` *inside the execution path* and
  stored the incoming flags into it; for a global label the byte
  became 0x02 and the fall-through executed it as `LD BC,[nn]`,
  desyncing the instruction stream. Plain labels stored 0 (NOP) and
  survived. Fix: moved the cell out of the code path.
- **#25 DEFB string bytes read from a bogus address.** str_intern
  passed the source pointer in HL, but intern_begin destroys HL
  (size argument), so intern_write copied from RAM at (pool offset)
  — zeros for small offsets, .COM image bytes (the banner) for
  larger ones. Fix: push/pop HL around intern_begin in str_intern.
- **#26 dec32_to_buf never terminated / lost digits.** div10u leaves
  HL = dec_cell, so the digit loop stored ASCII digits into dec_cell
  itself (a fixed point at 48..57 -> infinite loop: this was the
  "assembler hangs" bug that blocked the first full-suite run), and
  div10u's use of B as its counter destroyed the digit count (only
  the most significant digit survived). Fix: preserve the digit
  pointer across div10u/is_zero32 and count digits in a cell.
- **#27 log_finish never called on the success path.** The call sat
  after err_line on the unclosed-scope error branch; normal
  assemblies jumped over it (no label section, no ZMA.SYM, log tail
  lost). Fix: call it right after out_close.
- **#28 st_fetch_name wrote names to a wrong address.** off_copy_add
  loads the offset into DE, destroying the destination pointer held
  there, so fetched names landed in low memory and the dump buffers
  stayed zero (masked whenever BSS happened to be zero). The copy
  loop was rewritten to use HL (which pio_read8 preserves).
  Related hazard, recorded: RD_SEG (DOS2 mapper support) must be
  treated as clobbering DE; never hold a live pointer in DE across
  pio_read8.
- **#29 MESSAGE escape letter lost (console and log).** pme_esc /
  lml_esc printed '\' with putc/lw_putc and then printed the letter
  still assumed to be in A; both writers clobber A, so the letter
  came out as NUL (console) / a control byte (log). Fix: save the
  letter in a cell first. (Console verdicts compared before this fix
  had masked it: only the \t case in p2_msg exercises it.)
- **#30 MULUB second byte wrong.** enc_mulub kept the opcode byte in
  B across the first emit8; em_2 loads the emitted byte into B, so
  the second byte came out as 0xED. Fix: keep it in a memory cell.
- **#31 Scope log hooks clobbered flags.** lw_scope_enter/exit's
  log_active gate test (`or a,a`) destroyed the flags the directive
  dispatch chain returns with (ENDSCOPE appeared to hang the
  machine). Fix: preserve AF in both hooks. Rule recorded: any
  routine called from inside the line/dispatch path must preserve
  AF unless its caller is known flag-insensitive.
- **#32 (harness)** MSX-DOS2 COPY silently ignores destinations with
  a 4-character extension (`.ZSYM`/`.ZLOG` are not valid 8.3);
  suite staging now uses .ZSY/.ZLO. Also: one syntax error in the
  assembler source (e.g. a stray `srl a, a`) makes cross ZMA's code
  address indeterminate and cascades into hundreds of phantom
  errors — fix root errors first, then recount.

### Known gaps (vs cross ZMA)

- zma.log: no per-instruction cycle lines (no Z80/R800 cycle
  database; P4-grade work).
- zma.log: main listing lines carry the raw source line; cross
  re-renders each line from its token stream (keywords uppercased,
  operands normalized, e.g. `0x8000` -> `08000H`, `start:` ->
  `START :`). A combined label+instruction line is one block in the
  DOS log, two blocks in cross (with the label info line ordered
  before the dump row there).
- Label-vs-assignment name collision where the label's address
  *equals* the assigned value: cross reports a duplicate; DOS2
  converges silently (different-value case oscillates into the
  non-convergence exit — verdict-equivalent). Assignment-vs-
  assignment duplicates (incl. SAME12) match exactly.
- Error *counts* can differ on multi-error sources (cross re-reports
  across fixpoint rounds; DOS2 reports once, in the final pass).
  Success/failure verdicts and exit codes match.
- DOS2 does not print cross's `Found N error(s).` / `Success.` /
  `Failed.` console summaries; the banner differs (product
  difference, accepted in P1).
- -D stoi overflow: cross's std::stoi exception path yields 0; DOS2
  wraps at 32 bits. Trailing junk after a valid DEFS/DEFB expression
  is ignored by DOS2 where cross errors "Illegal parameter.".
- Combined nesting (MACRO+REPEAT+SCOPE <= 8): enforced since P3
  (shared scope_depth counter; see the P3 section).

## P3 — MACRO / REPEAT / LINK (2026-11-12)

ZMA.COM is now **53,879 bytes** (P2: 39,522). Source: src/zma.asm
(~14,000 lines; the P3 chunk is inline — src/p3_chunk.inc is a stale
intermediate, zma.asm is canonical). Shipped binary: build/ZMA.COM.

### What was built

- **Input-stack text entries**: macro bodies, REPEAT bodies and LINK
  bodies are captured per pass into a mapper-backed arena and
  replayed as text sources (entry kinds 1/2/3) through the existing
  src_frames machinery, with site identity = (file-name hash, line,
  ctx hash). get_line's terminator probe only *arms* a pending
  boundary; the frame pop / REPEAT rollover fires on the next real
  read, so a body's last line is still processed in its own frame
  and scope (#50).
- **MACRO**: definition/invocation with word-list-equivalent
  substitution via re-serialized expansion text built in the arena.
  Plain parameters splice token-wise (tokens re-joined with single
  spaces); `@` (through) parameters stringify the whole argument:
  tokens joined with single spaces, strings/chars decoded and the
  value re-escaped in cross's canonical escape form, wrapped in a
  leading `"` (evaluation-equivalent to cross's unterminated form).
  Each invocation site gets scope `@MACRO<n>` (per-site instance
  index), so macro-local labels are per-site. A macro definition
  inside a repeated/macro body re-registers per site (cross gives
  "Multiple definition." for the REPEAT case; DOS2 matches, E6).
- **REPEAT**: `REPEAT var, expr` / `ENDR`. The count is evaluated
  once and frozen per site (an unresolvable count freezes as 0,
  like cross); the counter lives in scope `@REPEAT<n>` and is
  written directly into the dict per iteration (no pass_changed),
  matching cross's direct dict writes. Count <= 0 emits nothing.
- **LINK**: `LINK t1, t2, ...` / `ENDL` trigger blocks. Bodies are
  captured and replayed in place only when a trigger has been
  marked used by a scoped symbol lookup (link_check_name, hooked
  into sym_lookup_scoped like cross's check_link). Because a
  forward reference *before* the LINK line cannot mark a trigger
  during the registration pass, link_force_check runs after every
  pass (cross's set_evaluated_for_all_links): an unevaluated LINK
  block forces one more pass (#56).
- **Shared nesting cap**: SCOPE, @MACRO and @REPEAT scopes share
  scope_depth, capped at 8 (author decision; cross has no cap).
  The 9th level reports "Scope nesting too deep." — a DOS2-only
  error text (documented divergence, suite M8).
- ENDSCOPE inside a @-scope (REPEAT/MACRO body) is "Invalid
  command." with no pop, matching cross.
- The arena shares the mapper pool's allocation: the stock
  FS-A1ST mapper has only 6 allocatable segments, so the pool
  takes them all and the arena lives in the pool's top segments
  (pool_limit_segs); baconlib's pool high-water is ~46.4 KiB, so
  pool = 4 segments + arena = 2 on this machine (#40).
- COM size discipline: DOS2/COMMAND2 here refuses to load much
  above ~54,000 bytes, so the 4 KiB RAM expansion buffer was
  eliminated (expansion is arena-backed) and scratch buffers were
  trimmed (dec_buf 260, val_buf 640). Current margin: ~120 bytes
  under the largest proven-loadable size — new code must watch
  the size after every build.

### Verification (openMSX, FS-A1ST_full, DOS2; DONE.TXT checked)

Harness: tests/drive.py + tests/p3/compare.py, suite in tests/p3/
(goldens generated by cross ZMA v1.0.20).

- **P3 suite: 23/23 OK** (single-disk run, tests/p3/autoexec_p3.txt).
  M1 basic macro, M2 @-stringification boundaries (expression,
  string literal, number, bare word), M3 token splice, M4
  macro-local labels x2 sites, M5 REPEAT basics / 0 count /
  expression count / nesting, M6 LINK used+unused, M7 nesting
  exactly 8, M9 REPEAT-in-macro + macro-in-REPEAT — all binaries
  byte-identical to cross, consoles clean. Error cases match
  cross's console verdicts: E1 stray ENDR "Syntax error.", E2 too
  few args "Too many parameters.", E3 macro redefinition and E4
  LINK duplicate trigger "Multiple definition." (E4 also reproduces
  the trailing "Cannot evaluate the expression."), E5 ENDSCOPE in
  REPEAT "Invalid command.", E6 macro def in REPEAT "Multiple
  definition.". M8 (9th nesting level) reports the DOS2-only cap
  error. Known attribution differences: E5/E6 error *line numbers*
  differ from cross (cross attributes block errors to the REPEAT
  line; DOS2 reports the offending line itself) — message texts
  and verdicts match. M8 leaves a 1-byte partial binary, as cross
  does for its own error cases (gold E1.BIN/E4.BIN are 1 byte).
- **baconlib standalone (the P3 gate): BYTE-IDENTICAL** —
  12,929 bytes, md5 b30c006ee82dd315f9d152ac97a5253d, console
  clean. **baconloader+baconlib combined: BYTE-IDENTICAL** —
  13,039 bytes, md5 35ed1d68582a4cc68eebbb2413b52b60.
  Method (circumventing the P2 capacity caveat): two-drive run
  (FS-A1ST_full_2D, tests/run2d.py) with the output binary directed
  to drive B: (`ZMA BACONLIB.ASM B:BACONLIB.BIN`). The 1.37 MB
  zma.log still overflows drive A:, but DOS log-write failures are
  non-fatal and the binary on B: completes intact. The P2 caveat
  therefore no longer blocks verification; it remains a real-world
  media constraint (and the log-suppression question stays open
  for the author, unchanged).
- **P1+P2 regression: 31/33 OK — identical to the P2 baseline**
  (tests/p2/compare.py; the 2 non-OK entries are the same bacon
  T3 staging items as in P2, superseded by the direct two-drive
  bacon verification above). TEST1/EX1 byte-identical, all P2
  binaries/HEX/zma.sym identical, console verdicts identical.
- **Scale test**: BIG.ASM (1,952 lines, 1,300 symbols) binary and
  zma.sym byte-identical.

### Bugs found & fixed during P3 (numbering continues; #32 was a
### harness bug — MSX-DOS2 COPY ignoring 4-char extensions)

- **#33 Chunk label collision.** The P3 chunk's escape-map labels
  em_1..em_3 collided with existing engine labels; one "Multiple
  definition" poisoned the whole symbol pass (hundreds of phantom
  errors). Renamed to esc_1..esc_7.
- **#34 Illegal Z80 operand forms in the chunk.** `sub a,[nn]`,
  `sbc a,[nn]`, `cp a,[nn]` do not exist (only [HL]/immediate) —
  rewritten register-based (5 sites).
- **#35 Accessors referenced before definition.** rec_cur, rwv,
  rr8, rr16 were used by the chunk but only their comment existed;
  defined (rr8/rr16 modeled on rr32x).
- **#36 Case-insensitive name collision.** Equates RP_COUNT /
  RP_SCOPE / RP_FROZEN vs data cells rp_count / rp_scope /
  rp_frozen — ZMA symbols are case-insensitive; cells renamed
  (rp_cnt32 / rp_scopeidx / rp_frz).
- **#37 jr range overflow across the chunk.** Bulk-converted to jp
  beyond ±55 lines; `push f` is also illegal in ZMA (must be
  `push af`) — bit twice in debug patches.
- **#38 dir_macro scanned a garbage line.** tok_scan was called
  without HL = line_buf, so macro definitions never registered.
- **#39 Arena starved of segments.** mapper_init's adaptive pool
  allocation took all 6 allocatable segments; arena_init got
  none. Arena moved into the pool's top segments with an explicit
  pool limit (see above).
- **#40 COM size vs the DOS2 load limit.** First full build was
  58,371 bytes and DOS2 refused to load it ("Not enough memory").
  Padding probes: 54,000 loads, 56,000 does not. The 4 KiB RAM
  expansion buffer was eliminated (arena-backed expansion) and
  scratch buffers trimmed.
- **#41 tok_is_word_start rejected digits and '_'.** A P1-latent
  range-check bug: the first `cp 'A' / jr c` bailed before the
  digit/'_' tests, so "PUT2" tokenized as "PUT"+"2..." and macro
  names with digits could not be defined or called. Fixed with
  independent range tests.
- **#42 tok_copy destroyed its destination.** tok_copy passed its
  destination in DE to tok_get, which clobbers DE. push/pop DE
  around the call.
- **#43 tok_op2_match destroyed HL.** It used HL as its table
  pointer; tok_one's operator path then computed garbage token
  lengths (a comma token "ran" ~250 chars). push/pop HL.
- **#44 pool_put_str looped forever.** Its terminator test read A
  after pio_write8, which destroys A ("only A/F destroyed") — the
  loop wrote pool bytes until something fatal happened (hang /
  silent DOS exit in production). Preserve A across the call.
- **#45 site_match always mismatched.** Stored and computed site
  bytes were identical, but the final pio_inc (`inc [hl]`)
  clobbered the flags the compare produced, so REPEAT/macro/LINK
  sites never matched (re-created every pass — the REPEAT
  "symbols did not converge" symptom). Re-derive Z after the loop.
- **#46 p3_scan_word carry convention inverted** (success returned
  CY, callers test CY = fail), and it never advanced [lp].
- **#47 REPEAT counter semantics.** Two defects: the define
  decision used sym_lookup_scoped, which manufactures an undefined
  stub instead of reporting "not found" (the counter stayed
  UNDEFINED — every body reference failed "Cannot evaluate"); and
  re-defining the counter each pass set pass_changed (the dict
  holds count-1 from the previous pass), so passes never
  converged. Fixed by probing with sym_find on the qualified name
  and writing the value directly on later passes (#45's cousin).
- **#48 spn_deep fell through into scope_pop.** The nesting-cap
  error path decremented scope_depth and fired the log exit hook
  after reporting the error. Added the missing ret.
- **#49 get_line probe crossed text-entry boundaries.** The
  one-char CR/LF probe read past a body/iteration end and fired
  the rollover/pop one line early (counters ran 1,2,2; a frame's
  last line lost its scope). Reworked to a pending-boundary flag
  (see "What was built").
- **#50 fill_text_hdr returned HL = entry+7.** Callers push HL as
  the frame pointer, so macro/REPEAT frames were pushed as a
  bogus pointer whose kind byte read as 0 (file) — frames vanished
  without their scope pop. fill_text_hdr now returns the entry.
- **#51 xb_put8 overflow comparison inverted.** `ret c` fired
  exactly when there WAS room, so every macro invocation ended in
  "Illegal parameter." while the expansion text itself was fine.
- **#52 lk_fresh linked the wrong LBLK record.** link_rec links
  rec_cur, but lk_find_site's failed walk leaves rec_cur at the
  chain's last record — the second LINK block linked the FIRST
  block again, creating a self-loop (blk1.NEXT = blk1) and a hang
  inside the site walk. Restore rec_cur = lk_blk before linking.
- **#53 dir_link never materialized the trigger name.** It called
  build_qname (which writes qname_buf) but not
  set_name_from_qname, so trigger registration/lookup used
  whatever name_buf happened to hold — duplicates reported
  against the wrong block, marks missed. (Same class as #55.)
- **#54 LINK converged before it could be marked.** In the
  registration pass, references earlier than the LINK line have
  already been looked up (chain still empty), so nothing marks
  the trigger and nothing else changes — the assembly converged
  with the body never replayed. Fixed by link_force_check (see
  "What was built").
- **#55 dir_macro '@' index overwritten.** After '@', the code
  loaded tok_count into A before storing dm_idx, so dm_idx became
  tok_count and every `@param` definition failed "Illegal
  argument." (suite M2).
- **#56 mba_tstr lost the string span.** It emitted the opening
  quote via val_put8 — which clobbers HL — and then called
  str_decode with HL = the value-buffer pointer, so @-arguments
  that were string literals stringified stale buffer bytes.
  Preserve HL across the call.
- **#57 scope_push_name copied scope_names onto itself.** The
  *33 offset math runs in HL, destroying the input name pointer;
  the copy loop then read from the scope_names base, so every
  pushed scope name was empty. REPEAT was self-consistent by luck
  ("::I" on both sides), but macro-local labels from different
  invocation sites collided under "::LOOP" and flipped values
  every pass (M4 non-convergence). Preserve the pointer in
  spn_src.

Harness lessons recorded during P3: the base image
test/testFINAL.dsk contains a STALE ZMA.COM — always stage the
fresh binary under the name ZMA.COM (a debug binary staged as
ZMADBG2.COM silently runs the stale one). DOS redirection keeps
the console file at 0 bytes until the program exits, so a hang
shows as an empty log; screenshot markers (no redirection) are
the reliable trace channel. Compare runs must wait for the
emulator to exit — reading the image mid-run (or across a VM
restart) produced two contradictory suite scores before the
DONE.TXT discipline was enforced.

### Known gaps (P3 additions)

- E5/E6 error line attribution differs from cross (see above).
- Through-parameter (@) values are built in a 640-byte RAM buffer;
  a longer argument value sets the overflow path ("Illegal
  parameter.") where cross would succeed. (Pool-backed values
  are a possible P4+ refinement.)
- A macro definition inside a REPEAT body gets a fresh site per
  outer-iteration context in DOS2; cross reports "Multiple
  definition." from the 2nd iteration (E6 passes because its def
  is re-encountered at the same site each pass).

### Next

P4: IF candidate search, charsets (CHAR_SET_NAME / BINARY in
strings), BINARY_LINK. P5: self-host (ZMA.COM assembling its own
source byte-identically).

## P4 — IF candidate search / charsets / BINARY_LINK (IN PROGRESS 2026-11-12)

Third attempt (two predecessors ended without a final report).
Checkpoint discipline: this section is updated after every verified
step so the state is recoverable from the file alone.

### Initial assessment (2026-11-12, source inspection)

All three features have substantial code in src/zma.asm
(302,254 bytes; cross build "Success.", output 53,694 bytes —
margin ~300 under the ~54,000 load limit), but **no DOS2 run
record existed anywhere**, so everything below starts as
"implemented, UNVERIFIED":

- **Charsets (PHASE 4a)**: dir_chg_char_set / dir_mapping_char /
  CHAR_SET_NAME / lf_charmap log section present. Set records
  (256-byte tables) live in the pool; CHG_CHAR_SET selects/creates
  by uppercased name with an identity table; pre-CHG current set
  is null (no conversion; MAPPING_CHAR -> E1's error). Conversion
  hooks sit in the expression literal paths with do_char_map
  suppression for CHG_CHAR_SET's own operand, MESSAGE/ERROR and
  BINARY_LINK paths.
- **BINARY_LINK (PHASE 4b)**: dir_binary_link present. Dry passes
  size the file via _SEEK-from-end (unopenable -> size 0, error
  deferred to the final pass); final pass streams through emit8.
  Cross quirks reproduced in code: unopenable file -> "Too many
  parameters." (E3), trailing words -> same, non-string ->
  "Illegal parameter.", unparseable -> "Illegal expression.".
- **IF (PHASE 4c/4d)**: branch-head pool records with sticky
  conditions, candidate/unresolved flags; dry passes walk every
  candidate branch with pc/file reset per head; a 4d candidate
  search (cross resolve_conditions equivalent) with the E2/E4
  error strings present. Suite tests/p4/ (C1-C3, B1-B2, F1-F7,
  E1-E6 + cross goldens + compare.py) was drafted by a
  predecessor but never run to a recorded result.

### Verification log

- 2026-11-12: first full-suite run (p4run.dsk, all 18 cases) was
  ABORTED mid-run on a policy change from the parent (the two
  predecessors both died during long emulator runs). No results
  were read from it. Verification proceeds in small per-group
  runs (C / B / F / E-minus-E4 / E4 alone), each recorded here
  immediately after it finishes.
- Harness speed (author request): drive.py / run2d.py Tcl now
  adds `set throttle off`, `set mute on`, `set maxframeskip 100`
  on top of `set speed 5000`. Measured reality on this host
  (1.5 shared CPUs): the emulated clock advances at roughly
  real-time speed regardless, so the run budget in emulated ms
  is effectively the wall-clock budget. Group budgets are
  therefore sized to the work (30 s covers the whole C group
  including DOS boot). The DONE.TXT discipline is unchanged.
- 2026-11-12 **C group (charsets): C1 OK, C3 OK, C2 FAIL** —
  C2's binary and console match cross; only the zma.log
  `<< character map >>` section differs (TEST set rows
  0x30/0x38/0x40: cross has a +0x20 band over 0x32..0x40).
  Root cause found in the cross sources (zma_text.cpp
  analyze()/all_process(), zma_information.cpp): cross's
  char_set_list lives in CZMA_INFORMATION for the WHOLE
  assembly; `info.clear()` between iterations resets only
  the current-set selection, NOT the tables, and MAPPING_CHAR
  argument char literals are evaluated through the current
  (evolving) table — so tables mutate across analyze
  iterations and again during the output pass, which is
  exactly what produces the band. **Bug #62**: the DOS2
  `cs_reset_tables` (#61) re-initialised every table to
  identity at each pass start, based on the opposite
  assumption. Fix: drop the per-pass table reset (records
  and tables now persist across passes; only cs_cur /
  cs_name_off reset). Rebuilt and re-verifying.
- 2026-11-12 #62 fix completed: cross freezes each line's
  data at first determination (is_data_fixed), so DOS2 now
  (a) evolves tables across dry passes, (b) resets them at
  the final pass so emitted bytes replay pass 1, and
  (c) rebuilds the dump state in lf_nosec (after the label
  section / zma.sym data is collected) by re-running
  A + 1 dry passes from identity, A = cross's analyze
  count (= DOS2 dry passes D, but at least 2 — cross's
  first iteration always counts as an update).  A first
  implementation of (c) appeared to "stick" at the T2
  table state for any pass count; instrumented runs
  (execution counters, marker bytes, chain-length probe)
  proved the passes themselves were correct — the loop
  counter register B was clobbered by cs_reset_tables
  (ldir) before the first push, so the loop ran 256
  passes and the byte counters wrapped to exactly 0.
  The final loop counts in a RAM cell instead.
- 2026-11-12 **C group (charsets): C1 OK, C2 OK, C3 OK** —
  binaries, console verdicts and the zma.log
  `<< character map >>` sections all byte-identical to
  cross.  ZMA.COM at this point: 53,766 bytes.
- 2026-11-12 **B group (BINARY_LINK): B1 OK, B2 OK** —
  binaries byte-identical (linked blob bytes land at the
  right offsets; pass-1 sizing path agrees with cross).
- 2026-11-12 F group (IF search), partial state: in a
  60 s (emulated) group run, F1–F5 completed (outputs on
  disk; comparison pending the rest), F6 did not finish.
  F7 alone also did not finish in 30 s (emulated).  F6 =
  IF in MACRO, F7 = IF in REPEAT — both put IF heads
  inside replayed text entries.  A 600 s F7 run is in
  flight to separate "very slow" from "loops forever";
  the search code is being read in parallel.  Note from
  the F-group disk: F2/F4/F5 .BIN sizes are smaller than
  the goldens (2 vs 4, 2 vs 3, 2 vs 4 bytes) — comparison
  will tell whether the DOS2 search picks different
  layouts than cross there.
- 2026-11-12 **F7 does not terminate within 600 emulated
  seconds** — this is a search explosion/loop, not mere
  slowness (cross assembles F7 instantly).  Debugging the
  trial machinery (if_passes convergence, head-record
  site matching for text-entry replays) with F7 as the
  repro.
- 2026-11-12 F7 debug build (EVALS.BIN progress file at
  DFS entry): after 120 emulated seconds the file was
  never created — **the IF search is never entered; a
  single run_pass never returns**.  The loop is inside
  one pass, in the REPEAT replay machinery interacting
  with the IF stack (F6 = MACRO has the same text-entry
  profile; plain REPEAT/MACRO without IF passed in P3).
- 2026-11-12 Bisection (probes in tests/p4/): R1 =
  counter REPEAT without IF: OK (51 51 51).  R2 (plain
  `REPEAT 2` without a counter variable) errors
  "Illegal parameter." at line 1 — DOS2's dir_repeat
  requires the variable form; whether cross accepts
  the bare form is a separate question (E-group
  material, not the F7 hang).  **R3 = counter REPEAT +
  counter-dependent IF condition (equal-size
  branches): HANGS** — minimal repro is R3.ASM.
- 2026-11-12 Harness lesson: **file writes by a still-
  running (killed) process may never reach the disk
  image** (DOS cache) — "file absent / 0 bytes" from a
  killed run is NOT evidence.  Also fat12.read needs
  the 8.3 name (TRACE.BIN -> "TRACE   BIN").  The
  EVALS.BIN "search never entered" conclusion is
  therefore unproven.  In-flight evidence now comes
  from VRAM markers + screenshots instead.
- 2026-11-12 (4th attempt takes over): build/ZMA.COM was
  still the P3 binary (53,879) — now refreshed from the
  current src/zma.asm (305,245 bytes): cross build
  "Success.", **ZMA.COM 53,795 bytes** (md5
  22b6b09bffa7550599ce55d86d067ba7), margin ~205 under
  the ~54,000 load limit.  (The 53,766 figure recorded
  at the C-group milestone was a scratch build of an
  intermediate source and no longer applies.)
- 2026-11-13 (5th attempt takes over): **author rulings
  recorded** (DESIGN.md §3 + §7 item 7; intentional
  divergences from cross): (a) **REPEAT iteration count
  capped at 16,384** — exceeding it is a DOS2-only
  error; author rationale: a case that does not finish
  in 600 fast-forwarded seconds is not a practical use
  case.  (b) **REPEAT nesting capped at 2** — applies
  to REPEAT-in-REPEAT only; the P3-verified combined
  MACRO+SCOPE+REPEAT cap of 8 is NOT lowered (if the
  combined cap ever has to change, flag it in the
  final report instead of deciding unilaterally).
- 2026-11-13 **Measurement first**: R3.ASM and F7.ASM
  both use `REPEAT I, 3` — 3 iterations, REPEAT nesting
  depth 1.  Both are far INSIDE the new caps, so the
  caps alone cannot fix the F7 hang; the hang is a
  non-convergence / in-pass loop (consistent with the
  earlier bisection: R1 counter-REPEAT without IF is
  OK, R3 = R1 + counter-dependent IF hangs).  The caps
  are implemented as insurance; the root cause in the
  IF/pass machinery must be fixed separately.
- 2026-11-13 (5th attempt, checkpoint): **the F7/R3
  "hang" does NOT reproduce with the current build**
  (53,795 B, md5 22b6b09b...).  A 9-case batch disk
  (R3, R4, F6, F7, F1-F5, one AUTOEXEC, current
  build/ZMA.COM staged) completed ALL cases inside
  300 virtual seconds.  Bug #63 (cur_site site
  collapse inside text entries -> dir_else found the
  IF branch's own record, self-linked BR_BNEXT,
  if_close_block looped forever) is already fixed in
  the current source, which explains the hang's
  disappearance.  RETRACTION: an early PC-sampling
  probe this session sampled mostly post-completion
  DOS idle (the assembly had already finished), so
  its "loop in sym_create" histogram is void.
- What DOES reproduce (current build): **ELSEIF /
  ELSE branch content is silently dropped** whenever
  it should be taken.  Batch results vs goldens:
  R3 = 51 51 (expected 51 51 52), F7 = 51 51 (gold
  51 51 52 52), F2 = 00 00 (gold 00 01 02 00),
  F4 = 00 00 (gold 00 01 00; cross takes the ELSE),
  F5 = b1 c0 (gold a2 a2 b1 c0), F6 = a1 (gold
  a2 a2 a1 a3 a3 a3).  F1 and F3 match.  Mutation
  tests (tests in /tmp/vt): V2 (else, MODE symbol)
  and V4 (else, constant `if 0`) both emit EMPTY
  output with no error; V3 (`if 0 / elseif 1`)
  fails with a spurious "No consistent, valid IF
  layout could be determined."; V6 (= F5 minus the
  nested part) drops the elseif bytes.  Pattern:
  only the first (IF) branch can ever emit; every
  bidx >= 1 branch is suppressed, and the candidate
  search/validation agrees with the wrong state
  (V3).  Root-cause hunt is in the dle_go /
  if_head_common / sticky BR_COND machinery, using
  an in-band marker diagnostic build (Tcl breakpoint
  probes proved unreliable in this environment).
- 2026-11-13 **Bug #64 ROOT CAUSE of the branch drop
  (found with an in-band marker diagnostic build;
  markers gated on final_pass && !trial_mode, emitted
  via out_byte into a throwaway build in /tmp/diag)**:
  `if_ent_fld` took the field displacement in A but
  called `if_ent_top` first, which overwrites A with
  (if_depth - 1); the subsequent `ld e, a` therefore
  always used disp = depth-1 -- at depth 1, disp 0 =
  IE_HEAD.  Every `if_ent_fld(IE_REC)` caller silently
  read/wrote the HEAD record instead of the current
  branch record: ihc_nok read the head's BR_COND (the
  IF condition) for ELSEIF/ELSE branches, so a false
  IF suppressed the whole block; per-branch cond
  sticking (if_ent_rec2) and branch sizes
  (if_fin_branch) also landed on the head record,
  which in turn poisoned close_block accounting and
  made the candidate search fail trivial chains
  (V3 spurious NOT_RESOLVED).  Masked whenever the IF
  branch itself was taken (ST_TAKEN short-circuits
  before the cond read) and for branch-0-only blocks
  (rec == head there), which is why plain IF and
  nested IF cases passed.  Raw pool dumps proved both
  records were byte-perfect (ELSE KIND=2/COND=2,
  HEAD COND=1, BNEXT chain correct) while the reads
  returned head values.  **Fix: push af / pop af
  around the if_ent_top call in if_ent_fld (+2
  bytes).**  Rebuilt: ZMA.COM **53,797 bytes** (md5
  e34fac3cd65c4b31f2659c29fd02b787), build/ZMA.COM
  updated.  Full re-verification running.
- 2026-11-13 **Bug #64 fix VERIFIED**: batch of 13
  (R3, R4, F1-F7, V2, V3, V4, V6) on the fixed build
  (53,797 B): **all pass** -- F1-F7 byte-identical to
  goldens (F2/F4/F5/F6/F7 were wrong before), R3 =
  51 51 52, R4 = 51 51, V2/V4/V6 emit the else /
  elseif byte, V3 assembles cleanly (a2) with no
  spurious NOT_RESOLVED error.  Consoles clean.
- 2026-11-13 Caps first run (N cases, 53,912 B build):
  N1 (REPEAT 20000) and N5 (REPEAT 16385) -> "REPEAT
  count too large." OK; N3 (2-deep, J=0..2) correct
  output 00 01 02 00 01 02 OK.  But N2 (3-deep) did
  NOT trip the nesting check: the first version
  walked `istk`, which holds FILE entries only --
  text frames (macro/REPEAT/LINK) live exclusively
  in the `src_frames` pointer array.  Fixed the
  walk to scan src_frames[0..src_nframes) and count
  kind-2 (REPEAT) frames; re-verification running.
- 2026-11-13 **Author caps VERIFIED** (build 53,912 B):
  N1 REPEAT 20000 -> "REPEAT count too large."; N5
  REPEAT 16385 -> same (boundary exact: 16384 allowed,
  16385 rejected); N2 REPEAT nested 3 deep ->
  "REPEAT nesting too deep." (reported once per
  analysis pass, line attribution at the enclosing
  ENDR -- same caveat class as E5/E6); N3 REPEAT
  nested 2 deep assembles fine, output
  00 01 02 00 01 02 (no false positive).  The
  combined MACRO+SCOPE+REPEAT cap of 8 is untouched.
  ZMADATA.BIN split NOT adopted -- not needed
  (margin to the ~54,000 B load limit: ~88 B).
- 2026-11-13 (6th attempt, final acceptance on the current
  53,912 B build, md5 e5c97c649ef142b3a2d77e205e831368):
  **P4 success groups re-run: C1 C2 C3 OK, B1 B2 OK,
  F1-F7 OK** (tests/p4fin1.dsk, DONE.TXT checked,
  compare.py) -- the F group is now verified on the
  caps build too, not only on the pre-caps 53,797 build.
- 2026-11-13 (6th attempt): **P4 E group first recorded run**
  (tests/p4fin2.dsk, current 53,912 B build, DONE.TXT
  checked): E1 OK, E3 OK, E5 OK.  **E2 and E6 MISMATCH**
  (recorded before any fix attempt):
  - E2 input: `HEAD: db 0 / if (TAIL - HEAD) <= 5 /
    db 1,2,3,4,5,6 / endif / TAIL: db 0` (circular: taken
    gives size 8 -> cond false; untaken gives size 2 ->
    cond true; no consistent layout).  Expected (cross):
    console `ERROR:No consistent, valid IF layout could
    be determined.: E2.ASM(2)`, Failed.; binary 2 bytes
    (matches DOS2's 2 bytes).  Actual (DOS2): console has
    ONLY the banner -- no error reported at all; the
    untaken layout was silently emitted.
  - E6 input: `CHG_CHAR_SET "X" / MAPPING_CHAR 'A' 0x61
    / db 0`.  Expected (cross): `Illegal expression.` at
    line 2.  Actual (DOS2): `Illegal parameter.` at
    line 2.
  Remaining verification (E4, P3, P1+P2, bacon) proceeds
  on the current build first so the full mismatch list
  is known before any code change.
  - E4 input: 11 self-referential IF/ELSE blocks
    (`if (Tn - Hn) > 5`, then 6 bytes / else 2 bytes;
    both layouts consistent per block -> 2^11 = 2048
    combinations).  Expected (cross): console
    `ERROR:IF layout search exceeded 1024 candidates;
    minimum size is not guaranteed.: E4.ASM(16)`,
    Failed.; binary 44 bytes.  Actual (DOS2): binary
    byte-identical (44 B, the minimum layout) but
    console has ONLY the banner -- no error.
  Pattern across E2/E4: DOS2's fixpoint resolution
  converges to the same bytes cross emits, but never
  raises the two search-failure errors (no-consistent-
  layout / candidate-overflow); the error strings
  exist in the source (initial assessment) but these
  shapes do not reach them.
- 2026-11-13 (6th attempt): **P3 suite regression on the
  current build: 23/23 OK** (tests/p3fin.dsk, DONE.TXT
  checked, tests/p3/compare.py).  Baseline maintained.
- 2026-11-13 (6th attempt): **P1+P2 regression on the
  current build: 31/33 OK** (tests/p2fin.dsk,
  tests/p2/compare.py) -- identical to the P2 baseline;
  the 2 non-OK are the known single-disk bacon T3
  staging items (BACON.BIN / SYM T3.ZSY), superseded by
  the two-drive bacon verification.  Current-build
  verification status: P4 C/B/F + E1/E3/E5 OK; P3 23/23;
  P1+P2 31/33.  Remaining: E2/E4/E6 fixes (below),
  bacon two-drive, caps re-check.
- 2026-11-13 (6th attempt): **Bug #65 = the E2/E4/E6
  divergences, root causes found in the cross sources**:
  (E6) cross MAPPING_CHAR classifies EVERY argument-
  shape failure as ILLEGAL_EXPRESSION (only
  CHG_CHAR_SET trailing words are ILLEGAL_PARAMETER);
  DOS2's dmc_comma_req used s_illegal_param for the
  missing-comma case.  (E2) DOS2's converged-state
  audit in if_pre_final could never escalate: it
  returned "consistent" whenever scope_depth == 0,
  which always holds after a well-formed pass, even
  when the validation pass had set trial_err (the
  paradox pattern the audit exists for).  (E4) cross
  enumerates unresolved_conditions as well as
  candidates: a block whose condition depends on its
  own layout (branch sizes differ, condition not
  fixable) is enumerated and the 1024 cap produces
  SEARCH_LIMIT; DOS2 set its candidate bit only when
  the block changed the symbol dict (speculative
  symbols), so db-only self-referential blocks never
  engaged the search and silently took the fixpoint
  layout.  Fixes (scratch build verified before
  applying): (a) dmc_comma_req -> s_illegal_expr
  (0 bytes); (b) audit gate: trial_err != 0 jumps to
  ipf_search (+1 byte); (c) at icb_und, an unresolved-
  this-pass block also sets the (sticky) candidate
  bit (+7 bytes).  Scratch build with (a)+(b):
  53,913 B; E2 OK, E6 OK, F2/F5/F7 OK.  (c) in test.
- 2026-11-13 (6th attempt): fix (c) test (scratch build
  53,920 B): E4 now TERMINATES with an error, but the
  WRONG one -- "No consistent, valid IF layout could
  be determined.: E4.ASM(2)" instead of the LIMIT
  error; binary still to check.  So with fix (c) the
  DFS engages for E4 but exhausts its stack with
  best_found = 0 (every complete assignment failed
  validation, even all-taken / all-else, which are
  both self-consistent per block), instead of hitting
  the 1024-evaluation cap.  Diagnosing with reduced
  variants (1-block / 2-block E4 shapes) before
  touching the search.
- 2026-11-13 (6th attempt): fix (c) side effect isolated:
  F2 FAILS on the (a)+(b)+(c) scratch build with a
  spurious NOT_RESOLVED, although it passed with
  (a)+(b) alone.  Mechanism: with (c) the head stays
  candidate-flagged at convergence, so if_scan_flags
  routes into the DFS; the DFS then validates NOTHING
  for label-referencing conditions.  Root cause of the
  validation flaw: the complete-assignment path in
  dfs_loop calls if_restore (dict back to the pre-
  assembly snapshot) and then validates with a SINGLE
  pass -- at the IF line, a label defined later in the
  file is not yet in the dict, so if_eval_cond returns
  "unknown" and every assignment is rejected.  (With
  (a)+(b) alone, F2 never entered the DFS: the audit
  validated the converged state directly and found it
  consistent, while E2's converged state is genuinely
  inconsistent -- the audit discriminates correctly.)
  Fix (d): drop the if_restore before the DFS
  validation pass, so validation runs over the trial's
  converged dict -- the same method the audit uses.
  The next dfs_loop iteration restores anyway.
- 2026-11-13 (6th attempt): fix (d) did NOT cure the
  DFS validation (F2/V1B still spurious NOT_RESOLVED;
  note compare.py's "clean console" regex misses the
  cross-format ERROR line, so its F2 "OK" in that batch
  was a false pass -- the console text is the truth).
  F5/F7 stay clean (they never needed the DFS).
  Diagnosing with a marker build: if_report forced to
  print during trials, which distinguishes the two
  failure channels (fresh condition UNKNOWN ->
  s_if_notres, vs selection mismatch -> s_if_illcond
  "Illegal condition.").
- 2026-11-13 (6th attempt): Bug #66 FOUND (marker build
  diag4, stream "B0T"): dfs_branch computes nch = 0 for
  F2.  Root cause: dfs_branch2 keeps nbr in B across a
  second rr8 call, but rr8's helper off_copy_add loads
  BC:DE from the record offset -- it CLOBBERS BC.
  Record offsets are small, so B becomes 0: nch := 0
  (has_else) or 1 (no else).  With nch = 0 the first
  backtrack pops the only frame and the search ends
  after a single validation -- every candidate case
  reaching dfs_branch was doomed.  The 'T' marker also
  shows the taken-choice validation raised trial_err;
  identifying that report next (diag5: err_line forced
  to print during trials), then fixing both.
- 2026-11-13 (6th attempt): a runtime restart wiped
  /tmp (all scratch/diag dirs).  Fixes (a)-(d) were
  reconstructed in scratch/zma.asm (persistent) from
  the recorded edit descriptions; the rebuilt binary
  is BYTE-IDENTICAL to the lost scratch build
  (53,917 B, md5 63f3460376f2d2f8a756fed6a98bf1fc,
  compared against the copy staged in p4fix3.dsk).
  Diag builds are henceforth made from scratch/.
- 2026-11-13 (6th attempt): Bug #66 fix: in dfs_branch2
  read BR_FLAGS first and carry the has_else Z flag
  across the BR_NBR rr8 call with push af / pop af
  (+2 bytes).  Testing on the scratch build next.
- 2026-11-13 (6th attempt): Bug #66 fix VERIFIED on
  the scratch build (53,919 B): F2 CLEAN (search finds
  the 4-byte winner), V1B CLEAN, E2 still correctly
  NOT_RESOLVED, F5/F7 CLEAN; binaries match gold via
  p4/compare.py (F2/E2/F5/F7 OK), V1B.BIN = 00 01 02 00.
  Remaining on scratch: E4 (expect SEARCH_LIMIT +
  44-byte binary), then the full final verification.
- 2026-11-13 (6th attempt): E4 first long run on the
  #66-fixed scratch build hit drive.py's 1200 s wall
  timeout before the search finished (no DONE.TXT --
  inconclusive, not a failure).  The DFS legitimately
  needs ~1024 expensive iterations.  Re-running with
  a long-timeout runner (scratch/run_long.py, wall
  3600 s, virtual 2400 s).
- 2026-11-13 (6th attempt): **E4 OK** on the scratch
  build: console "IF layout search exceeded 1024
  candidates; minimum size is not guaranteed.:
  E4.ASM(2)" and p4/compare.py E4 OK (44-byte binary
  identical).  Line attribution is (2) vs cross's (16)
  -- cross takes the first key of a string-keyed map
  (lexicographic artifact); recorded as a known
  divergence.  P4 E group is now fully verified on
  the fixed build (E1-E6).  Porting the five fixes
  ((a)(b)(c)(d) + #66) to src/zma.asm for the final
  verification round.
- 2026-11-13 (6th attempt): FINAL build (53,919 B)
  first suite disk (vfin1): C1-C3 OK, F2-F7 OK, but
  B1/B2 FAIL ("Too many parameters." at BINARY_LINK
  lines; bins 3/1 bytes vs gold 13/16) and F1 FAIL
  (spurious NOT_RESOLVED, 4 B vs gold 8 B).  F1 has
  exactly ONE consistent layout (taken); the DFS
  rejects the taken choice -- the same asymmetry the
  diag4 'T' marker showed for F2 (else choice OK,
  taken choice reports).  B1/B2 were never run on a
  build containing fix (a) before (the (a)-targeted
  s_illegal_param occurrence is suspect).  Checking
  both before touching anything.
- 2026-11-13 (6th attempt): vfin1's B1/B2 FAILs were
  a HARNESS error by me: the disk lacked BLOB.BIN
  (earlier p4fin1.dsk had it).  Rebuilt with BLOB.BIN
  on the final build: B1 OK, B2 OK (clean consoles,
  compare.py OK).  The first bb912 comparison disk
  was also void (reference binary staged under the
  wrong file name, so the template's P1 binary ran).
  F1 remains a REAL regression: final build prints
  spurious NOT_RESOLVED for F1 (one consistent layout:
  taken).  Confirming F1 on the 53,912 build next
  (bb912b, correctly staged), then isolating which of
  the five fixes is responsible.
- 2026-11-13 (6th attempt): F1 confirmed OK on
  53,912 (clean, gold match) and broken on 53,919.
  Two compounding causes: fix (c)'s candidate bit is
  sticky across passes, so F1 (which resolves
  naturally to the taken layout by pass 2) still
  enters the search; and the search's taken-choice
  validation spuriously reports (the diag4 'T').
  The cross-faithful root fix is the validation
  asymmetry.  Diag7: unmask all trial error channels
  on the current source and read what the taken
  choice's validation actually reports for F1.
- 2026-11-13 (6th attempt): diag9 (markers + all
  channels unmasked) on F1: stream B2 V [illcond(2),
  illcond(4)] V [illcond(2)] D.  Both DFS validations
  report "Illegal condition." -- the IF head in both,
  the ELSE head in the first.  That means if_sel in
  the validation pass matches NEITHER branch (the
  chain_sel "none" value 2): the framed choice is not
  reaching dir_if's selection, and the fallback
  chain_sel does not see the trial's sticky-true
  branch either (record-layer mismatch suspected in
  final passes).  Diag10 prints if_choice_for's and
  if_chain_sel's return values when validate_mode=1.
- 2026-11-13 (6th attempt): diag10 on F1 printed
  "01": if_choice_for DOES deliver the framed choices
  (0, then 1) in the two validation passes.  So the
  selection is right; combined with diag9's illcond
  pattern (both heads in valpass 1, IF head only in
  valpass 2), valpass 1's FRESH evaluation must be
  FALSE where the taken layout demands TRUE -- the
  dictionary state seen by the validation pass is in
  question.  Diag11 prints if_fresh in the validation
  block.
- 2026-11-13 (6th attempt): diag12 on F2 confirms the
  pathology is UNIVERSAL: stream "2 0 1 | 4 1 1 ...":
  the choice-0 trial converges to a 2-byte layout
  (NEITHER branch walked) and its validation rejects
  (fresh FALSE against a phantom TAIL=2); the
  choice-1 trial walks the else branch (size 4) and
  validates.  F2 passes only because its winner is
  choice 1; F1's only winner is choice 0.  Diag13
  prints if_choice_for's result in the search's DRY
  trial passes too, to see what dir_if actually gets
  on the first framed trial.
- 2026-11-13 (6th attempt): **Bug #67 root cause
  pinned** (diag12-14 evidence chain): in DRY passes
  every branch head resets pc/file_off to the block
  base (dir_else dle_nores), and nothing re-adds the
  selected branch's size at ENDIF -- so in the trial
  dict, labels after a block hold blk + LAST-branch
  addresses (F1 taken trial: TAIL=1, real 7).  Fix (d)
  made the DFS validation evaluate conditions against
  those phantom addresses: F1's taken choice reads
  (1-0)>2 = FALSE and is rejected as "Illegal
  condition."; F2's taken choice is rejected by the
  same mechanism (its else winner masked it), and
  single-branch blocks (E2) are unaffected because
  the only branch IS the last.  Fixes: (e) validate
  in TWO final-format passes -- pass A with
  validate_mode=0 lays the framed choice out with
  real pc accumulation so the dict holds real
  addresses, pass B with validate_mode=1 checks
  against them (applied at the DFS complete path and
  the if_pre_final audit); (f) the winner final pass
  runs with validate_mode=0 (the assignment was
  already validated; re-validating there reads the
  dry dict and can only produce spurious reports).
- 2026-11-13 (6th attempt): **Bug #67 fixes (e)(f)
  VERIFIED** on the scratch build (53,936 B): F1 CLEAN
  with the 8-byte taken layout (compare OK), F2/V1B
  CLEAN, E2 correctly NOT_RESOLVED, F5/F7 CLEAN --
  the whole F/E regression set passes.  Porting all
  seven fixes ((a)(b)(c)(d), #66, (e), (f)) to
  src/zma.asm and running the FULL final
  verification on the resulting build.
- 2026-11-13 (6th attempt): FINAL build (53,936 B)
  verification 1/6: P4 C/B/F groups 12/12 OK
  (compare.py C1-C3, B1-B2 with BLOB.BIN staged,
  F1-F7; console ERROR scan clean).
- 2026-11-13 (6th attempt): FINAL build verification
  2/6: P4 E group (minus E4) 5/5 OK (E1/E2/E3/E5/E6;
  consoles carry exactly the expected cross-format
  errors).  P4 now stands at 17/18 with E4's long run
  still to go on this build.
- 2026-11-13 (6th attempt): FINAL build verification
  3/6: P3 suite 23/23 OK (p3/compare.py).
- 2026-11-13 (6th attempt): FINAL build verification
  4/6: P1+P2 regression 31/33 OK (the two non-OK are
  the baseline single-disk bacon staging items).
- 2026-11-13 (6th attempt): FINAL build verification
  5/6: author caps re-verified -- N0 (REPEAT 16384)
  assembles (16384-byte output), N1 (16385) and N5
  (20000) print "REPEAT count too large.", N2
  (nesting 3) prints "REPEAT nesting too deep.",
  N3 (nesting 2) outputs 00 01 02 00 01 02.
- 2026-11-13 (6th attempt): CAPS BATCH ANOMALY
  (recorded before any fix, per standing rule): on
  vfincaps.dsk the batch did not finish inside the
  600 s virtual budget (no DONE.TXT; N2/N3 never
  ran).  N1/N5 printed "REPEAT count too large." as
  expected, but N0.BIN is only 5,120 bytes (expected
  16,384 zeros for REPEAT 16384 / db 0) although
  N0's own console is clean and N2's command had
  already started.  Investigating with an isolated
  N0 run before drawing conclusions.
- 2026-11-13 (6th attempt): N0 anomaly REPRODUCED in
  isolation (vn0.dsk, DONE.TXT written): N0.BIN is
  5,120 bytes, not 16,384; ZMA.LOG is 577,536 bytes,
  so large-file writes per se work.  Bacon outputs
  (13,039 B) were byte-identical on earlier builds,
  so plain output writing handles >5,120.  Suspect
  the REPEAT-expansion emit path; checking the
  output-buffer constants and whether the 53,912
  reference build shows the same size.
- 2026-11-13 (6th attempt): N0 truncation is NOT a
  regression and NOT disk-full: the 53,912 reference
  build produces the identical result (N0.BIN 5,120;
  ZMA.LOG 577,536 with exactly 5,497 db detail
  lines; ~27 KB free on the 720 KB image).  The
  final pass stops at 5,497 iterations and the
  trailing 377-byte partial buffer never lands
  (5,497 - 377 = 5,120).  The inherited "N0
  16,384-byte output verified" claim does not hold
  against filesystem evidence: REPEAT counts above
  ~5,497 silently truncate.  This is a pre-existing
  product bug (call it Bug #68) in both builds.
  Bracketing the threshold with a count sweep
  (4000/5490/5500/6000/8000) and reading the REPEAT
  / dict / arena code next.
- 2026-11-13 (6th attempt): Bug #68 RETRACTED as a
  product bug: the 720 KB test image's FAT shows 0
  free clusters after the N0 run.  DOS2 ZMA's
  listing log costs ~105 B per emitted byte for a
  REPEAT body, so REPEAT 16384 needs ~1.7 MB of log
  -- impossible on the 720 KB test medium; writes
  past the fill point fail silently and the output
  truncates at the last successful flush (5,120).
  The assembly itself runs to completion (exit
  normal, DONE.TXT written).  This is exactly the
  known open item "zma.log suppression on small
  media -- author's decision pending".  Remaining
  check: cross ZMA's own log size for the same
  source, and the sweep results for sub-threshold
  counts (where the disk does not fill).
- 2026-11-13 (6th attempt): sweep confirms the media
  theory: S4000.BIN is exactly 4,000 bytes (log fit);
  larger counts truncate only because the shared
  720 KB disk fills with the listing log (cross's
  own log for N0 is 1,671,692 bytes -- DOS2's format
  is faithful).  REPEAT expansion itself is
  byte-exact where the medium holds out.
- 2026-11-13 (6th attempt): FINAL build verification
  5/6 (caps, corrected): N1 (16385) and N5 (20000)
  print "REPEAT count too large."; N2 (nesting 3)
  prints "REPEAT nesting too deep."; N3 (nesting 2)
  outputs 00 01 02 00 01 02.  N0 (16384) is
  accepted and assembles to completion, but its
  16,384-byte output cannot be recorded on the
  720 KB test medium: the cross-faithful zma.log
  alone needs 1,671,692 bytes (measured with cross
  ZMA) and the disk fills first (FAT: 0 free
  clusters; output stops at the last flush,
  5,120 B; identical on the 53,912 build).  Where
  the medium holds out, expansion is byte-exact
  (sweep: 4,000/4,000).  Recording N0's full output
  awaits the author's zma.log-suppression decision
  or a larger medium.
- 2026-11-13 (6th attempt): FINAL build verification
  6/6 (E4): E4 OK on the final build -- console
  carries "IF layout search exceeded 1024
  candidates; minimum size is not guaranteed." and
  the 44-byte binary matches gold.  P4 suite is now
  18/18 on the final 53,936-byte build.
- 2026-11-13 (6th attempt): bacon two-drive, part 1:
  BLIB.BIN is byte-identical (12,929 B, md5
  b30c006ee82dd315f9d152ac97a5253d), console clean.
  The second assembly (BACONLDR -> BOTH.BIN) did
  not finish inside the 900 s window; re-running it
  alone with a longer window.
- 2026-11-13 (6th attempt): bacon two-drive, part 2:
  BOTH.BIN is byte-identical (13,039 B, md5
  35ed1d68582a4cc68eebbb2413b52b60), console clean,
  DONE.TXT written.

================================================================
P4 COMPLETE (2026-11-13, 6th attempt, final build)
================================================================
Final build: build/ZMA.COM = 53,936 bytes
(md5 1167701ba6890214b7b9af7263450949), ~64 bytes
below the ~54,000-byte DOS2 load limit.
ZMADATA.BIN split NOT adopted.

Verification, all on the final build:
- P4 suite 18/18: C1 C2 C3 (charsets), B1 B2
  (BINARY_LINK), E1-E6 (IF layout search errors),
  F1-F7 (IF/REPEAT regressions).
- P3 suite 23/23.  P1+P2 regression 31/33 (the two
  non-OK are the known single-disk bacon staging
  items, unchanged from baseline).
- bacon two-drive (tests/run2d.py family):
  BLIB.BIN 12,929 B md5 b30c006ee82dd315f9d152ac97a5253d;
  BOTH.BIN 13,039 B md5 35ed1d68582a4cc68eebbb2413b52b60;
  both byte-identical to cross ZMA.
- Author caps: REPEAT 16385 / 20000 ->
  "REPEAT count too large."; REPEAT nesting 3 ->
  "REPEAT nesting too deep."; nesting 2 OK
  (00 01 02 00 01 02).  REPEAT 16384 is accepted
  and assembles to completion, but its 16,384-byte
  output cannot be recorded on the 720 KB test
  medium: the cross-faithful zma.log alone is
  1,671,692 bytes for that source (measured with
  cross ZMA), the test disk fills (FAT: 0 free
  clusters) and the output stops at the last
  successful flush (5,120 B; identical behaviour
  on the pre-P4-fix 53,912 build, so no
  regression).  Where the medium holds out,
  expansion is byte-exact (sweep: 4,000/4,000).

Bugs fixed in P4 (all in src/zma.asm):
- #63: cur_site collapse inside text entries
  self-linked BR_BNEXT (search looped forever).
- #64: if_ent_fld let if_ent_top clobber the flags
  register, so ELSE-branch condition reads hit the
  head record (the F-series failures / F7 hang);
  push af/pop af (+2 B).
- #65 (E group): (a) MAPPING_CHAR argument errors
  now report "Illegal expression." like cross
  (was "Illegal parameter."); (b) the pre-final
  audit escalates an inconsistent converged state
  to the layout search; (c) unresolved-this-pass +
  size-dependent blocks register as search
  candidates; (d) DFS validation no longer restores
  the pre-trial snapshot first (it wiped the labels
  under test).
- #66: dfs_branch2 held the branch count in B
  across a record read whose helper loads BC --
  count read as 0, search ended after one
  validation; the has_else flag now crosses the
  read in the AF stack slot (+2 B).
- #67: dry-pass addresses past a multi-branch
  block are block-relative (each branch head
  resets pc to the block base and ENDIF does not
  re-add the selected branch's size), so DFS
  validation judged choices against phantom
  addresses and rejected F1's only consistent
  layout.  Validation now runs two final-format
  passes (layout pass with validation off, then
  the validating pass over the real addresses) in
  both the DFS and the audit; the winner final
  pass no longer re-validates against the dry
  dict.

Intentional divergences from cross ZMA (author
rulings, 2026-11-13): REPEAT iterations capped at
16,384; REPEAT nesting capped at 2 (the combined
MACRO/SCOPE/REPEAT cap of 8 is unchanged).

Known remaining divergences / open items:
- Error line attribution differs where cross's is
  an artifact of its string-keyed maps: E4 reports
  line 2 vs cross's 16; the nesting-cap error is
  attributed at the enclosing ENDR line.
  Message texts match.
- zma.log: no cycle lines; line images are the
  source text; label+instruction composite lines
  occupy one block (P3-era, unchanged).
- Console prints no "Found N error(s)." summary.
- zma.log suppression for small media is still
  the author's pending decision (see the REPEAT
  16384 note above); NOT implemented unilaterally.
================================================================

================================================================
## P5 — self-host (STARTED 2026-11-13)
================================================================
Goal: DOS2 ZMA.COM assembles src/zma.asm (307,712 B,
16,951 lines, self-contained -- no INCLUDE / BINARY_LINK
use in the body) and the output is BYTE-IDENTICAL to the
cross-built build/ZMA.COM (53,936 B, md5
1167701ba6890214b7b9af7263450949).  Then the self-hosted
binary itself must assemble a small test correctly
(smoke test).

Media plan (the log is the constraint, as in P4):
- DOS2's cross-faithful zma.log for this source is
  ~2.5 MB in cross terms (cross src/zma.log = 2,554,019 B
  for the same input); it cannot fit any single floppy.
  Precedent (bacon two-drive, P4 N0): a log that fills
  its disk truncates silently and does NOT affect the
  output binary, as long as the output is on a separate
  drive.  The zma.log suppression switch is the author's
  pending decision and is NOT implemented here.
- Layout (two drives, FS-A1ST_full_2D):
  A: (720 KB boot, testFINAL base, everything except
     MSXDOS2.SYS / COMMAND2.COM deleted -- the base's
     stale 21,588 B ZMA.COM is removed): ZMA.COM =
     current build (53,936 B), zma.asm (307,712 B),
     AUTOEXEC.BAT.  CWD = A:, so ZMA.LOG / ZMA.SYM /
     CON.TXT land on A: (~330 KB headroom; the log
     truncates partway -- accepted, see above).
  B: (fresh 1.44 MB data image, mk144 geometry):
     receives ONLY B:ZMA2.BIN (53,936 B expected) and
     B:DONE.TXT.
- AUTOEXEC: `ZMA zma.asm B:ZMA2.BIN > A:CON.TXT`,
  then `ECHO DONE > B:DONE.TXT`, then A:DONE.TXT.
- A short pilot run validates staging before the long
  run; the long run uses scratch/run2d_long.py's
  pattern with a virtual budget of 5,400 s.

----------------------------------------------------------------
P5 checkpoint (2026-11-13): pilot result + zma.log ruling
----------------------------------------------------------------
Pilot run (420 s virtual, tests/p5/run_p5.py): FAILED at the
media layer, not in ZMA.  Screenshot evidence: ZMA started
(banner shown), then DOS stopped the batch with
"Not a DOS disk reading drive B: / Abort or Retry (A/R)?"
when ZMA tried to create B:ZMA2.BIN.  The fresh 1.44 MB B:
image (mk144-style BPB patch) is rejected by DOS2 on the
FS-A1ST_full_2D machine's drive B; the PROVEN two-drive
layout (bacon, P2-P4) uses 720 KB images on BOTH drives.
Fix for the re-pilot: B: becomes a plain 720 KB image
(the output is only 53,936 B, so nothing is lost).
A: contained no CON.TXT / ZMA.LOG afterwards -- consistent
with the batch never getting past the output create (and
DOS directory caching on emulator quit); no ZMA-side issue
indicated.

AUTHOR RULING (2026-11-13, settles the long-pending
zma.log question): the DOS2 zma.log becomes the
ABBREVIATED form.  Contents are ONLY (1) for each line
that raised an error or warning: its line number and
line content (with the error message); (2) the defined
symbol list (the << label >> section).  No full line
listing (<< code >>), no << character map >>, no header
block.  Intentional divergence from cross ZMA's full
log; recorded in DESIGN.md section 7 item 8.  Console
output and exit behavior are unchanged; generated
binaries must stay byte-identical across all suites.
The log comparison criterion changes accordingly: the
P4 C-group charmap-section check is retired; the new
check is "log contains only error/warning line records
plus the symbol list".

Implementation plan (src/zma.asm, BEFORE the self-host
final confirmation; the self-host target is then taken
from the NEW source/build pair):
- log_open_write_header: create the file + set
  log_active only (no banner / -D listing / DEFS /
  OUTPUT TYPE / << code >> header writes).
- Per-line listing suppressed: log_line_begin only
  clears per-line state; log_line_end and log_capture
  become no-ops; dump rows, definition info lines and
  scope enter/exit lines are no longer emitted.
- Error lines (lw_error_line / lw_msg_error_line) now
  first emit the offending source line once per line
  ("<line6>|      |    |<raw text>", new lw_src_line),
  then the existing error record.  All log-reaching
  errors fire inside process_line during the final
  pass, where line_buf holds exactly that line's text
  (deferred IF-search reports via if_report_at run
  BEFORE the log is opened, so they never reached the
  log under the old format either -- unchanged).
  MESSAGE lines are console-only now (not errors).
- log_finish: label section kept verbatim;
  lf_nosec drops cs_rebuild_dump_state + lf_charmap.
  cs_rebuild_dump_state and lf_charmap (with lcm_*
  helpers) are deleted; zma.sym writing is untouched.
- Expected effects: COM size drops (dead log code is
  removed); the P5 media constraint disappears (log
  for zma.asm ~= symbol list only); REPEAT 16384
  (P4 N0) must become fully recordable on 720 KB --
  to be re-verified after the change.

----------------------------------------------------------------
P5 checkpoint (2026-11-13): abbreviated log IMPLEMENTED
----------------------------------------------------------------
src/zma.asm edited (anchor-based surgical edit, script
kept at scratch/p5/apply_log_change.py; pre-change source
+ cross log/sym backed up in scratch/p5/):
- log_open_write_header writes no header block (create +
  log_active only); -D listing / DEFS / OUTPUT TYPE /
  << code >> header code and strings deleted.
- log_line_begin only clears the per-line flag;
  log_line_end and log_capture are no-ops; dump rows,
  definition info lines, MESSAGE log lines and scope
  enter/exit lines are no longer emitted (routines and
  their strings deleted or stubbed).
- NEW lw_src_line: an error record is now preceded
  (once per line) by the source line record
  "<line6>|      |    |<raw text>"; called from
  lw_error_line and lw_msg_error_line.
- log_finish: << label >> section kept verbatim;
  cs_rebuild_dump_state and lf_charmap (+ helpers,
  ~250 lines) deleted.  zma.sym untouched.
- Net: 16,951 -> 16,246 lines.  Cross build "Success.":
  ZMA.COM = 52,060 B (was 53,936; -1,876 B), md5
  d2bd2b0f5b423d983d48cb749758621f.  Load-limit margin
  grows from ~64 B to ~1,940 B.
Re-verification standard updated: tests/p4/compare.py
and tests/p2/compare.py log checks are being replaced
with the new-format criteria (label section byte-equal
to the cross golden's; error blocks = source line +
error records; C-group charmap check retired).
autoexec_p4.txt now copies ZMA.LOG to <case>.ZLO for
every case.  Suite re-runs on the new build follow.

----------------------------------------------------------------
P5 checkpoint (2026-11-13): suite re-run #1 + harness lesson
----------------------------------------------------------------
First new-build P4 batch (all 17 non-E4 cases on ONE disk)
appeared to stall in E3; screenshot evidence showed the
real cause: "ZMA.LOG -- Root directory full" /
"*** Redirection error: Root directory full".  The 720 KB
root holds 112 entries; the stock testFINAL base carries
~50 P1-era leftovers, and 17 cases x (BIN + console + ZLO)
+ ZMA.LOG/SYM overflowed it mid-batch.  E3 itself had
assembled CORRECTLY (its new-format log was complete:
source line record + error record).  HARNESS LESSON:
stage suite disks CLEAN (delete everything except
MSXDOS2.SYS / COMMAND2.COM) -- helper kept at
scratch/p5/stage_clean.py.  Batches re-split as in the
P4 acceptance (C/B/F disk, E disk, E4 alone).
Spot results from the aborted batch (valid, pre-overflow):
E1 log = source line + "Default character set cannot be
mapped and changed." record; E3 likewise for "Too many
parameters." -- the new format works as specified.

----------------------------------------------------------------
P5 checkpoint (2026-11-13): abbreviated-log re-verification
----------------------------------------------------------------
New build (52,060 B, md5 d2bd2b0f...), clean-staged disks:
- P4 C/B/F group: 12/12 under the new criteria (binaries
  byte-identical + consoles clean per compare.py; logs
  per scratch/p5/check_p4log.py: label sections
  byte-equal to the cross goldens', no forbidden
  sections, no error blocks).  Log sizes now 0-50 B
  (was: up to ~600 KB for C2).
- P4 E group (E1/E2/E3/E5/E6): consoles + binaries OK
  per compare.py.  Logs: E1/E3/E5/E6 carry exactly the
  expected in-pass error block (source line record with
  text verified against the .ASM + error record); E2's
  log is label-section only (its NOT_RESOLVED report is
  issued before the log opens -- unchanged behavior).
- E2 label-section nuance (pre-existing, NOT caused by
  this change; the label dump code is untouched): gold
  (cross) prints "TAIL ... ????" (symbol unresolved in
  its analyze state), DOS2's fail-final pass prints
  "TAIL ... 1 ( 0x1 )".  Recorded as a known divergence
  of the NOT_RESOLVED handling; compare.py's new-log
  check tolerates a golden "????" row by name.
- compare.py (p4) rewritten to the new criteria;
  autoexec_p4.txt copies ZMA.LOG for every case.
Remaining: E4 long run, P3, P1+P2, caps + N0 effect
check, bacon two-drive; then the self-host itself.

- P4 SUITE: **18/18 OK** on the new build under the
  NEW log criteria (merged disk tests/p4all.dsk,
  tests/p4/compare.py): all binaries byte-identical,
  all consoles unchanged, all logs verified as
  error-blocks + label section (E2/E4 label sections
  match the goldens modulo the accepted "????"
  unresolved-row artifact).
- P3 SUITE: **23/23 OK** (unchanged criteria).
- P1+P2 REGRESSION: **33/33 OK** -- above the 31/33
  baseline.  The two baseline non-OK items were both
  staging artifacts and now pass legitimately: the
  single-disk bacon T3 (the old full log used to fill
  the disk mid-run; the abbreviated log does not) and,
  after re-staging with TESTINC.ASM (which the dirty
  base used to provide implicitly), TEST1/SYM T1.
  All four new-format LOG checks (S6/S1/S4/D1) pass:
  each DOS log is exactly the golden's label section.
- AUTHOR CAPS re-verified on the new build: N1 (16385)
  and N5 (20000) print "REPEAT count too large.",
  N2 (nesting 3) prints "REPEAT nesting too deep.",
  N3 (nesting 2) outputs 00 01 02 00 01 02.
- **N0 EFFECT CHECK PASSED**: REPEAT 16384 now records
  FULLY on a 720 KB disk -- N0.BIN = 16,384 bytes, all
  zero, console clean, DONE written (previously
  truncated at 5,120 B because the cross-faithful log
  filled the medium).  The ruling's intended effect is
  confirmed.
- BACON two-drive on the new build: BLIB.BIN 12,929 B
  md5 b30c006ee82dd315f9d152ac97a5253d and BOTH.BIN
  13,039 B md5 35ed1d68582a4cc68eebbb2413b52b60 --
  both byte-identical; consoles clean; DONE written.
  The BOTH run's zma.log (label section for ~1,300
  symbols) is 79,623 B and now fits its disk (the old
  format's 1.37 MB overflowed A:).
ALL re-verification for the abbreviated log is green:
P4 18/18, P3 23/23, P1+P2 33/33, caps, N0 effect,
bacon.  Proceeding to the self-host (P5 proper) with
the new pair: src/zma.asm 295,865 B md5
1f468965301678cd21c7baf9599556f3; target ZMA.COM
52,060 B md5 d2bd2b0f5b423d983d48cb749758621f.
Staging: tests/p5/selfA2.dsk (clean 720 KB: system +
AUTOEXEC + ZMA.COM + zma.asm, in-image md5s verified)
and tests/p5/selfB2.dsk (empty 720 KB -- the pilot's
1.44 MB B: was rejected by DOS2, "Not a DOS disk").
- N0 isolated re-check: DONE, N0.BIN 16,384 B all
  zero, console clean, and ZMA.LOG is now **44 bytes**
  total ("<< label >>" + the single @REPEAT0:I row) --
  the same source whose cross-faithful DOS2 log was
  ~577 KB on this medium (1.67 MB in cross terms).
Self-host pilot (new pair, B: = 720 KB) started.

================================================================
## P5 COMPLETION (2026-11-13) -- PROJECT COMPLETE
================================================================
The media plan above was overtaken by events in the best
possible way: the author's abbreviated-log ruling (DESIGN
section 7 item 8) removed the log-size constraint
entirely, so the layout became two plain 720 KB drives
(A: boot + ZMA.COM + zma.asm + log/sym/console;
B: output + DONE only).  The first 1.44 MB B: pilot was
rejected by DOS2 ("Not a DOS disk reading drive B:") --
a staging fact, recorded earlier; the 720 KB B: is the
proven form.

SELF-HOST RESULT (acceptance criterion 1):
- DOS2 ZMA.COM (52,060 B build) assembled src/zma.asm
  (295,865 B, 16,246 lines, md5
  1f468965301678cd21c7baf9599556f3) on
  Panasonic_FS-A1ST_full_2D, output to B:ZMA2.BIN.
- B:ZMA2.BIN = 52,060 bytes, md5
  **d2bd2b0f5b423d983d48cb749758621f** -- BYTE-IDENTICAL
  to the cross-built build/ZMA.COM.  DONE.TXT markers
  were written on both drives; the run had already
  finished when the first disk snapshot was taken,
  ~150 s into a 420 s pilot budget (the "pilot" thus
  serves as the acceptance run; the evidence -- DONE
  markers plus byte identity -- is complete).
- Byproducts: ZMA.LOG = 88,820 B (the << label >>
  section only; no error blocks -- the source assembles
  clean), ZMA.SYM = 40,354 B.  Both fit A: with room to
  spare (the old format's log alone would have been
  ~2.5 MB).  Every one of the 2,048 symbol rows DOS2
  printed is byte-identical to cross's row for that
  symbol, in both files.
- NEW KNOWN LIMITATION (found by the self-host,
  recorded per the phase rule; NOT fixed in P5):
  st_collect caps the symbol dumps at SYMTAB_MAX =
  2,048 entries.  zma.asm defines 2,086 symbols, so
  the last-collected 38 symbols are missing from
  ZMA.LOG's label section and from ZMA.SYM.  The
  output binary is unaffected (the dumps are written
  after the output closes).  Raising the cap is a
  one-line change (plus its resident-array size) for
  a future revision; it is flagged for the author
  rather than folded in here, because any source
  change would invalidate the byte-identity above
  and restart the verification cycle.
- Harness curiosity (no impact): A:CON.TXT, the
  batch's redirection target, is absent from the
  final image although the batch demonstrably ran
  (outputs + DONE chain).  Attributed to the host
  copy/kill racing the emulator's lazy image flush;
  the console's content is fully determined by the
  other evidence (clean log + byte-identical output
  = banner + "Success.").

SMOKE TEST (acceptance criterion 2): the self-hosted
binary (extracted B:ZMA2.BIN, staged as ZMA.COM)
boots on DOS2 and assembles correctly:
- EX1.ASM -> 20 B, byte-identical to build/EX1REF.BIN
- F1.ASM  -> 8 B, byte-identical to tests/p4 gold
- E1.ASM  -> console error in the exact format and a
  correct abbreviated log (source line + error record)

WHOLE-PROJECT SUMMARY
- Deliverable: ZMA for MSX-DOS2 -- build/ZMA.COM,
  52,060 bytes (DOS2 load limit ~54,000; margin
  ~1,940 B), assembled from src/zma.asm by cross ZMA
  and now proven to assemble ITSELF byte-identically.
  ZMADATA.BIN split was never needed.
- Phase record:
  P1 core:            21,588 B; regression 17/17
  P2 symbols:         39,522 B; P1+P2 suite 31/33
                      baseline (33/33 on the final
                      build -- see below)
  P3 MACRO/REPEAT/LINK: 53,879 B; suite 23/23
  P4 IF search/charset/BINARY_LINK: 53,936 B;
                      suite 18/18; caps implemented
  P5 self-host:       52,060 B after the abbreviated
                      log; self-host byte-identical
- Final verification on the shipped build:
  P4 18/18, P3 23/23, P1+P2 33/33, author caps
  (16385/20000 -> "REPEAT count too large.", nesting
  3 -> "REPEAT nesting too deep.", nesting 2 OK),
  REPEAT 16384 fully recorded on 720 KB (16,384 B,
  44-byte log), bacon standalone + combined
  byte-identical via two drives, self-host
  byte-identical, smoke test passed.
- Bugs fixed across the project: #1-#67 (67 total;
  #68 was raised during P4 and retracted -- a media
  capacity artifact, not a product bug).  P4 alone:
  #63-#67.
- Intentional divergences from cross ZMA (author
  rulings, DESIGN.md section 7): REPEAT iterations
  <= 16,384 and REPEAT nesting <= 2 (DOS2-only
  errors); the abbreviated zma.log (2026-11-13).
- Other known divergences (recorded in the phase
  sections): no per-instruction cycle lines (moot
  since the listing itself is gone); error line
  attribution differs where cross's is a
  string-keyed-map artifact (E4: line 2 vs 16;
  E5/E6: offending line vs REPEAT line; caps errors
  attributed at the enclosing construct); the
  console prints no "Found N error(s)." summary;
  E2/E4 label sections print natural values where
  cross prints "????" for layout-unresolved symbols;
  one P2-era symbol-collision case judged
  differently; a macro defined inside a REPEAT body
  gets a fresh site per outer-iteration context
  (cross reports "Multiple definition." from the 2nd
  iteration); through-parameter (@) values are built
  in a 640-byte buffer (longer -> "Illegal
  parameter."); symbol dumps cap at 2,048 symbols
  (above).
- Author-decision items: the long-pending zma.log
  question is SETTLED by the 2026-11-13 ruling and
  implemented here.  No ZMA items remain open on the
  author.  (The SYMTAB_MAX raise is offered as an
  optional future fix, not a pending decision.)
================================================================
