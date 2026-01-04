//
//  FileNode.swift
//  ShaderTune
//
//  Created by Anthony Pardee on 1/4/26.
//

import Foundation

/// Represents a file or directory node in the file tree
struct FileNode: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let url: URL
    let isDirectory: Bool
    var children: [FileNode]?  // nil for files, array for directories

    var isMetalFile: Bool {
        !isDirectory && url.pathExtension == "metal"
    }

    // Computed property for sorting: directories first, then alphabetical
    var sortKey: String {
        (isDirectory ? "0_" : "1_") + name.lowercased()
    }
}

/// Builds a file tree from a directory URL
class FileTreeBuilder {
    func buildTree(from url: URL) throws -> [FileNode] {
        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        var nodes: [FileNode] = []

        for fileURL in contents {
            let resourceValues = try fileURL.resourceValues(forKeys: [.isDirectoryKey])
            let isDirectory = resourceValues.isDirectory ?? false

            var children: [FileNode]? = nil
            if isDirectory {
                // Recursively build children, but catch errors for unreadable dirs
                children = (try? buildTree(from: fileURL)) ?? []

                // Skip empty directories
                if children?.isEmpty ?? true {
                    continue
                }
            } else if fileURL.pathExtension != "metal" {
                // Skip non-.metal files
                continue
            }

            nodes.append(FileNode(
                name: fileURL.lastPathComponent,
                url: fileURL,
                isDirectory: isDirectory,
                children: children
            ))
        }

        // Sort: directories first, then alphabetically
        return nodes.sorted { $0.sortKey < $1.sortKey }
    }
}
