// --------------------------------------------------------------------
//	Z80 Macro Assembler ZMA
// ====================================================================
//	2019/05/02	t.hara
// --------------------------------------------------------------------

#include <iostream>
#include <vector>
#include <string>
#include <algorithm>
#include "zma_text.hpp"

static const char* p_version = "v1.0.16";

// --------------------------------------------------------------------
static void usage( const char* p_name ) {
	std::cerr << "Usage> " << p_name << " [-options] <input.asm> <output.bin>\n";
	std::cerr << "This is Z80/R800 Macro Assembler.\n";
	std::cerr << "[-options]\n";
	std::cerr << "  -HELP, -H ........... Display this message.\n";
	std::cerr << "  -I{path} ............ Add {path} to the include path.\n";
	std::cerr << "  -D{name}={value} .... Define symbol. ex) -DSWITCH=1 -DNAME='GAME'\n";
	std::cerr << "  -DEFS ............... Change the DEFS instruction to an area allocation instruction.\n";
	std::cerr << "  -HEX ................ Output file is a HEX file.\n";
	std::cerr << "  -EALL ............... Detailed error display.\n";
}

// --------------------------------------------------------------------
static void option_d( CZMA_INFORMATION &info, std::string s_argument ){
	std::string s_name;
	std::string s_value;
	CVALUE value;
	size_t i;

	for( i = 2; i < s_argument.size(); i++ ){
		if( s_argument[ i ] == '=' ){
			break;
		}
		s_name = s_name + s_argument[ i ];
	}
	i++;
	for( ; i < s_argument.size(); i++ ){
		s_value = s_value + s_argument[ i ];
	}
	if( s_name == "" || s_value == "" ){
		std::cerr << "Invalid command line option [" << s_argument << "].\n";
		return;
	}
	if( s_value.size() > 0 && s_value[ 0 ] == '\'' ){
		if( s_value[ s_value.size() - 1 ] != '\'' ){
			std::cerr << "Invalid command line option [" << s_argument << "].\n";
			return;
		}
		s_value = s_value.substr( 1, s_value.size() - 2 );
		value.value_type = CVALUE_TYPE::CV_STRING;
		value.s = s_value;
		info.log << "  String : " << s_name << " = \"" << value.s << "\"\n";
	}
	else{
		value.value_type = CVALUE_TYPE::CV_INTEGER;
		try{
			value.i = std::stoi( s_value );
		}
		catch( ... ){
			value.i = 0;
		}
		info.log << "  Integer: " << s_name << " = " << value.i << "\n";
	}
	info.dict[ s_name ] = value;
}

// --------------------------------------------------------------------
static std::vector<std::string> get_command_line_options( int argc, char *argv[], CZMA_INFORMATION &info ){
	int i;
	std::string s_argument;
	std::vector<std::string> sa_options;

	for( i = 1; i < argc; i++ ){
		s_argument = argv[ i ];
		if( s_argument[ 0 ] == '-' || s_argument[ 0 ] == '/' ){
			s_argument[ 0 ] = '-';
			std::transform( s_argument.begin(), s_argument.end(), s_argument.begin(), toupper );
			if( s_argument == "-H" || s_argument == "-HELP" ){
				usage( argv[ 0 ] );
				exit( 1 );
			}
			else if( s_argument == "-DEFS" ){
				info.defs_is_space = true;
			}
			else if( s_argument[ 1 ] == 'I' ){
				info.add_include_path( s_argument.substr( 2 ).c_str() );
			}
			else if( s_argument[ 1 ] == 'D' ){
				option_d( info, s_argument );
			}
			else if( s_argument == "-HEX" ){
				info.output_type = CZMA_INFORMATION::OUTPUT_TYPE::CZMA_INTELHEX;
			}
			else if( s_argument == "-EALL" ){
				info.all_error_enable = true;
			}
		}
		else{
			sa_options.push_back( s_argument );
		}
	}

	if( info.defs_is_space ){
		info.log << "  DEFS is DEFINE SPACE.\n";
	}
	else{
		info.log << "  DEFS is DEFINE STRING (default).\n";
	}

	if( info.output_type == CZMA_INFORMATION::OUTPUT_TYPE::CZMA_BINARY ){
		info.log << "  OUTPUT TYPE: BINARY\n\n";
	}
	else{
		info.log << "  OUTPUT TYPE: INTEL HEX\n\n";
	}
	return sa_options;
}

// --------------------------------------------------------------------
int main( int argc, char *argv[] ) {
    std::cout << "Z80 Macro Assembler ZMA " << p_version << "\n";
	std::cout << "=====================================================\n";
	std::cout << "Programmed by t.hara\n";

	CZMA_TEXT src;
	CZMA_INFORMATION info;
	std::vector< std::string > sa_options;

	info.log.open( "zma.log", std::ios::out );
	info.log << "Z80 Macro Assembler ZMA " << p_version << "\n";
	info.log << "=====================================================\n";
	info.log << "Programmed by t.hara\n\n";

	sa_options = get_command_line_options( argc, argv, info );
	if( sa_options.size() < 2 ) {
		usage( argv[0] );
		return 1;
	}

	info.log << "<< code >>\n";
	info.log << "LINE# |OFFSET|ADDR|MNEMONIC\n";
	info.log << "======+======+====+==================================\n";
	info.add_include_path( "./" );
	info.add_include_path( argv[0], "include/" );
	src.load( info, sa_options[0].c_str() );

	int return_code = 0;
	if( src.all_process( info ) ) {
		return_code = 0;
		std::cout << "Success.\n";
	}
	else {
		return_code = 1;
		std::cout << "Failed.\n";
	}
	if( !src.save( info, sa_options[1].c_str() ) ){
		return_code = 1;
		std::cout << "Save error.\n";
	}
	return return_code;
}
