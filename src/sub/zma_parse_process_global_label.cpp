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
bool CZMA_PARSE_GLOBAL_LABEL::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {
	std::string label;
	CVALUE v;

	update_flags( &info, p_last_line );
	//	log
	if( !this->is_analyze_phase ) {
		log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
		std::stringstream s;
		s << "0x" << std::hex << std::setw( 6 ) << std::setfill( '0' ) << this->get_code_address();
		log.push_back( "[" + get_line() + "]" );
		log.push_back( "\tglobal label address: " + s.str() );
		log.write_separator();
	}
	if( this->is_data_fixed ) {
		return check_all_fixed();
	}
	this->set_code_size( &info, 0 );
	if( words[0][0] == '\"' ) {
		put_error( "Label name cannot be string." );
		return false;
	}
	if( this->get_fixed_code_address() ) {
		label = words[0];
		if( info.dict.count( label ) ) {
			put_error( std::string( "There are declarations of the same label '" ) + label + "' in multiple places." );
			return false;
		}
		else {
			this->is_data_fixed = true;
			v.value_type = CVALUE_TYPE::CV_INTEGER;
			v.i = this->get_code_address();
			info.dict[label] = v;
			info.is_updated = true;
		}
	}
	else {
		put_error( std::string( "Label '" ) + words[0] + "' is indeterminate." );
		return false;
	}
	return check_all_fixed();
}

