// --------------------------------------------------------------------
//	Z80 Macro Assembler dictionary
// ====================================================================
//	2019/05/05	t.hara
// --------------------------------------------------------------------

#pragma once

#include <string>
#include <map>
#include <vector>
#include <fstream>
#include <iomanip>

// --------------------------------------------------------------------
enum class CVALUE_TYPE {
	CV_UNKNOWN,
	CV_INTEGER,
	CV_STRING,
};

// --------------------------------------------------------------------
class CVALUE {
public:
	CVALUE_TYPE value_type;

	int			i;
	std::string	s;

	// --------------------------------------------------------------------
	CVALUE(): value_type( CVALUE_TYPE::CV_UNKNOWN ), i( 0 ), s( "" ) {
	}
};

// --------------------------------------------------------------------
class CZMA_MACRO_ARG {
public:
	std::string						name;
	bool							is_through;

	// --------------------------------------------------------------------
	CZMA_MACRO_ARG(): name( "" ), is_through( false ) {
	}
};

// --------------------------------------------------------------------
class CZMA_MACRO {
public:
	std::vector< CZMA_MACRO_ARG >	parameter_name_list;
	std::vector<class CZMA_PARSE*>	m_text;
};

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
class CZMA_IF_SUB_T {
public:
	bool							is_condition_fixed = false;
	bool							is_condition = false;
	class CZMA_PARSE_IF				*p_if = nullptr;
	class CZMA_TEXT					*p_text = nullptr;
};

// --------------------------------------------------------------------
class CZMA_IF_T {
public:
	std::vector<CZMA_IF_SUB_T*>		m_sub;
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
	std::ofstream					log;
	std::vector< std::string >		include_path;

	unsigned int auto_label_index;

	enum class BLOCK_TYPE_T {
		CZMA_INFO_UNKNOWN,
		CZMA_INFO_MACRO_BLOCK,
		CZMA_INFO_REPEAT_BLOCK,
		CZMA_INFO_IF_BLOCK,
	};
	std::map< std::string, BLOCK_TYPE_T >	block_begin_table{ { "REPEAT", { BLOCK_TYPE_T::CZMA_INFO_REPEAT_BLOCK } },
													{ "ELSEIF", BLOCK_TYPE_T::CZMA_INFO_IF_BLOCK }, { "ELSE", BLOCK_TYPE_T::CZMA_INFO_IF_BLOCK }, { "IF", { BLOCK_TYPE_T::CZMA_INFO_IF_BLOCK } } };
	std::map< std::string, BLOCK_TYPE_T >	block_end_table{ { "ENDM", BLOCK_TYPE_T::CZMA_INFO_MACRO_BLOCK }, { "ENDR", BLOCK_TYPE_T::CZMA_INFO_REPEAT_BLOCK },
													{ "ELSEIF", BLOCK_TYPE_T::CZMA_INFO_IF_BLOCK }, { "ELSE", BLOCK_TYPE_T::CZMA_INFO_IF_BLOCK }, { "ENDIF", BLOCK_TYPE_T::CZMA_INFO_IF_BLOCK }  };
	bool is_updated;
	bool is_block_processing;
	BLOCK_TYPE_T block_type;
	std::vector<class CZMA_PARSE*>			*p_text;

	CZMA_MACRO* p_macro;
	std::map< std::string, CZMA_MACRO* >	macro_list;
	std::map< std::string, std::string >	parameter_list;

	CZMA_REPEAT_T*							p_repeat;

	CZMA_IF_T*								p_if;

	std::map< std::string, CZMA_CHAR_SET >	char_set_list;
	CZMA_CHAR_SET*							p_char_set;
	std::string								s_char_set;

	// --------------------------------------------------------------------
	CZMA_INFORMATION(): is_updated( false ), is_block_processing( false ), block_type( BLOCK_TYPE_T::CZMA_INFO_UNKNOWN  ), auto_label_index( 0 ), p_text( nullptr ), p_macro( nullptr ), p_if( nullptr ), p_repeat( nullptr ), p_char_set( nullptr ){
	}

	// --------------------------------------------------------------------
	unsigned int get_auto_label_index( void ) {
		return auto_label_index++;
	}

	// --------------------------------------------------------------------
	std::string get_scope_path( void ) const {
		std::string r = "";
		for( std::string s : scope ) {
			r = r + s + ":";
		}
		return r;
	}

	// --------------------------------------------------------------------
	bool get_label_value( CVALUE& result, std::string word ) {
		int i, l;
		std::string s;

		for( l = (int)scope.size(); l >= 0; l-- ) {
			s = "";
			for( i = 0; i < l; i++ ) {
				s = s + scope[i] + ":";
			}
			s = s + word;
			if( this->dict.count( s ) ) {
				result = this->dict[s];
				return true;
			}
		}
		result.value_type = CVALUE_TYPE::CV_UNKNOWN;
		return false;
	}

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
	void add_include_path( const char* p_path, const char *p_sub_path = "" ) {
		std::string s = p_path;

		for( int i = (int)s.size() - 1; i >= 0; i-- ) {
			if( s[i] == '/' || s[i] == '\\' ) {
				s = s.substr( 0, i );
				break;
			}
		}
		include_path.push_back( s + "/" + p_sub_path );
	}

	// --------------------------------------------------------------------
	std::string dot( std::string s, int max_length ){
		int length = max_length - s.size();
		std::string s_result = " ";
		for( int i = 0; i < length; i++ ){
			s_result = s_result + ".";
		}
		return s_result;
	}

	// --------------------------------------------------------------------
	void write( void ) {
		std::string s;
		log << "<< label >>" << std::endl;
		size_t max_label_length = 0;
		for( auto item : dict ){
			if( item.first.size() > max_label_length ){
				max_label_length = item.first.size();
			}
		}
		max_label_length += 3;
		for( auto item : dict ) { 
			s = dot( item.first, max_label_length );
			if( item.second.value_type == CVALUE_TYPE::CV_INTEGER ) {
				log << item.first << s << " " << std::dec << item.second.i << " ( 0x" << std::hex << item.second.i << " )" << std::endl;
			}
			else if( item.second.value_type == CVALUE_TYPE::CV_STRING ) {
				log << item.first << s << " \"" << item.second.s << "\"" << std::endl;
			}
			else {
				log << item.first << s << " ????" << std::endl;
			}
		}

		std::ofstream sym_file;
		sym_file.open( "zma.sym", std::ios::out );
		if( !sym_file ){
			return;
		}
		for( auto item : dict ){
			if( item.second.value_type != CVALUE_TYPE::CV_INTEGER ){
				continue;
			}
			sym_file << item.first << " equ 0" << std::hex << item.second.i << "h" << std::endl;
		}
		sym_file.close();
	}
};
