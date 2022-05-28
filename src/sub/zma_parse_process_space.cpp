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
			//	サイズ
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
			if( v.i < 0 || v.i > 65536 ){
				put_error( "Invalid parameter." );
				return false;
			}
			space_size = v.i;
			//	, があるか？
			if( i < (int)this->words.size() && this->words[ i ] == "," ){
				i = this->expression( info, i + 1, v );
				if( i == 0 ){
					put_error( std::string( "Cannot evaluate the expression" ) );
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
		log.push_back( "[" + get_line() + "]" );
		if( this->get_code_size() ){
			log.push_back( "\tAllocate space: " + std::to_string( this->get_code_size() ) + "byte(s)" );
			log.push_back( "\t\tFill value: " + std::to_string( this->data[0] ) );
		}
		else{
			log.push_back( "\tNo space was allocated." );
		}
		log.push_back( "" );
	}
	return check_all_fixed();
}

