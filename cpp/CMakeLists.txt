cmake_minimum_required(VERSION 3.20)

include("deps.cmake")

set(CMAKE_C_COMPILER "gcc")
set(CMAKE_CXX_COMPILER "g++")

set(PROJECT_NAME "PT_node")
set(GLOBAL_NAMESPACE "PT")
set(INSTALL_DIR "install")
set(INCLUDE_DIR "include")
set(SRC_DIR "src")

# --------------------------------------------
# PT project
# --------------------------------------------
project("${PROJECT_NAME}"         
            VERSION "1.0"
            DESCRIPTION "PT framework"
            HOMEPAGE_URL "https://github.com/MisterSawyer/PT"
            LANGUAGES CXX
)

message(STATUS "[${PROJECT_NAME}] initializing project ...")

# --------------------------------------------
# dependencies
# --------------------------------------------

#message(STATUS "[${PROJECT_NAME}] initializing `OpenSSL` dependency...")
#find_package(OpenSSL REQUIRED)

message(STATUS "[${PROJECT_NAME}] initializing `asio` dependency...")
FetchContent_MakeAvailable(asio)

# --------------------------------------------
# library target
# --------------------------------------------
add_library("${PROJECT_NAME}" STATIC "${INCLUDE_DIR}/PT.hpp")
set(PUBLIC_HEADERS_LIST
    "${INCLUDE_DIR}/PT.hpp"
    "${INCLUDE_DIR}/index.hpp"
    "${INCLUDE_DIR}/registry.hpp"
    "${INCLUDE_DIR}/concept-fwd.hpp"
    "${INCLUDE_DIR}/concept.hpp"
    "${INCLUDE_DIR}/operand-fwd.hpp"
    "${INCLUDE_DIR}/operand.hpp"
)
target_sources("${PROJECT_NAME}" PRIVATE 
    "${SRC_DIR}/PT.cpp"
    "${SRC_DIR}/registry.cpp"
    "${SRC_DIR}/operand.cpp"
    "${SRC_DIR}/concept.cpp"
)
target_include_directories("${PROJECT_NAME}" PUBLIC 
    "${INCLUDE_DIR}" 
    "${asio_SOURCE_DIR}/asio/include"
)

target_link_options("${PROJECT_NAME}" PUBLIC 
    -static-libgcc
    -static-libstdc++
)

target_link_libraries("${PROJECT_NAME}" PUBLIC 
    #OpenSSL::SSL
    #OpenSSL::Crypto
)

# windows specyfic linking
if (WIN32)
    target_link_libraries("${PROJECT_NAME}" PUBLIC 
        ws2_32
    )
endif (WIN32)

set_property(TARGET "${PROJECT_NAME}" PROPERTY CXX_STANDARD 23)
set_target_properties("${PROJECT_NAME}" PROPERTIES PUBLIC_HEADER "${PUBLIC_HEADERS_LIST}")
set_target_properties("${PROJECT_NAME}" PROPERTIES DEBUG_POSTFIX "_D")


# --------------------------------------------
# executable target
# --------------------------------------------
message(STATUS "Configuring executable")
add_executable("${PROJECT_NAME}_exe" "${SRC_DIR}/main.cpp")

set_property(TARGET "${PROJECT_NAME}_exe" PROPERTY CXX_STANDARD 23)
set_target_properties("${PROJECT_NAME}_exe" PROPERTIES PUBLIC_HEADER "${PUBLIC_HEADERS_LIST}")
set_target_properties("${PROJECT_NAME}_exe" PROPERTIES DEBUG_POSTFIX "_D")

target_link_libraries("${PROJECT_NAME}_exe" PRIVATE "${PROJECT_NAME}")

# --------------------------------------------
# install target
# --------------------------------------------
if(DEFINED CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    message(
        STATUS
        "[${PROJECT_NAME}] "
        "CMAKE_INSTALL_PREFIX is not set\n\t"
        "Default value: ${CMAKE_INSTALL_PREFIX}\n\t"
        "Will set it to ${CMAKE_SOURCE_DIR}/${INSTALL_DIR}"
    )
    set(CMAKE_INSTALL_PREFIX
        "${CMAKE_SOURCE_DIR}/${INSTALL_DIR}"
        CACHE PATH "Where the library will be installed to" FORCE
    )
else()
    message(
        STATUS
        "[${PROJECT_NAME}] "
        "CMAKE_INSTALL_PREFIX was already set\n\t"
        "Current value: ${CMAKE_INSTALL_PREFIX}"
    )
endif()

if(NOT DEFINED CMAKE_INSTALL_INCLUDEDIR)
    set(CMAKE_INSTALL_INCLUDEDIR "${INCLUDE_DIR}" CACHE PATH "C header files (include)")
endif()

install(TARGETS "${PROJECT_NAME}" EXPORT "${PROJECT_NAME}Targets"
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"                                   # bin
    LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"                                   # lib
    ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"                                   # lib
    PUBLIC_HEADER DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/${GLOBAL_NAMESPACE}"     # INCLUDE_DIR/GLOBAL_NAMESPACE
    INCLUDES DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"                              # INCLUDE_DIR
)

# --------------------------------------------
# tests
# --------------------------------------------
if(BUILD_TESTING)
    message(STATUS "[${PROJECT_NAME}] initializing `googletest` dependency...")
    FetchContent_MakeAvailable(googletest)
    message(STATUS "Configuring unit tests")
    add_subdirectory(tests)
    set_property(TARGET "unit-tests" PROPERTY CXX_STANDARD 23)
endif()
