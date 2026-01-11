//
//  ContentView.swift
//  ShaderTune
//
//  Created by Anthony Pardee on 12/31/25.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

enum FileError: LocalizedError {
    case loadFailed(String)
    case saveFailed(String)
    case scanFailed(String)

    var errorDescription: String? {
        switch self {
        case .loadFailed(let path): return "Failed to load file: \(path)"
        case .saveFailed(let path): return "Failed to save file: \(path)"
        case .scanFailed(let path): return "Failed to scan directory: \(path)"
        }
    }
}

struct ContentView: View {
    // Default shader is empty - shows empty state until file is loaded
    private static let defaultShader = ""

    @State private var compiler: MetalCompilerService
    @State private var shaderSource = ContentView.defaultShader
    @State private var autoCompile = true
    @State private var debounceTask: Task<Void, Never>?
    @State private var showingFindReplace = false
    @State private var searchText = ""
    @State private var replaceText = ""
    @State private var showingCompletions = false
    @State private var completions: [CompletionItem] = []
    @State private var completionProvider = CompletionProvider()
	@State private var mousePosition: CGPoint = .zero

    // File navigation state
    @State private var selectedDirectoryURL: URL?
    @State private var fileTree: [FileNode] = []
    @State private var selectedFileURL: URL?
    @State private var isFileDirty: Bool = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    // Error handling
    @State private var fileError: FileError?
    @State private var showingFileError: Bool = false

