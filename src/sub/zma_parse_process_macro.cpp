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
bool CZMA_PARSE_MACRO::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {
	std::string label;
	CZMA_MACRO* p_macro;
	CZMA_MACRO_ARG arg;
	int i;

	bool result = update_flags( &info, p_last_line );
	if( !this->is_data_fixed ) {
		if( info.macro_list.count( words[0] ) && info.macro_list[words[0]] != nullptr ) {
			//	同じ名前のマクロを宣言することはできない
			put_error( std::string( "There are declarations of the same macro '" ) + words[0] + "' in multiple places." );
			return false;
		}
		//	引数抽出処理
		p_macro = new CZMA_MACRO;
		for( i = 2; i < ( int) words.size(); ) {
			if( words[i] == "@" ) {
				arg.is_through = true;
				i++;
			}
			else {
				arg.is_through = false;
			}
			if( i >= (int)words.size() ) {
				put_error( "Illegal argument." );
				return false;
			}
			arg.name = words[i];
			if( (i + 1) < (int)words.size() && words[ i + 1 ] != "," ) {
				put_error( "Illegal argument." );
				return false;
			}
			for( auto s : p_macro->parameter_name_list ) {
				if( s.name == words[i] ) {
					put_error( std::string( "Multiple arguments of the same name '" + words[i] + "' exist." ) );
					return false;
				}
			}
			i = i + 2;
			p_macro->parameter_name_list.push_back( arg );
		}
		info.block_type = info.CZMA_INFO_MACRO_BLOCK;
		info.is_block_processing = true;
		info.p_macro = p_macro;
		info.p_text = &(info.p_macro->m_text);
		this->is_data_fixed = true;
		this->set_code_size( &info, 0 );
		info.macro_list[words[0]] = p_macro;
	}
	//	log
	if( !is_analyze_phase ) {
		log.push_back( "Define macro {" + get_line() + "}" );
		log.push_back( "" );
	}
	return result;
}

