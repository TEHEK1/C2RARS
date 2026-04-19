#ifndef AST_H
#define AST_H

#include <string>
#include <vector>
#include <memory>
#include <iostream>

namespace c2rars {
namespace ast {

class ASTNode {
public:
    virtual ~ASTNode() = default;
    virtual void print(std::ostream& os, int indent = 0) const = 0;
};

class Directive : public ASTNode {
public:
    enum Type {
        TEXT, DATA, BSS, GLOBL, ALIGN, 
        SECTION, STRING, ASCIZ, WORD, BYTE, HALF, SPACE, COMM
    };
    
    Type type;
    std::string argument;
    int numericArg;
    
    Directive(Type t, const std::string& arg = "", int num = 0)
        : type(t), argument(arg), numericArg(num) {}
    
    void print(std::ostream& os, int indent = 0) const override {
        os << std::string(indent, ' ') << "Directive: " << typeToString() 
           << " " << argument;
        if (numericArg != 0) os << " " << numericArg;
        os << "\n";
    }
    
    std::string typeToString() const {
        switch(type) {
            case TEXT: return ".text";
            case DATA: return ".data";
            case BSS: return ".bss";
            case GLOBL: return ".globl";
            case ALIGN: return ".align";
            case SECTION: return ".section";
            case STRING: return ".string";
            case ASCIZ: return ".asciz";
            case WORD: return ".word";
            case BYTE: return ".byte";
            case HALF: return ".half";
            case SPACE: return ".space";
            case COMM: return ".comm";
            default: return "unknown";
        }
    }
};

class Label : public ASTNode {
public:
    std::string name;
    
    explicit Label(const std::string& n) : name(n) {}
    
    void print(std::ostream& os, int indent = 0) const override {
        os << std::string(indent, ' ') << "Label: " << name << "\n";
    }
};

class Operand {
public:
    virtual ~Operand() = default;
    
    virtual void print(std::ostream& os) const = 0;
    
    virtual std::unique_ptr<Operand> clone() const = 0;
};

class Register : public Operand {
private:
    int number;
    
public:
    explicit Register(int num) : number(num) {}
    
    int getNumber() const { return number; }
    
    void print(std::ostream& os) const override {
        if (number == 0) os << "zero";
        else if (number == 1) os << "ra";
        else if (number == 2) os << "sp";
        else if (number >= 10 && number <= 17) os << "a" << (number - 10);
        else if (number >= 5 && number <= 7) os << "t" << (number - 5);
        else if (number >= 8 && number <= 9) os << "s" << (number - 8);
        else os << "x" << number;
    }
    
    std::unique_ptr<Operand> clone() const override {
        return std::make_unique<Register>(number);
    }
};

class FRegister : public Operand {
private:
    int number;

public:
    explicit FRegister(int num) : number(num) {}

    int getNumber() const { return number; }

    void print(std::ostream& os) const override {
        if (number >= 0 && number <= 7)        os << "ft" << number;
        else if (number >= 8 && number <= 9)   os << "fs" << (number - 8);
        else if (number >= 10 && number <= 17) os << "fa" << (number - 10);
        else if (number >= 18 && number <= 27) os << "fs" << (number - 16);
        else if (number >= 28 && number <= 31) os << "ft" << (number - 20);
        else os << "f" << number;
    }

    std::unique_ptr<Operand> clone() const override {
        return std::make_unique<FRegister>(number);
    }
};

class Immediate : public Operand {
private:
    int value;
    
public:
    explicit Immediate(int val) : value(val) {}
    
    int getValue() const { return value; }
    
    void print(std::ostream& os) const override {
        os << value;
    }
    
    std::unique_ptr<Operand> clone() const override {
        return std::make_unique<Immediate>(value);
    }
};

class LabelOperand : public Operand {
private:
    std::string name;
    
public:
    explicit LabelOperand(const std::string& n) : name(n) {}
    
    const std::string& getName() const { return name; }
    
    void print(std::ostream& os) const override {
        os << name;
    }
    
