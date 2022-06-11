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
bool CZMA_PARSE_CHG_CHAR_SET::process( CZMA_INFORMATION &info, CZMA_PARSE *p_last_line ){
	CVALUE v;
	int index, i;

	this->set_code_size( &info, 0 );
	update_flags( &info, p_last_line );
	index = this->expression( info, 1, v, false );
	if( index == 0 ){
		put_error( "Illegal expression." );
		return false;
	}
	if( index < (int)words.size() ){
		put_error( "Illegal parameter." );
		return false;
	}
	if( v.value_type == CVALUE_TYPE::CV_INTEGER ){
		v.value_type = CVALUE_TYPE::CV_STRING;
		v.s = std::to_string( v.i );
	}

	std::transform( v.s.begin(), v.s.end(), v.s.begin(), toupper );

	//	存在確認
	info.s_char_set = v.s;
	if( info.char_set_list.count( v.s ) ){
		//	すでに存在する場合、切り替えるだけ
		info.p_char_set = &( info.char_set_list[ v.s ] );
	}
	else{
		//	存在しない場合、新たに作る
		CZMA_CHAR_SET char_set;
		for( i = 0; i < 256; i++ ){
			char_set.ascii_to_map.push_back( (unsigned char)i );
		}
		info.char_set_list[ v.s ] = char_set;
		info.p_char_set = &( info.char_set_list[ v.s ] );
	}
	if( !this->is_analyze_phase ){
		log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
		log.write_separator();
	}
	return true;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_MAPPING_CHAR::process( CZMA_INFORMATION &info, CZMA_PARSE *p_last_line ){
	CVALUE v;
	int index, start_char_ascii, end_char_ascii, start_char_map, step_char_map, di, code;

	this->set_code_size( &info, 0 );
	update_flags( &info, p_last_line );
	if( info.p_char_set == nullptr ){
		//	デフォルトキャラセットはマッピング変更できない
		put_error( "Default character sets cannot be mapped and changed." );
		return false;
	}
	//	第1引数
	index = this->expression( info, 1, v );
	if( index == 0 || v.value_type != CVALUE_TYPE::CV_INTEGER ){
		put_error( "Illegal expression." );
		return false;
	}
	start_char_ascii = v.i;
	end_char_ascii = v.i;
	//	カンマ
	if( index == (int)words.size() || words[index] != "," ){
		put_error( "Illegal expression." );
		return false;
	}
	//	第2引数
	index = this->expression( info, index + 1, v );
	if( index == 0 || v.value_type != CVALUE_TYPE::CV_INTEGER ){
		put_error( "Illegal expression." );
		return false;
	}
	start_char_map = v.i;
	step_char_map = 1;
	//	カンマ (※省略可能)
	if( index != (int)words.size() && words[ index ] == "," ){
		//	第3引数
		index = this->expression( info, index + 1, v );
		if( index == 0 || v.value_type != CVALUE_TYPE::CV_INTEGER ){
			put_error( "Illegal expression." );
			return false;
		}
		end_char_ascii = v.i;
	}
	//	カンマ (※省略可能)
	if( index != (int)words.size() && words[ index ] == "," ){
		//	第4引数
		index = this->expression( info, index + 1, v );
		if( index == 0 || v.value_type != CVALUE_TYPE::CV_INTEGER ){
			put_error( "Illegal expression." );
			return false;
		}
		step_char_map = v.i;
	}
	//	変換テーブルを更新
	if( start_char_ascii <= end_char_ascii ){
		di = 1;
	}
	else{
		di = -1;
	}
	index = start_char_ascii & 255;
	code = start_char_map & 255;
	for( ;; ){
		info.p_char_set->ascii_to_map[ index ] = code;
		if( index == end_char_ascii ){
			break;
		}
		index = ( index + di ) & 255;
		code = ( code + step_char_map ) & 255;
	}
	return false;
}
