//
//  FileCommands.swift
//  ShaderTune
//
//  Created by Anthony Pardee on 12/31/25.
//

import SwiftUI

// MARK: - Focused Value Keys

struct NewFileActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

struct OpenFileActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

struct ToggleDiagnosticsActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

struct DiagnosticsVisibleKey: FocusedValueKey {
    typealias Value = Bool
}

struct RecentProjectsKey: FocusedValueKey {
    typealias Value = [URL]
}

struct OpenRecentProjectActionKey: FocusedValueKey {
    typealias Value = (URL) -> Void
}

struct ClearRecentProjectsActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

struct CompileActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

struct AutoCompileKey: FocusedValueKey {
    typealias Value = Binding<Bool>
}

extension FocusedValues {
    var newFileAction: (() -> Void)? {
        get { self[NewFileActionKey.self] }
        set { self[NewFileActionKey.self] = newValue }
    }

    var openFileAction: (() -> Void)? {
        get { self[OpenFileActionKey.self] }
        set { self[OpenFileActionKey.self] = newValue }
    }

    var toggleDiagnosticsAction: (() -> Void)? {
        get { self[ToggleDiagnosticsActionKey.self] }
        set { self[ToggleDiagnosticsActionKey.self] = newValue }
    }

    var diagnosticsVisible: Bool? {
        get { self[DiagnosticsVisibleKey.self] }
        set { self[DiagnosticsVisibleKey.self] = newValue }
    }

    var recentProjects: [URL]? {
        get { self[RecentProjectsKey.self] }
        set { self[RecentProjectsKey.self] = newValue }
    }

    var openRecentProjectAction: ((URL) -> Void)? {
        get { self[OpenRecentProjectActionKey.self] }
        set { self[OpenRecentProjectActionKey.self] = newValue }
    }

    var clearRecentProjectsAction: (() -> Void)? {
        get { self[ClearRecentProjectsActionKey.self] }
        set { self[ClearRecentProjectsActionKey.self] = newValue }
    }

    var compileAction: (() -> Void)? {
        get { self[CompileActionKey.self] }
        set { self[CompileActionKey.self] = newValue }
    }

    var autoCompile: Binding<Bool>? {
        get { self[AutoCompileKey.self] }
        set { self[AutoCompileKey.self] = newValue }
    }
}

// MARK: - File Menu Commands

// MARK: - View Menu Commands

struct ViewMenuCommands: Commands {
    @FocusedValue(\.toggleDiagnosticsAction) var toggleDiagnosticsAction
    @FocusedValue(\.diagnosticsVisible) var diagnosticsVisible

    var body: some Commands {
        CommandGroup(after: .toolbar) {
            Button(diagnosticsVisible == true ? "Hide Diagnostics" : "Show Diagnostics") {
                toggleDiagnosticsAction?()
            }
            .keyboardShortcut("m", modifiers: [.command, .shift])
        }
    }
}

// MARK: - Window Menu Commands

struct WindowMenuCommands: Commands {
    var previewState: PreviewState

    var body: some Commands {
        CommandGroup(before: .windowList) {
            DetachPreviewMenuItem(previewState: previewState)
        }
    }
}

/// Extracted into a View so @Observable tracking and @Environment work correctly
private struct DetachPreviewMenuItem: View {
    var previewState: PreviewState
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        Button {
            if previewState.isDetached {
                previewState.isDetached = false
                dismissWindow(id: "shader-preview")
            } else {
                previewState.isDetached = true
                openWindow(id: "shader-preview")
            }
        } label: {
            Label(
                previewState.isDetached ? "Attach Preview" : "Detach Preview",
                systemImage: previewState.isDetached
                    ? "rectangle.inset.filled" : "macwindow.on.rectangle"
            )
        }
        .keyboardShortcut("d", modifiers: [.command, .shift])
    }
}

// MARK: - Build Menu Commands

struct BuildMenuCommands: Commands {
    @FocusedValue(\.compileAction) var compileAction
    @FocusedBinding(\.autoCompile) var autoCompile: Bool?

    var body: some Commands {
        CommandMenu("Build") {
            Button {
                compileAction?()
            } label: {
                Label("Compile", systemImage: "hammer.fill")
            }
            .keyboardShortcut("b", modifiers: .command)
            .disabled(compileAction == nil)

            Divider()

            Toggle(isOn: Binding(get: { autoCompile ?? false }, set: { autoCompile = $0 })) {
                Label("Auto-Compile", systemImage: "bolt.fill")
            }
            .disabled(autoCompile == nil)
        }
    }
}

// MARK: - File Menu Commands

struct FileMenuCommands: Commands {
    @FocusedValue(\.newFileAction) var newFileAction
    @FocusedValue(\.openFileAction) var openFileAction
    @FocusedValue(\.recentProjects) var recentProjects
    @FocusedValue(\.openRecentProjectAction) var openRecentProjectAction
    @FocusedValue(\.clearRecentProjectsAction) var clearRecentProjectsAction

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Project...") {
                newFileAction?()
            }
            .keyboardShortcut("n", modifiers: .command)

            Button("Open...") {
                openFileAction?()
            }
            .keyboardShortcut("o", modifiers: .command)

            Divider()

            // Open Recent submenu
            Menu("Open Recent") {
                if let projects = recentProjects, !projects.isEmpty {
                    ForEach(projects, id: \.self) { url in
                        Button(RecentProjectsService.displayName(for: url)) {
                            openRecentProjectAction?(url)
                        }
                    }

                    Divider()

                    Button("Clear Menu") {
                        clearRecentProjectsAction?()
                    }
                } else {
                    Text("No Recent Projects")
                        .disabled(true)
                }
            }
            .disabled(recentProjects?.isEmpty ?? true)
        }
    }
}
