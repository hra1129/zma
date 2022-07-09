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

#include "zma_parse_process_repeat.hpp"

// --------------------------------------------------------------------
//	REPEAT文は特殊な構造を持つのでこのメソッドを定義
//	load 時は、このクラスは REPEATの1行目単独を示している。
//	この関数では、REPEAT～ENDR全体を示すように変更する。
void CZMA_PARSE_REPEAT::block_structure( std::vector<CZMA_PARSE *> &m_text, std::vector<CZMA_PARSE *>::iterator &pp_current ){

	while( pp_current != m_text.end() ){
		//	ENDR か？
		if( ( *pp_current )->words.size() > 0 && ( *pp_current )->words[ 0 ] == "ENDR" ){
			//	ENDR自体はもう不要なので削除
			pp_current = m_text.erase( pp_current );
			break;
		}
		//	中身を this->m_text に詰める
		pp_current++;
		while( pp_current != m_text.end() ){
			if( ( *pp_current )->words.size() == 0 ){
				//	through
			}
			else if( ( *pp_current )->words[ 0 ] == "ENDR" ){
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
std::vector< std::vector< std::string > > CZMA_PARSE_REPEAT::get_words( void ){
	std::vector< std::vector< std::string > > list, sub_list;
	std::vector< std::string > words_endif = { "ENDR" };

	list.push_back( this->words );
	for( auto &p_block : this->m_text.m_text ){
		sub_list = p_block->get_words();
		list.insert( list.end(), sub_list.begin(), sub_list.end() );
	}
	list.push_back( words_endif );
	return list;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_REPEAT::write_output_and_log( CZMA_INFORMATION& info, std::ofstream* f ) {
	bool result;

	result = true;
	for( auto &line : log_header ){
		info.log << line << std::endl;
	}
	for( auto text : this->m_text_list ) {
		result = result && text->write( info, f );
	}
	for( auto &line : log ) {
		info.log << line << std::endl;
	}
	return result;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_REPEAT::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {
	std::string label;
	CVALUE v;
	int index, i;
	unsigned int sub_success_count;
	CZMA_TEXT *p_text;
	CZMA_PARSE *p_parse;
	std::string s_scope;
	std::vector< std::string > label_line;

	update_flags( &info, p_last_line );
	if( !this->is_counter_end_fixed ) {
		if( words.size() < 4 ) {
			//	REPEAT 変数名 , 値 で、少なくとも 4[word] なければならない
			put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_PARAMETER ) );
			return false;
		}
		if( words[2] != "," ) {
			put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_PARAMETER ) );
			return false;
		}
		//	"REPEAT 変数名 , 値" の 値を評価する
		index = this->expression( info, 3, v );
		if( index == 0 ) {
			put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_EXPRESSION ) );
			return false;
		}
		if( index < ( int) words.size() ) {
			put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_EXPRESSION ) );
			return false;
		}
		if( v.value_type != CVALUE_TYPE::CV_INTEGER ) {
			put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_PARAMETER ) );
			return false;
		}
		this->counter_end = v.i;
		this->is_counter_end_fixed = true;
		this->scope_name = "@REPEAT" + std::to_string( info.get_auto_label_index() );
		info.scope.push_back( this->scope_name );
		v.value_type = CVALUE_TYPE::CV_INTEGER;
		v.i = 0;
		this->counter_symbol = info.get_scope_path() + words[ 1 ];
		info.dict[this->counter_symbol] = v;

		this->is_data_fixed = true;
		info.is_updated = true;
	}
	else{
		info.scope.push_back( this->scope_name );
		this->counter_symbol = info.get_scope_path() + words[ 1 ];
	}
	//	log
	if( !is_analyze_phase ){
		log_header.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
		log_header.write_message( "Enter scope: " + info.get_scope_path() );
		log_header.write_separator();
	}

	//	this->m_text_list が空っぽなら中身を詰める
	if( !this->is_loaded ){
		if( !this->is_counter_end_fixed ){
			//	繰り返しカウンターがまだ評価完了していない
			put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::REPEAT_COUNTER_IS_NO_FIXED ) );
			info.scope.pop_back();
			return false;
		}
		for( i = 0; i < this->counter_end; i++ ){
			info.dict[ this->counter_symbol ].i = i;
			p_text = new CZMA_TEXT;
			for( auto p : this->m_text.m_text ){
				auto words_list = p->get_words();
				for( auto &insert_line : words_list ){
					if( insert_line.size() > 2 && ( ( insert_line[ 1 ] == ":" ) || ( insert_line[ 1 ] == "::" ) ) ){
						label_line.resize( 2 );
						label_line[ 0 ] = insert_line[ 0 ];
						label_line[ 1 ] = insert_line[ 1 ];
						p_parse = CZMA_PARSE::create( info, label_line, this->p_file_name, this->line_no );
						p_text->m_text.push_back( p_parse );
						insert_line.erase( insert_line.begin() );
						insert_line.erase( insert_line.begin() );
						p_parse = CZMA_PARSE::create( info, insert_line, this->p_file_name, this->line_no );
						p_text->m_text.push_back( p_parse );
					}
					else{
						p_parse = CZMA_PARSE::create( info, insert_line, this->p_file_name, this->line_no );
						p_text->m_text.push_back( p_parse );
					}
				}
			}
			p_text->analyze_structure();
			this->m_text_list.push_back( p_text );
		}
		this->is_loaded = true;
		info.is_updated = true;
	}
	//	中身を処理する
	for( i = 0; i < this->counter_end; i++ ){
		info.dict[ this->counter_symbol ].i = i;
		p_last_line = this->m_text_list[ i ]->process( info, sub_success_count, p_last_line, !is_analyze_phase );
	}

	//	データが確定したか確認する
	if( !this->is_data_fixed ){
		for( auto p_text : this->m_text_list ){
			for( auto p : p_text->m_text ){
				this->is_data_fixed = this->is_data_fixed && p->is_fixed_code_size();
			}
		}
		if( this->is_data_fixed ){
			info.is_updated = true;
		}
	}

	//	コードサイズを計算する
	if( this->code_size == -1 ){
		this->code_size = 0;
		for( auto p_text : this->m_text_list ){
			for( auto p : p_text->m_text ){
				if( this->code_size != -1 && p->is_fixed_code_size() ){
					this->code_size = this->code_size + p->get_code_size();
				}
				else{
					this->code_size = -1;
					break;
				}
			}
			if( this->code_size == -1 ){
				break;
			}
		}
		if( this->code_size != -1 ){
			info.is_updated = true;
		}
	}

	//	次のアドレスを計算する
	if( this->next_code_address == -1 ){
		if( p_last_line == nullptr ){
			this->next_code_address = 0;
		}
		else{
			this->next_code_address = p_last_line->get_next_code_address();
		}
		if( this->next_code_address != -1 ){
			info.is_updated = true;
		}
	}

	//	log
	if( !is_analyze_phase ){
		log.write_message( "Exit scope: " + s_scope );
		log.write_separator();
	}
	s_scope = info.get_scope_path();
	info.scope.pop_back();
	return check_all_fixed();
}

// --------------------------------------------------------------------
bool CZMA_PARSE_ENDR::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {
	//	本来、これは実行されるべきでないので、常にエラーを返す。
	put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::SYNTAX_ERROR ) );
	return false;
}
