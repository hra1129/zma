// --------------------------------------------------------------------
//	Z80 Macro Assembler parse
// ====================================================================
//	2019/05/04	t.hara
// --------------------------------------------------------------------

#include "zma_parse.hpp"
#include "zma_text.hpp"
#include <string>
#include <cctype>
#include <iostream>
#include <fstream>
#include <sstream>
#include <algorithm>

// --------------------------------------------------------------------
std::string CZMA_PARSE::get_word( int index ) {
	if( index >= (int)words.size() ) {
		return "";
	}
	return words[index];
}

// --------------------------------------------------------------------
std::string CZMA_PARSE::delete_head_space( std::string s ) {
	int i;

	for( i = 0; isspace( s[i] ); i++ );
	return s.substr( i );
}

// --------------------------------------------------------------------
static bool is_shift_jis_1st( char c ) {
	unsigned char cc = (unsigned char) c;
	if( ((cc >= 0x81) && (cc <= 0x9f)) || ((cc >= 0xe0) && (cc <= 0xfc)) ) {
		return true;
	}
	return false;
}

// --------------------------------------------------------------------
std::vector<std::string> CZMA_PARSE::get_word_split( std::string s ) {
	int i;
	std::string word;
	std::vector< std::string > words;
	static std::vector< std::string > operator_list = { 
		"<<", ">>", "!=", "==", "<=", ">=", "::", "&&", "||", ":="
	};

	for(;;) {
		s = delete_head_space( s );
		if( s[0] == ';' || s[0] == '\0' ) {
			break;
		}
		else if( s[0] == '\'' ) {
			if( (int)s.size() < 2 ) {
				break;
			}
			if( s[1] == '\\' ) {
				if( ( int) s.size() < 4 ) {
					break;
				}
				switch( s[2] ) {
				case 'a':	word = std::to_string( (int)'\a' );		break;
				case 'b':	word = std::to_string( (int)'\b' );		break;
				case 'f':	word = std::to_string( (int)'\f' );		break;
				case 'n':	word = std::to_string( (int)'\n' );		break;
				case 'r':	word = std::to_string( (int)'\r' );		break;
				case 't':	word = std::to_string( (int)'\t' );		break;
				case '\\':	word = std::to_string( (int)'\\' );		break;
				case '\'':	word = std::to_string( (int)'\'' );		break;
				case '\"':	word = std::to_string( (int)'\"' );		break;
				default:	word = std::to_string( ( int) s[2] );	break;
				}
				words.push_back( word );
				if( s[3] != '\'' ) {
					s = s.substr( 3 );
					continue;
				}
				s = s.substr( 4 );
				continue;
			}
			else {
				word = std::to_string( ( int) s[1] );
				words.push_back( word );
				if( s[2] != '\'' ) {
					s = s.substr( 2 );
					continue;
				}
				s = s.substr( 3 );
				continue;
			}
		}
		else if( s[0] == '\"' ) {
			word = "\"";
			for( i = 1; i < (int)s.size(); i++ ) {
				if( s[i] == '\\' ) {
					i++;
					if( i >= (int)s.size() ) {
						break;
					}
					switch( s[i] ) {
					case 'a':	word = word + "\a";	break;
					case 'b':	word = word + "\b";	break;
					case 'f':	word = word + "\f";	break;
					case 'n':	word = word + "\n";	break;
					case 'r':	word = word + "\r";	break;
					case 't':	word = word + "\t";	break;
					case '\\':	word = word + "\\";	break;
					case '\'':	word = word + "\'";	break;
					case '\"':	word = word + "\"";	break;
					default:	word = word + s[i];	break;
					}
					continue;
				}
				else if( s[i] == '\"' ) {
					i++;
					break;
				}
				else if( is_shift_jis_1st( s[i] ) ) {
					word = word + s[i];
					i++;
					if( i >= (int)s.size() ) {
						break;
					}
				}
				word = word + s[i];
			}
			words.push_back( word );
			s = s.substr( i );
			continue;
		}
		else if( isalpha( s[0] ) || isdigit( s[0] ) || s[0] == '_' ) {
			//	symbols or numbers
			for( i = 0; isalpha( s[i] ) || isdigit( s[i] ) || s[i] == '_' || s[i] == '\''; i++ );
		}
		else {
			//	operators
			i = 1;
			for( std::string &op : operator_list ) {
				if( op == s.substr( 0, op.length() ) ) {
					i = op.length();
					break;
				}
			}
		}
		word = s.substr( 0, i );
		std::transform( word.begin(), word.end(), word.begin(), ::toupper );
		words.push_back( word );
		s = s.substr( i );
	}
	return words;
}

