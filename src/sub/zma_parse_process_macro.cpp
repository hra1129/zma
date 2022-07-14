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

#include "zma_parse_process_macro.hpp"

// --------------------------------------------------------------------
//	MACRO文は特殊な構造を持つのでこのメソッドを定義
//	load 時は、このクラスは MACROの1行目単独を示している。
//	この関数では、MACRO～ENDM全体を示すように変更する。
void CZMA_PARSE_MACRO::block_structure( std::vector<CZMA_PARSE *> &m_text, std::vector<CZMA_PARSE *>::iterator &pp_current ){

	while( pp_current != m_text.end() ){
		//	ENDM か？
		if( ( *pp_current )->words.size() > 0 && ( *pp_current )->words[ 0 ] == "ENDM" ){
			//	ENDM自体はもう不要なので削除
			pp_current = m_text.erase( pp_current );
			break;
		}
		//	中身を this->m_text に詰める
		pp_current++;
		while( pp_current != m_text.end() ){
			if( ( *pp_current )->words.size() == 0 ){
				//	through
			}
			else if( ( *pp_current )->words[ 0 ] == "ENDM" ){
				break;
			}
			( *pp_current )->block_structure( m_text, pp_current );
			this->m_text.m_text.push_back( *pp_current );
			pp_current = m_text.erase( pp_current );
		}
	}
	pp_current--;
}

// --------------------------------------------------------------------
std::vector< std::vector< std::string > > CZMA_PARSE_MACRO::get_words( void ){
	std::vector< std::vector< std::string > > list, sub_list;
	std::vector< std::string > words_endif = { "ENDM" };

	list.push_back( this->words );
	for( auto &p_block : this->m_text.m_text ){
		sub_list = p_block->get_words();
		list.insert( list.end(), sub_list.begin(), sub_list.end() );
	}
	list.push_back( words_endif );
	return list;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_MACRO::write_output_and_log( CZMA_INFORMATION &info, std::ofstream *f ){
	bool result;

	result = true;
	for( auto &line : log_header ){
		info.log << line << std::endl;
	}
	result = result && this->m_text.write( info, f );
	for( auto &line : log ){
		info.log << line << std::endl;
	}
	return result;
}


// --------------------------------------------------------------------
bool CZMA_PARSE_MACRO::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {
	std::string label;
	CZMA_MACRO_ARG arg;
	int i;

	bool result = update_flags( &info, p_last_line );
	this->set_code_size( &info, 0 );

	if( !this->is_data_fixed ) {
		if( info.macro_list.count( words[0] ) && info.macro_list[words[0]] != nullptr ) {
			//	同じ名前のマクロを宣言することはできない
			put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::MULTIPLE_DEFINITION ) );
			return false;
		}
		//	引数抽出処理
		for( i = 2; i < ( int) words.size(); ) {
			if( words[i] == "@" ) {
				arg.is_through = true;
				i++;
			}
			else {
				arg.is_through = false;
			}
			if( i >= (int)words.size() ) {
				put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_ARGUMENT ) );
				return false;
			}
			arg.name = words[i];
			if( (i + 1) < (int)words.size() && words[ i + 1 ] != "," ) {
				put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_ARGUMENT ) );
				return false;
			}
			for( auto &s : this->parameter_name_list ) {
				if( s.name == words[i] ) {
					put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::MULTIPLE_DEFINITION ) );
					return false;
				}
			}
			i = i + 2;
			this->parameter_name_list.push_back( arg );
		}
		this->is_data_fixed = true;
		this->set_code_size( &info, 0 );
		info.macro_list[words[0]] = this;
	}
	//	log
	if( !is_analyze_phase ) {
		log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
		log.write_separator();
	}
	return result;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_MACRO_INS::write_output_and_log( CZMA_INFORMATION& info, std::ofstream* f ) {
	bool result = true;

	for( auto &line : log_header ) {
		info.log << line << std::endl;
	}
	m_text.write( info, f );
	for( auto &line : log ){
		info.log << line << std::endl;
	}
	return result;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_ENDM::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {
	//	本来、これは実行されるべきでないので、常にエラーを返す。
	put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::SYNTAX_ERROR ) );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_MACRO_INS::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {
	CZMA_PARSE *p_parse;
	CZMA_PARSE_MACRO* p_macro;
	std::map< std::string, std::vector< std::string > > argument;
	std::vector< std::string > parameter, label_line;
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
				put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::TOO_MANY_PARAMETERS ) );
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
			put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::TOO_MANY_PARAMETERS ) );
			return false;
		}
		//	m_text に macro の展開内容をコピーする
		for( auto p : p_macro->m_text.m_text ) {
			auto words_list = p->get_words();
			for( auto &insert_line : words_list ){
				for( auto word = insert_line.begin(); word != insert_line.end(); ){
					replace_name = *word;
					if( argument.count( replace_name ) ){
						//	マクロの仮引数を見つけた場合、指定されている式に置き換える
						word = insert_line.erase( word );
						for( auto &insert_word : argument[ replace_name ] ){
							word = insert_line.insert( word, insert_word );
							++word;
						}
					}
					else{
						++word;
					}
				}
				//	LABEL: COMMAND のパターンはあり得ない。必ず、LABEL: か COMMAND に分けられている。
				p_parse = CZMA_PARSE::create( info, insert_line, this->p_file_name, this->line_no );
				m_text.m_text.push_back( p_parse );
			}
		}
		m_text.analyze_structure();
		this->is_loaded = true;
		info.is_updated = true;
	}
	info.scope.push_back( "@MACRO" + std::to_string( info.get_auto_label_index() ) );

	p_last_line = m_text.process( info, success_count, p_last_line, !this->is_analyze_phase );
	if( !this->is_data_fixed ) {
		this->is_data_fixed = true;
		for( auto p : m_text.m_text ) {
			this->is_data_fixed = this->is_data_fixed && p->check_data_fixed();
		}
		if( this->is_data_fixed ) {
			info.is_updated = true;
		}
	}
	if( this->code_size == -1 ) {
		this->code_size = 0;
		for( auto p : m_text.m_text ) {
			if( this->code_size != -1 && p->is_fixed_code_size() ) {
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

	//	log
	if( !is_analyze_phase ){
		log_header.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
		log_header.write_message( "Intra-macro scope: " + info.get_scope_path() );

		log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
		log.write_message( "Exit scope: " + info.get_scope_path() );
		log.write_separator();
	}

	if( info.scope.size() > 0 ) {
		info.scope.pop_back();
	}
	this->next_code_address = p_last_line->get_next_code_address();
	return result && check_all_fixed();
}
