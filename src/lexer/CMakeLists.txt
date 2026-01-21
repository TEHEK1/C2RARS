FLEX_TARGET(RiscvLexer lexer.l 
            ${CMAKE_CURRENT_BINARY_DIR}/lex.yy.cpp
            COMPILE_FLAGS "--c++")

add_library(lexer STATIC ${FLEX_RiscvLexer_OUTPUTS})
target_include_directories(lexer PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_include_directories(lexer PUBLIC ${CMAKE_CURRENT_BINARY_DIR})
target_include_directories(lexer PUBLIC ${CMAKE_SOURCE_DIR}/include)
