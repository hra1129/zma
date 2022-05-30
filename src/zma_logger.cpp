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
std::string CZMA_LOG::convert_to_hex( int value, int columns ){
	std::stringstream s;

	if( value == 0xFFFFFFFF ){
		s << std::setw( columns ) << std::setfill( 'X' ) << "X";
	}
	else{
		s << std::setw( columns ) << std::hex << std::right << std::setfill( '0' ) << std::uppercase << value;
	}
	return s.str();
}


// --------------------------------------------------------------------
void CZMA_LOG::write_separator( void ) {
	this->push_back( "------+----+------+----------------------------------" );
}

// --------------------------------------------------------------------
void CZMA_LOG::write_line_infomation( int line_no, int address, int offset, const std::string &s_line_image ){
	std::stringstream s;

	s << std::dec << std::setw(6) << std::right << line_no << "|    |      |" << s_line_image;
	this->push_back( s.str() );
}

// --------------------------------------------------------------------
void CZMA_LOG::write_cycle_information( int z80_cycle, int r800_cycle, int z80_cycle2, int r800_cycle2, const std::string s_comment ){
	std::stringstream s;

	s << "      |    |      |  ";
	if( z80_cycle2 >= 0 ){
		s << "Z80:" << z80_cycle << "cyc/" << z80_cycle << "cyc";
	}
	else if( z80_cycle >= 0 ){
		s << "Z80:" << z80_cycle << "cyc";
	}
	else{
		s << "Z80:---";
	}
	if( r800_cycle2 >= 0 ){
		s << "R800:" << r800_cycle << "cyc/" << r800_cycle << "cyc";
	}
	else if( r800_cycle >= 0 ){
		s << ", R800:" << r800_cycle << "cyc";
	}
	else{
		s << ", R800:---";
	}
	s << s_comment;
	this->push_back( s.str() );
}

// --------------------------------------------------------------------
void CZMA_LOG::write_dump( int address, int offset, std::vector<unsigned char> &data ){
	int count;
	std::stringstream line;
	count = 0;
	for( auto d : data ){
		if( count == 0 ){
			line << "      |" << convert_to_hex( address, 4 ) << '|' << convert_to_hex( offset, 6 ) << "| ";
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