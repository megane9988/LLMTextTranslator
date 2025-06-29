# LLM Text Translator

OpenAIのGPTとWhisper APIを使用したmacOS専用のメニューバーアプリケーション。リアルタイムテキスト翻訳と音声文字起こし機能を提供する。

## 機能

### 🌐 テキスト翻訳
- 選択したテキストを英語⇔日本語で自動翻訳
- GPTモデルによる高品質な翻訳
- ショートカットキーで瞬時にアクセス
- フローティング ポップアップウィンドウで結果表示
- 翻訳結果の自動クリップボードコピー

### 🎙️ 音声録音・文字起こし
- Whisper APIを使用した音声テキスト変換
- フィラー音自動除去で読みやすいテキスト生成
- 日本語音声認識対応
- ショートカットキーで録音切り替え
- **文字起こし + 翻訳**: 音声を文字起こしして自動翻訳

### 📱 メニューバー統合
- 軽量メニューバーアプリ（🌐アイコン）
- メニューからテスト機能にアクセス
- クリーンでミニマルなインターフェース
- **ログイン時自動起動**: macOSログイン時にアプリを自動起動

### ⚙️ ログイン時自動起動
- macOSログイン時にアプリを自動起動する設定
- Apple純正のService Management framework (SMAppService) を使用
- セキュアでシステム統合されたアプローチ
- メニューバーから簡単に切り替え可能

## システム要件

- macOS 10.14以降
- 音声機能使用時はマイク権限が必要
- API呼び出し用のインターネット接続
- 有効なOpenAI APIキー

## インストール

1. リポジトリをクローン:
   ```bash
   git clone https://github.com/megane9988/LLMTextTranslator.git
   cd LLMTextTranslator
   ```

2. Xcodeで`LLMTextTranslator.xcodeproj`を開く

3. **署名設定（重要）**: このプロジェクトはアドホック署名用に設定されている
   - Apple Developer アカウントは不要
   - 自動的に"Sign to Run Locally"で署名される
   - 他の環境でクローンした場合も追加設定不要

4. プロジェクトをビルドして実行

### 他の環境でのセットアップ

このリポジトリを他のMacでクローンした場合：

#### 自動設定（推奨）
プロジェクトは既にアドホック署名用に設定済み：
- `CODE_SIGN_IDENTITY = "-"` （アドホック署名）
- `CODE_SIGN_STYLE = Manual`
- `DEVELOPMENT_TEAM = ""` （開発チーム不要）

**→ 追加の署名設定は不要。そのままビルド可能。**

#### 署名トラブルが発生した場合
稀に署名エラーが発生する場合は、Xcodeで以下を確認：

1. **プロジェクト設定を開く**
   - プロジェクトナビゲーターで最上位の`LLMTextTranslator`をクリック
   - `LLMTextTranslator` ターゲットを選択

2. **Signing & Capabilities タブ**
   - "Automatically manage signing" のチェックを**外す**
   - "Signing Certificate" を **"Sign to Run Locally"** に設定
   - "Team" を **"None"** に設定

3. **ビルド設定確認**
   ```
   Code Signing Identity: Sign to Run Locally
   Code Signing Style: Manual
   Development Team: (空白)
   ```

#### 配布用署名に変更する場合
将来的にアプリを配布したい場合は：
1. Apple Developer Program に登録（年額￥12,800）
2. プロジェクト設定で開発者チームを選択
3. "Automatically manage signing" を有効化
4. 配布用の署名設定に変更

**注意**: アドホック署名アプリは署名したMacでのみ動作する。他のMacで動かすには各環境でビルドが必要。

## セットアップ

### ログイン時自動起動の設定

便利なようにアプリをmacOSログイン時に自動起動させることができる:

1. **アプリを起動** - メニューバーに地球アイコン（🌐）が表示される
2. **地球アイコンをクリック** - メニューを開く
3. **「ログイン時に自動起動」を切り替え** - チェックマーク（✓）が有効状態を示す
4. **再起動不要** - 設定は即座に有効になる

**技術詳細:**
- ✅ Apple純正のService Management framework (SMAppService) を使用
- ✅ セキュアなシステムレベル統合
- ✅ macOSベストプラクティスに準拠
- ✅ メニューインターフェースから簡単に有効/無効切り替え
- ✅ 追加権限不要

### OpenAI APIキー設定

⚠️ **重要**: アプリを使用する前にOpenAI APIキーの設定が必要だ。

アプリはAPIキーを最大限のセキュリティでmacOS Keychainに安全に保存する。APIキー設定手順:

