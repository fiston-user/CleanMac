import SwiftUI

enum AppMode: String, CaseIterable {
    case apps = "Apps"
    case systemJunk = "System Junk"
    
    var icon: String {
        switch self {
        case .apps: return "app.badge.checkmark"
        case .systemJunk: return "trash.fill"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var appManager: AppManager
    @StateObject private var junkCleaner = JunkCleaner()
    @State private var currentMode: AppMode = .apps
    
    var body: some View {
        ZStack {
            VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            HStack(spacing: 0) {
                sidebarView
                    .frame(width: 300)
                
                Divider()
                
                detailView
            }
        }
        .alert("Delete \(appManager.selectedApp?.name ?? "App")?", isPresented: $appManager.showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Move to Trash", role: .destructive) {
                Task {
                    await appManager.deleteSelectedApp()
                }
            }
        } message: {
            Text("The app and \(appManager.selectedApp?.relatedFiles.filter { $0.isSelected }.count ?? 0) related files will be moved to Trash.")
        }
        .alert("Error", isPresented: .init(
            get: { appManager.deleteError != nil },
            set: { if !$0 { appManager.deleteError = nil } }
        )) {
            Button("OK") { appManager.deleteError = nil }
        } message: {
            Text(appManager.deleteError ?? "An unknown error occurred")
        }
        .alert("\(appManager.runningAppName) is Running", isPresented: $appManager.showRunningAppWarning) {
            Button("Cancel", role: .cancel) { }
            Button("Quit & Uninstall", role: .destructive) {
                Task {
                    await appManager.forceDeleteSelectedApp()
                }
            }
        } message: {
            Text("The app is currently running. Quit it first to uninstall?")
        }
        .sheet(isPresented: $appManager.showFullDiskAccessPrompt) {
            FullDiskAccessSheet(skippedCount: appManager.skippedFilesCount) {
                appManager.showFullDiskAccessPrompt = false
            } onOpenSettings: {
                appManager.openFullDiskAccessSettings()
                appManager.showFullDiskAccessPrompt = false
            }
        }
    }
    
    private var sidebarView: some View {
        VStack(spacing: 0) {
            modeSwitcher
                .padding()
            
            Divider()
            
            switch currentMode {
            case .apps:
                AppListView()
            case .systemJunk:
                SystemJunkSidebarView(junkCleaner: junkCleaner)
            }
        }
        .background(VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow))
    }
    
    private var modeSwitcher: some View {
        HStack(spacing: 4) {
            ForEach(AppMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        currentMode = mode
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: mode.icon)
                            .font(.caption)
                        Text(mode.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(currentMode == mode ? Color.accentColor.opacity(0.15) : Color.clear)
                    .foregroundStyle(currentMode == mode ? .primary : .secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(.quaternary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    @ViewBuilder
    private var detailView: some View {
        switch currentMode {
        case .apps:
            if let app = appManager.selectedApp {
                AppDetailView(app: app)
            } else {
                EmptyStateView()
            }
        case .systemJunk:
            SystemJunkView(junkCleaner: junkCleaner)
        }
    }
}

struct SystemJunkSidebarView: View {
    @ObservedObject var junkCleaner: JunkCleaner
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "trash.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                    
                    Text("System Junk")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
            }
            .padding()
            
            Divider()
            
            if junkCleaner.isScanning {
                VStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Scanning...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                    Spacer()
                }
            } else if junkCleaner.categories.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    
                    Text("Click Scan to find junk")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    
                    Button {
                        Task {
                            await junkCleaner.scan()
                        }
                    } label: {
                        Text("Scan Now")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(junkCleaner.categories) { category in
                            JunkCategorySummaryRow(category: category)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Divider()
            
            HStack {
                Text("\(junkCleaner.categories.count) categories")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(junkCleaner.formattedTotalSize)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .fontWeight(.medium)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }
}

struct JunkCategorySummaryRow: View {
    let category: JunkCategory
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text("\(category.items.count) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(category.formattedSize)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.orange)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
    }
}

struct VisualEffectBlur: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "app.badge.checkmark")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("Select an App")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Choose an application from the list to see details and remove it completely.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppManager())
}
