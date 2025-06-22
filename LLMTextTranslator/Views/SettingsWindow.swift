import Cocoa

protocol SettingsWindowDelegate: AnyObject {
    func settingsWindow(_ window: SettingsWindow, didSaveAPIKey key: String)
    func settingsWindow(_ window: SettingsWindow, didDeleteAPIKey: Void)
    func settingsWindow(_ window: SettingsWindow, didShowMessage message: String)
}

class SettingsWindow {
    weak var delegate: SettingsWindowDelegate?
    
    // MARK: - APIキー設定画面表示
    func showAPIKeySettings() {
        let alert = NSAlert()
        alert.messageText = "OpenAI APIキー設定"
        alert.informativeText = "OpenAI APIキーを入力してください。このキーはKeychainに安全に保存されます。"
        alert.addButton(withTitle: "保存")
        alert.addButton(withTitle: "キャンセル")
        
        let textField = createAPIKeyTextField()
        alert.accessoryView = textField
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            handleAPIKeySave(from: textField)
        } else {
            print("APIキー設定がキャンセルされた")
        }
    }
    
    private func createAPIKeyTextField() -> NSTextField {
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 20))
        
        // 現在のAPIキーを表示
        textField.stringValue = KeychainHelper.shared.getAPIKey() ?? ""
        textField.placeholderString = "sk-proj-..."
        
        // セキュリティのため、パスワードフィールドとして設定することも可能
        // textField.isSecureTextEntry = true // 必要に応じてコメントアウト
        
        return textField
    }
    
    private func handleAPIKeySave(from textField: NSTextField) {
        let apiKey = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if apiKey.isEmpty {
            // 空の場合は削除
            handleAPIKeyDeletion()
        } else {
            // 保存
            handleAPIKeySave(apiKey: apiKey)
        }
    }
    
    private func handleAPIKeyDeletion() {
        if KeychainHelper.shared.deleteAPIKey() {
            print("APIキーを削除した")
            delegate?.settingsWindow(self, didDeleteAPIKey: ())
            delegate?.settingsWindow(self, didShowMessage: "APIキーを削除しました")
        } else {
            print("APIキーの削除に失敗")
            delegate?.settingsWindow(self, didShowMessage: "APIキーの削除に失敗しました")
        }
    }
    
    private func handleAPIKeySave(apiKey: String) {
        // APIキーの基本的なバリデーション
        if !isValidAPIKeyFormat(apiKey) {
            print("無効なAPIキー形式")
            delegate?.settingsWindow(self, didShowMessage: "無効なAPIキー形式です。sk- で始まる正しいキーを入力してください。")
            return
        }
        
        if KeychainHelper.shared.saveAPIKey(apiKey) {
            print("APIキーを保存した")
            delegate?.settingsWindow(self, didSaveAPIKey: apiKey)
            delegate?.settingsWindow(self, didShowMessage: "APIキーを保存しました")
        } else {
            print("APIキーの保存に失敗")
            delegate?.settingsWindow(self, didShowMessage: "APIキーの保存に失敗しました")
        }
    }
    
    // MARK: - バリデーション
    private func isValidAPIKeyFormat(_ key: String) -> Bool {
        // OpenAI APIキーの基本的な形式チェック
        // sk-proj- または sk- で始まり、適切な長さを持つ
        return key.hasPrefix("sk-") && key.count > 20
    }
    
    // MARK: - 確認ダイアログ
    func showConfirmationDialog(title: String, message: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "はい")
        alert.addButton(withTitle: "いいえ")
        alert.alertStyle = .warning
        
        let response = alert.runModal()
        return response == .alertFirstButtonReturn
    }
    
    // MARK: - エラーダイアログ
    func showErrorDialog(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.alertStyle = .critical
        
        alert.runModal()
    }
    
    // MARK: - 情報ダイアログ
    func showInfoDialog(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.alertStyle = .informational
        
        alert.runModal()
    }
    
    // MARK: - APIキー管理機能
    func getCurrentAPIKey() -> String? {
        return KeychainHelper.shared.getAPIKey()
    }
    
    func hasAPIKey() -> Bool {
        return getCurrentAPIKey() != nil
    }
    
    func clearAPIKey() -> Bool {
        return KeychainHelper.shared.deleteAPIKey()
    }
}