1. **アプリを起動** - メニューバーに地球アイコン（🌐）が表示される
2. **地球アイコンをクリック** - ドロップダウンメニューを開く
3. **「API Key Settings」を選択** - メニューから選択
4. **OpenAI APIキーを入力** - ダイアログボックスに入力（`sk-proj-...`で始まる）
5. **「保存」をクリック** - キーがKeychainに安全に保存される

**セキュリティ機能:**
- ✅ APIキーはmacOS Keychain（システムレベル暗号化）に保存
- ✅ ソースコードにハードコーディングされた認証情報なし
- ✅ メニューから簡単にキーの更新・削除可能
- ✅ 不正・無効キーの自動エラーハンドリング

**APIキーの更新・削除方法:**
- 同じ「API Key Settings」メニューオプションを使用
- フィールドを空にして「保存」をクリックするとキーが削除される

### 権限設定

アプリは以下の権限が必要:

#### 1. アクセシビリティ権限
- グローバルキーボードショートカットとテキスト選択に必要
- アプリがシステム環境設定での有効化を促す
- 手順: システム環境設定 → セキュリティとプライバシー → プライバシー → アクセシビリティ
- 「LLM Text Translator」を追加して有効化

#### 2. マイク権限
- 音声録音機能に必要
- アプリが自動的に権限をリクエスト
- 拒否された場合: システム環境設定 → セキュリティとプライバシー → プライバシー → マイク
- 「LLM Text Translator」を有効化

## 使用方法

### テキスト翻訳

1. 任意のアプリケーションでテキストを選択
2. `⌘ + ⌥ + ⇧ + T` を押す
3. 選択されたテキストがコピーされて翻訳される
4. フローティングポップアップウィンドウに翻訳結果が表示される
5. 結果が自動的にクリップボードにコピーされる

**注意**: アプリは言語を自動検出し、英語⇔日本語間で翻訳する。

### 音声録音・文字起こし

#### 文字起こしのみ
1. `⌘ + ⌥ + ⇧ + R` を押して録音開始
2. マイクに向かって話す
3. 同じショートカットをもう一度押して録音停止、または `ESC` キーで録音をキャンセル
4. 文字起こしされたテキストがフローティングポップアップウィンドウに表示される
5. 結果が自動的にクリップボードにコピーされる

#### 文字起こし + 翻訳
1. `⌘ + ⌥ + ⇧ + E` を押して録音開始
2. マイクに向かって話す
3. 同じショートカットをもう一度押して録音停止、または `ESC` キーで録音をキャンセル
4. 文字起こしされた後、自動的に翻訳される
5. 翻訳結果がフローティングポップアップウィンドウに表示される
6. 結果が自動的にクリップボードにコピーされる

### メニューバーオプション

メニューバーの地球アイコン（🌐）をクリックすると以下にアクセス:
- **Test Translation**: 翻訳機能のテスト
- **Test Recording**: 録音機能のテスト
- **API Key Settings**: OpenAI APIキーの安全な設定
- **ログイン時に自動起動**: ログイン時自動起動の切り替え（チェックマークでON/OFF表示）
- **Quit**: アプリケーションの終了

## キーボードショートカット

| ショートカット | 機能 |
|----------|----------|
| `⌘ + ⌥ + ⇧ + T` | 選択したテキストを翻訳 |
| `⌘ + ⌥ + ⇧ + R` | 音声録音（文字起こしのみ）- 開始/停止切り替え |
| `⌘ + ⌥ + ⇧ + E` | 音声録音（文字起こし + 翻訳）- 開始/停止切り替え |
| `ESC` | 録音中の場合は録音をキャンセル |

## トラブルシューティング

### 署名・ビルドエラー

#### 「Signing for "LLMTextTranslator" requires a development team」エラー
このエラーが表示された場合：

1. **プロジェクト設定を確認**
   - Xcodeでプロジェクト設定を開く
   - "Signing & Capabilities" タブを選択
   - "Automatically manage signing" のチェックを外す
   - "Team" を "None" に設定

2. **署名設定を手動で設定**
   ```
   Code Signing Identity: Sign to Run Locally
   Code Signing Style: Manual  
   Development Team: (空白)
   ```

3. **クリーンビルド実行**
   - メニュー: Product → Clean Build Folder
   - 再度ビルドを実行

#### 「アクセシビリティ権限を何度も求められる」問題
ビルドのたびに権限を求められる場合：
- 署名が一貫していない可能性
- 上記の署名設定を確認してアドホック署名が正しく設定されていることを確認
- アドホック署名により権限設定が維持される

### 「アクセシビリティ権限が必要」メッセージ
- システム環境設定 → セキュリティとプライバシー → プライバシー → アクセシビリティ
- 鍵アイコンをクリックしてパスワードを入力
- 「LLM Text Translator」をリストに追加してチェックボックスを有効化

