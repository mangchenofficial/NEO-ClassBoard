cmake_minimum_required(VERSION 3.16)
project(ClassBoard VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 6.11 REQUIRED COMPONENTS Quick QuickControls2 Widgets)

qt_standard_project_setup()

set(MD3_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/md3")
add_subdirectory("${MD3_SOURCE_DIR}/src/Core" md3Core_build)

qt_add_executable(ClassBoard
    main.cpp
    csesparser.h
    settingsdialog.h
    scheduleeditor.h
    classswapdialog.h
)

qt_add_qml_module(ClassBoard
    URI ClassBoard
    VERSION 1.0
    QML_FILES
        main.qml
        Settings.qml
    IMPORTS
        QtQuick.Controls
        Qt.labs.platform
        md3.Core
)

if(MINGW)
    target_compile_options(ClassBoard PRIVATE -fno-stack-protector)
    target_link_options(ClassBoard PRIVATE -fno-stack-protector)
    target_link_libraries(ClassBoard
        PRIVATE
            Qt6::Quick
            Qt6::QuickControls2
            Qt6::Widgets
            ucrt
            winmm
            -Wl,--whole-archive
            md3Core
            -Wl,--no-whole-archive
    )
else()
    target_link_libraries(ClassBoard
        PRIVATE Qt6::Quick Qt6::QuickControls2 Qt6::Widgets md3Core winmm
    )
endif()

qt_import_qml_plugins(ClassBoard)
qt_finalize_executable(ClassBoard)

set_target_properties(ClassBoard PROPERTIES
    WIN32_EXECUTABLE TRUE
    MACOSX_BUNDLE TRUE
)

if(WIN32)
    find_program(WINDEPLOYQT_EXECUTABLE
        NAMES windeployqt.exe windeployqt
    )

    if(WINDEPLOYQT_EXECUTABLE)
        add_custom_command(TARGET ClassBoard POST_BUILD
            COMMAND "${WINDEPLOYQT_EXECUTABLE}" --qmldir "${CMAKE_SOURCE_DIR}" $<TARGET_FILE:ClassBoard>
            COMMENT "Running windeployqt to bundle Qt runtime into the executable folder"
        )
    else()
        message(WARNING "windeployqt not found in PATH. You must run windeployqt manually to deploy Qt runtime (or add Qt bin to PATH).")
    endif()
endif()
