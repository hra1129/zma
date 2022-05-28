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
class CZMA_PARSE_ERROR: public CZMA_PARSE {
public:
	CZMA_REPEAT_T* p_repeat = nullptr;

	using CZMA_PARSE::CZMA_PARSE;
	bool process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line = nullptr ) override;
	virtual bool is_parse_error( void ) {
		return true;
	}
};

// --------------------------------------------------------------------
class CZMA_PARSE_REPEAT: public CZMA_PARSE {
public:
	CZMA_REPEAT_T *p_repeat = nullptr;

	using CZMA_PARSE::CZMA_PARSE;
	bool process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line = nullptr ) override;
};

// --------------------------------------------------------------------
class CZMA_PARSE_INCLUDE: public CZMA_PARSE {
public:
	CZMA_TEXT text;
	bool is_loaded = false;
	std::string s_file_name;

	using CZMA_PARSE::CZMA_PARSE;
	bool process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line = nullptr ) override;
	bool write( CZMA_INFORMATION& info, std::ofstream* f ) override;
};

// --------------------------------------------------------------------
bool CZMA_PARSE_INCLUDE::write( CZMA_INFORMATION& info, std::ofstream* f ) {

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
class CZMA_PARSE_ENDR: public CZMA_PARSE {
public:
	std::vector< CZMA_TEXT* > text_list;
	CZMA_REPEAT_T* p_repeat = nullptr;
	bool is_loaded = false;

	using CZMA_PARSE::CZMA_PARSE;
	bool process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line = nullptr ) override;
	bool write( CZMA_INFORMATION& info, std::ofstream* f ) override;
};

// --------------------------------------------------------------------
class CZMA_PARSE_ENDM: public CZMA_PARSE {
public:
	CZMA_MACRO* p_macro = nullptr;
	bool is_loaded = false;

	using CZMA_PARSE::CZMA_PARSE;
	bool process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line = nullptr ) override;
};

// --------------------------------------------------------------------
bool CZMA_PARSE_ENDR::write( CZMA_INFORMATION& info, std::ofstream* f ) {
	bool result;

	info.log << "\trepeat begin" << std::endl;
	for( auto line : log ) {
	}
	result = true;
	for( auto text : this->text_list ) {
		result = result & text->write( info, f );
	}
	info.log << "\trepeat end" << std::endl;
	for( auto line : log ) {
		info.log << line << std::endl;
		info.log << std::endl;
	}
	return result;
}

// --------------------------------------------------------------------
class CZMA_PARSE_MACRO_INS: public CZMA_PARSE {
public:
	CZMA_TEXT text;
	bool is_loaded = false;

	using CZMA_PARSE::CZMA_PARSE;
	bool process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line = nullptr ) override;
	bool write( CZMA_INFORMATION& info, std::ofstream* f ) override;
};

// --------------------------------------------------------------------
bool CZMA_PARSE_MACRO_INS::write( CZMA_INFORMATION& info, std::ofstream* f ) {
	bool result = true;

	for( auto line : log ) {
		info.log << line << std::endl;
	}
	text.write( info, f );
	return result;
}

// --------------------------------------------------------------------
int CZMA_PARSE::number_of_error = 0;

