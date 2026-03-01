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

DIGIT       [0-9]
HEXDIGIT    [0-9a-fA-F]
LETTER      [a-zA-Z_]
ALNUM       [a-zA-Z0-9_]

%%

".file".*                           { /* skip GCC .file directive */ }
".option".*                         { /* skip GCC .option directive */ }
".attribute".*                      { /* skip GCC .attribute directive */ }
".type".*                           { /* skip GCC .type directive */ }
".size".*                           { /* skip GCC .size directive */ }
".ident".*                          { /* skip GCC .ident directive */ }
".section"[ \t]+"."[^\n]*          { /* skip .section with dot-prefixed names (.rodata, .note, etc.) */ }

".text"         { return yy::parser::make_TEXT_DIRECTIVE(); }
".data"         { return yy::parser::make_DATA_DIRECTIVE(); }
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

"add"           { return yy::parser::make_ADD(); }
"addi"          { return yy::parser::make_ADDI(); }
"sub"           { return yy::parser::make_SUB(); }
"mul"           { return yy::parser::make_MUL(); }
"mulh"          { return yy::parser::make_MULH(); }
"div"           { return yy::parser::make_DIV(); }
"rem"           { return yy::parser::make_REM(); }
"and"           { return yy::parser::make_AND(); }
"andi"          { return yy::parser::make_ANDI(); }
"or"            { return yy::parser::make_OR(); }
"ori"           { return yy::parser::make_ORI(); }
"xor"           { return yy::parser::make_XOR(); }
"xori"          { return yy::parser::make_XORI(); }
"sll"           { return yy::parser::make_SLL(); }
"slli"          { return yy::parser::make_SLLI(); }
"srl"           { return yy::parser::make_SRL(); }
"srli"          { return yy::parser::make_SRLI(); }
"sra"           { return yy::parser::make_SRA(); }
"srai"          { return yy::parser::make_SRAI(); }
"slt"           { return yy::parser::make_SLT(); }
"slti"          { return yy::parser::make_SLTI(); }
"sltu"          { return yy::parser::make_SLTU(); }
"lw"            { return yy::parser::make_LW(); }
"sw"            { return yy::parser::make_SW(); }
"lb"            { return yy::parser::make_LB(); }
"lbu"           { return yy::parser::make_LBU(); }
"lh"            { return yy::parser::make_LH(); }
"lhu"           { return yy::parser::make_LHU(); }
"sb"            { return yy::parser::make_SB(); }
"sh"            { return yy::parser::make_SH(); }
"beq"           { return yy::parser::make_BEQ(); }
"bne"           { return yy::parser::make_BNE(); }
"blt"           { return yy::parser::make_BLT(); }
"bge"           { return yy::parser::make_BGE(); }
"bltu"          { return yy::parser::make_BLTU(); }
"bgeu"          { return yy::parser::make_BGEU(); }
"bgt"           { return yy::parser::make_BGT(); }
"ble"           { return yy::parser::make_BLE(); }
"bgtu"          { return yy::parser::make_BGTU(); }
"bleu"          { return yy::parser::make_BLEU(); }
"jal"           { return yy::parser::make_JAL(); }
"jalr"          { return yy::parser::make_JALR(); }
"lui"           { return yy::parser::make_LUI(); }
"li"            { return yy::parser::make_LI(); }
"la"            { return yy::parser::make_LA(); }
"mv"            { return yy::parser::make_MV(); }
"call"          { return yy::parser::make_CALL(); }
"ret"           { return yy::parser::make_RET(); }
"j"             { return yy::parser::make_J(); }
"jr"            { return yy::parser::make_JR(); }
"nop"           { return yy::parser::make_NOP(); }
"neg"           { return yy::parser::make_NEG(); }
"not"           { return yy::parser::make_NOT_INST(); }
"seqz"          { return yy::parser::make_SEQZ(); }
"snez"          { return yy::parser::make_SNEZ(); }
"ecall"         { return yy::parser::make_ECALL(); }

