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
	if( opecode_ccc_nnn( info, 0xC3, 0xC2 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
			if( data[0] == 0xC3 ) {
				log.push_back( "[\t" + get_line() + "] Z80:11cyc, R800:5cyc" );	//	JP nn
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:11cyc, R800:5cyc(cond=true), 3cyc(cond=false)" );	//	JP cond, nn
			}
			log.write_dump( this->code_address, this->file_address, this->data );
			log.write_separator();
		}
		return check_all_fixed();
	}
	if( words.size() == 2 && words[1] == "HL" ) {
		if( !this->is_data_fixed ) {
			this->set_code_size( &info, 1 );
			this->is_data_fixed = true;
			this->data.push_back( 0xE9 );
		}
		//	log
		if( !this->is_analyze_phase ) {
			log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
			log.push_back( "[\t" + get_line() + "] Z80:5cyc, R800:3cyc" );	//	JP HL
			log.write_dump( this->code_address, this->file_address, this->data );
			log.write_separator();
		}
		return check_all_fixed();
	}
	if( words.size() == 2 && words[1] == "IX" ) {
		if( !this->is_data_fixed ) {
			this->set_code_size( &info, 2 );
			this->is_data_fixed = true;
			this->data.push_back( 0xDD );
			this->data.push_back( 0xE9 );
		}
		//	log
		if( !this->is_analyze_phase ) {
			log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
			log.push_back( "[\t" + get_line() + "] Z80:10cyc, R800:4cyc" );	//	JP IX
			log.write_dump( this->code_address, this->file_address, this->data );
			log.write_separator();
		}
		return check_all_fixed();
	}
	if( words.size() == 2 && words[1] == "IY" ) {
		if( !this->is_data_fixed ) {
			this->set_code_size( &info, 2 );
			this->is_data_fixed = true;
			this->data.push_back( 0xFD );
			this->data.push_back( 0xE9 );
		}
		//	log
		if( !this->is_analyze_phase ) {
			log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
			log.push_back( "[\t" + get_line() + "] Z80:10cyc, R800:4cyc" );	//	JP IY
			log.write_dump( this->code_address, this->file_address, this->data );
			log.write_separator();
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

