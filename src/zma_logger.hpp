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
	//	Dump
	void write_dump( int address, int offset, std::vector<unsigned char> &data );

	// --------------------------------------------------------------------
	//	LINE#:ADRS:OFFSET:MNEMONIC
	void write_line_infomation( int line_no, int address, int offset, const std::string &s_line_image );

	// --------------------------------------------------------------------
	//	Cycles information
	void write_cycle_information( int z80_cycle, int r800_cycle );
};
