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
bool CZMA_PARSE_BIT::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( this->opecode_n_sss( info, 0x40, true ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( data.size() == 2 && (data[1] & 0x07) != 0x06 ) {
				log.push_back( "[\t" + get_line() + "] Z80:10cyc, R800:2cyc" );	//	BIT b,r
			}
			else if( data.size() == 2 ) {
				log.push_back( "[\t" + get_line() + "] Z80:14cyc, R800:5cyc" );	//	BIT b,[HL]
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:22cyc, R800:7cyc" );	//	BIT b,[IX+o]
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

