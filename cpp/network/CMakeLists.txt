set(MODULE_ALIAS "network")
set(MODULE_NAME "pt-${MODULE_ALIAS}")

message(STATUS "Configuring pt::${MODULE_ALIAS} module")

add_library("${MODULE_NAME}" OBJECT "include/network.hpp")
add_library("pt::${MODULE_ALIAS}" ALIAS "${MODULE_NAME}")

target_include_directories("${MODULE_NAME}" 
PUBLIC 
    "${INCLUDE_DIR}"
    "include"
    "${asio_SOURCE_DIR}/asio/include"
)

target_sources("${MODULE_NAME}" 
PRIVATE
    "src/server.cpp"
    "src/tcp.cpp"
)

set(PUBLIC_HEADERS_LIST
    "include/network.hpp"
    "include/server.hpp"
    "include/tcp.hpp"
)

target_link_libraries("${MODULE_NAME}" PUBLIC
    pt::native
)

set_property(TARGET "${MODULE_NAME}" PROPERTY CXX_STANDARD 23)
set_target_properties("${MODULE_NAME}" PROPERTIES PUBLIC_HEADER "${PUBLIC_HEADERS_LIST}")
set_target_properties("${MODULE_NAME}" PROPERTIES DEBUG_POSTFIX "_D")

install(TARGETS "${MODULE_NAME}"
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"                                                   # bin
    LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"                                                   # lib
    ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"                                                   # lib
    PUBLIC_HEADER DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/${GLOBAL_NAMESPACE}"                     # INCLUDE_DIR/GLOBAL_NAMESPACE
    INCLUDES DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"                                              # INCLUDE_DIR
)

