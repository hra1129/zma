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
//	IF文は特殊な構造を持つのでこのメソッドを定義
//	load 時は、このクラスは IFの1行目単独を示している。
//	この関数では、IF～ENDIF全体を示すように変更する。
//	elseif, else, endif を if の中に取り込む。
void CZMA_PARSE_IF::block_structure( std::vector<CZMA_PARSE *> &m_text, std::vector<CZMA_PARSE *>::iterator &pp_current ){
	CZMA_PARSE_IF_BLOCK *p_block;
	CZMA_IF_BLOCK_T *p_sub;
	bool b_do_else;

	//	この IF そのものの IF_BLOCK を作る。
	p_block = new CZMA_PARSE_IF_BLOCK( this->words, this->p_file_name, this->line_no );
	pp_current = m_text.insert( pp_current, p_block );	//	IF_BLOCK を IF の位置に挿入する
	pp_current++;										//	pp_current が IF を指すように移動させる

	b_do_else = false;
	while( pp_current != m_text.end() ){
		//	ENDIF か？
		if( ( *pp_current )->words.size() > 0 && ( *pp_current )->words[ 0 ] == "ENDIF" ){
			//	ENDIF自体はもう不要なので削除
			pp_current = m_text.erase( pp_current );
			break;
		}
		//	IF, ELSEIF を sub に追加
		p_sub = new CZMA_IF_BLOCK_T;
		p_sub->p_if = reinterpret_cast< CZMA_PARSE_IF* >( *pp_current );
		pp_current = m_text.erase( pp_current );
		p_block->m_sub.push_back( p_sub );
		//	中身を p_if->m_text に詰める
		std::vector< CZMA_PARSE * >::iterator p = p_sub->p_if->m_text.m_text.begin();
		while( pp_current != m_text.end() ){
			if( ( *pp_current )->words.size() == 0 ){
				//	through
			}
			else if( ( *pp_current )->words[ 0 ] == "ENDIF" ){
				break;
			}
			else if( ( *pp_current )->words[ 0 ] == "ELSEIF" ){
				if( b_do_else ){
					//	ELSE のあとに ELSEIF がある場合、エラー
					put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::SYNTAX_ERROR ) );
				}
				break;
			}
			else if( ( *pp_current )->words[ 0 ] == "ELSE" ){
				b_do_else = true;
				break;
			}
			( *pp_current )->block_structure( m_text, pp_current );
			p_sub->p_if->m_text.m_text.push_back( *pp_current );
			pp_current = m_text.erase( pp_current );
		}
	}
	pp_current--;
}

// --------------------------------------------------------------------
void CZMA_PARSE_ELSEIF::block_structure( std::vector<CZMA_PARSE *> &m_text, std::vector<CZMA_PARSE *>::iterator &pp_current ){

	set_output_mode();
	put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::SYNTAX_ERROR ) );
}

// --------------------------------------------------------------------
void CZMA_PARSE_ELSE::block_structure( std::vector<CZMA_PARSE *> &m_text, std::vector<CZMA_PARSE *>::iterator &pp_current ){

	set_output_mode();
	put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::SYNTAX_ERROR ) );
}

// --------------------------------------------------------------------
//	1つのIF文についてコードサイズを計算する
int CZMA_PARSE_IF_BLOCK::calc_code_size( CZMA_INFORMATION &info, CZMA_IF_BLOCK_T *p_block, CZMA_PARSE *p_last_line, int &next_code_address ){
	int code_size = 0;

	for( auto &p: p_block->p_if->m_text.m_text ){
		if( p->is_fixed_code_size() ){
			code_size += p->get_code_size();
		}
		else{
			return -1;
		}
		if( p->is_fixed_next_code_address() ){
			next_code_address = p->get_next_code_address();
		}
		else{
			next_code_address = -1;
		}
	}
	return code_size;
}

