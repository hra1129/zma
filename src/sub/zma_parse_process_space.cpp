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
bool CZMA_PARSE_SPACE::process( CZMA_INFORMATION &info, CZMA_PARSE *p_last_line ){
	int i, space_size, value;
	CVALUE v;

	update_flags( &info, p_last_line );
	if( !this->is_data_fixed ){
		if( !this->is_fixed_code_size() ){
			//	サイズ
			i = this->expression( info, 1, v );
			if( i == 0 ){
				put_error( "Illegal expression." );
				data.clear();
				return false;
			}
			if( v.value_type != CVALUE_TYPE::CV_INTEGER ){
				put_error( "Illegal expression." );
				return false;
			}
			if( v.i < 0 || v.i > 65536 ){
				put_error( "Illegal parameter." );
				return false;
			}
			space_size = v.i;
			//	, があるか？
			if( i < (int)this->words.size() && this->words[ i ] == "," ){
				i = this->expression( info, i + 1, v );
				if( i == 0 ){
					put_error( "Illegal expression." );
					data.clear();
					return false;
				}
				if( v.value_type != CVALUE_TYPE::CV_INTEGER ){
					put_error( "Illegal expression." );
					return false;
				}
				if( v.i < 0 || v.i > 65536 ){
					put_error( "Illegal parameter." );
					return false;
				}
				value = v.i;
			}
			else{
				value = 0;
			}
			//	スペースを確保する
			this->set_code_size( &info, space_size );
			for( i = 0; i < space_size; i++ ){
				this->data.push_back( value );
			}
			this->is_data_fixed = true;
			info.is_updated = true;
		}
	}

	if( !is_analyze_phase ){
		log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
		if( this->get_code_size() ){
			std::stringstream ss;
			log.write_message( "Allocate space: " + std::to_string( this->get_code_size() ) + "byte(s)" );
			ss << "Fill value    : " << (int)this->data[ 0 ] << "(0x" << std::setw(2) << std::setfill('0') << std::hex << (int)this->data[0] << ")";
			log.write_message( ss.str() );
		}
		else{
			log.write_message( "No space was allocated." );
		}
		log.write_dump( this->code_address, this->file_address, this->data );
		log.write_separator();
	}
	return check_all_fixed();
}

