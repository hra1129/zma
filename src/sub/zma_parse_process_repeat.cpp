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
bool CZMA_PARSE_ENDR::write_output_and_log( CZMA_INFORMATION& info, std::ofstream* f ) {
	bool result;

	result = true;
	for( auto text : this->text_list ) {
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
	int index;

	update_flags( &info, p_last_line );
	this->set_code_size( &info, 0 );
	if( p_repeat == nullptr ) {
		p_repeat = new CZMA_REPEAT_T;
	}
	if( !p_repeat->is_counter_end_fixed ) {
		if( words.size() < 4 ) {
			//	REPEAT •Ï”–¼ , ’l ‚ÅA­‚È‚­‚Æ‚à 4[word] ‚È‚¯‚ê‚Î‚È‚ç‚È‚¢
			put_error( "Illegal parameter." );
			return false;
		}
		if( words[2] != "," ) {
			put_error( "Illegal parameter." );
			return false;
		}

		info.block_type = CZMA_INFORMATION::BLOCK_TYPE_T::CZMA_INFO_REPEAT_BLOCK;
		info.p_repeat = p_repeat;
		info.is_block_processing = true;
		info.p_text = &(info.p_repeat->m_text);

		index = this->expression( info, 3, v );
		if( index == 0 ) {
			put_error( "Illegal expression." );
			return false;
		}
		if( index < ( int) words.size() ) {
			put_error( "Illegal expression." );
			return false;
		}
		if( v.value_type != CVALUE_TYPE::CV_INTEGER ) {
			put_error( "Illegal parameter." );
			return false;
		}
		p_repeat->counter_end = v.i;
		p_repeat->is_counter_end_fixed = true;
		p_repeat->scope_name = "@REPEAT" + std::to_string( info.get_auto_label_index() );
		info.scope.push_back( p_repeat->scope_name );
		p_repeat->counter_symbol = info.get_scope_path() + words[1];
		v.value_type = CVALUE_TYPE::CV_INTEGER;
		v.i = 0;
		info.dict[p_repeat->counter_symbol] = v;

		this->is_data_fixed = true;
		info.is_updated = true;
	}
	else {
		info.scope.push_back( p_repeat->scope_name );

		p_repeat->counter_symbol = info.get_scope_path() + words[1];
	}

	//	log
	if( !is_analyze_phase ) {
		log.write_line_infomation( this->line_no, this->code_address, this->file_address, get_line() );
		log.write_message( "Enter scope: " + info.get_scope_path() );
		log.write_separator();
	}
	return check_all_fixed();
}

// --------------------------------------------------------------------
bool CZMA_PARSE_ENDR::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {
	CZMA_TEXT* p_text;
	int i;
	unsigned int sub_success_count;
	std::string s_scope;

	update_flags( &info, p_last_line );
	if( !this->is_loaded ) {
		p_repeat = info.p_repeat;
		if( p_repeat == nullptr ) {
			put_error( "Illegal command." );
			return false;
		}
		if( !p_repeat->is_counter_end_fixed ) {
			put_error( "REPEAT counter is not fixed." );
			return false;
		}
		for( i = 0; i < p_repeat->counter_end; i++ ) {
			info.dict[p_repeat->counter_symbol].i = i;
			p_text = new CZMA_TEXT;
			for( auto ins_p : p_repeat->m_text ) {
				p_text->m_text.push_back( CZMA_PARSE::create( info, ins_p->words, ins_p->get_file_name(), ins_p->get_line_no() ) );
			}
			this->text_list.push_back( p_text );
		}
		this->is_loaded = true;
		info.is_updated = true;
	}
	info.is_block_processing = false;
	for( i = 0; i < p_repeat->counter_end; i++ ) {
		info.dict[p_repeat->counter_symbol].i = i;
		p_last_line = this->text_list[i]->process( info, sub_success_count, p_last_line, !is_analyze_phase );
	}
	if( !this->is_data_fixed ) {
		for( auto p_text : this->text_list ) {
			for( auto p : p_text->m_text ) {
				this->is_data_fixed = this->is_data_fixed && p->is_fixed_code_size();
			}
		}
		if( this->is_data_fixed ) {
			info.is_updated = true;
		}
	}
	if( this->code_size == -1 ) {
		this->code_size = 0;
		for( auto p_text : this->text_list ) {
			for( auto p : p_text->m_text ) {
				if( this->code_size != -1 && p->is_fixed_code_size() ) {
					this->code_size = this->code_size + p->get_code_size();
				}
				else {
					this->code_size = -1;
				}
			}
		}
		if( this->code_size != -1 ) {
			info.is_updated = true;
		}
	}
	if( info.scope.size() == 0 ) {
		put_error( "Invalid command." );
		return false;
	}
	if( info.scope[info.scope.size() - 1] != p_repeat->scope_name ) {
		put_error( "Invalid command." );
		return false;
	}
	s_scope = info.get_scope_path();
	info.scope.pop_back();

	if( words.size() != 1 ) {
		put_error( "Too many parameters." );
		return false;
	}
	//	log
	if( !is_analyze_phase ) {
		log.write_message( "Exit scope: " + s_scope );
		log.write_separator();
	}
	return check_all_fixed();
}
