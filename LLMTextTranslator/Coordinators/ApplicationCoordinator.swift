import Foundation
import Combine

@MainActor
class ApplicationCoordinator: ObservableObject {
    // ViewModels
    @Published var menuBarViewModel: MenuBarViewModel
    @Published var popupViewModel: PopupViewModel
    
    // Services
    private let openAIService: OpenAIService
    private let recordingService: RecordingService
    private let permissionManager: PermissionManager
    
    // UI Managers
    private let statusBarManager: StatusBarManager
    private let popupWindow: PopupWindow
    private let settingsWindow: SettingsWindow
    private let globalHotKeyManager: GlobalHotKeyManager
    private let clipboardManager: ClipboardManager
    
    // State management
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // ViewModels初期化
        self.menuBarViewModel = MenuBarViewModel()
        self.popupViewModel = PopupViewModel()
        
        // Services初期化
        self.openAIService = OpenAIService()
        self.recordingService = RecordingService()
        self.permissionManager = PermissionManager.shared
        
        // UI Managers初期化
        self.statusBarManager = StatusBarManager()
        self.popupWindow = PopupWindow()
        self.settingsWindow = SettingsWindow()
        self.globalHotKeyManager = GlobalHotKeyManager()
        self.clipboardManager = ClipboardManager()
        
