import Cocoa

protocol ClipboardManagerDelegate: AnyObject {
    func clipboardManager(_ manager: ClipboardManager, didCopyText text: String)
    func clipboardManager(_ manager: ClipboardManager, didFailToCopyText: Void)
}

class ClipboardManager {
    weak var delegate: ClipboardManagerDelegate?
    
    private let copyDelay: TimeInterval = 0.3
    
    // MARK: - テキスト選択とコピー
    func copySelectedText() {
        print("選択されたテキストのコピーを開始")
        
        // Cmd+C を送信してテキストをクリップボードにコピー
        sendCopyCommand()
        
        // 少し待ってからクリップボードの内容を取得
        DispatchQueue.main.asyncAfter(deadline: .now() + copyDelay) { [weak self] in
            self?.retrieveClipboardText()
        }
    }
    
    private func sendCopyCommand() {
        let source = CGEventSource(stateID: .combinedSessionState)
        
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true) // C key
        cmdDown?.flags = .maskCommand
        
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        cmdUp?.flags = .maskCommand
        
        cmdDown?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)
        
        print("Cmd+C を送信した")
    }
    
    private func retrieveClipboardText() {
        let pasteboard = NSPasteboard.general
        
        if let copiedText = pasteboard.string(forType: .string), !copiedText.isEmpty {
            print("コピーしたテキスト: \(copiedText)")
            delegate?.clipboardManager(self, didCopyText: copiedText)
        } else {
            print("クリップボードが空だ")
            delegate?.clipboardManager(self, didFailToCopyText: ())
        }
    }
    
    // MARK: - クリップボードへの書き込み
    func writeToClipboard(text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        if pasteboard.setString(text, forType: .string) {
            print("テキストをクリップボードに書き込んだ: \(text.prefix(50))...")
        } else {
            print("クリップボードへの書き込みに失敗")
        }
    }
    
    // MARK: - クリップボードからの読み取り
    func readFromClipboard() -> String? {
        let pasteboard = NSPasteboard.general
        return pasteboard.string(forType: .string)
    }
    
    // MARK: - クリップボードの状態確認
    func hasText() -> Bool {
        guard let text = readFromClipboard() else { return false }
        return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func getClipboardTextLength() -> Int {
        return readFromClipboard()?.count ?? 0
    }
    
    // MARK: - クリップボードのクリア
    func clearClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        print("クリップボードをクリアした")
    }
    
    // MARK: - 履歴管理（オプション機能）
    private var clipboardHistory: [String] = []
    private let maxHistoryCount = 10
    
    func addToHistory(text: String) {
        // 重複を避ける
        if let index = clipboardHistory.firstIndex(of: text) {
            clipboardHistory.remove(at: index)
        }
        
        clipboardHistory.insert(text, at: 0)
        
        // 履歴の上限を管理
        if clipboardHistory.count > maxHistoryCount {
            clipboardHistory = Array(clipboardHistory.prefix(maxHistoryCount))
        }
        
        print("クリップボード履歴に追加: \(text.prefix(30))...")
    }
    
    func getHistory() -> [String] {
        return clipboardHistory
    }
    
    func clearHistory() {
        clipboardHistory.removeAll()
        print("クリップボード履歴をクリアした")
    }
}
