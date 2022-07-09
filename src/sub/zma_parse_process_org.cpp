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

#include "zma_parse_process_org.hpp"

// --------------------------------------------------------------------
bool CZMA_PARSE_ORG::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {
	CVALUE address;
	int index;

	update_flags( &info, p_last_line );
	index = this->expression( info, 1, address );
	this->code_size = 0;
	if( index == 0 ) {
		put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_EXPRESSION ) );
		return false;
	}
	if( address.value_type != CVALUE_TYPE::CV_INTEGER ) {
		put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_PARAMETER ) );
		return false;
	}
	if( index < (int)words.size() ) {
		put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_PARAMETER ) );
		return false;
	}
	this->is_data_fixed = true;
	this->code_address = address.i;
	this->next_code_address = address.i;
	//	log
	if( !this->is_analyze_phase ) {
		log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
		log.write_separator();
	}
	return check_all_fixed();
}

