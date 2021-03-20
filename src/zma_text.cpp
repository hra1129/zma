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
	code_size = 0;
	next_code_address = 0;
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
//	File Load
// ----------------------------------------------------------------
bool CZMA_TEXT::load( CZMA_INFORMATION &info, const char* p_file_name ) {
	m_text.clear();
	std::string s;
	CZMA_PARSE *p_parse;
	int line_no;

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
		p_parse = CZMA_PARSE::create( info, s, p_file_name, line_no );
		m_text.push_back( p_parse );
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
	for( auto p = m_text.begin(); p != m_text.end(); ) {
		if( output_mode ) {
			(*p)->set_output_mode();
		}
		if( info.is_block_processing ) {
			//	ブロックの中の処理
			if( (*p)->words.size() >= 1 && info.block_end_table.count( (*p)->words[0] ) ) {
				//	ブロックを閉じる記号を発見
				if( (*p)->words[0] == "ENDR" || (*p)->words[0] == "ENDM" || (*p)->words[0] == "ENDIF" ) {
					//	特に ENDR, ENDM, ENDIF の処理
					if( nest_count ) {
						//	ブロック内のブロックだったのでネスト数を減らすだけ
						nest_count--;
						info.p_text->push_back( *p );
						p = m_text.erase( p );
						continue;
					}
				}
				if( nest_count == 0 ) {
					if( info.block_type != info.block_end_table[(*p)->words[0]] ) {
						//	着目ブロックの種類と異なる「閉じる記号」を発見
						(*p)->put_structure_error( "Invalid block pair." );
						p_prev = (*p);
						p++;
						continue;
					}
					//	「閉じる記号」の処理
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
					//	ブロックの内側にブロックの開始を発見
					if( (*p)->words[0] == "REPEAT" || (*p)->words[0] == "IF" ) {
						nest_count++;
					}
				}
				else if( (*p)->words.size() >= 2 && (*p)->words[1] == "MACRO" ) {
					//	ブロックの内側にマクロ宣言を発見
					(*p)->put_structure_error( "MACRO cannot define in MACRO/REPEAT/IF block." );
					p_prev = (*p);
					p++;
					continue;
				}
				info.p_text->push_back( *p );
				p = m_text.erase( p );
			}
		}
		else {
			//	パースエラーを起こした行の場合、再パースを試みる
			if( (*p)->is_parse_error() ) {
				CZMA_PARSE *p_parse = CZMA_PARSE::create( info, (*p)->get_line(), (*p)->get_file_name(), (*p)->get_line_no() );
				if( !(p_parse->is_parse_error()) ) {
					p = m_text.erase( p );
					p = m_text.insert( p, p_parse );
				}
				else {
					delete p_parse;
				}
			}
			//	ブロックの外側の処理
			if( (*p)->process( info, p_prev ) ) {
				success_count++;
			}
			p_prev = (*p);
			p++;
		}
	}
	return p_prev;
}

// --------------------------------------------------------------------
bool CZMA_TEXT::all_process( CZMA_INFORMATION& info ) {
	unsigned int success_count;
	CZMA_PARSE* p_last_line;

	for( ; ; ) {
		success_count = 0;
		info.scope.clear();
		info.is_updated = false;
		info.is_block_processing = false;
		info.auto_label_index = 0;
		p_last_line = this->process( info, success_count, nullptr, false );
		if( info.is_block_processing ) {
			p_last_line->set_output_mode();
			p_last_line->put_error( "Block processing is not close." );
			break;
		}
		if( !info.is_updated ) {
			break;
		}
	}
	info.scope.clear();
	info.is_block_processing = false;
	info.auto_label_index = 0;
	p_last_line = this->process( info, success_count, nullptr, true );
	if( p_last_line == nullptr ) {
		std::cerr << "Code is not found.\n";
		return false;
	}
	if( info.scope.size() > 0 ) {
		p_last_line->put_error( "Scope is not closed." );
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
	for( auto p: m_text ) {
		result = result & p->write( info, f );
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
