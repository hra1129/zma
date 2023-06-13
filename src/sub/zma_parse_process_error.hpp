// --------------------------------------------------------------------
//	Z80 Macro Assembler parse
// ====================================================================
//	2019/05/04	t.hara
// --------------------------------------------------------------------

#pragma once

#include "zma_parse_process.hpp"

// --------------------------------------------------------------------
class CZMA_PARSE_ERROR: public CZMA_PARSE {
public:
	using CZMA_PARSE::CZMA_PARSE;
	bool process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line = nullptr ) override;
	virtual bool is_parse_error( void ) override {
		return true;
	}
};
