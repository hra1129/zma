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
bool CZMA_PARSE_DEFB::process( CZMA_INFORMATION &info, CZMA_PARSE *p_last_line ){
	int i, count;
	CVALUE v;

	update_flags( &info, p_last_line );
	if( !this->is_fixed_code_size() ){
		count = 0;
		i = 1;
		for( ;; ){
			i = this->expression( info, i, v );
			if( v.is_integer() ){
				//	数値の場合は、値の確定の有無にかかわらず 1byte
				count++;
			}
			else if( v.is_string() ){
				if( v.is_unknown() ){
					//	文字列の場合は、値が確定していないとサイズが不明
					count = -1;
					break;
				}
				//	文字列の場合は、値が確定していると文字長がそのままサイズ
				count += v.s.size();
			}
			else{
				//	型もわからない場合は、サイズが不明
				count = -1;
				break;
			}
			if( i >= (int)words.size() ){
				break;
			}
			if( words[ i ] != "," ){
				put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_PARAMETER ) );
				count = -1;
				break;
			}
			i++;
		}
		if( count >= 0 ){
			this->set_code_size( &info, count );
		}
	}
	if( !this->is_data_fixed ){
		i = 1;
		for( ;; ){
			i = this->expression( info, i, v );
			if( i == 0 ){
				put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::CANNOT_EVALUATE_THE_EXPRESSION ) );
				data.clear();
				return false;
			}
			if( i < (int)words.size() && words[ i ] != "," ){
				put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_EXPRESSION ) );
				data.clear();
				return false;
			}
			i++;
			if( v.is_unknown() ){
				put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_EXPRESSION ) );
				data.clear();
				return false;
			}
			else if( v.is_integer() ) {
				data.push_back( v.i & 255 );
			}
			else {
				//	v.is_string()
				for( char &c : v.s ){
					data.push_back( (unsigned char) c );
				}
			}
			if( i >= (int)words.size() ){
				break;
			}
		}
		this->is_data_fixed = true;
	}
	//	log
	if( !this->is_analyze_phase ){
		log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
		log.write_dump( this->code_address, this->file_address, this->data );
		log.write_separator();
	}
	return check_all_fixed();
}

