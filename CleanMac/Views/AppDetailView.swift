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
                HStack(spacing: 16) {
                    Image(nsImage: app.icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 88, height: 88)
                        .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(app.name)
                            .font(.title)
                            .fontWeight(.semibold)
                        
                        Label(app.bundleIdentifier, systemImage: "app.badge")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Size Stats
                HStack(spacing: 12) {
                    StatBox(title: "App Size", value: app.formattedSize, icon: "app.fill")
                    StatBox(title: "Related Files", value: ByteCountFormatter.string(fromByteCount: selectedFilesSize, countStyle: .file), icon: "doc.fill")
                    StatBox(title: "Total", value: ByteCountFormatter.string(fromByteCount: app.size + selectedFilesSize, countStyle: .file), icon: "chart.pie.fill", accent: true)
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [.clear, Color.accentColor.opacity(0.06)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            Divider()
            
            // Related Files Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Related Files")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if !app.relatedFiles.isEmpty {
                        HStack(spacing: 8) {
                            Button("Select All") {
                                for index in app.relatedFiles.indices {
                                    if !app.relatedFiles[index].isSelected {
                                        appManager.toggleFileSelection(at: index)
                                    }
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            
                            Button("Deselect All") {
                                for index in app.relatedFiles.indices {
                                    if app.relatedFiles[index].isSelected {
                                        appManager.toggleFileSelection(at: index)
                                    }
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
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
                    List {
                        ForEach(Array(app.relatedFiles.enumerated()), id: \.element.id) { index, file in
                            RelatedFileRow(file: file, isHovered: hoveredFileId == file.id)
                                .listRowInsets(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
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
                    .listStyle(.inset)
                    .scrollContentBackground(.hidden)
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
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
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
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.callout)
                    .foregroundStyle(accent ? Color.accentColor : .secondary)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.secondary.opacity(0.12))
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
                .background(Color.secondary.opacity(0.12))
                .clipShape(Capsule())
            
            Text(file.formattedSize)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovered ? Color.secondary.opacity(0.08) : (file.isSelected ? Color.accentColor.opacity(0.06) : Color.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.secondary.opacity(isHovered ? 0.2 : 0.08))
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
