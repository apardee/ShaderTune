//
//  ShaderTuneApp.swift
//  ShaderTune
//
//  Created by Anthony Pardee on 12/31/25.
//

import AppKit
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
                .background(WindowMover())
                .ignoresSafeArea()
        }
        .windowStyle(.hiddenTitleBar)
    }
}

/// Makes the window draggable by clicking anywhere in its background.
private struct WindowMover: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            view.window?.isMovableByWindowBackground = true
        }
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {}
}
