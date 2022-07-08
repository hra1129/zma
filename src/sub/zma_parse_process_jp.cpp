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
bool CZMA_PARSE_JP::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( (words.size() == 2 && words[1] == "HL") || (words.size() == 4 && words[1] == "(" && words[2] == "HL" && words[3] == ")") ) {
		if( !this->is_data_fixed ) {
			this->set_code_size( &info, 1 );
			this->is_data_fixed = true;
			this->data.push_back( 0xE9 );
		}
		//	log
		if( !this->is_analyze_phase ) {
			log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
			log.write_cycle_information( 5, 3 );		//	JP HL
			log.write_dump( this->code_address, this->file_address, this->data );
			log.write_separator();
		}
		return check_all_fixed();
	}
	if( (words.size() == 2 && words[1] == "IX") || (words.size() == 4 && words[1] == "(" && words[2] == "IX" && words[3] == ")") ) {
		if( !this->is_data_fixed ) {
			this->set_code_size( &info, 2 );
			this->is_data_fixed = true;
			this->data.push_back( 0xDD );
			this->data.push_back( 0xE9 );
		}
		//	log
		if( !this->is_analyze_phase ) {
			log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
			log.write_cycle_information( 10, 4 );		//	JP IX
			log.write_dump( this->code_address, this->file_address, this->data );
			log.write_separator();
		}
		return check_all_fixed();
	}
	if( (words.size() == 2 && words[1] == "IY") || (words.size() == 4 && words[1] == "(" && words[2] == "IY" && words[3] == ")") ) {
		if( !this->is_data_fixed ) {
			this->set_code_size( &info, 2 );
			this->is_data_fixed = true;
			this->data.push_back( 0xFD );
			this->data.push_back( 0xE9 );
		}
		//	log
		if( !this->is_analyze_phase ) {
			log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
			log.write_cycle_information( 10, 4 );	//	JP IY
			log.write_dump( this->code_address, this->file_address, this->data );
			log.write_separator();
		}
		return check_all_fixed();
	}
	if( opecode_condition_address( info, 0xC3, 0xC2 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
			if( data[0] == 0xC3 ) {
				log.write_cycle_information( 11, 5 );		//	JP nn
			}
			else {
				log.write_cycle_information( 11, 5, -1, 3 );		//	JP cond, nn
			}
			log.write_dump( this->code_address, this->file_address, this->data );
			log.write_separator();
		}
		return check_all_fixed();
	}
	put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_OPERAND ), info.all_error_enable, info.error_disable );
	info.error_disable = true;
	return false;
}

