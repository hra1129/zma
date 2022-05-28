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

// --------------------------------------------------------------------
bool CZMA_PARSE_ENDSCOPE::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {
	std::string s;

	update_flags( &info, p_last_line );
	if( words.size() > 1 ) {
		put_error( "ENDSCOPE command has not parameter." );
		return false;
	}
	this->is_data_fixed = true;
	this->set_code_size( &info, 0 );
	if( info.scope.size() < 1 ) {
		put_error( "ENDSCOPE in wrong position." );
		return false;
	}
	if( info.scope[ info.scope.size() - 1 ][0] == '@' ) {
		put_error( "ENDSCOPE in wrong position." );
		return false;
	}
	info.scope.pop_back();

	//	log
	if( !is_analyze_phase ) {
		log.push_back( "[\t" + get_line() + "]" );
		log.push_back( "\tScope path: " + info.get_scope_path() );
		log.push_back( "" );
	}
	return check_all_fixed();
}

