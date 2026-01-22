import Foundation
import AppKit
import Combine

enum SortOption: String, CaseIterable {
    case name = "Name"
    case size = "Size"
    case totalSize = "Total Size"
    
    var icon: String {
        switch self {
        case .name: return "textformat"
        case .size: return "square.stack.3d.up"
        case .totalSize: return "chart.bar"
        }
    }
}

@MainActor
class AppManager: ObservableObject {
    @Published var installedApps: [InstalledApp] = []
    @Published var selectedApp: InstalledApp?
    @Published var isLoading = false
    @Published var isDeleting = false
    @Published var searchText = ""
    @Published var sortOption: SortOption = .name
    @Published var showDeleteConfirmation = false
    @Published var deleteError: String?
    @Published var showRunningAppWarning = false
    @Published var showFullDiskAccessPrompt = false
    @Published var skippedFilesCount = 0
    var runningAppName: String = ""
    
    var filteredApps: [InstalledApp] {
        let filtered = searchText.isEmpty
            ? installedApps
            : installedApps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        
        switch sortOption {
        case .name:
            return filtered.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .size:
            return filtered.sorted { $0.size > $1.size }
        case .totalSize:
            return filtered.sorted { $0.totalSize > $1.totalSize }
        }
    }
    
    init() {
        Task {
            await loadInstalledApps()
        }
    }
    
    func loadInstalledApps() async {
        isLoading = true
        
        let apps = await Task.detached(priority: .userInitiated) {
            await self.scanApplications()
        }.value
        
        installedApps = apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        isLoading = false
    }
    
