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
bool CZMA_PARSE_CONTAINER::update_flags( CZMA_INFORMATION *p_info, const CZMA_PARSE *p_last_line ){

}

// --------------------------------------------------------------------
bool CZMA_PARSE_CONTAINER::write_output_and_log( CZMA_INFORMATION& info, std::ofstream* f ) {

	for( auto line : log ) {
		info.log << line << " begin" << std::endl;
	}
	bool result = this->text.write( info, f );
	for( auto line : log ) {
		info.log << line << " end" << std::endl;
		info.log << std::endl;
	}
	return result;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_CONTAINER::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {
	std::string s;
	int i;
	unsigned int success_count;
	CVALUE path;
	std::ifstream f;
	bool is_open;

	update_flags( &info, p_last_line );
	if( words.size() < 2 ) {
		put_error( "Must be set include file name." );
		return false;
	}
	i = this->expression( info, 1, path );
	if( i == 0 ) {
		put_error( "Invalid expression." );
		return false;
	}
	if( path.value_type != CVALUE_TYPE::CV_STRING ) {
		put_error( "Invalid parameter." );
		return false;
	}
	if( i < (int)words.size() ) {
		put_error( "INCLUDE command has only one parameter." );
		return false;
	}
	if( !this->is_loaded ) {
		is_open = false;
		for( auto include_path : info.include_path ) {
			s = include_path + "/" + path.s;
			f.open( s.c_str() );
			if( f ) {
				f.close();
				this->s_file_name = s;
				if( this->text.load( info, this->s_file_name.c_str() ) ) {
					this->is_loaded = true;
					is_open = true;
					break;
				}
			}
		}
		if( !is_open ) {
			put_error( std::string( "Cannot open include file '" ) + path.s + "'." );
			return false;
		}
		info.is_updated = true;
	}
	//	log
	if( !this->is_analyze_phase ) {
		log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
	}
	if( p_last_line->is_fixed_file_address() && p_last_line->is_fixed_code_size() ) {
		this->file_address = p_last_line->get_file_address() + p_last_line->get_code_size();
	}
	p_last_line = this->text.process( info, success_count, p_last_line, !this->is_analyze_phase );
	if( p_last_line->is_fixed_next_code_address() ) {
		this->next_code_address = p_last_line->get_next_code_address();
	}
	if( !this->is_data_fixed ) {
		for( auto p : text.m_text ) {
			this->is_data_fixed = this->is_data_fixed && p->check_data_fixed();
		}
		if( this->is_data_fixed ) {
			info.is_updated = true;
		}
	}
	if( this->code_size == -1 ) {
		for( auto p : text.m_text ) {
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
	if( success_count < this->text.m_text.size() ) {
		return false;
	}
	return check_all_fixed();
}
