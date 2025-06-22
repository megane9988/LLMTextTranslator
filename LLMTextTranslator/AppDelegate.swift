import Cocoa
import AVFoundation
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    // サービス層
    private let openAIService = OpenAIService()
    private let recordingService = RecordingService()
    private let permissionManager = PermissionManager.shared
    
    // UI層
    private let statusBarManager = StatusBarManager()
    private let popupWindow = PopupWindow()
    private let settingsWindow = SettingsWindow()
    private let globalHotKeyManager = GlobalHotKeyManager()
    private let clipboardManager = ClipboardManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("App launched")
        
        // デリゲート設定
        openAIService.delegate = self
        recordingService.delegate = self
        permissionManager.delegate = self
        statusBarManager.delegate = self
        settingsWindow.delegate = self
        globalHotKeyManager.delegate = self
        clipboardManager.delegate = self
        
        // 権限チェック開始
        permissionManager.checkAccessibilityPermission()
    }
    
    func setupApp() {
        print("アプリのセットアップを開始")
        
        // ステータスバー設定
        statusBarManager.setupStatusBar()
        
        // 音声録音権限をリクエスト
        permissionManager.checkMicrophonePermission()
        
        // グローバルキーボード監視を開始
        globalHotKeyManager.startMonitoring()
        
        print("アプリのセットアップ完了")
    }
    
    func translateSelectedText() {
        print("テキスト翻訳を開始")
        clipboardManager.copySelectedText()
    }
}

// MARK: - OpenAIServiceDelegate
extension AppDelegate: OpenAIServiceDelegate {
    func openAIService(_ service: OpenAIService, didReceiveTranslation translation: String) {
        popupWindow.showPopup(text: translation)
    }
    
    func openAIService(_ service: OpenAIService, didReceiveTranscription transcription: String) {
        popupWindow.showPopup(text: transcription)
    }
    
    func openAIService(_ service: OpenAIService, didFailWithError error: String) {
        popupWindow.showPopup(text: error)
    }
}

// MARK: - RecordingServiceDelegate
extension AppDelegate: RecordingServiceDelegate {
    func recordingService(_ service: RecordingService, didStartRecording: Bool) {
        statusBarManager.setIconState(.recording)
        popupWindow.showPopup(text: "録音中... ⌘ + ⌥ + ⇧ + R で停止")
    }
    
    func recordingService(_ service: RecordingService, didStopRecording audioURL: URL?) {
        statusBarManager.setIconState(.normal)
        
        if let url = audioURL {
            print("録音ファイル: \(url.path)")
            openAIService.transcribeAudio(from: url)
        }
    }
    
    func recordingService(_ service: RecordingService, didFailWithError error: String) {
        popupWindow.showPopup(text: error)
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

// MARK: - StatusBarManagerDelegate
extension AppDelegate: StatusBarManagerDelegate {
    func statusBarManager(_ manager: StatusBarManager, didSelectTestTranslation: Void) {
        print("テスト翻訳を実行")
        popupWindow.showPopup(text: "テスト: アプリが正常に動作している")
    }
    
    func statusBarManager(_ manager: StatusBarManager, didSelectTestRecording: Void) {
        print("テスト録音を実行")
        recordingService.toggleRecording()
    }
    
    func statusBarManager(_ manager: StatusBarManager, didSelectAPIKeySettings: Void) {
        settingsWindow.showAPIKeySettings()
    }
    
    func statusBarManager(_ manager: StatusBarManager, didToggleLaunchAtLogin: Void) {
        Task { @MainActor in
            let launchManager = LaunchAtLoginManager.shared
            launchManager.toggle()
            statusBarManager.updateLaunchAtLoginState()
            print("自動起動設定を切り替えた: \(launchManager.isEnabled)")
        }
    }
}

// MARK: - SettingsWindowDelegate
extension AppDelegate: SettingsWindowDelegate {
    func settingsWindow(_ window: SettingsWindow, didSaveAPIKey key: String) {
        print("APIキーが保存された")
    }
    
    func settingsWindow(_ window: SettingsWindow, didDeleteAPIKey: Void) {
        print("APIキーが削除された")
    }
    
    func settingsWindow(_ window: SettingsWindow, didShowMessage message: String) {
        popupWindow.showPopup(text: message)
    }
}

// MARK: - GlobalHotKeyManagerDelegate
extension AppDelegate: GlobalHotKeyManagerDelegate {
    func globalHotKeyManager(_ manager: GlobalHotKeyManager, didTriggerTranslation: Void) {
        translateSelectedText()
    }
    
    func globalHotKeyManager(_ manager: GlobalHotKeyManager, didTriggerRecording: Void) {
        recordingService.toggleRecording()
    }
}

// MARK: - ClipboardManagerDelegate
extension AppDelegate: ClipboardManagerDelegate {
    func clipboardManager(_ manager: ClipboardManager, didCopyText text: String) {
        openAIService.translateText(text)
    }
    
    func clipboardManager(_ manager: ClipboardManager, didFailToCopyText: Void) {
        popupWindow.showPopup(text: "テキストが選択されていない")
    }
}