    private nonisolated func scanApplications() async -> [InstalledApp] {
        let fileManager = FileManager.default
        let applicationsURL = URL(fileURLWithPath: "/Applications")
        
        guard let contents = try? fileManager.contentsOfDirectory(
            at: applicationsURL,
            includingPropertiesForKeys: [.isApplicationKey, .totalFileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }
        
        var apps: [InstalledApp] = []
        
        for url in contents where url.pathExtension == "app" {
            if let app = createInstalledAppSync(from: url) {
                apps.append(app)
            }
        }
        
        // Also check user Applications folder
        let userAppsURL = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications")
        
        if let userContents = try? fileManager.contentsOfDirectory(
            at: userAppsURL,
            includingPropertiesForKeys: [.isApplicationKey],
            options: [.skipsHiddenFiles]
        ) {
            for url in userContents where url.pathExtension == "app" {
                if let app = createInstalledAppSync(from: url) {
                    apps.append(app)
                }
            }
        }
        
        return apps
    }
    
    private func createInstalledApp(from url: URL) -> InstalledApp? {
        createInstalledAppSync(from: url)
    }
    
    private nonisolated func createInstalledAppSync(from url: URL) -> InstalledApp? {
        let bundle = Bundle(url: url)
        let bundleIdentifier = bundle?.bundleIdentifier ?? url.deletingPathExtension().lastPathComponent
        
        let name = (bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String)
            ?? url.deletingPathExtension().lastPathComponent
        
        var icon: NSImage?
        DispatchQueue.main.sync {
            icon = NSWorkspace.shared.icon(forFile: url.path)
            icon?.size = NSSize(width: 64, height: 64)
        }
        
        let size = calculateDirectorySizeSync(url)
        let relatedFiles = findRelatedFilesSync(for: bundleIdentifier, appName: name)
        
        return InstalledApp(
            name: name,
            bundleIdentifier: bundleIdentifier,
            path: url,
            icon: icon ?? NSImage(),
            size: size,
            relatedFiles: relatedFiles
        )
    }
    
    private nonisolated func calculateDirectorySizeSync(_ url: URL) -> Int64 {
        let fileManager = FileManager.default
        var totalSize: Int64 = 0
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }
        
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey]),
                  resourceValues.isDirectory == false,
                  let fileSize = resourceValues.fileSize else { continue }
            totalSize += Int64(fileSize)
        }
        
        return totalSize
    }
    
    func findRelatedFiles(for bundleIdentifier: String, appName: String) -> [RelatedFile] {
        findRelatedFilesSync(for: bundleIdentifier, appName: appName)
    }
    
    private nonisolated func findRelatedFilesSync(for bundleIdentifier: String, appName: String) -> [RelatedFile] {
        var relatedFiles: [RelatedFile] = []
        let fileManager = FileManager.default
        let homeDir = fileManager.homeDirectoryForCurrentUser
        
        let searchPaths: [(URL, RelatedFile.FileType)] = [
            (homeDir.appendingPathComponent("Library/Preferences"), .preferences),
            (homeDir.appendingPathComponent("Library/Caches"), .cache),
            (homeDir.appendingPathComponent("Library/Application Support"), .applicationSupport),
            (homeDir.appendingPathComponent("Library/Logs"), .logs),
            (homeDir.appendingPathComponent("Library/Containers"), .containers),
            (homeDir.appendingPathComponent("Library/Saved Application State"), .savedState),
            (homeDir.appendingPathComponent("Library/Cookies"), .cookies),
            (homeDir.appendingPathComponent("Library/Application Scripts"), .other),
            (homeDir.appendingPathComponent("Library/Group Containers"), .containers),
        ]
        
        let searchTerms = [
            bundleIdentifier,
            bundleIdentifier.lowercased(),
            appName,
            appName.lowercased(),
            appName.replacingOccurrences(of: " ", with: ""),
            appName.replacingOccurrences(of: " ", with: "-"),
        ]
        
        for (basePath, fileType) in searchPaths {
            guard let contents = try? fileManager.contentsOfDirectory(
                at: basePath,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) else { continue }
            
            for item in contents {
                let itemName = item.lastPathComponent
                for term in searchTerms {
                    if itemName.localizedCaseInsensitiveContains(term) {
                        let size = calculateDirectorySizeSync(item)
                        if size > 0 || fileManager.fileExists(atPath: item.path) {
                            let file = RelatedFile(
                                path: item,
                                size: size > 0 ? size : (try? fileManager.attributesOfItem(atPath: item.path)[.size] as? Int64) ?? 0,
                                type: fileType
                            )
                            if !relatedFiles.contains(where: { $0.path == file.path }) {
                                relatedFiles.append(file)
                            }
                        }
                        break
                    }
                }
            }
        }
        
        return relatedFiles.sorted { $0.size > $1.size }
    }
    
    func selectApp(_ app: InstalledApp) {
        var updatedApp = app
        updatedApp.relatedFiles = findRelatedFiles(for: app.bundleIdentifier, appName: app.name)
        selectedApp = updatedApp
    }
    
    func toggleFileSelection(at index: Int) {
        guard var app = selectedApp, index < app.relatedFiles.count else { return }
        app.relatedFiles[index].isSelected.toggle()
        selectedApp = app
    }
    
    func isAppRunning(_ bundleIdentifier: String) -> Bool {
        NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == bundleIdentifier }
    }
    
    func quitApp(_ bundleIdentifier: String) {
        if let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleIdentifier }) {
            app.terminate()
        }
    }
    
    func deleteSelectedApp() async {
        guard let app = selectedApp else { return }
        
        if isAppRunning(app.bundleIdentifier) {
            showRunningAppWarning = true
            runningAppName = app.name
            return
        }
        
        isDeleting = true
        deleteError = nil
        
        // Collect all paths to delete
        var pathsToDelete: [String] = []
        
        // Add related files first
        for file in app.relatedFiles where file.isSelected {
            pathsToDelete.append(file.path.path)
        }
        
        // Add the app itself
        pathsToDelete.append(app.path.path)
        
        do {
            try await trashItemsWithPrivileges(paths: pathsToDelete)
            
            // Remove from list on success
            installedApps.removeAll { $0.id == app.id }
            selectedApp = nil
            showDeleteConfirmation = false
            
        } catch {
            deleteError = error.localizedDescription
        }
        
        isDeleting = false
    }
    
    func forceDeleteSelectedApp() async {
        guard let app = selectedApp else { return }
        
        quitApp(app.bundleIdentifier)
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        isDeleting = true
        deleteError = nil
        
        var pathsToDelete: [String] = []
        
        for file in app.relatedFiles where file.isSelected {
            pathsToDelete.append(file.path.path)
        }
        
        pathsToDelete.append(app.path.path)
        
        do {
            try await trashItemsWithPrivileges(paths: pathsToDelete)
            
            installedApps.removeAll { $0.id == app.id }
            selectedApp = nil
            showDeleteConfirmation = false
            
        } catch {
            deleteError = error.localizedDescription
        }
        
        isDeleting = false
    }
    
    private func trashItemsWithPrivileges(paths: [String]) async throws {
        let fileManager = FileManager.default
        
        var failedPaths: [String] = []
        var protectedPaths: [String] = []
        
        // First try without privileges for user-owned files
        for path in paths {
            if fileManager.fileExists(atPath: path) {
                do {
                    try fileManager.trashItem(at: URL(fileURLWithPath: path), resultingItemURL: nil)
                } catch {
                    failedPaths.append(path)
                }
            }
        }
        
        // If some failed, try with Finder
        if !failedPaths.isEmpty {
            let pathList = failedPaths.map { "POSIX file \"\($0)\"" }.joined(separator: ", ")
            
            let script = """
            tell application "Finder"
                move {\(pathList)} to trash
            end tell
            """
            
            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: script) {
                appleScript.executeAndReturnError(&error)
                
                if error != nil {
                    // Finder failed, try with admin privileges
                    let adminScript = """
                    do shell script "for f in \(failedPaths.map { "'\($0.replacingOccurrences(of: "'", with: "'\\''"))'" }.joined(separator: " ")); do mv \\"$f\\" ~/.Trash/ 2>/dev/null || rm -rf \\"$f\\" 2>/dev/null || echo \\"PROTECTED:$f\\"; done" with administrator privileges
                    """
                    
                    var adminError: NSDictionary?
                    if let adminAppleScript = NSAppleScript(source: adminScript) {
                        let result = adminAppleScript.executeAndReturnError(&adminError)
                        
                        // Check for protected files in output
                        if let output = result.stringValue {
                            let lines = output.components(separatedBy: "\n")
                            for line in lines {
                                if line.hasPrefix("PROTECTED:") {
                                    let protectedPath = String(line.dropFirst("PROTECTED:".count))
                                    protectedPaths.append(protectedPath)
                                }
                            }
                        }
                        
                        if let adminError = adminError {
                            let errorMessage = adminError["NSAppleScriptErrorMessage"] as? String ?? ""
                            // Only throw if it's not a "user cancelled" error
                            if !errorMessage.contains("cancel") {
                                throw NSError(
                                    domain: "CleanMac",
                                    code: -1,
                                    userInfo: [NSLocalizedDescriptionKey: errorMessage]
                                )
                            }
                        }
                    }
                }
            }
        }
        
        // Check which files still exist (protected by SIP/TCC)
        for path in failedPaths {
            if fileManager.fileExists(atPath: path) {
                protectedPaths.append(path)
            }
        }
        
        // Notify about protected files
        if !protectedPaths.isEmpty {
            skippedFilesCount = protectedPaths.count
            showFullDiskAccessPrompt = true
        }
    }
    
    func checkFullDiskAccess() -> Bool {
        let testPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Containers")
            .appendingPathComponent(".test_fda_\(UUID().uuidString)")
        
        do {
            try "test".write(to: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(at: testPath)
            return true
        } catch {
            return false
        }
    }
    
    func openFullDiskAccessSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }
}
