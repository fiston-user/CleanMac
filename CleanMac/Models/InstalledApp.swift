import Foundation
import AppKit

struct InstalledApp: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let bundleIdentifier: String
    let path: URL
    let icon: NSImage
    let size: Int64
    var relatedFiles: [RelatedFile]
    
    var totalSize: Int64 {
        size + relatedFiles.reduce(0) { $0 + $1.size }
    }
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    static func == (lhs: InstalledApp, rhs: InstalledApp) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct RelatedFile: Identifiable, Hashable {
    let id = UUID()
    let path: URL
    let size: Int64
    let type: FileType
    var isSelected: Bool = true
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var displayPath: String {
        path.path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
    }
    
    enum FileType: String, CaseIterable {
        case preferences = "Preferences"
        case cache = "Caches"
        case applicationSupport = "Application Support"
        case logs = "Logs"
        case containers = "Containers"
        case savedState = "Saved Application State"
        case cookies = "Cookies"
        case crashReports = "Crash Reports"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .preferences: return "gearshape"
            case .cache: return "arrow.triangle.2.circlepath"
            case .applicationSupport: return "folder"
            case .logs: return "doc.text"
            case .containers: return "shippingbox"
            case .savedState: return "arrow.counterclockwise"
            case .cookies: return "circle.grid.2x2"
            case .crashReports: return "exclamationmark.triangle"
            case .other: return "doc"
            }
        }
    }
}
