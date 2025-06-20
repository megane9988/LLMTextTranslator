import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var permissionTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("App launched")
        checkAccessibilityPermission()
    }
    
    func checkAccessibilityPermission() {
        // デバッグ情報を追加
        let bundleID = Bundle.main.bundleIdentifier ?? "Unknown"
        print("Bundle ID: \(bundleID)")
        
        let trusted = AXIsProcessTrusted()
        print("アクセシビリティ権限状態: \(trusted)")
        
        if !trusted {
            print("アクセシビリティ権限が必要だ")
            
            // 最初にプロンプトありで権限要求
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
            let promptResult = AXIsProcessTrustedWithOptions(options as CFDictionary)
            print("プロンプト後の権限状態: \(promptResult)")
            
            if promptResult {
                // 即座に許可された場合
                print("権限が即座に許可された")
                setupApp()
                return
            }
            
            // アラートは一度だけ表示
            let alert = NSAlert()
            alert.messageText = "アクセシビリティ権限が必要"
            alert.informativeText = "システム環境設定でアプリを許可した後、アプリを再起動してください"
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "設定を開く")
            
            let response = alert.runModal()
            if response == .alertSecondButtonReturn {
                // システム環境設定を開く
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            }
            
            // タイマーでチェック（回数制限付き）
            var checkCount = 0
            permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                checkCount += 1
                print("権限チェック中... (\(checkCount)/30)")
                
                if AXIsProcessTrusted() {
                    print("アクセシビリティ権限が許可された！")
                    timer.invalidate()
                    self.permissionTimer = nil
                    DispatchQueue.main.async {
                        self.setupApp()
                    }
                } else if checkCount >= 30 {
                    // 30秒後にタイマーを停止
                    print("権限チェックタイムアウト。アプリを再起動してください。")
                    timer.invalidate()
                    self.permissionTimer = nil
                }
            }
            return
        }
        
        print("アクセシビリティ権限は既に許可されている")
        setupApp()
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
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        let testItem = NSMenuItem(title: "Test Translation", action: #selector(testTranslation), keyEquivalent: "")
        testItem.target = self
        
        menu.addItem(testItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(quitItem)
        statusItem.menu = menu
        
        print("メニューを設定した")

        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            print("キーイベント検出: keyCode=\(event.keyCode), modifiers=\(event.modifierFlags)")
            if event.modifierFlags.contains([.command, .option, .shift]) &&
                event.keyCode == 17 {
                print("ショートカット検出！")
                self?.translateSelectedText()
            }
        }
        
        print("グローバルキーボード監視を開始した")
        print("アプリのセットアップ完了")
    }
    
    @objc func testTranslation() {
        print("テスト翻訳を実行")
        showPopup(text: "テスト: アプリが正常に動作している")
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
                self.callOpenAI(text: copied)
            } else {
                print("クリップボードが空だ")
                self.showPopup(text: "テキストが選択されていない")
            }
        }
    }

    func callOpenAI(text: String) {
        print("OpenAI API を呼び出し中...")
        
        // 環境変数または設定からAPIキーを取得（後で修正）
        let apiKey = "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"
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            print("URL作成に失敗")
            return
        }
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let prompt = "Translate the following text between English and Japanese depending on its original language:\n\(text)"
        let json: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                ["role": "system", "content": "You are a translator."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0
        ]

        do {
            req.httpBody = try JSONSerialization.data(withJSONObject: json)
        } catch {
            print("JSON作成エラー: \(error)")
            return
        }

        URLSession.shared.dataTask(with: req) { data, response, error in
            if let error = error {
                print("ネットワークエラー: \(error)")
                DispatchQueue.main.async {
                    self.showPopup(text: "ネットワークエラー")
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTPステータス: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("データがない")
                return
            }
            
            do {
                if let result = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("APIレスポンス: \(result)")
                    
                    if let choices = result["choices"] as? [[String: Any]],
                       let message = choices.first?["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        DispatchQueue.main.async {
                            self.showPopup(text: content.trimmingCharacters(in: .whitespacesAndNewlines))
                        }
                    } else if let error = result["error"] as? [String: Any] {
                        print("API エラー: \(error)")
                        DispatchQueue.main.async {
                            self.showPopup(text: "API エラー")
                        }
                    }
                }
            } catch {
                print("JSON解析エラー: \(error)")
            }
        }.resume()
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
}

