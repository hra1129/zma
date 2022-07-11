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

#include "zma_parse_process_link.hpp"

// --------------------------------------------------------------------
//	LINK���͓���ȍ\�������̂ł��̃��\�b�h���`
//	load ���́A���̃N���X�� LINK��1�s�ڒP�Ƃ������Ă���B
//	���̊֐��ł́ALINK�`ENDL�S�̂������悤�ɕύX����B
void CZMA_PARSE_LINK::block_structure( std::vector<CZMA_PARSE *> &m_text, std::vector<CZMA_PARSE *>::iterator &pp_current ){

	while( pp_current != m_text.end() ){
		//	ENDL ���H
		if( ( *pp_current )->words.size() > 0 && ( *pp_current )->words[ 0 ] == "ENDL" ){
			//	ENDL���̂͂����s�v�Ȃ̂ō폜
			pp_current = m_text.erase( pp_current );
			break;
		}
		//	���g�� this->m_text �ɋl�߂�
		pp_current++;
		while( pp_current != m_text.end() ){
			if( ( *pp_current )->words.size() == 0 ){
				//	through
			}
			else if( ( *pp_current )->words[ 0 ] == "ENDL" ){
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
std::vector< std::vector< std::string > > CZMA_PARSE_LINK::get_words( void ){
	std::vector< std::vector< std::string > > list, sub_list;
	std::vector< std::string > words_endif = { "ENDL" };

	list.push_back( this->words );
	for( auto &p_block : this->m_text.m_text ){
		sub_list = p_block->get_words();
		list.insert( list.end(), sub_list.begin(), sub_list.end() );
	}
	list.push_back( words_endif );
	return list;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_LINK::write_output_and_log( CZMA_INFORMATION& info, std::ofstream* f ) {
	bool result;

	result = true;
	for( auto &line : log_header ){
		info.log << line << std::endl;
	}
	result = this->m_text.write( info, f );
	for( auto &line : log ) {
		info.log << line << std::endl;
	}
	return result;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_LINK::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {
	std::string label;
	CVALUE v;
	int index;
	unsigned int sub_success_count;
	std::string s_scope, s_name;
	std::vector< std::string > label_line;

	update_flags( &info, p_last_line );
	if( !this->is_trigger_evaluated ) {
		if( words.size() < 2 ) {
			//	LINK ���x���� �ŁA���Ȃ��Ƃ� 2[word] �Ȃ���΂Ȃ�Ȃ�
			put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_PARAMETER ) );
			return false;
		}
		s_scope = info.get_scope_path();
		for( index = 1; index < (int)words.size(); ){
			s_name = s_scope + words[ index ];
			this->trigger_name_list.push_back( s_name );
			if( ( index + 1 ) < (int)words.size() && words[ index + 1 ] != "," ){
				put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_PARAMETER ) );
				return false;
			}
			//	info.link_list �ɖ��O���X�g��ǉ�����B
			if( info.link_list.count( s_name ) ){
				put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::MULTIPLE_DEFINITION ) );
				return false;
			}
			info.link_list[ s_name ] = this;
			//	���O���̂��̂� , �� 2words
			index += 2;
		}
		this->is_trigger_evaluated = true;
		info.is_updated = true;
	}
	//	log
	if( !is_analyze_phase && is_used ){
		log_header.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
		log_header.write_separator();
	}

	if( is_used ){
		//	���g����������
		p_last_line = this->m_text.process( info, sub_success_count, p_last_line, !is_analyze_phase );

		//	�f�[�^���m�肵�����m�F����
		if( !this->is_data_fixed ){
			this->is_data_fixed = this->m_text.check_data_fixed();
			if( this->is_data_fixed ){
				info.is_updated = true;
			}
		}

		//	�R�[�h�T�C�Y���v�Z����
		if( this->code_size == -1 ){
			this->m_text.calc_code_size();
			this->code_size = this->m_text.get_code_size();
			if( this->code_size != -1 ){
				info.is_updated = true;
			}
		}

		//	���̃A�h���X���v�Z����
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
	}
	else if( is_evaluated ){
		this->set_code_size( &info, 0 );

		//	���̃A�h���X���v�Z����
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
	}

	return check_all_fixed();
}

// --------------------------------------------------------------------
bool CZMA_PARSE_ENDL::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {
	//	�{���A����͎��s�����ׂ��łȂ��̂ŁA��ɃG���[��Ԃ��B
	put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::SYNTAX_ERROR ) );
	return false;
}
