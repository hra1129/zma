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
			log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
			log.write_cycle_information( 11, 2 );			//	ld	{A|I|R}, {A|I|R}
		}
	}
	else if( opecode_ddd_sss( info, 0x40 ) ) {				//	ld <reg8>, <reg8> line
		//	log
		if( !is_analyze_phase ) {
			log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
			if( this->code_size == 1 ) {
				log.write_cycle_information( 5, 2 );			//	ld <reg8>, reg8>
			}
			else {
				log.write_cycle_information( 10, 2 );			//	ld <reg8>, ixh
			}
		}
	}
	else if( opecode_ddd_ref_hl( info, 0x46 ) ) {				//	ld <reg8>, [HL] line
		//	log
		if( !is_analyze_phase ) {
			log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
			if( this->code_size == 1 ) {
				log.write_cycle_information( 8, 4 );			//	ld	<reg8>, [hl]
			}
			else {
				log.write_cycle_information( 21, 7 );			//	ld	<reg8>, [ix+d]
			}
		}
	}
	else if( opecode_a_ref_bc( info, 0x0A ) ) {				//	ld a, [bc/de/nn] line
		//	log
		if( !is_analyze_phase ) {
			log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
			if( this->code_size == 1 ) {
				log.write_cycle_information( 8, 4 );			//	ld	<reg8>, [bc/de]
			}
			else {
				log.write_cycle_information( 14, 6 );			//	ld	a, [nn]
			}
		}
	}
	else if( opecode_ddd_n( info, 0x06 ) ) {					//	ld <reg8>, imm8 line
		//	log
		if( !is_analyze_phase ) {
			log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
			if( this->code_size == 2 ) {
				log.write_cycle_information( 8, 2 );			//	ld	<reg8>, imm8
			}
			else {
				log.write_cycle_information( 13, 3 );			//	ld	ixh, imm8
			}
		}
	}
	else if( opecode_sp_hl( info, 0xF9 ) ) {					//	ld sp, hl/ix/iy line
		//	log
		if( !is_analyze_phase ) {
			log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
			if( this->code_size == 1 ) {
				log.write_cycle_information( 7, 1 );			//	ld	sp, hl
			}
			else {
				log.write_cycle_information( 12, 2 );			//	ld	sp, ix
			}
		}
	}
	else if( opecode_rp_nn( info, 0x01 ) ) {					//	ld <reg16>, imm16 line
		//	log
		if( !is_analyze_phase ) {
			log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
			if( this->code_size == 3 ) {
				log.write_cycle_information( 11, 3 );			//	ld	<reg16>, imm16
			}
			else {
				log.write_cycle_information( 16, 4 );			//	ld	ix, imm16
			}
		}
	}
	else if( opecode_rp_ref_nn( info, 0x2A, 0x4B ) ) {		//	ld <reg16>, [nn] line
		//	log
		if( !is_analyze_phase ) {
			log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
			if( this->code_size == 3 ) {
				log.write_cycle_information( 17, 7 );			//	ld	hl, [nn]
			}
			else {
				log.write_cycle_information( 22, 8 );			//	ld	de/bc/sp/ix/iy, [nn]
			}
		}
	}
	else if( opecode_ref_hl_sss( info, 0x70 ) ) {			//	ld [HL], <reg8> line
		//	log
		if( !is_analyze_phase ) {
			log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
			log.write_cycle_information( 8, 4 );			//	ld [HL], <reg8>
		}
	}
	else if( opecode_ref_hl_n( info, 0x36 ) ) {				//	ld [HL], imm8 line
		//	log
		if( !is_analyze_phase ) {
			log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
			if( this->code_size == 2 ) {
				log.write_cycle_information( 11, 5 );			//	ld [HL], imm8
			}
			else {
				log.write_cycle_information( 21, 7 );			//	ld [IX+d], imm8
			}
		}
	}
	else if( opecode_ref_bc_a( info, 0x02 ) ) {				//	ld [bc/de/nn], a line
		//	log
		if( !is_analyze_phase ) {
			log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
			if( this->code_size == 1 ) {
				log.write_cycle_information( 8, 4 );			//	ld [bc/de], a
			}
			else {
				log.write_cycle_information( 14, 6 );			//	ld [nn], a
			}
		}
	}
	else if( opecode_ref_nn_rp( info, 0xED, 0x22, 0x43 ) ) {	//	ld [nn], <reg16> line
		//	log
		if( !is_analyze_phase ) {
			log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
			if( this->code_size == 3 ) {
				log.write_cycle_information( 17, 7 );			//	ld [nn],hl
			}
			else {
				log.write_cycle_information( 22, 8 );			//	ld [nn],bc/de/sp/ix/iy
			}
		}
	}
	else {
		put_error( "Illegal operand." );
		return false;
	}
	//	log
	if( !is_analyze_phase ) {
		log.write_dump( this->code_address, this->file_address, this->data );
		log.write_separator();
	}
	return check_all_fixed();
}

