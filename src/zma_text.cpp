// --------------------------------------------------------------------
//	ZMA: CZMA_TEXT
// ====================================================================
//	2019/05/02	t.hara
// --------------------------------------------------------------------

#include "zma_text.hpp"
#include <fstream>
#include <iostream>
#include <limits>
#include <utility>
#include "zma_parse_process_if.hpp"

namespace {
struct SOURCE_LINE {
	std::vector<std::string> words;
	const char *file_name;
	int line_no;
};

struct ASSEMBLY_INPUT {
	std::vector<SOURCE_LINE> lines;
	std::map<std::string, CVALUE> dict;
	std::vector<std::string> include_path;
	std::vector<std::string> macro_names;
	std::map<std::string, CZMA_CHAR_SET> char_sets;
	bool defs_is_space;
	bool all_error_enable;
	CZMA_INFORMATION::OUTPUT_TYPE output_type;

	ASSEMBLY_INPUT( CZMA_TEXT &text, const CZMA_INFORMATION &info ):
		dict( info.dict ), include_path( info.include_path ), char_sets( info.char_set_list ),
		defs_is_space( info.defs_is_space ), all_error_enable( info.all_error_enable ), output_type( info.output_type ) {
		for( auto p : text.m_text ) {
			lines.push_back( { p->words, p->get_file_name(), p->get_line_no() } );
		}
		for( const auto &macro : info.macro_list ) {
			macro_names.push_back( macro.first );
		}
	}

	void build( CZMA_TEXT &text, CZMA_INFORMATION &info ) const {
		for( auto p : text.m_text ) {
			delete p;
		}
		text.m_text.clear();
		info.clear();
		info.conditional_candidates.clear();
		info.dict = dict;
		info.include_path = include_path;
		info.char_set_list = char_sets;
		info.macro_list.clear();
		info.link_list.clear();
		info.p_sub_dict = nullptr;
		info.macro_instance_index = 0;
		info.defs_is_space = defs_is_space;
		info.all_error_enable = all_error_enable;
		info.output_type = output_type;
		for( const auto &name : macro_names ) {
			info.macro_list[name] = nullptr;
		}
		for( const auto &line : lines ) {
			auto words = line.words;
			text.m_text.push_back( CZMA_PARSE::create( info, words, line.file_name, line.line_no ) );
		}
		text.analyze_structure();
	}
};

class TRIAL_DIAGNOSTICS {
public:
	TRIAL_DIAGNOSTICS() { CZMA_PARSE::set_trial_mode( true ); }
	~TRIAL_DIAGNOSTICS() { CZMA_PARSE::set_trial_mode( false ); }
};

bool resolve_conditions( CZMA_TEXT &text, CZMA_INFORMATION &info, const ASSEMBLY_INPUT &input ) {
	using CHOICES = std::map<std::string, int>;
	std::vector<CHOICES> pending( 1 );
	CHOICES best;
	int best_size = std::numeric_limits<int>::max();
	bool found = false;
	unsigned int evaluations = 0;

	while( !pending.empty() && evaluations < 1024 ) {
		CHOICES choices = std::move( pending.back() );
		pending.pop_back();
		evaluations++;
		CZMA_INFORMATION trial_info;
		CZMA_TEXT trial_text;
		TRIAL_DIAGNOSTICS diagnostics;
		input.build( trial_text, trial_info );
		trial_info.conditional_choices = choices;
		if( CZMA_PARSE::get_trial_errors() || !trial_text.analyze( trial_info ) ) {
			continue;
		}
		auto undecided = trial_info.conditional_candidates;
		undecided.insert( trial_info.unresolved_conditions.begin(), trial_info.unresolved_conditions.end() );
		for( const auto &choice : choices ) {
			undecided.erase( choice.first );
		}
		if( !undecided.empty() ) {
			const auto &unresolved = *undecided.begin();
			for( int i = unresolved.second->number_of_choices() - 1; i >= 0; i-- ) {
				CHOICES next = choices;
				next[unresolved.first] = i;
				pending.push_back( std::move( next ) );
			}
			continue;
		}
		trial_info.validate_conditions = true;
		trial_info.clear();
		unsigned int success_count;
		auto last = trial_text.process( trial_info, success_count, nullptr, true );
		trial_text.calc_code_size();
		if( CZMA_PARSE::get_trial_errors() || !trial_info.scope.empty() || last == nullptr ||
			!last->is_fixed_next_code_address() || trial_text.get_code_size() < 0 ) {
			continue;
		}
		if( trial_text.get_code_size() < best_size ) {
			best_size = trial_text.get_code_size();
			best = std::move( choices );
			found = true;
		}
	}
	if( !pending.empty() || !found ) {
		auto line = !info.conditional_candidates.empty() ?
			info.conditional_candidates.begin()->second : info.unresolved_conditions.begin()->second;
		line->set_output_mode();
		line->put_error( CZMA_ERROR::get( pending.empty() ?
			CZMA_ERROR_CODE::CONDITIONAL_NOT_RESOLVED : CZMA_ERROR_CODE::CONDITIONAL_SEARCH_LIMIT ) );
		return false;
	}
	// Replay only the winner, so speculative symbols, diagnostics and expansions cannot escape.
	input.build( text, info );
	info.conditional_choices = std::move( best );
	info.validate_conditions = true;
	return text.analyze( info );
}
}

