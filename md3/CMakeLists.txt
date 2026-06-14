cmake_minimum_required(VERSION 3.16)

project(md3 VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT ANDROID)
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
endif()

# ── Auto-discover Qt6 ──────────────────────────────────────────────────────
# Qt6_DIR or CMAKE_PREFIX_PATH can be set externally (env/presets/cmake args).
# If neither provides a valid Qt6, search for it automatically.
#
# Search order:
#   1. $ENV{QT6_DIR} / $ENV{CMAKE_PREFIX_PATH}  (environment variables)
#   2. $ENV{QTDIR}  (legacy Qt env var)
#   3. $HOME/Qt/<version>/<platform>   (macOS / Linux)
#   4. C:\Qt\<version>\<platform>       (Windows default)
#   5. D:\Qt\<version>\<platform> ...   (Windows alternative drives)
if(NOT DEFINED Qt6_DIR AND NOT DEFINED CMAKE_PREFIX_PATH)

    # ── Try env vars ─────────────────────────────────────────────────────
    if(DEFINED ENV{CMAKE_PREFIX_PATH})
        set(CMAKE_PREFIX_PATH "$ENV{CMAKE_PREFIX_PATH}" CACHE PATH "" FORCE)
    elseif(DEFINED ENV{QT6_DIR})
        set(CMAKE_PREFIX_PATH "$ENV{QT6_DIR}" CACHE PATH "" FORCE)
    elseif(DEFINED ENV{QTDIR})
        set(CMAKE_PREFIX_PATH "$ENV{QTDIR}" CACHE PATH "" FORCE)
    else()

        # ── Platform-specific platform subdirectory name ─────────────────
        if(WIN32)
            set(_qt_platform_names
                "msvc2022_64" "msvc2022_arm64"
                "msvc2019_64" "msvc2019"
                "mingw_64" "mingw"
            )
        elseif(APPLE)
            set(_qt_platform_names "macos" "clang_64")
        else()
            set(_qt_platform_names "gcc_64" "clang_64" "linux_gcc_64")
        endif()

        # ── Search Qt installation roots ─────────────────────────────────
        set(_qt_search_roots "")

        if(DEFINED ENV{HOME})
            list(APPEND _qt_search_roots "$ENV{HOME}/Qt")
        endif()

        if(WIN32)
            foreach(_drv C D E F G)
                if(EXISTS "${_drv}:/Qt")
                    list(APPEND _qt_search_roots "${_drv}:/Qt")
                endif()
            endforeach()
            if(DEFINED ENV{ProgramFiles})
                list(APPEND _qt_search_roots "$ENV{ProgramFiles}/Qt")
            endif()
        endif()

        # ── Search each root, prefer highest version ────────────────────
        set(_qt_auto_found FALSE)
        foreach(_qt_root ${_qt_search_roots})
            if(NOT EXISTS "${_qt_root}")
                continue()
            endif()
            file(GLOB _qt_versions LIST_DIRECTORIES true "${_qt_root}/*")
            list(SORT _qt_versions)
            list(REVERSE _qt_versions)

            foreach(_qt_ver_dir ${_qt_versions})
                if(NOT IS_DIRECTORY "${_qt_ver_dir}")
                    continue()
                endif()
                foreach(_plat ${_qt_platform_names})
                    set(_qt_prefix "${_qt_ver_dir}/${_plat}")
                    if(EXISTS "${_qt_prefix}/lib/cmake/Qt6/Qt6Config.cmake")
                        set(CMAKE_PREFIX_PATH "${_qt_prefix}" CACHE PATH
                            "Auto-discovered Qt6 prefix" FORCE)
                        message(STATUS "Auto-discovered Qt6 at: ${_qt_prefix}")
                        set(_qt_auto_found TRUE)
                        break()
                    endif()
                endforeach()
                if(_qt_auto_found)
                    break()
                endif()
            endforeach()
            if(_qt_auto_found)
                break()
            endif()
        endforeach()

        if(NOT _qt_auto_found)
            message(WARNING "Could not auto-discover Qt6. "
                            "Set CMAKE_PREFIX_PATH or Qt6_DIR manually "
                            "(e.g. -DCMAKE_PREFIX_PATH=C:/Qt/6.11.0/msvc2022_64).")
        endif()

        unset(_qt_auto_found)
        unset(_qt_versions)
        unset(_qt_ver_dir)
        unset(_qt_prefix)
        unset(_qt_platform_names)
        unset(_qt_search_roots)
        unset(_plat)
    endif()
endif()

find_package(Qt6 REQUIRED COMPONENTS Quick Gui Svg Network )

qt_standard_project_setup(REQUIRES 6.8)

set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS
    "${CMAKE_SOURCE_DIR}/src/Extras/Charts/CMakeLists.txt"
    "${CMAKE_SOURCE_DIR}/src/Extras/DataGrid/CMakeLists.txt"
    "${CMAKE_SOURCE_DIR}/src/Extras/HotReload/CMakeLists.txt"
    "${CMAKE_SOURCE_DIR}/src/Extras/Performance/CMakeLists.txt"
    "${CMAKE_SOURCE_DIR}/src/Extras/MathSymbols/CMakeLists.txt"
    "${CMAKE_SOURCE_DIR}/src/Extras/Markdown/CMakeLists.txt"
    "${CMAKE_SOURCE_DIR}/src/Extras/NodeGraph/CMakeLists.txt"
    "${CMAKE_SOURCE_DIR}/src/Extras/Gantt/CMakeLists.txt"
    "${CMAKE_SOURCE_DIR}/src/Extras/ReportDesigner/CMakeLists.txt"
    "${CMAKE_SOURCE_DIR}/src/Extras/VideoWall/CMakeLists.txt"
)

