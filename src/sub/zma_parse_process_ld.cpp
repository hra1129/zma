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
bool CZMA_PARSE_LD::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( opecode_a_i_r( info ) ) {						//	ld {A|I|R}, {A|I|R} line
		//	log
		if( !is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:11cyc, R800:2cyc" );			//	ld	{A|I|R}, {A|I|R}
		}
	}
	else if( opecode_ddd_sss( info, 0x40 ) ) {				//	ld <reg8>, <reg8> line
		//	log
		if( !is_analyze_phase ) {
			if( this->code_size == 1 ) {
				log.push_back( "[\t" + get_line() + "] Z80:5cyc, R800:2cyc" );		//	ld <reg8>, reg8>
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:10cyc, R800:2cyc" );		//	ld <reg8>, ixh
			}
		}
	}
	else if( opecode_ddd_ref_hl( info, 0x46 ) ) {			//	ld <reg8>, [HL] line
		//	log
		if( !is_analyze_phase ) {
			if( this->code_size == 1 ) {
				log.push_back( "[\t" + get_line() + "] Z80:8cyc, R800:4cyc" );		//	ld	<reg8>, [hl]
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:21cyc, R800:7cyc" );		//	ld	<reg8>, [ix+d]
			}
		}
	}
	else if( opecode_a_ref_bc( info, 0x0A ) ) {				//	ld a, [bc/de/nn] line
		//	log
		if( !is_analyze_phase ) {
			if( this->code_size == 1 ) {
				log.push_back( "[\t" + get_line() + "] Z80:8cyc, R800:4cyc" );		//	ld	a, [bc/de]
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:14cyc, R800:6cyc" );		//	ld	a, [nn]
			}
		}
	}
	else if( opecode_ddd_n( info, 0x06 ) ) {					//	ld <reg8>, imm8 line
		//	log
		if( !is_analyze_phase ) {
			if( this->code_size == 2 ) {
				log.push_back( "[\t" + get_line() + "] Z80:8cyc, R800:2cyc" );		//	ld	<reg8>, imm8
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:13cyc, R800:3cyc" );		//	ld	ixh, imm8
			}
		}
	}
	else if( opecode_sp_hl( info, 0xF9 ) ) {					//	ld sp, hl/ix/iy line
		//	log
		if( !is_analyze_phase ) {
			if( this->code_size == 1 ) {
				log.push_back( "[\t" + get_line() + "] Z80:7cyc, R800:1cyc" );		//	ld	sp, hl
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:12cyc, R800:2cyc" );		//	ld	sp, ix
			}
		}
	}
	else if( opecode_rp_nn( info, 0x01 ) ) {					//	ld <reg16>, imm16 line
		//	log
		if( !is_analyze_phase ) {
			if( this->code_size == 3 ) {
				log.push_back( "[\t" + get_line() + "] Z80:11cyc, R800:3cyc" );		//	ld	<reg16>, imm16
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:16cyc, R800:4cyc" );		//	ld	ix, imm16
			}
		}
	}
	else if( opecode_rp_ref_nn( info, 0x2A, 0x4B ) ) {		//	ld <reg16>, [nn] line
		//	log
		if( !is_analyze_phase ) {
			if( this->code_size == 3 ) {
				log.push_back( "[\t" + get_line() + "] Z80:17cyc, R800:7cyc" );		//	ld	hl, [nn]
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:22cyc, R800:8cyc" );		//	ld	de/bc/sp/ix/iy, [nn]
			}
		}
	}
	else if( opecode_ref_hl_sss( info, 0x70 ) ) {			//	ld [HL], <reg8> line
		//	log
		if( !is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:8cyc, R800:4cyc" );			//	ld [HL], <reg8>
		}
	}
	else if( opecode_ref_hl_n( info, 0x36 ) ) {				//	ld [HL], imm8 line
		//	log
		if( !is_analyze_phase ) {
			if( this->code_size == 2 ) {
				log.push_back( "[\t" + get_line() + "] Z80:11cyc, R800:5cyc" );		//	ld [HL], imm8
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:21cyc, R800:7cyc" );		//	ld [IX+d], imm8
			}
		}
	}
	else if( opecode_ref_bc_a( info, 0x02 ) ) {				//	ld [bc/de/nn], a line
		//	log
		if( !is_analyze_phase ) {
			if( this->code_size == 1 ) {
				log.push_back( "[\t" + get_line() + "] Z80:8cyc, R800:4cyc" );		//	ld [bc/de], a
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:14cyc, R800:6cyc" );		//	ld [nn], a
			}
		}
	}
	else if( opecode_ref_nn_rp( info, 0xED, 0x22, 0x43 ) ) {	//	ld [nn], <reg16> line
		//	log
		if( !is_analyze_phase ) {
			if( this->code_size == 3 ) {
				log.push_back( "[\t" + get_line() + "] Z80:17cyc, R800:7cyc" );		//	ld [nn],hl
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:22cyc, R800:8cyc" );		//	ld [nn],bc/de/sp/ix/iy
			}
		}
	}
	else {
		put_error( "Illegal operand." );
		return false;
	}
	//	log
	if( !is_analyze_phase ) {
		log_data_dump();
		log.push_back( "" );
	}
	return check_all_fixed();
}

