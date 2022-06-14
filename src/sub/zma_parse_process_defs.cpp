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
bool CZMA_PARSE_DEFS::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {
	CVALUE v;
	int index;

	update_flags( &info, p_last_line );
	index = this->expression( info, 1, v );
	if( index == 0 ) {
		put_error( "Illegal expression." );
		return false;
	}
	if( index < ( int) words.size() ) {
		put_error( "Illegal parameter." );
		return false;
	}
	if( v.is_unknown() ){
		put_error( "Illegal parameter." );
		return false;
	}
	if( v.is_integer() ) {
		v.value_type = CVALUE_TYPE::CV_STRING;
		v.s = std::to_string( v.i );
	}
	this->set_code_size( &info, (unsigned int)v.s.size() );
	if( !this->is_data_fixed ) {
		for( auto c : v.s ) {
			data.push_back( c );
		}
		this->is_data_fixed = true;
	}
	//	log
	if( !this->is_analyze_phase ) {
		log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
		log.write_dump( this->code_address, this->file_address, this->data );
		log.write_separator();
	}
	return check_all_fixed();
}

