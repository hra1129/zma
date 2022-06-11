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
	{ "CHG_CHAR_SET", CZMA_COMMAND_TYPE::CZMA_CHG_CHAR_SET },
	{ "MAPPING_CHAR", CZMA_COMMAND_TYPE::CZMA_MAPPING_CHAR },
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
		OPE_CASE( CHG_CHAR_SET );
		OPE_CASE( MAPPING_CHAR );
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
		if( s.size() > 0 && (s[0] == '\"' || s[0] == '\'') ){
			ss = s[ 0 ];
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
			ss = ss + s[0];
		}
		else {
			ss = s;
		}
		if( r == "" ) {
			r = ss;
		}
		else if( ss == "," ){
			r = r + ss;
		}
		else if( ss[ 0 ] == '0' && ss[ 1 ] == 'X' ){
			ss[ 1 ] = 'x';
			r = r + " " + ss;
		}
		else if( ss[ 0 ] == '0' && ss[ 1 ] == 'B' ){
			ss[ 1 ] = 'b';
			r = r + " " + ss;
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
