// --------------------------------------------------------------------
//	ZMA: CZMA_TEXT
// ====================================================================
//	2019/05/02	t.hara
// --------------------------------------------------------------------

#include "zma_error.hpp"
#include <iostream>
#include <fstream>
#include <iostream>
#include <iomanip>
#include <sstream>
#include <map>

static std::map< CZMA_ERROR_CODE, const std::string > error_message = {
	{ CZMA_ERROR_CODE::SYNTAX_ERROR, "Syntax error." },
	{ CZMA_ERROR_CODE::INVALID_COMMAND, "Invalid command." },
	{ CZMA_ERROR_CODE::ADDRESS_DETERMINED, "Code address not yet determined." },
	{ CZMA_ERROR_CODE::ILLEGAL_OPERAND, "Illegal operand." },
	{ CZMA_ERROR_CODE::ILLEGAL_PARAMETER, "Illegal parameter." },
	{ CZMA_ERROR_CODE::ILLEGAL_EXPRESSION, "Illegal expression." },
	{ CZMA_ERROR_CODE::ILLEGAL_CONDITION, "Illegal condition." },
	{ CZMA_ERROR_CODE::ILLEGAL_ARGUMENT, "Illegal argument." },
	{ CZMA_ERROR_CODE::TOO_MANY_PARAMETERS, "Too many parameters." },
	{ CZMA_ERROR_CODE::DEFAULT_CHAR_SET_CANNOT_BE_MAPPED_AND_CHANGED, "Default character set cannot be mapped and changed." },
	{ CZMA_ERROR_CODE::CANNOT_OPEN_THE_FILE, "Cannot open the file." },
	{ CZMA_ERROR_CODE::CANNOT_EVALUATE_THE_EXPRESSION, "Cannot evaluate the expression." },
	{ CZMA_ERROR_CODE::MULTIPLE_DEFINITION, "Multiple definition." },
	{ CZMA_ERROR_CODE::LABEL_IS_INDETERMINATE, "Label is indeterminate." },
	{ CZMA_ERROR_CODE::REPEAT_COUNTER_IS_NO_FIXED, "Repeat counter is no fixed." },
	{ CZMA_ERROR_CODE::MUST_BE_SET_NAME, "Must be set name." },
	{ CZMA_ERROR_CODE::BLOCK_PROCESSING_IS_NOT_CLOSED, "Block processing is not closed." },
	{ CZMA_ERROR_CODE::SCOPE_IS_NOT_CLOSED, "Scope is not closed." },
	{ CZMA_ERROR_CODE::OUT_OF_RANGE_RELATIVE_ADDRESS, "Out of range relative address." },
	{ CZMA_ERROR_CODE::OUT_OF_RANGE_BIT_NUMBER, "Out of range bit number." },
	{ CZMA_ERROR_CODE::THE_NUMERICAL_VALUE_IS_INCORRECT, "The numerical value is incorrect." },
	{ CZMA_ERROR_CODE::DIVIDED_BY_ZERO, "Divided by zero." },
};

// --------------------------------------------------------------------
std::string CZMA_ERROR::get( CZMA_ERROR_CODE code, std::string message1, std::string message2, std::string message3 ){
	std::string base_message;
	std::string result( "" );
	bool b_insert_message = false;

	base_message = error_message[ code ];
	for( auto &c : base_message ){
		if( c == '$' ){
			b_insert_message = true;
			continue;
		}
		if( b_insert_message ){
			b_insert_message = false;
			if( c == '1' ){
				result = result + message1;
			}
			else if( c == '2' ){
				result = result + message2;
			}
			else{
				result = result + message3;
			}
		}
		else{
			result = result + c;
		}
	}
	return result;
}