### 「マイク権限が必要」メッセージ
- システム環境設定 → セキュリティとプライバシー → プライバシー → マイク
- 「LLM Text Translator」をリストに追加してチェックボックスを有効化

### 翻訳が動作しない
- メニューの「API Key Settings」でOpenAI APIキーが設定されていることを確認
- インターネット接続を確認
- ショートカット使用前にテキストが正しく選択されていることを確認

### 録音が動作しない
- マイク権限を確認
- 他のアプリケーションでマイクが動作することを確認
- メニューからOpenAI APIキーが設定されていることを確認

### APIエラーメッセージ
- 「APIキーが設定されていません」: メニューの「API Key Settings」でキーを設定
- 「ネットワークエラー」: インターネット接続を確認
- 「API エラー」: OpenAI APIキーが正しく、十分なクレジットがあることを確認

## 開発

### プロジェクト構造
```
LLMTextTranslator/
├── AppDelegate.swift                      # メインアプリケーションロジック
├── LLMTextTranslatorApp.swift             # アプリエントリーポイント
├── ContentView.swift                      # SwiftUIビュー（最小限）
├── KeychainHelper.swift                   # セキュアAPIキー管理
├── LaunchAtLoginManager.swift             # ログイン時自動起動管理
├── Info.plist                             # アプリ設定
├── LLMTextTranslator.entitlements         # セキュリティエンタイトルメント
├── Coordinators/
│   └── ApplicationCoordinator.swift       # アプリケーション全体の調整
├── Managers/
│   ├── ClipboardManager.swift             # クリップボード管理
│   ├── GlobalHotKeyManager.swift          # グローバルホットキー管理
│   ├── PermissionManager.swift            # 権限管理
│   └── StatusBarManager.swift             # ステータスバー管理
├── Services/
│   ├── OpenAIService.swift                # OpenAI API統合
│   └── RecordingService.swift             # 録音サービス
├── ViewModels/
│   ├── MenuBarViewModel.swift             # メニューバービューモデル
│   └── PopupViewModel.swift               # ポップアップビューモデル
└── Views/
    ├── PopupWindow.swift                  # ポップアップウィンドウ
    └── SettingsWindow.swift               # 設定ウィンドウ
```

### 主要コンポーネント

- **ApplicationCoordinator.swift**: アプリケーション全体の調整とデリゲート管理
- **LaunchAtLoginManager.swift**: SMAppServiceフレームワークを使用したログイン時自動起動処理
- **KeychainHelper.swift**: macOS Keychainを使用したセキュアAPIキー保存・取得
- **StatusBarManager.swift**: `NSStatusItem`を使用したメニューバー統合
- **GlobalHotKeyManager.swift**: `NSEvent.addGlobalMonitorForEvents`を使用したグローバルショートカット実装
- **OpenAIService.swift**: OpenAI APIへの直接HTTP呼び出し
- **PermissionManager.swift**: アクセシビリティとマイク権限の処理
- **RecordingService.swift**: AVFoundationを使用した音声録音
- **PopupWindow.swift**: `NSWindow`を使用したフローティングポップアップ

### ソースからのビルド

1. Xcodeがインストールされていることを確認
2. Xcodeでプロジェクトを開く
3. プロジェクト設定で開発チームを設定
4. ビルドして実行

### アーキテクチャ

このアプリケーションはCoordinatorパターンとMVVMアーキテクチャを組み合わせて使用:

- **Coordinator**: アプリケーション全体のフロー管理
- **ViewModels**: UI状態とビジネスロジックの管理  
- **Services**: 外部API呼び出しとシステムサービス
- **Managers**: システムレベルの機能（クリップボード、権限、ホットキー等）
- **Delegates**: コンポーネント間の通信

## セキュリティ注意事項

- アプリはグローバルキーストロークを監視するためアクセシビリティ権限が必要
- 音声録音のためマイクアクセスが必要
- **APIキーはmacOS Keychainに安全に保存** - ハードコーディングやプレーンテキスト保存なし
- アプリはバックグラウンドメニューバーアプリケーションとして動作
- すべての機密データはシステムレベルセキュリティで暗号化

## ライセンス

Copyright © 2025 9988 megane. All rights reserved.

## 貢献

このプロジェクトは翻訳と文字起こしにOpenAIのAPIを使用している。適切なAPIアクセスがあることを確認し、OpenAIの使用ポリシーを理解すること。

---

**注意**: このアプリは個人使用と開発目的で設計されている。OpenAIのAPIを使用する際は、利用規約と使用ポリシーに準拠すること。
