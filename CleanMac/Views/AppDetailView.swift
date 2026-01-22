import SwiftUI

struct AppDetailView: View {
    let app: InstalledApp
    @EnvironmentObject var appManager: AppManager
    @State private var hoveredFileId: UUID?
    
    var selectedFilesSize: Int64 {
        app.relatedFiles.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
    }
    
    var body: some View {
        ZStack {
            mainContent
            
            if appManager.isDeleting {
                deletingOverlay
            }
        }
    }
    
    private var deletingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                LoadingView("Uninstalling \(app.name)", subtitle: "Moving files to Trash...")
            }
            .padding(40)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            // App Header
            VStack(spacing: 16) {
                Image(nsImage: app.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 96, height: 96)
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                
                VStack(spacing: 4) {
                    Text(app.name)
                        .font(.title)
                        .fontWeight(.semibold)
                    
                    Text(app.bundleIdentifier)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Size Stats
                HStack(spacing: 24) {
                    StatBox(title: "App Size", value: app.formattedSize, icon: "app.fill")
                    StatBox(title: "Related Files", value: ByteCountFormatter.string(fromByteCount: selectedFilesSize, countStyle: .file), icon: "doc.fill")
                    StatBox(title: "Total", value: ByteCountFormatter.string(fromByteCount: app.size + selectedFilesSize, countStyle: .file), icon: "chart.pie.fill", accent: true)
                }
            }
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [.clear, Color.accentColor.opacity(0.03)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            Divider()
            
            // Related Files Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Related Files")
                        .font(.headline)
                    
                    Spacer()
                    
                    if !app.relatedFiles.isEmpty {
                        Button("Select All") {
                            for index in app.relatedFiles.indices {
                                if !app.relatedFiles[index].isSelected {
                                    appManager.toggleFileSelection(at: index)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .font(.caption)
                        .foregroundStyle(.blue)
                        
                        Text("•")
                            .foregroundStyle(.secondary)
                        
                        Button("Deselect All") {
                            for index in app.relatedFiles.indices {
                                if app.relatedFiles[index].isSelected {
                                    appManager.toggleFileSelection(at: index)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .font(.caption)
                        .foregroundStyle(.blue)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                
                if app.relatedFiles.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle")
                            .font(.largeTitle)
                            .foregroundStyle(.green)
                        Text("No additional files found")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(Array(app.relatedFiles.enumerated()), id: \.element.id) { index, file in
                                RelatedFileRow(file: file, isHovered: hoveredFileId == file.id)
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.1)) {
                                            appManager.toggleFileSelection(at: index)
                                        }
                                    }
                                    .onHover { hovering in
                                        hoveredFileId = hovering ? file.id : nil
                                    }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }
                }
            }
            
            Divider()
            
            // Delete Button
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ready to clean")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    let selectedCount = app.relatedFiles.filter { $0.isSelected }.count
                    Text("App + \(selectedCount) files")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                
                Spacer()
                
                Button {
                    appManager.showDeleteConfirmation = true
                } label: {
                    HStack(spacing: 6) {
                        if appManager.isDeleting {
                            ProgressView()
                                .scaleEffect(0.6)
                        } else {
                            Image(systemName: "trash")
                        }
                        Text("Uninstall")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(appManager.isDeleting)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    var accent: Bool = false
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(accent ? .blue : .secondary)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 100)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.quaternary.opacity(0.3))
        )
    }
}

struct RelatedFileRow: View {
    let file: RelatedFile
    let isHovered: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: file.isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(file.isSelected ? .blue : .secondary)
            
            Image(systemName: file.type.icon)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(file.path.lastPathComponent)
                    .font(.body)
                    .lineLimit(1)
                
                Text(file.displayPath)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(file.type.rawValue)
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.quaternary)
                .clipShape(Capsule())
            
            Text(file.formattedSize)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.secondary.opacity(0.1) : (file.isSelected ? Color.blue.opacity(0.05) : Color.clear))
        )
        .contentShape(Rectangle())
    }
}

#Preview {
    AppDetailView(app: InstalledApp(
        name: "Example App",
        bundleIdentifier: "com.example.app",
        path: URL(fileURLWithPath: "/Applications/Example.app"),
        icon: NSImage(systemSymbolName: "app.fill", accessibilityDescription: nil)!,
        size: 104857600,
        relatedFiles: []
    ))
    .environmentObject(AppManager())
    .frame(width: 500, height: 600)
}
