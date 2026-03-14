cmake_minimum_required(VERSION 3.16)
project(mozuku_grammar C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ------------------------------------------------------------------
# MeCab の検索
# ------------------------------------------------------------------
find_program(MECAB_CONFIG mecab-config)
if(MECAB_CONFIG)
  execute_process(
    COMMAND ${MECAB_CONFIG} --libs-only-L
    OUTPUT_VARIABLE MECAB_LIBRARY_DIRS OUTPUT_STRIP_TRAILING_WHITESPACE)
  execute_process(
    COMMAND ${MECAB_CONFIG} --libs-only-l
    OUTPUT_VARIABLE MECAB_LINK_LIBRARIES OUTPUT_STRIP_TRAILING_WHITESPACE)
  execute_process(
    COMMAND ${MECAB_CONFIG} --inc-dir
    OUTPUT_VARIABLE MECAB_INCLUDE_DIRS OUTPUT_STRIP_TRAILING_WHITESPACE)
  string(REPLACE "-L" "" MECAB_LIBRARY_DIRS "${MECAB_LIBRARY_DIRS}")
  string(REPLACE "-l" "" MECAB_LINK_LIBRARIES "${MECAB_LINK_LIBRARIES}")
  separate_arguments(MECAB_LINK_LIBRARIES)
  message(STATUS "MeCab found via mecab-config")
  message(STATUS "  include: ${MECAB_INCLUDE_DIRS}")
  message(STATUS "  lib dirs: ${MECAB_LIBRARY_DIRS}")
  message(STATUS "  libs: ${MECAB_LINK_LIBRARIES}")
else()
  message(FATAL_ERROR "mecab-config が見つかりません。brew install mecab を実行してください。")
endif()

add_library(mecab_system INTERFACE IMPORTED)
target_include_directories(mecab_system INTERFACE ${MECAB_INCLUDE_DIRS})
if(MECAB_LIBRARY_DIRS)
  target_link_directories(mecab_system INTERFACE ${MECAB_LIBRARY_DIRS})
endif()
target_link_libraries(mecab_system INTERFACE ${MECAB_LINK_LIBRARIES})

# ------------------------------------------------------------------
# ソースファイル（CaboCha/tree-sitter/CURL不要の最小セット）
# ------------------------------------------------------------------
set(SRC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../mozuku-lsp/src")
set(INC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../mozuku-lsp/include")

set(GRAMMAR_SOURCES
  ${SRC_DIR}/analyzer.cpp
  ${SRC_DIR}/utf16.cpp
  ${SRC_DIR}/encoding_utils.cpp
  ${SRC_DIR}/text_processor.cpp
  ${SRC_DIR}/pos_analyzer.cpp
  ${SRC_DIR}/mecab_manager.cpp
  ${SRC_DIR}/grammar_checker.cpp
  ${SRC_DIR}/mozuku_bridge.cpp
)

add_library(mozuku_grammar STATIC ${GRAMMAR_SOURCES})

target_include_directories(mozuku_grammar PUBLIC ${INC_DIR})
target_compile_features(mozuku_grammar PUBLIC cxx_std_17)

# CaboChaなし（IME向け最小構成）
# MOZUKU_ENABLE_CABOCHA を定義しないことで cabocha.h を使わない

if(WIN32)
  target_compile_definitions(mozuku_grammar PRIVATE NOMINMAX WIN32_LEAN_AND_MEAN)
endif()

target_link_libraries(mozuku_grammar PRIVATE mecab_system)

if(APPLE)
  target_link_libraries(mozuku_grammar PRIVATE "-liconv")
endif()

find_package(Threads REQUIRED)
target_link_libraries(mozuku_grammar PRIVATE Threads::Threads)

# ------------------------------------------------------------------
# インストール設定
# ------------------------------------------------------------------
include(GNUInstallDirs)

install(TARGETS mozuku_grammar
        ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}")
install(FILES ${INC_DIR}/mozuku_bridge.h
        DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}")

message(STATUS "mozuku_grammar static library configured")
message(STATUS "  Sources: ${GRAMMAR_SOURCES}")
