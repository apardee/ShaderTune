//
//  ContentView.swift
//  ShaderTune
//
//  Created by Anthony Pardee on 12/31/25.
//

import Metal
import SwiftUI

#if os(macOS)
import AppKit
import UniformTypeIdentifiers
#endif

enum FileError: LocalizedError {
    case loadFailed(String)
    case saveFailed(String)
    case scanFailed(String)
    case projectError(String)

    var errorDescription: String? {
        switch self {
        case .loadFailed(let path): return "Failed to load file: \(path)"
        case .saveFailed(let path): return "Failed to save file: \(path)"
        case .scanFailed(let path): return "Failed to scan directory: \(path)"
        case .projectError(let message): return "Project error: \(message)"
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

    // Project mode state
    @State private var currentProject: ShaderProject?
    @State private var selectedPass: ShaderPass?
    @State private var workspaceProjects: [ShaderProject] = []
    @State private var passLibraries: [String: MTLLibrary] = [:]

    // New file sheet
    @State private var showingNewFileSheet: Bool = false

    // Error handling
    @State private var fileError: FileError?
    @State private var showingFileError: Bool = false

    init() {
        guard let compiler = MetalCompilerService() else {
            fatalError("Metal is not supported on this device")
        }
        self.compiler = compiler
    }

    /// Returns diagnostics for the currently selected pass, or global diagnostics
    private var currentDiagnostics: [CompilationDiagnostic] {
        if let pass = selectedPass {
            return compiler.diagnostics(for: pass.name)
        }
        return compiler.diagnostics
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar: File Navigator (or Project Navigator)
            FileNavigatorView(
                selectedDirectoryURL: $selectedDirectoryURL,
                fileTree: $fileTree,
                selectedFileURL: $selectedFileURL,
                onSelectFile: handleFileSelection,
                currentProject: $currentProject,
                selectedPass: $selectedPass,
                workspaceProjects: $workspaceProjects,
                passDiagnostics: compiler.passDiagnostics,
                onSelectPass: handlePassSelection
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

                    // Show project/pass info or filename
                    if let project = currentProject, let pass = selectedPass {
                        HStack(spacing: 4) {
                            Image(systemName: pass.isMain ? "display" : "square.stack")
                                .foregroundColor(.accentColor)
                            Text("\(project.name) / \(pass.name)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    } else if let filename = selectedFileURL?.lastPathComponent {
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
                if selectedFileURL == nil && shaderSource.isEmpty && currentProject == nil {
                    // Empty state when no file is selected
                    VStack(spacing: 20) {
                        Spacer()

                        Image(
                            systemName: selectedDirectoryURL != nil
                                ? "doc.text.magnifyingglass" : "folder.badge.plus"
                        )
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)

                        VStack(spacing: 8) {
                            Text("No Shader Selected")
                                .font(.title2)
                                .fontWeight(.semibold)

                            if selectedDirectoryURL != nil {
                                Text(
                                    "Select a Metal shader file (.metal) from the sidebar to begin editing"
                                )
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
                            diagnostics: currentDiagnostics
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
                            .offset(x: 100, y: 100)  // Simple fixed position
                            .transition(.opacity)
                        }
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 300, ideal: 500)
        } detail: {
            // Detail: Renderer preview
            if currentProject != nil && !passLibraries.isEmpty {
                // Multi-pass project mode
                RendererView(
                    mousePosition: $mousePosition,
                    compiledLibrary: $compiler.compiledLibrary,
                    project: $currentProject,
                    passLibraries: $passLibraries
                )
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let location):
                        mousePosition = location
                    case .ended:
                        break
                    }
                }
                .navigationSplitViewColumnWidth(min: 200, ideal: 400)
            } else if selectedFileURL != nil && compiler.compiledLibrary != nil {
                // Single file mode
                RendererView(
                    mousePosition: $mousePosition,
                    compiledLibrary: $compiler.compiledLibrary
                )
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

                        if selectedFileURL == nil && currentProject == nil {
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
                openFile()
                return .handled
            }
            return .ignored
        }
        .onKeyPress("n", phases: .down) { keyPress in
            if keyPress.modifiers.contains(.command) {
                newFile()
                return .handled
            }
            return .ignored
        }
        .focusedSceneValue(\.newFileAction) { newFile() }
        .focusedSceneValue(\.openFileAction) { openFile() }
        .sheet(isPresented: $showingNewFileSheet) {
            NewProjectSheet(onCreate: createNewProject)
        }
        #endif
        .alert("File Error", isPresented: $showingFileError, presenting: fileError) { error in
            Button("OK") {}
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
                    compileCurrentSource(source)
                }
            }
        }
    }

    private func compileNow() {
        // Cancel any pending debounced compilation
        debounceTask?.cancel()
        compileCurrentSource(shaderSource)
    }

    private func compileCurrentSource(_ source: String) {
        if currentProject != nil, let pass = selectedPass {
            // Project mode - compile only the current pass
            if let library = compiler.compilePass(source: source, passName: pass.name) {
                passLibraries[pass.name] = library
            }
        } else {
            // Single file mode
            compiler.compile(source: source)
        }
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
        // Simplified - would need actual cursor tracking
        let cursorPosition = shaderSource.endIndex
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

    private func scanDirectory(_ url: URL) {
        // Reset project state
        currentProject = nil
        workspaceProjects = []
        selectedPass = nil
        passLibraries = [:]
        compiler.clearPassState()

        // Analyze the directory type
        let directoryType = WorkspaceService.analyzeDirectory(url)

        switch directoryType {
        case .project(let project):
            // Single project mode
            currentProject = project
            fileTree = []

            // Compile all passes
            passLibraries = compiler.compileProject(project)

            // Select the main pass by default
            selectedPass = project.mainPass
            let fileURL = project.fileURL(for: project.mainPass)
            loadFile(fileURL)

        case .workspace(let projects):
            // Workspace mode - multiple projects
            workspaceProjects = projects
            fileTree = []

            // Select first project by default
            if let firstProject = projects.first {
                currentProject = firstProject
                passLibraries = compiler.compileProject(firstProject)
                selectedPass = firstProject.mainPass
                let fileURL = firstProject.fileURL(for: firstProject.mainPass)
                loadFile(fileURL)
            }

        case .looseFiles:
            // Loose files mode - build file tree
            do {
                let builder = FileTreeBuilder()
                fileTree = try builder.buildTree(from: url)
            } catch {
                fileError = .scanFailed(url.path)
                showingFileError = true
                fileTree = []
            }
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

    private func handlePassSelection(_ pass: ShaderPass) {
        guard let project = currentProject else { return }

        // Save current file if dirty
        if isFileDirty, let currentURL = selectedFileURL {
            saveFile(currentURL)
        }

        // Load the pass's shader file
        let fileURL = project.fileURL(for: pass)
        loadFile(fileURL)
        selectedPass = pass
    }

    // MARK: - New/Open File Actions

    #if os(macOS)
    private func newFile() {
        // Always show the new project sheet - it will handle folder selection
        showingNewFileSheet = true
    }

    private func openFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [
            .folder,
            .init(filenameExtension: "yaml")!,
            .init(filenameExtension: "yml")!,
        ]
        panel.message = "Select a shader project folder or project.yaml file"

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }

            var directoryURL: URL

            // Determine the project directory
            if url.hasDirectoryPath {
                // User selected a directory
                directoryURL = url
            } else if url.pathExtension == "yaml" || url.pathExtension == "yml" {
                // User selected a project.yaml file - use its parent directory
                directoryURL = url.deletingLastPathComponent()
            } else {
                // Fallback - treat as directory
                directoryURL = url
            }

            selectedDirectoryURL = directoryURL
            scanDirectory(directoryURL)
        }
    }
    #endif

    private func createNewProject(at projectURL: URL, named projectName: String) {
        do {
            let project = try ProjectConfigService.createProject(name: projectName, at: projectURL)

            // Set as current directory and project
            selectedDirectoryURL = projectURL
            currentProject = project
            workspaceProjects = []
            fileTree = []

            // Compile all passes
            passLibraries = compiler.compileProject(project)

            // Select the main pass
            selectedPass = project.mainPass
            let fileURL = project.fileURL(for: project.mainPass)
            loadFile(fileURL)
        } catch {
            fileError = .projectError(error.localizedDescription)
            showingFileError = true
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 800, height: 600)
}
