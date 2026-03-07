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

    @Environment(PreviewState.self) private var previewState
    @Environment(\.openWindow) private var openWindow

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

    // File navigation state
    @State private var selectedDirectoryURL: URL?
    @State private var fileTree: [FileNode] = []
    @State private var selectedFileURL: URL?
    @State private var isFileDirty: Bool = false
    /// Snapshot of the file content as last loaded from or saved to disk.
    @State private var savedSource: String = ""
    @State private var showSidebar: Bool = true
    @State private var showDiagnostics: Bool = false
    @State private var recentProjects: [URL] = []

    // Project mode state
    @State private var currentProject: ShaderProject?
    @State private var selectedPass: ShaderPass?
    @State private var workspaceProjects: [ShaderProject] = []
    @State private var passLibraries: [String: MTLLibrary] = [:]

    // New file sheet
    @State private var showingNewFileSheet: Bool = false

    // File watcher for external changes
    @State private var fileWatcher = FileWatcherService()

    // Error handling
    @State private var fileError: FileError?
    @State private var showingFileError: Bool = false

    init() {
        guard let compiler = MetalCompilerService() else {
            fatalError("Metal is not supported on this device")
        }
        self.compiler = compiler
        self.recentProjects = RecentProjectsService.getRecentProjects()
    }

    /// Returns diagnostics for the currently selected pass, or global diagnostics
    private var currentDiagnostics: [CompilationDiagnostic] {
        if let pass = selectedPass {
            return compiler.diagnostics(for: pass.name)
        }
        return compiler.diagnostics
    }

    @ViewBuilder
    private var contentPane: some View {
        VStack(spacing: 0) {
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
                    .foregroundStyle(.secondary)

                    VStack(spacing: 8) {
                        Text("No Shader Selected")
                            .font(.title2)
                            .fontWeight(.semibold)

                        if selectedDirectoryURL != nil {
                            Text(
                                "Select a Metal shader file (.metal) from the sidebar to begin editing"
                            )
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        } else {
                            Text("Open a folder (Cmd+O) or drag a shader file here to begin")
                                .font(.body)
                                .foregroundStyle(.secondary)
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
    }

    @State private var isHoveringPreview = false
    @State private var previewWidth: CGFloat = 320
    @State private var dragStartWidth: CGFloat?
    @State private var dragStartLocation: CGPoint?
    private let previewMinWidth: CGFloat = 160
    private let previewMaxWidth: CGFloat = 640

    var body: some View {
        mainLayout
    }

    private var splitView: some View {
        FlatSplitViewWithBottom(
            showSidebar: $showSidebar,
            showBottom: $showDiagnostics,
            sidebar: {
                FileNavigatorView(
                    selectedDirectoryURL: $selectedDirectoryURL,
                    fileTree: $fileTree,
                    selectedFileURL: $selectedFileURL,
                    onSelectFile: handleFileSelection,
                    currentProject: $currentProject,
                    selectedPass: $selectedPass,
                    workspaceProjects: $workspaceProjects,
                    passDiagnostics: compiler.passDiagnostics,
                    onSelectPass: handlePassSelection,
                    onProjectUpdated: handleProjectUpdated
                )
            },
            content: {
                contentPane
                    .overlay(alignment: .bottomTrailing) {
                        if !previewState.isDetached {
                            previewInset
                                .padding(24)
                        }
                    }
            },
            bottom: {
                DiagnosticsPane(
                    diagnostics: currentDiagnostics,
                    onDismiss: {
                        showDiagnostics = false
                    },
                    onSelectDiagnostic: { diagnostic in
                        // Jump to line in editor (simplified - would need cursor positioning)
                        print("Jump to line \(diagnostic.line)")
                    }
                )
            }
        )
    }

    @ViewBuilder
    private var previewInset: some View {
        let previewHeight = previewWidth * 3 / 4
        PreviewWindowContent()
            .frame(width: previewWidth, height: previewHeight)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(alignment: .topTrailing) {
                if isHoveringPreview {
                    Button {
                        previewState.isDetached = true
                        openPreviewWindow()
                    } label: {
                        Image(systemName: "macwindow.on.rectangle")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(5)
                            .background(.black.opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                    .padding(6)
                    .transition(.opacity)
                }
            }
            .overlay(alignment: .leading) {
                previewResizeHandle(edge: .leading, horizontal: true)
            }
            .overlay(alignment: .top) {
                previewResizeHandle(edge: .top, horizontal: false)
            }
            .overlay(alignment: .topLeading) {
                previewResizeCorner
            }
            .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 2)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHoveringPreview = hovering
                }
            }
    }

    private func previewResizeHandle(edge: Edge, horizontal: Bool) -> some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: horizontal ? 6 : nil, height: horizontal ? nil : 6)
            .contentShape(Rectangle())
            .cursor(horizontal ? .resizeLeftRight : .resizeUpDown)
            .gesture(
                DragGesture(minimumDistance: 1, coordinateSpace: .global)
                    .onChanged { value in
                        if dragStartWidth == nil {
                            dragStartWidth = previewWidth
                            dragStartLocation = value.startLocation
                        }
                        guard let startWidth = dragStartWidth,
                            let startLoc = dragStartLocation
                        else { return }
                        let delta =
                            horizontal
                            ? -(value.location.x - startLoc.x)
                            : -(value.location.y - startLoc.y)
                        let aspect: CGFloat = horizontal ? 1.0 : 4.0 / 3.0
                        previewWidth = (startWidth + delta * aspect)
                            .clamped(to: previewMinWidth...previewMaxWidth)
                    }
                    .onEnded { _ in
                        dragStartWidth = nil
                        dragStartLocation = nil
                    }
            )
    }

    private var previewResizeCorner: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: 10, height: 10)
            .contentShape(Rectangle())
            .cursor(.crosshair)
            .gesture(
                DragGesture(minimumDistance: 1, coordinateSpace: .global)
                    .onChanged { value in
                        if dragStartWidth == nil {
                            dragStartWidth = previewWidth
                            dragStartLocation = value.startLocation
                        }
                        guard let startWidth = dragStartWidth,
                            let startLoc = dragStartLocation
                        else { return }
                        let dx = -(value.location.x - startLoc.x)
                        let dy = -(value.location.y - startLoc.y)
                        let delta = max(dx, dy)
                        previewWidth = (startWidth + delta)
                            .clamped(to: previewMinWidth...previewMaxWidth)
                    }
                    .onEnded { _ in
                        dragStartWidth = nil
                        dragStartLocation = nil
                    }
            )
    }

    private func openPreviewWindow() {
        openWindow(id: "shader-preview")
    }

    private var withKeyBindings: some View {
        splitView
            #if os(macOS)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    if isFileDirty {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 7))
                            .foregroundColor(.orange)
                            .help("Unsaved changes")
                    }
                    if let project = currentProject, let pass = selectedPass {
                        Image(systemName: pass.isMain ? "display" : "square.stack")
                            .foregroundStyle(.tint)
                        Text("\(project.name) / \(pass.name)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else if let filename = selectedFileURL?.lastPathComponent {
                        Text(filename)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            ToolbarItemGroup(placement: .primaryAction) {
                if compiler.isCompiling {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
        }
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
        .onKeyPress("m", phases: .down) { keyPress in
            if keyPress.modifiers.contains([.command, .shift]) {
                showDiagnostics.toggle()
                return .handled
            }
            return .ignored
        }
        .focusedSceneValue(\.newFileAction) { newFile() }
        .focusedSceneValue(\.openFileAction) { openFile() }
        .focusedSceneValue(\.toggleDiagnosticsAction) { showDiagnostics.toggle() }
        .focusedSceneValue(\.compileAction) { compileNow() }
        .focusedSceneValue(\.autoCompile, $autoCompile)
        .focusedSceneValue(\.diagnosticsVisible, showDiagnostics)
        .focusedSceneValue(\.recentProjects, recentProjects)
        .focusedSceneValue(\.openRecentProjectAction, openRecentProject)
        .focusedSceneValue(\.clearRecentProjectsAction, clearRecentProjects)
        .sheet(isPresented: $showingNewFileSheet) {
            NewProjectSheet(onCreate: createNewProject)
        }
            #endif
    }

    private var withAlerts: some View {
        withKeyBindings
            .alert("File Error", isPresented: $showingFileError, presenting: fileError) { error in
                Button("OK") {}
            } message: { error in
                Text(error.localizedDescription)
            }
    }

    private var mainLayout: some View {
        withAlerts
            .background(MainWindowConfigurator())
            .onChange(of: currentDiagnostics) { _, newValue in
                // Auto-show diagnostics pane when there are errors
                if !newValue.isEmpty && !showDiagnostics {
                    showDiagnostics = true
                }
            }
            .onChange(of: selectedDirectoryURL) { _, newValue in
                if let dir = newValue {
                    fileWatcher.watch(directory: dir)
                    fileWatcher.onChange = { [self] changedURLs in
                        handleExternalFileChanges(changedURLs)
                    }
                } else {
                    fileWatcher.stop()
                }
            }
            .onChange(of: selectedFileURL) { _, newValue in
                previewState.selectedFileURL = newValue
                if newValue == nil && selectedDirectoryURL != nil {
                    savedSource = ""
                    shaderSource = ""
                    isFileDirty = false
                } else if newValue == nil && selectedDirectoryURL == nil {
                    savedSource = ContentView.defaultShader
                    shaderSource = ContentView.defaultShader
                    isFileDirty = false
                }
            }
            .onChange(of: shaderSource) { oldValue, newValue in
                if selectedFileURL != nil {
                    isFileDirty = newValue != savedSource
                }
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
        syncPreviewState()
    }

    private func syncPreviewState() {
        previewState.compiledLibrary = compiler.compiledLibrary
        previewState.currentProject = currentProject
        previewState.passLibraries = passLibraries
        previewState.selectedFileURL = selectedFileURL
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
        syncPreviewState()
    }

    private func loadFile(_ url: URL) {
        // Auto-save current file if dirty
        if isFileDirty, let currentURL = selectedFileURL {
            saveFile(currentURL)
        }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            savedSource = content
            shaderSource = content
            selectedFileURL = url
            isFileDirty = false
            syncPreviewState()

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
        fileWatcher.markSaved(url)
        do {
            try shaderSource.write(to: url, atomically: true, encoding: .utf8)
            savedSource = shaderSource
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

    private func handleProjectUpdated(_ project: ShaderProject) {
        // Recompile the project when it's updated (e.g., new buffer added)
        passLibraries = compiler.compileProject(project)

        // If a new buffer was added, load its file
        if let pass = selectedPass {
            let fileURL = project.fileURL(for: pass)
            loadFile(fileURL)
        }
        syncPreviewState()
    }

    // MARK: - External File Change Handling

    private func handleExternalFileChanges(_ changedURLs: Set<URL>) {
        for url in changedURLs {
            let filename = url.lastPathComponent.lowercased()

            // Handle project.yaml changes — reload the entire project
            if filename == "project.yaml" || filename == "project.yml" {
                if let dir = selectedDirectoryURL {
                    scanDirectory(dir)
                }
                return
            }

            // Handle .metal file changes
            if url == selectedFileURL {
                // Currently open file changed externally
                if isFileDirty {
                    // Don't overwrite unsaved user edits
                    continue
                }
                // Reload the file content
                do {
                    let content = try String(contentsOf: url, encoding: .utf8)
                    savedSource = content
                    shaderSource = content
                    isFileDirty = false
                    if autoCompile {
                        compileNow()
                    }
                } catch {
                    // File may have been deleted or be temporarily unreadable
                }
            } else if let project = currentProject {
                // A different pass in the project changed — recompile it
                for pass in project.buffers where project.fileURL(for: pass) == url {
                    do {
                        let source = try String(contentsOf: url, encoding: .utf8)
                        if let library = compiler.compilePass(
                            source: source, passName: pass.name)
                        {
                            passLibraries[pass.name] = library
                        }
                    } catch {}
                }
                syncPreviewState()
            }
        }
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

            // Add to recent projects if it's a project directory
            if ProjectConfigService.isProjectDirectory(directoryURL)
                || ProjectConfigService.isWorkspaceDirectory(directoryURL)
            {
                addToRecentProjects(directoryURL)
            }
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
            syncPreviewState()

            // Add to recent projects
            addToRecentProjects(projectURL)
        } catch {
            fileError = .projectError(error.localizedDescription)
            showingFileError = true
        }
    }

    // MARK: - Recent Projects

    private func addToRecentProjects(_ url: URL) {
        RecentProjectsService.addRecentProject(url)
        recentProjects = RecentProjectsService.getRecentProjects()
    }

    private func openRecentProject(_ url: URL) {
        selectedDirectoryURL = url
        scanDirectory(url)
        addToRecentProjects(url)
    }

    private func clearRecentProjects() {
        RecentProjectsService.clearRecentProjects()
        recentProjects = []
    }
}

#if os(macOS)
private struct MainWindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            Self.configure(view.window)
        }
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
        DispatchQueue.main.async {
            Self.configure(view.window)
        }
    }

    private static func configure(_ window: NSWindow?) {
        guard let window else { return }
        window.titleVisibility = .hidden
        // Prevent content from extending under the title bar so that
        // HSplitView dividers don't bleed into the title bar area.
        window.styleMask.remove(.fullSizeContentView)
    }
}
#endif

// MARK: - Helpers

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

#if os(macOS)
private extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        onHover { hovering in
            if hovering {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
#endif

#Preview {
    ContentView()
        .environment(PreviewState())
        .frame(width: 800, height: 600)
}
