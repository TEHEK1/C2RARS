BISON_TARGET(RiscvParser parser.y 
             ${CMAKE_CURRENT_BINARY_DIR}/parser.tab.cpp
             DEFINES_FILE ${CMAKE_CURRENT_BINARY_DIR}/parser.tab.hpp
             COMPILE_FLAGS "-d")

add_library(parser STATIC 
    ${BISON_RiscvParser_OUTPUTS}
)

target_include_directories(parser PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_include_directories(parser PUBLIC ${CMAKE_CURRENT_BINARY_DIR})
target_include_directories(parser PUBLIC ${CMAKE_SOURCE_DIR}/include)
