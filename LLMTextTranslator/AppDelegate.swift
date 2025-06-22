import Cocoa
import AVFoundation
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var launchAtLoginManager = LaunchAtLoginManager.shared
    
    // サービス層
    private let openAIService = OpenAIService()
    private let recordingService = RecordingService()
    private let permissionManager = PermissionManager.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("App launched")
        
        // デリゲート設定
        openAIService.delegate = self
        recordingService.delegate = self
        permissionManager.delegate = self
        
        // 権限チェック開始
        permissionManager.checkAccessibilityPermission()
    }
    
    func setupApp() {
        print("アプリのセットアップを開始")
        
        // 既存のstatusItemがあれば削除
        if statusItem != nil {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard let button = statusItem.button else {
            print("ステータスアイテムのボタン作成に失敗")
            return
        }
        
        button.title = "🌐"
        print("ステータスバーアイテムを設定した: \(button.title)")
        
        // メニューバーアイテムにメニューを追加
        let menu = NSMenu()
        let testItem = NSMenuItem(title: "Test Translation", action: #selector(testTranslation), keyEquivalent: "")
        let testRecordingItem = NSMenuItem(title: "Test Recording", action: #selector(testRecording), keyEquivalent: "")
        let settingsItem = NSMenuItem(title: "API Key Settings", action: #selector(showAPIKeySettings), keyEquivalent: "")
        
        // 自動起動設定項目を追加
        let launchAtLoginItem = NSMenuItem(title: "ログイン時に自動起動", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLoginItem.target = self
        // 現在の状態に応じてチェックマークを設定
        Task { @MainActor in
            launchAtLoginItem.state = launchAtLoginManager.isEnabled ? .on : .off
        }
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        
        testItem.target = self
        testRecordingItem.target = self
        settingsItem.target = self
        
        menu.addItem(testItem)
        menu.addItem(testRecordingItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(settingsItem)
        menu.addItem(launchAtLoginItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(quitItem)
        statusItem.menu = menu
        
        print("メニューを設定した")
        
        // 音声録音権限をリクエスト
        permissionManager.checkMicrophonePermission()

        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            print("キーイベント検出: keyCode=\(event.keyCode), modifiers=\(event.modifierFlags)")
            
            // ⌘ + ⌥ + ⇧ + T (翻訳)
            if event.modifierFlags.contains([.command, .option, .shift]) &&
                event.keyCode == 17 {
                print("翻訳ショートカット検出！")
                self?.translateSelectedText()
            }
            
            // ⌘ + ⌥ + ⇧ + R (録音)
            if event.modifierFlags.contains([.command, .option, .shift]) &&
                event.keyCode == 15 {
                print("録音ショートカット検出！")
                self?.toggleRecording()
            }
        }
        
        print("グローバルキーボード監視を開始した")
        print("アプリのセットアップ完了")
    }
    
    @objc func showAPIKeySettings() {
        let alert = NSAlert()
        alert.messageText = "OpenAI APIキー設定"
        alert.informativeText = "OpenAI APIキーを入力してください。このキーはKeychainに安全に保存されます。"
        alert.addButton(withTitle: "保存")
        alert.addButton(withTitle: "キャンセル")
        
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 20))
        textField.stringValue = KeychainHelper.shared.getAPIKey() ?? ""
        textField.placeholderString = "sk-proj-..."
        alert.accessoryView = textField
        
        if alert.runModal() == .alertFirstButtonReturn {
            let apiKey = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if apiKey.isEmpty {
                // 空の場合は削除
                if KeychainHelper.shared.deleteAPIKey() {
                    showPopup(text: "APIキーを削除しました")
                } else {
                    showPopup(text: "APIキーの削除に失敗しました")
                }
            } else {
                // 保存
                if KeychainHelper.shared.saveAPIKey(apiKey) {
                    showPopup(text: "APIキーを保存しました")
                } else {
                    showPopup(text: "APIキーの保存に失敗しました")
                }
            }
        }
    }

    @objc func testTranslation() {
        print("テスト翻訳を実行")
        showPopup(text: "テスト: アプリが正常に動作している")
    }

    @objc func testRecording() {
        print("テスト録音を実行")
        recordingService.toggleRecording()
    }
    
    func toggleRecording() {
        recordingService.toggleRecording()
    }

    func translateSelectedText() {
        print("テキスト翻訳を開始")
        
        // コピーコマンドを送信
        let src = CGEventSource(stateID: .combinedSessionState)
        let cmdDown = CGEvent(keyboardEventSource: src, virtualKey: 0x08, keyDown: true) // C key
        cmdDown?.flags = .maskCommand
        let cmdUp = CGEvent(keyboardEventSource: src, virtualKey: 0x08, keyDown: false)
        cmdUp?.flags = .maskCommand
        
        cmdDown?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)
        print("Cmd+C を送信した")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let pb = NSPasteboard.general
            if let copied = pb.string(forType: .string), !copied.isEmpty {
                print("コピーしたテキスト: \(copied)")
                self.openAIService.translateText(copied)
            } else {
                print("クリップボードが空だ")
                self.showPopup(text: "テキストが選択されていない")
            }
        }
    }

    func showPopup(text: String) {
        let popupWidth: CGFloat = 600
        let popupHeight: CGFloat = 400

        guard let screen = NSScreen.main?.frame else { return }
        let window = NSWindow(
            contentRect: NSRect(
                x: (screen.width - popupWidth) / 2,
                y: (screen.height - popupHeight) / 2,
                width: popupWidth,
                height: popupHeight
            ),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.isReleasedWhenClosed = false
        window.level = .floating
        window.backgroundColor = NSColor.windowBackgroundColor
        window.isOpaque = true
        window.hasShadow = true
        window.title = "Translation Result"
        window.isMovable = true
        window.minSize = NSSize(width: 300, height: 200)
        
        // シンプルなNSTextFieldを使用
        let textField = NSTextField(wrappingLabelWithString: text)
        textField.frame = NSRect(x: 20, y: 20, width: popupWidth - 40, height: popupHeight - 40)
        textField.font = NSFont.systemFont(ofSize: 16)
        textField.textColor = NSColor.labelColor
        textField.backgroundColor = NSColor.textBackgroundColor
        textField.drawsBackground = true
        textField.isSelectable = true
        textField.isEditable = false
        textField.alignment = .left
        textField.lineBreakMode = .byWordWrapping
        textField.maximumNumberOfLines = 0
        textField.preferredMaxLayoutWidth = popupWidth - 40
        
        window.contentView?.addSubview(textField)
        
        // デバッグ用
        print("ウィンドウ表示: \(text)")
        print("テキストフィールドのフレーム: \(textField.frame)")
        
        window.makeKeyAndOrderFront(nil)

        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)

        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
            window.orderOut(nil)
        }
    }
    
    @objc func toggleLaunchAtLogin() {
        Task { @MainActor in
            launchAtLoginManager.toggle()
            
            // メニュー項目の状態を更新
            if let menu = statusItem.menu {
                for item in menu.items {
                    if item.title == "ログイン時に自動起動" {
                        item.state = launchAtLoginManager.isEnabled ? .on : .off
                        break
                    }
                }
            }
            
            print("自動起動設定を切り替えた: \(launchAtLoginManager.isEnabled)")
        }
    }
}

