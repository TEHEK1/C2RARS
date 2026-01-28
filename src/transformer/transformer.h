#ifndef TRANSFORMER_H
#define TRANSFORMER_H

#include <string>
#include <vector>
#include <map>
#include "ast.h"

namespace c2rars {

using namespace ast;

struct Section {
    std::string name;
    std::vector<std::string> lines;
};

class Transformer {
public:
    Transformer();
    ~Transformer();

    bool loadAssemblyFile(const std::string& filename);

    bool transform();

    bool transformAST(ast::Program* ast);

    bool saveOutput(const std::string& filename);

    void setVerbose(bool verbose) { m_verbose = verbose; }

private:
    void parseSections();

    void removeUnsupportedDirectivesFromAST(ast::Program* ast);

    void removeUnsupportedDirectives();

    void adaptSyntax();

    void includeLibraries();

    void replaceSyscalls();

    bool processInstruction(ast::Instruction* inst);

    void generateCodeFromAST(const ast::Program* ast);

    std::vector<std::string> m_inputLines;
    std::vector<std::string> m_outputLines;
    std::map<std::string, Section> m_sections;
    bool m_verbose;
};

} // namespace c2rars

#endif // TRANSFORMER_H
