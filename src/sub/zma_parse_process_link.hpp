// --------------------------------------------------------------------
//	Z80 Macro Assembler parse
// ====================================================================
//	2019/05/04	t.hara
// --------------------------------------------------------------------

#pragma once

#include "zma_parse_process.hpp"

// --------------------------------------------------------------------
class CZMA_PARSE_LINK: public CZMA_PARSE {
public:
	std::vector< std::string > trigger_name_list;
	bool is_trigger_evaluated = false;			//	trigger_name_list が作成済みか否か

	bool is_evaluated = false;					//	使用確認チェックを終えたか否か
	bool is_used = false;						//	true:使用する, false:使用しない
	CZMA_TEXT m_text;							//	展開前のソースコード
	CZMA_LOG log_header;

	using CZMA_PARSE::CZMA_PARSE;
	bool process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line = nullptr ) override;
	void block_structure( std::vector<CZMA_PARSE *> &m_text, std::vector<CZMA_PARSE *>::iterator &pp_current ) override;
	std::vector< std::vector< std::string > > get_words( void );
	bool write_output_and_log( CZMA_INFORMATION &info, std::ofstream *f ) override;
};

CLASS_CZMA_PARSE( ENDL );
