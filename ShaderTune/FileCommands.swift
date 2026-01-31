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

extension FocusedValues {
    var newFileAction: (() -> Void)? {
        get { self[NewFileActionKey.self] }
        set { self[NewFileActionKey.self] = newValue }
    }

    var openFileAction: (() -> Void)? {
        get { self[OpenFileActionKey.self] }
        set { self[OpenFileActionKey.self] = newValue }
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