    std::unique_ptr<Operand> clone() const override {
        return std::make_unique<LabelOperand>(name);
    }
};

class Instruction : public ASTNode {
public:
    enum OpCode {
        ADD, SUB, MUL, MULH, DIV, REM,
        AND, OR, XOR,
        SLL, SRL, SRA,
        ADDI, SLTI, XORI, ORI, ANDI,
        SLLI, SRLI, SRAI,
        LW, LH, LB, LWU, LHU, LBU,
        JALR,
        SW, SH, SB,
        BEQ, BNE, BLT, BGE, BLTU, BGEU,
        LUI, AUIPC,
        JAL,
        ECALL, EBREAK, FENCE,
        LI, LA, MV, CALL, RET, J, JR,
        NOP, NEG, NOT, SEQZ, SNEZ,
        BGT, BLE, BGTU, BLEU,
        // RV32F extension
        FLW, FSW,
        FADD_S, FSUB_S, FMUL_S, FDIV_S, FSQRT_S,
        FCVT_W_S, FCVT_S_W, FCVT_WU_S, FCVT_S_WU,
        FMV_X_W, FMV_W_X, FMV_S,
        FEQ_S, FLT_S, FLE_S, FGT_S, FGE_S,
        FNEG_S, FABS_S, FCLASS_S,
        // RV32D extension
        FLD, FSD,
        FADD_D, FSUB_D, FMUL_D, FDIV_D, FSQRT_D,
        FCVT_W_D, FCVT_D_W, FCVT_WU_D, FCVT_D_WU,
        FCVT_S_D, FCVT_D_S,
        FMV_D,
        FEQ_D, FLT_D, FLE_D, FGT_D, FGE_D,
        FNEG_D, FABS_D, FCLASS_D,
        FMIN_D, FMAX_D, FMIN_S, FMAX_S
    };
    
    OpCode opcode;
    std::vector<std::unique_ptr<Operand>> operands;
    
    explicit Instruction(OpCode op) : opcode(op) {}
    
    static std::unique_ptr<Instruction> CreateRType(OpCode op, int rd, int rs1, int rs2) {
        auto inst = std::make_unique<Instruction>(op);
        inst->addRegister(rd);
        inst->addRegister(rs1);
        inst->addRegister(rs2);
        return inst;
    }
    
    static std::unique_ptr<Instruction> CreateIType(OpCode op, int rd, int rs1, int imm) {
        auto inst = std::make_unique<Instruction>(op);
        inst->addRegister(rd);
        inst->addRegister(rs1);
        inst->addImmediate(imm);
        return inst;
    }
    
    static std::unique_ptr<Instruction> CreateSType(OpCode op, int rs2, int rs1, int imm) {
        auto inst = std::make_unique<Instruction>(op);
        inst->addRegister(rs2);
        inst->addImmediate(imm);
        inst->addRegister(rs1);
        return inst;
    }
    
    static std::unique_ptr<Instruction> CreateBType(OpCode op, int rs1, int rs2, const std::string& label) {
        auto inst = std::make_unique<Instruction>(op);
        inst->addRegister(rs1);
        inst->addRegister(rs2);
        inst->addLabel(label);
        return inst;
    }
    
    static std::unique_ptr<Instruction> CreateJType(OpCode op, int rd, const std::string& label) {
        auto inst = std::make_unique<Instruction>(op);
        inst->addRegister(rd);
        inst->addLabel(label);
        return inst;
    }
    
    void addOperand(std::unique_ptr<Operand> operand) {
        operands.push_back(std::move(operand));
    }
    
    void addRegister(int reg) {
        operands.push_back(std::make_unique<Register>(reg));
    }
    
    void addFRegister(int reg) {
        operands.push_back(std::make_unique<FRegister>(reg));
    }
    
    void addImmediate(int imm) {
        operands.push_back(std::make_unique<Immediate>(imm));
    }
    
    void addLabel(const std::string& label) {
        operands.push_back(std::make_unique<LabelOperand>(label));
    }
    
    size_t getOperandCount() const { return operands.size(); }
    
    const Operand* getOperand(size_t index) const { 
        return operands[index].get(); 
    }
    
    Operand* getOperand(size_t index) { 
        return operands[index].get(); 
    }
    
    void print(std::ostream& os, int indent = 0) const override {
        os << std::string(indent, ' ') << "Instruction: " << opcodeToString();
        
        for (size_t i = 0; i < operands.size(); i++) {
            if (i > 0) os << ",";
            os << " ";
            operands[i]->print(os);
        }
        os << "\n";
    }
    
