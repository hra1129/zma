// --------------------------------------------------------------------
//	Z80 Macro Assembler parse
// ====================================================================
//	2019/05/04	t.hara
// --------------------------------------------------------------------

#include "zma_parse.hpp"
#include "zma_text.hpp"
#include "zma_parse_process.hpp"
#include <string>
#include <cctype>
#include <iostream>
#include <fstream>
#include <sstream>
#include <algorithm>

#include "zma_parse_process_blank.hpp"

// --------------------------------------------------------------------
bool CZMA_PARSE_BLANK::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	this->is_data_fixed = true;
	update_flags( &info, p_last_line );
	this->set_code_size( &info, 0 );
	return this->check_all_fixed();
}

