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

CLASS_CZMA_PARSE( EX );
CLASS_CZMA_PARSE( EXX );
CLASS_CZMA_PARSE( PUSH );
CLASS_CZMA_PARSE( POP );
CLASS_CZMA_PARSE( RLCA );
CLASS_CZMA_PARSE( RLA );
CLASS_CZMA_PARSE( RLC );
CLASS_CZMA_PARSE( RL );
CLASS_CZMA_PARSE( RRCA );
CLASS_CZMA_PARSE( RRA );
CLASS_CZMA_PARSE( RRC );
CLASS_CZMA_PARSE( RR );
CLASS_CZMA_PARSE( SLA );
CLASS_CZMA_PARSE( SRA );
CLASS_CZMA_PARSE( SRL );
CLASS_CZMA_PARSE( SLL );
CLASS_CZMA_PARSE( ADD );
CLASS_CZMA_PARSE( ADC );
CLASS_CZMA_PARSE( INC );
CLASS_CZMA_PARSE( SUB );
CLASS_CZMA_PARSE( SBC );
CLASS_CZMA_PARSE( DEC );
CLASS_CZMA_PARSE( AND );
CLASS_CZMA_PARSE( OR );
CLASS_CZMA_PARSE( XOR );
CLASS_CZMA_PARSE( CPL );
CLASS_CZMA_PARSE( NEG );
CLASS_CZMA_PARSE( CCF );
CLASS_CZMA_PARSE( SCF );
CLASS_CZMA_PARSE( BIT );
CLASS_CZMA_PARSE( SET );
CLASS_CZMA_PARSE( RES );
CLASS_CZMA_PARSE( CPI );
CLASS_CZMA_PARSE( CPIR );
CLASS_CZMA_PARSE( CPD );
CLASS_CZMA_PARSE( CPDR );
CLASS_CZMA_PARSE( CP );
CLASS_CZMA_PARSE( JP );
CLASS_CZMA_PARSE( JR );
CLASS_CZMA_PARSE( DJNZ );
CLASS_CZMA_PARSE( CALL );
CLASS_CZMA_PARSE( RET );
CLASS_CZMA_PARSE( RETI );
CLASS_CZMA_PARSE( RETN );
CLASS_CZMA_PARSE( RST );
CLASS_CZMA_PARSE( NOP );
CLASS_CZMA_PARSE( HALT );
CLASS_CZMA_PARSE( DI );
CLASS_CZMA_PARSE( EI );
CLASS_CZMA_PARSE( IM0 );
CLASS_CZMA_PARSE( IM1 );
CLASS_CZMA_PARSE( IM2 );
CLASS_CZMA_PARSE( IN );
CLASS_CZMA_PARSE( INI );
CLASS_CZMA_PARSE( INIR );
CLASS_CZMA_PARSE( IND );
CLASS_CZMA_PARSE( INDR );
CLASS_CZMA_PARSE( OUT );
CLASS_CZMA_PARSE( OUTI );
CLASS_CZMA_PARSE( OTIR );
CLASS_CZMA_PARSE( OUTD );
CLASS_CZMA_PARSE( OTDR );
CLASS_CZMA_PARSE( DAA );
CLASS_CZMA_PARSE( RLD );
CLASS_CZMA_PARSE( RRD );
CLASS_CZMA_PARSE( MULUB );
CLASS_CZMA_PARSE( MULUW );
CLASS_CZMA_PARSE( IF );

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
class CZMA_PARSE_ELSEIF: public CZMA_PARSE_IF {
public:
	using CZMA_PARSE_IF::CZMA_PARSE_IF;
	bool process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line = nullptr ) override;
};

// --------------------------------------------------------------------
class CZMA_PARSE_ELSE: public CZMA_PARSE_IF {
public:
	using CZMA_PARSE_IF::CZMA_PARSE_IF;
	bool process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line = nullptr ) override;
};

// --------------------------------------------------------------------
class CZMA_PARSE_ENDIF: public CZMA_PARSE {
public:
	CZMA_IF_T* p_if = nullptr;
	bool is_loaded = false;