"%hi("[^)]*")"  { return yy::parser::make_IDENTIFIER(std::string(yytext + 4, yyleng - 5)); }
"%lo("[^)]*")"  { return yy::parser::make_IDENTIFIER(std::string(yytext + 4, yyleng - 5)); }

"x"[0-9]+       { return yy::parser::make_REGISTER(atoi(yytext + 1)); }
"zero"          { return yy::parser::make_REGISTER(0); }
"ra"            { return yy::parser::make_REGISTER(1); }
"sp"            { return yy::parser::make_REGISTER(2); }
"gp"            { return yy::parser::make_REGISTER(3); }
"tp"            { return yy::parser::make_REGISTER(4); }
"t0"            { return yy::parser::make_REGISTER(5); }
"t1"            { return yy::parser::make_REGISTER(6); }
"t2"            { return yy::parser::make_REGISTER(7); }
"s0"|"fp"       { return yy::parser::make_REGISTER(8); }
"s1"            { return yy::parser::make_REGISTER(9); }
"a0"            { return yy::parser::make_REGISTER(10); }
"a1"            { return yy::parser::make_REGISTER(11); }
"a2"            { return yy::parser::make_REGISTER(12); }
"a3"            { return yy::parser::make_REGISTER(13); }
"a4"            { return yy::parser::make_REGISTER(14); }
"a5"            { return yy::parser::make_REGISTER(15); }
"a6"            { return yy::parser::make_REGISTER(16); }
"a7"            { return yy::parser::make_REGISTER(17); }
"s2"            { return yy::parser::make_REGISTER(18); }
"s3"            { return yy::parser::make_REGISTER(19); }
"s4"            { return yy::parser::make_REGISTER(20); }
"s5"            { return yy::parser::make_REGISTER(21); }
"s6"            { return yy::parser::make_REGISTER(22); }
"s7"            { return yy::parser::make_REGISTER(23); }
"s8"            { return yy::parser::make_REGISTER(24); }
"s9"            { return yy::parser::make_REGISTER(25); }
"s10"           { return yy::parser::make_REGISTER(26); }
"s11"           { return yy::parser::make_REGISTER(27); }
"t3"            { return yy::parser::make_REGISTER(28); }
"t4"            { return yy::parser::make_REGISTER(29); }
"t5"            { return yy::parser::make_REGISTER(30); }
"t6"            { return yy::parser::make_REGISTER(31); }

"."{LETTER}{ALNUM}*":"  {
    std::string label(yytext, yyleng - 1);
    return yy::parser::make_LABEL_DEF(label);
}

{LETTER}{ALNUM}*":"     { 
    std::string label(yytext, yyleng - 1);
    return yy::parser::make_LABEL_DEF(label);
}

"."{LETTER}{ALNUM}*     { return yy::parser::make_IDENTIFIER(std::string(yytext)); }

{LETTER}{ALNUM}*        { 
    return yy::parser::make_IDENTIFIER(std::string(yytext));
}

{DIGIT}+                { return yy::parser::make_NUMBER(atoi(yytext)); }
"0x"{HEXDIGIT}+         { return yy::parser::make_NUMBER(strtol(yytext, NULL, 16)); }
"-"{DIGIT}+             { return yy::parser::make_NUMBER(atoi(yytext)); }

\"([^\\\"]|\\.)*\"      { 
    return yy::parser::make_STRING(std::string(yytext));
}

"#".*                   { /* ignore comments */ }

","                     { return yy::parser::make_COMMA(); }
"("                     { return yy::parser::make_LPAREN(); }
")"                     { return yy::parser::make_RPAREN(); }
":"                     { return yy::parser::make_COLON(); }

[ \t]+                  { /* ignore whitespace */ }
\n                      { return yy::parser::make_NEWLINE(); }

.                       { 
    std::cerr << "Unknown character: " << yytext 
              << " on line " << lineno() << std::endl;
    return yy::parser::make_ERROR();
}

%%
