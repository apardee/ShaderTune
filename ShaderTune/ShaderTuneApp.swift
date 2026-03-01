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
            BuildMenuCommands()
            ViewMenuCommands()
            WindowMenuCommands(previewState: previewState)
        }

        Window("Shader Preview", id: "shader-preview") {
            PreviewWindowContent()
                .environment(previewState)
                .background(ShaderPreviewWindowConfigurator(previewState: previewState))
                .ignoresSafeArea()
        }
        .defaultSize(width: 800, height: 600)
    }
}

#if os(macOS)
/// Configures the shader preview window to show native macOS controls with full screen support
private struct ShaderPreviewWindowConfigurator: NSViewRepresentable {
    var previewState: PreviewState

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            updateWindow(forView: view)
        }
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {}
    
    private func updateWindow(forView view: NSView) {
        guard let window = view.window else { return }

        let delegate = ShaderPreviewWindowDelegate(previewState: previewState)
        window.delegate = delegate
        // Keep delegate alive
        objc_setAssociatedObject(
            window, "windowDelegate", delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        delegate.updateWindow(window)
    }
}

/// Window delegate to handle full screen transitions and window close
@MainActor
private class ShaderPreviewWindowDelegate: NSObject, NSWindowDelegate {
    let previewState: PreviewState

    init(previewState: PreviewState) {
        self.previewState = previewState
    }

    func updateWindow(_ window: NSWindow) {
        // Enable full screen and native window controls
        window.styleMask.insert(.fullSizeContentView)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden

        // Keep window controls (traffic lights) visible in normal mode
        window.standardWindowButton(.closeButton)?.superview?.superview?.isHidden = false

        // Make window draggable by background
        window.isMovableByWindowBackground = true

        // Enable full screen mode with proper behavior
        window.collectionBehavior = [.fullScreenPrimary, .fullScreenAllowsTiling]
    }
    
    func windowWillClose(_ notification: Notification) {
        previewState.isDetached = false
    }

    func windowDidBecomeKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        DispatchQueue.main.async {
            self.updateWindow(window)
        }
    }

    func window(
        _ window: NSWindow,
        willUseFullScreenPresentationOptions proposedOptions: NSApplication.PresentationOptions
    ) -> NSApplication.PresentationOptions {
        // Hide menu bar and dock in full screen for true edge-to-edge content
        return [.fullScreen, .autoHideMenuBar, .autoHideDock]
    }

    func windowWillEnterFullScreen(_ notification: Notification) {
        // Additional configuration when entering full screen if needed
    }

    func windowWillExitFullScreen(_ notification: Notification) {
        // Pre-apply hidden title bar settings before exiting full screen animation
        // This prevents the title bar from flashing during the transition
        guard let window = notification.object as? NSWindow else { return }

        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.styleMask.insert(.fullSizeContentView)
    }

    func windowDidExitFullScreen(_ notification: Notification) {
        // Ensure settings persist after animation completes
        guard let window = notification.object as? NSWindow else { return }

        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.styleMask.insert(.fullSizeContentView)
    }
}
#endif
