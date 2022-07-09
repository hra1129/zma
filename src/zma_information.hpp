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
#include "zma_error.hpp"
#include "zma_hexfile.hpp"
#include "zma_parse_process.hpp"
#include "zma_parse_expression.hpp"

#ifndef __ZMA_INFORMATION_HPP__
#define __ZMA_INFORMATION_HPP__

class CZMA_PARSE_MACRO;

// --------------------------------------------------------------------
//class CZMA_MACRO {
//public:
//	std::vector< CZMA_MACRO_ARG >	parameter_name_list;
//	std::vector<class CZMA_PARSE*>	m_text;
//};

// --------------------------------------------------------------------
class CZMA_REPEAT_T {
public:
	std::string						counter_symbol;
	int								counter_end;
	bool							is_counter_end_fixed;
	std::string						scope_name;
	std::vector<class CZMA_PARSE*>	m_text;

	// --------------------------------------------------------------------
	CZMA_REPEAT_T(): counter_symbol( "" ), counter_end( 0 ), is_counter_end_fixed( false ), scope_name( "" ) {
	}
};

// --------------------------------------------------------------------
class CZMA_CHAR_SET {
public:
	std::vector< unsigned char >	ascii_to_map;
};

// --------------------------------------------------------------------
class CZMA_INFORMATION {
public:
	std::map< std::string, CVALUE >	dict;
	std::map< std::string, CVALUE >	*p_sub_dict;
	std::map< std::string, int >	sss_or_ddd_id { { "B", 0 }, { "C", 1 }, { "D", 2 }, { "E", 3 }, { "H", 4 }, { "L", 5 }, { "A", 7 }, };
	std::map< std::string, int >	ix_hl{ { "IXH", 4 }, { "IXL", 5 }, };
	std::map< std::string, int >	iy_hl{ { "IYH", 4 }, { "IYL", 5 }, };
	std::map< std::string, int >	rp_id { { "BC", 0 }, { "DE", 1 }, { "HL", 2 }, { "SP", 3 }, };
	std::map< std::string, int >	ix_rp_id{ { "BC", 0 }, { "DE", 1 }, { "IX", 2 }, { "SP", 3 }, };
	std::map< std::string, int >	iy_rp_id{ { "BC", 0 }, { "DE", 1 }, { "IY", 2 }, { "SP", 3 }, };
	std::map< std::string, int >	rp_with_af_id{ { "BC", 0 }, { "DE", 1 }, { "HL", 2 }, {"AF", 3 }, };
	std::map< std::string, int >	ccc_id{ { "NZ", 0 }, { "Z", 1 }, { "NC", 2 }, { "C", 3 }, { "PO", 4 }, { "PE", 5 }, { "P", 6 }, { "M", 7 }, };
	std::map< std::string, int >	cc2_id{ { "NZ", 0 }, { "Z", 1 }, { "NC", 2 }, { "C", 3 }, };
	std::vector< std::string >		scope;
	std::vector< std::string >		include_path;

	unsigned int auto_label_index;

	bool		defs_is_space;		//	false: DEFS疑似命令は文字列配置(default), true: DEFS疑似命令は領域確保
	bool		all_error_enable;	//	false: アドレス未確定以降のエラーを抑止, true: 全てのエラーを表示
	bool		error_disable;

	enum class OUTPUT_TYPE{
		CZMA_BINARY,
		CZMA_INTELHEX,
	};
	OUTPUT_TYPE	output_type;
	CZMA_HEXFILE_WRITER hexfile;
	bool is_updated;

	std::map< std::string, CZMA_PARSE_MACRO* >	macro_list;
	std::map< std::string, CZMA_CHAR_SET >		char_set_list;
	CZMA_CHAR_SET*								p_char_set;
	std::string									s_char_set;

	CZMA_ERROR									error;
	std::ofstream								log;

	// --------------------------------------------------------------------
	CZMA_INFORMATION(): is_updated( false ), 
			auto_label_index( 0 ), p_sub_dict( nullptr ),
			p_char_set( nullptr ), defs_is_space(false),
			output_type( OUTPUT_TYPE::CZMA_BINARY ),
			error_disable( false ), all_error_enable( false ) {
	}

	// --------------------------------------------------------------------
	void clear( void ){
		scope.clear();
		p_char_set = nullptr;
		s_char_set = "DEFAULT";
		is_updated = false;
		auto_label_index = 0;
		error_disable = false;
	}

	// --------------------------------------------------------------------
	unsigned int get_auto_label_index( void ) {
		return auto_label_index++;
	}

	// --------------------------------------------------------------------
	std::string get_scope_path( void );

	// --------------------------------------------------------------------
	bool get_label_value( CVALUE &result, std::string word );

	// --------------------------------------------------------------------
	bool is_sss_or_ddd( std::string word ) const {
		int d = (int)sss_or_ddd_id.count( word );
		return d;
	}

	// --------------------------------------------------------------------
	bool is_ix_hl( std::string word ) const {
		int d = (int)ix_hl.count( word );
		return d;
	}

	// --------------------------------------------------------------------
	bool is_iy_hl( std::string word ) const {
		int d = (int)iy_hl.count( word );
		return d;
	}

	// --------------------------------------------------------------------
	bool is_rp( std::string word ) const {
		return (int)rp_id.count( word );
	}

	// --------------------------------------------------------------------
	bool is_ix_rp( std::string word ) const{
		return (int)ix_rp_id.count( word );
	}

	// --------------------------------------------------------------------
	bool is_iy_rp( std::string word ) const{
		return (int)iy_rp_id.count( word );
	}

	// --------------------------------------------------------------------
	bool is_rp_with_af( std::string word ) const {
		return (int)rp_with_af_id.count( word );
	}

	// --------------------------------------------------------------------
	bool is_ccc( std::string word ) const {
		return (int)ccc_id.count( word );
	}

	// --------------------------------------------------------------------
	bool is_cc2( std::string word ) const {
		return (int)cc2_id.count( word );
	}

	// --------------------------------------------------------------------
	void add_include_path( const char *p_path, const char *p_sub_path = "" );

	// --------------------------------------------------------------------
	std::string dot( std::string s, int max_length );

	// --------------------------------------------------------------------
	void write( void );
};

#endif
