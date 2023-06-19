; =============================================================================
;	Z80 Utility
; -----------------------------------------------------------------------------
;	2019/07/04	t.hara
; =============================================================================

; =============================================================================
;	RL16	{BC|DE|HL}
;
;	���r�b�g���[�e�C�g�Bbit0 �ɂ� CF �̒l���ACF �ɂ͂͂ݏo���� bit15 ���i�[�����B
; =============================================================================
RL16	macro	@reg16
			if		reg16 == "BC"
				RL		C
				RL		B
			elseif	reg16 == "DE"
				RL		E
				RL		D
			elseif	reg16 == "HL"
				RL		L
				RL		H
			else
				error	"Unsupported argument \" + reg16 + "\" in RL16 macro."
			endif
		endm

; =============================================================================
;	RR16	{BC|DE|HL}
;
;	�E�r�b�g���[�e�C�g�Bbit15 �ɂ� CF �̒l���ACF �ɂ͂͂ݏo���� bit0 ���i�[�����B
; =============================================================================
RR16	macro	@reg16
			if		reg16 == "BC"
				RR		B
				RR		C
			elseif	reg16 == "DE"
				RR		D
				RR		E
			elseif	reg16 == "HL"
				RR		H
				RR		L
			else
				error	"Unsupported argument \" + reg16 + "\" in RR16 macro."
			endif
		endm

; =============================================================================
;	SLA16	{BC|DE|HL}
;
;	�Z�p1bit���V�t�g�Bbit0 �� 0 �ɂȂ�B
; =============================================================================
SLA16	macro	@reg16
			if		reg16 == "BC"
				SLA		C
				RL		B
			elseif	reg16 == "DE"
				SLA		E
				RL		D
			elseif	reg16 == "HL"
				SLA		L
				RL		H
			else
				error	"Unsupported argument \" + reg16 + "\" in SLA16 macro."
			endif
		endm

; =============================================================================
;	SRA16	{BC|DE|HL}
;
;	�Z�p1bit�E�V�t�g�Bbit15 �͕ω������B
; =============================================================================
SRA16	macro	@reg16
			if		reg16 == "BC"
				SRA		B
				RR		C
			elseif	reg16 == "DE"
				SRA		D
				RR		E
			elseif	reg16 == "HL"
				SRA		H
				RR		L
			else
				error	"Unsupported argument \" + reg16 + "\" in SRA16 macro."
			endif
		endm

; =============================================================================
;	SRL16	{BC|DE|HL}
;
;	�_��1bit�E�V�t�g�Bbit15 �� 0 �ɂȂ�B
; =============================================================================
SRL16	macro	@reg16
			if		reg16 == "BC"
				SRL		B
				RR		C
			elseif	reg16 == "DE"
				SRL		D
				RR		E
			elseif	reg16 == "HL"
				SRL		H
				RR		L
			else
				error	"Unsupported argument \" + reg16 + "\" in SRL16 macro."
			endif
		endm
