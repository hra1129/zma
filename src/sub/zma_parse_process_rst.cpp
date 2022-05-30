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
bool CZMA_PARSE_RST::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {
	CVALUE p;
	int index;
	update_flags( &info, p_last_line );
	if( words.size() >= 2 ) {
		index = this->expression( info, 1, p );
		if( index == 0 ) {
			put_error( "Illegal expression." );
			return false;
		}
		if( p.value_type != CVALUE_TYPE::CV_INTEGER ) {
			put_error( "Illegal expression." );
			return false;
		}
		if( index < (int)words.size() ) {
			put_error( "Illegal operand." );
			return false;
		}
		if( (p.i & ~0x38) != 0 ) {
			put_error( std::string("Illegal restart address (") + std::to_string(p.i) + ")" );
			return false;
		}
		if( !this->is_data_fixed ) {
			this->is_data_fixed = true;
			this->set_code_size( &info, 1 );
			this->data.push_back( 0xC7 | p.i );
		}
		//	log
		if( !this->is_analyze_phase ) {
			log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
			log.push_back( "[\t" + get_line() + "] Z80:12cyc, R800:6 or 7cyc" );
			log.write_dump( this->code_address, this->file_address, this->data );
			log.write_separator();
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