// --------------------------------------------------------------------
CZMA_PARSE::CZMA_PARSE( std::vector<std::string> words, const char* p_file_name, int line_no ) {
	this->code_address = -1;
	this->next_code_address = -1;
	this->file_address = -1;
	this->code_size = -1;
	this->is_data_fixed = false;
	this->words = words;
	this->p_file_name = p_file_name;
	this->line_no = line_no;
	this->is_analyze_phase = true;
	this->is_label_search_state = true;
	this->is_structure_error = false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::update_flags( CZMA_INFORMATION* p_info, const CZMA_PARSE* p_last_line ) {
	bool result = true;
	if( p_last_line == nullptr ) {
		this->set_code_address( p_info, 0 );
		this->set_file_address( p_info, 0 );
	}
	else {
		if( p_last_line->get_fixed_next_code_address() ) {
			this->set_code_address( p_info, p_last_line->get_next_code_address() );
		}
		else {
			result = false;
		}

		if( p_last_line->get_fixed_file_address() && p_last_line->get_fixed_code_size() ) {
			this->set_file_address( p_info, p_last_line->get_file_address() + p_last_line->get_code_size() );
		}
		else {
			result = false;
		}
	}
	if( !this->is_data_fixed ) {
		result = false;
	}
	if( this->get_fixed_code_address() && this->get_fixed_code_size() ) {
		if( this->next_code_address == -1 ) {
			p_info->is_updated = true;
		}
		this->next_code_address = this->get_code_address() + this->get_code_size();
	}
	else {
		result = false;
	}
	return result;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::check_location_hl( int index ) {
	if( (int)words.size() >= (index + 3) && words[index] == "[" && words[index+1] == "HL" && words[index+2] == "]" ) {
		return true;
	}
	return false;
}

// --------------------------------------------------------------------
int CZMA_PARSE::check_location_ix( int index ) {
	if( (int)words.size() < (index + 3) ) {
		return 0;
	}
	if( words[index] == "[" && words[index + 1] == "IX" && words[index + 2] == "]" ) {
		return index + 3;
	}
	if( words[index] != "[" || words[index + 1] != "IX" || (words[index + 2] != "+" && words[index + 2] != "-") ) {
		return 0;
	}
	for( index += 2; (size_t)index < words.size() && words[index] != "]"; index++ );
	if( (size_t)index >= words.size() ) {
		return 0;
	}
	return index + 1;
}

// --------------------------------------------------------------------
int CZMA_PARSE::check_location_iy( int index ) {
	if( (int)words.size() < (index + 3) ) {
		return 0;
	}
	if( words[index] == "[" && words[index + 1] == "IY" && words[index + 2] == "]" ) {
		return index + 3;
	}
	if( words[index] != "[" || words[index + 1] != "IY" || (words[index + 2] != "+" && words[index + 2] != "-") ) {
		return false;
	}
	for( index += 2; (size_t)index < words.size() && words[index] != "]"; index++ );
	if( (size_t)index >= words.size() ) {
		return 0;
	}
	return index + 1;
}

// --------------------------------------------------------------------
int CZMA_PARSE::relative_address( CZMA_INFORMATION &info, int index ) {
	int relative;
	CVALUE imm;
	index = this->expression( info, index, imm );
	if( index == 0 ) {
		put_error( "Illegal expression." );
		return -9999;
	}
	if( imm.type != CVALUE::CV_INTEGER ) {
		put_error( "Illegal operand." );
		return -9999;
	}
	if( index < ( int) words.size() ) {
		put_error( "Illegal operand." );
		return -9999;
	}
	relative = imm.i - (this->code_address + this->get_code_size() );
	if( relative < -128 || relative > 127 ) {
		put_error( "Out of range relative address" );
		return -9999;
	}
	return relative;
}

// --------------------------------------------------------------------
void CZMA_PARSE::put_error( std::string message ) {
	std::stringstream ss;
	std::string s;

	if( this->is_analyze_phase ) {
		return;
	}
	ss << "ERROR: " << message << ": " << p_file_name << "(" << line_no << ")";
	s = ss.str();
	std::cerr << s << "\n";
	log.push_back( s );
	number_of_error++;
}

// --------------------------------------------------------------------
void CZMA_PARSE::put_message( std::string message ) {
	std::stringstream ss;
	std::string s;

	if(this->is_analyze_phase) {
		return;
	}
	ss << "MESSAGE: " << message << ": " << p_file_name << "(" << line_no << ")";
	s = ss.str();
	std::cout << s << "\n";
	log.push_back( s );
}

// --------------------------------------------------------------------
void CZMA_PARSE::put_structure_error( std::string message ) {
	std::stringstream ss;
	std::string s;

	if( this->is_structure_error ) {
		return;
	}
	this->is_structure_error = true;
	ss << "ERROR: " << message << ": " << p_file_name << "(" << line_no << ")";
	s = ss.str();
	std::cerr << s << "\n";
	this->structure_error = s;
	log.push_back( s );
	number_of_error++;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::opecode( CZMA_INFORMATION& info, unsigned char op1, int op2 ) {

	if( words.size() != 1 ) {
		return false;
	}
	if( this->is_data_fixed ) {
		return true;
	}
	this->is_data_fixed = true;
	if( op2 == -1 ) {
		this->set_code_size( &info, 1 );
		this->data.push_back( op1 );
	}
	else {
		this->set_code_size( &info, 2 );
		this->data.push_back( op1 );
		this->data.push_back( op2 );
	}
	return true;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::opecode_a_i_r( CZMA_INFORMATION& info ) {

	if( words.size() != 4 || words[2] != "," ) {
		return false;
	}
	if( words[1] == "A" && words[3] == "I" ) {
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		this->set_code_size( &info, 2 );
		this->data.push_back( 0xED );
		this->data.push_back( 0x57 );
		return true;
	}
	if( words[1] == "I" && words[3] == "A" ) {
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		this->set_code_size( &info, 2 );
		this->data.push_back( 0xED );
		this->data.push_back( 0x47 );
		return true;
	}
	if( words[1] == "A" && words[3] == "R" ) {
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		this->set_code_size( &info, 2 );
		this->data.push_back( 0xED );
		this->data.push_back( 0x5F );
		return true;
	}
	if( words[1] == "R" && words[3] == "A" ) {
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		this->set_code_size( &info, 2 );
		this->data.push_back( 0xED );
		this->data.push_back( 0x4F );
		return true;
	}
	return false;
}


// --------------------------------------------------------------------
bool CZMA_PARSE::opecode_ddd_sss( CZMA_INFORMATION& info, unsigned char op1 ) {
	int ddd, sss;
	int ixhl = 0;

	if( words.size() != 4 || (!info.is_sss_or_ddd( words[1] ) && !info.is_ix_hl( words[1] ) && !info.is_iy_hl( words[1] )) || 
		words[2] != ","   || (!info.is_sss_or_ddd( words[3] ) && !info.is_ix_hl( words[3] ) && !info.is_iy_hl( words[3] )) ) {
		return false;
	}
	if( info.is_sss_or_ddd( words[1] ) ) {
		ddd = info.sss_or_ddd_id[words[1]];
	}
	else if( info.is_ix_hl( words[1] ) ) {
		ddd = info.ix_hl[words[1]];
		ixhl = 1;
	}
	else {
		ddd = info.iy_hl[words[1]];
		ixhl = 2;
	}
	if( info.is_sss_or_ddd( words[3] ) ) {
		sss = info.sss_or_ddd_id[words[3]];
	}
	else if( info.is_ix_hl( words[3] ) ) {
		sss = info.ix_hl[words[3]];
		if( ixhl || words[1] == "H" || words[1] == "L" ) {
			put_error( "Illegal operand." );
			return false;
		}
		ixhl = 1;
	}
	else {
		sss = info.iy_hl[words[3]];
		if( ixhl || words[1] == "H" || words[1] == "L" ) {
			put_error( "Illegal operand." );
			return false;
		}
		ixhl = 2;
	}
	if( this->is_data_fixed ) {
		return true;
	}
	this->is_data_fixed = true;
	if( ixhl == 1 ) {
		this->set_code_size( &info, 2 );
		this->data.push_back( 0xDD );
	}
	else if( ixhl == 2 ) {
		this->set_code_size( &info, 2 );
		this->data.push_back( 0xFD );
	}
	else {
		this->set_code_size( &info, 1 );
	}
	this->data.push_back( op1 | (ddd << 3) | sss );
	return true;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::opecode_a_sss( CZMA_INFORMATION& info, unsigned char op1 ) {
	int sss;
	CVALUE d;

	if( words.size() == 4 && words[1] == "A" && words[2] == "," && info.is_sss_or_ddd( words[3] ) ) {
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		sss = info.sss_or_ddd_id[words[3]];
		this->set_code_size( &info, 1 );
		this->data.push_back( op1 | sss );
		return true;
	}
	if( words.size() == 4 && words[1] == "A" && words[2] == "," && info.is_ix_hl( words[3] ) ) {
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		sss = info.ix_hl[words[3]];
		this->set_code_size( &info, 2 );
		this->data.push_back( 0xDD );
		this->data.push_back( op1 | sss );
		return true;
	}
	if( words.size() == 4 && words[1] == "A" && words[2] == "," && info.is_iy_hl( words[3] ) ) {
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		sss = info.iy_hl[words[3]];
		this->set_code_size( &info, 2 );
		this->data.push_back( 0xFD );
		this->data.push_back( op1 | sss );
		return true;
	}
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::opecode_ddd_c( CZMA_INFORMATION& info, unsigned char op1, unsigned char op1c, unsigned char op2 ) {
	int ddd;
	CVALUE nn;

	if( words.size() == 6 && info.is_sss_or_ddd( words[1] ) && words[2] == "," && words[3] == "[" && words[4] == "C" && words[5] == "]" ) {
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		ddd = info.sss_or_ddd_id[words[1]];
		this->set_code_size( &info, 2 );
		this->data.push_back( op1c );
		this->data.push_back( op2 | (ddd << 3) );
		return true;
	}
	if( words.size() == 6 && words[ 1 ] == "F" && words[ 2 ] == "," && words[ 3 ] == "[" && words[ 4 ] == "C" && words[ 5 ] == "]" ){
		if( this->is_data_fixed ){
			return true;
		}
		this->is_data_fixed = true;
		ddd = info.sss_or_ddd_id[ words[ 1 ] ];
		this->set_code_size( &info, 2 );
		this->data.push_back( op1c );
		this->data.push_back( op2 | ( 6 << 3 ) );
		return true;
	}
	if( words.size() >= 6 && words[1] == "A" && words[2] == "," && words[3] == "[" ) {
		this->set_code_size( &info, 2 );
		if( !this->expression( info, 4, nn ) ) {
			return false;
		}
		if( nn.type != CVALUE::CV_INTEGER ) {
			put_error( "Illegal operand." );
			return false;
		}
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		this->data.push_back( op1 );
		this->data.push_back( nn.i );
		return true;
	}
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::opecode_c_sss( CZMA_INFORMATION& info, unsigned char op1, unsigned char op1c, unsigned char op2 ) {
	int sss, n;
	CVALUE nn;

	if( words.size() == 6 && words[1] == "[" && words[2] == "C" && words[3] == "]" && words[4] == "," && info.is_sss_or_ddd( words[5] ) ) {
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		sss = info.sss_or_ddd_id[words[5]];
		this->set_code_size( &info, 2 );
		this->data.push_back( op1c );
		this->data.push_back( op2 | (sss << 3) );
		return true;
	}
	if( words.size() == 6 && words[ 1 ] == "[" && words[ 2 ] == "C" && words[ 3 ] == "]" && words[ 4 ] == "," && words[ 5 ] == "0" ){
		if( this->is_data_fixed ){
			return true;
		}
		this->is_data_fixed = true;
		this->set_code_size( &info, 2 );
		this->data.push_back( op1c );
		this->data.push_back( op2 | ( 6 << 3 ) );
		return true;
	}
	for( n = 2; n < (int)words.size() && words[n] != "]"; n++ ) {
	}
	if( n >= (int)words.size() ) {
		return false;
	}
	n++;
	if( words.size() >= 6 && words[1] == "[" && words[n] == "," && words[n+1] == "A" ) {
		this->set_code_size( &info, 2 );
		if( !this->expression( info, 2, nn ) ) {
			return false;
		}
		if( nn.type != CVALUE::CV_INTEGER ) {
			put_error( "Illegal operand." );
			return false;
		}
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		this->data.push_back( op1 );
		this->data.push_back( nn.i );
		return true;
	}
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::opecode_n_sss( CZMA_INFORMATION& info, unsigned char op1, bool no_3operand ) {
	int sss, ddd, n;
	CVALUE b, d;

	for( n = 1; n < (int) words.size() && words[n] != ","; n++ ) {
	}
	if( n >= (int) words.size() ) {
		return false;
	}
	if( !this->expression( info, 1, b ) ) {
		return false;
	}
	if( b.type != CVALUE::CV_INTEGER ) {
		put_error( "Illegal operand." );
		return false;
	}
	if( b.i < 0 || b.i > 7 ) {
		put_error( "Bit number is out of range." );
		b.i &= 7;
	}
	n++;
	if( (int) words.size() == (n + 1) && info.is_sss_or_ddd( words[n] ) ) {
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		sss = info.sss_or_ddd_id[words[n]];
		this->set_code_size( &info, 2 );
		this->data.push_back( 0xCB );
		this->data.push_back( op1 | (b.i << 3) | sss );
		return true;
	}
	if( (int) words.size() == (n + 3) && this->check_location_hl( n ) ) {
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		this->set_code_size( &info, 2 );
		this->data.push_back( 0xCB );
		this->data.push_back( op1 | (b.i << 3) | 0x06 );
		return true;
	}
	if( (int) words.size() >= (n + 5) && this->check_location_ix( n ) ) {
		this->set_code_size( &info, 4 );
		if( words[n + 2] == "+" || words[n + 2] == "-" ) {
			n = this->expression( info, n + 2, d );
			if( n == 0 ) {
				return false;
			}
			if( words[ n ] != "]" ){
				put_error( "Illegal operand." );
				return false;
			}
			if( d.type != CVALUE::CV_INTEGER ) {
				put_error( "Illegal operand." );
				return false;
			}
			if( d.i < -128 || d.i > 127 ) {
				put_error( "Offset value is out of range (" + std::to_string( d.i ) + ")." );
				return false;
			}
			if( !no_3operand && words.size() > (unsigned)(n + 2) && words[ n + 1 ] == "," && info.is_sss_or_ddd( words[ n + 2 ] ) ){
				ddd = info.sss_or_ddd_id[ words[ n + 2 ] ];
			}
			else{
				ddd = 6;
			}
		}
		else {
			d.i = 0;
			ddd = 6;
		}
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		this->data.push_back( 0xDD );
		this->data.push_back( 0xCB );
		this->data.push_back( d.i );
		this->data.push_back( op1 | (b.i << 3) | ddd );
		return true;
	}
	if( (int) words.size() >= (n + 5) && this->check_location_iy( n ) ) {
		this->set_code_size( &info, 4 );
		if( words[n + 2] == "+" || words[n + 2] == "-" ) {
			n = this->expression( info, n + 2, d );
			if( n == 0 ){
				return false;
			}
			if( d.type != CVALUE::CV_INTEGER ) {
				put_error( "Illegal operand." );
				return false;
			}
			if( d.i < -128 || d.i > 127 ) {
				put_error( "Offset value is out of range (" + std::to_string( d.i ) + ")." );
				return false;
			}
			if( !no_3operand && words.size() > (unsigned)( n + 2 ) && words[ n + 1 ] == "," && info.is_sss_or_ddd( words[ n + 2 ] ) ){
				ddd = info.sss_or_ddd_id[ words[ n + 2 ] ];
			}
			else{
				ddd = 6;
			}
		}
		else{
			d.i = 0;
			ddd = 6;
		}
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		this->data.push_back( 0xFD );
		this->data.push_back( 0xCB );
		this->data.push_back( d.i );
		this->data.push_back( op1 | ( b.i << 3 ) | ddd );
		return true;
	}
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::opecode_hl_rp( CZMA_INFORMATION& info, unsigned char op1 ) {
	int rp;

	if( words.size() == 4 && words[1] == "HL" && words[2] == "," && info.is_rp( words[3] ) ) {
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		rp = info.rp_id[words[3]];
		this->set_code_size( &info, 1 );
		this->data.push_back( op1 | (rp << 4) );
		return true;
	}
	if( words.size() == 4 && words[1] == "IX" && words[2] == "," && info.is_ix_rp( words[3] ) ) {
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		rp = info.ix_rp_id[words[3]];
		this->set_code_size( &info, 2 );
		this->data.push_back( 0xDD );
		this->data.push_back( op1 | (rp << 4) );
		return true;
	}
	if( words.size() == 4 && words[1] == "IY" && words[2] == "," && info.is_iy_rp( words[3] ) ) {
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		rp = info.iy_rp_id[words[3]];
		this->set_code_size( &info, 2 );
		this->data.push_back( 0xFD );
		this->data.push_back( op1 | (rp << 4) );
		return true;
	}
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::opecode_hl_rp_witnout_ix( CZMA_INFORMATION& info, unsigned char op1, unsigned char op2 ) {
	int rp;

	if( words.size() == 4 && words[1] == "HL" && words[2] == "," && info.is_rp( words[3] ) ) {
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		rp = info.rp_id[words[3]];
		this->set_code_size( &info, 2 );
		this->data.push_back( op1 );
		this->data.push_back( op2 | (rp << 4) );
		return true;
	}
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::opecode_ddd_ref_hl( CZMA_INFORMATION& info, unsigned char op1 ) {
	int ddd, index;
	CVALUE d;

	if( words.size() < 6 || !info.is_sss_or_ddd( words[1] ) || words[2] != "," || (!check_location_hl( 3 ) && !check_location_ix( 3 ) && !check_location_iy( 3 )) ) {
		return false;
	}
	ddd = info.sss_or_ddd_id[words[1]];
	if( words.size() >= 6 && check_location_ix( 3 ) ) {
		this->set_code_size( &info, 3 );
		if( words[5] == "+" || words[5] == "-" ) {
			index = this->expression( info, 5, d );
			if( index == 0 ) {
				return false;
			}
			if( d.type != CVALUE::CV_INTEGER ) {
				put_error( "Illegal operand." );
				return false;
			}
			if( d.i < -128 || d.i > 127 ) {
				put_error( "Offset value is out of range (" + std::to_string( d.i ) + ")." );
				return false;
			}
			if( (int)words.size() > (index + 1) ) {
				put_error( "There is an extra account that can not be interpreted." );
				return false;
			}
		}
		else {
			if( words.size() > 6 ) {
				put_error( "There is an extra account that can not be interpreted." );
				return false;
			}
			d.i = 0;
		}
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		this->data.push_back( 0xDD );
		this->data.push_back( op1 | (ddd << 3) );
		this->data.push_back( d.i );
		return true;
	}
	else if( words.size() >= 6 && check_location_iy( 3 ) ) {
		this->set_code_size( &info, 3 );
		if( words[5] == "+" || words[5] == "-" ) {
			index = this->expression( info, 5, d );
			if( index == 0 ) {
				return false;
			}
			if( d.type != CVALUE::CV_INTEGER ) {
				put_error( "Illegal operand." );
				return false;
			}
			if( d.i < -128 || d.i > 127 ) {
				put_error( "Offset value is out of range (" + std::to_string( d.i ) + ")." );
				return false;
			}
			if( (int)words.size() > (index + 1) ) {
				put_error( "There is an extra account that can not be interpreted." );
				return false;
			}
		}
		else {
			if( words.size() > 6 ) {
				put_error( "There is an extra account that can not be interpreted." );
				return false;
			}
			d.i = 0;
		}
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		this->data.push_back( 0xFD );
		this->data.push_back( op1 | (ddd << 3) );
		this->data.push_back( d.i );
		return true;
	}
	else if( words.size() == 6 ) {
		if( this->is_data_fixed ) {
			return true;
		}
		this->set_code_size( &info, 1 );
		this->is_data_fixed = true;
		this->data.push_back( op1 | (ddd << 3) );
		return true;
	}
	return true;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::opecode_a_ref_hl( CZMA_INFORMATION& info, unsigned char op1 ) {
	CVALUE d;

	if( words.size() < 6 || words[1] != "A" || words[2] != "," || (!check_location_hl( 3 ) && !check_location_ix( 3 ) && !check_location_iy( 3 )) ) {
		return false;
	}
	if( words.size() >= 6 && check_location_ix( 3 ) ) {
		this->set_code_size( &info, 3 );
		if( words[5] == "+" || words[5] == "-" ) {
			if( !this->expression( info, 5, d ) ) {
				return false;
			}
			if( d.type != CVALUE::CV_INTEGER ) {
				put_error( "Illegal operand." );
				return false;
			}
			if( d.i < -128 || d.i > 127 ) {
				put_error( "Offset value is out of range (" + std::to_string( d.i ) + ")." );
				return false;
			}
		}
		else {
			d.i = 0;
		}
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		this->data.push_back( 0xDD );
		this->data.push_back( op1 );
		this->data.push_back( d.i );
		return true;
	}
	else if( words.size() >= 6 && check_location_iy( 3 ) ) {
		this->set_code_size( &info, 3 );
		if( words[5] == "+" || words[5] == "-" ) {
			if( !this->expression( info, 5, d ) ) {
				return false;
			}
			if( d.type != CVALUE::CV_INTEGER ) {
				put_error( "Illegal operand." );
				return false;
			}
			if( d.i < -128 || d.i > 127 ) {
				put_error( "Offset value is out of range (" + std::to_string( d.i ) + ")." );
				return false;
			}
		}
		else {
			d.i = 0;
		}
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		this->data.push_back( 0xFD );
		this->data.push_back( op1 );
		this->data.push_back( d.i );
		return true;
	}
	else if( words.size() == 6 ) {
		if( this->is_data_fixed ) {
			return true;
		}
		this->set_code_size( &info, 1 );
		this->is_data_fixed = true;
		this->data.push_back( op1 );
		return true;
	}
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::opecode_ref_hl( CZMA_INFORMATION& info, unsigned char op1 ) {
	CVALUE d;
	int index;

	if( words.size() < 4 || !(check_location_hl( 1 ) || check_location_ix( 1 ) || check_location_iy( 1 )) ) {
		return false;
	}
	if( check_location_ix( 1 ) ) {
		this->set_code_size( &info, 3 );
		if( words[3] == "+" || words[3] == "-" ) {
			index = this->expression( info, 3, d );
			if( index == 0 ) {
				put_error( "Illegal operand." );
				return false;
			}
			if( d.type != CVALUE::CV_INTEGER ) {
				put_error( "Illegal operand." );
				return false;
			}
			if( (index + 1) < (int) words.size() ) {
				put_error( "Illegal operand." );
				return false;
			}
			if( d.i < -128 || d.i > 127 ) {
				put_error( "Offset value is out of range (" + std::to_string( d.i ) + ")." );
				return false;
			}
		}
		else {
			d.i = 0;
		}
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		this->data.push_back( 0xDD );
		this->data.push_back( op1 );
		this->data.push_back( d.i );
	}
	else if( check_location_iy( 1 ) ) {
		this->set_code_size( &info, 3 );
		if( words[3] == "+" || words[3] == "-" ) {
			index = this->expression( info, 3, d );
			if( index == 0 ) {
				put_error( "Illegal operand." );
				return false;
			}
			if( d.type != CVALUE::CV_INTEGER ) {
				put_error( "Illegal operand." );
				return false;
			}
			if( (index + 1) < (int) words.size() ) {
				put_error( "Illegal operand." );
				return false;
			}
			if( d.i < -128 || d.i > 127 ) {
				put_error( "Offset value is out of range (" + std::to_string( d.i ) + ")." );
				return false;
			}
		}
		else {
			d.i = 0;
		}
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		this->data.push_back( 0xFD );
		this->data.push_back( op1 );
		this->data.push_back( d.i );
	}
	else {
		if( this->is_data_fixed ) {
			return true;
		}
		this->set_code_size( &info, 1 );
		this->is_data_fixed = true;
		this->data.push_back( op1 );
	}
	return true;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::opecode_ddd_n( CZMA_INFORMATION& info, unsigned char op1 ) {
	int ddd;
	CVALUE imm8;

	if( words.size() < 4 || (!info.is_sss_or_ddd( words[1] ) && !info.is_ix_hl( words[1] ) && !info.is_iy_hl( words[1] )) || words[2] != "," || words[3] == "[" ) {
		return false;
	}
	if( info.is_sss_or_ddd( words[1] ) ) {
		this->set_code_size( &info, 2 );
	}
	else if( info.is_ix_hl( words[1] ) ) {
		this->set_code_size( &info, 3 );
	}
	else {
		this->set_code_size( &info, 3 );
	}
	if( !this->expression( info, 3, imm8 ) ) {
		return false;
	}
	if( imm8.type != CVALUE::CV_INTEGER ) {
		put_error( "Illegal operand." );
		return false;
	}
	if( imm8.i < -128 || imm8.i > 255) {
		put_error( "Operand is out of range." );
		return false;
	}
	if( this->is_data_fixed ) {
		return true;
	}
	this->is_data_fixed = true;
	if( info.is_sss_or_ddd( words[1] ) ) {
		ddd = info.sss_or_ddd_id[words[1]];
	}
	else if( info.is_ix_hl( words[1] ) ) {
		ddd = info.ix_hl[words[1]];
		this->data.push_back( 0xDD );
	}
	else {
		ddd = info.iy_hl[words[1]];
		this->data.push_back( 0xFD );
	}
	this->data.push_back( op1 | (ddd << 3) );
	this->data.push_back( imm8.i );
	return true;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::opecode_a_n( CZMA_INFORMATION& info, unsigned char op1 ) {
	CVALUE imm8;

	if( words.size() < 4 || words[1] != "A" || words[2] != "," || words[3] == "[" ) {
		return false;
	}
	this->set_code_size( &info, 2 );
	if( !this->expression( info, 3, imm8 ) ) {
		return false;
	}
	if( imm8.type != CVALUE::CV_INTEGER ) {
		put_error( "Illegal operand." );
		return false;
	}
	if( this->is_data_fixed ) {
		return true;
	}
	this->is_data_fixed = true;
	this->data.push_back( op1 );
	this->data.push_back( imm8.i );
	return true;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::opecode_rp( CZMA_INFORMATION& info, unsigned char op1 ) {
	int rp;

	if( words.size() != 2 || (!info.is_rp( words[1] ) && words[1] != "IX" && words[1] != "IY") ) {
		return false;
	}
	if( this->is_data_fixed ) {
		return true;
	}
	this->is_data_fixed = true;
	if( words[1] == "IX" ) {
		rp = 2;
		this->set_code_size( &info, 2 );
		this->data.push_back( 0xDD );
	}
	else if( words[1] == "IY" ) {
		rp = 2;
		this->set_code_size( &info, 2 );
		this->data.push_back( 0xFD );
	}
	else {
		rp = info.rp_id[words[1]];
		this->set_code_size( &info, 1 );
	}
	this->data.push_back( op1 | (rp << 4) );
	return true;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::opecode_rp_nn( CZMA_INFORMATION& info, unsigned char op1 ) {
	int rp;
	CVALUE nn;

	if( words.size() < 4 || (!info.is_rp( words[1] ) && words[1] != "IX" && words[1] != "IY") || words[2] != "," || words[3] == "[" ) {
		return false;
	}
	if( words[1] == "IX" || words[1] == "IY" ) {
		this->set_code_size( &info, 4 );
	}
	else {
		this->set_code_size( &info, 3 );
	}
	if( !this->expression( info, 3, nn ) ) {
		put_error( "Illegal operand." );
		return false;
	}
	if( nn.type != CVALUE::CV_INTEGER ) {
		put_error( "Illegal operand." );
		return false;
	}
	if( nn.i < -32768 || nn.i > 65535 ) {
		put_error( "Operand is out of range." );
		return false;
	}
	if( this->is_data_fixed ) {
		return true;
	}
	this->is_data_fixed = true;
	if( words[1] == "IX" ) {
		rp = 2;
		this->data.push_back( 0xDD );
	}
	else if( words[1] == "IY" ) {
		rp = 2;
		this->data.push_back( 0xFD );
	}
	else {
		rp = info.rp_id[words[1]];
	}
	this->data.push_back( op1 | (rp << 4) );
	this->data.push_back( nn.i & 255 );
	this->data.push_back( (nn.i >> 8) & 255 );
	return true;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::opecode_rp_ref_nn( CZMA_INFORMATION& info, unsigned char op1, unsigned char op1c ) {
	int rp;
	CVALUE nn;

	if( words.size() < 6 || (!info.is_rp( words[1] ) && words[1] != "IX" && words[1] != "IY") || words[2] != "," || words[3] != "[" ) {
		return false;
	}
	if( words[1] == "HL" ) {
		this->set_code_size( &info, 3 );
	}
	else {
		this->set_code_size( &info, 4 );
	}
	if( !this->expression( info, 4, nn ) ) {
		put_error( "Illegal operand." );
		return false;
	}
	if( nn.type != CVALUE::CV_INTEGER ) {
		put_error( "Illegal operand." );
		return false;
	}
	if( nn.i < -32768 || nn.i > 65535 ) {
		put_error( "Operand is out of range." );
		return false;
	}
	if( this->is_data_fixed ) {
		return true;
	}
	this->is_data_fixed = true;
	if( words[1] == "HL" ) {
		this->data.push_back( op1 );
	}
	else if( words[1] == "IX" ) {
		this->data.push_back( 0xDD );
		this->data.push_back( op1 );
	}
	else if( words[1] == "IY" ) {
		this->data.push_back( 0xFD );
		this->data.push_back( op1 );
	}
	else {
		rp = info.rp_id[words[1]];
		this->data.push_back( 0xED );
		this->data.push_back( op1c | (rp << 4) );
	}
	this->data.push_back( nn.i & 255 );
	this->data.push_back( (nn.i >> 8) & 255 );
	return true;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::opecode_ref_hl_sss( CZMA_INFORMATION& info, unsigned char op1 ) {
	int i, sss;
	CVALUE nn;

	if( words[1] != "[" ) {
		return false;
	}
	for( i = 2; i < (int)words.size() && words[i] != "]"; i++ ) {
	}
	if( i >= (int)words.size() ) {
		return false;
	}
	if( words[i + 1] != "," || !info.is_sss_or_ddd( words[i + 2] ) ) {
		return false;
	}
	sss = info.sss_or_ddd_id[words[i + 2]];
	if( this->check_location_hl( 1 ) ) {
		if( this->is_data_fixed ) {
			return true;
		}
		this->set_code_size( &info, 1 );
		this->is_data_fixed = true;
		this->data.push_back( op1 | sss );
		return true;
	}
	if( this->check_location_ix( 1 ) ) {
		this->set_code_size( &info, 3 );
		if( words[3] == "+" || words[3] == "-" ) {
			if( !this->expression( info, 3, nn ) ) {
				put_error( "Illegal operand." );
				return false;
			}
			if( nn.type != CVALUE::CV_INTEGER ) {
				put_error( "Illegal operand." );
				return false;
			}
			if( nn.i < -128 || nn.i > 127 ) {
				put_error( "Offset value is out of range (" + std::to_string(nn.i) + ")." );
				return false;
			}
		}
		else {
			nn.i = 0;
		}
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		this->data.push_back( 0xDD );
		this->data.push_back( op1 | sss );
		this->data.push_back( nn.i );
		return true;
	}
	if( this->check_location_iy( 1 ) ) {
		this->set_code_size( &info, 3 );
		if( words[3] == "+" || words[3] == "-" ) {
			if( !this->expression( info, 3, nn ) ) {
				put_error( "Illegal operand." );
				return false;
			}
			if( nn.type != CVALUE::CV_INTEGER ) {
				put_error( "Illegal operand." );
				return false;
			}
			if( nn.i < -128 || nn.i > 127 ) {
				put_error( "Offset value is out of range (" + std::to_string( nn.i ) + ")." );
				return false;
			}
		}
		else {
			nn.i = 0;
		}
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		this->data.push_back( 0xFD );
		this->data.push_back( op1 | sss );
		this->data.push_back( nn.i );
		return true;
	}
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::opecode_ref_hl_n( CZMA_INFORMATION& info, unsigned char op1 ) {
	int i;
	CVALUE n, d;

	if( words[1] != "[" ) {
		return false;
	}
	for( i = 2; i < (int) words.size() && words[i] != "]"; i++ ) {
	}
	if( i >= (int) words.size() ) {
		return false;
	}
	if( words[i + 1] != "," || info.is_sss_or_ddd( words[i + 2] ) ) {
		return false;
	}
	if( this->check_location_hl( 1 ) ) {
		if( !this->expression( info, i + 2, n ) ) {
			put_error( "Illegal operand." );
			return false;
		}
		if( n.type != CVALUE::CV_INTEGER ) {
			put_error( "Illegal operand." );
			return false;
		}
		if( n.i < -128 || n.i > 255 ) {
			put_error( "Operand is out of range." );
			return false;
		}
		this->set_code_size( &info, 2 );
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		this->data.push_back( op1 );
		this->data.push_back( n.i & 255 );
		return true;
	}
	if( this->check_location_ix( 1 ) ) {
		if( words[3] == "+" || words[3] == "-" ) {
			if( !this->expression( info, 3, d ) ) {
				put_error( "Illegal operand." );
				return false;
			}
			if( d.type != CVALUE::CV_INTEGER ) {
				put_error( "Illegal operand." );
				return false;
			}
			if( d.i < -128 || d.i > 127 ) {
				put_error( "Offset value is out of range (" + std::to_string( d.i ) + ")." );
				return false;
			}
		}
		else {
			d.i = 0;
		}
		if( !this->expression( info, i + 2, n ) ) {
			put_error( "Illegal operand." );
			return false;
		}
		if( n.type != CVALUE::CV_INTEGER ) {
			put_error( "Illegal operand." );
			return false;
		}
		if( n.i < -128 || n.i > 255 ) {
			put_error( "Operand is out of range." );
			return false;
		}
		this->set_code_size( &info, 4 );
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		this->data.push_back( 0xDD );
		this->data.push_back( op1 );
		this->data.push_back( d.i );
		this->data.push_back( n.i & 255 );
		return true;
	}
	if( this->check_location_iy( 1 ) ) {
		if( words[3] == "+" || words[3] == "-" ) {
			if( !this->expression( info, 3, d ) ) {
				put_error( "Illegal operand." );
				return false;
			}
			if( d.type != CVALUE::CV_INTEGER ) {
				put_error( "Illegal operand." );
				return false;
			}
			if( d.i < -128 || d.i > 127 ) {
				put_error( "Offset value is out of range (" + std::to_string( d.i ) + ")." );
				return false;
			}
		}
		else {
			d.i = 0;
		}
		if( !this->expression( info, i + 2, n ) ) {
			put_error( "Illegal operand." );
			return false;
		}
		if( n.type != CVALUE::CV_INTEGER ) {
			put_error( "Illegal operand." );
			return false;
		}
		if( n.i < -128 || n.i > 255 ) {
			put_error( "Operand is out of range." );
			return false;
		}
		this->set_code_size( &info, 4 );
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		this->data.push_back( 0xFD );
		this->data.push_back( op1 );
		this->data.push_back( d.i );
		this->data.push_back( n.i & 255 );
		return true;
	}
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::opecode_a_ref_bc( CZMA_INFORMATION& info, unsigned char op1 ) {
	CVALUE nn;
	int index;

	if( words.size() == 6 && words[1] == "A" && words[2] == "," && words[3] == "[" && words[4] == "BC" && words[5] == "]" ) {
		if( this->is_data_fixed ) {
			return true;
		}
		this->set_code_size( &info, 1 );
		this->is_data_fixed = true;
		this->data.push_back( op1 | 0x00 );
		return true;
	}
	if( words.size() == 6 && words[1] == "A" && words[2] == "," && words[3] == "[" && words[4] == "DE" && words[5] == "]" ) {
		if( this->is_data_fixed ) {
			return true;
		}
		this->set_code_size( &info, 1 );
		this->is_data_fixed = true;
		this->data.push_back( op1 | 0x10 );
		return true;
	}
	if( words.size() >= 6 && words[1] == "A" && words[2] == "," && words[3] == "[" ) {
		this->set_code_size( &info, 3 );
		index = this->expression( info, 4, nn );
		if( index == 0 ) {
			//	別の命令の可能性があるので、ここではエラーを出さない
			return false;	//	この命令にはマッチしなかったという意味で false
		}
		if( words[index] != "]" ) {
			put_error( "Illegal operand." );
			return false;
		}
		if( (index + 1) < (int)words.size() ) {
			put_error( "Illegal operand." );
			return false;
		}
		if( nn.type != CVALUE::CV_INTEGER ) {
			put_error( "Illegal operand." );
			return false;
		}
		if( nn.i < -32768 || nn.i > 65535 ) {
			put_error( "Operand is out of range." );
			return false;
		}
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		this->data.push_back( op1 | 0x30 );
		this->data.push_back( nn.i & 255 );
		this->data.push_back( (nn.i >> 8) & 255 );
		return true;
	}
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::opecode_ref_bc_a( CZMA_INFORMATION& info, unsigned char op1 ) {
	int i;
	CVALUE nn;

	if( words.size() == 6 && words[1] == "[" && words[2] == "BC" && words[3] == "]" && words[4] == "," && words[5] == "A" ) {
		if( this->is_data_fixed ) {
			return true;
		}
		this->set_code_size( &info, 1 );
		this->is_data_fixed = true;
		this->data.push_back( op1 | 0x00 );
		return true;
	}
	if( words.size() == 6 && words[1] == "[" && words[2] == "DE" && words[3] == "]" && words[4] == "," && words[5] == "A" ) {
		if( this->is_data_fixed ) {
			return true;
		}
		this->set_code_size( &info, 1 );
		this->is_data_fixed = true;
		this->data.push_back( op1 | 0x10 );
		return true;
	}
	for( i = 2; i < (int)words.size() && words[i] != "]"; i++ ) {
	}
	if( i >= (int)words.size() ) {
		return false;
	}
	if( (int)words.size() == (i + 3) && words[1] == "[" && words[i] == "]" && words[i + 1] == "," && words[i + 2] == "A" ) {
		this->set_code_size( &info, 3 );
		if( !this->expression( info, 2, nn ) ) {
			put_error( "Illegal operand." );
			return false;
		}
		if( nn.type != CVALUE::CV_INTEGER ) {
			put_error( "Illegal operand." );
			return false;
		}
		if( nn.i < -32768 || nn.i > 65535 ) {
			put_error( "Operand is out of range." );
			return false;
		}
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		this->data.push_back( op1 | 0x30 );
		this->data.push_back( nn.i & 255 );
		this->data.push_back( (nn.i >> 8) & 255 );
		return true;
	}
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::opecode_ref_nn_rp( CZMA_INFORMATION& info, unsigned char op1, unsigned char op1c, unsigned char op2 ) {
	int i, rp;
	CVALUE nn;

	if( words[1] != "[" ) {
		return false;
	}
	for( i = 2; i < (int) words.size() && words[i] != "]"; i++ ) {
	}
	if( (int)words.size() != (i + 3) || words[i + 1] != "," ) {
		return false;
	}
	if(  words[i + 2] == "HL" ) {
		this->set_code_size( &info, 3 );
		if( !this->expression( info, 2, nn ) ) {
			put_error( "Illegal operand." );
			return false;
		}
		if( nn.type != CVALUE::CV_INTEGER ) {
			put_error( "Illegal operand." );
			return false;
		}
		if( nn.i < -32768 || nn.i > 65535 ) {
			put_error( "Operand is out of range." );
			return false;
		}
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		this->data.push_back( op1c );
		this->data.push_back( nn.i & 255 );
		this->data.push_back( (nn.i >> 8) & 255 );
		return true;
	}
	if( info.is_rp(words[i+2]) ) {
		this->set_code_size( &info, 4 );
		if( !this->expression( info, 2, nn ) ) {
			put_error( "Illegal operand." );
			return false;
		}
		if( nn.type != CVALUE::CV_INTEGER ) {
			put_error( "Illegal operand." );
			return false;
		}
		if(nn.i < -32768 || nn.i > 65535) {
			put_error( "Operand is out of range." );
			return false;
		}
		rp = info.rp_id[words[i + 2]];
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		this->data.push_back( op1 );
		this->data.push_back( op2 | (rp << 4) );
		this->data.push_back( nn.i & 255 );
		this->data.push_back( (nn.i >> 8) & 255 );
		return true;
	}
	if( words[i + 2] == "IX" ) {
		this->set_code_size( &info, 4 );
		if( !this->expression( info, 2, nn ) ) {
			put_error( "Illegal operand." );
			return false;
		}
		if( nn.type != CVALUE::CV_INTEGER ) {
			put_error( "Illegal operand." );
			return false;
		}
		if(nn.i < -32768 || nn.i > 65535) {
			put_error( "Operand is out of range." );
			return false;
		}
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		this->data.push_back( 0xDD );
		this->data.push_back( op1c );
		this->data.push_back( nn.i & 255 );
		this->data.push_back( (nn.i >> 8) & 255 );
		return true;
	}
	if( words[i + 2] == "IY" ) {
		this->set_code_size( &info, 4 );
		if( !this->expression( info, 2, nn ) ) {
			put_error( "Illegal operand." );
			return false;
		}
		if( nn.type != CVALUE::CV_INTEGER ) {
			put_error( "Illegal operand." );
			return false;
		}
		if(nn.i < -32768 || nn.i > 65535) {
			put_error( "Operand is out of range." );
			return false;
		}
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		this->data.push_back( 0xFD );
		this->data.push_back( op1c );
		this->data.push_back( nn.i & 255 );
		this->data.push_back( (nn.i >> 8) & 255 );
		return true;
	}
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::opecode_sp_hl( CZMA_INFORMATION& info, unsigned char op1 ) {

	if( words.size() != 4 || words[1] != "SP" || words[2] != "," ) {
		return false;
	}
	if( words[3] == "HL" ) {
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		this->set_code_size( &info, 1 );
		this->data.push_back( op1 );
		return true;
	}
	if( words[3] == "IX" ) {
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		this->set_code_size( &info, 2 );
		this->data.push_back( 0xDD );
		this->data.push_back( op1 );
		return true;
	}
	if( words[3] == "IY" ) {
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		this->set_code_size( &info, 2 );
		this->data.push_back( 0xFD );
		this->data.push_back( op1 );
		return true;
	}
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::opecode_rp_with_af( CZMA_INFORMATION& info, unsigned char op1 ) {
	int rp;

	if( words.size() != 2 || (!info.is_rp_with_af( words[1] ) && words[1] != "IX" && words[1] != "IY") ) {
		return false;
	}
	if( this->is_data_fixed ) {
		return true;
	}
	this->is_data_fixed = true;
	if( words[1] == "IX" ) {
		rp = 2;
		this->set_code_size( &info, 2 );
		this->data.push_back( 0xDD );
	}
	else if( words[1] == "IY" ) {
		rp = 2;
		this->set_code_size( &info, 2 );
		this->data.push_back( 0xFD );
	}
	else {
		rp = info.rp_with_af_id[words[1]];
		this->set_code_size( &info, 1 );
	}
	this->data.push_back( op1 | (rp << 4) );
	return true;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::opecode_sss( CZMA_INFORMATION& info, unsigned char op1, int op2 ) {
	int sss, ddd, n;
	CVALUE nn;

	if( words.size() == 2 && info.is_sss_or_ddd( words[1] ) ) {
		if( this->is_data_fixed ) {
			return true;
		}
		sss = info.sss_or_ddd_id[words[1]];
		this->is_data_fixed = true;
		if( op2 != -1 ) {
			this->set_code_size( &info, 2 );
			this->data.push_back( op1 );
			this->data.push_back( op2 | sss );
		}
		else {
			this->set_code_size( &info, 1 );
			this->data.push_back( op1 | sss );
		}
		return true;
	}
	if( words.size() == 4 && this->check_location_hl( 1 ) ) {
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		if( op2 != -1 ) {
			this->set_code_size( &info, 2 );
			this->data.push_back( op1 );
			this->data.push_back( op2 | 0x06 );
		}
		else {
			this->set_code_size( &info, 1 );
			this->data.push_back( op1 | 0x06 );
		}
		return true;
	}
	if( words.size() >= 6 && this->check_location_ix( 1 ) ) {
		if( op2 != -1 ) {
			this->set_code_size( &info, 4 );
		}
		else {
			this->set_code_size( &info, 3 );
		}
		if( words[3] == "+" || words[3] == "-" ) {
			n = this->expression( info, 3, nn );
			if( n == 0 ) {
				put_error( "Illegal operand." );
				return false;
			}
			if( words[ n ] != "]" ){
				put_error( "Illegal operand." );
				return false;
			}
			if( nn.type != CVALUE::CV_INTEGER ) {
				put_error( "Illegal operand." );
				return false;
			}
			if( nn.i < -128 || nn.i > 127 ) {
				put_error( "Offset value is out of range (" + std::to_string( nn.i ) + ")." );
				return false;
			}
			if( words.size() > (unsigned)(n + 2) && words[ n + 1 ] == "," && info.is_sss_or_ddd( words[ n + 2 ] ) ){
				ddd = info.sss_or_ddd_id[ words[ n + 2 ] ];
			}
			else{
				ddd = 6;
			}
		}
		else {
			nn.i = 0;
			ddd = 6;
		}
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		this->data.push_back( 0xDD );
		if( op2 != -1 ) {
			this->data.push_back( op1 );
			this->data.push_back( nn.i );
			this->data.push_back( op2 | ddd );
		}
		else {
			this->data.push_back( op1 | ddd );
			this->data.push_back( nn.i );
		}
		return true;
	}
	if( words.size() >= 6 && this->check_location_iy( 1 ) ) {
		if( op2 != -1 ) {
			this->set_code_size( &info, 4 );
		}
		else {
			this->set_code_size( &info, 3 );
		}
		if( words[3] == "+" || words[3] == "-" ) {
			n = this->expression( info, 3, nn );
			if( n == 0 ){
				put_error( "Illegal operand." );
				return false;
			}
			if( words[ n ] != "]" ){
				put_error( "Illegal operand." );
				return false;
			}
			if( nn.type != CVALUE::CV_INTEGER ) {
				put_error( "Illegal operand." );
				return false;
			}
			if( nn.i < -128 || nn.i > 127 ) {
				put_error( "Offset value is out of range (" + std::to_string( nn.i ) + ")." );
				return false;
			}
			if( words.size() > (unsigned)(n + 2) && words[ n + 1 ] == "," && info.is_sss_or_ddd( words[ n + 2 ] ) ){
				ddd = info.sss_or_ddd_id[ words[ n + 2 ] ];
			}
			else{
				ddd = 6;
			}
		}
		else{
			nn.i = 0;
			ddd = 6;
		}
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		this->data.push_back( 0xFD );
		if( op2 != -1 ) {
			this->data.push_back( op1 );
			this->data.push_back( nn.i );
			this->data.push_back( op2 | ddd );
		}
		else {
			this->data.push_back( op1 | ddd );
			this->data.push_back( nn.i );
		}
		return true;
	}
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::opecode_ccc_nnn( CZMA_INFORMATION& info, unsigned char op1, unsigned char op1c ) {
	int ccc, index;
	CVALUE address;

	if( words.size() == 2 && (words[1] == "HL" || words[1] == "IX" || words[1] == "IY") ) {
		return false;
	}
	if( words.size() >= 4 && info.is_ccc( words[1] ) ) {
		this->set_code_size( &info, 3 );
		index = this->expression( info, 3, address );
		if( index == 0 ) {
			put_error( "Illegal operand." );
			return false;
		}
		if( address.type != CVALUE::CV_INTEGER ) {
			put_error( "Illegal operand." );
			return false;
		}
		if( index < (int)words.size() ) {
			return false;
		}
		ccc = info.ccc_id[words[1]];
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		this->data.push_back( op1c | (ccc << 3) );
		this->data.push_back( address.i & 255 );
		this->data.push_back( (address.i >> 8) & 255 );
		return true;
	}
	else {
		this->set_code_size( &info, 3 );
		index = this->expression( info, 1, address );
		if( index == 0 ) {
			put_error( "Illegal operand." );
			return false;
		}
		if( address.type != CVALUE::CV_INTEGER ) {
			put_error( "Illegal operand." );
			return false;
		}
		if( index < (int)words.size() ) {
			return false;
		}
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		this->data.push_back( op1 );
		this->data.push_back( address.i & 255 );
		this->data.push_back( (address.i >> 8) & 255 );
		return true;
	}
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::opecode_ccc_e( CZMA_INFORMATION& info, unsigned char op1, unsigned char op1c ) {
	int address, ccc;

	if( words.size() >= 4 && info.is_cc2( words[1] ) ) {
		this->set_code_size( &info, 2 );
		address = this->relative_address( info, 3 );
		if( address == -9999 ) {
			return false;
		}
		ccc = info.cc2_id[words[1]];
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		this->data.push_back( op1c | (ccc << 3) );
		this->data.push_back( address );
		return true;
	}
	if( words.size() >= 2 ) {
		this->set_code_size( &info, 2 );
		address = this->relative_address( info, 1 );
		if( address == -9999 ) {
			return false;
		}
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		this->data.push_back( op1 );
		this->data.push_back( address );
		return true;
	}
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::opecode_ccc( CZMA_INFORMATION& info, unsigned char op1, unsigned char op1c ) {
	int ccc;

	if( words.size() == 2 && info.is_ccc( words[1] ) ) {
		ccc = info.ccc_id[words[1]];
		this->set_code_size( &info, 1 );
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		this->data.push_back( op1c | (ccc << 3) );
		return true;
	}
	else if( words.size() == 1 ) {
		this->set_code_size( &info, 1 );
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		this->data.push_back( op1 );
		return true;
	}
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::opecode_mulub( CZMA_INFORMATION& info, unsigned char op1, int op2 ) {
	int ddd;

	if( words.size() != 4 ) {
		return false;
	}
	if( words[1] != "A" || words[2] != "," ) {
		return false;
	}
	if( words[3] != "B" && words[3] != "C" && words[3] != "D" && words[3] != "E" ) {
		return false;
	}
	if( this->is_data_fixed ) {
		return true;
	}
	this->is_data_fixed = true;
	this->set_code_size( &info, 2 );
	ddd = info.sss_or_ddd_id[words[3]];
	this->data.push_back( op1 );
	this->data.push_back( op2 | (ddd << 3) );
	return true;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::opecode_muluw( CZMA_INFORMATION& info ) {

	if( words.size() != 4 ) {
		return false;
	}
	if( words[1] != "HL" || words[2] != "," ) {
		return false;
	}
	if( words[3] == "BC" ) {
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		this->set_code_size( &info, 2 );
		this->data.push_back( 0xED );
		this->data.push_back( 0xC3 );
		return true;
	}
	if( words[3] == "SP" ) {
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		this->set_code_size( &info, 2 );
		this->data.push_back( 0xED );
		this->data.push_back( 0xC5 );
		return true;
	}
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::opecode_ddd( CZMA_INFORMATION& info, unsigned char op1, int op2 ) {
	int ddd;
	CVALUE nn;

	if( words.size() == 2 && info.is_sss_or_ddd( words[1] ) ) {
		ddd = info.sss_or_ddd_id[words[1]];
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		if( op2 != -1 ) {
			this->set_code_size( &info, 2 );
			this->data.push_back( op1 );
			this->data.push_back( op2 | (ddd << 3) );
		}
		else {
			this->set_code_size( &info, 1 );
			this->data.push_back( op1 | (ddd << 3) );
		}
		return true;
	}
	if( words.size() == 2 && info.is_ix_hl( words[1] ) ) {
		ddd = info.ix_hl[words[1]];
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		if( op2 != -1 ) {
			this->set_code_size( &info, 3 );
			this->data.push_back( 0xDD );
			this->data.push_back( op1 );
			this->data.push_back( op2 | (ddd << 3) );
		}
		else {
			this->set_code_size( &info, 2 );
			this->data.push_back( 0xDD );
			this->data.push_back( op1 | (ddd << 3) );
		}
		return true;
	}
	if( words.size() == 2 && info.is_iy_hl( words[1] ) ) {
		ddd = info.iy_hl[words[1]];
		if( this->is_data_fixed ) {
			return true;
		}
		this->is_data_fixed = true;
		if( op2 != -1 ) {
			this->set_code_size( &info, 3 );
			this->data.push_back( 0xFD );
			this->data.push_back( op1 );
			this->data.push_back( op2 | (ddd << 3) );
		}
		else {
			this->set_code_size( &info, 2 );
			this->data.push_back( 0xFD );
			this->data.push_back( op1 | (ddd << 3) );
		}
		return true;
	}
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::write( CZMA_INFORMATION &info, std::ofstream *f ) {
	unsigned char c;

	for( auto d: data ) {
		c = d;
		f->write( (const char*) &c, 1 );
	}
	for( auto line : log ) {
		info.log << line << std::endl;
	}
	return true;
}
