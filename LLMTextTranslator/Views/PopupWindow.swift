import Cocoa

class PopupWindow {
    private var currentWindow: NSWindow?
    
    // ウィンドウのデフォルト設定
    private let defaultWidth: CGFloat = 600
    private let defaultHeight: CGFloat = 400
    private let autoCloseDelay: TimeInterval = 8.0
    
    // MARK: - ポップアップ表示
    func showPopup(text: String, title: String = "Translation Result") {
        // 既存のウィンドウがあれば閉じる
        closeCurrentWindow()
        
        guard let screen = NSScreen.main?.frame else { 
            print("メインスクリーンの取得に失敗")
            return 
        }
        
        let window = createWindow(
            text: text,
            title: title,
            screenFrame: screen
        )
        
        currentWindow = window
        
        // ウィンドウを表示
        window.makeKeyAndOrderFront(nil)
        
        // クリップボードにコピー
        copyToClipboard(text: text)
        
        // 自動で閉じるタイマーを設定
        scheduleAutoClose()
        
        // デバッグ用
        print("ポップアップウィンドウを表示: \(text.prefix(50))...")
    }
    
    private func createWindow(text: String, title: String, screenFrame: NSRect) -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(
                x: (screenFrame.width - defaultWidth) / 2,
                y: (screenFrame.height - defaultHeight) / 2,
                width: defaultWidth,
                height: defaultHeight
            ),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        // ウィンドウプロパティ設定
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.backgroundColor = NSColor.windowBackgroundColor
        window.isOpaque = true
        window.hasShadow = true
        window.title = title
        window.isMovable = true
        window.minSize = NSSize(width: 300, height: 200)
        
        // テキストフィールドを作成
        let textField = createTextField(text: text)
        window.contentView?.addSubview(textField)
        
        return window
    }
    
    private func createTextField(text: String) -> NSTextField {
        let textField = NSTextField(wrappingLabelWithString: text)
        
        textField.frame = NSRect(
            x: 20, 
            y: 20, 
            width: defaultWidth - 40, 
            height: defaultHeight - 40
        )
        
        // テキストフィールドのスタイル設定
        textField.font = NSFont.systemFont(ofSize: 16)
        textField.textColor = NSColor.labelColor
        textField.backgroundColor = NSColor.textBackgroundColor
        textField.drawsBackground = true
        textField.isSelectable = true
        textField.isEditable = false
        textField.alignment = .left
        textField.lineBreakMode = .byWordWrapping
        textField.maximumNumberOfLines = 0
        textField.preferredMaxLayoutWidth = defaultWidth - 40
        
        print("テキストフィールドのフレーム: \(textField.frame)")
        
        return textField
    }
    
    private func copyToClipboard(text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        print("テキストをクリップボードにコピーした")
    }
    
    private func scheduleAutoClose() {
        DispatchQueue.main.asyncAfter(deadline: .now() + autoCloseDelay) { [weak self] in
            self?.closeCurrentWindow()
        }
    }
    
    // MARK: - ウィンドウ管理
    func closeCurrentWindow() {
        currentWindow?.orderOut(nil)
        currentWindow = nil
        print("ポップアップウィンドウを閉じた")
    }
    
    var isWindowVisible: Bool {
        return currentWindow?.isVisible == true
    }
    
    // MARK: - 設定変更
    func updateWindowSize(width: CGFloat, height: CGFloat) {
        guard let window = currentWindow else { return }
        
        let newFrame = NSRect(
            x: window.frame.origin.x,
            y: window.frame.origin.y,
            width: width,
            height: height
        )
        
        window.setFrame(newFrame, display: true, animate: true)
        print("ウィンドウサイズを変更: \(width) x \(height)")
    }
}
