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
#include <algorithm>

// --------------------------------------------------------------------
bool CZMA_PARSE::operator_single( CZMA_INFORMATION& info, int &index, CVALUE& result, bool do_char_map ) {
	std::string s, num;
	bool is_success;

	s = get_word( index );
	if( s == "$" || s == "CODE_ADDRESS" ) {
		index++;
		result.value_type = CVALUE_TYPE::CV_INTEGER;
		if( this->is_fixed_code_address() ) {
			result.i = this->get_code_address();
		}
		else {
			result.value_type = CVALUE_TYPE::CV_UNKNOWN_INTEGER;
			result.i = 0;
		}
		return true;
	}
	if( s == "$$" || s == "FILE_ADDRESS" ) {
		index++;
		result.value_type = CVALUE_TYPE::CV_INTEGER;
		if( this->is_fixed_file_address() ) {
			result.i = this->get_file_address();
		}
		else {
			result.value_type = CVALUE_TYPE::CV_UNKNOWN_INTEGER;
			result.i = 0;
		}
		return true;
	}
	if( s == "CHAR_SET_NAME" ){
		index++;
		result.value_type = CVALUE_TYPE::CV_STRING;
		result.s = info.s_char_set;
		return true;
	}
	if( s[ 0 ] == '$' ){
		num = "";
		for( auto c : s ){
			if( isxdigit( c ) ){
				num = num + c;
				continue;
			}
			if( c == '_' || c == '$' ){
				continue;
			}
			put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::THE_NUMERICAL_VALUE_IS_INCORRECT ) );
			return false;
		}
		result.value_type = CVALUE_TYPE::CV_INTEGER;
		try{
			result.i = (int)std::stoll( num, nullptr, 16 );
		}
		catch( ... ){
			put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::THE_NUMERICAL_VALUE_IS_INCORRECT ) );
			result.i = 0;
		}
		return true;
	}
	if( s == "+" ) {
		index++;
		is_success = operator_single( info, index, result, do_char_map );
		if( !result.is_integer() ) {
			put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_EXPRESSION ) );
			return false;
		}
		return is_success;
	}
	if( s == "-" ) {
		index++;
		is_success = operator_single( info, index, result, do_char_map );
		if( !result.is_integer() ) {
			put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_EXPRESSION ) );
			return false;
		}
		result.i = -result.i;
		return is_success;
	}
	if( s == "(" ) {
		index++;
		is_success = operator_logical_or( info, index, result, do_char_map );
		if( !is_success ) {
			put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_EXPRESSION ) );
			return false;
		}
		s = get_word( index );
		if( s != ")" ) {
			put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_EXPRESSION ) );
			return false;
		}
		index++;
		return true;
	}
	if( s == "!" ) {
		index++;
		is_success = operator_single( info, index, result, do_char_map );
		if( !result.is_integer() ) {
			put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_EXPRESSION ) );
			return false;
		}
		result.i = (int) !((bool)result.i);
		return is_success;
	}
	if( s == "~" ) {
		index++;
		is_success = operator_single( info, index, result, do_char_map );
		if( !result.is_integer() ) {
			put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_EXPRESSION ) );
			return false;
		}
		result.i = ~result.i;
		return is_success;
	}
	if( s[0] == '0' ) {
		//	0 �Ŏn�܂鐔��
		index++;
		if( s[1] == '\0' ) {
			//	�P���� 0
			result.value_type = CVALUE_TYPE::CV_INTEGER;
			result.i = 0;
			return true;
		}
		num = "";
		if( s[s.size() - 1] == 'H' ){
			//	0???H �� 16�i��
			for( auto c : s ){
				if( isxdigit( c ) ){
					num = num + c;
					continue;
				}
				if( c == '_' || c == 'H' ) {
					continue;
				}
				put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::THE_NUMERICAL_VALUE_IS_INCORRECT ) );
				return false;
			}
			result.value_type = CVALUE_TYPE::CV_INTEGER;
			try{
				result.i = (int)std::stoll( num, nullptr, 16 );
			}
			catch( ... ){
				put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::THE_NUMERICAL_VALUE_IS_INCORRECT ) );
				result.i = 0;
			}
			return true;
		}
		if( s[ 1 ] == 'X' ){
			//	0x??? �� 16�i��
			for( auto c : s.substr( 2 ) ) {
				if( isxdigit( c ) ) {
					num = num + c;
					continue;
				}
				if( c == '_' ) {
					continue;
				}
				put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::THE_NUMERICAL_VALUE_IS_INCORRECT ) );
				return false;
			}
			result.value_type = CVALUE_TYPE::CV_INTEGER;
			try{
				result.i = (int)std::stoll( num, nullptr, 16 );
			}
			catch(...) {
				put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::THE_NUMERICAL_VALUE_IS_INCORRECT ) );
				result.i = 0;
			}
			return true;
		}
		if( s[1] == 'B' ) {
			//	0b???? �� 2�i��
			for( auto c : s.substr( 2 ) ) {
				if( c == '0' || c == '1' ) {
					num = num + c;
					continue;
				}
				if( c == '_' ) {
					continue;
				}
				put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::THE_NUMERICAL_VALUE_IS_INCORRECT ) );
				return false;
			}
			result.value_type = CVALUE_TYPE::CV_INTEGER;
			try {
				result.i = (int)std::stoll( num, nullptr, 2 );
			}
			catch( ... ){
				put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::THE_NUMERICAL_VALUE_IS_INCORRECT ) );
				result.i = 0;
			}
			return true;
		}
		for( auto c : s.substr( 1 ) ) {
			//	0??? �� 8�i��
			if( c >= '0' && c <= '7' ) {
				num = num + c;
				continue;
			}
			if( c == '_' ) {
				continue;
			}
			put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::THE_NUMERICAL_VALUE_IS_INCORRECT ) );
			return false;
		}
		result.value_type = CVALUE_TYPE::CV_INTEGER;
		try {
			result.i = (int)std::stoll( num, nullptr, 8 );
		}
		catch( ... ){
			put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::THE_NUMERICAL_VALUE_IS_INCORRECT ) );
			result.i = 0;
		}
		return true;
	}
	if( s[ 0 ] == '\'' ){
		index++;
		unsigned char c;
		//	����
		c = (unsigned char) s[ 1 ];
		if( do_char_map && info.p_char_set != nullptr ) {
			//	�L�����Z�b�g�ϊ�
			c = info.p_char_set->ascii_to_map[ c ];
		}
		result.value_type = CVALUE_TYPE::CV_INTEGER;
		result.i = (int) c;
		return true;
	}
	if( isdigit( s[0] ) ) {
		//	����
		num = "";
		if( s[ s.size() - 1 ] == 'H' ){
			for( auto c : s ){
				if( isxdigit( c ) ){
					num = num + c;
					continue;
				}
				if( c == '_' || c == 'H' ){
					continue;
				}
				put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::THE_NUMERICAL_VALUE_IS_INCORRECT ) );
				return false;
			}
			result.value_type = CVALUE_TYPE::CV_INTEGER;
			try{
				result.i = (int)std::stoll( num, nullptr, 16 );
			}
			catch( ... ){
				put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::THE_NUMERICAL_VALUE_IS_INCORRECT ) );
				result.i = 0;
			}
			return true;
		}
		index++;
		for( auto c : s ) {
			if( isdigit( c ) ) {
				num = num + c;
				continue;
			}
			if( c == '_' ) {
				continue;
			}
			put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::THE_NUMERICAL_VALUE_IS_INCORRECT ) );
			return false;
		}
		result.value_type = CVALUE_TYPE::CV_INTEGER;
		try {
			result.i = (int)std::stoll( num, nullptr );
		}
		catch( ... ){
			put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::THE_NUMERICAL_VALUE_IS_INCORRECT ) );
			result.i = 0;
		}
		return true;
	}
	//	string
	if( s[0] == '\"' ) {
		std::string ss;
		index++;
		result.value_type = CVALUE_TYPE::CV_STRING;
		ss = s.substr( 1 );
		if( do_char_map && info.p_char_set != nullptr ){
			for( auto &c : ss ){
				c = info.p_char_set->ascii_to_map[ c ];
			}
		}
		result.s = ss;
		return true;
	}
	//	�s���ȋL��
	//	label
	if( isalpha( s[0] ) || s[0] == '_' ) {
		if( info.get_label_value( result, s ) ) {
			index++;
			return true;
		}
	}
	return false;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::operator_mul_div( CZMA_INFORMATION& info, int& index, CVALUE& result, bool do_char_map ) {
	std::string s;
	bool is_success;
	CVALUE term;
	int i;

	s = get_word( index );
	is_success = operator_single( info, index, result, do_char_map );
	if( !is_success ) {
		return false;
	}
	for( ;;) {
		s = get_word( index );
		if( s == "*" ) {
			index++;
			is_success = operator_single( info, index, term, do_char_map );
			if( !is_success ) {
				return false;
			}
			if( result.is_integer() && term.is_integer() ) {
				result.i = result.i * term.i;
				result.inherit( CVALUE_TYPE::CV_INTEGER, result.value_type, term.value_type );
				continue;
			}
			else if( result.is_string() && term.is_integer() ) {
				s = "";
				for( i = 0; i < term.i; i++ ) {
					s = s + result.s;
				}
				result.inherit( CVALUE_TYPE::CV_STRING, result.value_type, term.value_type );
				result.s = s;
				continue;
			}
			else if( result.is_integer() && term.is_string() ) {
				s = "";
				for( i = 0; i < result.i; i++ ) {
					s = s + term.s;
				}
				result.inherit( CVALUE_TYPE::CV_STRING, result.value_type, term.value_type );
				result.s = s;
				continue;
			}
			put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_EXPRESSION ) );
			return false;
		}
		if( s == "/" ) {
			index++;
			is_success = operator_single( info, index, term, do_char_map );
			if( !is_success ) {
				return false;
			}
			if( !result.is_integer() || !term.is_integer() ) {
				put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_EXPRESSION ) );
				return false;
			}
			if( term.i == 0 ) {
				put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::DIVIDED_BY_ZERO ) );
				return false;
			}
			else {
				result.inherit( CVALUE_TYPE::CV_INTEGER, result.value_type, term.value_type );
				result.i = result.i / term.i;
			}
			continue;
		}
		if( s == "%" ) {
			index++;
			is_success = operator_single( info, index, term, do_char_map );
			if( !is_success ) {
				return false;
			}
			if( !result.is_integer() || !term.is_integer() ) {
				put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_EXPRESSION ) );
				return false;
			}
			if( term.i == 0 ) {
				put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::DIVIDED_BY_ZERO ) );
				return false;
			}
			else {
				result.inherit( CVALUE_TYPE::CV_INTEGER, result.value_type, term.value_type );
				result.i = result.i % term.i;
			}
			continue;
		}
		break;
	}
	return true;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::operator_add_sub( CZMA_INFORMATION& info, int& index, CVALUE& result, bool do_char_map ) {
	std::string s;
	bool is_success;
	CVALUE term;

	s = get_word( index );
	is_success = operator_mul_div( info, index, result, do_char_map );
	if( !is_success ) {
		return false;
	}
	for( ;;) {
		s = get_word( index );
		if( s == "+" ) {
			index++;
			is_success = operator_mul_div( info, index, term, do_char_map );
			if( !is_success ) {
				return false;
			}
			if( result.is_integer() && term.is_integer() ) {
				result.inherit( CVALUE_TYPE::CV_INTEGER, result.value_type, term.value_type );
				result.i = result.i + term.i;
			}
			else if( result.is_string() && term.is_integer() ) {
				result.inherit( CVALUE_TYPE::CV_STRING, result.value_type, term.value_type );
				result.s = result.s + std::to_string(term.i);
			}
			else if( result.is_integer() && term.is_string() ) {
				result.inherit( CVALUE_TYPE::CV_STRING, result.value_type, term.value_type );
				result.s = std::to_string(result.i) + term.s;
			}
			else{
			//	result.is_string() && term.is_string()
				result.inherit( CVALUE_TYPE::CV_STRING, result.value_type, term.value_type );
				result.s = result.s + term.s;
			}
		}
		else if( s == "-" ) {
			index++;
			is_success = operator_mul_div( info, index, term, do_char_map );
			if( !is_success ) {
				return false;
			}
			if( !result.is_integer() || !term.is_integer() ) {
				put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_EXPRESSION ) );
				return false;
			}
			result.inherit( CVALUE_TYPE::CV_INTEGER, result.value_type, term.value_type );
			result.i = result.i - term.i;
		}
		else {
			break;
		}
	}
	return true;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::operator_shift( CZMA_INFORMATION& info, int& index, CVALUE& result, bool do_char_map ) {
	std::string s;
	bool is_success;
	CVALUE term;

	s = get_word( index );
	is_success = operator_add_sub( info, index, result, do_char_map );
	if( !is_success ) {
		return false;
	}
	if( !result.is_integer() ) {
		return true;
	}
	for( ;;) {
		s = get_word( index );
		if( s == "<<" ) {
			index++;
			is_success = operator_add_sub( info, index, term, do_char_map );
			if( !is_success ) {
				return false;
			}
			if( !term.is_integer() ) {
				put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_EXPRESSION ) );
				return false;
			}
			result.inherit( CVALUE_TYPE::CV_INTEGER, result.value_type, term.value_type );
			result.i = result.i << term.i;
			continue;
		}
		if( s == ">>" ) {
			index++;
			is_success = operator_add_sub( info, index, term, do_char_map );
			if( !is_success ) {
				return false;
			}
			if( !term.is_integer() ) {
				put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_EXPRESSION ) );
				return false;
			}
			result.inherit( CVALUE_TYPE::CV_INTEGER, result.value_type, term.value_type );
			result.i = result.i >> term.i;
			continue;
		}
		break;
	}
	return true;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::operator_compare( CZMA_INFORMATION& info, int& index, CVALUE& result, bool do_char_map ) {
	std::string s;
	bool is_success;
	CVALUE term;

	s = get_word( index );
	is_success = operator_shift( info, index, result, do_char_map );
	if( !is_success ) {
		return false;
	}
	if( !result.is_integer() ) {
		return true;
	}
	for( ;;) {
		s = get_word( index );
		if( s == "<" ) {
			index++;
			is_success = operator_shift( info, index, term, do_char_map );
			if( !is_success ) {
				return false;
			}
			if( !term.is_integer() ) {
				put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_EXPRESSION ) );
				return false;
			}
			result.inherit( CVALUE_TYPE::CV_INTEGER, result.value_type, term.value_type );
			result.i = result.i < term.i;
			continue;
		}
		if( s == ">" ) {
			index++;
			is_success = operator_shift( info, index, term, do_char_map );
			if( !is_success ) {
				return false;
			}
			if( !term.is_integer() ) {
				put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_EXPRESSION ) );
				return false;
			}
			result.inherit( CVALUE_TYPE::CV_INTEGER, result.value_type, term.value_type );
			result.i = result.i > term.i;
			continue;
		}
		if( s == "<=" ) {
			index++;
			is_success = operator_shift( info, index, term, do_char_map );
			if( !is_success ) {
				return false;
			}
			if( !term.is_integer() ) {
				put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_EXPRESSION ) );
				return false;
			}
			result.inherit( CVALUE_TYPE::CV_INTEGER, result.value_type, term.value_type );
			result.i = result.i <= term.i;
			continue;
		}
		if( s == ">=" ) {
			index++;
			is_success = operator_shift( info, index, term, do_char_map );
			if( !is_success ) {
				return false;
			}
			if( !term.is_integer() ) {
				put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_EXPRESSION ) );
				return false;
			}
			result.inherit( CVALUE_TYPE::CV_INTEGER, result.value_type, term.value_type );
			result.i = result.i >= term.i;
			continue;
		}
		break;
	}
	return true;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::operator_equal( CZMA_INFORMATION& info, int& index, CVALUE& result, bool do_char_map ) {
	std::string s;
	bool is_success;
	CVALUE term;

	s = get_word( index );
	is_success = operator_compare( info, index, result, do_char_map );
	if( !is_success ) {
		return false;
	}
	for( ;;) {
		s = get_word( index );
		if( s == "==" ) {
			index++;
			is_success = operator_compare( info, index, term, do_char_map );
			if( !is_success ) {
				return false;
			}
			if( result.is_string() && term.is_string() ) {
				result.inherit( CVALUE_TYPE::CV_INTEGER, result.value_type, term.value_type );
				result.i = result.s == term.s;
				continue;
			}
			if( result.is_integer() && term.is_integer() ) {
				result.inherit( CVALUE_TYPE::CV_INTEGER, result.value_type, term.value_type );
				result.i = result.i == term.i;
				continue;
			}
			result.inherit( CVALUE_TYPE::CV_INTEGER, result.value_type, term.value_type );
			result.i = false;
			continue;
		}
		if( s == "!=" ) {
			index++;
			is_success = operator_compare( info, index, term, do_char_map );
			if( !is_success ) {
				return false;
			}
			if( result.is_string() && term.is_string() ) {
				result.value_type = CVALUE_TYPE::CV_INTEGER;
				result.i = result.s != term.s;
				continue;
			}
			if( result.is_integer() && term.is_integer() ) {
				result.i = result.i != term.i;
				continue;
			}
			result.inherit( CVALUE_TYPE::CV_INTEGER, result.value_type, term.value_type );
			result.i = true;
			continue;
		}
		break;
	}
	return true;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::operator_bit_and( CZMA_INFORMATION& info, int& index, CVALUE& result, bool do_char_map ) {
	std::string s;
	bool is_success;
	CVALUE term;

	s = get_word( index );
	is_success = operator_equal( info, index, result, do_char_map );
	if( !is_success ) {
		return false;
	}
	if( !result.is_integer() ) {
		return true;
	}
	for( ;;) {
		s = get_word( index );
		if( s == "&" ) {
			index++;
			is_success = operator_equal( info, index, term, do_char_map );
			if( !is_success ) {
				return false;
			}
			if( !term.is_integer() ) {
				put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_EXPRESSION ) );
				return false;
			}
			result.inherit( result.value_type, result.value_type, term.value_type );
			result.i = result.i & term.i;
			continue;
		}
		break;
	}
	return true;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::operator_bit_xor( CZMA_INFORMATION& info, int& index, CVALUE& result, bool do_char_map ) {
	std::string s;
	bool is_success;
	CVALUE term;

	s = get_word( index );
	is_success = operator_bit_and( info, index, result, do_char_map );
	if( !is_success ) {
		return false;
	}
	if( !result.is_integer() ) {
		return true;
	}
	for( ;;) {
		s = get_word( index );
		if( s == "^" ) {
			index++;
			is_success = operator_bit_and( info, index, term, do_char_map );
			if( !is_success ) {
				return false;
			}
			if( !term.is_integer() ) {
				put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_EXPRESSION ) );
				return false;
			}
			result.inherit( result.value_type, result.value_type, term.value_type );
			result.i = result.i ^ term.i;
			continue;
		}
		break;
	}
	return true;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::operator_bit_or( CZMA_INFORMATION& info, int& index, CVALUE& result, bool do_char_map ) {
	std::string s;
	bool is_success;
	CVALUE term;

	s = get_word( index );
	is_success = operator_bit_xor( info, index, result, do_char_map );
	if( !is_success ) {
		return false;
	}
	if( !result.is_integer() ) {
		return true;
	}
	for( ;;) {
		s = get_word( index );
		if( s == "|" ) {
			index++;
			is_success = operator_bit_xor( info, index, term, do_char_map );
			if( !is_success ) {
				return false;
			}
			if( !term.is_integer() ) {
				put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_EXPRESSION ) );
				return false;
			}
			result.inherit( result.value_type, result.value_type, term.value_type );
			result.i = result.i | term.i;
			continue;
		}
		break;
	}
	return true;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::operator_logical_and( CZMA_INFORMATION& info, int& index, CVALUE& result, bool do_char_map ) {
	std::string s;
	bool is_success;
	CVALUE term;

	s = get_word( index );
	is_success = operator_bit_or( info, index, result, do_char_map );
	if( !is_success ) {
		return false;
	}
	if( !result.is_integer() ) {
		return true;
	}
	for( ;;) {
		s = get_word( index );
		if( s == "&&" ) {
			index++;
			is_success = operator_bit_or( info, index, term, do_char_map );
			if( !is_success ) {
				return false;
			}
			if( !term.is_integer() ) {
				put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_EXPRESSION ) );
				return false;
			}
			result.inherit( result.value_type, result.value_type, term.value_type );
			result.i = (int)( (bool)result.i && (bool)term.i );
			continue;
		}
		break;
	}
	return true;
}

// --------------------------------------------------------------------
bool CZMA_PARSE::operator_logical_or( CZMA_INFORMATION& info, int& index, CVALUE& result, bool do_char_map ) {
	std::string s;
	bool is_success;
	CVALUE term;

	s = get_word(index);
	is_success = operator_logical_and( info, index, result, do_char_map );
	if( !is_success ) {
		return false;
	}
	if( !result.is_integer() ) {
		return true;
	}
	for( ;;) {
		s = get_word( index );
		if( s == "||" ) {
			index++;
			is_success = operator_logical_and( info, index, term, do_char_map );
			if( !is_success ) {
				return false;
			}
			if( !term.is_integer() ) {
				put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ILLEGAL_EXPRESSION ) );
				return false;
			}
			result.inherit( result.value_type, result.value_type, term.value_type );
			result.i = (int)( (bool)result.i || (bool)term.i );
			continue;
		}
		break;
	}
	return true;
}

// --------------------------------------------------------------------
int CZMA_PARSE::expression( CZMA_INFORMATION& info, int index, CVALUE& result, bool do_char_map ) {
	bool is_success = operator_logical_or( info, index, result, do_char_map );
	if( is_success ) {
		return index;
	}
	return 0;
}
