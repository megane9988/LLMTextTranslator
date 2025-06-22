import Foundation
import Combine

@MainActor
class PopupViewModel: ObservableObject {
    @Published var isVisible = false
    @Published var currentText = ""
    @Published var currentTitle = "Translation Result"
    
    // 設定
    @Published var autoCloseDelay: TimeInterval = 8.0
    @Published var windowWidth: CGFloat = 600
    @Published var windowHeight: CGFloat = 400
    
    private var autoCloseTimer: Timer?
    
    // MARK: - ポップアップ表示
    func showPopup(text: String, title: String = "Translation Result") {
        // 既存のタイマーをクリア
        autoCloseTimer?.invalidate()
        
        currentText = text
        currentTitle = title
        isVisible = true
        
        print("PopupViewModel: ポップアップを表示 - \(text)")
        
        // 自動クローズタイマーを設定
        scheduleAutoClose()
    }
    
    // MARK: - ポップアップ非表示
    func hidePopup() {
        isVisible = false
        autoCloseTimer?.invalidate()
        print("PopupViewModel: ポップアップを非表示")
    }
    
    // MARK: - 自動クローズ
    private func scheduleAutoClose() {
        autoCloseTimer = Timer.scheduledTimer(withTimeInterval: autoCloseDelay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.hidePopup()
            }
        }
    }
    
    // MARK: - タイマー管理
    func cancelAutoClose() {
        autoCloseTimer?.invalidate()
        autoCloseTimer = nil
        print("PopupViewModel: 自動クローズをキャンセル")
    }
    
    func restartAutoClose() {
        scheduleAutoClose()
        print("PopupViewModel: 自動クローズを再開")
    }
    
    // MARK: - ウィンドウサイズ変更
    func updateWindowSize(width: CGFloat, height: CGFloat) {
        windowWidth = width
        windowHeight = height
        print("PopupViewModel: ウィンドウサイズを更新 \(width) x \(height)")
    }
    
    // MARK: - 設定変更
    func setAutoCloseDelay(_ delay: TimeInterval) {
        autoCloseDelay = delay
        print("PopupViewModel: 自動クローズ時間を更新: \(delay)秒")
    }
    
    // MARK: - ユーティリティ
    var textLength: Int {
        return currentText.count
    }
    
    var hasLongText: Bool {
        return textLength > 500
    }
    
    var recommendedHeight: CGFloat {
        // テキストの長さに応じて推奨高さを計算
        let baseHeight: CGFloat = 200
        let extraHeight = CGFloat(textLength / 100) * 50
        return min(baseHeight + extraHeight, 800) // 最大800px
    }
    
    // MARK: - クリーンアップ
    deinit {
        autoCloseTimer?.invalidate()
    }
}
