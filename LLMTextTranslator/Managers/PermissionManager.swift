import Foundation
import AVFoundation
import Cocoa

protocol PermissionManagerDelegate: AnyObject {
    func permissionManager(_ manager: PermissionManager, accessibilityPermissionGranted: Bool)
    func permissionManager(_ manager: PermissionManager, microphonePermissionGranted: Bool)
}

class PermissionManager {
    static let shared = PermissionManager()
    weak var delegate: PermissionManagerDelegate?
    
    private var permissionTimer: Timer?
    private let maxCheckCount = 30
    
    private init() {}
    
    // MARK: - アクセシビリティ権限チェック
    func checkAccessibilityPermission() {
        let bundleID = Bundle.main.bundleIdentifier ?? "Unknown"
        print("Bundle ID: \(bundleID)")
        
        // まずは現在の権限状態をチェック
        let trusted = AXIsProcessTrusted()
        print("アクセシビリティ権限状態: \(trusted)")
        
        if trusted {
            print("アクセシビリティ権限は既に許可されている")
            delegate?.permissionManager(self, accessibilityPermissionGranted: true)
        } else {
            print("アクセシビリティ権限が必要だ")
            requestAccessibilityPermission()
        }
    }
    
    private func requestAccessibilityPermission() {
        // システム環境設定を開く前に一度チェック
        if AXIsProcessTrusted() {
            delegate?.permissionManager(self, accessibilityPermissionGranted: true)
            return
        }
        
        // アラート表示
        showAccessibilityAlert()
        
        // プロンプトありで権限要求（アラート後）
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
        let promptResult = AXIsProcessTrustedWithOptions(options as CFDictionary)
        print("プロンプト後の権限状態: \(promptResult)")
        
        if promptResult {
            print("権限が即座に許可された")
            delegate?.permissionManager(self, accessibilityPermissionGranted: true)
            return
        }
        
        // タイマーでチェック
        startPermissionTimer()
    }
    
    private func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "アクセシビリティ権限が必要"
        alert.informativeText = """
        このアプリを使用するには、システム環境設定でアクセシビリティ権限を許可する必要があります。
        
        1. 「設定を開く」をクリック
        2. 左側の「プライバシーとセキュリティ」を選択
        3. 「アクセシビリティ」を選択
        4. 「LLM Text Translator」をチェック
        
        注意：許可後は自動的に権限が有効になります。
        """
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "設定を開く")
        
        DispatchQueue.main.async {
            let response = alert.runModal()
            if response == .alertSecondButtonReturn {
                if #available(macOS 13.0, *) {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                } else {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security")!)
                }
            }
        }
    }
    
    private func startPermissionTimer() {
        var checkCount = 0
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            checkCount += 1
            
            if AXIsProcessTrusted() {
                print("アクセシビリティ権限が許可された！")
                timer.invalidate()
                self.permissionTimer = nil
                DispatchQueue.main.async {
                    self.delegate?.permissionManager(self, accessibilityPermissionGranted: true)
                }
            } else if checkCount >= self.maxCheckCount {
                print("権限チェックタイムアウト。手動で権限を確認してください。")
                timer.invalidate()
                self.permissionTimer = nil
                // タイムアウト後も定期的にチェックを継続
                self.scheduleBackgroundPermissionCheck()
            }
        }
    }
    
    private func scheduleBackgroundPermissionCheck() {
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            if AXIsProcessTrusted() {
                print("バックグラウンドチェック: アクセシビリティ権限が許可された！")
                timer.invalidate()
                DispatchQueue.main.async {
                    self.delegate?.permissionManager(self, accessibilityPermissionGranted: true)
                }
            }
        }
    }
    
    // MARK: - マイクロフォン権限チェック
    func checkMicrophonePermission() {
        if #available(macOS 10.14, *) {
            switch AVCaptureDevice.authorizationStatus(for: .audio) {
            case .authorized:
                print("マイクロフォン権限は既に許可済み")
                delegate?.permissionManager(self, microphonePermissionGranted: true)
            case .denied, .restricted:
                print("マイクロフォン権限が拒否されている")
                showMicrophoneAlert()
            case .notDetermined:
                requestMicrophonePermission()
            @unknown default:
                print("不明なマイクロフォン権限状態")
            }
        }
    }
    
    private func requestMicrophonePermission() {
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    print("マイクロフォン権限が許可された")
                    self?.delegate?.permissionManager(self!, microphonePermissionGranted: true)
                } else {
                    print("マイクロフォン権限が拒否された")
                    self?.showMicrophoneAlert()
                }
            }
        }
    }
    
    private func showMicrophoneAlert() {
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
    
    // MARK: - 権限状態確認
    var hasAccessibilityPermission: Bool {
        return AXIsProcessTrusted()
    }
    
    var hasMicrophonePermission: Bool {
        if #available(macOS 10.14, *) {
            return AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        }
        return true
    }
}
