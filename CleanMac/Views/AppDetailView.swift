import SwiftUI

struct AppDetailView: View {
    let app: InstalledApp
    @EnvironmentObject var appManager: AppManager
    @State private var hoveredFileId: UUID?
    
    var selectedFilesSize: Int64 {
        app.relatedFiles.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
    }
    
    var selectedFilesCount: Int {
        app.relatedFiles.filter { $0.isSelected }.count
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
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                LoadingView("Uninstalling \(app.name)", subtitle: "Moving files to Trash...")
            }
            .padding(40)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    appHeaderCard
                    
                    if !app.relatedFiles.isEmpty {
                        relatedFilesSection
                    } else {
                        noFilesCard
                    }
                }
                .padding(16)
            }
            
            footerBar
        }
    }
    
    private var appHeaderCard: some View {
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                Image(nsImage: app.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(app.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(app.bundleIdentifier)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    Text(app.path.path)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                StatCard(
                    icon: "app.fill",
                    title: "App",
                    value: app.formattedSize,
                    color: .blue
                )
                
                StatCard(
                    icon: "doc.on.doc.fill",
                    title: "Files",
                    value: ByteCountFormatter.string(fromByteCount: selectedFilesSize, countStyle: .file),
                    color: .orange
                )
                
                StatCard(
                    icon: "sum",
                    title: "Total",
                    value: ByteCountFormatter.string(fromByteCount: app.size + selectedFilesSize, countStyle: .file),
                    color: .red
                )
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.primary.opacity(0.06))
        )
    }
    
    private var noFilesCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 44))
                .foregroundStyle(.green.gradient)
            
            Text("No Leftover Files")
                .font(.headline)
            
            Text("This app doesn't have any related files to clean up.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.primary.opacity(0.06))
        )
    }
    
    private var relatedFilesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Related Files", systemImage: "folder.fill")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Text("(\(selectedFilesCount)/\(app.relatedFiles.count))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                
                Spacer()
                
                Button {
                    for index in app.relatedFiles.indices {
                        if !app.relatedFiles[index].isSelected {
                            appManager.toggleFileSelection(at: index)
                        }
                    }
                } label: {
                    Text("All")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button {
                    for index in app.relatedFiles.indices {
                        if app.relatedFiles[index].isSelected {
                            appManager.toggleFileSelection(at: index)
                        }
                    }
                } label: {
                    Text("None")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 6) {
                ForEach(Array(app.relatedFiles.enumerated()), id: \.element.id) { index, file in
                    FileRow(file: file, isHovered: hoveredFileId == file.id)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                appManager.toggleFileSelection(at: index)
                            }
                        }
                        .onHover { hovering in
                            hoveredFileId = hovering ? file.id : nil
                        }
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.primary.opacity(0.06))
        )
    }
    
    private var footerBar: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Ready to uninstall")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("App + \(selectedFilesCount) related files")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                appManager.showDeleteConfirmation = true
            } label: {
                Label("Uninstall", systemImage: "trash.fill")
                    .frame(minWidth: 120)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
            .disabled(appManager.isDeleting)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct FileRow: View {
    let file: RelatedFile
    let isHovered: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(file.isSelected ? Color.accentColor : Color.secondary.opacity(0.15))
                    .frame(width: 24, height: 24)
                
                Image(systemName: file.isSelected ? "checkmark" : "")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
            }
            
            Image(systemName: file.type.icon)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(file.path.lastPathComponent)
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(file.displayPath)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(file.type.rawValue)
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1))
                .clipShape(Capsule())
            
            Text(file.formattedSize)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .frame(minWidth: 60, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovered ? Color.accentColor.opacity(0.08) : Color.clear)
        )
        .contentShape(Rectangle())
    }
    
    private var iconColor: Color {
        switch file.type {
        case .preferences: return .blue
        case .cache: return .orange
        case .applicationSupport: return .purple
        case .logs: return .green
        case .containers: return .pink
        case .savedState: return .teal
        case .cookies: return .brown
        case .crashReports: return .red
        case .other: return .gray
        }
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
    .frame(width: 550, height: 650)
}
