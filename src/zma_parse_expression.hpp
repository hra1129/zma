// --------------------------------------------------------------------
//	Z80 Macro Assembler dictionary
// ====================================================================
//	2019/05/05	t.hara
// --------------------------------------------------------------------

#include <string>
#include <map>
#include <vector>
#include <fstream>
#include <sstream>
#include <iomanip>

#ifndef __ZMA_PARSE_EXPRESSION_HPP__
#define __ZMA_PARSE_EXPRESSION_HPP__

// --------------------------------------------------------------------
enum class CVALUE_TYPE {
	CV_UNKNOWN = 0x100,
	CV_UNKNOWN_INTEGER = 0x101,
	CV_UNKNOWN_STRING = 0x102,
	CV_INTEGER = 0x1,
	CV_STRING = 0x2,
};

// --------------------------------------------------------------------
class CVALUE {
public:
	CVALUE_TYPE value_type;

	int			i;
	std::string	s;

	// --------------------------------------------------------------------
	CVALUE(): value_type( CVALUE_TYPE::CV_UNKNOWN ), i( 0 ), s( "" ) {
	}

	// --------------------------------------------------------------------
	bool is_unknown( void ) const{
		return ( ( (int)value_type & 0x100 ) == 0x100 );
	}

	// --------------------------------------------------------------------
	bool is_integer( void ) const{
		return ( ( (int)value_type & 0xFF ) == 0x1 );
	}

	// --------------------------------------------------------------------
	bool is_string( void ) const{
		return ( ( (int)value_type & 0xFF ) == 0x2 );
	}

	// --------------------------------------------------------------------
	void inherit( CVALUE_TYPE base, CVALUE_TYPE inherit_a, CVALUE_TYPE inherit_b ){
		value_type = (CVALUE_TYPE)( (int)base | ( ( (int)inherit_a | (int)inherit_b ) & 0x100 ) );
	}
};

#endif
