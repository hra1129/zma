// --------------------------------------------------------------------
//	Z80 Macro Assembler parse
// ====================================================================
//	2019/05/04	t.hara
// --------------------------------------------------------------------

#pragma once

#include "zma_parse_process.hpp"
#include "zma_text.hpp"

// --------------------------------------------------------------------
class CZMA_MACRO_ARG{
public:
	std::string		name;			//	�����̖��O
	bool			is_through;		//	false: ���ʂ̈���, true: @�t������

	// --------------------------------------------------------------------
	CZMA_MACRO_ARG(): name( "" ), is_through( false ){
	}
};

// --------------------------------------------------------------------
class CZMA_PARSE_MACRO: public CZMA_PARSE{
public:
	std::vector< CZMA_MACRO_ARG >	parameter_name_list;		//	�������X�g
	CZMA_TEXT m_text;											//	�W�J�O�̃\�[�X�R�[�h
	CZMA_LOG log_header;

	using CZMA_PARSE::CZMA_PARSE;
	bool process( CZMA_INFORMATION &info, CZMA_PARSE *p_last_line = nullptr ) override;
	void block_structure( std::vector<CZMA_PARSE *> &m_text, std::vector<CZMA_PARSE *>::iterator &pp_current ) override;
	std::vector< std::vector< std::string > > get_words( void ) override;
	bool write_output_and_log( CZMA_INFORMATION &info, std::ofstream *f ) override;
};

CLASS_CZMA_PARSE( ENDM );

// --------------------------------------------------------------------
class CZMA_PARSE_MACRO_INS: public CZMA_PARSE {
public:
	CZMA_TEXT m_text;
	CZMA_LOG log_header;
	bool is_loaded = false;

	using CZMA_PARSE::CZMA_PARSE;
	bool process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line = nullptr ) override;
	bool write_output_and_log( CZMA_INFORMATION& info, std::ofstream* f ) override;
};