    std::string opcodeToString() const {
        switch(opcode) {
            case ADD: return "add";
            case SUB: return "sub";
            case MUL: return "mul";
            case MULH: return "mulh";
            case DIV: return "div";
            case REM: return "rem";
            case AND: return "and";
            case OR: return "or";
            case XOR: return "xor";
            case SLL: return "sll";
            case SRL: return "srl";
            case SRA: return "sra";
            case ADDI: return "addi";
            case SLTI: return "slti";
            case XORI: return "xori";
            case ORI: return "ori";
            case ANDI: return "andi";
            case SLLI: return "slli";
            case SRLI: return "srli";
            case SRAI: return "srai";
            case LW: return "lw";
            case LH: return "lh";
            case LB: return "lb";
            case LWU: return "lwu";
            case LHU: return "lhu";
            case LBU: return "lbu";
            case JALR: return "jalr";
            case SW: return "sw";
            case SH: return "sh";
            case SB: return "sb";
            case BEQ: return "beq";
            case BNE: return "bne";
            case BLT: return "blt";
            case BGE: return "bge";
            case BLTU: return "bltu";
            case BGEU: return "bgeu";
            case LUI: return "lui";
            case AUIPC: return "auipc";
            case JAL: return "jal";
            case ECALL: return "ecall";
            case EBREAK: return "ebreak";
            case FENCE: return "fence";
            case LI: return "li";
            case LA: return "la";
            case MV: return "mv";
            case CALL: return "call";
            case RET: return "ret";
            case J: return "j";
            case JR: return "jr";
            case NOP: return "nop";
            case NEG: return "neg";
            case NOT: return "not";
            case SEQZ: return "seqz";
            case SNEZ: return "snez";
            case BGT: return "bgt";
            case BLE: return "ble";
            case BGTU: return "bgtu";
            case BLEU: return "bleu";
            case FLW: return "flw";
            case FSW: return "fsw";
            case FADD_S: return "fadd.s";
            case FSUB_S: return "fsub.s";
            case FMUL_S: return "fmul.s";
            case FDIV_S: return "fdiv.s";
            case FSQRT_S: return "fsqrt.s";
            case FCVT_W_S: return "fcvt.w.s";
            case FCVT_S_W: return "fcvt.s.w";
            case FCVT_WU_S: return "fcvt.wu.s";
            case FCVT_S_WU: return "fcvt.s.wu";
            case FMV_X_W: return "fmv.x.w";
            case FMV_W_X: return "fmv.w.x";
            case FMV_S: return "fmv.s";
            case FEQ_S: return "feq.s";
            case FLT_S: return "flt.s";
            case FLE_S: return "fle.s";
            case FGT_S: return "fgt.s";
            case FGE_S: return "fge.s";
            case FNEG_S: return "fneg.s";
            case FABS_S: return "fabs.s";
            case FCLASS_S: return "fclass.s";
            case FLD: return "fld";
            case FSD: return "fsd";
            case FADD_D: return "fadd.d";
            case FSUB_D: return "fsub.d";
            case FMUL_D: return "fmul.d";
            case FDIV_D: return "fdiv.d";
            case FSQRT_D: return "fsqrt.d";
            case FCVT_W_D: return "fcvt.w.d";
            case FCVT_D_W: return "fcvt.d.w";
            case FCVT_WU_D: return "fcvt.wu.d";
            case FCVT_D_WU: return "fcvt.d.wu";
            case FCVT_S_D: return "fcvt.s.d";
            case FCVT_D_S: return "fcvt.d.s";
            case FMV_D: return "fmv.d";
            case FEQ_D: return "feq.d";
            case FLT_D: return "flt.d";
            case FLE_D: return "fle.d";
            case FGT_D: return "fgt.d";
            case FGE_D: return "fge.d";
            case FNEG_D: return "fneg.d";
            case FABS_D: return "fabs.d";
            case FCLASS_D: return "fclass.d";
            case FMIN_D: return "fmin.d";
            case FMAX_D: return "fmax.d";
            case FMIN_S: return "fmin.s";
            case FMAX_S: return "fmax.s";
            default: return "unknown";
        }
    }
};

class Program : public ASTNode {
public:
    std::vector<std::unique_ptr<ASTNode>> statements;
    
    void addStatement(std::unique_ptr<ASTNode> stmt) {
        statements.push_back(std::move(stmt));
    }
    
    void print(std::ostream& os, int indent = 0) const override {
        os << "Program:\n";
        for (const auto& stmt : statements) {
            stmt->print(os, indent + 2);
        }
    }
};

} // namespace ast
} // namespace c2rars

#endif // AST_H