    init() {
        guard let compiler = MetalCompilerService() else {
            fatalError("Metal is not supported on this device")
        }
		self.compiler = compiler
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar: File Navigator
            FileNavigatorView(
                selectedDirectoryURL: $selectedDirectoryURL,
                fileTree: $fileTree,
                selectedFileURL: $selectedFileURL,
                onSelectFolder: {
                    #if os(macOS)
                    selectFolder()
                    #endif
                },
                onSelectFile: handleFileSelection
            )
            .navigationSplitViewColumnWidth(min: 180, ideal: 220)
        } content: {
            // Content: Editor with toolbar and find/replace
            VStack(spacing: 0) {
                // Toolbar
                HStack {
                    if isFileDirty {
                        Text("●")
                            .foregroundColor(.orange)
                            .help("Unsaved changes")
                    }

                    if let filename = selectedFileURL?.lastPathComponent {
                        Text(filename)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Text("Device: \(compiler.deviceInfo)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Toggle("Auto-compile", isOn: $autoCompile)
                        .toggleStyle(.switch)
                        .help("Automatically compile shader as you type")

                    if compiler.isCompiling {
                        ProgressView()
                            .scaleEffect(0.8)
                            .padding(.leading, 8)
                    }

                    Button("Compile") {
                        compileNow()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(compiler.isCompiling)
                }
                .padding()
                #if os(macOS)
                .background(Color(nsColor: .controlBackgroundColor))
                #else
                .background(Color(.systemBackground))
                #endif

                // Find/Replace bar
                if showingFindReplace {
                    FindReplaceView(
                        searchText: $searchText,
                        replaceText: $replaceText,
                        isVisible: $showingFindReplace,
                        onFind: findNext,
                        onReplace: replaceNext,
                        onReplaceAll: replaceAll
                    )
                }

                // Editor with inline error display
                if selectedFileURL == nil && shaderSource.isEmpty {
                    // Empty state when no file is selected
                    VStack(spacing: 20) {
                        Spacer()

                        Image(systemName: selectedDirectoryURL != nil ? "doc.text.magnifyingglass" : "folder.badge.plus")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary)

                        VStack(spacing: 8) {
                            Text("No Shader Selected")
                                .font(.title2)
                                .fontWeight(.semibold)

                            if selectedDirectoryURL != nil {
                                Text("Select a Metal shader file (.metal) from the sidebar to begin editing")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            } else {
                                Text("Open a folder (Cmd+O) or drag a shader file here to begin")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                        }

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ZStack(alignment: .topLeading) {
                        // Editor with native inline errors
                        ShaderEditorViewWrapper(
                            source: $shaderSource,
                            diagnostics: compiler.diagnostics
                        )

                        // Completion popup
                        if showingCompletions && !completions.isEmpty {
                            CompletionView(
                                completions: completions,
                                onSelect: { item in
                                    insertCompletion(item)
                                },
                                onDismiss: {
                                    showingCompletions = false
                                }
                            )
                            .offset(x: 100, y: 100) // Simple fixed position
                            .transition(.opacity)
                        }
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 300, ideal: 500)
        } detail: {
            // Detail: Renderer preview
            if selectedFileURL != nil && compiler.compiledLibrary != nil {
                RendererView(mousePosition: $mousePosition, compiledLibrary: $compiler.compiledLibrary)
                    .onContinuousHover { phase in
                        switch phase {
                        case .active(let location):
                            mousePosition = location
                        case .ended:
                            break
                        }
                    }
                    .navigationSplitViewColumnWidth(min: 200, ideal: 400)
            } else {
                // Empty state when no shader is compiled
                VStack(spacing: 20) {
                    Spacer()

                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)

                    VStack(spacing: 8) {
                        Text("No Shader Preview")
                            .font(.title2)
                            .fontWeight(.semibold)

                        if selectedFileURL == nil {
                            Text("Select a shader file to see the rendered output")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        } else {
                            Text("Compile your shader to see the preview")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationSplitViewColumnWidth(min: 200, ideal: 400)
            }
        }
        #if os(macOS)
        .onKeyPress("f", phases: .down) { keyPress in
            if keyPress.modifiers.contains(.command) {
                showingFindReplace.toggle()
                return .handled
            }
            return .ignored
        }
        .onKeyPress(" ", phases: .down) { keyPress in
            if keyPress.modifiers.contains(.control) {
                triggerCompletion()
                return .handled
            }
            return .ignored
        }
        .onKeyPress("s", phases: .down) { keyPress in
            if keyPress.modifiers.contains(.command) {
                saveCurrentFile()
                return .handled
            }
            return .ignored
        }
        .onKeyPress("o", phases: .down) { keyPress in
            if keyPress.modifiers.contains(.command) {
                selectFolder()
                return .handled
            }
            return .ignored
        }
        #endif
        .alert("File Error", isPresented: $showingFileError, presenting: fileError) { error in
            Button("OK") { }
        } message: { error in
            Text(error.localizedDescription)
        }
        .onChange(of: selectedFileURL) { oldValue, newValue in
            // Keep shaderSource in sync with selected file
            if newValue == nil && selectedDirectoryURL != nil {
                // Folder is open but no file selected - clear the editor
                shaderSource = ""
                isFileDirty = false
            } else if newValue == nil && selectedDirectoryURL == nil {
                // No folder and no file - show default shader
                shaderSource = ContentView.defaultShader
                isFileDirty = false
            }
            // When a file is selected, it's loaded via loadFile() which sets shaderSource
        }
        .onChange(of: shaderSource) { oldValue, newValue in
            // Mark as dirty when content changes (only for file-backed buffers)
            if selectedFileURL != nil {
                isFileDirty = true
            }

            // Auto-trigger completion on typing
            if newValue.count > oldValue.count {
                updateCompletions()
            }
            if autoCompile && !newValue.isEmpty {
                scheduleCompilation(for: newValue)
            }
        }
    }

    private func scheduleCompilation(for source: String) {
        // Cancel any existing debounce task
        debounceTask?.cancel()

        // Create a new debounced compilation task
        debounceTask = Task {
            // Wait for 1 second of inactivity
            try? await Task.sleep(nanoseconds: 1_000_000_000)

            // Check if task was cancelled during sleep
            if !Task.isCancelled {
                await MainActor.run {
                    compiler.compile(source: source)
                }
            }
        }
    }

    private func compileNow() {
        // Cancel any pending debounced compilation
        debounceTask?.cancel()
        compiler.compile(source: shaderSource)
    }

    // MARK: - Find/Replace

    private func findNext() {
        guard !searchText.isEmpty else { return }
        // Note: Basic implementation - in production would need cursor tracking
        // For now, just highlights that the feature exists
        print("Find: \(searchText)")
    }

    private func replaceNext() {
        guard !searchText.isEmpty else { return }
        // Find first occurrence and replace
        if let range = shaderSource.range(of: searchText) {
            shaderSource.replaceSubrange(range, with: replaceText)
        }
    }

    private func replaceAll() {
        guard !searchText.isEmpty else { return }
        shaderSource = shaderSource.replacingOccurrences(of: searchText, with: replaceText)
    }

    // MARK: - Code Completion

    private func triggerCompletion() {
        let cursorPosition = shaderSource.endIndex // Simplified - would need actual cursor tracking
        completions = completionProvider.completions(for: shaderSource, at: cursorPosition)
        showingCompletions = !completions.isEmpty
    }

    private func updateCompletions() {
        let cursorPosition = shaderSource.endIndex
        if completionProvider.shouldTriggerCompletion(for: shaderSource, at: cursorPosition) {
            completions = completionProvider.completions(for: shaderSource, at: cursorPosition)
            showingCompletions = !completions.isEmpty
        } else {
            showingCompletions = false
        }
    }

    private func insertCompletion(_ item: CompletionItem) {
        // Find word range and replace with completion
        let cursorPosition = shaderSource.endIndex
        if let range = completionProvider.wordRange(in: shaderSource, at: cursorPosition) {
            shaderSource.replaceSubrange(range, with: item.text)
        }
        showingCompletions = false
    }

    // MARK: - File Operations

    #if os(macOS)
    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a folder containing Metal shader files"

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }

            selectedDirectoryURL = url
            scanDirectory(url)
        }
    }
    #endif

    private func scanDirectory(_ url: URL) {
        do {
            let builder = FileTreeBuilder()
            fileTree = try builder.buildTree(from: url)
        } catch {
            fileError = .scanFailed(url.path)
            showingFileError = true
            fileTree = []
        }
    }

    private func loadFile(_ url: URL) {
        // Auto-save current file if dirty
        if isFileDirty, let currentURL = selectedFileURL {
            saveFile(currentURL)
        }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            shaderSource = content
            selectedFileURL = url
            isFileDirty = false

            // Compile the newly loaded shader if auto-compile is enabled
            if autoCompile {
                compileNow()
            }
        } catch {
            fileError = .loadFailed(url.path)
            showingFileError = true
        }
    }

    private func saveFile(_ url: URL) {
        do {
            try shaderSource.write(to: url, atomically: true, encoding: .utf8)
            isFileDirty = false
        } catch {
			print(error)
            fileError = .saveFailed(url.path)
            showingFileError = true
        }
    }

    private func saveCurrentFile() {
        guard let url = selectedFileURL else { return }
        saveFile(url)
    }

    private func handleFileSelection(_ url: URL) {
        // Don't reload if already selected
        guard url != selectedFileURL else { return }

        loadFile(url)
    }
}

#Preview {
    ContentView()
        .frame(width: 800, height: 600)
}
