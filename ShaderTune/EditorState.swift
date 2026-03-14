//
//  EditorState.swift
//  ShaderTune
//
//  Created by Anthony Pardee on 3/14/26.
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

enum DisplayMode {
    case editor
    case preview
}

@MainActor @Observable
final class EditorState {
    private static let defaultShader = ""

    // MARK: - Compiler

    var compiler: MetalCompilerService
    var shaderSource: String = ""
    var autoCompile: Bool = true
    private var debounceTask: Task<Void, Never>?

    // MARK: - File State

    var selectedDirectoryURL: URL?
    var fileTree: [FileNode] = []
    var selectedFileURL: URL?
    var isFileDirty: Bool = false
    var savedSource: String = ""

    // MARK: - Project State

    var currentShader: Shader?
    var selectedPass: ShaderPass?
    var shaders: [Shader] = []
    var passLibraries: [String: MTLLibrary] = [:]

    // MARK: - UI State

    var showDiagnostics: Bool = false
    var displayMode: DisplayMode = .editor
    var recentProjects: [URL] = []

    // MARK: - Completion

    var showingCompletions: Bool = false
    var completions: [CompletionItem] = []
    private var completionProvider = CompletionProvider()

    // MARK: - Find/Replace

    var searchText: String = ""
    var replaceText: String = ""

    // MARK: - File Watcher

    var fileWatcher = FileWatcherService()

    // MARK: - Error Handling

    var fileError: FileError?
    var showingFileError: Bool = false

    // MARK: - Preview

    weak var previewState: PreviewState?

    var currentDiagnostics: [CompilationDiagnostic] {
        if let pass = selectedPass {
            return compiler.diagnostics(for: pass.name)
        }
        return compiler.diagnostics
    }

    init() {
        guard let compiler = MetalCompilerService() else {
            fatalError("Metal is not supported on this device")
        }
        self.compiler = compiler
        self.recentProjects = RecentProjectsService.getRecentProjects()
    }

    // MARK: - Compilation