        setupDelegates()
        setupBindings()
    }
    
    // MARK: - セットアップ
    private func setupDelegates() {
        // Service delegates
        openAIService.delegate = self
        recordingService.delegate = self
        permissionManager.delegate = self
        
        // UI delegates
        statusBarManager.delegate = self
        settingsWindow.delegate = self
        globalHotKeyManager.delegate = self
        clipboardManager.delegate = self
    }
    
    private func setupBindings() {
        // MenuBarViewModelの状態変化を監視
        menuBarViewModel.$isRecording
            .sink { [weak self] isRecording in
                self?.handleRecordingStateChange(isRecording)
            }
            .store(in: &cancellables)
        
        menuBarViewModel.$isLaunchAtLoginEnabled
            .sink { [weak self] _ in
                self?.statusBarManager.updateLaunchAtLoginState()
            }
            .store(in: &cancellables)
        
        // PopupViewModelの状態変化を監視
        popupViewModel.$isVisible
            .sink { [weak self] isVisible in
                if isVisible {
                    self?.popupWindow.showPopup(
                        text: self?.popupViewModel.currentText ?? "",
                        title: self?.popupViewModel.currentTitle ?? "Translation Result"
                    )
                } else {
                    self?.popupWindow.closeCurrentWindow()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - アプリケーション開始
    func startApplication() {
        print("アプリケーション開始")
        permissionManager.checkAccessibilityPermission()
    }
    
    func setupMainApp() {
        print("メインアプリのセットアップを開始")
        
        // UI設定
        statusBarManager.setupStatusBar()
        
        // 権限チェック
        permissionManager.checkMicrophonePermission()
        
        // グローバルホットキー開始
        globalHotKeyManager.startMonitoring()
        
        // ViewModelの状態同期
        syncViewModelStates()
        
        print("メインアプリのセットアップ完了")
    }
    
    private func syncViewModelStates() {
        menuBarViewModel.refreshLaunchAtLoginState()
    }
    
    // MARK: - イベント処理
    private func handleRecordingStateChange(_ isRecording: Bool) {
        if isRecording {
            recordingService.startRecording()
        } else {
            recordingService.stopRecording()
        }
        
        // ステータスバーアイコン更新
        let iconState: StatusBarManager.IconState = isRecording ? .recording : .normal
        statusBarManager.setIconState(iconState)
    }
    
    // MARK: - アクション処理
    func executeTestTranslation() {
        popupViewModel.showPopup(text: "テスト: アプリが正常に動作している")
    }
    
    func executeTestRecording() {
        menuBarViewModel.toggleRecording()
    }
    
    func executeTranslateSelectedText() {
        print("テキスト翻訳を開始")
        clipboardManager.copySelectedText()
    }
    
    func executeToggleRecording() {
        menuBarViewModel.toggleRecording()
    }
    
    func executeTranscribeAndTranslateRecording() {
        menuBarViewModel.toggleTranscribeAndTranslateRecording()
    }
    
    func executeShowAPIKeySettings() {
        settingsWindow.showAPIKeySettings()
    }
    
    func executeToggleLaunchAtLogin() {
        menuBarViewModel.toggleLaunchAtLogin()
    }
    
    // MARK: - クリーンアップ
    func cleanup() {
        globalHotKeyManager.stopMonitoring()
        statusBarManager.cleanup()
        cancellables.removeAll()
    }
    
    deinit {
        // Main Actorを使わずに直接クリーンアップ
        globalHotKeyManager.stopMonitoring()
        cancellables.removeAll()
        // statusBarManager.cleanup()はMain Actorが必要なので、ここでは呼ばない
        print("ApplicationCoordinator: deinit完了")
    }
}

// MARK: - Service Delegates
extension ApplicationCoordinator: OpenAIServiceDelegate {
    func openAIService(_ service: OpenAIService, didStartTranslation: Void) {
        popupViewModel.setTranslatingState(true)
        statusBarManager.setIconState(.translating)
    }
    
    func openAIService(_ service: OpenAIService, didStartTranscription: Void) {
        popupViewModel.setTranscribingState(true)
        statusBarManager.setIconState(.transcribing)
    }
    
    func openAIService(_ service: OpenAIService, didReceiveTranslation translation: String) {
        popupViewModel.setTranslatingState(false)
        statusBarManager.setIconState(.normal)
        popupViewModel.showPopup(text: translation)
    }
    
    func openAIService(_ service: OpenAIService, didReceiveTranscription transcription: String) {
        popupViewModel.setTranscribingState(false)
        statusBarManager.setIconState(.normal)
        popupViewModel.showPopup(text: transcription)
    }
    
    func openAIService(_ service: OpenAIService, didFailWithError error: String) {
        // エラー時は両方の状態をリセット
        popupViewModel.setTranslatingState(false)
        popupViewModel.setTranscribingState(false)
        statusBarManager.setIconState(.normal)
        popupViewModel.showPopup(text: error)
    }
}

extension ApplicationCoordinator: RecordingServiceDelegate {
    func recordingService(_ service: RecordingService, didStartRecording: Bool) {
        switch menuBarViewModel.currentRecordingType {
        case .transcribeOnly:
            popupViewModel.showPopup(text: "録音中... ⌘ + ⌥ + ⇧ + R で停止")
        case .transcribeAndTranslate:
            popupViewModel.showPopup(text: "録音中（翻訳付き）... ⌘ + ⌥ + ⇧ + E で停止")
        }
    }
    
    func recordingService(_ service: RecordingService, didStopRecording audioURL: URL?) {
        if let url = audioURL {
            print("録音ファイル: \(url.path)")
            switch menuBarViewModel.currentRecordingType {
            case .transcribeOnly:
                openAIService.transcribeAudio(from: url)
            case .transcribeAndTranslate:
                openAIService.transcribeAndTranslateAudio(from: url)
            }
        }
    }
    
    func recordingService(_ service: RecordingService, didFailWithError error: String) {
        popupViewModel.showPopup(text: error)
        // 録音エラー時は状態をリセット
        menuBarViewModel.setRecordingState(false)
    }
}

extension ApplicationCoordinator: PermissionManagerDelegate {
    func permissionManager(_ manager: PermissionManager, accessibilityPermissionGranted: Bool) {
        if accessibilityPermissionGranted {
            setupMainApp()
        }
    }
    
    func permissionManager(_ manager: PermissionManager, microphonePermissionGranted: Bool) {
        if microphonePermissionGranted {
            print("マイクロフォン権限が許可された")
        }
    }
}

// MARK: - UI Manager Delegates
extension ApplicationCoordinator: StatusBarManagerDelegate {
    func statusBarManager(_ manager: StatusBarManager, didSelectTestTranslation: Void) {
        executeTestTranslation()
    }
    
    func statusBarManager(_ manager: StatusBarManager, didSelectTestRecording: Void) {
        executeTestRecording()
    }
    
    func statusBarManager(_ manager: StatusBarManager, didSelectAPIKeySettings: Void) {
        executeShowAPIKeySettings()
    }
    
    func statusBarManager(_ manager: StatusBarManager, didToggleLaunchAtLogin: Void) {
        executeToggleLaunchAtLogin()
    }
}

extension ApplicationCoordinator: SettingsWindowDelegate {
    func settingsWindow(_ window: SettingsWindow, didSaveAPIKey key: String) {
        print("APIキーが保存された")
    }
    
    func settingsWindow(_ window: SettingsWindow, didDeleteAPIKey: Void) {
        print("APIキーが削除された")
    }
    
    func settingsWindow(_ window: SettingsWindow, didShowMessage message: String) {
        popupViewModel.showPopup(text: message)
    }
}

extension ApplicationCoordinator: GlobalHotKeyManagerDelegate {
    func globalHotKeyManager(_ manager: GlobalHotKeyManager, didTriggerTranslation: Void) {
        executeTranslateSelectedText()
    }
    
    func globalHotKeyManager(_ manager: GlobalHotKeyManager, didTriggerRecording: Void) {
        executeToggleRecording()
    }
    
    func globalHotKeyManager(_ manager: GlobalHotKeyManager, didTriggerTranscribeAndTranslate: Void) {
        executeTranscribeAndTranslateRecording()
    }
}

extension ApplicationCoordinator: ClipboardManagerDelegate {
    func clipboardManager(_ manager: ClipboardManager, didCopyText text: String) {
        openAIService.translateText(text)
    }
    
    func clipboardManager(_ manager: ClipboardManager, didFailToCopyText: Void) {
        popupViewModel.showPopup(text: "テキストが選択されていない")
    }
}
