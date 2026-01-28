add_executable(c2rars main.cpp)

target_include_directories(c2rars PRIVATE 
    ${CMAKE_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/../parser
    ${CMAKE_BINARY_DIR}/src/parser
)

target_link_libraries(c2rars 
    PRIVATE
    transformer
    parser
    lexer
    utils
)

install(TARGETS c2rars DESTINATION bin)
