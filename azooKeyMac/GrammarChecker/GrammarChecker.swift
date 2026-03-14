import Foundation

/// 文法チェックの診断結果
struct GrammarDiagnostic {
    let startChar: Int
    let endChar: Int
    let severity: Int   // 1=error, 2=warning, 3=info
    let message: String
}

/// MoZuku文法チェッカーのSwiftラッパー（actor で排他制御）
actor GrammarChecker {

    private var analyzerPtr: UnsafeMutableRawPointer?
    private var isReady = false

    static let shared = GrammarChecker()

    private init() {}

    /// MeCabの辞書パスを指定して初期化する
    /// - Parameter mecabDicPath: 例 "/opt/homebrew/lib/mecab/dic/ipadic"
    func initialize(mecabDicPath: String = GrammarChecker.detectMecabDicPath()) {
        guard !isReady else { return }

        analyzerPtr = mozuku_analyzer_create()
        guard let ptr = analyzerPtr else { return }

        let result = mozuku_analyzer_initialize(ptr, mecabDicPath)
        isReady = (result == 1)
        if !isReady {
            mozuku_analyzer_destroy(ptr)
            analyzerPtr = nil
        }
    }

    deinit {
        if let ptr = analyzerPtr {
            mozuku_analyzer_destroy(ptr)
        }
    }

    /// 文法チェックを実行する（初期化されていない場合は空配列を返す）
    func checkGrammar(_ text: String) -> [GrammarDiagnostic] {
        guard isReady, let ptr = analyzerPtr, !text.isEmpty else { return [] }

        let list = mozuku_check_grammar(ptr, text)
        defer { mozuku_diagnostic_list_free(list) }

        guard list.count > 0, let items = list.items else { return [] }

        return (0..<Int(list.count)).map { i in
            let item = items[i]
            let msg = withUnsafePointer(to: item.message) {
                $0.withMemoryRebound(to: CChar.self, capacity: 512) {
                    String(cString: $0)
                }
            }
            return GrammarDiagnostic(
                startChar: Int(item.start_char),
                endChar: Int(item.end_char),
                severity: Int(item.severity),
                message: msg
            )
        }
    }

    /// Homebrewなどの一般的なパスからMeCab辞書を自動検出する
    static func detectMecabDicPath() -> String {
        let candidates = [
            "/opt/homebrew/lib/mecab/dic/ipadic",
            "/usr/local/lib/mecab/dic/ipadic",
            "/usr/lib/mecab/dic/ipadic",
            "/usr/share/mecab/dic/ipadic",
        ]
        return candidates.first {
            FileManager.default.fileExists(atPath: $0)
        } ?? candidates[0]
    }
}
