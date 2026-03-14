add_executable(c2rars main.cpp)

target_include_directories(c2rars PRIVATE 
    ${CMAKE_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/../parser
    ${CMAKE_BINARY_DIR}/src/parser
)

if(NOT C2RARS_CROSS_COMPILER)
    find_program(C2RARS_CROSS_COMPILER
        NAMES riscv64-unknown-elf-gcc riscv64-elf-gcc
    )
    if(NOT C2RARS_CROSS_COMPILER)
        set(C2RARS_CROSS_COMPILER "riscv64-unknown-elf-gcc")
        message(WARNING "RISC-V cross-compiler not found, using default: ${C2RARS_CROSS_COMPILER}")
    endif()
endif()
message(STATUS "RISC-V cross-compiler: ${C2RARS_CROSS_COMPILER}")

target_compile_definitions(c2rars PRIVATE
    C2RARS_INCLUDE_DIR="${CMAKE_INSTALL_PREFIX}/include"
    C2RARS_SOURCE_INCLUDE_DIR="${CMAKE_SOURCE_DIR}/include"
    C2RARS_CROSS_COMPILER="${C2RARS_CROSS_COMPILER}"
)

target_link_libraries(c2rars 
    PRIVATE
    transformer
    parser
    lexer
    utils
)

install(TARGETS c2rars DESTINATION bin)
