import Foundation
import AVFoundation
import AudioToolbox

protocol RecordingServiceDelegate: AnyObject {
    func recordingService(_ service: RecordingService, didStartRecording: Bool)
    func recordingService(_ service: RecordingService, didStopRecording audioURL: URL?)
    func recordingService(_ service: RecordingService, didFailWithError error: String)
}

class RecordingService: NSObject {
    weak var delegate: RecordingServiceDelegate?
    
    private var audioRecorder: AVAudioRecorder?
    private var isRecording = false
    private var recordingURL: URL?
    
    // MARK: - 音声フィードバック
    private func playStartSound() {
        AudioServicesPlaySystemSound(1113) // Sound for start
    }
    
    private func playStopSound() {
        AudioServicesPlaySystemSound(1114) // Sound for stop
    }
    
    var recordingState: Bool {
        return isRecording
    }
    
    // MARK: - 録音開始
    func startRecording() {
        print("録音開始")
        
        // 一時ファイルのURL
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        recordingURL = documentsPath.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
        
        // 録音設定（macOS用）
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            guard let url = recordingURL else {
                delegate?.recordingService(self, didFailWithError: "録音URL作成に失敗")
                return
            }
            
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            isRecording = true
            
            playStartSound() // 録音開始音
            print("録音中...")
            delegate?.recordingService(self, didStartRecording: true)
            
        } catch {
            print("録音開始エラー: \(error)")
            delegate?.recordingService(self, didFailWithError: "録音開始エラー: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 録音停止
    func stopRecording() {
        print("録音停止")
        
        audioRecorder?.stop()
        isRecording = false
        
        playStopSound() // 録音停止音
        
        if let url = recordingURL {
            print("録音ファイル: \(url.path)")
            delegate?.recordingService(self, didStopRecording: url)
        } else {
            delegate?.recordingService(self, didStopRecording: nil)
        }
    }
    
    // MARK: - 録音切り替え
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
}

// MARK: - AVAudioRecorderDelegate
extension RecordingService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("録音完了: \(flag)")
        if !flag {
            delegate?.recordingService(self, didFailWithError: "録音が正常に完了しませんでした")
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("録音エンコードエラー: \(error?.localizedDescription ?? "不明なエラー")")
        delegate?.recordingService(self, didFailWithError: "録音エンコードエラー")
    }
}
