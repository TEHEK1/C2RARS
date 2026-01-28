FLEX_TARGET(RiscvLexer lexer.l 
            ${CMAKE_CURRENT_BINARY_DIR}/lex.yy.cpp
            COMPILE_FLAGS "--c++")

add_library(lexer STATIC 
    ${FLEX_RiscvLexer_OUTPUTS}
    ${CMAKE_SOURCE_DIR}/include/scanner.h
)

target_include_directories(lexer PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_include_directories(lexer PUBLIC ${CMAKE_CURRENT_BINARY_DIR})
target_include_directories(lexer PUBLIC ${CMAKE_SOURCE_DIR}/include)
target_include_directories(lexer PUBLIC ${CMAKE_BINARY_DIR}/src/parser)

target_compile_options(lexer PRIVATE -DYY_NO_UNISTD_H)

add_dependencies(lexer parser)
