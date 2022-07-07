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
//	IF���͓���ȍ\�������̂ł��̃��\�b�h���`
//	load ���́A���̃N���X�� IF��1�s�ڒP�Ƃ������Ă���B
//	���̊֐��ł́AIF�`ENDIF�S�̂������悤�ɕύX����B
//	elseif, else, endif �� if �̒��Ɏ�荞�ށB
void CZMA_PARSE_IF::block_structure( std::vector<CZMA_PARSE *> &m_text, std::vector<CZMA_PARSE *>::iterator &pp_current ){
	CZMA_PARSE_IF_BLOCK *p_block;
	CZMA_IF_BLOCK_T *p_sub;
	bool b_do_else;

	//	���� IF ���̂��̂� IF_BLOCK �����B
	p_block = new CZMA_PARSE_IF_BLOCK( this->words, this->p_file_name, this->line_no );
	pp_current = m_text.insert( pp_current, p_block );	//	IF_BLOCK �� IF �̈ʒu�ɑ}������
	pp_current++;										//	pp_current �� IF ���w���悤�Ɉړ�������

	b_do_else = false;
	while( pp_current != m_text.end() ){
		//	ENDIF ���H
		if( ( *pp_current )->words.size() > 0 && ( *pp_current )->words[ 0 ] == "ENDIF" ){
			//	ENDIF���̂͂����s�v�Ȃ̂ō폜
			pp_current = m_text.erase( pp_current );
			break;
		}
		//	IF, ELSEIF �� sub �ɒǉ�
		p_sub = new CZMA_IF_BLOCK_T;
		p_sub->p_if = reinterpret_cast< CZMA_PARSE_IF* >( *pp_current );
		pp_current = m_text.erase( pp_current );
		p_block->m_sub.push_back( p_sub );
		//	���g�� p_if->m_text �ɋl�߂�
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
					//	ELSE �̂��Ƃ� ELSEIF ������ꍇ�A�G���[
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
//	1��IF���ɂ��ăR�[�h�T�C�Y���v�Z����
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
		//	IF, ELSEIF, ELSE �̂����ꂩ
		p_previous_sub_dict = info.p_sub_dict;
		if( p_block->p_if->is_condition_fixed && !p_block->p_if->is_condition ){
			//	�����s�������m�肵�Ă���̂Ŏ���
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
			//	���̏������I�����ꂽ�̂ŁA����ȍ~�� ELSEIF, ELSE �͕]���ΏۊO
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
		//	���łɏ������͑S�Ċm�肵�Ă���
		return;
	}
	this->is_condition_fixed = true;
	for( auto &p : this->m_sub ){
		if( p->p_if->is_condition_fixed && p->p_if->is_condition ){
			//	�������m�肵�Ă��āA���� TRUE �ł���ꍇ�A����ȍ~�̏��������m��ł��֌W�Ȃ��̂Ŋm�肵�����Ƃɂ���
			info.is_updated = true;		//	�����m��ւ̕ω��Ƃ������ƂŁAis_update �𗧂Ă�
			break;
		}
		if( !p->p_if->is_condition_fixed ){
			//	�������m�肵�Ă��Ȃ� IF/ELSEIF �ɓ��������ꍇ�A����ȍ~�̏������m��ł����Ă��֌W�Ȃ��̂Ŗ��m��Ƃ��Ĕ�����
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
		//	���łɃT�C�Y�͊m��ς݂Ȃ̂ŉ������Ȃ�
		return;
	}

	this->code_size = -1;
	this->next_code_address = -1;
	for( auto &p : this->m_sub ){
		if( p->p_if->is_condition_fixed ) {
			//	�������m��ς݂̏ꍇ
			if( !p->p_if->is_condition ){
				//	�����s�����̏ꍇ�A�e�����y�ڂ��Ȃ�
				continue;
			}
			//	���������̏ꍇ
			if( p->p_if->get_code_size() == -1 ){
				//	�܂��R�[�h�T�C�Y����܂��Ă��Ȃ��ꍇ
				this->code_size = -1;
				this->next_code_address = -1;
				break;
			}
			//	�R�[�h�T�C�Y����܂��Ă���ꍇ
			if( this->code_size == -1 ){
				//	�ŏ���IF���̏ꍇ�A�����őS�Ă��m�肷��
				this->code_size = p->p_if->get_code_size();
				this->next_code_address = p->p_if->get_next_code_address();
				break;
			}
			//	2�Ԗڈȍ~��IF���̏ꍇ�A�T�C�Y�̈Ⴂ���`�F�b�N����
			if( this->code_size != p->p_if->get_code_size() ){
				//	1�Ԗڂ�2�Ԗڈȍ~�ŃT�C�Y���قȂ��Ă���̂Ŗ��m�舵����6����
				this->code_size = -1;
			}
			if( this->next_code_address != p->p_if->get_next_code_address() ){
				//	1�Ԗڂ�2�Ԗڈȍ~�ŃT�C�Y���قȂ��Ă���̂Ŗ��m�舵����6����
				this->next_code_address = -1;
			}
			if( this->code_size == -1 || this->next_code_address == -1 ){
				//	���m�肪���������̂Ŕ�����
				break;
			}
		}
		else{
			//	���������m��̏ꍇ
			if( p->p_if->get_code_size() == -1 ){
				//	�܂��R�[�h�T�C�Y����܂��Ă��Ȃ��ꍇ
				this->code_size = -1;
				this->next_code_address = -1;
				break;
			}
			//	�R�[�h�T�C�Y����܂��Ă���ꍇ
			if( this->code_size == -1 ){
				//	�ŏ���IF���̏ꍇ�A�����őS�Ă��m�肷��
				this->code_size = p->p_if->get_code_size();
				this->next_code_address = p->p_if->get_next_code_address();
				continue;
			}
			//	2�Ԗڈȍ~��IF���̏ꍇ�A�T�C�Y�̈Ⴂ���`�F�b�N����
			if( this->code_size != p->p_if->get_code_size() ){
				//	1�Ԗڂ�2�Ԗڈȍ~�ŃT�C�Y���قȂ��Ă���̂Ŗ��m�舵����6����
				this->code_size = -1;
			}
			if( this->next_code_address != p->p_if->get_next_code_address() ){
				//	1�Ԗڂ�2�Ԗڈȍ~�ŃT�C�Y���قȂ��Ă���̂Ŗ��m�舵����6����
				this->next_code_address = -1;
			}
			if( this->code_size == -1 || this->next_code_address == -1 ){
				//	���m�肪���������̂Ŕ�����
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

	//	��������]������
	this->update_flags( &info, p_last_line );
	if( !this->is_condition_fixed ){
		index = this->expression( info, 1, result );
		if( result.is_unknown() ){
			//	���������s��Ȃ̂ŁA���m�舵�����ێ�
			this->is_condition_fixed = false;
		}
		else if( result.is_string() ){
			//	��������������ɂȂ��Ă���̂ŁA�G���[�ɂ���
			put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_PARAMETER ) );
			return false;
		}
		else{
			//	���������m�肵���̂ŁA���ʂ�ۑ�����
			this->is_condition = ( result.i != 0 );
			this->is_condition_fixed = true;
		}
	}
	if( this->is_condition_fixed && !this->is_condition ){
		//	������]���ς݂ŁA������ FALSE �������ꍇ�A�����o���Ȃ��B
		return true;
	}
	//	���g��]������
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
		//	������]���ς݂ŁA������ FALSE �������ꍇ�A�����o���Ȃ��B
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

	//	��������]������
	this->update_flags( &info, p_last_line );
	if( !this->is_condition_fixed ){
		index = this->expression( info, 1, result );
		if( result.is_unknown() ){
			//	���������s��Ȃ̂ŁA���m�舵�����ێ�
			this->is_condition_fixed = false;
		}
		else if( result.is_string() ){
			//	��������������ɂȂ��Ă���̂ŁA�G���[�ɂ���
			put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_PARAMETER ) );
			return false;
		}
		else{
			//	���������m�肵���̂ŁA���ʂ�ۑ�����
			this->is_condition = ( result.i != 0 );
			this->is_condition_fixed = true;
		}
	}
	if( this->is_condition_fixed && !this->is_condition ){
		//	������]���ς݂ŁA������ FALSE �������ꍇ�A�����o���Ȃ��B
		return true;
	}
	//	���g��]������
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
	//	ELSE �́A�����������ŏ�ɐ����B
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
	//	�{���A����͎��s�����ׂ��łȂ��̂ŁA��ɃG���[��Ԃ��B
	put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::SYNTAX_ERROR ) );
	return false;
}
