// --------------------------------------------------------------------
//	ZMA: CZMA_ERROR
// ====================================================================
//	2019/05/02	t.hara
// --------------------------------------------------------------------

#pragma once

#include <fstream>
#include <string>
#include <vector>

enum class CZMA_ERROR_CODE {
	INVALID_COMMAND,
	ILLEGAL_OPERAND,
	ILLEGAL_PARAMETER,
	ILLEGAL_EXPRESSION,
	ILLEGAL_CONDITION,
	TOO_MANY_PARAMETERS,
	DEFAULT_CHAR_SET_CANNOT_BE_MAPPED_AND_CHANGED,
	CANNOT_OPEN_THE_FILE,
	CANNOT_EVALUATE_THE_EXPRESSION,
	MULTIPLE_DEFINITION,
	LABEL_IS_INDETERMINATE,
	REPEAT_COUNTER_IS_NO_FIXED,
	MUST_BE_SET_NAME,
};

class CZMA_ERROR {
public:
	void put_error( CZMA_ERROR_CODE code, std::string message );
	void put_structure_error( CZMA_ERROR_CODE code, std::string message );
};
