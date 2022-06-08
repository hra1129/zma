// --------------------------------------------------------------------
//	Z80 Macro Assembler parse
// ====================================================================
//	2019/05/04	t.hara
// --------------------------------------------------------------------

#pragma once

#include "zma_parse_process.hpp"

// --------------------------------------------------------------------
class CZMA_PARSE_CONTAINER: public CZMA_PARSE {
public:
	CZMA_TEXT text;
	bool is_loaded = false;
	std::string s_file_name;

	using CZMA_PARSE::CZMA_PARSE;

	bool update_flags( CZMA_INFORMATION *p_info, const CZMA_PARSE *p_last_line );
	bool process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line = nullptr ) override;
	bool write_output_and_log( CZMA_INFORMATION& info, std::ofstream* f ) override;
};
