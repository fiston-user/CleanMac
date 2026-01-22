import SwiftUI

struct AppListView: View {
    @EnvironmentObject var appManager: AppManager
    
    var body: some View {
        VStack(spacing: 0) {
            if appManager.isLoading {
                AppLoadingView()
            } else {
                List {
                    if appManager.filteredApps.isEmpty {
                        Group {
                            if #available(macOS 14.0, *) {
                                ContentUnavailableView("No Apps Found", systemImage: "magnifyingglass", description: Text("Try a different search."))
                            } else {
                                VStack(spacing: 8) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 36))
                                        .foregroundStyle(.secondary)
                                    Text("No Apps Found")
                                        .font(.headline)
                                    Text("Try a different search.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(.vertical, 24)
                            }
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(appManager.filteredApps) { app in
                            AppRowView(app: app, isSelected: appManager.selectedApp?.id == app.id)
                                .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                                .listRowSeparator(.hidden)
                                .listRowBackground(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(appManager.selectedApp?.id == app.id ? Color.accentColor.opacity(0.12) : Color.clear)
                                        .padding(.horizontal, 8)
                                )
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        appManager.selectApp(app)
                                    }
                                }
                        }
                    }
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
            }
            
            Divider()
            
            // Footer Stats
            HStack {
                Text("\(appManager.installedApps.count) apps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                let totalSize = appManager.installedApps.reduce(0) { $0 + $1.totalSize }
                Text(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .searchable(text: $appManager.searchText, placement: .sidebar, prompt: "Search apps")
        .navigationTitle("CleanMac")
    }
}

struct AppRowView: View {
    let app: InstalledApp
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: app.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 36, height: 36)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .lineLimit(1)
                
                Text(app.formattedTotalSize)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if !app.relatedFiles.isEmpty {
                Text("\(app.relatedFiles.count)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary.opacity(0.6))
                    .foregroundStyle(.secondary)
                    .clipShape(Capsule())
            }
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    AppListView()
        .environmentObject(AppManager())
        .frame(width: 300, height: 600)
}
