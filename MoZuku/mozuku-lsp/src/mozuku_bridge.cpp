/**
 * mozuku_bridge.cpp
 * C API wrapper implementation for MoZuku grammar checker
 */
#include "mozuku_bridge.h"
#include "analyzer.hpp"

#include <cstring>
#include <memory>
#include <vector>

extern "C" {

void* mozuku_analyzer_create(void) {
    return new MoZuku::Analyzer();
}

void mozuku_analyzer_destroy(void* analyzer) {
    delete static_cast<MoZuku::Analyzer*>(analyzer);
}

int mozuku_analyzer_initialize(void* analyzer, const char* mecab_dic_path) {
    if (!analyzer) return 0;

    MoZukuConfig config;
    config.mecab.dicPath = mecab_dic_path ? mecab_dic_path : "";
    config.mecab.charset = "UTF-8";
    config.analysis.enableCaboCha = false;  /* IMEではCaboCha不要 */
    config.analysis.grammarCheck = true;
    config.analysis.minJapaneseRatio = 0.0; /* IMEテキストは短いため閾値を下げる */

    /* ら抜き・助詞重複・読点過多のみ有効 */
    config.analysis.rules.raDropping = true;
    config.analysis.rules.duplicateParticleSurface = true;
    config.analysis.rules.adjacentParticles = true;
    config.analysis.rules.commaLimit = true;
    config.analysis.rules.adversativeGa = true;
    config.analysis.rules.conjunctionRepeat = true;

    auto* a = static_cast<MoZuku::Analyzer*>(analyzer);
    return a->initialize(config) ? 1 : 0;
}

MozukuDiagnosticList mozuku_check_grammar(void* analyzer, const char* text) {
    MozukuDiagnosticList result{nullptr, 0};
    if (!analyzer || !text) return result;

    auto* a = static_cast<MoZuku::Analyzer*>(analyzer);
    if (!a->isInitialized()) return result;

    std::vector<Diagnostic> diags = a->checkGrammar(std::string(text));
    if (diags.empty()) return result;

    result.count = static_cast<int>(diags.size());
    result.items = new MozukuDiagnosticC[result.count];

    for (int i = 0; i < result.count; ++i) {
        result.items[i].start_char = diags[i].range.start.character;
        result.items[i].end_char   = diags[i].range.end.character;
        result.items[i].severity   = diags[i].severity;

        /* message を固定長バッファに安全コピー */
        std::strncpy(result.items[i].message, diags[i].message.c_str(), 511);
        result.items[i].message[511] = '\0';
    }

    return result;
}

void mozuku_diagnostic_list_free(MozukuDiagnosticList list) {
    delete[] list.items;
}

} /* extern "C" */
