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
bool CZMA_PARSE_USER_MESSAGE::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {
	CVALUE v;

	set_code_size( &info, 0 );
	this->is_data_fixed = true;
	update_flags( &info, p_last_line );
	if( words.size() == 1 ) {
		put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::TOO_MANY_PARAMETERS ) );
		return false;
	}
	if( this->expression( info, 1, v, false ) == 0 ) {
		put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_PARAMETER ) );
		return false;
	}
	else if( v.is_unknown() ){
		put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_PARAMETER ) );
		return false;
	}
	if( v.is_integer() ) {
		v.s = std::to_string( v.i );
	}
	//	log
	if( !this->is_analyze_phase ) {
		put_message( v.s );
	}
	return true;
}
