#include <iostream>
#include <string>
#include <vector>
#include <cstdlib>
#include <cstdio>
#include <fstream>
#include <memory>
#include "../transformer/transformer.h"
#include "../utils/file_utils.h"
#include "scanner.h"
#include "ast.h"
#include "parser.tab.hpp"

extern c2rars::Scanner* scanner;
extern c2rars::ast::Program* getAST();

using namespace c2rars;

struct Options {
    std::string inputFile;
    std::string outputFile;
    std::string compiler = C2RARS_CROSS_COMPILER;
    std::vector<std::string> defines;
    bool verbose = false;
};

static void printHelp() {
    std::cout <<
        "C2RARS - C to RARS assembler transformation\n"
        "Author: Kashapov A.V., BPI231\n\n"
        "Usage:\n"
        "  c2rars [options] [<file.c>]\n\n"
        "Options:\n"
        "  -i, --input <file>      Input C file (optional if <file.c> is given)\n"
        "  -o, --output <file>     Output assembly file\n"
        "  -c, --compiler <name>   Cross-compiler command (or set RISCV_GCC env var)\n"
        "  -D KEY[=VAL]            Pass a -D macro to the cross-compiler\n"
        "                          (may be repeated; -DKEY also accepted)\n"
        "  -v, --verbose           Verbose output\n"
        "  -h, --help              Show this help\n"
        "      --version           Show version\n"
        "\nNotes:\n"
        "  c2rars always defines __C2RARS__=1 for the cross-compiler.\n"
        "  Use it in your C code (e.g. in c2rars/rars_io.h) to switch between\n"
        "  the RARS ecall backend and a host-libc backend, so the same source\n"
        "  can be debugged natively with `cc prog.c -o prog && ./prog` and\n"
        "  then deployed to RARS via c2rars.\n"
        "\nExamples:\n"
        "  c2rars program.c -o program.asm\n"
        "  c2rars -i program.c -o program.asm\n"
        "  c2rars test.c -o test.asm -v\n"
        "  c2rars hello.c -c riscv64-elf-gcc -v\n"
        "  c2rars prog.c -DDEBUG=1 -DBUFSZ=128\n";
}

static void printVersion() {
    std::cout <<
        "C2RARS version 1.0.0\n"
        "Project: Transformation of programs obtained by C language\n"
        "         cross-compiler into RARS simulator assembler\n"
        "HSE University, Faculty of Computer Science, 2025-2026\n";
}

static bool parseArgs(int argc, char* argv[], Options& opts) {
    if (const char* env = std::getenv("RISCV_GCC"))
        opts.compiler = env;

    for (int i = 1; i < argc; i++) {
        std::string arg = argv[i];

        if (arg == "-h" || arg == "--help") {
            printHelp();
            std::exit(0);
        } else if (arg == "--version") {
            printVersion();
            std::exit(0);
        } else if (arg == "-v" || arg == "--verbose") {
            opts.verbose = true;
        } else if ((arg == "-i" || arg == "--input") && i + 1 < argc) {
            opts.inputFile = argv[++i];
        } else if ((arg == "-o" || arg == "--output") && i + 1 < argc) {
            opts.outputFile = argv[++i];
        } else if ((arg == "-c" || arg == "--compiler") && i + 1 < argc) {
            opts.compiler = argv[++i];
        } else if (arg == "-D" && i + 1 < argc) {
            opts.defines.push_back(argv[++i]);
        } else if (arg.size() > 2 && arg[0] == '-' && arg[1] == 'D') {
            opts.defines.push_back(arg.substr(2));
        } else if (!arg.empty() && arg[0] != '-') {
            if (!opts.inputFile.empty()) {
                std::cerr << "Error: multiple input files specified: "
                          << opts.inputFile << " and " << arg << std::endl;
                return false;
            }
            opts.inputFile = arg;
        } else {
            std::cerr << "Unknown argument: " << arg << std::endl;
            return false;
        }
    }

    if (opts.inputFile.empty()) {
        std::cerr << "Error: input file not specified" << std::endl;
        return false;
    }

    if (opts.outputFile.empty())
        opts.outputFile = utils::getBaseName(opts.inputFile) + ".asm";

    return true;
}

