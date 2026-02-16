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

struct DetachPreviewActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

struct PreviewDetachedKey: FocusedValueKey {
    typealias Value = Bool
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

extension FocusedValues {
    var newFileAction: (() -> Void)? {
        get { self[NewFileActionKey.self] }
        set { self[NewFileActionKey.self] = newValue }
    }

    var openFileAction: (() -> Void)? {
        get { self[OpenFileActionKey.self] }
        set { self[OpenFileActionKey.self] = newValue }
    }

    var detachPreviewAction: (() -> Void)? {
        get { self[DetachPreviewActionKey.self] }
        set { self[DetachPreviewActionKey.self] = newValue }
    }

    var previewDetached: Bool? {
        get { self[PreviewDetachedKey.self] }
        set { self[PreviewDetachedKey.self] = newValue }
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
}

// MARK: - File Menu Commands

// MARK: - View Menu Commands

struct ViewMenuCommands: Commands {
    @FocusedValue(\.detachPreviewAction) var detachPreviewAction
    @FocusedValue(\.previewDetached) var previewDetached
    @FocusedValue(\.toggleDiagnosticsAction) var toggleDiagnosticsAction
    @FocusedValue(\.diagnosticsVisible) var diagnosticsVisible

    var body: some Commands {
        CommandGroup(after: .toolbar) {
            Button(previewDetached == true ? "Attach Preview" : "Detach Preview") {
                detachPreviewAction?()
            }
            .keyboardShortcut("d", modifiers: [.command, .shift])

            Divider()

            Button(diagnosticsVisible == true ? "Hide Diagnostics" : "Show Diagnostics") {
                toggleDiagnosticsAction?()
            }
            .keyboardShortcut("m", modifiers: [.command, .shift])
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