add_subdirectory(src/Core)

set(MD3_HAS_EXTRA_CHARTS FALSE)
set(MD3_HAS_EXTRA_DATAGRID FALSE)
set(MD3_HAS_EXTRA_HOTRELOAD FALSE)
set(MD3_HAS_EXTRA_PERFORMANCE FALSE)
set(MD3_HAS_EXTRA_MATHSYMBOLS FALSE)
set(MD3_HAS_EXTRA_MARKDOWN FALSE)
set(MD3_HAS_EXTRA_NODEGRAPH FALSE)
set(MD3_HAS_EXTRA_GANTT FALSE)
set(MD3_HAS_EXTRA_REPORTDESIGNER FALSE)
set(MD3_HAS_EXTRA_VIDEOWALL FALSE)

if(EXISTS "${CMAKE_SOURCE_DIR}/src/Extras/Charts/CMakeLists.txt")
    add_subdirectory(src/Extras/Charts)
    set(MD3_HAS_EXTRA_CHARTS TRUE)
endif()

if(EXISTS "${CMAKE_SOURCE_DIR}/src/Extras/DataGrid/CMakeLists.txt")
    add_subdirectory(src/Extras/DataGrid)
    set(MD3_HAS_EXTRA_DATAGRID TRUE)
endif()

if(EXISTS "${CMAKE_SOURCE_DIR}/src/Extras/HotReload/CMakeLists.txt")
    add_subdirectory(src/Extras/HotReload)
    set(MD3_HAS_EXTRA_HOTRELOAD TRUE)
endif()

if(EXISTS "${CMAKE_SOURCE_DIR}/src/Extras/Performance/CMakeLists.txt")
    if(MD3_HAS_EXTRA_CHARTS)
        add_subdirectory(src/Extras/Performance)
        set(MD3_HAS_EXTRA_PERFORMANCE TRUE)
    else()
        message(WARNING "Performance extra found, but Charts extra is missing. Performance is disabled.")
    endif()
endif()

if(EXISTS "${CMAKE_SOURCE_DIR}/src/Extras/MathSymbols/CMakeLists.txt")
    add_subdirectory(src/Extras/MathSymbols)
    set(MD3_HAS_EXTRA_MATHSYMBOLS TRUE)
endif()

if(EXISTS "${CMAKE_SOURCE_DIR}/src/Extras/Markdown/CMakeLists.txt")
    add_subdirectory(src/Extras/Markdown)
    set(MD3_HAS_EXTRA_MARKDOWN TRUE)
endif()

if(EXISTS "${CMAKE_SOURCE_DIR}/src/Extras/NodeGraph/CMakeLists.txt")
    add_subdirectory(src/Extras/NodeGraph)
    set(MD3_HAS_EXTRA_NODEGRAPH TRUE)
endif()

if(EXISTS "${CMAKE_SOURCE_DIR}/src/Extras/Gantt/CMakeLists.txt")
    add_subdirectory(src/Extras/Gantt)
    set(MD3_HAS_EXTRA_GANTT TRUE)
endif()

if(EXISTS "${CMAKE_SOURCE_DIR}/src/Extras/ReportDesigner/CMakeLists.txt")
    add_subdirectory(src/Extras/ReportDesigner)
    set(MD3_HAS_EXTRA_REPORTDESIGNER TRUE)
endif()

if(EXISTS "${CMAKE_SOURCE_DIR}/src/Extras/VideoWall/CMakeLists.txt")
    add_subdirectory(src/Extras/VideoWall)
    set(MD3_HAS_EXTRA_VIDEOWALL TRUE)
endif()

message(STATUS "MD3 extras availability:")
message(STATUS "  Charts      : ${MD3_HAS_EXTRA_CHARTS}")
message(STATUS "  DataGrid    : ${MD3_HAS_EXTRA_DATAGRID}")
message(STATUS "  HotReload   : ${MD3_HAS_EXTRA_HOTRELOAD}")
message(STATUS "  Performance : ${MD3_HAS_EXTRA_PERFORMANCE}")
message(STATUS "  MathSymbols : ${MD3_HAS_EXTRA_MATHSYMBOLS}")
message(STATUS "  Markdown    : ${MD3_HAS_EXTRA_MARKDOWN}")
message(STATUS "  NodeGraph   : ${MD3_HAS_EXTRA_NODEGRAPH}")
message(STATUS "  Gantt       : ${MD3_HAS_EXTRA_GANTT}")
message(STATUS "  ReportDesign: ${MD3_HAS_EXTRA_REPORTDESIGNER}")
message(STATUS "  VideoWall   : ${MD3_HAS_EXTRA_VIDEOWALL}")

add_subdirectory(src/App)
