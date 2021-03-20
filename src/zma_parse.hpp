// --------------------------------------------------------------------
//	Z80 Macro Assembler parse
// ====================================================================
//	2019/05/04	t.hara
// --------------------------------------------------------------------

#pragma once

#include <string>
#include <vector>
#include <map>
#include "zma_information.hpp"

class CZMA_PARSE {
protected:
	std::vector<unsigned char> data;
	int	code_address;
	int	file_address;
	int	code_size;
	int next_code_address;
	bool is_data_fixed;
	bool is_label_search_state;
	const char* p_file_name;
	int line_no;
	bool is_analyze_phase;
	static int number_of_error;
	std::vector< std::string > log;

	bool is_structure_error;
	std::string structure_error;

	static std::vector<std::string> get_word_split( std::string s );
	static std::string delete_head_space( std::string s );

	bool update_flags( CZMA_INFORMATION *p_info, const CZMA_PARSE* p_last_line );
	bool check_location_hl( int index );
	int check_location_ix( int index );
	int check_location_iy( int index );
	int relative_address( CZMA_INFORMATION &info, int index );
	std::string get_word( int index );
	void log_data_dump( void );

	// --------------------------------------------------------------------
	bool operator_single( CZMA_INFORMATION& info, int &index, CVALUE&result );
	bool operator_mul_div( CZMA_INFORMATION& info, int& index, CVALUE& result );
	bool operator_add_sub( CZMA_INFORMATION& info, int& index, CVALUE& result );
	bool operator_shift( CZMA_INFORMATION& info, int& index, CVALUE& result );
	bool operator_compare( CZMA_INFORMATION& info, int& index, CVALUE& result );
	bool operator_equal( CZMA_INFORMATION& info, int& index, CVALUE& result );
	bool operator_bit_and( CZMA_INFORMATION& info, int& index, CVALUE& result );
	bool operator_bit_xor( CZMA_INFORMATION& info, int& index, CVALUE& result );
	bool operator_bit_or( CZMA_INFORMATION& info, int& index, CVALUE& result );
	bool operator_logical_and( CZMA_INFORMATION& info, int& index, CVALUE& result );
	bool operator_logical_or( CZMA_INFORMATION& info, int& index, CVALUE& result );

	// --------------------------------------------------------------------
	//	命令の引数を解釈する関数
	//
	//	返値:
	//		true ..... 所定の引数並びにマッチ 又は すでにオペコード生成済み
	//		false .... 所定の引数並びにマッチしない
	//	備考:
	//		返値はオペコードを生成し終えたかどうかの判定結果ではないことに注意。
	//		オペコードを生成し終えたかどうかは、is_data_fixed を参照。
	//		オペコードを生成し終えている場合は、引数並びをチェックせずに true を返す。
	// --------------------------------------------------------------------
	bool opecode( CZMA_INFORMATION& info, unsigned char op1, int op2 = -1 );
	bool opecode_a_i_r( CZMA_INFORMATION& info );
	bool opecode_ddd_sss( CZMA_INFORMATION& info, unsigned char op1 );
	bool opecode_a_sss( CZMA_INFORMATION& info, unsigned char op1 );
	bool opecode_ddd_c( CZMA_INFORMATION& info, unsigned char op1, unsigned char op1c, unsigned char op2 );
	bool opecode_c_sss( CZMA_INFORMATION& info, unsigned char op1, unsigned char op1c, unsigned char op2 );
	bool opecode_n_sss( CZMA_INFORMATION& info, unsigned char op1, bool no_3operand = false );
	bool opecode_hl_rp( CZMA_INFORMATION& info, unsigned char op1 );
	bool opecode_hl_rp_witnout_ix( CZMA_INFORMATION& info, unsigned char op1, unsigned char op2 );
	bool opecode_ddd_ref_hl( CZMA_INFORMATION& info, unsigned char op1 );
	bool opecode_a_ref_hl( CZMA_INFORMATION& info, unsigned char op1 );
	bool opecode_ref_hl( CZMA_INFORMATION& info, unsigned char op1 );
	bool opecode_ddd_n( CZMA_INFORMATION& info, unsigned char op1 );
	bool opecode_a_n( CZMA_INFORMATION& info, unsigned char op1 );
	bool opecode_rp( CZMA_INFORMATION& info, unsigned char op1 );
	bool opecode_rp_nn( CZMA_INFORMATION& info, unsigned char op1 );
	bool opecode_rp_ref_nn( CZMA_INFORMATION& info, unsigned char op1, unsigned char op1c );
	bool opecode_ref_hl_sss( CZMA_INFORMATION& info, unsigned char op1 );
	bool opecode_ref_hl_n( CZMA_INFORMATION& info, unsigned char op1 );
	bool opecode_ref_bc_a( CZMA_INFORMATION& info, unsigned char op1 );
	bool opecode_ref_nn_rp( CZMA_INFORMATION& info, unsigned char op1, unsigned char op1c, unsigned char op2 );
	bool opecode_a_ref_bc( CZMA_INFORMATION& info, unsigned char op1 );
	bool opecode_sp_hl( CZMA_INFORMATION& info, unsigned char op1 );
	bool opecode_rp_with_af( CZMA_INFORMATION& info, unsigned char op1 );
	bool opecode_sss( CZMA_INFORMATION& info, unsigned char op1, int op2 = -1 );
	bool opecode_ddd( CZMA_INFORMATION& info, unsigned char op1, int op2 = -1 );
	bool opecode_ccc_nnn( CZMA_INFORMATION& info, unsigned char op1, unsigned char op1c );
	bool opecode_ccc_e( CZMA_INFORMATION& info, unsigned char op1, unsigned char op1c );
	bool opecode_ccc( CZMA_INFORMATION& info, unsigned char op1, unsigned char op1c );
	bool opecode_mulub( CZMA_INFORMATION& info, unsigned char op1, int op2 );
	bool opecode_muluw( CZMA_INFORMATION& info );

public:
	std::string get_line( void );
	void put_error( std::string message );
	void put_message( std::string message );
	void put_structure_error( std::string message );
	std::vector<std::string> words;
	int expression( CZMA_INFORMATION& info, int index, CVALUE& result );

