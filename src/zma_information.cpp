// --------------------------------------------------------------------
//	Z80 Macro Assembler dictionary
// ====================================================================
//	2019/05/05	t.hara
// --------------------------------------------------------------------

#include "zma_information.hpp"

// --------------------------------------------------------------------
bool CZMA_INFORMATION::get_label_value( CVALUE &result, std::string word ){
	int i, l;
	std::string s;

	for( l = (int)scope.size(); l >= 0; l-- ){
		s = "";
		for( i = 0; i < l; i++ ){
			s = s + scope[ i ] + ":";
		}
		s = s + word;
		if( this->dict.count( s ) ){
			result = this->dict[ s ];
			return true;
		}
	}
	result.value_type = CVALUE_TYPE::CV_UNKNOWN;
	return false;
}

// --------------------------------------------------------------------
std::string CZMA_INFORMATION::get_scope_path( void ) {
	std::string r = "";
	for( std::string s : scope ){
		r = r + s + ":";
	}
	return r;
}

// --------------------------------------------------------------------
void CZMA_INFORMATION::add_include_path( const char *p_path, const char *p_sub_path ){
	std::string s = p_path;

	for( int i = (int)s.size() - 1; i >= 0; i-- ){
		if( s[ i ] == '/' || s[ i ] == '\\' ){
			s = s.substr( 0, i );
			break;
		}
	}
	include_path.push_back( s + "/" + p_sub_path );
}

// --------------------------------------------------------------------
std::string CZMA_INFORMATION::dot( std::string s, int max_length ){
	int length = max_length - (int)s.size();
	std::string s_result = " ";
	for( int i = 0; i < length; i++ ){
		s_result = s_result + ".";
	}
	return s_result;
}

// --------------------------------------------------------------------
void CZMA_INFORMATION::write( void ){
	int i, j;
	unsigned char c;
	std::string s;
	std::stringstream s_dump;
	if( dict.size() ){
		log << "<< label >>" << std::endl;
		size_t max_label_length = 0;
		for( auto item : dict ){
			if( item.first.size() > max_label_length ){
				max_label_length = item.first.size();
			}
		}
		max_label_length += 3;
		for( auto &item : dict ){
			s = dot( item.first, (int)max_label_length );
			if( item.second.value_type == CVALUE_TYPE::CV_INTEGER ){
				log << item.first << s << " " << std::dec << item.second.i << " ( 0x" << std::hex << item.second.i << " )" << std::endl;
			}
			else if( item.second.value_type == CVALUE_TYPE::CV_STRING ){
				log << item.first << s << " \"" << item.second.s << "\"" << std::endl;
			}
			else{
				log << item.first << s << " ????" << std::endl;
			}
		}
	}

	if( char_set_list.size() ){
		log << "<< character map >>" << std::endl;
		for( auto &item : char_set_list ){
			log << "[" << item.first << "]" << std::endl;
			for( i = 0; i < 256; i += 8 ){
				s_dump.str( "" );
				for( j = 0; j < 8; j++ ){
					//	ƒ_ƒ“ƒv
					c = i + j;
					c = item.second.ascii_to_map[ c ];
					s_dump << std::hex << std::setw( 2 ) << std::setfill( '0' ) << (int)c << " ";
					//	‹L†
					c = i + j;
					if( c < 32 ){
						c = 32;
					}
					else if( c >= 0x7F ){
						c = '?';
					}
					log << c;
				}
				log << ":" << s_dump.str() << std::endl;
			}
			log << std::endl;
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
