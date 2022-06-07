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
		if( !this->get_fixed_code_size() ){
			//	�T�C�Y
			i = this->expression( info, 1, v );
			if( i == 0 ){
				put_error( "Cannot evaluate the expression" );
				data.clear();
				return false;
			}
			if( v.value_type != CVALUE_TYPE::CV_INTEGER ){
				put_error( "Illegal expression." );
				return false;
			}
			if( v.i < 0 || v.i > 65536 ){
				put_error( "Invalid parameter." );
				return false;
			}
			space_size = v.i;
			//	, �����邩�H
			if( i < (int)this->words.size() && this->words[ i ] == "," ){
				i = this->expression( info, i + 1, v );
				if( i == 0 ){
					put_error( "Cannot evaluate the expression" );
					data.clear();
					return false;
				}
				if( v.value_type != CVALUE_TYPE::CV_INTEGER ){
					put_error( "Illegal expression." );
					return false;
				}
				if( v.i < 0 || v.i > 65536 ){
					put_error( "Invalid parameter." );
					return false;
				}
				value = v.i;
			}
			else{
				value = 0;
			}
			//	�X�y�[�X���m�ۂ���
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
			log.write_message( "Allocate space: " + std::to_string( this->get_code_size() ) + "byte(s)" );
			log.write_message( "Fill value    : " + std::to_string( this->data[0] ) );
		}
		else{
			log.write_message( "No space was allocated." );
		}
		log.write_separator();
	}
	return check_all_fixed();
}

