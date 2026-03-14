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
  message(STATUS "MeCab found: ${MECAB_INCLUDE_DIRS}")
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
# libmozuku_grammar 静的ライブラリ
# CaboCha / tree-sitter / CURL / nlohmann_json 不要の最小構成
# ------------------------------------------------------------------
set(GRAMMAR_SOURCES
  src/analyzer.cpp
  src/utf16.cpp
  src/encoding_utils.cpp
  src/text_processor.cpp
  src/pos_analyzer.cpp
  src/mecab_manager.cpp
  src/grammar_checker.cpp
  src/mozuku_bridge.cpp
)

add_library(mozuku_grammar STATIC ${GRAMMAR_SOURCES})
target_include_directories(mozuku_grammar PUBLIC include)
target_compile_features(mozuku_grammar PUBLIC cxx_std_17)

# CaboCha 無効（IME向け最小構成）
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
# インストール
# ------------------------------------------------------------------
include(GNUInstallDirs)
install(TARGETS mozuku_grammar ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}")
install(FILES include/mozuku_bridge.h DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}")

message(STATUS "mozuku_grammar configured (MeCab only, no CaboCha/CURL/tree-sitter)")