// --------------------------------------------------------------------
std::vector< std::vector< std::string > > CZMA_PARSE_IF_BLOCK::get_words( void ){
	std::vector< std::vector< std::string > > list, sub_list;
	std::vector< std::string > words_endif = { "ENDIF" };

	for( auto &p_block : this->m_sub ){
		sub_list = p_block->p_if->get_words();
		list.insert( list.end(), sub_list.begin(), sub_list.end() );
	}
	list.push_back( words_endif );
	return list;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_IF_BLOCK::sub_process( CZMA_INFORMATION &info, CZMA_PARSE *p_last_line ){
	bool b_result = true;
	bool data_fixed = true;
	std::map< std::string, CVALUE > *p_previous_sub_dict;

	for( auto &p_block : this->m_sub ){
		//	IF, ELSEIF, ELSE のいずれか
		p_previous_sub_dict = info.p_sub_dict;
		if( p_block->p_if->is_condition_fixed && !p_block->p_if->is_condition ){
			//	条件不成立が確定しているので次へ
			continue;
		}
		info.p_sub_dict = &( p_block->dict );
		if( !p_block->p_if->process( info, p_last_line ) ){
			b_result = false;
		}
		if( !p_block->p_if->is_condition_fixed || !p_block->p_if->check_data_fixed() ){
			data_fixed = false;
		}
		info.p_sub_dict = p_previous_sub_dict;
		if( p_block->p_if->is_condition_fixed && p_block->p_if->is_condition ){
			//	この条件が選択されたので、これ以降の ELSEIF, ELSE は評価対象外
			break;
		}
	}
	is_data_fixed = data_fixed;
	return b_result;
}

// --------------------------------------------------------------------
void CZMA_PARSE_IF_BLOCK::set_output_mode( void ){

	this->is_analyze_phase = false;
	for( auto &p_block : this->m_sub ){
		p_block->p_if->set_output_mode();
	}
}

// --------------------------------------------------------------------
void CZMA_PARSE_IF_BLOCK::update_condition( CZMA_INFORMATION &info, CZMA_PARSE *p_last_line ){

	if( this->is_condition_fixed ){
		//	すでに条件式は全て確定している
		return;
	}
	this->is_condition_fixed = true;
	for( auto &p : this->m_sub ){
		if( p->p_if->is_condition_fixed && p->p_if->is_condition ){
			//	条件が確定していて、かつ TRUE である場合、これ以降の条件が未確定でも関係ないので確定したことにする
			info.is_updated = true;		//	条件確定への変化ということで、is_update を立てる
			break;
		}
		if( !p->p_if->is_condition_fixed ){
			//	条件が確定していない IF/ELSEIF に当たった場合、これ以降の条件が確定であっても関係ないので未確定として抜ける
			this->is_condition_fixed = false;
			break;
		}
	}
}

// --------------------------------------------------------------------
void CZMA_PARSE_IF_BLOCK::update_code_size( CZMA_INFORMATION &info, CZMA_PARSE *p_last_line ){
	bool b_code_size_fixed;
	bool b_next_code_address_fixed;

	b_code_size_fixed = ( this->code_size != -1 );
	b_next_code_address_fixed = ( this->next_code_address != -1 );

	if( b_code_size_fixed && b_next_code_address_fixed ){
		//	すでにサイズは確定済みなので何もしない
		return;
	}

	this->code_size = -1;
	this->next_code_address = -1;
	for( auto &p : this->m_sub ){
		if( p->p_if->is_condition_fixed ) {
			//	条件が確定済みの場合
			if( !p->p_if->is_condition ){
				//	条件不成立の場合、影響を及ぼさない
				continue;
			}
			//	条件成立の場合
			if( p->p_if->get_code_size() == -1 ){
				//	まだコードサイズが定まっていない場合
				this->code_size = -1;
				this->next_code_address = -1;
				break;
			}
			//	コードサイズが定まっている場合
			if( this->code_size == -1 ){
				//	最初のIF文の場合、ここで全てが確定する
				this->code_size = p->p_if->get_code_size();
				this->next_code_address = p->p_if->get_next_code_address();
				break;
			}
			//	2番目以降のIF文の場合、サイズの違いをチェックする
			if( this->code_size != p->p_if->get_code_size() ){
				//	1番目と2番目以降でサイズが異なっているので未確定扱いに6する
				this->code_size = -1;
			}
			if( this->next_code_address != p->p_if->get_next_code_address() ){
				//	1番目と2番目以降でサイズが異なっているので未確定扱いに6する
				this->next_code_address = -1;
			}
			if( this->code_size == -1 || this->next_code_address == -1 ){
				//	未確定が発生したので抜ける
				break;
			}
		}
		else{
			//	条件が未確定の場合
			if( p->p_if->get_code_size() == -1 ){
				//	まだコードサイズが定まっていない場合
				this->code_size = -1;
				this->next_code_address = -1;
				break;
			}
			//	コードサイズが定まっている場合
			if( this->code_size == -1 ){
				//	最初のIF文の場合、ここで全てが確定する
				this->code_size = p->p_if->get_code_size();
				this->next_code_address = p->p_if->get_next_code_address();
				continue;
			}
			//	2番目以降のIF文の場合、サイズの違いをチェックする
			if( this->code_size != p->p_if->get_code_size() ){
				//	1番目と2番目以降でサイズが異なっているので未確定扱いに6する
				this->code_size = -1;
			}
			if( this->next_code_address != p->p_if->get_next_code_address() ){
				//	1番目と2番目以降でサイズが異なっているので未確定扱いに6する
				this->next_code_address = -1;
			}
			if( this->code_size == -1 || this->next_code_address == -1 ){
				//	未確定が発生したので抜ける
				break;
			}
		}
	}
	if( ((!b_code_size_fixed) && (this->code_size != -1)) || ((!b_next_code_address_fixed) && (this->next_code_address != -1)) ){
		info.is_updated = true;
	}
}

// --------------------------------------------------------------------
bool CZMA_PARSE_IF_BLOCK::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	sub_process( info, p_last_line );
	update_flags( &info, p_last_line );
	update_condition( info, p_last_line );
	update_code_size( info, p_last_line );
	return check_all_fixed();
}

