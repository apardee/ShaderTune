//
//  RecentProjectsService.swift
//  ShaderTune
//
//  Service for tracking and persisting recently opened projects
//

import Foundation

/// Service for managing recently opened project URLs
class RecentProjectsService {
    private static let maxRecentProjects = 10
    private static let userDefaultsKey = "recentProjects"

    /// Get the list of recently opened project URLs
    static func getRecentProjects() -> [URL] {
        guard
            let bookmarks = UserDefaults.standard.array(forKey: userDefaultsKey)
                as? [Data]
        else {
            return []
        }

        var urls: [URL] = []
        for bookmark in bookmarks {
            var isStale = false
            guard
                let url = try? URL(
                    resolvingBookmarkData: bookmark,
                    options: .withSecurityScope,
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                ),
                !isStale
            else {
                continue
            }

            // Verify the directory still exists
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
                isDirectory.boolValue
            {
                urls.append(url)
            }
        }

        return urls
    }

    /// Add a project URL to the recent projects list
    static func addRecentProject(_ url: URL) {
        var recentURLs = getRecentProjects()

        // Remove the URL if it already exists (we'll add it to the front)
        recentURLs.removeAll { $0 == url }

        // Add to the front
        recentURLs.insert(url, at: 0)

        // Limit to max count
        if recentURLs.count > maxRecentProjects {
            recentURLs = Array(recentURLs.prefix(maxRecentProjects))
        }

        // Convert to security-scoped bookmarks and save
        let bookmarks = recentURLs.compactMap { url -> Data? in
            try? url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
        }

        UserDefaults.standard.set(bookmarks, forKey: userDefaultsKey)
    }

    /// Clear all recent projects
    static func clearRecentProjects() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }

    /// Get display name for a project URL
    static func displayName(for url: URL) -> String {
        return url.lastPathComponent
    }
}
