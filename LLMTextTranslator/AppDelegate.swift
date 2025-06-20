import Cocoa
import AVFoundation
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var permissionTimer: Timer?
    var audioRecorder: AVAudioRecorder?
    var isRecording = false
    var recordingURL: URL?
    var launchAtLoginManager = LaunchAtLoginManager.shared

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
        requestMicrophonePermission()

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
    
    func requestMicrophonePermission() {
        // macOSでのマイクロフォン権限チェック
        if #available(macOS 10.14, *) {
            switch AVCaptureDevice.authorizationStatus(for: .audio) {
            case .authorized:
                print("マイクロフォン権限は既に許可済み")
            case .denied, .restricted:
                print("マイクロフォン権限が拒否されている")
                showPermissionAlert()
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    DispatchQueue.main.async {
                        if granted {
                            print("マイクロフォン権限が許可された")
                        } else {
                            print("マイクロフォン権限が拒否された")
                            self.showPermissionAlert()
                        }
                    }
                }
            @unknown default:
                print("不明なマイクロフォン権限状態")
            }
        }
    }
    
    func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "マイクロフォン権限が必要"
        alert.informativeText = "音声録音機能を使用するにはマイクロフォンへのアクセスを許可してください"
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "設定を開く")
        
        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")!)
        }
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
        toggleRecording()
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
        
        // KeychainからAPIキーを取得
        guard let apiKey = KeychainHelper.shared.getAPIKey() else {
            print("APIキーが設定されていない")
            showPopup(text: "APIキーが設定されていません。アプリのメニューから設定してください。")
            return
        }
        
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
            "model": "gpt-3.5-turbo",
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

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    func startRecording() {
        print("録音開始")
        
        // 一時ファイルのURL
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        recordingURL = documentsPath.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
        
        // 録音設定（macOS用）
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: recordingURL!, settings: settings)
            audioRecorder?.record()
            isRecording = true
            
            // ステータスバーのアイコンを変更
            statusItem.button?.title = "🔴"
            print("録音中...")
            
            showPopup(text: "録音中... ⌘ + ⌥ + ⇧ + R で停止")
            
        } catch {
            print("録音開始エラー: \(error)")
        }
    }
    
    func stopRecording() {
        print("録音停止")
        
        audioRecorder?.stop()
        isRecording = false
        
        // ステータスバーのアイコンを元に戻す
        statusItem.button?.title = "🌐"
        
        if let url = recordingURL {
            print("録音ファイル: \(url.path)")
            convertToMP3AndTranscribe(audioURL: url)
        }
    }
    
    func convertToMP3AndTranscribe(audioURL: URL) {
        print("音声ファイルを処理中...")
        
        // M4AファイルをそのままWhisperに送信（MP3変換は省略してシンプルに）
        transcribeAudio(audioURL: audioURL)
    }
    
    func transcribeAudio(audioURL: URL) {
        print("Whisper API で文字起こし中...")
        
        // KeychainからAPIキーを取得
        guard let apiKey = KeychainHelper.shared.getAPIKey() else {
            print("APIキーが設定されていない")
            showPopup(text: "APIキーが設定されていません。")
            return
        }
        
        guard let url = URL(string: "https://api.openai.com/v1/audio/transcriptions") else {
            print("URL作成に失敗")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var data = Data()
        
        // モデルパラメータ
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        data.append("whisper-1\r\n".data(using: .utf8)!)
        
        // 言語パラメータ（日本語と英語を自動認識）
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        data.append("ja\r\n".data(using: .utf8)!)
        
        // プロンプトパラメータを追加（フィラー音除去指示）
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
        data.append("Remove filler sounds and meaningless interjections, and convert it into clear and easy-to-read text.".data(using: .utf8)!)
        data.append("\r\n".data(using: .utf8)!)
        
        // ファイルデータ
        do {
            let audioData = try Data(contentsOf: audioURL)
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: audio/mp4\r\n\r\n".data(using: .utf8)!)
            data.append(audioData)
            data.append("\r\n".data(using: .utf8)!)
        } catch {
            print("音声ファイル読み込みエラー: \(error)")
            return
        }
        
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = data
        
        URLSession.shared.dataTask(with: request) { data, response, error in
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
                    print("Whisper APIレスポンス: \(result)")
                    
                    if let text = result["text"] as? String {
                        DispatchQueue.main.async {
                            self.showPopup(text: "文字起こし結果:\n\n\(text)")
                        }
                    } else if let error = result["error"] as? [String: Any] {
                        print("Whisper API エラー: \(error)")
                        DispatchQueue.main.async {
                            self.showPopup(text: "文字起こしエラー")
                        }
                    }
                }
            } catch {
                print("JSON解析エラー: \(error)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("レスポンス内容: \(responseString)")
                }
            }
            
            // 一時ファイルを削除
            DispatchQueue.main.async {
                try? FileManager.default.removeItem(at: audioURL)
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