// --------------------------------------------------------------------
bool CZMA_PARSE_IF_BLOCK::write_output_and_log( CZMA_INFORMATION &info, std::ofstream *f ){
	bool result = true;

	if( this->m_sub.size() == 0 ){
		return true;
	}
	for( auto &p : this->m_sub ){
		if( p->p_if->is_condition_fixed && p->p_if->is_condition ){
			result = p->p_if->write_output_and_log( info, f );
			break;
		}
	}
	return result;
}

// --------------------------------------------------------------------
std::vector< std::vector< std::string > > CZMA_PARSE_IF::get_words( void ){
	std::vector< std::vector< std::string > > list, sub_list;

	list.push_back( this->words );
	for( auto &p_block : this->m_text.m_text ){
		sub_list = p_block->get_words();
		list.insert( list.end(), sub_list.begin(), sub_list.end() );
	}
	return list;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_IF::process( CZMA_INFORMATION &info, CZMA_PARSE *p_last_line ){
	int index;
	unsigned int success_count;
	CVALUE result;

	//	条件式を評価する
	this->update_flags( &info, p_last_line );
	if( !this->is_condition_fixed ){
		index = this->expression( info, 1, result );
		if( result.is_unknown() ){
			//	条件式が不定なので、未確定扱いを維持
			this->is_condition_fixed = false;
		}
		else if( result.is_string() ){
			//	条件式が文字列になっているので、エラーにする
			put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_PARAMETER ) );
			return false;
		}
		else{
			//	条件式が確定したので、結果を保存する
			this->is_condition = ( result.i != 0 );
			this->is_condition_fixed = true;
		}
	}
	if( this->is_condition_fixed && !this->is_condition ){
		//	条件を評価済みで、条件が FALSE だった場合、何も出さない。
		return true;
	}
	//	中身を評価する
	this->m_text.process( info, success_count, p_last_line, !this->is_analyze_phase );
	this->m_text.calc_code_size();
	this->code_size = this->m_text.get_code_size();
	this->is_data_fixed = this->m_text.check_data_fixed();
	if( !this->is_fixed_next_code_address() ){
		this->next_code_address = this->m_text.get_next_code_address();
	}
	return check_all_fixed();
}

// --------------------------------------------------------------------
void CZMA_PARSE_IF::set_output_mode( void ){

	this->is_analyze_phase = false;
	for( auto &p : this->m_text.m_text ){
		p->set_output_mode();
	}
}

// --------------------------------------------------------------------
bool CZMA_PARSE_IF::write_output_and_log( CZMA_INFORMATION &info, std::ofstream *f ){
	bool result = true;

	if( this->is_condition_fixed && !this->is_condition ){
		//	条件を評価済みで、条件が FALSE だった場合、何も出さない。
		return true;
	}
	for( auto &p : this->m_text.m_text ){
		result = p->write_output_and_log( info, f ) && result;
	}
	return result;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_ELSEIF::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {
	int index;
	unsigned int success_count;
	CVALUE result;

	//	条件式を評価する
	this->update_flags( &info, p_last_line );
	if( !this->is_condition_fixed ){
		index = this->expression( info, 1, result );
		if( result.is_unknown() ){
			//	条件式が不定なので、未確定扱いを維持
			this->is_condition_fixed = false;
		}
		else if( result.is_string() ){
			//	条件式が文字列になっているので、エラーにする
			put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_PARAMETER ) );
			return false;
		}
		else{
			//	条件式が確定したので、結果を保存する
			this->is_condition = ( result.i != 0 );
			this->is_condition_fixed = true;
		}
	}
	if( this->is_condition_fixed && !this->is_condition ){
		//	条件を評価済みで、条件が FALSE だった場合、何も出さない。
		return true;
	}
	//	中身を評価する
	this->m_text.process( info, success_count, p_last_line, !this->is_analyze_phase );
	this->m_text.calc_code_size();
	this->code_size = this->m_text.get_code_size();
	this->is_data_fixed = this->m_text.check_data_fixed();
	if( !this->is_fixed_next_code_address() ){
		this->next_code_address = this->m_text.get_next_code_address();
	}
	return check_all_fixed();
}

// --------------------------------------------------------------------
bool CZMA_PARSE_ELSE::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {
	unsigned int success_count;

	this->update_flags( &info, p_last_line );
	//	ELSE は、条件式無しで常に成立。
	if( !this->is_condition_fixed ){
		info.is_updated = true;
	}
	this->is_condition_fixed = true;
	this->is_condition = true;

	this->m_text.process( info, success_count, p_last_line, !this->is_analyze_phase );
	this->m_text.calc_code_size();
	this->code_size = this->m_text.get_code_size();
	this->is_data_fixed = this->m_text.check_data_fixed();
	if( !this->is_fixed_next_code_address() ){
		this->next_code_address = this->m_text.get_next_code_address();
	}
	return this->check_all_fixed();
}

// --------------------------------------------------------------------
bool CZMA_PARSE_ENDIF::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {
	//	本来、これは実行されるべきでないので、常にエラーを返す。
	put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::SYNTAX_ERROR ) );
	return false;
}
