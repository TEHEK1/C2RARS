%{
#include <iostream>
#include <string>
#include <memory>
#include <vector>
#include "ast.h"

using namespace c2rars::ast;

extern int yylex();
void yyerror(const char *s);
extern int yylineno;

std::unique_ptr<Program> rootProgram;

%}

%require "3.2"
%language "c++"
%define api.value.type variant
%define api.token.constructor

%code requires {
    #include <string>
    #include <memory>
    #include "ast.h"
    
    using ASTNodePtr = std::unique_ptr<c2rars::ast::ASTNode>;
    using InstructionPtr = std::unique_ptr<c2rars::ast::Instruction>;
    using DirectivePtr = std::unique_ptr<c2rars::ast::Directive>;
    using LabelPtr = std::unique_ptr<c2rars::ast::Label>;
}

/* Directive tokens */
%token TEXT_DIRECTIVE DATA_DIRECTIVE BSS_DIRECTIVE
%token GLOBL_DIRECTIVE ALIGN_DIRECTIVE SECTION_DIRECTIVE
%token STRING_DIRECTIVE ASCIZ_DIRECTIVE
%token WORD_DIRECTIVE BYTE_DIRECTIVE HALF_DIRECTIVE SPACE_DIRECTIVE

/* Instruction tokens */
%token ADD ADDI SUB MUL DIV REM
%token AND OR XOR
%token SLL SRL SRA
%token LW SW LB SB
%token BEQ BNE BLT BGE
%token JAL JALR RET ECALL

/* Operand tokens */
%token <int> REGISTER
%token <int> NUMBER
%token <std::string> IDENTIFIER STRING LABEL_DEF

/* Delimiters */
%token COMMA LPAREN RPAREN COLON NEWLINE ERROR

/* Nonterminal types */
%type <ASTNodePtr> line
%type <InstructionPtr> instruction r_type_inst i_type_inst s_type_inst b_type_inst j_type_inst special_inst
%type <DirectivePtr> directive
%type <LabelPtr> label

%%

program:
    /* empty */ { rootProgram = std::make_unique<Program>(); }
    | program line { 
        if ($2) {
            rootProgram->addStatement(std::move($2));
        }
    }
    ;

line:
    NEWLINE { }
    | directive NEWLINE { $$ = std::move($1); }
    | label NEWLINE { $$ = std::move($1); }
    | instruction NEWLINE { $$ = std::move($1); }
    | error NEWLINE { yyerrok; }
    ;

directive:
    TEXT_DIRECTIVE { 
        $$ = std::make_unique<Directive>(Directive::TEXT); 
    }
    | DATA_DIRECTIVE { 
        $$ = std::make_unique<Directive>(Directive::DATA); 
    }
    | BSS_DIRECTIVE { 
        $$ = std::make_unique<Directive>(Directive::BSS); 
    }
    | GLOBL_DIRECTIVE IDENTIFIER { 
        $$ = std::make_unique<Directive>(Directive::GLOBL, $2);
    }
    | ALIGN_DIRECTIVE NUMBER { 
        $$ = std::make_unique<Directive>(Directive::ALIGN, "", $2);
    }
    | SECTION_DIRECTIVE IDENTIFIER { 
        $$ = std::make_unique<Directive>(Directive::SECTION, $2);
    }
    | STRING_DIRECTIVE STRING { 
        $$ = std::make_unique<Directive>(Directive::STRING, $2);
    }
    | ASCIZ_DIRECTIVE STRING { 
        $$ = std::make_unique<Directive>(Directive::ASCIZ, $2);
    }
    | WORD_DIRECTIVE NUMBER { 
        $$ = std::make_unique<Directive>(Directive::WORD, "", $2);
    }
    | BYTE_DIRECTIVE NUMBER { 
        $$ = std::make_unique<Directive>(Directive::BYTE, "", $2);
    }
    | HALF_DIRECTIVE NUMBER { 
        $$ = std::make_unique<Directive>(Directive::HALF, "", $2);
    }
    | SPACE_DIRECTIVE NUMBER { 
        $$ = std::make_unique<Directive>(Directive::SPACE, "", $2);
    }
    ;

label:
    LABEL_DEF { 
        $$ = std::make_unique<Label>($1);
    }
    | IDENTIFIER COLON { 
        $$ = std::make_unique<Label>($1);
    }
    ;

instruction:
    r_type_inst
    | i_type_inst
    | s_type_inst
    | b_type_inst
    | u_type_inst
    | j_type_inst
    | special_inst
    ;

