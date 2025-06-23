import Foundation

protocol OpenAIServiceDelegate: AnyObject {
    func openAIService(_ service: OpenAIService, didReceiveTranslation translation: String)
    func openAIService(_ service: OpenAIService, didReceiveTranscription transcription: String)
    func openAIService(_ service: OpenAIService, didFailWithError error: String)
    func openAIService(_ service: OpenAIService, didStartTranslation: Void)
    func openAIService(_ service: OpenAIService, didStartTranscription: Void)
}

class OpenAIService {
    weak var delegate: OpenAIServiceDelegate?
    
    private let baseURL = "https://api.openai.com/v1"
    
    // MARK: - 翻訳機能
    func translateText(_ text: String) {
        print("OpenAI API を呼び出し中...")
        
        // 開始を通知
        delegate?.openAIService(self, didStartTranslation: ())
        
        guard let apiKey = KeychainHelper.shared.getAPIKey() else {
            print("APIキーが設定されていない")
            delegate?.openAIService(self, didFailWithError: "APIキーが設定されていません。アプリのメニューから設定してください。")
            return
        }
        
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            print("URL作成に失敗")
            delegate?.openAIService(self, didFailWithError: "URL作成に失敗")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // プロンプトを作成し、翻訳結果のみを返すよう指示
        let prompt = "Translate the following text between English and Japanese depending on its original language. Return only the translated text without any explanations, notes, or other content:\n\(text)"
        let json: [String: Any] = [
            "model": "gpt-4.1-nano",
            "messages": [
                ["role": "system", "content": "You are a translator."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: json)
        } catch {
            print("JSON作成エラー: \(error)")
            delegate?.openAIService(self, didFailWithError: "JSON作成エラー")
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("ネットワークエラー: \(error)")
                DispatchQueue.main.async {
                    self.delegate?.openAIService(self, didFailWithError: "ネットワークエラー")
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTPステータス: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("データがない")
                DispatchQueue.main.async {
                    self.delegate?.openAIService(self, didFailWithError: "データがない")
                }
                return
            }
            
            do {
                if let result = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("APIレスポンス: \(result)")
                    
                    if let choices = result["choices"] as? [[String: Any]],
                       let message = choices.first?["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        DispatchQueue.main.async {
                            self.delegate?.openAIService(self, didReceiveTranslation: content.trimmingCharacters(in: .whitespacesAndNewlines))
                        }
                    } else if let error = result["error"] as? [String: Any] {
                        print("API エラー: \(error)")
                        DispatchQueue.main.async {
                            self.delegate?.openAIService(self, didFailWithError: "API エラー")
                        }
                    }
                }
            } catch {
                print("JSON解析エラー: \(error)")
                DispatchQueue.main.async {
                    self.delegate?.openAIService(self, didFailWithError: "JSON解析エラー")
                }
            }
        }.resume()
    }
    
    // MARK: - 音声文字起こし+翻訳機能
    func transcribeAndTranslateAudio(from audioURL: URL) {
        print("Whisper API で文字起こし＋翻訳中...")
        
        // 開始を通知
        delegate?.openAIService(self, didStartTranscription: ())
        
        guard let apiKey = KeychainHelper.shared.getAPIKey() else {
            print("APIキーが設定されていない")
            delegate?.openAIService(self, didFailWithError: "APIキーが設定されていません。")
            return
        }
        
        guard let url = URL(string: "\(baseURL)/audio/transcriptions") else {
            print("URL作成に失敗")
            delegate?.openAIService(self, didFailWithError: "URL作成に失敗")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var data = Data()
        
        // モデルパラメータ
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        data.append("whisper-1\r\n".data(using: .utf8)!)
        
        // 言語パラメータ
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        data.append("ja\r\n".data(using: .utf8)!)
        
        // プロンプトパラメータ
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
        data.append("Remove filler sounds and meaningless interjections, and convert it into clear and easy-to-read text.".data(using: .utf8)!)
        data.append("\r\n".data(using: .utf8)!)
        
        // ファイルデータ
        do {
            let audioData = try Data(contentsOf: audioURL)
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: audio/mp4\r\n\r\n".data(using: .utf8)!)
            data.append(audioData)
            data.append("\r\n".data(using: .utf8)!)
        } catch {
            print("音声ファイル読み込みエラー: \(error)")
            delegate?.openAIService(self, didFailWithError: "音声ファイル読み込みエラー")
            return
        }
        
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = data
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("ネットワークエラー: \(error)")
                DispatchQueue.main.async {
                    self.delegate?.openAIService(self, didFailWithError: "ネットワークエラー")
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTPステータス: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("データがない")
                DispatchQueue.main.async {
                    self.delegate?.openAIService(self, didFailWithError: "データがない")
                }
                return
            }
            
            do {
                if let result = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("Whisper APIレスポンス: \(result)")
                    
                    if let text = result["text"] as? String {
                        // 文字起こし成功後、翻訳を実行
                        DispatchQueue.main.async {
                            self.translateText(text)
                        }
                    } else if let error = result["error"] as? [String: Any] {
                        print("Whisper API エラー: \(error)")
                        DispatchQueue.main.async {
                            self.delegate?.openAIService(self, didFailWithError: "文字起こしエラー")
                        }
                    }
                }
            } catch {
                print("JSON解析エラー: \(error)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("レスポンス内容: \(responseString)")
                }
                DispatchQueue.main.async {
                    self.delegate?.openAIService(self, didFailWithError: "JSON解析エラー")
                }
            }
            
            // 一時ファイルを削除
            DispatchQueue.main.async {
                try? FileManager.default.removeItem(at: audioURL)
            }
        }.resume()
    }
    
    // MARK: - 音声文字起こし機能
    func transcribeAudio(from audioURL: URL) {
        print("Whisper API で文字起こし中...")
        
        // 開始を通知
        delegate?.openAIService(self, didStartTranscription: ())
        
        guard let apiKey = KeychainHelper.shared.getAPIKey() else {
            print("APIキーが設定されていない")
            delegate?.openAIService(self, didFailWithError: "APIキーが設定されていません。")
            return
        }
        
        guard let url = URL(string: "\(baseURL)/audio/transcriptions") else {
            print("URL作成に失敗")
            delegate?.openAIService(self, didFailWithError: "URL作成に失敗")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var data = Data()
        
        // モデルパラメータ
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        data.append("whisper-1\r\n".data(using: .utf8)!)
        
        // 言語パラメータ
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        data.append("ja\r\n".data(using: .utf8)!)
        
        // プロンプトパラメータ
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
        data.append("Remove filler sounds and meaningless interjections, and convert it into clear and easy-to-read text.".data(using: .utf8)!)
        data.append("\r\n".data(using: .utf8)!)
        
        // ファイルデータ
        do {
            let audioData = try Data(contentsOf: audioURL)
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: audio/mp4\r\n\r\n".data(using: .utf8)!)
            data.append(audioData)
            data.append("\r\n".data(using: .utf8)!)
        } catch {
            print("音声ファイル読み込みエラー: \(error)")
            delegate?.openAIService(self, didFailWithError: "音声ファイル読み込みエラー")
            return
        }
        
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = data
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("ネットワークエラー: \(error)")
                DispatchQueue.main.async {
                    self.delegate?.openAIService(self, didFailWithError: "ネットワークエラー")
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTPステータス: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("データがない")
                DispatchQueue.main.async {
                    self.delegate?.openAIService(self, didFailWithError: "データがない")
                }
                return
            }
            
            do {
                if let result = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("Whisper APIレスポンス: \(result)")
                    
                    if let text = result["text"] as? String {
                        DispatchQueue.main.async {
                            self.delegate?.openAIService(self, didReceiveTranscription: text)
                        }
                    } else if let error = result["error"] as? [String: Any] {
                        print("Whisper API エラー: \(error)")
                        DispatchQueue.main.async {
                            self.delegate?.openAIService(self, didFailWithError: "文字起こしエラー")
                        }
                    }
                }
            } catch {
                print("JSON解析エラー: \(error)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("レスポンス内容: \(responseString)")
                }
                DispatchQueue.main.async {
                    self.delegate?.openAIService(self, didFailWithError: "JSON解析エラー")
                }
            }
            
            // 一時ファイルを削除
            DispatchQueue.main.async {
                try? FileManager.default.removeItem(at: audioURL)
            }
        }.resume()
    }
}