// --------------------------------------------------------------------
static std::map< std::string, CZMA_COMMAND_TYPE > command_list = {
	{ "ALIGN", CZMA_COMMAND_TYPE::CZMA_ALIGN },
	{ "SPACE", CZMA_COMMAND_TYPE::CZMA_SPACE },
	{ "REPEAT", CZMA_COMMAND_TYPE::CZMA_REPEAT },
	{ "ENDR", CZMA_COMMAND_TYPE::CZMA_ENDR },
	{ "ENDM", CZMA_COMMAND_TYPE::CZMA_ENDM },
	{ "IF", CZMA_COMMAND_TYPE::CZMA_IF },
	{ "ELSEIF", CZMA_COMMAND_TYPE::CZMA_ELSEIF },
	{ "ELSE", CZMA_COMMAND_TYPE::CZMA_ELSE },
	{ "ENDIF", CZMA_COMMAND_TYPE::CZMA_ENDIF },
	{ "ORG", CZMA_COMMAND_TYPE::CZMA_ORG },
	{ "INCLUDE", CZMA_COMMAND_TYPE::CZMA_INCLUDE },
	{ "ADD_INCLUDE_PATH", CZMA_COMMAND_TYPE::CZMA_ADD_INCLUDE_PATH },
	{ "ERROR", CZMA_COMMAND_TYPE::CZMA_USER_ERROR },
	{ "MESSAGE", CZMA_COMMAND_TYPE::CZMA_USER_MESSAGE },
	{ "SCOPE", CZMA_COMMAND_TYPE::CZMA_SCOPE },
	{ "ENDSCOPE", CZMA_COMMAND_TYPE::CZMA_ENDSCOPE },
	{ "BINARY_LINK", CZMA_COMMAND_TYPE::CZMA_BINARY_LINK },
	{ "DEFB", CZMA_COMMAND_TYPE::CZMA_DEFB },
	{ "DEFW", CZMA_COMMAND_TYPE::CZMA_DEFW },
	{ "DEFD", CZMA_COMMAND_TYPE::CZMA_DEFD },
	{ "DEFS", CZMA_COMMAND_TYPE::CZMA_DEFS },
	{ "DB", CZMA_COMMAND_TYPE::CZMA_DEFB },
	{ "DW", CZMA_COMMAND_TYPE::CZMA_DEFW },
	{ "DD", CZMA_COMMAND_TYPE::CZMA_DEFD },
	{ "DS", CZMA_COMMAND_TYPE::CZMA_DEFS },
	{ "LD", CZMA_COMMAND_TYPE::CZMA_LD },
	{ "LDI", CZMA_COMMAND_TYPE::CZMA_LDI },
	{ "LDIR", CZMA_COMMAND_TYPE::CZMA_LDIR },
	{ "LDD", CZMA_COMMAND_TYPE::CZMA_LDD },
	{ "LDDR", CZMA_COMMAND_TYPE::CZMA_LDDR },
	{ "EX", CZMA_COMMAND_TYPE::CZMA_EX },
	{ "EXX", CZMA_COMMAND_TYPE::CZMA_EXX },
	{ "PUSH", CZMA_COMMAND_TYPE::CZMA_PUSH },
	{ "POP", CZMA_COMMAND_TYPE::CZMA_POP },
	{ "RLCA", CZMA_COMMAND_TYPE::CZMA_RLCA },
	{ "RLA", CZMA_COMMAND_TYPE::CZMA_RLA },
	{ "RLC", CZMA_COMMAND_TYPE::CZMA_RLC },
	{ "RL", CZMA_COMMAND_TYPE::CZMA_RL },
	{ "RRCA", CZMA_COMMAND_TYPE::CZMA_RRCA },
	{ "RRA", CZMA_COMMAND_TYPE::CZMA_RRA },
	{ "RRC", CZMA_COMMAND_TYPE::CZMA_RRC },
	{ "RR", CZMA_COMMAND_TYPE::CZMA_RR },
	{ "SLA", CZMA_COMMAND_TYPE::CZMA_SLA },
	{ "SRA", CZMA_COMMAND_TYPE::CZMA_SRA },
	{ "SRL", CZMA_COMMAND_TYPE::CZMA_SRL },
	{ "SLL", CZMA_COMMAND_TYPE::CZMA_SLL },
	{ "ADD", CZMA_COMMAND_TYPE::CZMA_ADD },
	{ "ADC", CZMA_COMMAND_TYPE::CZMA_ADC },
	{ "INC", CZMA_COMMAND_TYPE::CZMA_INC },
	{ "SUB", CZMA_COMMAND_TYPE::CZMA_SUB },
	{ "SBC", CZMA_COMMAND_TYPE::CZMA_SBC },
	{ "DEC", CZMA_COMMAND_TYPE::CZMA_DEC },
	{ "AND", CZMA_COMMAND_TYPE::CZMA_AND },
	{ "OR", CZMA_COMMAND_TYPE::CZMA_OR },
	{ "XOR", CZMA_COMMAND_TYPE::CZMA_XOR },
	{ "CPL", CZMA_COMMAND_TYPE::CZMA_CPL },
	{ "NEG", CZMA_COMMAND_TYPE::CZMA_NEG },
	{ "CCF", CZMA_COMMAND_TYPE::CZMA_CCF },
	{ "SCF", CZMA_COMMAND_TYPE::CZMA_SCF },
	{ "BIT", CZMA_COMMAND_TYPE::CZMA_BIT },
	{ "RES", CZMA_COMMAND_TYPE::CZMA_RES },
	{ "SET", CZMA_COMMAND_TYPE::CZMA_SET },
	{ "CPI", CZMA_COMMAND_TYPE::CZMA_CPI },
	{ "CPIR", CZMA_COMMAND_TYPE::CZMA_CPIR },
	{ "CPD", CZMA_COMMAND_TYPE::CZMA_CPD },
	{ "CPDR", CZMA_COMMAND_TYPE::CZMA_CPDR },
	{ "CP", CZMA_COMMAND_TYPE::CZMA_CP },
	{ "JP", CZMA_COMMAND_TYPE::CZMA_JP },
	{ "JR", CZMA_COMMAND_TYPE::CZMA_JR },
	{ "DJNZ", CZMA_COMMAND_TYPE::CZMA_DJNZ },
	{ "CALL", CZMA_COMMAND_TYPE::CZMA_CALL },
	{ "RET", CZMA_COMMAND_TYPE::CZMA_RET },
	{ "RETI", CZMA_COMMAND_TYPE::CZMA_RETI },
	{ "RETN", CZMA_COMMAND_TYPE::CZMA_RETN },
	{ "RST", CZMA_COMMAND_TYPE::CZMA_RST },
	{ "NOP", CZMA_COMMAND_TYPE::CZMA_NOP },
	{ "HALT", CZMA_COMMAND_TYPE::CZMA_HALT },
	{ "DI", CZMA_COMMAND_TYPE::CZMA_DI },
	{ "EI", CZMA_COMMAND_TYPE::CZMA_EI },
	{ "IM0", CZMA_COMMAND_TYPE::CZMA_IM0 },
	{ "IM1", CZMA_COMMAND_TYPE::CZMA_IM1 },
	{ "IM2", CZMA_COMMAND_TYPE::CZMA_IM2 },
	{ "IN", CZMA_COMMAND_TYPE::CZMA_IN },
	{ "INI", CZMA_COMMAND_TYPE::CZMA_INI },
	{ "INIR", CZMA_COMMAND_TYPE::CZMA_INIR },
	{ "IND", CZMA_COMMAND_TYPE::CZMA_IND },
	{ "INDR", CZMA_COMMAND_TYPE::CZMA_INDR },
	{ "OUT", CZMA_COMMAND_TYPE::CZMA_OUT },
	{ "OUTI", CZMA_COMMAND_TYPE::CZMA_OUTI },
	{ "OTIR", CZMA_COMMAND_TYPE::CZMA_OTIR },
	{ "OUTD", CZMA_COMMAND_TYPE::CZMA_OUTD },
	{ "OTDR", CZMA_COMMAND_TYPE::CZMA_OTDR },
	{ "DAA", CZMA_COMMAND_TYPE::CZMA_DAA },
	{ "RLD", CZMA_COMMAND_TYPE::CZMA_RLD },
	{ "RRD", CZMA_COMMAND_TYPE::CZMA_RRD },
	{ "MULUB", CZMA_COMMAND_TYPE::CZMA_MULUB },
	{ "MULUW", CZMA_COMMAND_TYPE::CZMA_MULUW },
};

