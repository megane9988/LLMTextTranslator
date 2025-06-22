import Foundation
import Combine

@MainActor
class MenuBarViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var isLaunchAtLoginEnabled = false
    
    // 依存関係
    private let launchAtLoginManager: LaunchAtLoginManager
    private var cancellables = Set<AnyCancellable>()
    
    init(launchAtLoginManager: LaunchAtLoginManager = LaunchAtLoginManager.shared) {
        self.launchAtLoginManager = launchAtLoginManager
        self.isLaunchAtLoginEnabled = launchAtLoginManager.isEnabled
        
        // 自動起動設定の変更を監視
        setupBindings()
    }
    
    private func setupBindings() {
        // 自動起動設定の変更を監視
        $isLaunchAtLoginEnabled
            .dropFirst() // 初期値をスキップ
            .sink { [weak self] newValue in
                self?.updateLaunchAtLoginSetting(enabled: newValue)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - アクション処理
    func testTranslation() {
        print("テスト翻訳アクションが実行された")
        // デリゲートやコールバックで通知
    }
    
    func testRecording() {
        print("テスト録音アクションが実行された")
        toggleRecording()
    }
    
    func showAPIKeySettings() {
        print("APIキー設定アクションが実行された")
    }
    
    func toggleLaunchAtLogin() {
        print("自動起動設定切り替えアクションが実行された")
        isLaunchAtLoginEnabled.toggle()
    }
    
    // MARK: - 録音状態管理
    func setRecordingState(_ recording: Bool) {
        isRecording = recording
        print("録音状態を更新: \(recording)")
    }
    
    func toggleRecording() {
        isRecording.toggle()
        print("録音状態を切り替え: \(isRecording)")
    }
    
    // MARK: - 自動起動設定管理
    private func updateLaunchAtLoginSetting(enabled: Bool) {
        launchAtLoginManager.setEnabled(enabled)
        print("自動起動設定を更新: \(enabled)")
    }
    
    func refreshLaunchAtLoginState() {
        isLaunchAtLoginEnabled = launchAtLoginManager.isEnabled
        print("自動起動設定を同期: \(isLaunchAtLoginEnabled)")
    }
    
    // MARK: - ステータス情報
    var statusIcon: String {
        return isRecording ? "🔴" : "🌐"
    }
    
    var launchAtLoginMenuState: Bool {
        return isLaunchAtLoginEnabled
    }
    
    // MARK: - クリーンアップ
    deinit {
        cancellables.removeAll()
    }
}
