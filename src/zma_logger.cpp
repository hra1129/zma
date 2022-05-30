// --------------------------------------------------------------------
//	ZMA: CZMA_TEXT
// ====================================================================
//	2019/05/02	t.hara
// --------------------------------------------------------------------

#include "zma_logger.hpp"
#include <iostream>
#include <fstream>
#include <iostream>
#include <iomanip>
#include <sstream>

// --------------------------------------------------------------------
void CZMA_LOG::write_separator( void ) {
	this->push_back( "------+----+------+----------------------------------" );
}

// --------------------------------------------------------------------
void CZMA_LOG::write_line_infomation( int line_no, int address, int offset, const std::string &s_line_image ){
	std::stringstream s;

	s << std::left << std::setw( 6 ) << std::dec << line_no << '|' <<
		std::right << std::setw( 4 ) << std::hex << std::uppercase << std::setfill( '0' ) << address << '|' <<
		std::right << std::setw( 6 ) << std::hex << std::uppercase << std::setfill( '0' ) << offset << '|' << s_line_image;

	this->push_back( s.str() );
}

// --------------------------------------------------------------------
void CZMA_LOG::write_cycle_information( int z80_cycle, int r800_cycle ){
	std::stringstream s;

	s << "      |    |      |  ";
	if( z80_cycle >= 0 ){
		s << "Z80:" << z80_cycle << "cyc";
	}
	else{
		s << "Z80:---";
	}
	if( r800_cycle >= 0 ){
		s << ", R800:" << r800_cycle << "cyc";
	}
	else{
		s << ", R800:---";
	}

	this->push_back( s.str() );
}

// --------------------------------------------------------------------
void CZMA_LOG::write_dump( int address, int offset, std::vector<unsigned char> &data ){
	int count;
	std::stringstream line;
	count = 0;
	for( auto d : data ){
		if( count == 0 ){
			line << "      |" << 
					std::right << std::setw( 4 ) << std::hex << std::uppercase << std::setfill( '0' ) << address << '|' <<
					std::right << std::setw( 6 ) << std::hex << std::uppercase << std::setfill( '0' ) << offset << "| ";
		}
		line << " " << std::right << std::setw( 2 ) << std::hex << std::uppercase << std::setfill( '0' ) << (int)(d & 255);
		address++;
		offset++;
		count++;
		if( count == 8 ){
			push_back( line.str() );
			line.str( "" );
			count = 0;
		}
	}
	if( count != 0 ){
		push_back( line.str() );
	}
}