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
bool CZMA_PARSE_ORG::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {
	CVALUE address;
	int index;

	update_flags( &info, p_last_line );
	index = this->expression( info, 1, address );
	this->code_size = 0;
	if( index == 0 ) {
		put_error( "Illegal expression." );
		return false;
	}
	if( address.value_type != CVALUE_TYPE::CV_INTEGER ) {
		put_error( "Illegal parameter." );
		return false;
	}
	if( index < (int)words.size() ) {
		put_error( "Illegal parameter." );
		return false;
	}
	this->is_data_fixed = true;
	this->code_address = address.i;
	this->next_code_address = address.i;
	//	log
	if( !this->is_analyze_phase ) {
		std::stringstream s;
		s << "0x" << std::hex << std::setw( 6 ) << std::setfill( '0' ) << this->get_code_address();
		log.push_back( "[\t" + get_line() + "]" );
		log.push_back( "\tcode address: " + s.str() );
		log.push_back( "" );
	}
	return check_all_fixed();
}

