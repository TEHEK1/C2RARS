add_library(transformer STATIC
    transformer.cpp
    transformer.h
)

target_include_directories(transformer PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_include_directories(transformer PUBLIC ${CMAKE_SOURCE_DIR}/include)
target_link_libraries(transformer PUBLIC parser)