// ----------------------------------------------------------------
//	Constructor
// ----------------------------------------------------------------
CZMA_TEXT::CZMA_TEXT() {
	code_size = -1;
	next_code_address = -1;
}

// ----------------------------------------------------------------
//	Destructor
// ----------------------------------------------------------------
CZMA_TEXT::~CZMA_TEXT() {
	for( auto p: m_text ) { 
		delete p; 
	}
}

// ----------------------------------------------------------------
//	code size
// ----------------------------------------------------------------
void CZMA_TEXT::calc_code_size( void ) {

	code_size = 0;
	for( auto &p : this->m_text ){
		if( p->is_fixed_code_size() ){
			code_size += p->get_code_size();
		}
		else{
			code_size = -1;
			break;
		}
		if( p->is_fixed_next_code_address() ){
			next_code_address = p->get_next_code_address();
		}
		else{
			next_code_address = -1;
		}
	}
}

// ----------------------------------------------------------------
//	check data fixed
// ----------------------------------------------------------------
bool CZMA_TEXT::check_data_fixed( void ){

	for( auto &p : this->m_text ){
		if( !p->check_data_fixed() ){
			return false;
		}
	}
	return true;
}

// ----------------------------------------------------------------
//	File Load
// ----------------------------------------------------------------
bool CZMA_TEXT::load( CZMA_INFORMATION &info, const char* p_file_name ) {
	m_text.clear();
	std::string s;
	CZMA_PARSE *p_parse;
	int line_no;
	std::vector< std::string > words, labels;

	std::ifstream file;
	file.open( p_file_name );
	if( !file ) {
		return false;
	}
	line_no = 1;
	for( ;; line_no++) {
		if(file.bad()) {
			break;
		}
		if(!std::getline( file, s )) {
			break;
		}
		words = CZMA_PARSE::get_word_split( s );
		if( words.size() > 2 && ( (words[ 1 ] == ":") || (words[ 1 ] == "::") ) ){
			labels.resize( 2 );
			labels[ 0 ] = words[ 0 ];
			labels[ 1 ] = words[ 1 ];
			p_parse = CZMA_PARSE::create( info, labels, p_file_name, line_no );
			m_text.push_back( p_parse );
			words.erase( words.begin() );
			words.erase( words.begin() );
			p_parse = CZMA_PARSE::create( info, words, p_file_name, line_no );
			m_text.push_back( p_parse );
		}
		else{
			p_parse = CZMA_PARSE::create( info, words, p_file_name, line_no );
			m_text.push_back( p_parse );
		}
	}
	file.close();
	return true;
}

