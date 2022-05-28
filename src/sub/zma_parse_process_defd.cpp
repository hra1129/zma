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
bool CZMA_PARSE_DEFD::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {
	int i, count;
	CVALUE v;

	update_flags( &info, p_last_line );
	if( !this->get_fixed_code_size() ) {
		count = 1;
		for( i = 1; i < ( int) words.size(); i++ ) {
			if( words[i] == "," ) {
				count++;
			}
		}
		this->set_code_size( &info, count * 4 );
	}
	if( !this->is_data_fixed ) {
		i = 1;
		for( count = 0; (count * 4) < this->get_code_size(); count++ ) {
			i = this->expression( info, i, v );
			if( i == 0 ) {
				put_error( std::string( "Cannot evaluate the expression(" ) + std::to_string( count + 1 ) + ")" );
				data.clear();
				return false;
			}
			if( v.value_type != CVALUE_TYPE::CV_INTEGER ) {
				put_error( "Illegal expression." );
				return false;
			}
			if( i < ( int) words.size() && words[i] != "," ) {
				put_error( std::string( "Illegal expression." ) );
				data.clear();
				return false;
			}
			i++;
			data.push_back( v.i & 255 );
			data.push_back( (v.i >> 8) & 255 );
			data.push_back( (v.i >> 16) & 255 );
			data.push_back( (v.i >> 24) & 255 );
		}
		this->is_data_fixed = true;
	}
	//	log
	if( !this->is_analyze_phase ) {
		log.push_back( "[\t" + get_line() + "]" );
		this->log_data_dump();
		log.push_back( "" );
	}
	return check_all_fixed();
}

