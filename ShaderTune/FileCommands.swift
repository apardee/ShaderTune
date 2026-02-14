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
}

// MARK: - File Menu Commands

// MARK: - View Menu Commands

struct ViewMenuCommands: Commands {
    @FocusedValue(\.detachPreviewAction) var detachPreviewAction
    @FocusedValue(\.previewDetached) var previewDetached

    var body: some Commands {
        CommandGroup(after: .toolbar) {
            Button(previewDetached == true ? "Attach Preview" : "Detach Preview") {
                detachPreviewAction?()
            }
            .keyboardShortcut("d", modifiers: [.command, .shift])
        }
    }
}

// MARK: - File Menu Commands

struct FileMenuCommands: Commands {
    @FocusedValue(\.newFileAction) var newFileAction
    @FocusedValue(\.openFileAction) var openFileAction

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
        }
    }
}
