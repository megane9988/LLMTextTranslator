//
//  LLMTextTranslatorApp.swift
//  LLMTextTranslator
//
//  Created by 9988 megane on 2025/06/20.
//

import SwiftUI

@main
struct LLMTextTranslatorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // ウィンドウ不要の場合は empty にしてしまってOK
        Settings {
            EmptyView()
        }
    }
}
