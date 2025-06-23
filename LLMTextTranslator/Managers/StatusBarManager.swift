import Cocoa

protocol StatusBarManagerDelegate: AnyObject {
    func statusBarManager(_ manager: StatusBarManager, didSelectTestTranslation: Void)
    func statusBarManager(_ manager: StatusBarManager, didSelectTestRecording: Void)
    func statusBarManager(_ manager: StatusBarManager, didSelectAPIKeySettings: Void)
    func statusBarManager(_ manager: StatusBarManager, didToggleLaunchAtLogin: Void)
}

class StatusBarManager {
    weak var delegate: StatusBarManagerDelegate?
    
    private var statusItem: NSStatusItem?
    
    // ステータスバーアイコンの状態
    enum IconState {
        case normal
        case recording
        case translating
        case transcribing
        
        var symbolName: String {
            switch self {
            case .normal: return "globe"
            case .recording: return "record.circle.fill"
            case .translating: return "arrow.triangle.2.circlepath"
            case .transcribing: return "mic.fill"
            }
        }
    }
    
    // MARK: - セットアップ
    func setupStatusBar() {
        print("ステータスバーのセットアップを開始")
        
        // 既存のstatusItemがあれば削除
        if let existingItem = statusItem {
            NSStatusBar.system.removeStatusItem(existingItem)
        }
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard let button = statusItem?.button else {
            print("ステータスアイテムのボタン作成に失敗")
            return
        }
        
        setupButtonIcon(button, state: .normal)
        print("ステータスバーアイテムを設定した: \(IconState.normal.symbolName)")
        
        setupMenu()
        print("ステータスバーのセットアップ完了")
    }
    
    private func setupMenu() {
        let menu = NSMenu()
        
        // テスト項目
        let testItem = NSMenuItem(
            title: "Test Translation", 
            action: #selector(testTranslationSelected), 
            keyEquivalent: ""
        )
        testItem.target = self
        
        let testRecordingItem = NSMenuItem(
            title: "Test Recording", 
            action: #selector(testRecordingSelected), 
            keyEquivalent: ""
        )
        testRecordingItem.target = self
        
        // 設定項目
        let settingsItem = NSMenuItem(
            title: "API Key Settings", 
            action: #selector(apiKeySettingsSelected), 
            keyEquivalent: ""
        )
        settingsItem.target = self
        
        // 自動起動設定項目
        let launchAtLoginItem = NSMenuItem(
            title: "ログイン時に自動起動", 
            action: #selector(launchAtLoginToggled), 
            keyEquivalent: ""
        )
        launchAtLoginItem.target = self
        
        // 終了項目
        let quitItem = NSMenuItem(
            title: "Quit", 
            action: #selector(NSApplication.terminate(_:)), 
            keyEquivalent: "q"
        )
        
        // メニューに追加
        menu.addItem(testItem)
        menu.addItem(testRecordingItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(settingsItem)
        menu.addItem(launchAtLoginItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
        
        // 現在の状態に応じてチェックマークを設定（非同期）
        updateLaunchAtLoginState()
        
        print("メニューを設定した")
    }
    
    // MARK: - アイコン状態変更
    func setIconState(_ state: IconState) {
        guard let button = statusItem?.button else { return }
        setupButtonIcon(button, state: state)
        print("ステータスバーアイコンを変更: \(state.symbolName)")
    }
    
    private func setupButtonIcon(_ button: NSStatusBarButton, state: IconState) {
        let image = NSImage(systemSymbolName: state.symbolName, accessibilityDescription: nil)
        image?.isTemplate = true
        button.image = image
        button.title = ""
    }
    
    // MARK: - 自動起動設定の更新
    func updateLaunchAtLoginState() {
        guard let menu = statusItem?.menu else { return }
        
        Task { @MainActor in
            let isEnabled = LaunchAtLoginManager.shared.isEnabled
            for item in menu.items {
                if item.title == "ログイン時に自動起動" {
                    item.state = isEnabled ? .on : .off
                    break
                }
            }
            print("自動起動設定メニューを更新: \(isEnabled)")
        }
    }
    
    // MARK: - メニューアクション
    @objc private func testTranslationSelected() {
        print("テスト翻訳メニューが選択された")
        delegate?.statusBarManager(self, didSelectTestTranslation: ())
    }
    
    @objc private func testRecordingSelected() {
        print("テスト録音メニューが選択された")
        delegate?.statusBarManager(self, didSelectTestRecording: ())
    }
    
    @objc private func apiKeySettingsSelected() {
        print("APIキー設定メニューが選択された")
        delegate?.statusBarManager(self, didSelectAPIKeySettings: ())
    }
    
    @objc private func launchAtLoginToggled() {
        print("自動起動設定メニューが選択された")
        delegate?.statusBarManager(self, didToggleLaunchAtLogin: ())
    }
    
    // MARK: - クリーンアップ
    func cleanup() {
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
            print("ステータスバーアイテムを削除した")
        }
    }
}
