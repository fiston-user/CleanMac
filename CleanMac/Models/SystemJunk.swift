import Foundation

struct JunkCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let description: String
    var items: [JunkItem]
    var isSelected: Bool = true
    
    var totalSize: Int64 {
        items.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
    }
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
}

struct JunkItem: Identifiable, Hashable {
    let id = UUID()
    let path: URL
    let size: Int64
    var isSelected: Bool = true
    
    var name: String { path.lastPathComponent }
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}
