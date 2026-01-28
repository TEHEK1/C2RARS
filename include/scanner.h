#ifndef SCANNER_H
#define SCANNER_H

#if !defined(yyFlexLexerOnce)
#undef yyFlexLexer
#define yyFlexLexer C2rarsFlexLexer
#include <FlexLexer.h>
#undef yyFlexLexer
#endif

#define YY_SKIP_YYWRAP 1

#include "parser.tab.hpp"

namespace c2rars {

class Scanner : public C2rarsFlexLexer {
public:
    Scanner(std::istream* in = nullptr) : C2rarsFlexLexer(in) {}
    virtual ~Scanner() {}
    
    yy::parser::symbol_type get_next_token();
};

}

#endif