// --------------------------------------------------------------------
#define OPE_CASE( operation )																			\
	case CZMA_COMMAND_TYPE::CZMA_##operation:																			\
		return reinterpret_cast<CZMA_PARSE*> (new CZMA_PARSE_##operation( words, p_file_name, line_no ))

// --------------------------------------------------------------------
CZMA_PARSE* CZMA_PARSE::create( CZMA_INFORMATION& info, std::vector<std::string> words, const char* p_file_name, int line_no ) {

	if( words.size() == 0 ) {
		return reinterpret_cast<CZMA_PARSE*> (new CZMA_PARSE_BLANK( words, p_file_name, line_no ));
	}
	if( words.size() == 2 && words[1] == ":" ) {
		return reinterpret_cast<CZMA_PARSE*> (new CZMA_PARSE_LABEL( words, p_file_name, line_no ));
	}
	if( words.size() == 2 && words[1] == "::" ) {
		return reinterpret_cast<CZMA_PARSE*> (new CZMA_PARSE_GLOBAL_LABEL( words, p_file_name, line_no ));
	}
	if( words.size() >= 3 && words[1] == "=" ) {
		return reinterpret_cast<CZMA_PARSE*> (new CZMA_PARSE_SYMBOL( words, p_file_name, line_no ));
	}
	if( words.size() >= 3 && words[1] == ":=" ) {
		return reinterpret_cast<CZMA_PARSE*> (new CZMA_PARSE_GLOBAL_SYMBOL( words, p_file_name, line_no ));
	}
	if( words.size() >= 2 && words[1] == "MACRO" ) {
		info.macro_list[words[0]] = nullptr;
		return reinterpret_cast<CZMA_PARSE*> (new CZMA_PARSE_MACRO( words, p_file_name, line_no ));
	}
	if( words.size() >= 1 && info.macro_list.count( words[0] ) ) {
		return reinterpret_cast<CZMA_PARSE*> (new CZMA_PARSE_MACRO_INS( words, p_file_name, line_no ));
	}
	switch( command_list[words[0]] ) {
		OPE_CASE( ORG );
		OPE_CASE( INCLUDE );
		OPE_CASE( ADD_INCLUDE_PATH );
		OPE_CASE( ALIGN );
		OPE_CASE( SPACE );
		OPE_CASE( REPEAT );
		OPE_CASE( ENDR );
		OPE_CASE( ENDM );
		OPE_CASE( IF );
		OPE_CASE( ELSEIF );
		OPE_CASE( ELSE );
		OPE_CASE( ENDIF );
		OPE_CASE( USER_ERROR );
		OPE_CASE( USER_MESSAGE );
		OPE_CASE( SCOPE );
		OPE_CASE( ENDSCOPE );
		OPE_CASE( BINARY_LINK );
		OPE_CASE( DEFB );
		OPE_CASE( DEFW );
		OPE_CASE( DEFD );
		OPE_CASE( DEFS );
		OPE_CASE( LD );
		OPE_CASE( PUSH );
		OPE_CASE( POP );
		OPE_CASE( EX );
		OPE_CASE( EXX );
		OPE_CASE( LDI );
		OPE_CASE( LDIR );
		OPE_CASE( LDD );
		OPE_CASE( LDDR );
		OPE_CASE( RLCA );
		OPE_CASE( RLA );
		OPE_CASE( RLC );
		OPE_CASE( RL );
		OPE_CASE( RRCA );
		OPE_CASE( RRA );
		OPE_CASE( RRC );
		OPE_CASE( RR );
		OPE_CASE( SLA );
		OPE_CASE( SRA );
		OPE_CASE( SRL );
		OPE_CASE( SLL );
		OPE_CASE( ADD );
		OPE_CASE( ADC );
		OPE_CASE( INC );
		OPE_CASE( SUB );
		OPE_CASE( SBC );
		OPE_CASE( DEC );
		OPE_CASE( AND );
		OPE_CASE( OR );
		OPE_CASE( XOR );
		OPE_CASE( CPL );
		OPE_CASE( NEG );
		OPE_CASE( CCF );
		OPE_CASE( SCF );
		OPE_CASE( BIT );
		OPE_CASE( RES );
		OPE_CASE( SET );
		OPE_CASE( CPI );
		OPE_CASE( CPIR );
		OPE_CASE( CPD );
		OPE_CASE( CPDR );
		OPE_CASE( CP );
		OPE_CASE( JP );
		OPE_CASE( JR );
		OPE_CASE( DJNZ );
		OPE_CASE( CALL );
		OPE_CASE( RET );
		OPE_CASE( RETI );
		OPE_CASE( RETN );
		OPE_CASE( RST );
		OPE_CASE( NOP );
		OPE_CASE( HALT );
		OPE_CASE( EI );
		OPE_CASE( DI );
		OPE_CASE( IM0 );
		OPE_CASE( IM1 );
		OPE_CASE( IM2 );
		OPE_CASE( IN );
		OPE_CASE( INI );
		OPE_CASE( INIR );
		OPE_CASE( IND );
		OPE_CASE( INDR );
		OPE_CASE( OUT );
		OPE_CASE( OUTI );
		OPE_CASE( OTIR );
		OPE_CASE( OUTD );
		OPE_CASE( OTDR );
		OPE_CASE( DAA );
		OPE_CASE( RLD );
		OPE_CASE( RRD );
		OPE_CASE( MULUB );
		OPE_CASE( MULUW );
	default:
		break;
	}
	return reinterpret_cast<CZMA_PARSE*> (new CZMA_PARSE_ERROR( words, p_file_name, line_no ));
}

// --------------------------------------------------------------------
void CZMA_PARSE::log_data_dump( void ) {
	int address, count;
	std::stringstream line;
	address = this->get_code_address();
	count = 0;
	line.str("");
	for( auto d : data ) {
		if( count == 0 ) {
			line << std::hex << std::setw( 6 ) << std::setfill( '0' ) << address << ":";
		}
		line << " " << std::hex << std::setw( 2 ) << std::setfill( '0' ) << (int)d;
		address++;
		count++;
		if( count == 8 ) {
			log.push_back( line.str() );
			line.str( "" );
			count = 0;
		}
	}
	if( count != 0 ) {
		log.push_back( line.str() );
	}
}

// --------------------------------------------------------------------
std::string CZMA_PARSE::get_line( void ) {
	std::string r, ss;

	r = "";
	for( auto s : words ) {
		if( s.size() > 0 && s[0] == '\"' ) {
			ss = "\"";
			for( int i = 1; i < (int)s.size(); i++ ) {
				switch( s[i] ) {
				case '\a':	ss = ss + "\\a";	break;
				case '\b':	ss = ss + "\\b";	break;
				case '\f':	ss = ss + "\\f";	break;
				case '\n':	ss = ss + "\\n";	break;
				case '\r':	ss = ss + "\\r";	break;
				case '\t':	ss = ss + "\\t";	break;
				case '\\':	ss = ss + "\\\\";	break;
				case '\'':	ss = ss + "\\'";	break;
				case '\"':	ss = ss + "\\\"";	break;
				default:	ss = ss + s[i];		break;
				}
			}
			ss = ss + '\"';
		}
		else {
			ss = s;
		}
		if( r == "" ) {
			r = ss;
		}
		else {
			r = r + " " + ss;
		}
	}
	return r;
}

// --------------------------------------------------------------------
CZMA_PARSE* CZMA_PARSE::create( CZMA_INFORMATION& info, std::string s, const char* p_file_name, int line_no ) {
	std::vector<std::string> words;

	words = CZMA_PARSE::get_word_split( s );
	return create( info, words, p_file_name, line_no );
}

// --------------------------------------------------------------------
bool CZMA_PARSE_ENDM::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	info.is_block_processing = false;
	this->is_data_fixed = true;
	this->set_code_size( &info, 0 );
	return check_all_fixed();
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
			//	REPEAT 変数名 , 値 で、少なくとも 4[word] なければならない
			put_error( "Illegal parameter." );
			return false;
		}
		if( words[2] != "," ) {
			put_error( "Illegal parameter." );
			return false;
		}

		info.block_type = info.CZMA_INFO_REPEAT_BLOCK;
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
		log.push_back( "[" + get_line() + "]" );
		log.push_back( "\tScope path: " + info.get_scope_path() );
		log.push_back( "" );
	}
	return check_all_fixed();
}

