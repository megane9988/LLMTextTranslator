import Cocoa

protocol GlobalHotKeyManagerDelegate: AnyObject {
    func globalHotKeyManager(_ manager: GlobalHotKeyManager, didTriggerTranslation: Void)
    func globalHotKeyManager(_ manager: GlobalHotKeyManager, didTriggerRecording: Void)
}

class GlobalHotKeyManager {
    weak var delegate: GlobalHotKeyManagerDelegate?
    
    private var globalMonitor: Any?
    
    // ショートカットキーの定義
    struct HotKey {
        static let translationKey: UInt16 = 17  // T key
        static let recordingKey: UInt16 = 15    // R key
        static let modifierFlags: NSEvent.ModifierFlags = [.command, .option, .shift]
    }
    
    // MARK: - グローバルキーボード監視開始
    func startMonitoring() {
        // 既存の監視があれば停止
        stopMonitoring()
        
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }
        
        print("グローバルキーボード監視を開始した")
    }
    
    // MARK: - グローバルキーボード監視停止
    func stopMonitoring() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
            print("グローバルキーボード監視を停止した")
        }
    }
    
    // MARK: - キーイベント処理
    private func handleKeyEvent(_ event: NSEvent) {
        print("キーイベント検出: keyCode=\(event.keyCode), modifiers=\(event.modifierFlags)")
        
        // 修飾キーの確認
        guard event.modifierFlags.contains(HotKey.modifierFlags) else {
            return
        }
        
        switch event.keyCode {
        case HotKey.translationKey:
            print("翻訳ショートカット検出！")
            delegate?.globalHotKeyManager(self, didTriggerTranslation: ())
            
        case HotKey.recordingKey:
            print("録音ショートカット検出！")
            delegate?.globalHotKeyManager(self, didTriggerRecording: ())
            
        default:
            break
        }
    }
    
    // MARK: - ショートカット情報取得
    func getTranslationShortcut() -> String {
        return "⌘ + ⌥ + ⇧ + T"
    }
    
    func getRecordingShortcut() -> String {
        return "⌘ + ⌥ + ⇧ + R"
    }
    
    func getAllShortcuts() -> [String: String] {
        return [
            "翻訳": getTranslationShortcut(),
            "録音": getRecordingShortcut()
        ]
    }
    
    // MARK: - デバッグ情報
    func isMonitoring() -> Bool {
        return globalMonitor != nil
    }
    
    func printShortcutInfo() {
        print("登録されているショートカット:")
        print("- 翻訳: \(getTranslationShortcut())")
        print("- 録音: \(getRecordingShortcut())")
    }
    
    // MARK: - クリーンアップ
    deinit {
        stopMonitoring()
    }
}
