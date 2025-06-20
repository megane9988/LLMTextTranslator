//
//  LaunchAtLoginManager.swift
//  LLMTextTranslator
//
//  Created by 9988 megane on 2025/06/21.
//

import SwiftUI
import ServiceManagement

@MainActor
class LaunchAtLoginManager: ObservableObject {
    static let shared = LaunchAtLoginManager()
    
    @Published var isEnabled: Bool = false
    
    private init() {
        checkStatus()
    }
    
    /// 現在の自動起動状態をチェック
    func checkStatus() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }
    
    /// 自動起動の有効/無効を切り替え
    func toggle() {
        setEnabled(!isEnabled)
    }
    
    /// 自動起動を設定
    /// - Parameter enabled: 有効にするかどうか
    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
                print("自動起動を有効にした")
            } else {
                try SMAppService.mainApp.unregister()
                print("自動起動を無効にした")
            }
            // 状態を更新
            checkStatus()
        } catch {
            print("自動起動設定に失敗: \(error.localizedDescription)")
            // エラーが発生した場合は状態を再確認
            checkStatus()
        }
    }
}
