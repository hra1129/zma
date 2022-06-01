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
bool CZMA_PARSE_IN::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( opecode_ddd_c( info, 0xDB, 0xED, 0x40 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
			if( data[0] == 0xDB ) {
				log.write_cycle_information( 12, 10, -1, 9 );	//	IN A, [n]
				log.push_back( "[\t" + get_line() + "] Z80:12cyc, R800:10 or 9cyc" );
			}
			else {
				log.write_cycle_information( 14, 10, -1, 9 );	//	IN A, [C]
				log.push_back( "[\t" + get_line() + "] Z80:14cyc, R800:10 or 9cyc" );
			}
			log.write_dump( this->code_address, this->file_address, this->data );
			log.write_separator();
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

