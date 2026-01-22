import SwiftUI

struct AppListView: View {
    @EnvironmentObject var appManager: AppManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    
                    Text("CleanMac")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button {
                                appManager.sortOption = option
                            } label: {
                                Label(option.rawValue, systemImage: option.icon)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: appManager.sortOption.icon)
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                    .foregroundStyle(.secondary)
                    
                    Button {
                        Task {
                            await appManager.loadInstalledApps()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.body)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
                
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    
                    TextField("Search apps...", text: $appManager.searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(.quaternary.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding()
            
            Divider()
            
            // App List
            if appManager.isLoading {
                AppLoadingView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(appManager.filteredApps) { app in
                            AppRowView(app: app, isSelected: appManager.selectedApp?.id == app.id)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        appManager.selectApp(app)
                                    }
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }
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
        .background(VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow))
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
                    .fontWeight(.medium)
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
                    .background(.blue.opacity(0.15))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isSelected ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
    }
}

#Preview {
    AppListView()
        .environmentObject(AppManager())
        .frame(width: 300, height: 600)
}
