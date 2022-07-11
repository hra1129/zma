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
	bool is_trigger_evaluated = false;			//	trigger_name_list ���쐬�ς݂��ۂ�

	bool is_evaluated = false;					//	�g�p�m�F�`�F�b�N���I�������ۂ�
	bool is_used = false;						//	true:�g�p����, false:�g�p���Ȃ�
	CZMA_TEXT m_text;							//	�W�J�O�̃\�[�X�R�[�h
	CZMA_LOG log_header;

	using CZMA_PARSE::CZMA_PARSE;
	bool process( CZMA_INFORMATION& info, CZMA_PARSE* p_last_line = nullptr ) override;
	void block_structure( std::vector<CZMA_PARSE *> &m_text, std::vector<CZMA_PARSE *>::iterator &pp_current ) override;
	std::vector< std::vector< std::string > > get_words( void );
	bool write_output_and_log( CZMA_INFORMATION &info, std::ofstream *f ) override;
};

CLASS_CZMA_PARSE( ENDL );
