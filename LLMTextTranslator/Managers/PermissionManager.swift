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
        
        let trusted = AXIsProcessTrusted()
        print("アクセシビリティ権限状態: \(trusted)")
        
        if !trusted {
            print("アクセシビリティ権限が必要だ")
            requestAccessibilityPermission()
        } else {
            print("アクセシビリティ権限は既に許可されている")
            delegate?.permissionManager(self, accessibilityPermissionGranted: true)
        }
    }
    
    private func requestAccessibilityPermission() {
        // 最初にプロンプトありで権限要求
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
        let promptResult = AXIsProcessTrustedWithOptions(options as CFDictionary)
        print("プロンプト後の権限状態: \(promptResult)")
        
        if promptResult {
            print("権限が即座に許可された")
            delegate?.permissionManager(self, accessibilityPermissionGranted: true)
            return
        }
        
        // アラート表示
        showAccessibilityAlert()
        
        // タイマーでチェック
        startPermissionTimer()
    }
    
    private func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "アクセシビリティ権限が必要"
        alert.informativeText = "システム環境設定でアプリを許可した後、アプリを再起動してください"
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "設定を開く")
        
        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        }
    }
    
    private func startPermissionTimer() {
        var checkCount = 0
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            checkCount += 1
            print("権限チェック中... (\(checkCount)/\(self.maxCheckCount))")
            
            if AXIsProcessTrusted() {
                print("アクセシビリティ権限が許可された！")
                timer.invalidate()
                self.permissionTimer = nil
                DispatchQueue.main.async {
                    self.delegate?.permissionManager(self, accessibilityPermissionGranted: true)
                }
            } else if checkCount >= self.maxCheckCount {
                print("権限チェックタイムアウト。アプリを再起動してください。")
                timer.invalidate()
                self.permissionTimer = nil
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
