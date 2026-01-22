import Foundation

@MainActor
class JunkCleaner: ObservableObject {
    @Published var categories: [JunkCategory] = []
    @Published var isScanning: Bool = false
    @Published var isCleaning: Bool = false
    @Published var cleanError: String?
    
    var totalSelectedSize: Int64 {
        categories.reduce(0) { $0 + $1.totalSize }
    }
    
    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSelectedSize, countStyle: .file)
    }
    
    private struct JunkLocation {
        let name: String
        let icon: String
        let description: String
        let path: String
        let scanSubdirectories: Bool
    }
    
    private let junkLocations: [JunkLocation] = [
        JunkLocation(
            name: "Xcode DerivedData",
            icon: "hammer.fill",
            description: "Build artifacts and intermediate files",
            path: "~/Library/Developer/Xcode/DerivedData",
            scanSubdirectories: false
        ),
        JunkLocation(
            name: "Xcode Archives",
            icon: "archivebox.fill",
            description: "Old app archives for distribution",
            path: "~/Library/Developer/Xcode/Archives",
            scanSubdirectories: false
        ),
        JunkLocation(
            name: "Xcode Device Support",
            icon: "iphone",
            description: "iOS device debug symbols",
            path: "~/Library/Developer/Xcode/iOS DeviceSupport",
            scanSubdirectories: false
        ),
        JunkLocation(
            name: "User Caches",
            icon: "cylinder.fill",
            description: "Application cache files",
            path: "~/Library/Caches",
            scanSubdirectories: true
        ),
        JunkLocation(
            name: "System Logs",
            icon: "doc.text.fill",
            description: "Application and system log files",
            path: "~/Library/Logs",
            scanSubdirectories: false
        ),
        JunkLocation(
            name: "Safari Cache",
            icon: "safari.fill",
            description: "Safari browser cache",
            path: "~/Library/Caches/com.apple.Safari",
            scanSubdirectories: false
        ),
        JunkLocation(
            name: "Chrome Cache",
            icon: "globe",
            description: "Google Chrome browser cache",
            path: "~/Library/Caches/Google/Chrome",
            scanSubdirectories: false
        ),
        JunkLocation(
            name: "Homebrew Cache",
            icon: "shippingbox.fill",
            description: "Downloaded package files",
            path: "~/Library/Caches/Homebrew",
            scanSubdirectories: false
        )
    ]
    
    func scan() async {
        isScanning = true
        categories = []
        
        await withTaskGroup(of: JunkCategory?.self) { group in
            for location in junkLocations {
                group.addTask {
                    await self.scanLocation(location)
                }
            }
            
            for await category in group {
                if let category = category, !category.items.isEmpty {
                    categories.append(category)
                }
            }
        }
        
        categories.sort { $0.totalSize > $1.totalSize }
        isScanning = false
    }
    
    private func scanLocation(_ location: JunkLocation) async -> JunkCategory? {
        let expandedPath = NSString(string: location.path).expandingTildeInPath
        let url = URL(fileURLWithPath: expandedPath)
        
        guard FileManager.default.fileExists(atPath: expandedPath) else {
            return nil
        }
        
        var items: [JunkItem] = []
        
        if location.scanSubdirectories {
            if let contents = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .isDirectoryKey]) {
                for itemURL in contents {
                    let size = calculateSize(at: itemURL)
                    if size > 0 {
                        items.append(JunkItem(path: itemURL, size: size))
                    }
                }
            }
        } else {
            if let contents = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .isDirectoryKey]) {
                for itemURL in contents {
                    let size = calculateSize(at: itemURL)
                    if size > 0 {
                        items.append(JunkItem(path: itemURL, size: size))
                    }
                }
            }
        }
        
        items.sort { $0.size > $1.size }
        
        return JunkCategory(
            name: location.name,
            icon: location.icon,
            description: location.description,
            items: items
        )
    }
    
    private func calculateSize(at url: URL) -> Int64 {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return 0
        }
        
        if isDirectory.boolValue {
            var totalSize: Int64 = 0
            if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.totalFileAllocatedSizeKey], options: [.skipsHiddenFiles]) {
                for case let fileURL as URL in enumerator {
                    if let resourceValues = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey]),
                       let size = resourceValues.totalFileAllocatedSize {
                        totalSize += Int64(size)
                    }
                }
            }
            return totalSize
        } else {
            if let resourceValues = try? url.resourceValues(forKeys: [.totalFileAllocatedSizeKey]),
               let size = resourceValues.totalFileAllocatedSize {
                return Int64(size)
            }
            return 0
        }
    }
    
    func clean() async {
        isCleaning = true
        cleanError = nil
        
        for categoryIndex in categories.indices {
            for itemIndex in categories[categoryIndex].items.indices {
                let item = categories[categoryIndex].items[itemIndex]
                if item.isSelected {
                    do {
                        try FileManager.default.trashItem(at: item.path, resultingItemURL: nil)
                    } catch {
                        cleanError = "Failed to delete \(item.name): \(error.localizedDescription)"
                    }
                }
            }
        }
        
        await scan()
        isCleaning = false
    }
    
    func toggleCategory(_ category: JunkCategory) {
        guard let index = categories.firstIndex(where: { $0.id == category.id }) else { return }
        let newState = !categories[index].isSelected
        categories[index].isSelected = newState
        for itemIndex in categories[index].items.indices {
            categories[index].items[itemIndex].isSelected = newState
        }
    }
    
    func toggleItem(_ item: JunkItem, in category: JunkCategory) {
        guard let categoryIndex = categories.firstIndex(where: { $0.id == category.id }),
              let itemIndex = categories[categoryIndex].items.firstIndex(where: { $0.id == item.id }) else { return }
        categories[categoryIndex].items[itemIndex].isSelected.toggle()
        
        let allSelected = categories[categoryIndex].items.allSatisfy { $0.isSelected }
        categories[categoryIndex].isSelected = allSelected
    }
}
