// --------------------------------------------------------------------
//	Z80 Macro Assembler ZMA
// ====================================================================
//	2019/05/02	t.hara
// --------------------------------------------------------------------

#include <iostream>
#include "zma_text.hpp"

static const char* p_version = "v1.0.16-alpha";

// --------------------------------------------------------------------
static void usage( const char* p_name ) {
	std::cerr << "Usage> " << p_name << " <input.asm> <output.bin>\n";
	std::cerr << "This is Z80/R800 Macro Assembler.\n";
}

// --------------------------------------------------------------------
int main( int argc, char *argv[] ) {
    std::cout << "Z80 Macro Assembler ZMA " << p_version << "\n";
	std::cout << "=====================================================\n";
	std::cout << "Programmed by t.hara\n";

	if( argc < 3 ) {
		usage( argv[0] );
		return 1;
	}

	CZMA_TEXT src;
	CZMA_INFORMATION info;

	info.log.open( "zma.log", std::ios::out );
	info.log << "Z80 Macro Assembler ZMA " << p_version << "\n";
	info.log << "=====================================================\n";
	info.log << "Programmed by t.hara\n\n";
	info.log << "<< code >>\n";
	info.log << "LINE# |ADRS|OFFSET|MNEMONIC\n";
	info.log << "======+====+======+==================================\n";
	info.add_include_path( "./" );
	info.add_include_path( argv[0], "include/" );
	src.load( info, argv[1] );

	int return_code = 0;
	if( src.all_process( info ) ) {
		return_code = 0;
		std::cout << "Success.\n";
	}
	else {
		return_code = 1;
		std::cout << "Failed.\n";
	}
	if( !src.save( info, argv[ 2 ] ) ){
		return_code = 1;
		std::cout << "Save error.\n";
	}
	return return_code;
}
