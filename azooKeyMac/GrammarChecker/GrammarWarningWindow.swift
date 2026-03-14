import Cocoa

/// 文法警告をカーソル付近にトースト表示するウィンドウ
final class GrammarWarningWindow: NSPanel {

    private let label = NSTextField(labelWithString: "")

    private static let displayDuration: TimeInterval = 4.0
    private var hideWorkItem: DispatchWorkItem?

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 36),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: true
        )
        self.level = .popUpMenu
        self.isOpaque = false
        self.backgroundColor = NSColor(red: 0.98, green: 0.93, blue: 0.60, alpha: 0.95)
        self.hasShadow = true

        // 角丸
        contentView?.wantsLayer = true
        contentView?.layer?.cornerRadius = 8

        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12)
        label.textColor = .black
        label.maximumNumberOfLines = 3
        label.lineBreakMode = .byWordWrapping
        contentView?.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView!.leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: contentView!.trailingAnchor, constant: -10),
            label.centerYAnchor.constraint(equalTo: contentView!.centerYAnchor)
        ])
    }

    /// 文法診断を表示する
    /// - Parameters:
    ///   - diagnostics: 診断結果リスト
    ///   - cursorLocation: カーソルのスクリーン座標
    func show(diagnostics: [GrammarDiagnostic], near cursorLocation: CGPoint) {
        guard !diagnostics.isEmpty else {
            return
        }

        let icon = diagnostics.first!.severity == 1 ? "⛔️" : "⚠️"
        let messages = diagnostics.prefix(2).map { $0.message }.joined(separator: " / ")
        label.stringValue = "\(icon) \(messages)"

        // サイズを内容に合わせる
        let maxWidth: CGFloat = 380
        let textSize = label.sizeThatFits(NSSize(width: maxWidth - 20, height: .greatestFiniteMagnitude))
        let windowWidth = min(maxWidth, textSize.width + 20)
        let windowHeight = max(36, textSize.height + 16)

        // カーソルの上に表示
        let origin = NSPoint(
            x: cursorLocation.x,
            y: cursorLocation.y + 24
        )
        setFrame(NSRect(x: origin.x, y: origin.y, width: windowWidth, height: windowHeight), display: false)
        orderFront(nil)

        // 一定時間後に自動的に隠す
        hideWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.hide()
        }
        hideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.displayDuration, execute: workItem)
    }

    func hide() {
        hideWorkItem?.cancel()
        hideWorkItem = nil
        orderOut(nil)
    }
}
