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
bool CZMA_PARSE_IF::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {
	std::string label;
	CZMA_IF_T* p_if;
	CZMA_IF_SUB_T* p_if_sub;

	update_flags( &info, p_last_line );
	if( !this->is_data_fixed ) {
		//	条件式を取り込む
		p_if				= new CZMA_IF_T;
		p_if_sub			= new CZMA_IF_SUB_T;
		p_if_sub->p_if		= this;
		p_if->m_sub.push_back( p_if_sub );
		p_if_sub->p_text	= new CZMA_TEXT;
		info.block_type				= CZMA_INFORMATION::BLOCK_TYPE_T::CZMA_INFO_IF_BLOCK;
		info.is_block_processing	= true;
		info.p_if					= p_if;
		info.p_text					= &(p_if_sub->p_text->m_text);
		this->is_data_fixed			= true;
		this->set_code_size( &info, 0 );
	}
	//	log
	if( !is_analyze_phase ) {
		log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
		log.write_separator();
	}
	return check_all_fixed();
}

// --------------------------------------------------------------------
bool CZMA_PARSE_ELSEIF::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {
	std::string label;
	CZMA_IF_T* p_if;
	CZMA_IF_SUB_T* p_if_sub;

	update_flags( &info, p_last_line );
	if( !this->is_data_fixed ) {
		if( !info.is_block_processing || info.block_type != CZMA_INFORMATION::BLOCK_TYPE_T::CZMA_INFO_IF_BLOCK ) {
			put_error( "Invalid command." );
			return false;
		}
		//	条件式を取り込む
		p_if = info.p_if;
		p_if_sub = new CZMA_IF_SUB_T;
		p_if_sub->p_if = this;
		p_if->m_sub.push_back( p_if_sub );
		p_if_sub->p_text = new CZMA_TEXT;
		info.p_text = &(p_if_sub->p_text->m_text);
		this->is_data_fixed = true;
		this->set_code_size( &info, 0 );
	}
	//	log
	if( !is_analyze_phase ) {
		log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
		log.write_separator();
	}
	return check_all_fixed();
}

// --------------------------------------------------------------------
bool CZMA_PARSE_ELSE::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {
	std::string label;
	CZMA_IF_T* p_if;
	CZMA_IF_SUB_T* p_if_sub;

	update_flags( &info, p_last_line );
	if( !this->is_data_fixed ) {
		if( !info.is_block_processing || info.block_type != CZMA_INFORMATION::BLOCK_TYPE_T::CZMA_INFO_IF_BLOCK ) {
			put_error( "Invalid command." );
			return false;
		}
		//	条件式を取り込む
		p_if = info.p_if;
		p_if_sub = new CZMA_IF_SUB_T;
		p_if_sub->p_if = this;
		p_if->m_sub.push_back( p_if_sub );
		p_if_sub->p_text = new CZMA_TEXT;
		info.p_text = &(p_if_sub->p_text->m_text);
		this->is_data_fixed = true;
		this->set_code_size( &info, 0 );
	}
	if( words.size() != 1 ) {
		put_error( "Too many parameters." );
		return false;
	}
	//	log
	if( !is_analyze_phase ) {
		log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
		log.write_separator();
	}
	return check_all_fixed();
}

// --------------------------------------------------------------------
bool CZMA_PARSE_ENDIF::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {
	CVALUE v;
	unsigned int sub_success_count;
	bool result;
	bool do_process;
	bool has_else, no_fixed;
	CZMA_PARSE_IF* p_selected_if = nullptr;
	int index, current_next_code_address;
	CZMA_PARSE* p_last_line_backup;

	update_flags( &info, p_last_line );
	if( !this->is_loaded ) {
		p_if = info.p_if;
		info.p_if = nullptr;
		this->is_loaded = true;
		info.is_updated = true;
	}
	if( p_if == nullptr ) {
		put_error( "Invalid command." );
		return false;
	}
	info.is_block_processing = false;
	if( words.size() != 1 ) {
		put_error( "Too many parameters." );
		return false;
	}
	//	コードサイズを求める処理
	if( this->next_code_address == -1 ) {
		current_next_code_address = -1;
		p_last_line_backup = p_last_line;
		has_else = false;
		no_fixed = false;
		for( auto i : p_if->m_sub ) {
			if( i->p_if->words[0] == "ELSE" ) {
				has_else = true;
			}
			p_last_line = i->p_text->process( info, sub_success_count, p_last_line_backup, false );
			if( current_next_code_address == -1 ) {
				if( p_last_line->get_next_code_address() == -1 ) {
					no_fixed = true;
					break;
				}
				current_next_code_address = p_last_line->get_next_code_address();
			}
			else {
				if( p_last_line->get_next_code_address() != current_next_code_address ) {
					no_fixed = true;
					break;
				}
			}
		}
		//	else句を持っており、かつすべての句の中身のサイズが同じであれば、中身のコードが確定していなくても、サイズを確定させる
		if( current_next_code_address != -1 && has_else && !no_fixed ) {
			this->code_size = p_last_line->get_file_address() + p_last_line->get_code_size() - this->file_address;
			this->next_code_address = current_next_code_address;
			info.is_updated = true;
		}
		p_last_line = p_last_line_backup;
	}
	//	実際に条件分岐を判断する
	result = true;
	do_process = false;
	for( auto i : p_if->m_sub ) {
		if( i->p_if->words[0] == "ELSE" ) {
			//	ELSE なら 常に条件は true
			v.value_type = CVALUE_TYPE::CV_INTEGER;
			v.i = 1;
		}
		else {
			//	IF 又は ELSEIF なら、条件式を評価
			index = i->p_if->expression( info, 1, v );
			if( index != 0 && index < (int)i->p_if->words.size() ) {
				i->p_if->put_error( "Illegal expression." );
				return false;
			}
		}
		if( v.value_type != CVALUE_TYPE::CV_INTEGER ) {
			put_error( "Illegal condition." );
			return false;
		}
		i->is_condition_fixed = true;
		if( !v.i ) {
			continue;
		}
		i->is_condition = true;
		p_last_line = i->p_text->process( info, sub_success_count, p_last_line, !is_analyze_phase );
		if( sub_success_count != i->p_text->m_text.size() ) {
			return false;
		}
		p_selected_if = i->p_if;
		do_process = true;
		break;
	}
	if( !this->is_data_fixed ) {
		this->is_data_fixed = true;
		info.is_updated = true;
	}
	if( this->next_code_address == -1 && p_last_line->get_next_code_address() != -1 ) {
		this->next_code_address = p_last_line->get_next_code_address();
		this->code_size = p_last_line->get_file_address() + p_last_line->get_code_size() - this->file_address;
		info.is_updated = true;
	}

	if( !is_analyze_phase ) {
		log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
		if( do_process ) {
			std::stringstream s;
			s << "Selected {" << p_selected_if->get_line() + "} block.";
			log.write_message( s.str() );
		}
		else {
			log.write_message( "All condition is not selected." );
		}
		log.write_separator();
	}
	return check_all_fixed();
}

// --------------------------------------------------------------------
bool CZMA_PARSE_ENDIF::write_output_and_log( CZMA_INFORMATION& info, std::ofstream* f ) {
	bool result;
	CVALUE v;

	if( p_if == nullptr ) {
		return false;
	}
	result = true;
	for( auto i : p_if->m_sub ) {
		if( !i->is_condition_fixed || !i->is_condition ) {
			continue;
		}
		result = i->p_text->write( info, f );
		break;
	}
	for( auto line : log ) {
		log.push_back( line );
	}
	log.write_separator();
	return result;
}

