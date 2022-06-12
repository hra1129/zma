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
bool CZMA_PARSE_GLOBAL_SYMBOL::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {
	std::string label;
	CVALUE v;

	this->set_code_size( &info, 0 );
	update_flags( &info, p_last_line );
	//	log
	label = info.get_scope_path() + words[ 0 ];
	if( !this->is_analyze_phase ){
		std::stringstream s;
		log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
		if( this->get_code_address() == -1 ){
			s << "global label address: 0xXXXXXX";
		}
		else{
			s << "global label [" << label << "] address: 0x" << std::hex << std::setw( 6 ) << std::setfill( '0' ) << this->get_code_address();
		}
		log.write_message( s.str() );
		log.write_separator();
	}
	if( this->is_data_fixed ) {
		if( check_all_fixed() && info.dict.count( label ) ){
			return true;
		}
	}
	if( words[ 0 ][ 0 ] == '\"' ){
		put_error( "Label name cannot be string." );
		return false;
	}



	this->set_code_size( &info, 0 );
	if( this->expression( info, 2, v ) ) {
		if( v.value_type != CVALUE_TYPE::CV_INTEGER ) {
			put_error( "Illegal expression." );
			return false;
		}
		label = words[0];
		if( info.dict.count( label ) ) {
			put_error( std::string( "There are declarations of the same label '" ) + label + "' in multiple places." );
			return false;
		}
		else {
			this->is_data_fixed = true;
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

