//
//  ContentView.swift
//  ShaderTune
//
//  Created by Anthony Pardee on 12/31/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(PreviewState.self) private var previewState
    @Environment(\.dismissWindow) private var dismissWindow

    @State private var state = EditorState()

    // UI-only state
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var showingFindReplace = false
    @State private var showShaderConfig: Bool = false
    @State private var shaderConfigWidth: CGFloat = 240
    @State private var showingNewFileSheet: Bool = false
    @State private var previewWidth: CGFloat = 320

    var body: some View {
        withChangeHandlers
            .onAppear {
                state.previewState = previewState
            }
    }

    private var withChangeHandlers: some View {
        withAlerts
            .onChange(of: state.currentDiagnostics) { _, newValue in
                if !newValue.isEmpty && !state.showDiagnostics {
                    state.showDiagnostics = true
                }
            }
            .onChange(of: state.currentShader) { oldValue, newValue in
                withAnimation(.easeInOut(duration: 0.25)) {
                    if newValue == nil {
                        showShaderConfig = false
                    } else if oldValue == nil {
                        showShaderConfig = true
                    }
                }
            }
            .onChange(of: state.selectedDirectoryURL) { _, newValue in
                state.handleDirectoryChanged(newValue)
            }
            .onChange(of: state.selectedFileURL) { _, newValue in
                state.handleSelectedFileURLChanged(newValue)
            }
            .onChange(of: state.displayMode) { _, newMode in
                if newMode == .preview && previewState.isDetached {
                    previewState.isDetached = false
                    dismissWindow(id: "shader-preview")
                }
            }
            .onChange(of: state.shaderSource) { oldValue, newValue in
                state.handleSourceChanged(oldValue: oldValue, newValue: newValue)
            }
    }

    private var withAlerts: some View {
        withKeyBindings
            .alert(
                "File Error", isPresented: $state.showingFileError, presenting: state.fileError
            ) { _ in
                Button("OK") {}
            } message: { error in
                Text(error.localizedDescription)
            }
    }

    private var withKeyBindings: some View {
        splitView
            .navigationTitle(navigationTitle)
            #if os(macOS)
        .toolbar { toolbarContent }
        .onKeyPress("f", phases: .down) { keyPress in
            if keyPress.modifiers.contains(.command) {
                showingFindReplace.toggle()
                return .handled
            }
            return .ignored
        }
        .onKeyPress(" ", phases: .down) { keyPress in
            if keyPress.modifiers.contains(.control) {
                state.triggerCompletion()
                return .handled
            }
            return .ignored
        }
        .onKeyPress("s", phases: .down) { keyPress in
            if keyPress.modifiers.contains(.command) {
                state.saveCurrentFile()
                return .handled
            }
            return .ignored
        }
        .onKeyPress("o", phases: .down) { keyPress in
            if keyPress.modifiers.contains(.command) {
                state.openFilePanel()
                return .handled
            }
            return .ignored
        }
        .onKeyPress("n", phases: .down) { keyPress in
            if keyPress.modifiers.contains(.command) {
                showingNewFileSheet = true
                return .handled
            }
            return .ignored
        }
        .onKeyPress("m", phases: .down) { keyPress in
            if keyPress.modifiers.contains([.command, .shift]) {
                state.showDiagnostics.toggle()
                return .handled
            }
            return .ignored
        }
        .focusedSceneValue(\.newFileAction) { showingNewFileSheet = true }
        .focusedSceneValue(\.openFileAction) { state.openFilePanel() }
        .focusedSceneValue(\.toggleDiagnosticsAction) { state.showDiagnostics.toggle() }
        .focusedSceneValue(\.compileAction) { state.compileNow() }
        .focusedSceneValue(\.autoCompile, $state.autoCompile)
        .focusedSceneValue(\.diagnosticsVisible, state.showDiagnostics)
        .focusedSceneValue(\.recentProjects, state.recentProjects)
        .focusedSceneValue(\.openRecentProjectAction, state.openRecentProject)
        .focusedSceneValue(\.clearRecentProjectsAction, state.clearRecentProjects)
        .sheet(isPresented: $showingNewFileSheet) {
            NewProjectSheet(onCreate: state.createNewProject)
        }
            #endif
    }

    // MARK: - Navigation

    private var navigationTitle: String {
        if let project = state.currentShader, let pass = state.selectedPass {
            return "\(project.name) — \(pass.name)"
        } else if let filename = state.selectedFileURL?.lastPathComponent {
            return filename
        }
        return "ShaderTune"
    }

    private var splitView: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            ProjectNavigator(
                directoryURL: $state.selectedDirectoryURL,
                shaders: $state.shaders,
                currentShader: $state.currentShader,
                onSelectShader: state.handleShaderSelection,
                onCreateShader: state.handleShaderCreated,
                onRenameShader: state.handleShaderRenamed,
                onRemoveShader: state.handleShaderRemoved
            )
            .navigationSplitViewColumnWidth(min: 160, ideal: 200)
        } detail: {
            if state.displayMode == .preview {
                PreviewModeDetailView(
                    state: state,
                    showShaderConfig: $showShaderConfig,
                    shaderConfigWidth: $shaderConfigWidth
                )
            } else {
                EditorDetailView(
                    state: state,
                    showingFindReplace: $showingFindReplace,
                    showShaderConfig: $showShaderConfig,
                    shaderConfigWidth: $shaderConfigWidth,
                    previewWidth: $previewWidth
                )
            }
        }
    }

    // MARK: - Toolbar

    #if os(macOS)
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Picker("Display Mode", selection: $state.displayMode) {
                Image(systemName: "rectangle.split.2x1")
                    .tag(DisplayMode.editor)
                Image(systemName: "rectangle")
                    .tag(DisplayMode.preview)
            }
            .pickerStyle(.segmented)

            if state.displayMode == .editor {
                if state.isFileDirty {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 7))
                        .foregroundColor(.orange)
                        .help("Unsaved changes")
                }
                if state.compiler.isCompiling {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showShaderConfig.toggle()
                }
            } label: {
                Image(systemName: "sidebar.right")
            }
            .help(
                showShaderConfig ? "Hide Shader Configuration" : "Show Shader Configuration"
            )
            .disabled(state.currentShader == nil)
        }
    }
    #endif
}

#Preview {
    ContentView()
        .environment(PreviewState())
        .frame(width: 800, height: 600)
}