	// ----------------------------------------------------------------
	//	Constructor
	// ----------------------------------------------------------------
	CZMA_PARSE( std::vector<std::string> words, const char* p_file_name, int line_no );
	static CZMA_PARSE* create( CZMA_INFORMATION &info, std::vector<std::string> words, const char* p_file_name, int line_no );
	static CZMA_PARSE* create( CZMA_INFORMATION &info, std::string s, const char *p_file_name, int line_no );

	// ----------------------------------------------------------------
	//	Destructor
	// ----------------------------------------------------------------
	~CZMA_PARSE() {
	}

	// ----------------------------------------------------------------
	//	Process method
	// ----------------------------------------------------------------
	virtual bool process( CZMA_INFORMATION &info, CZMA_PARSE* p_last_line = NULL ) = 0;

	// ----------------------------------------------------------------
	bool check_all_fixed() const {
		return get_fixed_code_address() && get_fixed_file_address () && get_fixed_code_size() && check_data_fixed();
	}

	// ----------------------------------------------------------------
	bool check_data_fixed() const {
		return is_data_fixed;
	}

	// ----------------------------------------------------------------
	//	Set method
	// ----------------------------------------------------------------
	void set_label_search_state( bool state ) {
		this->is_label_search_state = state;
	}

	// --------------------------------------------------------------------
	void set_code_address( CZMA_INFORMATION* p_info, unsigned int new_code_address ) {
		if( this->code_address == -1 ) {
			p_info->is_updated = true;
		}
		this->code_address = new_code_address;
	}

	// ----------------------------------------------------------------
	void set_file_address( CZMA_INFORMATION* p_info, unsigned int new_file_address ) {
		if( this->file_address == -1 ) {
			p_info->is_updated = true;
		}
		this->file_address = new_file_address;
	}

	// ----------------------------------------------------------------
	void set_code_size( CZMA_INFORMATION* p_info, unsigned int new_code_size ) {
		if( this->code_size != (int)new_code_size ) {
			p_info->is_updated = true;
			this->code_size = new_code_size;
		}
		if( this->get_fixed_code_address() ) {
			if( this->next_code_address == -1 ) {
				p_info->is_updated = true;
			}
			this->next_code_address = this->code_address + new_code_size;
		}
	}

	// --------------------------------------------------------------------
	void set_output_mode( void ) {
		this->is_analyze_phase = false;
	}

	// --------------------------------------------------------------------
	const char *get_file_name( void ) {
		return p_file_name;
	}

	// ----------------------------------------------------------------
	//	Get method
	// ----------------------------------------------------------------
	bool get_fixed_code_address() const {
		return (code_address != -1);
	}

	// ----------------------------------------------------------------
	bool get_fixed_next_code_address() const {
		return (next_code_address != -1);
	}

	// ----------------------------------------------------------------
	bool get_fixed_file_address() const {
		return (file_address != -1);
	}

	// ----------------------------------------------------------------
	bool get_fixed_code_size() const {
		return (code_size != -1);
	}

	// ----------------------------------------------------------------
	int get_code_address() const {
		return code_address;
	}

	// ----------------------------------------------------------------
	int get_next_code_address() const {
		return next_code_address;
	}

	// ----------------------------------------------------------------
	int get_file_address() const {
		return file_address;
	}

	// ----------------------------------------------------------------
	int get_code_size() const {
		return code_size;
	}

	// ----------------------------------------------------------------
	int get_line_no() const {
		return line_no;
	}

	// ----------------------------------------------------------------
	static int get_number_of_errors() {
		return number_of_error;
	}

	// ----------------------------------------------------------------
	virtual bool write( CZMA_INFORMATION& info, std::ofstream *f );

	// ----------------------------------------------------------------
	virtual bool is_parse_error( void ) {
		return false;
	}
};
