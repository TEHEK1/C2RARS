#ifndef TRANSFORMER_H
#define TRANSFORMER_H

#include <string>
#include <vector>
#include "ast.h"

namespace c2rars {

class Transformer {
public:
    Transformer() = default;
    ~Transformer() = default;

    bool transformAST(ast::Program* ast);
    bool saveOutput(const std::string& filename);

    void setVerbose(bool verbose) { m_verbose = verbose; }

private:
    static constexpr int REG_A0 = 10;
    static constexpr int REG_A7 = 17;

    static constexpr int RARS_PRINT_INT       = 1;
    static constexpr int RARS_PRINT_STRING    = 4;
    static constexpr int RARS_READ_INT        = 5;
    static constexpr int RARS_READ_STRING     = 8;
    static constexpr int RARS_EXIT            = 10;
    static constexpr int RARS_PRINT_CHAR      = 11;
    static constexpr int RARS_READ_CHAR       = 12;
    static constexpr int RARS_EXIT2           = 17;

    static constexpr int LINUX_EXIT           = 93;
    static constexpr int LINUX_EXIT_GROUP     = 94;

    void removeUnsupportedDirectives(ast::Program* ast);
    void foldLuiAddiPairs(ast::Program* ast);
    void replaceMainReturn(ast::Program* ast);
    bool processInstruction(ast::Instruction* inst, bool& needsEcall);

    void generateCodeFromAST(const ast::Program* ast);
    std::string serializeNode(const ast::ASTNode* node) const;
    void reorganizeSections();

    std::vector<std::string> m_outputLines;
    bool m_verbose = false;
};

} // namespace c2rars

#endif // TRANSFORMER_H
