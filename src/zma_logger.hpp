// --------------------------------------------------------------------
//	ZMA: CZMA_TEXT
// ====================================================================
//	2019/05/02	t.hara
// --------------------------------------------------------------------

#pragma once

#include <fstream>
#include <string>
#include <vector>

class CZMA_LOG: public std::vector< std::string > {
public:

	// --------------------------------------------------------------------
	//	Separator
	void write_separator( void );

	// --------------------------------------------------------------------
	//	Hexadecimal
	std::string convert_to_hex( int value, int columns );

	// --------------------------------------------------------------------
	//	Dump
	void write_dump( int address, int offset, std::vector<unsigned char> &data );

	// --------------------------------------------------------------------
	//	LINE#:ADRS:OFFSET:MNEMONIC
	void write_line_infomation( int line_no, int address, int offset, const std::string &s_line_image );

	// --------------------------------------------------------------------
	//	Write message
	void write_message( const std::string &s_message );

	// --------------------------------------------------------------------
	//	Write error message
	void write_error_message( const char *p_file_name, int line_no, const std::string &s_message );

	// --------------------------------------------------------------------
	//	Cycles information
	void write_cycle_information( int z80_cycle, int r800_cycle, int z80_cycle2 = -1, int r800_cycle2 = -1, const std::string s_comment = "");
};
