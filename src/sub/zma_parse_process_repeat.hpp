// --------------------------------------------------------------------
//	Z80 Macro Assembler parse
// ====================================================================
//	2019/05/04	t.hara
// --------------------------------------------------------------------

#pragma once

#include "zma_parse_process.hpp"

// --------------------------------------------------------------------
class CZMA_PARSE_REPEAT: public CZMA_PARSE {
public:
	std::vector< CZMA_TEXT * > m_text_list;		//	展開後のソースコード
	bool is_loaded;								//	m_text_list に展開済みか否か

	std::string counter_symbol;
	int counter_end;
	bool is_counter_end_fixed;
	std::string scope_name;
	CZMA_TEXT m_text;							//	展開前のソースコード
	CZMA_LOG log_header;

	using CZMA_PARSE::CZMA_PARSE;
	bool process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line = nullptr ) override;
	void block_structure( std::vector<CZMA_PARSE *> &m_text, std::vector<CZMA_PARSE *>::iterator &pp_current ) override;
	std::vector< std::vector< std::string > > get_words( void );
	bool write_output_and_log( CZMA_INFORMATION &info, std::ofstream *f ) override;
};

// --------------------------------------------------------------------
class CZMA_PARSE_ENDR: public CZMA_PARSE {
public:
	CZMA_REPEAT_T* p_repeat = nullptr;
	bool is_loaded = false;

	using CZMA_PARSE::CZMA_PARSE;
	bool process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line = nullptr ) override;
};
