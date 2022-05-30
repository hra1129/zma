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
bool CZMA_PARSE_ALIGN::process( CZMA_INFORMATION &info, CZMA_PARSE *p_last_line ) {
	int i, address, padding_size, block_size;
	CVALUE v;

	update_flags( &info, p_last_line );
	if( !this->is_data_fixed ){
		if( this->get_fixed_code_address() ){
			i = this->expression( info, 1, v );
			if( i == 0 ){
				put_error( std::string( "Cannot evaluate the expression" ) );
				data.clear();
				return false;
			}
			if( v.value_type != CVALUE_TYPE::CV_INTEGER ){
				put_error( "Illegal expression." );
				return false;
			}
			if( v.i < 1 ){
				put_error( "Illegal parameter." );
				return false;
			}
			//	パディングの量を計算する
			block_size = v.i;
			address = this->get_code_address();
			padding_size = ( block_size - ( address % block_size ) ) % block_size;
			//	パディングする
			this->set_code_size( &info, padding_size );
			for( i = 0; i < padding_size; i++ ){
				this->data.push_back( 0 );
			}
			this->is_data_fixed = true;
			info.is_updated = true;
		}
	}

	if( !is_analyze_phase ){
		log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
		log.push_back( "\tPadding: " + std::to_string( this->get_code_size() ) + "byte(s)" );
		log.write_separator();
	}
	return check_all_fixed();
}
