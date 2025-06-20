# LLM Text Translator

A macOS menu bar application that provides real-time text translation and voice transcription using OpenAI's GPT and Whisper APIs.

## Features

### 🌐 Text Translation
- Translate selected text between English and Japanese automatically
- Uses OpenAI's GPT model for high-quality translations
- Quick access via keyboard shortcut
- Results displayed in floating popup windows
- Automatic clipboard copy of translation results

### 🎤 Voice Recording & Transcription
- Record audio and convert speech to text using Whisper API
- Automatic filler word removal for cleaner transcriptions
- Support for Japanese language recognition
- Toggle recording with keyboard shortcut

### 📱 Menu Bar Integration
- Lightweight menu bar app with globe icon (🌐)
- Test functions available through menu
- Clean, minimal interface

## System Requirements

- macOS 10.14 or later
- Microphone access for voice features
- Internet connection for API calls
- Valid OpenAI API key

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/megane9988/LLMTextTranslator.git
   cd LLMTextTranslator
   ```

2. Open `LLMTextTranslator.xcodeproj` in Xcode

3. Build and run the project

## Setup

### API Key Configuration

⚠️ **Important**: You need to configure your OpenAI API key before using the app.

Currently, the API key is hardcoded in the source code. For security reasons, you should:

1. Open `LLMTextTranslator/AppDelegate.swift`
2. Replace the hardcoded API key in both `callOpenAI` and `transcribeAudio` functions with your own key
3. Consider using environment variables or a secure configuration file instead

**Recommended**: Store your API key in an environment variable:
```swift
let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
```

### Permissions

The app requires the following permissions:

#### 1. Accessibility Permission
- Required for global keyboard shortcuts and text selection
- The app will prompt you to enable this in System Preferences
- Go to: System Preferences → Security & Privacy → Privacy → Accessibility
- Add and enable "LLM Text Translator"

#### 2. Microphone Permission
- Required for voice recording features
- The app will request this permission automatically
- If denied, go to: System Preferences → Security & Privacy → Privacy → Microphone
- Enable "LLM Text Translator"

## Usage

### Text Translation

1. Select any text in any application
2. Press `⌘ + ⌥ + ⇧ + T`
3. The selected text will be copied and translated
4. Translation result appears in a floating popup window
5. The result is automatically copied to your clipboard

**Note**: The app automatically detects the language and translates between English and Japanese.

### Voice Recording

1. Press `⌘ + ⌥ + ⇧ + R` to start recording
2. Speak into your microphone
3. Press the same shortcut again to stop recording
4. The transcribed text will appear in a floating popup window
5. The result is automatically copied to your clipboard

### Menu Bar Options

Click the globe icon (🌐) in your menu bar to access:
- **Test Translation**: Test the translation feature
- **Test Recording**: Test the recording feature
- **Quit**: Exit the application

## Keyboard Shortcuts

| Shortcut | Function |
|----------|----------|
| `⌘ + ⌥ + ⇧ + T` | Translate selected text |
| `⌘ + ⌥ + ⇧ + R` | Toggle voice recording |

## Troubleshooting

### "Accessibility permission required" message
- Go to System Preferences → Security & Privacy → Privacy → Accessibility
- Click the lock icon and enter your password
- Add "LLM Text Translator" to the list and check the box

### "Microphone permission required" message
- Go to System Preferences → Security & Privacy → Privacy → Microphone
- Add "LLM Text Translator" to the list and check the box

### Translation not working
- Ensure you have a valid OpenAI API key configured
- Check your internet connection
- Verify that text is properly selected before using the shortcut

### Recording not working
- Check microphone permissions
- Ensure your microphone is working in other applications
- Verify OpenAI API key is configured

### API Error Messages
- "Network Error": Check your internet connection
- "Invalid API Key": Verify your OpenAI API key is correct and has sufficient credits

## Development

### Project Structure
```
LLMTextTranslator/
├── AppDelegate.swift          # Main application logic
├── LLMTextTranslatorApp.swift # App entry point
├── ContentView.swift          # SwiftUI view (minimal)
├── Info.plist                 # App configuration
└── LLMTextTranslator.entitlements # Security entitlements
```

### Key Components

- **AppDelegate.swift**: Contains all the main functionality including API calls, recording, and UI management
- **Menu Bar Integration**: Uses `NSStatusItem` for menu bar presence
- **Global Shortcuts**: Implemented using `NSEvent.addGlobalMonitorForEvents`
- **API Integration**: Direct HTTP calls to OpenAI's APIs
- **Permissions**: Handles accessibility and microphone permissions

### Building from Source

1. Ensure you have Xcode installed
2. Open the project in Xcode
3. Configure your development team in project settings
4. Build and run

## Security Notes

- The app requires accessibility permissions to monitor global keystrokes
- Microphone access is needed for voice recording
- API keys should be stored securely, not hardcoded
- The app runs as a background menu bar application

## License

Copyright © 2025 9988 megane. All rights reserved.

## Contributing

This project uses OpenAI's APIs for translation and transcription. Make sure you have appropriate API access and understand OpenAI's usage policies.

---

**Note**: This app is designed for personal use and development purposes. Ensure you comply with OpenAI's terms of service and usage policies when using their APIs.

---

## 日本語版説明 (Japanese Documentation)

### 概要
LLM Text Translatorは、OpenAIのGPTとWhisper APIを使用して、リアルタイムでテキスト翻訳と音声文字起こしを行うmacOSメニューバーアプリケーションです。

### 主な機能
- **テキスト翻訳**: 選択したテキストを英語と日本語間で自動翻訳
- **音声録音・文字起こし**: 音声をテキストに変換（フィラー音除去機能付き）
- **メニューバー統合**: 軽量で使いやすいメニューバーアプリ

### キーボードショートカット
- `⌘ + ⌥ + ⇧ + T`: 選択したテキストを翻訳
- `⌘ + ⌥ + ⇧ + R`: 音声録音の開始/停止

### 必要な権限
1. **アクセシビリティ権限**: システム環境設定 → セキュリティとプライバシー → プライバシー → アクセシビリティ
2. **マイクロフォン権限**: システム環境設定 → セキュリティとプライバシー → プライバシー → マイクロフォン

### セットアップ
1. OpenAI APIキーを取得
2. `AppDelegate.swift`内のAPIキーを自分のキーに置き換え
3. アプリをビルドして実行

詳細については上記の英語版ドキュメントをご参照ください。