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
bool CZMA_PARSE_INCLUDE::write_output_and_log( CZMA_INFORMATION& info, std::ofstream* f ) {

	for( auto line : log ) {
		info.log << line << " begin" << std::endl;
	}
	bool result = this->m_text.write( info, f );
	for( auto line : log ) {
		info.log << line << " end" << std::endl;
	}
	return result;
}

// --------------------------------------------------------------------
//	1つのIF文についてコードサイズを計算する
int CZMA_PARSE_INCLUDE::calc_code_size( CZMA_INFORMATION &info, CZMA_PARSE *p_last_line, int &next_code_address ){
	int code_size = 0;

	for( auto &p : this->m_text.m_text ){
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
bool CZMA_PARSE_INCLUDE::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {
	std::string s;
	int i;
	unsigned int success_count;
	CVALUE path;
	std::ifstream f;
	bool is_open;

	update_flags( &info, p_last_line );
	//	ファイル名を評価
	if( words.size() < 2 ) {
		put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::MUST_BE_SET_NAME ) );
		return false;
	}
	i = this->expression( info, 1, path, false );
	if( i == 0 ) {
		put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_EXPRESSION ) );
		return false;
	}
	if( path.value_type != CVALUE_TYPE::CV_STRING ) {
		put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_PARAMETER ) );
		return false;
	}
	if( i < (int)words.size() ) {
		put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::TOO_MANY_PARAMETERS ) );
		return false;
	}
	if( !this->is_loaded ) {
		//	指定のファイルを m_text に読み込み
		is_open = false;
		//	includeパスを順次走査
		for( auto include_path : info.include_path ) {
			s = include_path + "/" + path.s;
			f.open( s.c_str() );
			if( f ) {
				f.close();
				this->s_file_name = s;
				if( this->m_text.load( info, this->s_file_name.c_str() ) ) {
					this->is_loaded = true;
					is_open = true;
					break;
				}
			}
		}
		if( !is_open ) {
			put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::CANNOT_OPEN_THE_FILE ) );
			return false;
		}
		this->m_text.analyze_structure();
		info.is_updated = true;
	}
	//	log
	if( !this->is_analyze_phase ) {
		log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
	}
	if( p_last_line->is_fixed_file_address() && p_last_line->is_fixed_code_size() ) {
		this->file_address = p_last_line->get_file_address() + p_last_line->get_code_size();
	}
	p_last_line = this->m_text.process( info, success_count, p_last_line, !this->is_analyze_phase );
	if( p_last_line->is_fixed_next_code_address() ) {
		this->next_code_address = p_last_line->get_next_code_address();
		this->code_size = p_last_line->get_file_address() + p_last_line->get_code_size() - this->file_address;
	}
	if( !this->is_data_fixed ) {
		for( auto p : m_text.m_text ) {
			this->is_data_fixed = this->is_data_fixed && p->check_data_fixed();
		}
		if( this->is_data_fixed ) {
			info.is_updated = true;
		}
	}
	if( this->code_size == -1 ) {
		calc_code_size( info, p_last_line, this->next_code_address );
		if( this->code_size != -1 ) {
			info.is_updated = true;
		}
	}
	if( success_count < this->m_text.m_text.size() ) {
		return false;
	}
	return check_all_fixed();
}
