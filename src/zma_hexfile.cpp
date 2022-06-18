// --------------------------------------------------------------------
//	HEX FILE WRITER
// ====================================================================
//	2022/06/19	t.hara
// --------------------------------------------------------------------

#include "zma_hexfile.hpp"
#include <iomanip>

using namespace std;

// --------------------------------------------------------------------
unsigned char CZMA_HEXFILE_WRITER::write_byte( std::ofstream &f, unsigned char c, unsigned char check_sum ) {

	f << setw(2) << setfill('0') << hex << uppercase << (int)c;
	return check_sum + c;
}

// --------------------------------------------------------------------
void CZMA_HEXFILE_WRITER::flush( ofstream &f ) {
	unsigned char check_sum;
	size_t i;

	if( data.size() == 0 ) {
		return;
	}

	update_segment( f );
	f << ':';
	check_sum = write_byte( f, (unsigned char)data.size(), 0 );
	check_sum = write_byte( f, (unsigned char)(address >> 8), check_sum );
	check_sum = write_byte( f, (unsigned char)(address & 255), check_sum );
	check_sum = write_byte( f, 0, check_sum );
	for( i = 0; i < data.size(); i++ ) {
		check_sum = write_byte( f, data[i], check_sum );
		address++;
		if( (address & 0x0FFFF) == 0 ) {
			break;
		}
	}
	write_byte( f, (unsigned char)(0x100 - check_sum), 0 );
	f << endl;

	if( i == data.size() ) {
		data.clear();
	}
	else {
		data.erase( data.begin(), data.begin()  + i );
		flush( f );
	}
}

// --------------------------------------------------------------------
void CZMA_HEXFILE_WRITER::update_segment( std::ofstream &f ) {
	unsigned char check_sum;

	int current_segment = (address >> 16);
	if( current_segment == last_segment ) {
		return;
	}
	//	: 02 0000 04 XXXX CC
	f << ':';
	check_sum = write_byte( f, 2, 0 );
	check_sum = write_byte( f, 0, check_sum );
	check_sum = write_byte( f, 0, check_sum );
	check_sum = write_byte( f, 4, check_sum );
	check_sum = write_byte( f, (unsigned char)(current_segment >> 8), check_sum );
	check_sum = write_byte( f, (unsigned char)(current_segment & 255), check_sum );
	check_sum = write_byte( f, (unsigned char)(0x100 - check_sum), 0 );
	f << endl;
	last_segment = current_segment;
}

// --------------------------------------------------------------------
void CZMA_HEXFILE_WRITER::set_address( ofstream &f, int new_address ) {

	flush( f );
	address = new_address;
}

// --------------------------------------------------------------------
void CZMA_HEXFILE_WRITER::write( ofstream &f, unsigned char c ) {

	data.push_back( c );
	if( data.size() >= 32 ) {
		flush( f );
	}
}
