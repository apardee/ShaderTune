import CoreServices
import Foundation

/// Watches a directory for `.metal` and `project.yaml` file changes using FSEvents.
/// Provides debounced callbacks filtered to relevant file types.
///
/// All mutable state is accessed exclusively on `queue` (a serial dispatch queue)
/// to avoid data races between the main thread and FSEvents callbacks.
final class FileWatcherService: @unchecked Sendable {
    nonisolated(unsafe) private var stream: FSEventStreamRef?
    private var watchedDirectory: URL?
    private var debounceWorkItem: DispatchWorkItem?
    private var pendingChangedURLs: Set<URL> = []
    private let debounceInterval: TimeInterval = 0.5
    private let queue = DispatchQueue(label: "com.shadertune.filewatcher", qos: .utility)

    /// Timestamps of recent saves made by this app, used to ignore self-triggered events.
    private var recentSaveTimestamps: [URL: Date] = [:]
    private let saveIgnoreWindow: TimeInterval = 1.0

    /// Called on the main queue when relevant files change externally.
    var onChange: ((_ changedURLs: Set<URL>) -> Void)?

    deinit {
        if let stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
        }
    }

    // MARK: - Public API

    /// Start watching a directory for file changes. Stops any previous watch.
    func watch(directory: URL) {
        stop()
        watchedDirectory = directory

        var context = FSEventStreamContext()
        context.info = Unmanaged.passUnretained(self).toOpaque()

        let pathToWatch = directory.path as CFString
        let paths = [pathToWatch] as CFArray

        let callback: FSEventStreamCallback = {
            _, clientInfo, numEvents, eventPaths, _, _ in
            guard let clientInfo else { return }
            let watcher = Unmanaged<FileWatcherService>.fromOpaque(clientInfo)
                .takeUnretainedValue()

            guard let cfPaths = unsafeBitCast(eventPaths, to: CFArray?.self) else { return }
            let count = CFArrayGetCount(cfPaths)
            var paths: [String] = []
            for i in 0..<count {
                if let cfStr = CFArrayGetValueAtIndex(cfPaths, i) {
                    let str = unsafeBitCast(cfStr, to: CFString.self) as String
                    paths.append(str)
                }
            }
            watcher.handlePaths(paths)
        }

        guard
            let stream = FSEventStreamCreate(
                nil,
                callback,
                &context,
                paths,
                FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
                0.3,
                UInt32(
                    kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes
                        | kFSEventStreamCreateFlagNoDefer)
            )
        else { return }

        self.stream = stream
        FSEventStreamSetDispatchQueue(stream, queue)
        FSEventStreamStart(stream)
    }

    /// Stop watching.
    func stop() {
        queue.sync {
            debounceWorkItem?.cancel()
            debounceWorkItem = nil
            pendingChangedURLs.removeAll()
            recentSaveTimestamps.removeAll()
        }

        if let stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
        }
        stream = nil
        watchedDirectory = nil
    }

    /// Mark a URL as recently saved by this app so the watcher ignores the resulting event.
    func markSaved(_ url: URL) {
        queue.async {
            self.recentSaveTimestamps[url] = Date()
        }
    }

    // MARK: - Internal

    /// Called on `queue` from the FSEvents callback — all state access is safe here.
    private func handlePaths(_ paths: [String]) {
        let now = Date()

        // Prune stale save timestamps
        recentSaveTimestamps = recentSaveTimestamps.filter {
            now.timeIntervalSince($0.value) < saveIgnoreWindow
        }

        for path in paths {
            let url = URL(fileURLWithPath: path)
            let ext = url.pathExtension.lowercased()
            let filename = url.lastPathComponent.lowercased()

            // Only care about .metal files and project.yaml/yml
            let isRelevant =
                ext == "metal" || filename == "project.yaml" || filename == "project.yml"
            guard isRelevant else { continue }

            // Skip if this was our own save
            if let savedAt = recentSaveTimestamps[url],
                now.timeIntervalSince(savedAt) < saveIgnoreWindow
            {
                continue
            }

            pendingChangedURLs.insert(url)
        }

        guard !pendingChangedURLs.isEmpty else { return }

        // Debounce: coalesce rapid changes into a single callback
        debounceWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self, !self.pendingChangedURLs.isEmpty else { return }
            let urls = self.pendingChangedURLs
            self.pendingChangedURLs.removeAll()
            DispatchQueue.main.async {
                self.onChange?(urls)
            }
        }
        debounceWorkItem = workItem
        queue.asyncAfter(deadline: .now() + debounceInterval, execute: workItem)
    }
}
