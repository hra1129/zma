// --------------------------------------------------------------------
//	HEX FILE WRITER
// ====================================================================
//	2022/06/19	t.hara
// --------------------------------------------------------------------

#include <fstream>
#include <vector>

class CZMA_HEXFILE_WRITER {
private:
	int								address;
	int								last_segment;
	std::vector< unsigned char >	data;
public:
	// --------------------------------------------------------------------
	CZMA_HEXFILE_WRITER(): address(0), last_segment(0) {
	}

	// --------------------------------------------------------------------
	unsigned char write_byte( std::ofstream &f, unsigned char c, unsigned char check_sum );

	// --------------------------------------------------------------------
	void flush( std::ofstream &f );

	// --------------------------------------------------------------------
	void update_segment( std::ofstream &f );

	// --------------------------------------------------------------------
	void set_address( std::ofstream &f, int new_address );

	// --------------------------------------------------------------------
	void write( std::ofstream &f, unsigned char c );
};
