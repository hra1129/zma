// --------------------------------------------------------------------
//	ZMA: CZMA_TEXT
// ====================================================================
//	2019/05/02	t.hara
// --------------------------------------------------------------------

#pragma once

#include <vector>
#include <string>
#include "zma_parse.hpp"

class CZMA_TEXT {
private:
	int	code_size;
	int next_code_address;

public:
	std::vector<CZMA_PARSE*> m_text;

	// --------------------------------------------------------------------
	int get_code_size( void ) const{
		return code_size;
	}

	// --------------------------------------------------------------------
	int get_next_code_address( void ) const{
		return next_code_address;
	}

	// --------------------------------------------------------------------
	void calc_code_size( void );

	// --------------------------------------------------------------------
	bool check_data_fixed( void );

	// ----------------------------------------------------------------
	//	Constructor
	// ----------------------------------------------------------------
	CZMA_TEXT();

	// ----------------------------------------------------------------
	//	Destructor
	// ----------------------------------------------------------------s
	~CZMA_TEXT();

	// ----------------------------------------------------------------
	//	File Load
	//	input)
	//		p_file_name .... Target file name
	//	result)
	//		true .... Success
	//		false ... failer
	//	comment)
	//		Read the target file and convert to line array.
	// ----------------------------------------------------------------
	bool load( CZMA_INFORMATION& info, const char* p_file_name );

	// ----------------------------------------------------------------
	//	File Save
	//	input)
	//		p_file_name .... Write file name
	//	result)
	//		true .... Success
	//		false ... failer
	//	comment)
	//		Write result.
	// ----------------------------------------------------------------
	bool save( CZMA_INFORMATION& info, const char* p_file_name );
	bool write( CZMA_INFORMATION& info, std::ofstream* f );

	CZMA_PARSE* process( CZMA_INFORMATION& info, unsigned int& success_count, CZMA_PARSE* p_prev_line, bool output_mode );

	void analyze_structure( void );
	bool all_process( CZMA_INFORMATION &info );
};