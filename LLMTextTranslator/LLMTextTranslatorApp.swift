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
        // メニューバーアプリなのでウィンドウは不要
        Settings {
            EmptyView()
        }
    }
}