    func scheduleCompilation(for source: String) {
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            if !Task.isCancelled {
                await MainActor.run {
                    self.compileCurrentSource(source)
                }
            }
        }
    }

    func compileNow() {
        debounceTask?.cancel()
        compileCurrentSource(shaderSource)
    }

    private func compileCurrentSource(_ source: String) {
        if currentShader != nil, let pass = selectedPass {
            if let library = compiler.compilePass(source: source, passName: pass.name) {
                passLibraries[pass.name] = library
            }
        } else {
            compiler.compile(source: source)
        }
        syncPreviewState()
    }

    func syncPreviewState() {
        previewState?.compiledLibrary = compiler.compiledLibrary
        previewState?.currentShader = currentShader
        previewState?.passLibraries = passLibraries
        previewState?.selectedFileURL = selectedFileURL
    }

    // MARK: - Find/Replace

    func findNext() {
        guard !searchText.isEmpty else { return }
        print("Find: \(searchText)")
    }

    func replaceNext() {
        guard !searchText.isEmpty else { return }
        if let range = shaderSource.range(of: searchText) {
            shaderSource.replaceSubrange(range, with: replaceText)
        }
    }

    func replaceAll() {
        guard !searchText.isEmpty else { return }
        shaderSource = shaderSource.replacingOccurrences(of: searchText, with: replaceText)
    }

    // MARK: - Code Completion

    func triggerCompletion() {
        let cursorPosition = shaderSource.endIndex
        completions = completionProvider.completions(for: shaderSource, at: cursorPosition)
        showingCompletions = !completions.isEmpty
    }

    func updateCompletions() {
        let cursorPosition = shaderSource.endIndex
        if completionProvider.shouldTriggerCompletion(for: shaderSource, at: cursorPosition) {
            completions = completionProvider.completions(for: shaderSource, at: cursorPosition)
            showingCompletions = !completions.isEmpty
        } else {
            showingCompletions = false
        }
    }

    func insertCompletion(_ item: CompletionItem) {
        let cursorPosition = shaderSource.endIndex
        if let range = completionProvider.wordRange(in: shaderSource, at: cursorPosition) {
            shaderSource.replaceSubrange(range, with: item.text)
        }
        showingCompletions = false
    }

    // MARK: - File Operations

    func scanDirectory(_ url: URL) {
        currentShader = nil
        shaders = []
        selectedPass = nil
        passLibraries = [:]
        compiler.clearPassState()

        let directoryType = WorkspaceService.analyzeDirectory(url)

        switch directoryType {
        case .shader(let shader):
            currentShader = shader
            fileTree = []
            passLibraries = compiler.compileShader(shader)
            selectedPass = shader.mainPass
            loadFile(shader.fileURL(for: shader.mainPass))

        case .project(let projectShaders):
            shaders = projectShaders
            fileTree = []
            if let firstShader = projectShaders.first {
                currentShader = firstShader
                passLibraries = compiler.compileShader(firstShader)
                selectedPass = firstShader.mainPass
                loadFile(firstShader.fileURL(for: firstShader.mainPass))
            }

        case .looseFiles:
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

    func loadFile(_ url: URL) {
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

            if autoCompile {
                compileNow()
            }
        } catch {
            fileError = .loadFailed(url.path)
            showingFileError = true
        }
    }

    func saveFile(_ url: URL) {
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

    func saveCurrentFile() {
        guard let url = selectedFileURL else { return }
        saveFile(url)
    }

    func handlePassSelection(_ pass: ShaderPass) {
        guard let project = currentShader else { return }
        if isFileDirty, let currentURL = selectedFileURL {
            saveFile(currentURL)
        }
        let fileURL = project.fileURL(for: pass)
        loadFile(fileURL)
        selectedPass = pass
    }

    func handleShaderUpdated(_ project: Shader) {
        passLibraries = compiler.compileShader(project)
        if let pass = selectedPass {
            let fileURL = project.fileURL(for: pass)
            loadFile(fileURL)
        }
        syncPreviewState()
    }

    // MARK: - Workspace Project Management

    func handleShaderSelection(_ project: Shader) {
        if isFileDirty, let url = selectedFileURL {
            saveFile(url)
        }
        currentShader = project
        passLibraries = compiler.compileShader(project)
        selectedPass = project.mainPass
        let fileURL = project.fileURL(for: project.mainPass)
        loadFile(fileURL)
        syncPreviewState()
    }

    func handleShaderCreated(_ url: URL, _ name: String) {
        do {
            let project = try ProjectConfigService.createShader(name: name, at: url)
            shaders.append(project)
            shaders.sort { $0.name < $1.name }
            handleShaderSelection(project)
        } catch {
            fileError = .projectError(error.localizedDescription)
            showingFileError = true
        }
    }

    func handleShaderRenamed(_ project: Shader, _ newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let workspaceURL = project.projectURL.deletingLastPathComponent()
        let newURL = workspaceURL.appendingPathComponent(trimmed)
        guard newURL != project.projectURL else { return }
        guard !FileManager.default.fileExists(atPath: newURL.path) else {
            fileError = .projectError("A folder named '\(trimmed)' already exists.")
            showingFileError = true
            return
        }
        do {
            try FileManager.default.moveItem(at: project.projectURL, to: newURL)
            let updated = Shader(
                id: project.id,
                version: project.version,
                name: trimmed,
                mainPass: project.mainPass,
                buffers: project.buffers,
                projectURL: newURL
            )
            try ProjectConfigService.saveShader(updated)
            if let idx = shaders.firstIndex(where: { $0.id == project.id }) {
                shaders[idx] = updated
            }
            shaders.sort { $0.name < $1.name }
            if currentShader?.id == project.id {
                currentShader = updated
                if let old = selectedFileURL, old.path.hasPrefix(project.projectURL.path) {
                    let rel = String(old.path.dropFirst(project.projectURL.path.count))
                    selectedFileURL = URL(fileURLWithPath: newURL.path + rel)
                }
            }
        } catch {
            fileError = .projectError(error.localizedDescription)
            showingFileError = true
        }
    }

    func handleShaderRemoved(_ project: Shader) {
        do {
            try FileManager.default.trashItem(at: project.projectURL, resultingItemURL: nil)
            shaders.removeAll { $0.id == project.id }
            compiler.clearPassState()
            if currentShader?.id == project.id {
                if let first = shaders.first {
                    handleShaderSelection(first)
                } else {
                    currentShader = nil
                    selectedPass = nil
                    selectedFileURL = nil
                    shaderSource = ""
                    savedSource = ""
                    passLibraries = [:]
                    syncPreviewState()
                }
            }
        } catch {
            fileError = .projectError(error.localizedDescription)
            showingFileError = true
        }
    }

    // MARK: - External File Changes

    func handleExternalFileChanges(_ changedURLs: Set<URL>) {
        for url in changedURLs {
            let filename = url.lastPathComponent.lowercased()

            if filename == "project.yaml" || filename == "project.yml" {
                if let dir = selectedDirectoryURL {
                    scanDirectory(dir)
                }
                return
            }

            if url == selectedFileURL {
                if isFileDirty { continue }
                do {
                    let content = try String(contentsOf: url, encoding: .utf8)
                    savedSource = content
                    shaderSource = content
                    isFileDirty = false
                    if autoCompile { compileNow() }
                } catch {}
            } else if let project = currentShader {
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

    // MARK: - New/Open File

    #if os(macOS)
    func openFilePanel() {
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

        panel.begin { [weak self] response in
            guard let self, response == .OK, let url = panel.url else { return }

            var directoryURL: URL
            if url.hasDirectoryPath {
                directoryURL = url
            } else if url.pathExtension == "yaml" || url.pathExtension == "yml" {
                directoryURL = url.deletingLastPathComponent()
            } else {
                directoryURL = url
            }

            self.selectedDirectoryURL = directoryURL
            self.scanDirectory(directoryURL)

            if ProjectConfigService.isShaderDirectory(directoryURL)
                || ProjectConfigService.isProjectDirectory(directoryURL)
            {
                self.addToRecentProjects(directoryURL)
            }
        }
    }
    #endif

    func createNewProject(at workspaceURL: URL, named projectName: String) {
        let projectURL = workspaceURL.appendingPathComponent(projectName)
        do {
            let project = try ProjectConfigService.createShader(
                name: projectName, at: projectURL)

            selectedDirectoryURL = workspaceURL
            currentShader = project
            shaders = [project]
            fileTree = []

            passLibraries = compiler.compileShader(project)
            selectedPass = project.mainPass
            loadFile(project.fileURL(for: project.mainPass))
            syncPreviewState()
            addToRecentProjects(workspaceURL)
        } catch {
            fileError = .projectError(error.localizedDescription)
            showingFileError = true
        }
    }

    // MARK: - Recent Projects

    func addToRecentProjects(_ url: URL) {
        RecentProjectsService.addRecentProject(url)
        recentProjects = RecentProjectsService.getRecentProjects()
    }

    func openRecentProject(_ url: URL) {
        selectedDirectoryURL = url
        scanDirectory(url)
        addToRecentProjects(url)
    }

    func clearRecentProjects() {
        RecentProjectsService.clearRecentProjects()
        recentProjects = []
    }

    // MARK: - Source Change Handling

    func handleSourceChanged(oldValue: String, newValue: String) {
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

    func handleSelectedFileURLChanged(_ newValue: URL?) {
        previewState?.selectedFileURL = newValue
        if newValue == nil && selectedDirectoryURL != nil {
            savedSource = ""
            shaderSource = ""
            isFileDirty = false
        } else if newValue == nil && selectedDirectoryURL == nil {
            savedSource = Self.defaultShader
            shaderSource = Self.defaultShader
            isFileDirty = false
        }
    }

    func handleDirectoryChanged(_ newValue: URL?) {
        if let dir = newValue {
            fileWatcher.watch(directory: dir)
            fileWatcher.onChange = { [weak self] changedURLs in
                self?.handleExternalFileChanges(changedURLs)
            }
        } else {
            fileWatcher.stop()
        }
    }
}
