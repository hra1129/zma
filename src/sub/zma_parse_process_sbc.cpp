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
bool CZMA_PARSE_SBC::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( this->opecode_a_sss( info, 0x98 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( data.size() == 2 ) {
				log.push_back( "[\t" + get_line() + "] Z80:10cyc, R800:2cyc" );	//	SBC A, IXh
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:5cyc, R800:1cyc" );	//	SBC A, r
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	if( this->opecode_a_ref_hl( info, 0x9E ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( words[4] == "HL" ) {
				log.push_back( "[\t" + get_line() + "] Z80:8cyc, R800:4cyc" );	//	SBC A, [HL]
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:21cyc, R800:7cyc" );	//	SBC A, [IX+o]
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	if( this->opecode_a_n( info, 0xDE ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:8cyc, R800:2cyc" );	//	SBC A, n
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	if( this->opecode_hl_rp_witnout_ix( info, 0xED, 0x42 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:17cyc, R800:2cyc" );	//	SBC HL, rr
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