	using CZMA_PARSE::CZMA_PARSE;
	bool process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line = nullptr ) override;
	bool write( CZMA_INFORMATION& info, std::ofstream* f ) override;
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
		info.block_type				= info.CZMA_INFO_IF_BLOCK;
		info.is_block_processing	= true;
		info.p_if					= p_if;
		info.p_text					= &(p_if_sub->p_text->m_text);
		this->is_data_fixed			= true;
		this->set_code_size( &info, 0 );
	}
	//	log
	if( !is_analyze_phase ) {
		log.push_back( "[" + get_line() + "]" );
		log.push_back( "" );
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
		if( !info.is_block_processing || info.block_type != info.CZMA_INFO_IF_BLOCK ) {
			put_error( "There is an ELSEIF description at an incorrect position." );
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
		log.push_back( "[" + get_line() + "]" );
		log.push_back( "" );
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
		if( !info.is_block_processing || info.block_type != info.CZMA_INFO_IF_BLOCK ) {
			put_error( "There is an ELSE description at an incorrect position." );
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
		put_error( "ELSE is not need parameters." );
		return false;
	}
	//	log
	if( !is_analyze_phase ) {
		log.push_back( "[" + get_line() + "]" );
		log.push_back( "" );
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
		put_error( "Illegal ENDIF." );
		return false;
	}
	info.is_block_processing = false;
	if( words.size() != 1 ) {
		put_error( "ENDIF is not need parameters." );
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
			this->set_code_size( &info, 0 );
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
		info.is_updated = true;
	}

	if( !is_analyze_phase ) {
		log.push_back( "[" + get_line() + "]" );
		if( do_process ) {
			log.push_back( "\tSelected {" + p_selected_if->get_line() + "} block." );
		}
		else {
			log.push_back( "\tAll condition is not selected." );
		}
		log.push_back( "" );
	}
	return check_all_fixed();
}

// --------------------------------------------------------------------
bool CZMA_PARSE_ENDIF::write( CZMA_INFORMATION& info, std::ofstream* f ) {
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
		info.log << line << std::endl;
	}
	info.log << std::endl;
	return result;
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
bool CZMA_PARSE_EXX::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( this->opecode( info, 0xD9 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:5cyc, R800:1cyc" );
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_EX::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( !this->is_data_fixed ) {
		this->is_data_fixed = true;
		if( words.size() == 4 && words[1] == "DE" && words[2] == "," && words[3] == "HL" ) {
			this->set_code_size( &info, 1 );
			this->data.push_back( 0xEB );
		}
		else if( words.size() == 4 && words[1] == "AF" && words[2] == "," && words[3] == "AF'" ) {
			this->set_code_size( &info, 1 );
			this->data.push_back( 0x08 );
		}
		else if( words.size() == 6 && words[1] == "[" && words[2] == "SP" && words[3] == "]" && words[4] == "," ) {
			if( words[5] == "HL" ) {
				this->set_code_size( &info, 1 );
				this->data.push_back( 0xE3 );
			}
			else if( words[5] == "IX" ) {
				this->set_code_size( &info, 2 );
				this->data.push_back( 0xDD );
				this->data.push_back( 0xE3 );
			}
			else if( words[5] == "IY" ) {
				this->set_code_size( &info, 2 );
				this->data.push_back( 0xFD );
				this->data.push_back( 0xE3 );
			}
			else {
				this->is_data_fixed = false;
				put_error( "Illegal operand" );
				return false;
			}
		}
		else {
			this->is_data_fixed = false;
			put_error( "Illegal operand" );
			return false;
		}
	}
	//	log
	if( !this->is_analyze_phase ) {
		if( words.size() == 6 ) {
			if( words[5] == "HL" ) {
				log.push_back( "[\t" + get_line() + "] Z80:20cyc, R800:7cyc" );
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:25cyc, R800:8cyc" );
			}
		}
		else {
			log.push_back( "[\t" + get_line() + "] Z80:5cyc, R800:1cyc" );
		}
		this->log_data_dump();
		log.push_back( "" );
	}
	return check_all_fixed();
}

// --------------------------------------------------------------------
bool CZMA_PARSE_PUSH::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( this->opecode_rp_with_af( info, 0xC5 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( words[1] == "IX" || words[1] == "IY" ) {
				log.push_back( "[\t" + get_line() + "] Z80:17cyc, R800:7cyc" );
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:12cyc, R800:6cyc" );
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_POP::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( this->opecode_rp_with_af( info, 0xC1 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( words[1] == "IX" || words[1] == "IY" ) {
				log.push_back( "[\t" + get_line() + "] Z80:16cyc, R800:6cyc" );
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:11cyc, R800:5cyc" );
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_RLCA::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( this->opecode( info, 0x07 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:5cyc, R800:1cyc" );
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_RLA::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( this->opecode( info, 0x17 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:5cyc, R800:1cyc" );
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_RLC::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( this->opecode_sss( info, 0xCB, 0x00 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( data.size() == 2 ) {
				if( this->data[1] == 0x06 ) {
					log.push_back( "[\t" + get_line() + "] Z80:17cyc, R800:8cyc" );		//	RLC	[HL]
				}
				else {
					log.push_back( "[\t" + get_line() + "] Z80:10cyc, R800:2cyc" );		//	RLC	r
				}
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:25cyc, R800:10cyc" );		//	RLC	[IX+d]
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_RL::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( this->opecode_sss( info, 0xCB, 0x10 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( data.size() == 2 ) {
				if( this->data[1] == 0x16 ) {
					log.push_back( "[\t" + get_line() + "] Z80:17cyc, R800:8cyc" );
				}
				else {
					log.push_back( "[\t" + get_line() + "] Z80:10cyc, R800:2cyc" );
				}
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:25cyc, R800:10cyc" );
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_RRCA::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( this->opecode( info, 0x0F ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:5cyc, R800:1cyc" );
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_RRA::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( this->opecode( info, 0x1F ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:5cyc, R800:1cyc" );
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_RRC::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( this->opecode_sss( info, 0xCB, 0x08 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( data.size() == 2 ) {
				if( this->data[1] == 0x0E ) {
					log.push_back( "[\t" + get_line() + "] Z80:17cyc, R800:8cyc" );			//	RRC [HL]
				}
				else {
					log.push_back( "[\t" + get_line() + "] Z80:10cyc, R800:2cyc" );			//	RRC r
				}
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:25cyc, R800:10cyc" );			//	RRC [IX+d]
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_RR::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( this->opecode_sss( info, 0xCB, 0x18 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( data.size() == 2 ) {
				if( this->data[1] == 0x1E ) {
					log.push_back( "[\t" + get_line() + "] Z80:17cyc, R800:8cyc" );			//	RR [HL]
				}
				else {
					log.push_back( "[\t" + get_line() + "] Z80:10cyc, R800:2cyc" );			//	RR r
				}
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:25cyc, R800:10cyc" );			//	RR [IX+d]
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_SLA::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( this->opecode_sss( info, 0xCB, 0x20 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( data.size() == 2 ) {
				if( this->data[1] == 0x26 ) {
					log.push_back( "[\t" + get_line() + "] Z80:17cyc, R800:8cyc" );		//	SLA [HL]
				}
				else {
					log.push_back( "[\t" + get_line() + "] Z80:10cyc, R800:2cyc" );		//	SLA r
				}
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:25cyc, R800:10cyc" );		//	SLA [IX+d]
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_SRA::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( this->opecode_sss( info, 0xCB, 0x28 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( data.size() == 2 ) {
				if( this->data[1] == 0x2E ) {
					log.push_back( "[\t" + get_line() + "] Z80:17cyc, R800:8cyc" );		//	SRA [HL]
				}
				else {
					log.push_back( "[\t" + get_line() + "] Z80:10cyc, R800:2cyc" );		//	SRA r
				}
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:25cyc, R800:10cyc" );		//	SRA [IX+d]
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_SRL::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( this->opecode_sss( info, 0xCB, 0x38 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( data.size() == 2 ) {
				if( this->data[1] == 0x3E ) {
					log.push_back( "[\t" + get_line() + "] Z80:17cyc, R800:8cyc" );		//	SRL [HL]
				}
				else {
					log.push_back( "[\t" + get_line() + "] Z80:10cyc, R800:2cyc" );		//	SRL	r
				}
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:25cyc, R800:10cyc" );		//	SRL	[IX+d]
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_SLL::process( CZMA_INFORMATION &info, CZMA_PARSE *p_last_line ){

	update_flags( &info, p_last_line );
	if( this->opecode_sss( info, 0xCB, 0x30 ) ){
		//	log
		if( !this->is_analyze_phase ){
			if( data.size() == 2 ){
				if( this->data[ 1 ] == 0x36 ){
					log.push_back( "[\t" + get_line() + "] Z80:17cyc, R800:8cyc" );		//	SLL [HL]
				}
				else{
					log.push_back( "[\t" + get_line() + "] Z80:10cyc, R800:2cyc" );		//	SLL	r
				}
			}
			else{
				log.push_back( "[\t" + get_line() + "] Z80:25cyc, R800:10cyc" );		//	SLL	[IX+d]
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_ADD::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( this->opecode_a_sss( info, 0x80 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( words[3].size() > 1 ) {
				log.push_back( "[\t" + get_line() + "] Z80:10cyc, R800:2cyc" );	//	ADD A, IXh
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:5cyc, R800:1cyc" );	//	ADD A, r
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	if( this->opecode_a_ref_hl( info, 0x86 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( words[4] == "HL" ) {
				log.push_back( "[\t" + get_line() + "] Z80:8cyc, R800:4cyc" );	//	ADD A, [HL]
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:21cyc, R800:7cyc" );	//	ADD A, [IX+o]
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	if( this->opecode_a_n( info, 0xC6 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:8cyc, R800:2cyc" );		//	ADD A, n
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	if( this->opecode_hl_rp( info, 0x09 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( words[1] == "HL" ) {
				log.push_back( "[\t" + get_line() + "] Z80:12cyc, R800:1cyc" );	//	ADD HL, rr
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:17cyc, R800:2cyc" );	//	ADD IX, rr
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_ADC::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( this->opecode_a_sss( info, 0x88 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( words[3].size() > 1 ) {
				log.push_back( "[\t" + get_line() + "] Z80:10cyc, R800:2cyc" );	//	ADC A, IXh
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:5cyc, R800:1cyc" );	//	ADC A, r
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	if( this->opecode_a_ref_hl( info, 0x8E ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( words[4] == "HL" ) {
				log.push_back( "[\t" + get_line() + "] Z80:8cyc, R800:4cyc" );	//	ADC A, [HL]
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:21cyc, R800:7cyc" );	//	ADC A, [IX+o]
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	if( this->opecode_a_n( info, 0xCE ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:8cyc, R800:2cyc" );	//	ADC A, n
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	if( this->opecode_hl_rp_witnout_ix( info, 0xED, 0x4A ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:17cyc, R800:2cyc" );	//	ADC HL, rr
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_INC::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( this->opecode_ddd( info, 0x04 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( data.size() == 2 ) {
				log.push_back( "[\t" + get_line() + "] Z80:10cyc, R800:2cyc" );		//	INC IXh
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:5cyc, R800:1cyc" );		//	INC r
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	if( this->opecode_rp( info, 0x03 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( words[1] == "IX" || words[1] == "IY" ) {
				log.push_back( "[\t" + get_line() + "] Z80:12cyc, R800:1cyc" );		//	INC IX
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:7cyc, R800:1cyc" );		//	INC rr
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	if( this->opecode_ref_hl( info, 0x34 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( words[2] == "HL" ) {
				log.push_back( "[\t" + get_line() + "] Z80:12cyc, R800:7cyc" );		//	INC [HL]
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:25cyc, R800:10cyc" );	//	INC [IX+o]
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_SUB::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( this->opecode_a_sss( info, 0x90 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( data.size() == 2 ) {
				log.push_back( "[\t" + get_line() + "] Z80:10cyc, R800:2cyc" );	//	SUB A, IXh
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:5cyc, R800:1cyc" );	//	SUB A, r
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	if( this->opecode_a_ref_hl( info, 0x96 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( words[4] == "HL" ) {
				log.push_back( "[\t" + get_line() + "] Z80:8cyc, R800:4cyc" );	//	SUB A, [HL]
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:21cyc, R800:7cyc" );	//	SUB A, [IX+o]
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	if( this->opecode_a_n( info, 0xD6 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:8cyc, R800:2cyc" );	//	SUB A, n
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_SBC::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( this->opecode_a_sss( info, 0x98 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( data.size() == 2 ) {
				log.push_back( "[\t" + get_line() + "] Z80:10cyc, R800:2cyc" );	//	SBC A, IXh
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:5cyc, R800:1cyc" );	//	SBC A, r
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	if( this->opecode_a_ref_hl( info, 0x9E ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( words[4] == "HL" ) {
				log.push_back( "[\t" + get_line() + "] Z80:8cyc, R800:4cyc" );	//	SBC A, [HL]
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:21cyc, R800:7cyc" );	//	SBC A, [IX+o]
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	if( this->opecode_a_n( info, 0xDE ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:8cyc, R800:2cyc" );	//	SBC A, n
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	if( this->opecode_hl_rp_witnout_ix( info, 0xED, 0x42 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:17cyc, R800:2cyc" );	//	SBC HL, rr
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_DEC::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( this->opecode_ddd( info, 0x05 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( data.size() == 2 ) {
				log.push_back( "[\t" + get_line() + "] Z80:10cyc, R800:2cyc" );	//	DEC IXh
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:5cyc, R800:1cyc" );	//	DEC r
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	if( this->opecode_rp( info, 0x0B ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( words[1] == "IX" || words[1] == "IY" ) {
				log.push_back( "[\t" + get_line() + "] Z80:12cyc, R800:2cyc" );	//	DEC IX
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:7cyc, R800:1cyc" );	//	DEC rr
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	if( this->opecode_ref_hl( info, 0x35 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( words[2] == "HL" ) {
				log.push_back( "[\t" + get_line() + "] Z80:12cyc, R800:7cyc" );		//	DEC [HL]
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:25cyc, R800:10cyc" );	//	DEC [IX+o]
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_AND::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( this->opecode_a_sss( info, 0xA0 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( data.size() == 2 ) {
				log.push_back( "[\t" + get_line() + "] Z80:10cyc, R800:2cyc" );	//	AND A, IXh
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:5cyc, R800:1cyc" );	//	AND A, r
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	if( this->opecode_a_n( info, 0xE6 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:8cyc, R800:2cyc" );	//	AND A, n
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	if( this->opecode_a_ref_hl( info, 0xA6 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( words[4] == "HL" ) {
				log.push_back( "[\t" + get_line() + "] Z80:8cyc, R800:4cyc" );	//	AND A, [HL]
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:21cyc, R800:7cyc" );	//	AND A, [IX+o]
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_OR::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( this->opecode_a_sss( info, 0xB0 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( data.size() == 2 ) {
				log.push_back( "[\t" + get_line() + "] Z80:10cyc, R800:2cyc" );	//	OR A, IXh
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:5cyc, R800:1cyc" );	//	OR A, r
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	if( this->opecode_a_n( info, 0xF6 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:8cyc, R800:2cyc" );	//	OR A, n
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	if( this->opecode_a_ref_hl( info, 0xB6 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( words[4] == "HL" ) {
				log.push_back( "[\t" + get_line() + "] Z80:8cyc, R800:4cyc" );	//	OR A, [HL]
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:21cyc, R800:7cyc" );	//	OR A, [IX+o]
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_XOR::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( this->opecode_a_sss( info, 0xA8 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( data.size() == 2 ) {
				log.push_back( "[\t" + get_line() + "] Z80:10cyc, R800:2cyc" );	//	XOR A, IXh
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:5cyc, R800:1cyc" );	//	XOR A, r
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	if( this->opecode_a_n( info, 0xEE ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:8cyc, R800:2cyc" );	//	XOR A, n
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	if( this->opecode_a_ref_hl( info, 0xAE ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( words[4] == "HL" ) {
				log.push_back( "[\t" + get_line() + "] Z80:8cyc, R800:4cyc" );	//	XOR A, [HL]
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:21cyc, R800:7cyc" );	//	XOR A, [IX+o]
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_CPL::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( this->opecode( info, 0x2F ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:5cyc, R800:1cyc" );	//	CPL
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_NEG::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( this->opecode( info, 0xED, 0x44 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:10cyc, R800:2cyc" );	//	NEG
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_CCF::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( this->opecode( info, 0x3F ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:5cyc, R800:1cyc" );	//	NEG
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_SCF::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( this->opecode( info, 0x37 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:5cyc, R800:1cyc" );	//	NEG
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_BIT::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( this->opecode_n_sss( info, 0x40, true ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( data.size() == 2 && (data[1] & 0x07) != 0x06 ) {
				log.push_back( "[\t" + get_line() + "] Z80:10cyc, R800:2cyc" );	//	BIT b,r
			}
			else if( data.size() == 2 ) {
				log.push_back( "[\t" + get_line() + "] Z80:14cyc, R800:5cyc" );	//	BIT b,[HL]
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:22cyc, R800:7cyc" );	//	BIT b,[IX+o]
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_RES::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( this->opecode_n_sss( info, 0x80 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( data.size() == 2 && (data[1] & 0x07) != 0x06 ) {
				log.push_back( "[\t" + get_line() + "] Z80:10cyc, R800:2cyc" );		//	RES b,r
			}
			else if( data.size() == 2 ) {
				log.push_back( "[\t" + get_line() + "] Z80:17cyc, R800:8cyc" );		//	RES b,[HL]
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:25cyc, R800:10cyc" );	//	RES b,[IX+o]
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_SET::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( this->opecode_n_sss( info, 0xC0 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( data.size() == 2 && (data[1] & 0x07) != 0x06 ) {
				log.push_back( "[\t" + get_line() + "] Z80:10cyc, R800:2cyc" );		//	SET b,r
			}
			else if( data.size() == 2 ) {
				log.push_back( "[\t" + get_line() + "] Z80:17cyc, R800:8cyc" );		//	SET b,[HL]
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:25cyc, R800:10cyc" );	//	SET b,[IX+o]
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_CPI::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( this->opecode( info, 0xED, 0xA1 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:18cyc, R800:6cyc" );
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_CPIR::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( this->opecode( info, 0xED, 0xB1 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:23cyc(BC!=0 && A!=[HL]), 18cyc(others), R800:?cyc(BC!=0 && A!=[HL]), 8cyc(others)" );
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_CPD::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( this->opecode( info, 0xED, 0xA9 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:18cyc, R800:6cyc" );
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_CPDR::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( this->opecode( info, 0xED, 0xB9 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:23cyc(BC!=0 && A!=[HL]), 18cyc(others), R800:?cyc(BC!=0 && A!=[HL]), 8cyc(others)" );
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_CP::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( this->opecode_a_sss( info, 0xB8 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( data.size() == 2 ) {
				log.push_back( "[\t" + get_line() + "] Z80:10cyc, R800:2cyc" );	//	CP A, IXh
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:5cyc, R800:1cyc" );	//	CP A, r
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	if( this->opecode_a_n( info, 0xFE ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:8cyc, R800:2cyc" );	//	CP A, n
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	if( this->opecode_a_ref_hl( info, 0xBE ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( words[4] == "HL" ) {
				log.push_back( "[\t" + get_line() + "] Z80:8cyc, R800:4cyc" );	//	CP A, [HL]
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:21cyc, R800:7cyc" );	//	CP A, [IX+o]
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_JP::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( opecode_ccc_nnn( info, 0xC3, 0xC2 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( data[0] == 0xC3 ) {
				log.push_back( "[\t" + get_line() + "] Z80:11cyc, R800:5cyc" );	//	JP nn
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:11cyc, R800:5cyc(cond=true), 3cyc(cond=false)" );	//	JP cond, nn
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	if( words.size() == 2 && words[1] == "HL" ) {
		if( !this->is_data_fixed ) {
			this->set_code_size( &info, 1 );
			this->is_data_fixed = true;
			this->data.push_back( 0xE9 );
		}
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:5cyc, R800:3cyc" );	//	JP HL
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	if( words.size() == 2 && words[1] == "IX" ) {
		if( !this->is_data_fixed ) {
			this->set_code_size( &info, 2 );
			this->is_data_fixed = true;
			this->data.push_back( 0xDD );
			this->data.push_back( 0xE9 );
		}
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:10cyc, R800:4cyc" );	//	JP IX
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	if( words.size() == 2 && words[1] == "IY" ) {
		if( !this->is_data_fixed ) {
			this->set_code_size( &info, 2 );
			this->is_data_fixed = true;
			this->data.push_back( 0xFD );
			this->data.push_back( 0xE9 );
		}
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:10cyc, R800:4cyc" );	//	JP IY
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_JR::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );

	if( opecode_ccc_e( info, 0x18, 0x20 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( data[0] == 0x18 ) {
				log.push_back( "[\t" + get_line() + "] Z80:13cyc, R800:3cyc" );	//	JR nn
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:13cyc(cond=true), 8cyc(cond=false), R800:3cyc(cond=true), 2cyc(cond=false)" );	//	JR cond, nn
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_DJNZ::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {
	int relative;

	update_flags( &info, p_last_line );
	if( words.size() != 2 ) {
		put_error( "Illegal operand" );
		return false;
	}
	if( !this->is_data_fixed ) {
		this->set_code_size( &info, 2 );
		relative = this->relative_address( info, 1 );
		if( relative == -9999 ) {
			put_error( "Illegal operand" );
			return false;
		}
		this->is_data_fixed = true;
		this->data.push_back( 0x10 );
		this->data.push_back( relative );
	}
	//	log
	if( !this->is_analyze_phase ) {
		log.push_back( "[\t" + get_line() + "] Z80:14cyc(cond=true), 9cyc(cond=false), R800:3cyc(cond=true), 2cyc(cond=false)" );	//	DJNZ nn
		this->log_data_dump();
		log.push_back( "" );
	}
	return check_all_fixed();
}

// --------------------------------------------------------------------
bool CZMA_PARSE_CALL::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( opecode_ccc_nnn( info, 0xCD, 0xC4 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( data[0] == 0xCD ) {
				log.push_back( "[\t" + get_line() + "] Z80:18cyc, R800:5cyc" );				//	CALL nn
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:18cyc(branch), 11cyc(through), R800:5cyc(branch), 3cyc(through)" );	//	CALL cond,nn
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_RET::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( opecode_ccc( info, 0xC9, 0xC0 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( data[0] == 0xC9 ) {
				log.push_back( "[\t" + get_line() + "] Z80:11cyc, R800:5cyc" );				//	RET
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:12cyc(branch), 6cyc(through), R800:5cyc(branch), 1cyc(through)" );	//	RET cond
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_RETI::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( opecode( info, 0xED, 0x4D ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:16cyc, R800:7cyc" );
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_RETN::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( opecode( info, 0xED, 0x45 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:16cyc, R800:7cyc" );
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_RST::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {
	CVALUE p;
	int index;
	update_flags( &info, p_last_line );
	if( words.size() >= 2 ) {
		index = this->expression( info, 1, p );
		if( index == 0 ) {
			put_error( "Illegal expression." );
			return false;
		}
		if( p.value_type != CVALUE_TYPE::CV_INTEGER ) {
			put_error( "Illegal expression." );
			return false;
		}
		if( index < (int)words.size() ) {
			put_error( "Illegal operand." );
			return false;
		}
		if( (p.i & ~0x38) != 0 ) {
			put_error( std::string("Illegal restart address (") + std::to_string(p.i) + ")" );
			return false;
		}
		if( !this->is_data_fixed ) {
			this->is_data_fixed = true;
			this->set_code_size( &info, 1 );
			this->data.push_back( 0xC7 | p.i );
		}
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:12cyc, R800:6 or 7cyc" );
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_NOP::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( opecode( info, 0x00 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:5cyc, R800:1cyc" );
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_HALT::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( opecode( info, 0x76 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:5cyc, R800:2cyc and wait interrupt" );
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_DI::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( opecode( info, 0xF3 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:5cyc, R800:2cyc" );
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_EI::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( opecode( info, 0xFB ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:5cyc, R800:1cyc" );
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_IM0::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( opecode( info, 0xED, 0x46 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:10cyc, R800:3cyc" );
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_IM1::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( opecode( info, 0xED, 0x56 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:10cyc, R800:3cyc" );
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_IM2::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( opecode( info, 0xED, 0x5E ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:10cyc, R800:3cyc" );
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_IN::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( opecode_ddd_c( info, 0xDB, 0xED, 0x40 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( data[0] == 0xDB ) {
				log.push_back( "[\t" + get_line() + "] Z80:12cyc, R800:10 or 9cyc" );		//	IN A,[n]
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:14cyc, R800:10 or 9cyc" );		//	IN A,[C]
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_INI::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( opecode( info, 0xED, 0xA2 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:18cyc, R800:12 or 11cyc" );
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_INIR::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( opecode( info, 0xED, 0xB2 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:23 or 18cyc, R800:? or 12 or 11cyc" );
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_IND::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( opecode( info, 0xED, 0xAA ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:18cyc, R800:12 or 11cyc" );
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_INDR::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( opecode( info, 0xED, 0xBA ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:23 or 18cyc, R800:? or 12 or 11cyc" );
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_OUT::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( opecode_c_sss( info, 0xD3, 0xED, 0x41 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			if( data[0] == 0xD3 ) {
				log.push_back( "[\t" + get_line() + "] Z80:12cyc, R800:10 or 9cyc" );	//	OUT [n], A
			}
			else {
				log.push_back( "[\t" + get_line() + "] Z80:14cyc, R800:10 or 9cyc" );	//	OUT	[C], A
			}
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_OUTI::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( opecode( info, 0xED, 0xA3 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:18cyc, R800:12 or 11cyc" );
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_OTIR::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( opecode( info, 0xED, 0xB3 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:23 or 18cyc, R800:? or 12 or 11cyc" );
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_OUTD::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( opecode( info, 0xED, 0xAB ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:18cyc, R800:12 or 11cyc" );
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_OTDR::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( opecode( info, 0xED, 0xBB ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:23 or 18cyc, R800:? or 12 or 11cyc" );
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_DAA::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( opecode( info, 0x27 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:5cyc, R800:1cyc" );
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_RLD::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( opecode( info, 0xED, 0x6F ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:20cyc, R800:8cyc" );
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_RRD::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( opecode( info, 0xED, 0x67 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:20cyc, R800:8cyc" );
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_MULUB::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( opecode_mulub( info, 0xED, 0xC1 ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:--, R800:14cyc" );
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_MULUW::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	update_flags( &info, p_last_line );
	if( opecode_muluw( info ) ) {
		//	log
		if( !this->is_analyze_phase ) {
			log.push_back( "[\t" + get_line() + "] Z80:--, R800:36cyc" );
			this->log_data_dump();
			log.push_back( "" );
		}
		return check_all_fixed();
	}
	put_error( "Illegal operand" );
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE_ERROR::process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line ) {

	put_error( "Illegal command" );
	return false;
}