// --------------------------------------------------------------------
bool CZMA_PARSE_ENDR::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {
	CZMA_TEXT* p_text;
	int i;
	unsigned int sub_success_count;

	update_flags( &info, p_last_line );
	if( !this->is_loaded ) {
		p_repeat = info.p_repeat;
		if( p_repeat == nullptr ) {
			put_error( "Illegal ENDR." );
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
				this->is_data_fixed = this->is_data_fixed && p->get_fixed_code_size();
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
				if( this->code_size != -1 && p->get_fixed_code_size() ) {
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
		put_error( "Scope of ENDR does not exist." );
		return false;
	}
	if( info.scope[info.scope.size() - 1] != p_repeat->scope_name ) {
		put_error( "Scope of ENDR does not exist." );
		return false;
	}
	info.scope.pop_back();

	if( words.size() != 1 ) {
		put_error( "ENDR is not need parameters." );
		return false;
	}
	//	log
	if( !is_analyze_phase ) {
		log.push_back( "\tScope path: " + info.get_scope_path() );
		log.push_back( "" );
	}
	return check_all_fixed();
}

// --------------------------------------------------------------------
bool CZMA_PARSE_MACRO_INS::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {
	CZMA_MACRO* p_macro;
	std::map< std::string, std::vector< std::string > > argument;
	std::vector< std::string > parameter, insert_line;
	std::string replace_name, arg_name;
	int i, j, id;
	unsigned int success_count;
	bool result = true;
	update_flags( &info, p_last_line );
	if( !this->is_loaded ) {
		p_macro = info.macro_list[words[0]];	//	※必ず存在する
		//	引数を取り込む
		id = 0;
		for( i = 1; i < (int)words.size(); i++ ) {
			parameter.clear();
			if( id >= (int)p_macro->parameter_name_list.size() ) {
				put_error( "Too many arguments for " + words[0] + "." );
				return false;
			}
			if( p_macro->parameter_name_list[id].is_through ) {
				arg_name = "\"";
				for( j = i; j < ( int) words.size() && words[j] != ","; j++ ) {
					arg_name = arg_name + words[j];
					if( (j + 1) < ( int) words.size() && words[j + 1] != "," ) {
						arg_name = arg_name + " ";
					}
				}
				parameter.push_back( arg_name );
			}
			else {
				for( j = i; j < ( int) words.size() && words[j] != ","; j++ ) {
					parameter.push_back( words[j] );
				}
			}
			argument[p_macro->parameter_name_list[id].name] = parameter;		//	argument[ 引数名 ] = 実際の引数
			i = j;
			id++;
		}
		if( id != (int)p_macro->parameter_name_list.size() ) {
			put_error( "Mismatched number of arguments." );
			return false;
		}
		//	m_text に macro の展開内容をコピーする
		for( auto p : p_macro->m_text ) {
			insert_line = p->words;
			for( auto word = insert_line.begin(); word != insert_line.end(); ) {
				replace_name = *word;
				if( argument.count( replace_name ) ) {
					//	マクロの仮引数を見つけた場合、指定されている式に置き換える
					word = insert_line.erase( word );
					for( auto insert_word : argument[replace_name] ) {
						word = insert_line.insert( word, insert_word );
						++word;
					}
				}
				else {
					++word;
				}
			}
			text.m_text.push_back( CZMA_PARSE::create( info, insert_line, this->p_file_name, this->line_no ) );
		}
		this->is_loaded = true;
		info.is_updated = true;
	}
	info.scope.push_back( "@MACRO" + std::to_string( info.get_auto_label_index() ) );
	//	log
	if( !is_analyze_phase ) {
		log.push_back( "((" + get_line() + "))" );
		log.push_back( "\tScope path: " + info.get_scope_path() );
	}
	p_last_line = text.process( info, success_count, p_last_line, !this->is_analyze_phase );
	if( !this->is_data_fixed ) {
		for( auto p : text.m_text ) {
			this->is_data_fixed = this->is_data_fixed && p->get_fixed_code_size();
		}
		if( this->is_data_fixed ) {
			info.is_updated = true;
		}
	}
	if( this->code_size == -1 ) {
		this->code_size = 0;
		for( auto p : text.m_text ) {
			if( this->code_size != -1 && p->get_fixed_code_size() ) {
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
	if( info.scope.size() > 0 ) {
		info.scope.pop_back();
	}
	this->next_code_address = p_last_line->get_next_code_address();
	return result && check_all_fixed();
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
		log.push_back( "[\tINCLUDE \"" + this->s_file_name + "\"]" );
	}
	if( p_last_line->get_fixed_file_address() && p_last_line->get_fixed_code_size() ) {
		this->file_address = p_last_line->get_file_address() + p_last_line->get_code_size();
	}
	p_last_line = this->text.process( info, success_count, p_last_line, !this->is_analyze_phase );
	if( p_last_line->get_fixed_next_code_address() ) {
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
			if( this->code_size != -1 && p->get_fixed_code_size() ) {
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

// --------------------------------------------------------------------
bool CZMA_PARSE_ERROR::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	put_error( "Illegal command" );
	return false;
}
