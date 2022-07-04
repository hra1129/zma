// --------------------------------------------------------------------
//	ZMA: CZMA_TEXT
// ====================================================================
//	2019/05/02	t.hara
// --------------------------------------------------------------------

#include "zma_text.hpp"
#include <fstream>
#include <iostream>

// ----------------------------------------------------------------
//	Constructor
// ----------------------------------------------------------------
CZMA_TEXT::CZMA_TEXT() {
	code_size = -1;
	next_code_address = -1;
}

// ----------------------------------------------------------------
//	Destructor
// ----------------------------------------------------------------
CZMA_TEXT::~CZMA_TEXT() {
	for( auto p: m_text ) { 
		delete p; 
	}
}

// ----------------------------------------------------------------
//	code size
// ----------------------------------------------------------------
void CZMA_TEXT::calc_code_size( void ) {

	code_size = 0;
	for( auto &p : this->m_text ){
		if( p->is_fixed_code_size() ){
			code_size += p->get_code_size();
		}
		else{
			code_size = -1;
			break;
		}
		if( p->is_fixed_next_code_address() ){
			next_code_address = p->get_next_code_address();
		}
		else{
			next_code_address = -1;
		}
	}
}

// ----------------------------------------------------------------
//	check data fixed
// ----------------------------------------------------------------
bool CZMA_TEXT::check_data_fixed( void ){

	for( auto &p : this->m_text ){
		if( !p->check_data_fixed() ){
			return false;
		}
	}
	return true;
}

// ----------------------------------------------------------------
//	File Load
// ----------------------------------------------------------------
bool CZMA_TEXT::load( CZMA_INFORMATION &info, const char* p_file_name ) {
	m_text.clear();
	std::string s;
	CZMA_PARSE *p_parse;
	int line_no;
	std::vector< std::string > words, labels;

	std::ifstream file;
	file.open( p_file_name );
	if( !file ) {
		return false;
	}
	line_no = 1;
	for( ;; line_no++) {
		if(file.bad()) {
			break;
		}
		if(!std::getline( file, s )) {
			break;
		}
		words = CZMA_PARSE::get_word_split( s );
		if( words.size() > 2 && ( (words[ 1 ] == ":") || (words[ 1 ] == "::") ) ){
			labels.resize( 2 );
			labels[ 0 ] = words[ 0 ];
			labels[ 1 ] = words[ 1 ];
			p_parse = CZMA_PARSE::create( info, labels, p_file_name, line_no );
			m_text.push_back( p_parse );
			words.erase( words.begin() );
			words.erase( words.begin() );
			p_parse = CZMA_PARSE::create( info, words, p_file_name, line_no );
			m_text.push_back( p_parse );
		}
		else{
			p_parse = CZMA_PARSE::create( info, words, p_file_name, line_no );
			m_text.push_back( p_parse );
		}
	}
	file.close();
	return true;
}