static bool crossCompile(const Options& opts, const std::string& tempAsmFile) {
    if (opts.verbose)
        std::cout << "Cross-compiling " << opts.inputFile << " to " << tempAsmFile << std::endl;

    std::string cmd = opts.compiler +
          " -S -march=rv32imfd -mabi=ilp32d -O0"
          " -isystem " C2RARS_INCLUDE_DIR
          " -isystem " C2RARS_SOURCE_INCLUDE_DIR
          " -D__C2RARS__=1";

    for (const auto& def : opts.defines)
        cmd += " -D" + def;

    cmd += " -o " + tempAsmFile + " " + opts.inputFile;

    if (opts.verbose)
        std::cout << "Executing: " << cmd << std::endl;

    if (std::system(cmd.c_str()) != 0) {
        std::cerr << "Compilation error" << std::endl;
        return false;
    }
    return true;
}

static bool hasExtension(const std::string& path, const std::string& ext) {
    return path.size() > ext.size() &&
           path.compare(path.size() - ext.size(), ext.size(), ext) == 0;
}

static int run(const Options& opts) {
    if (!utils::fileExists(opts.inputFile)) {
        std::cerr << "Error: file not found: " << opts.inputFile << std::endl;
        return 1;
    }

    bool isAssembly = hasExtension(opts.inputFile, ".s");
    std::string tempAsmFile = isAssembly
        ? opts.inputFile
        : utils::getBaseName(opts.inputFile) + "_temp.s";

    if (isAssembly) {
        if (opts.verbose)
            std::cout << "Input is assembly file, using directly\n" << std::endl;
    } else if (!crossCompile(opts, tempAsmFile)) {
        return 1;
    }

    auto cleanupTemp = [&]() {
        if (!isAssembly && !opts.verbose)
            std::remove(tempAsmFile.c_str());
    };

    if (opts.verbose)
        std::cout << "Parsing assembly file..." << std::endl;

    std::ifstream asmInput(tempAsmFile);
    if (!asmInput.is_open()) {
        std::cerr << "Error: failed to open " << tempAsmFile << " for parsing" << std::endl;
        return 1;
    }

    auto scannerPtr = std::make_unique<Scanner>(&asmInput);
    scanner = scannerPtr.get();

    yy::parser parser;
    if (parser.parse() != 0) {
        std::cerr << "Error: parsing failed" << std::endl;
        scanner = nullptr;
        cleanupTemp();
        return 1;
    }
    scanner = nullptr;

    ast::Program* ast = getAST();
    if (!ast) {
        std::cerr << "Error: AST is empty" << std::endl;
        cleanupTemp();
        return 1;
    }

    if (opts.verbose) {
        std::cout << "AST constructed successfully" << std::endl;
        std::cout << "Transforming for RARS..." << std::endl;
    }

    Transformer transformer;
    transformer.setVerbose(opts.verbose);

    if (!transformer.transformAST(ast)) {
        std::cerr << "Transformation error" << std::endl;
        cleanupTemp();
        return 1;
    }

    if (!transformer.saveOutput(opts.outputFile)) {
        std::cerr << "Error saving output" << std::endl;
        cleanupTemp();
        return 1;
    }

    cleanupTemp();
    std::cout << "Transformation completed successfully!\n"
              << "Output saved to: " << opts.outputFile << std::endl;
    return 0;
}

int main(int argc, char* argv[]) {
    Options opts;
    if (!parseArgs(argc, argv, opts)) {
        printHelp();
        return 1;
    }

    if (opts.verbose) {
        printVersion();
        std::cout << "\nParameters:\n"
                  << "  Input file:  " << opts.inputFile << "\n"
                  << "  Output file: " << opts.outputFile << "\n"
                  << "  Compiler:    " << opts.compiler << "\n\n";
    }

    return run(opts);
}
