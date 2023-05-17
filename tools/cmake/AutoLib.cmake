# Sourced from https://github.com/vector-of-bool/pitchfork/blob/develop/extras/pf-cmake/auto.cmake

include_guard(GLOBAL)

include(CMakePackageConfigHelpers)

# Auto create library
function(_auto_lib)
    set(options
        NO_INSTALL
    )
    set(args
        LIBRARY_NAME
        ALIAS
        OUTPUT_NAME
        VERSION_COMPATIBILITY
    )
    set(list_args
        LINK
        PRIVATE_LINK
    )
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${options}" "${args}" "${list_args}")

    # Unparsed args
    foreach(arg IN LISTS ARG_UNPARSED_ARGUMENTS)
        message(WARNING "Uknown argument to auto_lib: ${arg}")
    endforeach()

    # Fail if no project
    if(NOT DEFINED PROJECT_NAME)
        message(FATAL_ERROR "project() must be called before auto_lib()!")
    endif()
    
    # Default args
    if(NOT DEFINED ARG_LIBRARY_NAME)
        set(ARG_LIBRARY_NAME "${PROJECT_NAME}")
    endif()

    if(NOT DEFINED ARG_ALIAS)
        set(ARG_ALIAS "${PROJECT_NAME}::${ARG_LIBRARY_NAME}")
    endif()
    if(NOT ARG_ALIAS MATCHES "::")
        # Ensure correct alias formatting
        message(SEND_ERROR "auto_lib(ALIAS) must contain a double-colon '::'.")
    endif()

    if(NOT DEFINED ARG_VERSION_COMPATIBILITY)
        set(ARG_VERSION_COMPATIBILITY ExactVersion)
    endif()

    # Src dir
    set(src_dir "${PROJECT_SOURCE_DIR}/src")
    if(NOT IS_DIRECTORY "${src_dir}")
        message(FATAL_ERROR "Could not find src directory!")
    endif()

    # Set output directories
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/bin")
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/lib")
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/lib")

    # Bool for if this is the root project
    get_directory_property(pr_pardir "${PROJECT_SOURCE_DIR}" DIRECTORY)
    set(is_root_project TRUE)
    if(pr_pardir)
        set(is_root_project FALSE)
    endif()

    # Check if install is needed
    set(do_install FALSE)
    if(is_root_project AND NOT ARG_NO_INSTALL)
        set(do_install TRUE)
    endif()

    # Detect target architecture
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(arch x64)
    else()
        set(arch x86)
    endif()
    set(install_infix "lib/${PROJECT_NAME}-${PROJECT_VERSION}-${arch}")
    set(install_target_common
        EXPORT "${PROJECT_NAME}Targets"
        RUNTIME DESTINATION "${install_infix}/bin"
        LIBRARY DESTINATION "${install_infix}/lib"
        ARCHIVE DESTINATION "${install_infix}/lib"
        OBJECTS DESTINATION "${install_infix}/lib"
        INCLUDES DESTINATION "${install_infix}/include"
    )

    # Find public include directory (Publically accessible headers)
    set(pub_inc_dir "${PROJECT_SOURCE_DIR}/include")
    if(NOT IS_DIRECTORY "${pub_inc_dir}")
        set(pub_inc_dir "${PROJECT_SOURCE_DIR}/src") # Default to src directory if there is no include dir
    endif()
    set(priv_inc_dir "${src_dir}")

    # Glob search src dir
    file(GLOB_RECURSE
        sources
        RELATIVE "${src_dir}"
        CONFIGURE_DEPENDS
        "${src_dir}/*"
    )

    set(exe_sources)
    set(lib_sources)

    # find all sources
    foreach(file IN LISTS sources)
        get_filename_component(fname "${file}" NAME)
        
        if(fname STREQUAL file)
            # File is not in a subdirectory, therefore is an executable
            list(APPEND exe_sources "src/${file}")
        else()
            # Otherwise, is library src file
            list(APPEND lib_sources "src/${file}")
        endif()
    endforeach()

    # Add headers for library sources
    if(NOT pub_inc_dir STREQUAL priv_inc_dir)
        file(GLOB_RECURSE includes "${pub_inc_dir}/*")
        list(APPEND lib_sources ${includes})
    endif()

    # Pull in external sources if they exist
    get_filename_component(external_dir "${PROJECT_SOURCE_DIR}/external" ABSOLUTE)
    if(EXISTS "${external_dir}/CMakeLists.txt")
        add_subdirectory("${exteranl_dir}")
    endif()

    foreach(link IN LISTS ARG_LINK ARG_PRIVATE_LINK)
        if(NOT TARGET "${link}")
            message(SEND_ERROR "Requested to link non-target: ${link}")
        endif()
    endforeach()
    

    # Define libary
    add_library("${ARG_LIBRARY_NAME}" ${lib_sources})
    target_include_directories("${ARG_LIBRARY_NAME}" PUBLIC "$<BUILD_INTERFACE:${pub_inc_dir}>")
    if(NOT pub_inc_dir STREQUAL priv_inc_dir)
        target_include_directories("${ARG_LIBRARY_NAME}" PRIVATE "${priv_inc_dir}")
    endif()

    # Link libraries
    target_link_libraries("${ARG_LIBRARY_NAME}" PUBLIC ${ARG_LINK})
    foreach(priv IN LISTS ARG_PRIVATE_LINK)
        target_link_libraries("${ARG_LIBRARY_NAME}" PRIVATE $<BUILD_INTERFACE:${priv}>)        
    endforeach()

    # Add alias target (Name used to reference library)
    add_library("${ARG_ALIAS}" ALIAS "${ARG_LIBRARY_NAME}")
    set_property(TARGET "${ARG_LIBRARY_NAME}" PROPERTY EXPORT_NAME "${ARG_ALIAS}")

    # Optional change output name
    if(DEFINED ARG_OUTPUT_NAME)
        set_property(TARGET "${ARG_LIBRARY_NAME}" PROPERTY OUTPUT_NAME "${ARG_OUTPUT_NAME}")
    endif()

    # Optional install
    if(do_install)
        install(TARGETS "${ARG_LIBRARY_NAME}" ${install_target_common})
        install(
            DIRECTORY "${pub_inc_dir}"
            DESTINATION "${install_infix}/include"
            FILES_MATCHING
                PATTERN *.h
                PATTERN *.hpp
                PATTERN *.hh
                PATTERN *.h++
                PATTERN *.hxx
                PATTERN *.H
        )
    endif()

    # Add executables here

    # Already included subdirectories
    get_directory_property(already_subdirs SUBDIRECTORIES)

    # Tests
    get_filename_component(tests_dir "${PROJECT_SOURCE_DIR}/tests" ABSOLUTE)
    option(BUILD_TESTING "Build the testing tree" ON)
    #set(_PF_ADDED_TESTS FALSE PARENT_SCOPE)
    if(EXISTS "${tests_dir}/CMakeLists.txt" AND BUILD_TESTING AND is_root_project AND NOT tests_dir IN_LIST already_subdirs)
        add_subdirectory("${tests_dir}")
        #set(_PF_ADDED_TESTS TRUE PARENT_SCOPE)
    endif()

    # Examples
    get_filename_component(examples_dir "${PROJECT_SOURCE_DIR}/examples" ABSOLUTE)
    option(BUILD_EXAMPLES "Build examples" ON)
    if(EXISTS "${examples_dir}/CMakeLists.txt" AND BUILD_EXAMPLES AND is_root_project AND NOT examples_dir IN_LIST already_subdirs)
        add_subdirectory("${examples_dir}")
    endif()

    # Tools
    get_filename_component(tools_dir "${PROJECT_SOURCE_DIR}/tools" ABSOLUTE)
    if(EXISTS "${tools_dir}/CMakeLists.txt" AND NOT tools_dir IN_LIST already_subdirs)
        add_subdirectory("${tools_dir}")
    endif()

    # Data
    get_filename_component(data_dir "${PROJECT_SOURCE_DIR}/data" ABSOLUTE)
    if(EXISTS "${data_dir}/CMakeLists.txt" AND NOT data_dir IN_LIST already_subdirs)
        add_subdirectory("${data_dir}")
    endif()

    if(do_install)
        install(
            EXPORT "${PROJECT_NAME}Targets"
            DESTINATION "${install_infix}/cmake"
            FILE "${PROJECT_NAME}Config.cmake"
        )
        write_basic_package_version_file(
            "${PROJECT_NAME}ConfigVersion.cmake"
            COMPATIBILITY ${ARG_VERSION_COMPATIBILITY}
        )
        install(
            FILES "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
            DESTINATION "${install_infix}/cmake"
        )
    endif()
endfunction()

# Macro to allow processing within parent scope
macro(auto_lib)
    _auto_lib(${ARGN})
endmacro()
