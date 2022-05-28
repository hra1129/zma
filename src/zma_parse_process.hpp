// --------------------------------------------------------------------
//	Z80 Macro Assembler parse
// ====================================================================
//	2019/05/04	t.hara
// --------------------------------------------------------------------

#pragma once

#define CLASS_CZMA_PARSE( name ) \
	class CZMA_PARSE_##name: public CZMA_PARSE {													\
	public:																							\
		using CZMA_PARSE::CZMA_PARSE;																\
		bool process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line = nullptr ) override;			\
	};

enum class CZMA_COMMAND_TYPE {
	CZMA_ERROR, CZMA_BLANK, CZMA_INCLUDE, CZMA_ADD_INCLUDE_PATH, CZMA_USER_ERROR, CZMA_USER_MESSAGE, CZMA_LABEL, CZMA_GLOBAL_LABEL, 
	CZMA_SCOPE, CZMA_ENDSCOPE, CZMA_IF, CZMA_ELSEIF, CZMA_ELSE, CZMA_ENDIF, CZMA_ENDM,
	CZMA_ALIGN, CZMA_SPACE, CZMA_REPEAT, CZMA_ENDR, CZMA_ORG, CZMA_GLOBAL_SYMBOL, CZMA_BINARY_LINK, CZMA_DEFB, CZMA_DEFW, CZMA_DEFD, CZMA_DEFS,
	CZMA_LD, CZMA_LDI, CZMA_LDIR, CZMA_LDD, CZMA_LDDR, CZMA_EX, CZMA_EXX, CZMA_PUSH, CZMA_POP, 
	CZMA_RLCA, CZMA_RLA, CZMA_RLC, CZMA_RL, CZMA_RRCA, CZMA_RRA, CZMA_RRC, CZMA_RR,
	CZMA_SLA, CZMA_SRA, CZMA_SRL, CZMA_SLL, CZMA_ADD, CZMA_ADC, CZMA_INC, CZMA_SUB, CZMA_SBC,
	CZMA_DEC, CZMA_AND, CZMA_OR, CZMA_XOR, CZMA_CPL, CZMA_NEG, CZMA_CCF, CZMA_SCF,
	CZMA_BIT, CZMA_RES, CZMA_SET, CZMA_CPI, CZMA_CPIR, CZMA_CPD, CZMA_CPDR, CZMA_CP, 
	CZMA_JP, CZMA_JR, CZMA_DJNZ, CZMA_CALL, CZMA_RET, CZMA_RETI, CZMA_RETN, CZMA_RST, 
	CZMA_NOP, CZMA_HALT, CZMA_DI, CZMA_EI, CZMA_IM0, CZMA_IM1, CZMA_IM2, CZMA_IN, 
	CZMA_INI, CZMA_INIR, CZMA_IND, CZMA_INDR, CZMA_OUT, CZMA_OUTI, CZMA_OTIR, 
	CZMA_OUTD, CZMA_OTDR, CZMA_DAA, CZMA_RLD, CZMA_RRD, CZMA_MULUB, CZMA_MULUW,
};

#include "zma_parse_process_align.hpp"
#include "zma_parse_process_user_error.hpp"
#include "zma_parse_process_user_message.hpp"
#include "zma_parse_process_add_include_path.hpp"
#include "zma_parse_process_space.hpp"
#include "zma_parse_process_blank.hpp"
#include "zma_parse_process_macro.hpp"
#include "zma_parse_process_label.hpp"
#include "zma_parse_process_global_label.hpp"
#include "zma_parse_process_symbol.hpp"
#include "zma_parse_process_global_symbol.hpp"
#include "zma_parse_process_scope.hpp"
#include "zma_parse_process_endscope.hpp"
#include "zma_parse_process_binary_link.hpp"
#include "zma_parse_process_defb.hpp"
#include "zma_parse_process_defw.hpp"
#include "zma_parse_process_defd.hpp"
#include "zma_parse_process_defs.hpp"
#include "zma_parse_process_org.hpp"
#include "zma_parse_process_ld.hpp"
#include "zma_parse_process_ldi.hpp"
#include "zma_parse_process_ldir.hpp"
#include "zma_parse_process_ldd.hpp"
#include "zma_parse_process_lddr.hpp"
#include "zma_parse_process_ex.hpp"
#include "zma_parse_process_exx.hpp"
#include "zma_parse_process_push.hpp"
#include "zma_parse_process_pop.hpp"
