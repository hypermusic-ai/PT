set(MODULE_ALIAS "native")
set(MODULE_NAME "pt-${MODULE_ALIAS}")
message(STATUS "Configuring pt::${MODULE_ALIAS} module")

add_library("${MODULE_NAME}" OBJECT "include/native.hpp")
add_library("pt::${MODULE_ALIAS}" ALIAS "${MODULE_NAME}")

target_include_directories("${MODULE_NAME}" 
PUBLIC 
    "include"
)

target_sources("${MODULE_NAME}" 
PRIVATE
    "src/native.cpp"
)

set(PUBLIC_HEADERS_LIST
    "include/native.hpp"
)

# windows specyfic linking
if (WIN32)
    message(STATUS "Configuring pt::${MODULE_ALIAS} module for Windows")
    list(APPEND PUBLIC_HEADERS_LIST
        "include/windows-native.hpp"
    )

    target_sources("${MODULE_NAME}" 
    PRIVATE
        "src/windows-native.cpp"
    )

    target_link_libraries("${MODULE_NAME}" PUBLIC 
        ws2_32
    )

endif (WIN32)

set_property(TARGET "${MODULE_NAME}" PROPERTY CXX_STANDARD 23)
set_target_properties("${MODULE_NAME}" PROPERTIES PUBLIC_HEADER "${PUBLIC_HEADERS_LIST}")
set_target_properties("${MODULE_NAME}" PROPERTIES DEBUG_POSTFIX "_D")

install(TARGETS "${MODULE_NAME}" EXPORT "${MODULE_NAME}Targets"
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"                                                   # bin
    LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"                                                   # lib
    ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"                                                   # lib
    PUBLIC_HEADER DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/${GLOBAL_NAMESPACE}"                     # INCLUDE_DIR/GLOBAL_NAMESPACE
    INCLUDES DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"                                              # INCLUDE_DIR
)
