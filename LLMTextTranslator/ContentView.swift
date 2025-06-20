//
//  ContentView.swift
//  LLMTextTranslator
//
//  Created by 9988 megane on 2025/06/20.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var launchManager = LaunchAtLoginManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("LLM Text Translator")
                .font(.title)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("設定")
                    .font(.headline)
                
                Toggle("ログイン時に自動起動", isOn: $launchManager.isEnabled)
                    .onChange(of: launchManager.isEnabled) { newValue in
                        launchManager.setEnabled(newValue)
                    }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
        .padding()
        .onAppear {
            launchManager.checkStatus()
        }
    }
}

#Preview {
    ContentView()
}
