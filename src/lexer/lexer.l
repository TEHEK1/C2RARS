%{
#include <iostream>
#include <string>
#include <cstdlib>
#include "scanner.h"

#undef YY_DECL
#define YY_DECL yy::parser::symbol_type c2rars::Scanner::get_next_token()

%}

%option c++
%option noyywrap
%option yylineno
%option prefix="C2rars"
%option yyclass="c2rars::Scanner"

/* Definitions */
DIGIT       [0-9]
HEXDIGIT    [0-9a-fA-F]
LETTER      [a-zA-Z_]
ALNUM       [a-zA-Z0-9_]

%%

".text"         { return yy::parser::make_TEXT_DIRECTIVE(); }
".data"         { return yy::parser::make_DATA_DIRECTIVE(); }
".rodata"       { return yy::parser::make_DATA_DIRECTIVE(); }  /* Treat .rodata as .data */
".bss"          { return yy::parser::make_BSS_DIRECTIVE(); }
".globl"        { return yy::parser::make_GLOBL_DIRECTIVE(); }
".align"        { return yy::parser::make_ALIGN_DIRECTIVE(); }
".section"      { return yy::parser::make_SECTION_DIRECTIVE(); }
".string"       { return yy::parser::make_STRING_DIRECTIVE(); }
".asciz"        { return yy::parser::make_ASCIZ_DIRECTIVE(); }
".word"         { return yy::parser::make_WORD_DIRECTIVE(); }
".byte"         { return yy::parser::make_BYTE_DIRECTIVE(); }
".half"         { return yy::parser::make_HALF_DIRECTIVE(); }
".space"        { return yy::parser::make_SPACE_DIRECTIVE(); }

    /* GCC directives to ignore */
".file"[^\n]*   { /* ignore */ }
".option"[^\n]* { /* ignore */ }
".attribute"[^\n]* { /* ignore */ }
".type"[^\n]*   { /* ignore */ }
".size"[^\n]*   { /* ignore */ }
".ident"[^\n]*  { /* ignore */ }
".section"[^\n]* { /* ignore */ }
"#APP"[^\n]*    { /* ignore inline asm markers */ }
"#NO_APP"[^\n]* { /* ignore inline asm markers */ }
"nop"           { /* ignore nop for now */ }

"add"           { return yy::parser::make_ADD(); }
"addi"          { return yy::parser::make_ADDI(); }
"sub"           { return yy::parser::make_SUB(); }
"mul"           { return yy::parser::make_MUL(); }
"div"           { return yy::parser::make_DIV(); }
"rem"           { return yy::parser::make_REM(); }
"and"           { return yy::parser::make_AND(); }
"or"            { return yy::parser::make_OR(); }
"xor"           { return yy::parser::make_XOR(); }
"sll"           { return yy::parser::make_SLL(); }
"srl"           { return yy::parser::make_SRL(); }
"sra"           { return yy::parser::make_SRA(); }
"lw"            { return yy::parser::make_LW(); }
"sw"            { return yy::parser::make_SW(); }
"lb"            { return yy::parser::make_LB(); }
"sb"            { return yy::parser::make_SB(); }
"beq"           { return yy::parser::make_BEQ(); }
"bne"           { return yy::parser::make_BNE(); }
"blt"           { return yy::parser::make_BLT(); }
"bge"           { return yy::parser::make_BGE(); }
"jal"           { return yy::parser::make_JAL(); }
"jalr"          { return yy::parser::make_JALR(); }
"ret"           { return yy::parser::make_RET(); }
"ecall"         { return yy::parser::make_ECALL(); }
"la"            { return yy::parser::make_LA(); }
"li"            { return yy::parser::make_LI(); }
"mv"            { return yy::parser::make_MV(); }
"jr"            { return yy::parser::make_JR(); }
"lui"           { return yy::parser::make_LUI(); }
"call"          { return yy::parser::make_CALL(); }

"x"[0-9]+       { return yy::parser::make_REGISTER(atoi(yytext + 1)); }
"zero"|"x0"     { return yy::parser::make_REGISTER(0); }
"ra"|"x1"       { return yy::parser::make_REGISTER(1); }
"sp"|"x2"       { return yy::parser::make_REGISTER(2); }
"gp"|"x3"       { return yy::parser::make_REGISTER(3); }
"tp"|"x4"       { return yy::parser::make_REGISTER(4); }
"t0"|"x5"       { return yy::parser::make_REGISTER(5); }
"t1"|"x6"       { return yy::parser::make_REGISTER(6); }
"t2"|"x7"       { return yy::parser::make_REGISTER(7); }
"s0"|"fp"|"x8"  { return yy::parser::make_REGISTER(8); }
"s1"|"x9"       { return yy::parser::make_REGISTER(9); }
"a0"|"x10"      { return yy::parser::make_REGISTER(10); }
"a1"|"x11"      { return yy::parser::make_REGISTER(11); }
"a2"|"x12"      { return yy::parser::make_REGISTER(12); }
"a3"|"x13"      { return yy::parser::make_REGISTER(13); }
"a4"|"x14"      { return yy::parser::make_REGISTER(14); }
"a5"|"x15"      { return yy::parser::make_REGISTER(15); }
"a6"|"x16"      { return yy::parser::make_REGISTER(16); }
"a7"|"x17"      { return yy::parser::make_REGISTER(17); }

{LETTER}{ALNUM}*":"     {
    std::string label(yytext, yyleng - 1);
    return yy::parser::make_LABEL_DEF(label);
}

{LETTER}{ALNUM}*        { 
    return yy::parser::make_IDENTIFIER(std::string(yytext));
}

{DIGIT}+                { return yy::parser::make_NUMBER(atoi(yytext)); }
"0x"{HEXDIGIT}+         { return yy::parser::make_NUMBER(strtol(yytext, NULL, 16)); }
"-"{DIGIT}+             { return yy::parser::make_NUMBER(atoi(yytext)); }

\"([^\\\"]|\\.)*\"      {
    return yy::parser::make_STRING(std::string(yytext));
}

"#".*                   { /* Ignore RISC-V comments */ }

","                     { return yy::parser::make_COMMA(); }
"("                     { return yy::parser::make_LPAREN(); }
")"                     { return yy::parser::make_RPAREN(); }
":"                     { return yy::parser::make_COLON(); }

[ \t]+                  { /* Ignore whitespace */ }
\n                      { return yy::parser::make_NEWLINE(); }

.                       {  /* Catch-all for unknown characters */ 
    std::cerr << "Unknown character: " << yytext 
              << " on line " << lineno() << std::endl;
    return yy::parser::make_ERROR();
}

%%
