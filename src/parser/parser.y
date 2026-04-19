%{
#include <iostream>
#include <string>
#include <memory>
#include <vector>
#include "ast.h"

using namespace c2rars::ast;

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

%code {
    #include "scanner.h"
    
    c2rars::Scanner* scanner = nullptr;
    
    namespace yy {
        parser::symbol_type yylex() {
            return scanner->get_next_token();
        }
    }
}

/* Directive tokens */
%token TEXT_DIRECTIVE DATA_DIRECTIVE BSS_DIRECTIVE
%token GLOBL_DIRECTIVE ALIGN_DIRECTIVE SECTION_DIRECTIVE
%token STRING_DIRECTIVE ASCIZ_DIRECTIVE
%token WORD_DIRECTIVE BYTE_DIRECTIVE HALF_DIRECTIVE SPACE_DIRECTIVE
%token COMM_DIRECTIVE

/* Instruction tokens */
%token ADD ADDI SUB MUL MULH DIV REM
%token AND OR XOR ANDI ORI XORI
%token SLL SRL SRA SLLI SRLI SRAI
%token SLT SLTI SLTU
%token LW SW LB SB LBU LH LHU SH
%token BEQ BNE BLT BGE BLTU BGEU
%token BGT BLE BGTU BLEU
%token JAL JALR RET ECALL
%token LA LI MV JR LUI CALL
%token J NOP NEG NOT_INST SEQZ SNEZ

/* RV32F instruction tokens */
%token FLW FSW
%token FADD_S FSUB_S FMUL_S FDIV_S FSQRT_S
%token FCVT_W_S FCVT_S_W FCVT_WU_S FCVT_S_WU
%token FMV_X_W FMV_W_X FMV_S
%token FEQ_S FLT_S FLE_S FGT_S FGE_S
%token FNEG_S FABS_S FCLASS_S

/* Operand tokens */
%token <int> REGISTER
%token <int> FREGISTER
%token <int> NUMBER
%token <std::string> IDENTIFIER STRING LABEL_DEF

/* Delimiters */
%token COMMA LPAREN RPAREN COLON NEWLINE ERROR

/* Nonterminal types */
%type <ASTNodePtr> line
%type <InstructionPtr> instruction r_type_inst i_type_inst s_type_inst b_type_inst u_type_inst j_type_inst special_inst pseudo_inst f_inst
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
    | COMM_DIRECTIVE IDENTIFIER COMMA NUMBER COMMA NUMBER {
        $$ = std::make_unique<Directive>(Directive::COMM, $2, $4);
    }
    | COMM_DIRECTIVE IDENTIFIER COMMA NUMBER {
        $$ = std::make_unique<Directive>(Directive::COMM, $2, $4);
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
    r_type_inst { $$ = std::move($1); }
    | i_type_inst { $$ = std::move($1); }
    | s_type_inst { $$ = std::move($1); }
    | b_type_inst { $$ = std::move($1); }
    | u_type_inst { $$ = std::move($1); }
    | j_type_inst { $$ = std::move($1); }
    | special_inst { $$ = std::move($1); }
    | pseudo_inst { $$ = std::move($1); }
    | f_inst { $$ = std::move($1); }
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
    | MULH REGISTER COMMA REGISTER COMMA REGISTER { 
        $$ = Instruction::CreateRType(Instruction::MULH, $2, $4, $6);
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
    | SLT REGISTER COMMA REGISTER COMMA REGISTER { 
        $$ = Instruction::CreateRType(Instruction::SLTI, $2, $4, $6);
    }
    | SLTU REGISTER COMMA REGISTER COMMA REGISTER { 
        $$ = Instruction::CreateRType(Instruction::SLTI, $2, $4, $6);
    }
    ;

/* I-type: addi, lw, etc. */
i_type_inst:
    ADDI REGISTER COMMA REGISTER COMMA NUMBER { 
        $$ = Instruction::CreateIType(Instruction::ADDI, $2, $4, $6);
    }
    | ADDI REGISTER COMMA REGISTER COMMA IDENTIFIER {
        auto inst = std::make_unique<Instruction>(Instruction::ADDI);
        inst->addRegister($2);
        inst->addRegister($4);
        inst->addLabel($6);
        $$ = std::move(inst);
    }
    | LW REGISTER COMMA NUMBER LPAREN REGISTER RPAREN {
        // Load needs [rd, imm, rs1] order for transformer compatibility  
        auto inst = std::make_unique<Instruction>(Instruction::LW);
        inst->addRegister($2);      // rd
        inst->addImmediate($4);     // offset
        inst->addRegister($6);      // base
        $$ = std::move(inst);
    }
    | LW REGISTER COMMA IDENTIFIER LPAREN REGISTER RPAREN {
        auto inst = std::make_unique<Instruction>(Instruction::LW);
        inst->addRegister($2); inst->addLabel($4); inst->addRegister($6);
        $$ = std::move(inst);
    }
    | LB REGISTER COMMA NUMBER LPAREN REGISTER RPAREN {
        auto inst = std::make_unique<Instruction>(Instruction::LB);
        inst->addRegister($2);      // rd
        inst->addImmediate($4);     // offset
        inst->addRegister($6);      // base
        $$ = std::move(inst);
    }
    | LB REGISTER COMMA IDENTIFIER LPAREN REGISTER RPAREN {
        auto inst = std::make_unique<Instruction>(Instruction::LB);
        inst->addRegister($2); inst->addLabel($4); inst->addRegister($6);
        $$ = std::move(inst);
    }
    | LBU REGISTER COMMA NUMBER LPAREN REGISTER RPAREN {
        auto inst = std::make_unique<Instruction>(Instruction::LBU);
        inst->addRegister($2);
        inst->addImmediate($4);
        inst->addRegister($6);
        $$ = std::move(inst);
    }
    | LBU REGISTER COMMA IDENTIFIER LPAREN REGISTER RPAREN {
        auto inst = std::make_unique<Instruction>(Instruction::LBU);
        inst->addRegister($2); inst->addLabel($4); inst->addRegister($6);
        $$ = std::move(inst);
    }
    | LH REGISTER COMMA NUMBER LPAREN REGISTER RPAREN {
        auto inst = std::make_unique<Instruction>(Instruction::LH);
        inst->addRegister($2);
        inst->addImmediate($4);
        inst->addRegister($6);
        $$ = std::move(inst);
    }
    | LH REGISTER COMMA IDENTIFIER LPAREN REGISTER RPAREN {
        auto inst = std::make_unique<Instruction>(Instruction::LH);
        inst->addRegister($2); inst->addLabel($4); inst->addRegister($6);
        $$ = std::move(inst);
    }
    | LHU REGISTER COMMA NUMBER LPAREN REGISTER RPAREN {
        auto inst = std::make_unique<Instruction>(Instruction::LHU);
        inst->addRegister($2);
        inst->addImmediate($4);
        inst->addRegister($6);
        $$ = std::move(inst);
    }
    | LHU REGISTER COMMA IDENTIFIER LPAREN REGISTER RPAREN {
        auto inst = std::make_unique<Instruction>(Instruction::LHU);
        inst->addRegister($2); inst->addLabel($4); inst->addRegister($6);
        $$ = std::move(inst);
    }
    | JALR REGISTER COMMA REGISTER COMMA NUMBER { 
        $$ = Instruction::CreateIType(Instruction::JALR, $2, $4, $6);
    }
    | SLLI REGISTER COMMA REGISTER COMMA NUMBER {
        $$ = Instruction::CreateIType(Instruction::SLLI, $2, $4, $6);
    }
    | SRLI REGISTER COMMA REGISTER COMMA NUMBER {
        $$ = Instruction::CreateIType(Instruction::SRLI, $2, $4, $6);
    }
    | SRAI REGISTER COMMA REGISTER COMMA NUMBER {
        $$ = Instruction::CreateIType(Instruction::SRAI, $2, $4, $6);
    }
    | ANDI REGISTER COMMA REGISTER COMMA NUMBER {
        $$ = Instruction::CreateIType(Instruction::ANDI, $2, $4, $6);
    }
    | ORI REGISTER COMMA REGISTER COMMA NUMBER {
        $$ = Instruction::CreateIType(Instruction::ORI, $2, $4, $6);
    }
    | XORI REGISTER COMMA REGISTER COMMA NUMBER {
        $$ = Instruction::CreateIType(Instruction::XORI, $2, $4, $6);
    }
    | SLTI REGISTER COMMA REGISTER COMMA NUMBER {
        $$ = Instruction::CreateIType(Instruction::SLTI, $2, $4, $6);
    }
    ;

/* S-type: sw, sb */
s_type_inst:
    SW REGISTER COMMA NUMBER LPAREN REGISTER RPAREN { 
        $$ = Instruction::CreateSType(Instruction::SW, $2, $6, $4);
    }
    | SW REGISTER COMMA IDENTIFIER LPAREN REGISTER RPAREN {
        auto inst = std::make_unique<Instruction>(Instruction::SW);
        inst->addRegister($2); inst->addLabel($4); inst->addRegister($6);
        $$ = std::move(inst);
    }
    | SB REGISTER COMMA NUMBER LPAREN REGISTER RPAREN { 
        $$ = Instruction::CreateSType(Instruction::SB, $2, $6, $4);
    }
    | SB REGISTER COMMA IDENTIFIER LPAREN REGISTER RPAREN {
        auto inst = std::make_unique<Instruction>(Instruction::SB);
        inst->addRegister($2); inst->addLabel($4); inst->addRegister($6);
        $$ = std::move(inst);
    }
    | SH REGISTER COMMA NUMBER LPAREN REGISTER RPAREN {
        $$ = Instruction::CreateSType(Instruction::SH, $2, $6, $4);
    }
    | SH REGISTER COMMA IDENTIFIER LPAREN REGISTER RPAREN {
        auto inst = std::make_unique<Instruction>(Instruction::SH);
        inst->addRegister($2); inst->addLabel($4); inst->addRegister($6);
        $$ = std::move(inst);
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
    | BLTU REGISTER COMMA REGISTER COMMA IDENTIFIER {
        $$ = Instruction::CreateBType(Instruction::BLTU, $2, $4, $6);
    }
    | BGEU REGISTER COMMA REGISTER COMMA IDENTIFIER {
        $$ = Instruction::CreateBType(Instruction::BGEU, $2, $4, $6);
    }
    | BGT REGISTER COMMA REGISTER COMMA IDENTIFIER {
        $$ = Instruction::CreateBType(Instruction::BGT, $2, $4, $6);
    }
    | BLE REGISTER COMMA REGISTER COMMA IDENTIFIER {
        $$ = Instruction::CreateBType(Instruction::BLE, $2, $4, $6);
    }
    | BGTU REGISTER COMMA REGISTER COMMA IDENTIFIER {
        $$ = Instruction::CreateBType(Instruction::BGTU, $2, $4, $6);
    }
    | BLEU REGISTER COMMA REGISTER COMMA IDENTIFIER {
        $$ = Instruction::CreateBType(Instruction::BLEU, $2, $4, $6);
    }
    ;

/* U-type: lui, auipc */
u_type_inst:
    LUI REGISTER COMMA NUMBER {
        auto inst = std::make_unique<Instruction>(Instruction::LUI);
        inst->addRegister($2);
        inst->addImmediate($4);
        $$ = std::move(inst);
    }
    | LUI REGISTER COMMA IDENTIFIER {
        auto inst = std::make_unique<Instruction>(Instruction::LUI);
        inst->addRegister($2);
        inst->addLabel($4);
        $$ = std::move(inst);
    }
    ;

/* J-type: jal */
j_type_inst:
    JAL REGISTER COMMA IDENTIFIER { 
        $$ = Instruction::CreateJType(Instruction::JAL, $2, $4);
    }
    | JAL IDENTIFIER { 
        $$ = Instruction::CreateJType(Instruction::JAL, 1, $2);
    }
    | J IDENTIFIER {
        auto inst = std::make_unique<Instruction>(Instruction::J);
        inst->addLabel($2);
        $$ = std::move(inst);
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
    | LA REGISTER COMMA IDENTIFIER {
        auto inst = std::make_unique<Instruction>(Instruction::LA);
        inst->addRegister($2);
        inst->addLabel($4);
        $$ = std::move(inst);
    }
    | LI REGISTER COMMA NUMBER {
        auto inst = std::make_unique<Instruction>(Instruction::LI);
        inst->addRegister($2);
        inst->addImmediate($4);
        $$ = std::move(inst);
    }
    | MV REGISTER COMMA REGISTER {
        auto inst = std::make_unique<Instruction>(Instruction::MV);
        inst->addRegister($2);
        inst->addRegister($4);
        $$ = std::move(inst);
    }
    | JR REGISTER {
        auto inst = std::make_unique<Instruction>(Instruction::JR);
        inst->addRegister($2);
        $$ = std::move(inst);
    }
    | CALL IDENTIFIER {
        auto inst = std::make_unique<Instruction>(Instruction::CALL);
        inst->addLabel($2);
        $$ = std::move(inst);
    }
    ;

pseudo_inst:
    NOP {
        $$ = std::make_unique<Instruction>(Instruction::NOP);
    }
    | NEG REGISTER COMMA REGISTER {
        auto inst = std::make_unique<Instruction>(Instruction::NEG);
        inst->addRegister($2);
        inst->addRegister($4);
        $$ = std::move(inst);
    }
    | NOT_INST REGISTER COMMA REGISTER {
        auto inst = std::make_unique<Instruction>(Instruction::NOT);
        inst->addRegister($2);
        inst->addRegister($4);
        $$ = std::move(inst);
    }
    | SEQZ REGISTER COMMA REGISTER {
        auto inst = std::make_unique<Instruction>(Instruction::SEQZ);
        inst->addRegister($2);
        inst->addRegister($4);
        $$ = std::move(inst);
    }
    | SNEZ REGISTER COMMA REGISTER {
        auto inst = std::make_unique<Instruction>(Instruction::SNEZ);
        inst->addRegister($2);
        inst->addRegister($4);
        $$ = std::move(inst);
    }
    ;

/* RV32F floating-point instructions */
f_inst:
    /* fadd.s/fsub.s/fmul.s/fdiv.s fd, fs1, fs2 */
    FADD_S FREGISTER COMMA FREGISTER COMMA FREGISTER {
        auto inst = std::make_unique<Instruction>(Instruction::FADD_S);
        inst->addFRegister($2); inst->addFRegister($4); inst->addFRegister($6);
        $$ = std::move(inst);
    }
    | FSUB_S FREGISTER COMMA FREGISTER COMMA FREGISTER {
        auto inst = std::make_unique<Instruction>(Instruction::FSUB_S);
        inst->addFRegister($2); inst->addFRegister($4); inst->addFRegister($6);
        $$ = std::move(inst);
    }
    | FMUL_S FREGISTER COMMA FREGISTER COMMA FREGISTER {
        auto inst = std::make_unique<Instruction>(Instruction::FMUL_S);
        inst->addFRegister($2); inst->addFRegister($4); inst->addFRegister($6);
        $$ = std::move(inst);
    }
    | FDIV_S FREGISTER COMMA FREGISTER COMMA FREGISTER {
        auto inst = std::make_unique<Instruction>(Instruction::FDIV_S);
        inst->addFRegister($2); inst->addFRegister($4); inst->addFRegister($6);
        $$ = std::move(inst);
    }
    /* fsqrt.s fd, fs1 */
    | FSQRT_S FREGISTER COMMA FREGISTER {
        auto inst = std::make_unique<Instruction>(Instruction::FSQRT_S);
        inst->addFRegister($2); inst->addFRegister($4);
        $$ = std::move(inst);
    }
    /* flw fd, offset(rs1) */
    | FLW FREGISTER COMMA NUMBER LPAREN REGISTER RPAREN {
        auto inst = std::make_unique<Instruction>(Instruction::FLW);
        inst->addFRegister($2); inst->addImmediate($4); inst->addRegister($6);
        $$ = std::move(inst);
    }
    /* flw fd, %lo(label)(rs1) — GCC relocation form */
    | FLW FREGISTER COMMA IDENTIFIER LPAREN REGISTER RPAREN {
        auto inst = std::make_unique<Instruction>(Instruction::FLW);
        inst->addFRegister($2); inst->addLabel($4); inst->addRegister($6);
        $$ = std::move(inst);
    }
    /* fsw fs2, offset(rs1) */
    | FSW FREGISTER COMMA NUMBER LPAREN REGISTER RPAREN {
        auto inst = std::make_unique<Instruction>(Instruction::FSW);
        inst->addFRegister($2); inst->addImmediate($4); inst->addRegister($6);
        $$ = std::move(inst);
    }
    | FSW FREGISTER COMMA IDENTIFIER LPAREN REGISTER RPAREN {
        auto inst = std::make_unique<Instruction>(Instruction::FSW);
        inst->addFRegister($2); inst->addLabel($4); inst->addRegister($6);
        $$ = std::move(inst);
    }
    /* fcvt.w.s rd, fs1 (with optional rounding mode) */
    | FCVT_W_S REGISTER COMMA FREGISTER {
        auto inst = std::make_unique<Instruction>(Instruction::FCVT_W_S);
        inst->addRegister($2); inst->addFRegister($4);
        $$ = std::move(inst);
    }
    | FCVT_W_S REGISTER COMMA FREGISTER COMMA IDENTIFIER {
        auto inst = std::make_unique<Instruction>(Instruction::FCVT_W_S);
        inst->addRegister($2); inst->addFRegister($4); inst->addLabel($6);
        $$ = std::move(inst);
    }
    /* fcvt.s.w fd, rs1 */
    | FCVT_S_W FREGISTER COMMA REGISTER {
        auto inst = std::make_unique<Instruction>(Instruction::FCVT_S_W);
        inst->addFRegister($2); inst->addRegister($4);
        $$ = std::move(inst);
    }
    /* fcvt.wu.s rd, fs1 (with optional rounding mode) */
    | FCVT_WU_S REGISTER COMMA FREGISTER {
        auto inst = std::make_unique<Instruction>(Instruction::FCVT_WU_S);
        inst->addRegister($2); inst->addFRegister($4);
        $$ = std::move(inst);
    }
    | FCVT_WU_S REGISTER COMMA FREGISTER COMMA IDENTIFIER {
        auto inst = std::make_unique<Instruction>(Instruction::FCVT_WU_S);
        inst->addRegister($2); inst->addFRegister($4); inst->addLabel($6);
        $$ = std::move(inst);
    }
    /* fcvt.s.wu fd, rs1 */
    | FCVT_S_WU FREGISTER COMMA REGISTER {
        auto inst = std::make_unique<Instruction>(Instruction::FCVT_S_WU);
        inst->addFRegister($2); inst->addRegister($4);
        $$ = std::move(inst);
    }
    /* fmv.x.w rd, fs1   and   fmv.w.x fd, rs1 */
    | FMV_X_W REGISTER COMMA FREGISTER {
        auto inst = std::make_unique<Instruction>(Instruction::FMV_X_W);
        inst->addRegister($2); inst->addFRegister($4);
        $$ = std::move(inst);
    }
    | FMV_W_X FREGISTER COMMA REGISTER {
        auto inst = std::make_unique<Instruction>(Instruction::FMV_W_X);
        inst->addFRegister($2); inst->addRegister($4);
        $$ = std::move(inst);
    }
    /* fmv.s fd, fs1 (pseudo) */
    | FMV_S FREGISTER COMMA FREGISTER {
        auto inst = std::make_unique<Instruction>(Instruction::FMV_S);
        inst->addFRegister($2); inst->addFRegister($4);
        $$ = std::move(inst);
    }
    /* feq.s/flt.s/fle.s/fgt.s/fge.s rd, fs1, fs2 */
    | FEQ_S REGISTER COMMA FREGISTER COMMA FREGISTER {
        auto inst = std::make_unique<Instruction>(Instruction::FEQ_S);
        inst->addRegister($2); inst->addFRegister($4); inst->addFRegister($6);
        $$ = std::move(inst);
    }
    | FLT_S REGISTER COMMA FREGISTER COMMA FREGISTER {
        auto inst = std::make_unique<Instruction>(Instruction::FLT_S);
        inst->addRegister($2); inst->addFRegister($4); inst->addFRegister($6);
        $$ = std::move(inst);
    }
    | FLE_S REGISTER COMMA FREGISTER COMMA FREGISTER {
        auto inst = std::make_unique<Instruction>(Instruction::FLE_S);
        inst->addRegister($2); inst->addFRegister($4); inst->addFRegister($6);
        $$ = std::move(inst);
    }
    | FGT_S REGISTER COMMA FREGISTER COMMA FREGISTER {
        auto inst = std::make_unique<Instruction>(Instruction::FGT_S);
        inst->addRegister($2); inst->addFRegister($4); inst->addFRegister($6);
        $$ = std::move(inst);
    }
    | FGE_S REGISTER COMMA FREGISTER COMMA FREGISTER {
        auto inst = std::make_unique<Instruction>(Instruction::FGE_S);
        inst->addRegister($2); inst->addFRegister($4); inst->addFRegister($6);
        $$ = std::move(inst);
    }
    /* fneg.s/fabs.s fd, fs1 (pseudo) */
    | FNEG_S FREGISTER COMMA FREGISTER {
        auto inst = std::make_unique<Instruction>(Instruction::FNEG_S);
        inst->addFRegister($2); inst->addFRegister($4);
        $$ = std::move(inst);
    }
    | FABS_S FREGISTER COMMA FREGISTER {
        auto inst = std::make_unique<Instruction>(Instruction::FABS_S);
        inst->addFRegister($2); inst->addFRegister($4);
        $$ = std::move(inst);
    }
    /* fclass.s rd, fs1 */
    | FCLASS_S REGISTER COMMA FREGISTER {
        auto inst = std::make_unique<Instruction>(Instruction::FCLASS_S);
        inst->addRegister($2); inst->addFRegister($4);
        $$ = std::move(inst);
    }
    ;

%%

namespace yy {
    void parser::error(const std::string& msg) {
        std::cerr << "Syntax error: " << msg << std::endl;
    }
}

c2rars::ast::Program* getAST() {
    return rootProgram.get();
}
