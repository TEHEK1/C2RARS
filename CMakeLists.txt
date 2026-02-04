cmake_minimum_required(VERSION 3.15)
project(c2rars VERSION 1.0.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_C_STANDARD 99)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(BISON_EXECUTABLE /opt/homebrew/opt/bison/bin/bison)
set(FLEX_EXECUTABLE /usr/bin/flex)
find_package(BISON REQUIRED)
find_package(FLEX REQUIRED)

include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src)
include_directories(${CMAKE_CURRENT_BINARY_DIR})

add_subdirectory(src/utils)
add_subdirectory(src/parser)
add_subdirectory(src/lexer)
add_subdirectory(src/transformer)
add_subdirectory(src/cli)

install(TARGETS c2rars DESTINATION bin)
install(DIRECTORY libs/ DESTINATION share/c2rars/libs)
install(FILES README.md DESTINATION share/doc/c2rars)
