cmake_minimum_required(VERSION 3.20)

set(VERBOSE TRUE)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Requires clang as the compiler
set(CMAKE_CXX_COMPILER clang++)

project("SolanaBPF" 
    VERSION "1.0"
    DESCRIPTION "PT framework"
    HOMEPAGE_URL "https://github.com/MisterSawyer/PT"
    LANGUAGES CXX)

message("SOLANA_SDK : ${SOLANA_SDK}")

add_executable("solana_program" "src/main.cpp")
target_include_directories("solana_program" PUBLIC "${SOLANA_SDK}/bin/sdk/sbf/c/inc")
target_link_libraries("solana_program" PRIVATE "libsol")