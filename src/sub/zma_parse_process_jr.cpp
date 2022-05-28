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
bool CZMA_PARSE_JR::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );

	if( opecode_ccc_e( info, 0x18, 0x20 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( data[0] == 0x18 ) {
				log.push_back( "[\t" + get_line() + "] Z80:13cyc, R800:3cyc" );	//	JR nn
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:13cyc(cond=true), 8cyc(cond=false), R800:3cyc(cond=true), 2cyc(cond=false)" );	//	JR cond, nn
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

