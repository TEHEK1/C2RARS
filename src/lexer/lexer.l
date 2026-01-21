%{
#include <iostream>
#include <string>
#include <cstdlib>
#include "parser.tab.hpp"
#include "ast.h"

%}

%option noyywrap
%option yylineno
%option c++
%option yyclass="RiscvLexer"

/* Definitions */
DIGIT       [0-9]
HEXDIGIT    [0-9a-fA-F]
LETTER      [a-zA-Z_]
ALNUM       [a-zA-Z0-9_]

%%

    /* Directives */
".text"         { return TEXT_DIRECTIVE; }
".data"         { return DATA_DIRECTIVE; }
".bss"          { return BSS_DIRECTIVE; }
".globl"        { return GLOBL_DIRECTIVE; }
".align"        { return ALIGN_DIRECTIVE; }
".section"      { return SECTION_DIRECTIVE; }
".string"       { return STRING_DIRECTIVE; }
".asciz"        { return ASCIZ_DIRECTIVE; }
".word"         { return WORD_DIRECTIVE; }
".byte"         { return BYTE_DIRECTIVE; }
".half"         { return HALF_DIRECTIVE; }
".space"        { return SPACE_DIRECTIVE; }

    /* RISC-V Instructions */
"add"           { return ADD; }
"addi"          { return ADDI; }
"sub"           { return SUB; }
"mul"           { return MUL; }
"div"           { return DIV; }
"rem"           { return REM; }
"and"           { return AND; }
"or"            { return OR; }
"xor"           { return XOR; }
"sll"           { return SLL; }
"srl"           { return SRL; }
"sra"           { return SRA; }
"lw"            { return LW; }
"sw"            { return SW; }
"lb"            { return LB; }
"sb"            { return SB; }
"beq"           { return BEQ; }
"bne"           { return BNE; }
"blt"           { return BLT; }
"bge"           { return BGE; }
"jal"           { return JAL; }
"jalr"          { return JALR; }
"ret"           { return RET; }
"ecall"         { return ECALL; }

    /* Registers */
"x"[0-9]+       { yylval.reg = atoi(yytext + 1); return REGISTER; }
"zero"|"x0"     { yylval.reg = 0; return REGISTER; }
"ra"|"x1"       { yylval.reg = 1; return REGISTER; }
"sp"|"x2"       { yylval.reg = 2; return REGISTER; }
"gp"|"x3"       { yylval.reg = 3; return REGISTER; }
"tp"|"x4"       { yylval.reg = 4; return REGISTER; }
"t0"|"x5"       { yylval.reg = 5; return REGISTER; }
"t1"|"x6"       { yylval.reg = 6; return REGISTER; }
"t2"|"x7"       { yylval.reg = 7; return REGISTER; }
"s0"|"fp"|"x8"  { yylval.reg = 8; return REGISTER; }
"s1"|"x9"       { yylval.reg = 9; return REGISTER; }
"a0"|"x10"      { yylval.reg = 10; return REGISTER; }
"a1"|"x11"      { yylval.reg = 11; return REGISTER; }
"a2"|"x12"      { yylval.reg = 12; return REGISTER; }
"a3"|"x13"      { yylval.reg = 13; return REGISTER; }
"a4"|"x14"      { yylval.reg = 14; return REGISTER; }
"a5"|"x15"      { yylval.reg = 15; return REGISTER; }
"a6"|"x16"      { yylval.reg = 16; return REGISTER; }
"a7"|"x17"      { yylval.reg = 17; return REGISTER; }

    /* Labels */
{LETTER}{ALNUM}*":"     { 
    yylval.build<std::string>(std::string(yytext, strlen(yytext) - 1));
    return LABEL_DEF;
}

{LETTER}{ALNUM}*        { 
    yylval.build<std::string>(yytext);
    return IDENTIFIER;
}

    /* Numbers */
{DIGIT}+                { yylval.num = atoi(yytext); return NUMBER; }
"0x"{HEXDIGIT}+         { yylval.num = strtol(yytext, NULL, 16); return NUMBER; }
"-"{DIGIT}+             { yylval.num = atoi(yytext); return NUMBER; }

    /* String literals */
\"([^\\\"]|\\.)*\"      { 
    yylval.build<std::string>(yytext);
    return STRING;
}

    /* Comments */
"#".*                   { /* Ignore comments */ }

    /* Delimiters */
","                     { return COMMA; }
"("                     { return LPAREN; }
")"                     { return RPAREN; }
":"                     { return COLON; }

    /* Whitespace */
[ \t]+                  { /* Ignore whitespace */ }
\n                      { return NEWLINE; }

    /* Everything else */
.                       { 
    std::cerr << "Unknown character: " << yytext 
              << " on line " << yylineno << std::endl;
    return ERROR;
}

%%
