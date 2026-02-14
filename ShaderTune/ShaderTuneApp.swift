//
//  ShaderTuneApp.swift
//  ShaderTune
//
//  Created by Anthony Pardee on 12/31/25.
//

import SwiftUI

@main
struct ShaderTuneApp: App {
    @State private var previewState = PreviewState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(previewState)
        }
        .commands {
            FileMenuCommands()
            ViewMenuCommands()
        }

        Window("Shader Preview", id: "shader-preview") {
            PreviewWindowContent()
                .environment(previewState)
        }
    }
}