/* R-type: add, sub, mul, etc. */
r_type_inst:
    ADD REGISTER COMMA REGISTER COMMA REGISTER { 
        $$ = Instruction::CreateRType(Instruction::ADD, $2, $4, $6);
    }
    | SUB REGISTER COMMA REGISTER COMMA REGISTER { 
        $$ = Instruction::CreateRType(Instruction::SUB, $2, $4, $6);
    }
    | MUL REGISTER COMMA REGISTER COMMA REGISTER { 
        $$ = Instruction::CreateRType(Instruction::MUL, $2, $4, $6);
    }
    | DIV REGISTER COMMA REGISTER COMMA REGISTER { 
        $$ = Instruction::CreateRType(Instruction::DIV, $2, $4, $6);
    }
    | REM REGISTER COMMA REGISTER COMMA REGISTER { 
        $$ = Instruction::CreateRType(Instruction::REM, $2, $4, $6);
    }
    | AND REGISTER COMMA REGISTER COMMA REGISTER { 
        $$ = Instruction::CreateRType(Instruction::AND, $2, $4, $6);
    }
    | OR REGISTER COMMA REGISTER COMMA REGISTER { 
        $$ = Instruction::CreateRType(Instruction::OR, $2, $4, $6);
    }
    | XOR REGISTER COMMA REGISTER COMMA REGISTER { 
        $$ = Instruction::CreateRType(Instruction::XOR, $2, $4, $6);
    }
    | SLL REGISTER COMMA REGISTER COMMA REGISTER { 
        $$ = Instruction::CreateRType(Instruction::SLL, $2, $4, $6);
    }
    | SRL REGISTER COMMA REGISTER COMMA REGISTER { 
        $$ = Instruction::CreateRType(Instruction::SRL, $2, $4, $6);
    }
    | SRA REGISTER COMMA REGISTER COMMA REGISTER { 
        $$ = Instruction::CreateRType(Instruction::SRA, $2, $4, $6);
    }
    ;

/* I-type: addi, lw, etc. */
i_type_inst:
    ADDI REGISTER COMMA REGISTER COMMA NUMBER { 
        $$ = Instruction::CreateIType(Instruction::ADDI, $2, $4, $6);
    }
    | LW REGISTER COMMA NUMBER LPAREN REGISTER RPAREN { 
        $$ = Instruction::CreateIType(Instruction::LW, $2, $6, $4);
    }
    | LB REGISTER COMMA NUMBER LPAREN REGISTER RPAREN { 
        $$ = Instruction::CreateIType(Instruction::LB, $2, $6, $4);
    }
    | JALR REGISTER COMMA REGISTER COMMA NUMBER { 
        $$ = Instruction::CreateIType(Instruction::JALR, $2, $4, $6);
    }
    ;

/* S-type: sw, sb */
s_type_inst:
    SW REGISTER COMMA NUMBER LPAREN REGISTER RPAREN { 
        $$ = Instruction::CreateSType(Instruction::SW, $2, $6, $4);
    }
    | SB REGISTER COMMA NUMBER LPAREN REGISTER RPAREN { 
        $$ = Instruction::CreateSType(Instruction::SB, $2, $6, $4);
    }
    ;

/* B-type: beq, bne, etc. */
b_type_inst:
    BEQ REGISTER COMMA REGISTER COMMA IDENTIFIER { 
        $$ = Instruction::CreateBType(Instruction::BEQ, $2, $4, $6);
    }
    | BNE REGISTER COMMA REGISTER COMMA IDENTIFIER { 
        $$ = Instruction::CreateBType(Instruction::BNE, $2, $4, $6);
    }
    | BLT REGISTER COMMA REGISTER COMMA IDENTIFIER { 
        $$ = Instruction::CreateBType(Instruction::BLT, $2, $4, $6);
    }
    | BGE REGISTER COMMA REGISTER COMMA IDENTIFIER { 
        $$ = Instruction::CreateBType(Instruction::BGE, $2, $4, $6);
    }
    ;

/* U-type: lui */
u_type_inst:
    /* Empty for now */
    ;

/* J-type: jal */
j_type_inst:
    JAL REGISTER COMMA IDENTIFIER { 
        $$ = Instruction::CreateJType(Instruction::JAL, $2, $4);
    }
    | JAL IDENTIFIER { 
        $$ = Instruction::CreateJType(Instruction::JAL, 1, $2);
    }
    ;

/* Special instructions */
special_inst:
    RET { 
        $$ = std::make_unique<Instruction>(Instruction::RET); 
    }
    | ECALL { 
        $$ = std::make_unique<Instruction>(Instruction::ECALL); 
    }
    ;

%%

void yyerror(const char *s) {
    std::cerr << "Syntax error on line " << yylineno 
              << ": " << s << std::endl;
}

c2rars::ast::Program* getAST() {
    return rootProgram.get();
}
