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
bool CZMA_PARSE_RR::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( this->opecode_sss( info, 0xCB, 0x18 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
			if( data.size() == 2 ) {
				if( this->data[1] == 0x1E ) {
					log.push_back( "[\t" + get_line() + "] Z80:17cyc, R800:8cyc" );			//	RR [HL]
				}
				else {
					log.push_back( "[\t" + get_line() + "] Z80:10cyc, R800:2cyc" );			//	RR r
				}
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:25cyc, R800:10cyc" );			//	RR [IX+d]
			}
			log.write_dump( this->code_address, this->file_address, this->data );
			log.write_separator();
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

