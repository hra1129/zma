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

#include "zma_parse_process_ex.hpp"

// --------------------------------------------------------------------
bool CZMA_PARSE_EX::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( !this->is_data_fixed ) {
		this->is_data_fixed = true;
		if( words.size() == 4 && words[1] == "DE" && words[2] == "," && words[3] == "HL" ) {
			this->set_code_size( &info, 1 );
			this->data.push_back( 0xEB );
		}
		else if( words.size() == 4 && words[1] == "AF" && words[2] == "," && words[3] == "AF'" ) {
			this->set_code_size( &info, 1 );
			this->data.push_back( 0x08 );
		}
		else if( words.size() == 6 && words[1] == "[" && words[2] == "SP" && words[3] == "]" && words[4] == "," ) {
			if( words[5] == "HL" ) {
				this->set_code_size( &info, 1 );
				this->data.push_back( 0xE3 );
			}
			else if( words[5] == "IX" ) {
				this->set_code_size( &info, 2 );
				this->data.push_back( 0xDD );
				this->data.push_back( 0xE3 );
			}
			else if( words[5] == "IY" ) {
				this->set_code_size( &info, 2 );
				this->data.push_back( 0xFD );
				this->data.push_back( 0xE3 );
			}
			else {
				this->is_data_fixed = false;
				put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_OPERAND ) );
				return false;
			}
		}
		else {
			this->is_data_fixed = false;
			put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_OPERAND ) );
			return false;
		}
	}
	//	log
	if( !this->is_analyze_phase ) {
		log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
		if( words.size() == 6 ) {
			if( words[5] == "HL" ) {
				log.write_cycle_information( 20, 7 );			//	EX (SP), HL
			}
			else {
				log.write_cycle_information( 25, 8 );			//	EX (SP), IX
			}
		}
		else {
			log.write_cycle_information( 5, 1 );			//	EX DE, HL/ EX AF, AF'
		}
		log.write_dump( this->code_address, this->file_address, this->data );
		log.write_separator();
	}
	return check_all_fixed();
}

