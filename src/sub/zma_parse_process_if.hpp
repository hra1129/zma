// --------------------------------------------------------------------
//	Z80 Macro Assembler parse
// ====================================================================
//	2019/05/04	t.hara
// --------------------------------------------------------------------

#include "zma_parse_process.hpp"

// --------------------------------------------------------------------
class CZMA_PARSE_IF: public CZMA_PARSE {
public:
	bool is_condition_fixed = false;
	bool is_condition = false;
	CZMA_TEXT m_text;

	using CZMA_PARSE::CZMA_PARSE;
	bool process( CZMA_INFORMATION &info, CZMA_PARSE *p_last_line = nullptr ) override;
	void block_structure( std::vector<CZMA_PARSE *> &m_text, std::vector<CZMA_PARSE *>::iterator &pp_current ) override;
	bool write_output_and_log( CZMA_INFORMATION &info, std::ofstream *f ) override;
	void set_output_mode( void ) override;
	std::vector< std::vector< std::string > > get_words( void ) override;
};

// --------------------------------------------------------------------
class CZMA_PARSE_ELSEIF: public CZMA_PARSE_IF{
public:
	using CZMA_PARSE_IF::CZMA_PARSE_IF;
	bool process( CZMA_INFORMATION &info, CZMA_PARSE *p_last_line = nullptr ) override;
	void block_structure( std::vector<CZMA_PARSE *> &m_text, std::vector<CZMA_PARSE *>::iterator &pp_current ) override;
};

// --------------------------------------------------------------------
class CZMA_PARSE_ELSE: public CZMA_PARSE_IF {
public:
	using CZMA_PARSE_IF::CZMA_PARSE_IF;
	bool process( CZMA_INFORMATION &info, CZMA_PARSE *p_last_line = nullptr ) override;
	void block_structure( std::vector<CZMA_PARSE *> &m_text, std::vector<CZMA_PARSE *>::iterator &pp_current ) override;
};

// --------------------------------------------------------------------
CLASS_CZMA_PARSE( ENDIF );

// --------------------------------------------------------------------
class CZMA_IF_BLOCK_T{
public:
	CZMA_PARSE_IF *p_if;
	std::map< std::string, CVALUE >	dict;

	CZMA_IF_BLOCK_T(): p_if( nullptr ){
	}
};

// --------------------------------------------------------------------
class CZMA_PARSE_IF_BLOCK: public CZMA_PARSE{
public:
	bool is_condition_fixed = false;
	std::vector<CZMA_IF_BLOCK_T *>	m_sub;

	int calc_code_size( CZMA_INFORMATION &info, CZMA_IF_BLOCK_T *p_block, CZMA_PARSE *p_last_line, int &next_code_address );
	void update_condition( CZMA_INFORMATION &info, CZMA_PARSE *p_last_line );
	void update_code_size( CZMA_INFORMATION &info, CZMA_PARSE *p_last_line );
	std::vector< std::vector< std::string > > get_words( void ) override;

	using CZMA_PARSE::CZMA_PARSE;
	bool sub_process( CZMA_INFORMATION &info, CZMA_PARSE *p_last_line );
	bool process( CZMA_INFORMATION &info, CZMA_PARSE *p_last_line = nullptr ) override;
	bool write_output_and_log( CZMA_INFORMATION &info, std::ofstream *f ) override;
	void set_output_mode( void ) override;
};
