import Cocoa

class PopupWindow {
    private var currentWindow: NSWindow?
    
    // ウィンドウのデフォルト設定
    private let defaultWidth: CGFloat = 600
    private let defaultHeight: CGFloat = 400
    
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
        
        // スクロール可能なテキストビューを作成
        let scrollView = createScrollableTextView(text: text)
        window.contentView?.addSubview(scrollView)
        
        return window
    }
    
    private func createScrollableTextView(text: String) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.frame = NSRect(
            x: 20, 
            y: 20, 
            width: defaultWidth - 40, 
            height: defaultHeight - 40
        )
        
        // スクロールビューの設定
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = false
        scrollView.borderType = .bezelBorder
        
        // テキストビューの作成
        let textView = NSTextView()
        textView.frame = NSRect(x: 0, y: 0, width: defaultWidth - 60, height: defaultHeight - 60)
        textView.string = text
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = NSFont.systemFont(ofSize: 16)
        textView.textColor = NSColor.labelColor
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.isRichText = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: defaultWidth - 60, height: CGFloat.greatestFiniteMagnitude)
        
        scrollView.documentView = textView
        
        print("スクロールビューのフレーム: \(scrollView.frame)")
        
        return scrollView
    }
    
    private func copyToClipboard(text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        print("テキストをクリップボードにコピーした")
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
        
        // スクロールビューのサイズも更新
        if let scrollView = window.contentView?.subviews.first as? NSScrollView {
            scrollView.frame = NSRect(
                x: 20,
                y: 20,
                width: width - 40,
                height: height - 40
            )
        }
        
        print("ウィンドウサイズを変更: \(width) x \(height)")
    }
}
