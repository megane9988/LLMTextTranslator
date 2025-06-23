import Foundation
import Combine

@MainActor
class PopupViewModel: ObservableObject {
    @Published var isVisible = false
    @Published var currentText = ""
    @Published var currentTitle = "Translation Result"
    @Published var isTranslating = false // 翻訳実行状態
    @Published var isTranscribing = false // 文字起こし実行状態
    
    // 設定
    @Published var windowWidth: CGFloat = 600
    @Published var windowHeight: CGFloat = 400
    
    // MARK: - ポップアップ表示
    func showPopup(text: String, title: String = "Translation Result") {
        currentText = text
        currentTitle = title
        isVisible = true
        
        print("PopupViewModel: ポップアップを表示 - \(text)")
    }
    
    // MARK: - ポップアップ非表示
    func hidePopup() {
        isVisible = false
        print("PopupViewModel: ポップアップを非表示")
    }
    
    
    // MARK: - ウィンドウサイズ変更
    func updateWindowSize(width: CGFloat, height: CGFloat) {
        windowWidth = width
        windowHeight = height
        print("PopupViewModel: ウィンドウサイズを更新 \(width) x \(height)")
    }
    
    
    // MARK: - 実行状態管理
    func setTranslatingState(_ translating: Bool) {
        isTranslating = translating
        if translating {
            showProcessingPopup(type: .translation)
        }
        print("PopupViewModel: 翻訳状態を更新 - \(translating)")
    }
    
    func setTranscribingState(_ transcribing: Bool) {
        isTranscribing = transcribing
        if transcribing {
            showProcessingPopup(type: .transcription)
        }
        print("PopupViewModel: 文字起こし状態を更新 - \(transcribing)")
    }
    
    private enum ProcessingType {
        case translation
        case transcription
        
        var message: String {
            switch self {
            case .translation: return "翻訳中..."
            case .transcription: return "音声を文字起こし中..."
            }
        }
        
        var icon: String {
            switch self {
            case .translation: return "🔄"
            case .transcription: return "🎙️"
            }
        }
    }
    
    private func showProcessingPopup(type: ProcessingType) {
        showPopup(text: "\(type.icon) \(type.message)", title: "処理中")
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
    
}