// --------------------------------------------------------------------
CZMA_PARSE *CZMA_TEXT::process( CZMA_INFORMATION &info, unsigned int &success_count, CZMA_PARSE *p_prev_line, bool output_mode ) {
	CZMA_PARSE* p_prev;
	bool result;
	int nest_count = 0;
	p_prev = p_prev_line;
	result = true;
	success_count = 0;
	std::vector<std::string> words;

	for( auto p = m_text.begin(); p != m_text.end(); ) {
		if( output_mode ) {
			(*p)->set_output_mode();
		}
		if( !info.is_block_processing ){
			//	�p�[�X�G���[���N�������s�̏ꍇ�A�ăp�[�X�����݂�
			if( ( *p )->is_parse_error() ){
				words = CZMA_PARSE::get_word_split( ( *p )->get_line() );
				CZMA_PARSE *p_parse = CZMA_PARSE::create( info, words, ( *p )->get_file_name(), ( *p )->get_line_no() );
				if( !( p_parse->is_parse_error() ) ){
					p = m_text.erase( p );
					p = m_text.insert( p, p_parse );
				}
				else{
					delete p_parse;
				}
			}
			//	�u���b�N�̊O���̏���
			if( ( *p )->process( info, p_prev ) ){
				success_count++;
			}
			p_prev = ( *p );
			p++;
		}
		else {
			//	�u���b�N�̒��̏���
			if( (*p)->words.size() >= 1 && info.block_end_table.count( (*p)->words[0] ) ) {
				//	�u���b�N�����L���𔭌�
				if( (*p)->words[0] == "ENDR" || (*p)->words[0] == "ENDM" ) {
					//	���� ENDR, ENDM �̏���
					if( nest_count ) {
						//	�u���b�N���̃u���b�N�������̂Ńl�X�g�������炷����
						nest_count--;
						info.p_text->push_back( *p );
						p = m_text.erase( p );
						continue;
					}
				}
				if( nest_count == 0 ) {
					if( info.block_type != info.block_end_table[(*p)->words[0]] ) {
						//	���ڃu���b�N�̎�ނƈقȂ�u����L���v�𔭌�
						(*p)->put_structure_error( "Invalid block pair." );
						p_prev = (*p);
						p++;
						continue;
					}
					//	�u����L���v�̏���
					if( (*p)->process( info, p_prev ) ) {
						success_count++;
					}
					p_prev = (*p);
					p++;
				}
				else {
					info.p_text->push_back( *p );
					p = m_text.erase( p );
					continue;
				}
			}
			else {
				if( (*p)->words.size() >= 1 && info.block_begin_table.count( (*p)->words[0] ) ) {
					//	�u���b�N�̓����Ƀu���b�N�̊J�n�𔭌�
					if( (*p)->words[0] == "REPEAT" ) {
						nest_count++;
					}
				}
				else if( (*p)->words.size() >= 2 && (*p)->words[1] == "MACRO" ) {
					//	�u���b�N�̓����Ƀ}�N���錾�𔭌�
					(*p)->put_structure_error( "MACRO cannot define in MACRO/REPEAT/IF block." );
					p_prev = (*p);
					p++;
					continue;
				}
				info.p_text->push_back( *p );
				p = m_text.erase( p );
			}
		}
	}
	return p_prev;
}

// --------------------------------------------------------------------
void CZMA_TEXT::analyze_structure( void ){
	std::vector<CZMA_PARSE *>::iterator pp_current = this->m_text.begin();

	while( pp_current != this->m_text.end() ){
		(*pp_current)->block_structure( this->m_text, pp_current );
		pp_current++;
	}
}

// --------------------------------------------------------------------
bool CZMA_TEXT::all_process( CZMA_INFORMATION& info ) {
	unsigned int success_count;
	CZMA_PARSE* p_last_line;

	this->analyze_structure();
	if( CZMA_PARSE::get_number_of_errors() ){
		return false;
	}
	for( ; ; ) {
		info.clear();
		p_last_line = this->process( info, success_count, nullptr, false );
		if( info.is_block_processing ) {
			p_last_line->set_output_mode();
			p_last_line->put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::BLOCK_PROCESSING_IS_NOT_CLOSED ) );
			break;
		}
		if( !info.is_updated ) {
			break;
		}
	}
	info.clear();
	p_last_line = this->process( info, success_count, nullptr, true );
	if( p_last_line == nullptr || ((p_last_line->get_file_address() == 0) && (p_last_line->get_code_size() == 0)) ) {
		std::cerr << "Code is not found.\n";
		return false;
	}
	if( info.scope.size() > 0 ) {
		p_last_line->put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::SCOPE_IS_NOT_CLOSED ) );
		return false;
	}
	if( CZMA_PARSE::get_number_of_errors() ) {
		std::cerr << "Found " << CZMA_PARSE::get_number_of_errors() << " error(s).\n";
		return false;
	}
	return true;
}

// --------------------------------------------------------------------
bool CZMA_TEXT::write( CZMA_INFORMATION& info, std::ofstream* f ) {
	bool result;

	result = true;
	for( auto &p: m_text ) {
		result = result && p->write_output_and_log( info, f );
	}
	if( info.output_type == CZMA_INFORMATION::OUTPUT_TYPE::CZMA_INTELHEX ){
		info.hexfile.flush( *f );
	}
	return result;
}

// --------------------------------------------------------------------
bool CZMA_TEXT::save( CZMA_INFORMATION& info, const char* p_file_name ) {
	std::ofstream f;

	f.open( p_file_name, std::ios::out | std::ios::binary );
	bool result = this->write( info, &f );
	info.write();
	return result;
}
