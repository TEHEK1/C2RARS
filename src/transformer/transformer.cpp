#include "transformer.h"
#include "ast.h"
#include <fstream>
#include <iostream>
#include <sstream>
#include <algorithm>
#include <unordered_set>

namespace c2rars {

using namespace c2rars::ast;

bool Transformer::transformAST(ast::Program* ast) {
    if (!ast) {
        std::cerr << "Error: AST is empty" << std::endl;
        return false;
    }

    if (m_verbose)
        std::cout << "Transforming AST..." << std::endl;

    removeUnsupportedDirectives(ast);
    foldLuiAddiPairs(ast);

    for (auto& stmt : ast->statements) {
        if (auto* inst = dynamic_cast<Instruction*>(stmt.get()))
            processInstruction(inst);
    }

    replaceMainReturn(ast);
    generateCodeFromAST(ast);

    if (m_verbose)
        std::cout << "AST transformation completed" << std::endl;

    return true;
}

bool Transformer::saveOutput(const std::string& filename) {
    if (m_verbose)
        std::cout << "Saving output to: " << filename << std::endl;

    std::ofstream file(filename);
    if (!file.is_open()) {
        std::cerr << "Error: failed to create file " << filename << std::endl;
        return false;
    }

    for (const auto& line : m_outputLines)
        file << line << "\n";

    return true;
}

// --- AST transformation passes ---

void Transformer::removeUnsupportedDirectives(ast::Program* ast) {
    if (m_verbose)
        std::cout << "Removing unsupported directives from AST..." << std::endl;

    static const std::unordered_set<Directive::Type> unsupported = {
        Directive::SECTION,
        Directive::ALIGN
    };

    size_t before = ast->statements.size();
    ast->statements.erase(
        std::remove_if(ast->statements.begin(), ast->statements.end(),
            [&](const std::unique_ptr<ASTNode>& stmt) {
                auto* dir = dynamic_cast<Directive*>(stmt.get());
                if (!dir || unsupported.find(dir->type) == unsupported.end())
                    return false;
                if (m_verbose)
                    std::cout << "  Removed directive: " << dir->typeToString() << std::endl;
                return true;
            }),
        ast->statements.end()
    );

    if (m_verbose && ast->statements.size() < before)
        std::cout << "  Removed " << (before - ast->statements.size()) << " directives" << std::endl;
}

void Transformer::foldLuiAddiPairs(ast::Program* ast) {
    for (size_t i = 0; i + 1 < ast->statements.size(); i++) {
        auto* lui = dynamic_cast<Instruction*>(ast->statements[i].get());
        auto* addi = dynamic_cast<Instruction*>(ast->statements[i + 1].get());

        if (!lui || !addi)
            continue;
        if (lui->opcode != Instruction::LUI || addi->opcode != Instruction::ADDI)
            continue;
        if (lui->operands.size() < 2 || addi->operands.size() < 3)
            continue;

        auto* luiLabel = dynamic_cast<LabelOperand*>(lui->operands[1].get());
        auto* addiLabel = dynamic_cast<LabelOperand*>(addi->operands[2].get());
        if (!luiLabel || !addiLabel || luiLabel->getName() != addiLabel->getName())
            continue;

        auto* luiReg = dynamic_cast<Register*>(lui->operands[0].get());
        auto* addiSrc = dynamic_cast<Register*>(addi->operands[1].get());
        if (!luiReg || !addiSrc || luiReg->getNumber() != addiSrc->getNumber())
            continue;

        auto* addiDest = dynamic_cast<Register*>(addi->operands[0].get());
        int destReg = addiDest->getNumber();
        std::string labelName = luiLabel->getName();

        if (m_verbose)
            std::cout << "  Folding lui+addi -> la x" << destReg << ", " << labelName << std::endl;

        lui->opcode = Instruction::LA;
        lui->operands.clear();
        lui->addRegister(destReg);
        lui->addLabel(labelName);

        ast->statements.erase(ast->statements.begin() + static_cast<long>(i + 1));
    }
}

void Transformer::replaceMainReturn(ast::Program* ast) {
    std::string currentFunction;

    for (size_t i = 0; i < ast->statements.size(); i++) {
        auto& stmt = ast->statements[i];

        if (auto* lbl = dynamic_cast<Label*>(stmt.get())) {
            if (!lbl->name.empty() && lbl->name[0] != '.')
                currentFunction = lbl->name;
            continue;
        }

        if (currentFunction != "main")
            continue;

        auto* inst = dynamic_cast<Instruction*>(stmt.get());
        if (!inst)
            continue;
        if (inst->opcode != Instruction::RET && inst->opcode != Instruction::JR)
            continue;

        if (m_verbose)
            std::cout << "  Replacing " << inst->opcodeToString() << " in main() with exit syscall" << std::endl;

        inst->opcode = Instruction::LI;
        inst->operands.clear();
        inst->addRegister(REG_A7);
        inst->addImmediate(RARS_EXIT);

        auto ecall = std::make_unique<Instruction>(Instruction::ECALL);
        ast->statements.insert(ast->statements.begin() + static_cast<long>(i + 1), std::move(ecall));
        i++;
    }
}

bool Transformer::processInstruction(ast::Instruction* inst) {
    if (!inst) return false;

    if (inst->opcode == Instruction::CALL && inst->getOperandCount() > 0) {
        auto* label = dynamic_cast<LabelOperand*>(inst->getOperand(0));
        if (!label) return false;

        const std::string& name = label->getName();
        if (name == "printf" || name == "puts") {
            if (m_verbose)
                std::cout << "  Replacing call " << name << " with RARS print_string syscall" << std::endl;
            inst->opcode = Instruction::LI;
            inst->operands.clear();
            inst->addRegister(REG_A7);
            inst->addImmediate(RARS_PRINT_STRING);
            return true;
        }
        if (name == "exit") {
            if (m_verbose)
                std::cout << "  Replacing call exit with RARS exit syscall" << std::endl;
            inst->opcode = Instruction::LI;
            inst->operands.clear();
            inst->addRegister(REG_A7);
            inst->addImmediate(RARS_EXIT);
            return true;
        }
        return false;
    }

    if (inst->opcode == Instruction::LI && inst->getOperandCount() >= 2) {
        auto* reg = dynamic_cast<Register*>(inst->getOperand(0));
        auto* imm = dynamic_cast<Immediate*>(inst->getOperand(1));
        if (reg && imm && reg->getNumber() == REG_A7) {
            int val = imm->getValue();
            if (val == LINUX_EXIT || val == LINUX_EXIT_GROUP) {
                if (m_verbose)
                    std::cout << "  Replacing Linux syscall " << val << " with RARS exit" << std::endl;
                inst->operands[1] = std::make_unique<Immediate>(RARS_EXIT);
                return true;
            }
        }
    }

    return false;
}

// --- Code generation ---

std::string Transformer::serializeNode(const ast::ASTNode* node) const {
    std::ostringstream ss;

    if (auto* dir = dynamic_cast<const Directive*>(node)) {
        ss << dir->typeToString();
        if (!dir->argument.empty())
            ss << " " << dir->argument;
        if (dir->numericArg != 0)
            ss << " " << dir->numericArg;
        return ss.str();
    }

    if (auto* lbl = dynamic_cast<const Label*>(node))
        return lbl->name + ":";

    auto* inst = dynamic_cast<const Instruction*>(node);
    if (!inst)
        return {};

    ss << "\t" << inst->opcodeToString();

    static const std::unordered_set<Instruction::OpCode> memOps = {
        Instruction::LW, Instruction::LB, Instruction::LBU,
        Instruction::LH, Instruction::LHU,
        Instruction::SW, Instruction::SB, Instruction::SH
    };

    bool isMemory = memOps.count(inst->opcode) && inst->getOperandCount() == 3;

    if (isMemory) {
        auto* reg0 = dynamic_cast<const Register*>(inst->getOperand(0));
        auto* imm = dynamic_cast<const Immediate*>(inst->getOperand(1));
        auto* reg2 = dynamic_cast<const Register*>(inst->getOperand(2));

        ss << " x" << reg0->getNumber()
           << ", " << imm->getValue()
           << "(x" << reg2->getNumber() << ")";
    } else {
        for (size_t i = 0; i < inst->getOperandCount(); i++) {
            ss << (i == 0 ? " " : ", ");
            const auto* op = inst->getOperand(i);
            if (auto* reg = dynamic_cast<const Register*>(op))
                ss << "x" << reg->getNumber();
            else if (auto* imm = dynamic_cast<const Immediate*>(op))
                ss << imm->getValue();
            else if (auto* label = dynamic_cast<const LabelOperand*>(op))
                ss << label->getName();
        }
    }

    return ss.str();
}

void Transformer::generateCodeFromAST(const ast::Program* ast) {
    if (m_verbose)
        std::cout << "Generating assembly code from AST..." << std::endl;

    m_outputLines.clear();
    m_outputLines.reserve(ast->statements.size());

    for (const auto& stmt : ast->statements) {
        std::string line = serializeNode(stmt.get());
        if (!line.empty())
            m_outputLines.push_back(std::move(line));
    }

    if (m_verbose)
        std::cout << "Generated " << m_outputLines.size() << " lines" << std::endl;

    reorganizeSections();
}

void Transformer::reorganizeSections() {
    static const std::unordered_set<std::string> dataDirectivePrefixes = {
        ".string", ".asciz", ".word", ".byte", ".half", ".space"
    };

    auto isDataDirective = [&](const std::string& line) {
        for (const auto& prefix : dataDirectivePrefixes)
            if (line.compare(0, prefix.size(), prefix) == 0)
                return true;
        return false;
    };

    std::vector<std::string> dataLines;
    std::vector<std::string> mainLines;
    std::vector<std::string> otherTextLines;

    std::string section;
    bool inMain = false;
    std::string prevLine;

    for (const auto& line : m_outputLines) {
        if (line == ".data") { section = "data"; continue; }
        if (line == ".text") { section = "text"; continue; }

        if (isDataDirective(line) && section == "text") {
            if (!prevLine.empty() && prevLine.back() == ':') {
                auto& target = inMain ? mainLines : otherTextLines;
                if (!target.empty() && target.back() == prevLine)
                    target.pop_back();
                dataLines.push_back(prevLine);
            }
            dataLines.push_back(line);
            prevLine = line;
            continue;
        }

        if (line == ".globl main") { inMain = true; prevLine = line; continue; }
        if (line == "main:") { inMain = true; mainLines.push_back(line); prevLine = line; continue; }

        if (!line.empty() && line.back() == ':' && line != "main:")
            inMain = false;

        if (section == "data")
            dataLines.push_back(line);
        else if (section == "text")
            (inMain ? mainLines : otherTextLines).push_back(line);

        prevLine = line;
    }

    m_outputLines.clear();

    if (!dataLines.empty()) {
        m_outputLines.push_back(".data");
        m_outputLines.insert(m_outputLines.end(), dataLines.begin(), dataLines.end());
        m_outputLines.emplace_back();
    }

    if (!mainLines.empty() || !otherTextLines.empty()) {
        m_outputLines.push_back(".text");
        if (!mainLines.empty()) {
            m_outputLines.push_back(".globl main");
            m_outputLines.insert(m_outputLines.end(), mainLines.begin(), mainLines.end());
            if (!otherTextLines.empty())
                m_outputLines.emplace_back();
        }
        m_outputLines.insert(m_outputLines.end(), otherTextLines.begin(), otherTextLines.end());
    }
}

} // namespace c2rars
