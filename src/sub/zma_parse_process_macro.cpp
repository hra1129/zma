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
		log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
		log.push_back( "" );
	}
	return result;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_MACRO_INS::write( CZMA_INFORMATION& info, std::ofstream* f ) {
	bool result = true;

	for( auto line : log ) {
		info.log << line << std::endl;
	}
	text.write( info, f );
	return result;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_ENDM::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	info.is_block_processing = false;
	this->is_data_fixed = true;
	this->set_code_size( &info, 0 );
	return check_all_fixed();
}

// --------------------------------------------------------------------
bool CZMA_PARSE_MACRO_INS::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {
	CZMA_MACRO* p_macro;
	std::map< std::string, std::vector< std::string > > argument;
	std::vector< std::string > parameter, insert_line;
	std::string replace_name, arg_name;
	int i, j, id;
	unsigned int success_count;
	bool result = true;
	update_flags( &info, p_last_line );
	if( !this->is_loaded ) {
		p_macro = info.macro_list[words[0]];	//	※必ず存在する
		//	引数を取り込む
		id = 0;
		for( i = 1; i < (int)words.size(); i++ ) {
			parameter.clear();
			if( id >= (int)p_macro->parameter_name_list.size() ) {
				put_error( "Too many arguments for " + words[0] + "." );
				return false;
			}
			if( p_macro->parameter_name_list[id].is_through ) {
				arg_name = "\"";
				for( j = i; j < ( int) words.size() && words[j] != ","; j++ ) {
					arg_name = arg_name + words[j];
					if( (j + 1) < ( int) words.size() && words[j + 1] != "," ) {
						arg_name = arg_name + " ";
					}
				}
				parameter.push_back( arg_name );
			}
			else {
				for( j = i; j < ( int) words.size() && words[j] != ","; j++ ) {
					parameter.push_back( words[j] );
				}
			}
			argument[p_macro->parameter_name_list[id].name] = parameter;		//	argument[ 引数名 ] = 実際の引数
			i = j;
			id++;
		}
		if( id != (int)p_macro->parameter_name_list.size() ) {
			put_error( "Mismatched number of arguments." );
			return false;
		}
		//	m_text に macro の展開内容をコピーする
		for( auto p : p_macro->m_text ) {
			insert_line = p->words;
			for( auto word = insert_line.begin(); word != insert_line.end(); ) {
				replace_name = *word;
				if( argument.count( replace_name ) ) {
					//	マクロの仮引数を見つけた場合、指定されている式に置き換える
					word = insert_line.erase( word );
					for( auto insert_word : argument[replace_name] ) {
						word = insert_line.insert( word, insert_word );
						++word;
					}
				}
				else {
					++word;
				}
			}
			text.m_text.push_back( CZMA_PARSE::create( info, insert_line, this->p_file_name, this->line_no ) );
		}
		this->is_loaded = true;
		info.is_updated = true;
	}
	info.scope.push_back( "@MACRO" + std::to_string( info.get_auto_label_index() ) );
	//	log
	if( !is_analyze_phase ) {
		log.push_back( "((" + get_line() + "))" );
		log.push_back( "\tScope path: " + info.get_scope_path() );
	}
	p_last_line = text.process( info, success_count, p_last_line, !this->is_analyze_phase );
	if( !this->is_data_fixed ) {
		for( auto p : text.m_text ) {
			this->is_data_fixed = this->is_data_fixed && p->get_fixed_code_size();
		}
		if( this->is_data_fixed ) {
			info.is_updated = true;
		}
	}
	if( this->code_size == -1 ) {
		this->code_size = 0;
		for( auto p : text.m_text ) {
			if( this->code_size != -1 && p->get_fixed_code_size() ) {
				this->code_size = this->code_size + p->get_code_size();
			}
			else {
				this->code_size = -1;
			}
		}
		if( this->code_size != -1 ) {
			info.is_updated = true;
		}
	}
	if( info.scope.size() > 0 ) {
		info.scope.pop_back();
	}
	this->next_code_address = p_last_line->get_next_code_address();
	return result && check_all_fixed();
}
