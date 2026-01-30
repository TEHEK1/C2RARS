#include "transformer.h"
#include "ast.h"
#include <fstream>
#include <iostream>
#include <sstream>
#include <algorithm>

namespace c2rars {

using namespace c2rars::ast;

Transformer::Transformer() : m_verbose(false) {
}

Transformer::~Transformer() {
}

bool Transformer::loadAssemblyFile(const std::string& filename) {
    if (m_verbose) {
        std::cout << "Loading file: " << filename << std::endl;
    }

    std::ifstream file(filename);
    if (!file.is_open()) {
        std::cerr << "Error: failed to open file " << filename << std::endl;
        return false;
    }

    std::string line;
    while (std::getline(file, line)) {
        m_inputLines.push_back(line);
    }

    file.close();

    if (m_verbose) {
        std::cout << "Loaded lines: " << m_inputLines.size() << std::endl;
    }

    return true;
}

bool Transformer::transform() {
    if (m_verbose) {
        std::cout << "Starting transformation..." << std::endl;
    }

    parseSections();
    removeUnsupportedDirectives();
    adaptSyntax();
    replaceSyscalls();
    includeLibraries();

    if (m_verbose) {
        std::cout << "Transformation completed successfully" << std::endl;
    }

    return true;
}

bool Transformer::saveOutput(const std::string& filename) {
    if (m_verbose) {
        std::cout << "Saving output to: " << filename << std::endl;
    }

    std::ofstream file(filename);
    if (!file.is_open()) {
        std::cerr << "Error: failed to create file " << filename << std::endl;
        return false;
    }

    for (const auto& line : m_outputLines) {
        file << line << "\n";
    }

    file.close();

    if (m_verbose) {
        std::cout << "Output saved" << std::endl;
    }

    return true;
}

void Transformer::parseSections() {
    if (m_verbose) {
        std::cout << "Parsing sections..." << std::endl;
    }

    std::string currentSection;
    
    for (const auto& line : m_inputLines) {
        std::string trimmed = line;
        trimmed.erase(0, trimmed.find_first_not_of(" \t"));
        trimmed.erase(trimmed.find_last_not_of(" \t") + 1);

        if (trimmed.empty()) {
            continue;
        }

        if (trimmed.find(".text") == 0) {
            currentSection = ".text";
        } else if (trimmed.find(".data") == 0) {
            currentSection = ".data";
        } else if (trimmed.find(".bss") == 0) {
            currentSection = ".bss";
        }

        if (!currentSection.empty()) {
            m_sections[currentSection].name = currentSection;
            m_sections[currentSection].lines.push_back(line);
        }
    }

    if (m_verbose) {
        std::cout << "Found sections: " << m_sections.size() << std::endl;
    }
}

void Transformer::removeUnsupportedDirectives() {
    if (m_verbose) {
        std::cout << "Removing unsupported directives..." << std::endl;
    }

    std::vector<std::string> unsupportedDirectives = {
        ".file",
        ".option",
        ".attribute",
        ".ident",
        ".type",
        ".size"
    };

    m_outputLines.clear();
    
    for (const auto& line : m_inputLines) {
        bool shouldRemove = false;
        
        for (const auto& directive : unsupportedDirectives) {
            if (line.find(directive) != std::string::npos) {
                shouldRemove = true;
                if (m_verbose) {
                    std::cout << "  Removed directive: " << directive << std::endl;
                }
                break;
            }
        }
        
        if (!shouldRemove) {
            m_outputLines.push_back(line);
        }
    }
}

void Transformer::adaptSyntax() {
    if (m_verbose) {
        std::cout << "Adapting syntax..." << std::endl;
    }
}

void Transformer::replaceSyscalls() {
    if (m_verbose) {
        std::cout << "Replacing syscalls..." << std::endl;
    }

    std::vector<std::string> newLines;
    
    for (auto& line : m_outputLines) {
        if (line.find("li a7, 93") != std::string::npos) {
            newLines.push_back("\tli a7, 10\t# RARS exit");
        } else {
            newLines.push_back(line);
        }
    }
    
    m_outputLines = newLines;
}

void Transformer::includeLibraries() {
    if (m_verbose) {
        std::cout << "Including RARS libraries..." << std::endl;
    }

    std::vector<std::string> header;
    
    m_outputLines.insert(m_outputLines.begin(), header.begin(), header.end());
}

bool Transformer::transformAST(ast::Program* ast) {
    if (!ast) {
        std::cerr << "Error: AST is empty" << std::endl;
        return false;
    }
    
    if (m_verbose) {
        std::cout << "Transforming AST..." << std::endl;
    }
    
    removeUnsupportedDirectivesFromAST(ast);
    
    std::string currentFunction;
    for (size_t i = 0; i < ast->statements.size(); i++) {
        auto& stmt = ast->statements[i];
        
        if (auto* lbl = dynamic_cast<Label*>(stmt.get())) {
            currentFunction = lbl->name;
        }
        
        if (auto* inst = dynamic_cast<Instruction*>(stmt.get())) {
            processInstruction(inst);
            
            if (currentFunction == "main" && 
                (inst->opcode == Instruction::RET || inst->opcode == Instruction::JR)) {
                if (m_verbose) {
                    std::cout << "  Replacing " << inst->opcodeToString() 
                              << " in main() with exit syscall" << std::endl;
                }
                
                // Replace ret with: li a7, 10; ecall
                inst->opcode = Instruction::LI;
                inst->operands.clear();
                inst->addRegister(17);
                inst->addImmediate(10);
                
                auto ecall = std::make_unique<Instruction>(Instruction::ECALL);
                ast->statements.insert(ast->statements.begin() + i + 1, std::move(ecall));
                i++;
            }
        }
    }
    
    generateCodeFromAST(ast);
    
    if (m_verbose) {
        std::cout << "AST transformation completed" << std::endl;
    }
    
    return true;
}

void Transformer::removeUnsupportedDirectivesFromAST(ast::Program* ast) {
    if (m_verbose) {
        std::cout << "Removing unsupported directives from AST..." << std::endl;
    }
    
    const std::vector<Directive::Type> unsupported = {
        Directive::SECTION,
        Directive::ALIGN
    };
    
    size_t removedCount = 0;
    ast->statements.erase(
        std::remove_if(ast->statements.begin(), ast->statements.end(),
            [&unsupported, &removedCount, this](const std::unique_ptr<ASTNode>& stmt) {
                if (auto* dir = dynamic_cast<Directive*>(stmt.get())) {
                    for (auto type : unsupported) {
                        if (dir->type == type) {
                            removedCount++;
                            if (m_verbose) {
                                std::cout << "  Removed directive: " << dir->typeToString() << std::endl;
                            }
                            return true;
                        }
                    }
                }
                return false;
            }),
        ast->statements.end()
    );
    
    if (m_verbose && removedCount > 0) {
        std::cout << "  Total removed: " << removedCount << " directives" << std::endl;
    }
}

bool Transformer::processInstruction(ast::Instruction* inst) {
    if (!inst) return false;
    
    bool modified = false;
    
    if (inst->opcode == Instruction::CALL && inst->getOperandCount() > 0) {
        if (auto* label = dynamic_cast<LabelOperand*>(inst->getOperand(0))) {
            const std::string& funcName = label->getName();
            
            if (funcName == "printf" || funcName == "puts") {
                if (m_verbose) {
                    std::cout << "  Replacing call " << funcName << " with RARS print_string syscall" << std::endl;
                }
                inst->opcode = Instruction::LI;
                inst->operands.clear();
                inst->addRegister(17);
                inst->addImmediate(4);
                modified = true;
            }
            else if (funcName == "exit") {
                if (m_verbose) {
                    std::cout << "  Replacing call exit with RARS exit syscall" << std::endl;
                }
                inst->opcode = Instruction::LI;
                inst->operands.clear();
                inst->addRegister(17);
                inst->addImmediate(10);
                modified = true;
            }
        }
    }
    
    if (inst->opcode == Instruction::LI && inst->getOperandCount() >= 2) {
        if (auto* reg = dynamic_cast<Register*>(inst->getOperand(0))) {
            if (reg->getNumber() == 17) {
                if (auto* imm = dynamic_cast<Immediate*>(inst->getOperand(1))) {
                    int syscallNum = imm->getValue();
                    if (syscallNum == 93 || syscallNum == 94) {
                        if (m_verbose) {
                            std::cout << "  Replacing Linux syscall " << syscallNum << " with RARS exit (10)" << std::endl;
                        }
                        inst->operands[1] = std::make_unique<Immediate>(10);
                        modified = true;
                    }
                }
            }
        }
    }
    
    return modified;
}

void Transformer::generateCodeFromAST(const ast::Program* ast) {
    if (m_verbose) {
        std::cout << "Generating assembly code from AST..." << std::endl;
    }
    
    m_outputLines.clear();
    
    std::string currentSection;
    
    for (const auto& stmt : ast->statements) {
        std::stringstream ss;
        
        if (auto* dir = dynamic_cast<Directive*>(stmt.get())) {
            std::string dirStr = dir->typeToString();
            
            if (dir->type == Directive::TEXT || dir->type == Directive::DATA || dir->type == Directive::BSS) {
                if (dirStr != currentSection) {
                    if (!currentSection.empty()) {
                        m_outputLines.push_back("");
                    }
                    currentSection = dirStr;
                }
            }
            
            ss << dirStr;
            if (!dir->argument.empty()) {
                ss << " " << dir->argument;
            }
            if (dir->numericArg != 0) {
                ss << " " << dir->numericArg;
            }
            m_outputLines.push_back(ss.str());
        }
        else if (auto* lbl = dynamic_cast<Label*>(stmt.get())) {
            m_outputLines.push_back(lbl->name + ":");
        }
        else if (auto* inst = dynamic_cast<Instruction*>(stmt.get())) {
            ss << "\t" << inst->opcodeToString();
            
            bool isMemoryAccess = (inst->opcode == Instruction::LW || 
                                   inst->opcode == Instruction::LB ||
                                   inst->opcode == Instruction::SW || 
                                   inst->opcode == Instruction::SB);
            
            if (isMemoryAccess && inst->getOperandCount() == 3) {
                auto* op0 = inst->getOperand(0);
                auto* op1 = inst->getOperand(1);
                auto* op2 = inst->getOperand(2);
                
                ss << " ";
                if (auto* reg = dynamic_cast<Register*>(op0)) {
                    ss << "x" << reg->getNumber();
                }
                
                ss << ", ";
                if (auto* imm = dynamic_cast<Immediate*>(op1)) {
                    ss << imm->getValue();
                }
                
                ss << "(";
                if (auto* reg = dynamic_cast<Register*>(op2)) {
                    ss << "x" << reg->getNumber();
                }
                ss << ")";
            }
            else {
                for (size_t i = 0; i < inst->getOperandCount(); i++) {
                    if (i == 0) ss << " ";
                    else ss << ", ";
                    
                    auto* op = inst->getOperand(i);
                    
                    if (auto* reg = dynamic_cast<Register*>(op)) {
                        ss << "x" << reg->getNumber();
                    }
                    else if (auto* imm = dynamic_cast<Immediate*>(op)) {
                        ss << imm->getValue();
                    }
                else if (auto* label = dynamic_cast<LabelOperand*>(op)) {
                    ss << label->getName();
                }
                }
            }
            
            m_outputLines.push_back(ss.str());
        }
    }
    
    if (m_verbose) {
        std::cout << "Generated lines: " << m_outputLines.size() << std::endl;
    }
}

} // namespace c2rars
