/**
 * mozuku_bridge.h
 * C API wrapper for MoZuku grammar checker (for Swift/Objective-C interop)
 */
#pragma once

#ifdef __cplusplus
extern "C" {
#endif

#include <stddef.h>

typedef struct {
    int start_char;
    int end_char;
    int severity;   /* 1=error, 2=warning, 3=info */
    char message[512];
} MozukuDiagnosticC;

typedef struct {
    MozukuDiagnosticC* items;
    int count;
} MozukuDiagnosticList;

/** アナライザーインスタンスを生成して返す */
void* mozuku_analyzer_create(void);

/** インスタンスを破棄する */
void mozuku_analyzer_destroy(void* analyzer);

/**
 * MeCabの辞書パスを指定して初期化する
 * @param mecab_dic_path  例: "/opt/homebrew/lib/mecab/dic/ipadic"
 * @return 1=成功, 0=失敗
 */
int mozuku_analyzer_initialize(void* analyzer, const char* mecab_dic_path);

/**
 * 文法チェックを実行する
 * @param text  UTF-8エンコードされた日本語テキスト
 * @return 診断結果のリスト（使い終わったら mozuku_diagnostic_list_free で解放すること）
 */
MozukuDiagnosticList mozuku_check_grammar(void* analyzer, const char* text);

/** mozuku_check_grammar の戻り値を解放する */
void mozuku_diagnostic_list_free(MozukuDiagnosticList list);

#ifdef __cplusplus
}
#endif