// MARK: - OpenAIServiceDelegate
extension AppDelegate: OpenAIServiceDelegate {
    func openAIService(_ service: OpenAIService, didReceiveTranslation translation: String) {
        showPopup(text: translation)
    }
    
    func openAIService(_ service: OpenAIService, didReceiveTranscription transcription: String) {
        showPopup(text: transcription)
    }
    
    func openAIService(_ service: OpenAIService, didFailWithError error: String) {
        showPopup(text: error)
    }
}

// MARK: - RecordingServiceDelegate
extension AppDelegate: RecordingServiceDelegate {
    func recordingService(_ service: RecordingService, didStartRecording: Bool) {
        // ステータスバーのアイコンを変更
        statusItem.button?.title = "🔴"
        showPopup(text: "録音中... ⌘ + ⌥ + ⇧ + R で停止")
    }
    
    func recordingService(_ service: RecordingService, didStopRecording audioURL: URL?) {
        // ステータスバーのアイコンを元に戻す
        statusItem.button?.title = "🌐"
        
        if let url = audioURL {
            print("録音ファイル: \(url.path)")
            openAIService.transcribeAudio(from: url)
        }
    }
    
    func recordingService(_ service: RecordingService, didFailWithError error: String) {
        showPopup(text: error)
    }
}

// MARK: - PermissionManagerDelegate
extension AppDelegate: PermissionManagerDelegate {
    func permissionManager(_ manager: PermissionManager, accessibilityPermissionGranted: Bool) {
        if accessibilityPermissionGranted {
            setupApp()
        }
    }
    
    func permissionManager(_ manager: PermissionManager, microphonePermissionGranted: Bool) {
        if microphonePermissionGranted {
            print("マイクロフォン権限が許可された")
        }
    }
}
