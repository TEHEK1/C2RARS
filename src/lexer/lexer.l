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
".local".*                          { /* skip .local linkage directive */ }
".section"[ \t]+"."[^\n]*          { /* skip .section with dot-prefixed names (.rodata, .sdata, .note, etc.) */ }

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
".zero"         { return yy::parser::make_SPACE_DIRECTIVE(); }
".comm"         { return yy::parser::make_COMM_DIRECTIVE(); }

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

"fadd.s"        { return yy::parser::make_FADD_S(); }
"fsub.s"        { return yy::parser::make_FSUB_S(); }
"fmul.s"        { return yy::parser::make_FMUL_S(); }
"fdiv.s"        { return yy::parser::make_FDIV_S(); }
"fsqrt.s"       { return yy::parser::make_FSQRT_S(); }
"fcvt.w.s"      { return yy::parser::make_FCVT_W_S(); }
"fcvt.s.w"      { return yy::parser::make_FCVT_S_W(); }
"fcvt.wu.s"     { return yy::parser::make_FCVT_WU_S(); }
"fcvt.s.wu"     { return yy::parser::make_FCVT_S_WU(); }
"fmv.x.w"      { return yy::parser::make_FMV_X_W(); }
"fmv.x.s"      { return yy::parser::make_FMV_X_W(); }
"fmv.w.x"      { return yy::parser::make_FMV_W_X(); }
"fmv.s.x"      { return yy::parser::make_FMV_W_X(); }
"fmv.s"         { return yy::parser::make_FMV_S(); }
"feq.s"         { return yy::parser::make_FEQ_S(); }
"flt.s"         { return yy::parser::make_FLT_S(); }
"fle.s"         { return yy::parser::make_FLE_S(); }
"fgt.s"         { return yy::parser::make_FGT_S(); }
"fge.s"         { return yy::parser::make_FGE_S(); }
"fneg.s"        { return yy::parser::make_FNEG_S(); }
"fabs.s"        { return yy::parser::make_FABS_S(); }
"fclass.s"      { return yy::parser::make_FCLASS_S(); }
"flw"           { return yy::parser::make_FLW(); }
"fsw"           { return yy::parser::make_FSW(); }

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

"f"[0-9]+       { return yy::parser::make_FREGISTER(atoi(yytext + 1)); }
"ft0"           { return yy::parser::make_FREGISTER(0); }
"ft1"           { return yy::parser::make_FREGISTER(1); }
"ft2"           { return yy::parser::make_FREGISTER(2); }
"ft3"           { return yy::parser::make_FREGISTER(3); }
"ft4"           { return yy::parser::make_FREGISTER(4); }
"ft5"           { return yy::parser::make_FREGISTER(5); }
"ft6"           { return yy::parser::make_FREGISTER(6); }
"ft7"           { return yy::parser::make_FREGISTER(7); }
"fs0"           { return yy::parser::make_FREGISTER(8); }
"fs1"           { return yy::parser::make_FREGISTER(9); }
"fa0"           { return yy::parser::make_FREGISTER(10); }
"fa1"           { return yy::parser::make_FREGISTER(11); }
"fa2"           { return yy::parser::make_FREGISTER(12); }
"fa3"           { return yy::parser::make_FREGISTER(13); }
"fa4"           { return yy::parser::make_FREGISTER(14); }
"fa5"           { return yy::parser::make_FREGISTER(15); }
"fa6"           { return yy::parser::make_FREGISTER(16); }
"fa7"           { return yy::parser::make_FREGISTER(17); }
"fs2"           { return yy::parser::make_FREGISTER(18); }
"fs3"           { return yy::parser::make_FREGISTER(19); }
"fs4"           { return yy::parser::make_FREGISTER(20); }
"fs5"           { return yy::parser::make_FREGISTER(21); }
"fs6"           { return yy::parser::make_FREGISTER(22); }
"fs7"           { return yy::parser::make_FREGISTER(23); }
"fs8"           { return yy::parser::make_FREGISTER(24); }
"fs9"           { return yy::parser::make_FREGISTER(25); }
"fs10"          { return yy::parser::make_FREGISTER(26); }
"fs11"          { return yy::parser::make_FREGISTER(27); }
"ft8"           { return yy::parser::make_FREGISTER(28); }
"ft9"           { return yy::parser::make_FREGISTER(29); }
"ft10"          { return yy::parser::make_FREGISTER(30); }
"ft11"          { return yy::parser::make_FREGISTER(31); }

"."{LETTER}{ALNUM}*("."{ALNUM}+)*":"  {
    std::string label(yytext, yyleng - 1);
    return yy::parser::make_LABEL_DEF(label);
}

{LETTER}{ALNUM}*("."{ALNUM}+)*":"     {
    std::string label(yytext, yyleng - 1);
    return yy::parser::make_LABEL_DEF(label);
}

"."{LETTER}{ALNUM}*("."{ALNUM}+)*     { return yy::parser::make_IDENTIFIER(std::string(yytext)); }

{LETTER}{ALNUM}*("."{ALNUM}+)*        {
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
