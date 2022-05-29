// --------------------------------------------------------------------
//	Z80 Macro Assembler parse
// ====================================================================
//	2019/05/04	t.hara
// --------------------------------------------------------------------

#pragma once

#include "zma_parse_process.hpp"

CLASS_CZMA_PARSE( MACRO );

// --------------------------------------------------------------------
class CZMA_PARSE_ENDM: public CZMA_PARSE {
public:
	CZMA_MACRO* p_macro = nullptr;
	bool is_loaded = false;

	using CZMA_PARSE::CZMA_PARSE;
	bool process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line = nullptr ) override;
};

// --------------------------------------------------------------------
class CZMA_PARSE_MACRO_INS: public CZMA_PARSE {
public:
	CZMA_TEXT text;
	bool is_loaded = false;

	using CZMA_PARSE::CZMA_PARSE;
	bool process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line = nullptr ) override;
	bool write( CZMA_INFORMATION& info, std::ofstream* f ) override;
};
