#include <iostream>
#include <string>
#include <cstdlib>
#include <fstream>
#include "../transformer/transformer.h"
#include "../utils/file_utils.h"
#include "scanner.h"
#include "ast.h"
#include "parser.tab.hpp"

extern c2rars::Scanner* scanner;
extern c2rars::ast::Program* getAST();

using namespace c2rars;

void printHelp() {
    std::cout << "C2RARS - C to RARS assembler transformation\n";
    std::cout << "Author: Kashapov A.V., BPI231\n\n";
    std::cout << "Usage:\n";
    std::cout << "  c2rars [options]\n\n";
    std::cout << "Options:\n";
    std::cout << "  -i, --input <file>      Input C file\n";
    std::cout << "  -o, --output <file>     Output assembly file\n";
    std::cout << "  -c, --compiler <name>   Compiler (gcc/clang), default is gcc\n";
    std::cout << "  -v, --verbose           Verbose output\n";
    std::cout << "  -h, --help              Show this help\n";
    std::cout << "      --version           Show version\n";
    std::cout << "\nExamples:\n";
    std::cout << "  c2rars -i program.c -o program.asm\n";
    std::cout << "  c2rars -i test.c -o test.asm -v\n";
    std::cout << "  c2rars --input hello.c --compiler clang --verbose\n";
}

void printVersion() {
    std::cout << "C2RARS version 1.0.0\n";
    std::cout << "Project: Transformation of programs obtained by C language\n";
    std::cout << "         cross-compiler into RARS simulator assembler\n";
    std::cout << "HSE University, Faculty of Computer Science, 2025-2026\n";
}

bool compileToAssembly(const std::string& inputFile, const std::string& tempAsmFile,
                       const std::string& compiler, bool verbose) {
    if (verbose) {
        std::cout << "Cross-compiling " << inputFile << " to " << tempAsmFile << std::endl;
    }

    std::string cmd;
    if (compiler == "gcc") {
        cmd = "riscv64-unknown-elf-gcc -S -march=rv32i -mabi=ilp32 -O0 -o " 
              + tempAsmFile + " " + inputFile;
    } else {
        std::cerr << "Unknown compiler: " << compiler << std::endl;
        return false;
    }

    if (verbose) {
        std::cout << "Executing: " << cmd << std::endl;
    }

    int result = system(cmd.c_str());
    if (result != 0) {
        std::cerr << "Compilation error" << std::endl;
        return false;
    }

    return true;
}

int main(int argc, char* argv[]) {
    std::string inputFile;
    std::string outputFile;
    std::string compiler = "gcc";
    bool verbose = false;

    for (int i = 1; i < argc; i++) {
        std::string arg = argv[i];
        
        if (arg == "-h" || arg == "--help") {
            printHelp();
            return 0;
        } else if (arg == "--version") {
            printVersion();
            return 0;
        } else if (arg == "-v" || arg == "--verbose") {
            verbose = true;
        } else if ((arg == "-i" || arg == "--input") && i + 1 < argc) {
            inputFile = argv[++i];
        } else if ((arg == "-o" || arg == "--output") && i + 1 < argc) {
            outputFile = argv[++i];
        } else if ((arg == "-c" || arg == "--compiler") && i + 1 < argc) {
            compiler = argv[++i];
        } else {
            std::cerr << "Unknown argument: " << arg << std::endl;
            printHelp();
            return 1;
        }
    }

    if (inputFile.empty()) {
        std::cerr << "Error: input file not specified" << std::endl;
        printHelp();
        return 1;
    }

    if (outputFile.empty()) {
        outputFile = utils::getBaseName(inputFile) + ".asm";
    }

    if (verbose) {
        printVersion();
        std::cout << "\nParameters:\n";
        std::cout << "  Input file:  " << inputFile << "\n";
        std::cout << "  Output file: " << outputFile << "\n";
        std::cout << "  Compiler:    " << compiler << "\n\n";
    }

    if (!utils::fileExists(inputFile)) {
        std::cerr << "Error: file not found: " << inputFile << std::endl;
        return 1;
    }

    std::string tempAsmFile = utils::getBaseName(inputFile) + "_temp.s";

    if (!compileToAssembly(inputFile, tempAsmFile, compiler, verbose)) {
        return 1;
    }

    if (verbose) {
        std::cout << "Parsing assembly file..." << std::endl;
    }

    std::ifstream asmInput(tempAsmFile);
    if (!asmInput.is_open()) {
        std::cerr << "Error: failed to open " << tempAsmFile << " for parsing" << std::endl;
        return 1;
    }

    scanner = new Scanner(&asmInput);
    yy::parser parser;
    
    if (parser.parse() != 0) {
        std::cerr << "Error: parsing failed" << std::endl;
        delete scanner;
        return 1;
    }

    delete scanner;
    scanner = nullptr;

    ast::Program* ast = getAST();
    if (!ast) {
        std::cerr << "Error: AST is empty" << std::endl;
        return 1;
    }

    if (verbose) {
        std::cout << "AST constructed successfully" << std::endl;
        std::cout << "Transforming for RARS..." << std::endl;
    }

    Transformer transformer;
    transformer.setVerbose(verbose);

    if (!transformer.transformAST(ast)) {
        std::cerr << "Transformation error" << std::endl;
        return 1;
    }

    if (!transformer.saveOutput(outputFile)) {
        std::cerr << "Error saving output" << std::endl;
        return 1;
    }

    if (!verbose) {
        remove(tempAsmFile.c_str());
    }

    std::cout << "Transformation completed successfully!\n";
    std::cout << "Output saved to: " << outputFile << std::endl;

    return 0;
}
