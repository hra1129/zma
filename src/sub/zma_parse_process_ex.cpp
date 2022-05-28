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
				put_error( "Illegal operand" );
				return false;
			}
		}
		else {
			this->is_data_fixed = false;
			put_error( "Illegal operand" );
			return false;
		}
	}
	//	log
	if( !this->is_analyze_phase ) {
		if( words.size() == 6 ) {
			if( words[5] == "HL" ) {
				log.push_back( "[\t" + get_line() + "] Z80:20cyc, R800:7cyc" );
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:25cyc, R800:8cyc" );
			}
		}
		else {
			log.push_back( "[\t" + get_line() + "] Z80:5cyc, R800:1cyc" );
		}
		this->log_data_dump();
		log.push_back( "" );
	}
	return check_all_fixed();
}

