// --------------------------------------------------------------------
//	Z80 Macro Assembler parse
// ====================================================================
//	2019/05/04	t.hara
// --------------------------------------------------------------------

#pragma once

#include "zma_parse_process.hpp"

CLASS_CZMA_PARSE( IF );

// --------------------------------------------------------------------
class CZMA_PARSE_ELSEIF: public CZMA_PARSE_IF {
public:
	using CZMA_PARSE_IF::CZMA_PARSE_IF;
	bool process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line = nullptr ) override;
};

// --------------------------------------------------------------------
class CZMA_PARSE_ELSE: public CZMA_PARSE_IF {
public:
	using CZMA_PARSE_IF::CZMA_PARSE_IF;
	bool process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line = nullptr ) override;
};

// --------------------------------------------------------------------
class CZMA_PARSE_ENDIF: public CZMA_PARSE {
public:
	CZMA_IF_T* p_if = nullptr;
	bool is_loaded = false;

	using CZMA_PARSE::CZMA_PARSE;
	bool process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line = nullptr ) override;
	bool write_output_and_log( CZMA_INFORMATION& info, std::ofstream* f ) override;
};