// --------------------------------------------------------------------
CZMA_PARSE *CZMA_TEXT::process( CZMA_INFORMATION &info, unsigned int &success_count, CZMA_PARSE *p_prev_line, bool output_mode ) {
	CZMA_PARSE* p_prev;
	bool result;
	int nest_count = 0;
	p_prev = p_prev_line;
	result = true;
	success_count = 0;
	std::vector<std::string> words;

	size_t line_index = 0;
	for( auto p = m_text.begin(); p != m_text.end(); ) {
		const std::string path = info.conditional_path;
		info.conditional_path += "/" + std::to_string( line_index++ );
		if( output_mode ) {
			(*p)->set_output_mode();
		}
		//	パースエラーを起こした行の場合、再パースを試みる
		if( ( *p )->is_parse_error() ){
			words = CZMA_PARSE::get_word_split( ( *p )->get_line() );
			CZMA_PARSE *p_parse = CZMA_PARSE::create( info, words, ( *p )->get_file_name(), ( *p )->get_line_no() );
			if( !( p_parse->is_parse_error() ) ){
				delete *p;
				p = m_text.erase( p );
				p = m_text.insert( p, p_parse );
			}
			else{
				delete p_parse;
			}
		}
		//	ブロックの外側の処理
		if( ( *p )->process( info, p_prev ) ){
			success_count++;
		}
		info.conditional_path = path;
		p_prev = ( *p );
		p++;
	}
	return p_prev;
}

// --------------------------------------------------------------------
void CZMA_TEXT::analyze_structure( void ){
	std::vector<CZMA_PARSE *>::iterator pp_current = this->m_text.begin();

	while( pp_current != this->m_text.end() ){
		(*pp_current)->block_structure( this->m_text, pp_current );
		pp_current++;
	}
}

// --------------------------------------------------------------------
bool CZMA_TEXT::analyze( CZMA_INFORMATION& info ) {
	unsigned int success_count;
	for( unsigned int pass = 0; pass < 1024; pass++ ) {
		info.clear();
		this->process( info, success_count, nullptr, false );
		info.set_evaluated_for_all_links();
		if( !info.is_updated ) {
			return true;
		}
	}
	if( !m_text.empty() ) {
		m_text.front()->set_output_mode();
		m_text.front()->put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::ASSEMBLY_DID_NOT_CONVERGE ) );
	}
	return false;
}

// --------------------------------------------------------------------
bool CZMA_TEXT::all_process( CZMA_INFORMATION& info ) {
	unsigned int success_count;
	CZMA_PARSE* p_last_line;
	const ASSEMBLY_INPUT input( *this, info );

	this->analyze_structure();
	if( CZMA_PARSE::get_number_of_errors() ){
		return false;
	}
	if( !analyze( info ) ) {
		return false;
	}
	if( (!info.unresolved_conditions.empty() || !info.conditional_candidates.empty()) &&
		!resolve_conditions( *this, info, input ) ) {
		std::cerr << "Found " << CZMA_PARSE::get_number_of_errors() << " error(s).\n";
		return false;
	}
	info.clear();
	p_last_line = this->process( info, success_count, nullptr, true );
	if( p_last_line == nullptr || ((p_last_line->get_file_address() == 0) && (p_last_line->get_code_size() == 0)) ) {
		std::cerr << "Code is not found.\n";
		return false;
	}
	if( info.scope.size() > 0 ) {
		p_last_line->put_error( CZMA_ERROR::get( CZMA_ERROR_CODE::SCOPE_IS_NOT_CLOSED ) );
		return false;
	}
	if( CZMA_PARSE::get_number_of_errors() ) {
		std::cerr << "Found " << CZMA_PARSE::get_number_of_errors() << " error(s).\n";
		return false;
	}
	return true;
}

// --------------------------------------------------------------------
bool CZMA_TEXT::write( CZMA_INFORMATION& info, std::ofstream* f ) {
	bool result;

	result = true;
	for( auto &p: m_text ) {
		result = result && p->write_output_and_log( info, f );
	}
	if( info.output_type == CZMA_INFORMATION::OUTPUT_TYPE::CZMA_INTELHEX ){
		info.hexfile.flush( *f );
	}
	return result;
}

// --------------------------------------------------------------------
bool CZMA_TEXT::save( CZMA_INFORMATION& info, const char* p_file_name ) {
	std::ofstream f;

	f.open( p_file_name, std::ios::out | std::ios::binary );
	bool result = this->write( info, &f );
	info.write();
	return result;
}
