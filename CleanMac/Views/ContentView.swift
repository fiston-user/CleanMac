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
        NavigationSplitView {
            sidebarView
                .navigationSplitViewColumnWidth(min: 260, ideal: 300, max: 360)
        } detail: {
            detailView
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Mode", selection: $currentMode) {
                    ForEach(AppMode.allCases, id: \.self) { mode in
                        Label(mode.rawValue, systemImage: mode.icon)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 240)
            }
            
            ToolbarItemGroup(placement: .primaryAction) {
                if currentMode == .apps {
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button {
                                appManager.sortOption = option
                            } label: {
                                Label(option.rawValue, systemImage: option.icon)
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: appManager.sortOption.icon)
                    }
                    
                    Button {
                        Task {
                            await appManager.loadInstalledApps()
                        }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
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
        Group {
            switch currentMode {
            case .apps:
                AppListView()
            case .systemJunk:
                SystemJunkSidebarView(junkCleaner: junkCleaner)
            }
        }
        .background(VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow))
    }
    
    @ViewBuilder
    private var detailView: some View {
        switch currentMode {
        case .apps:
            if let app = appManager.selectedApp {
                AppDetailView(app: app)
                    .background(VisualEffectBlur(material: .contentBackground, blendingMode: .behindWindow))
            } else {
                EmptyStateView()
                    .background(VisualEffectBlur(material: .contentBackground, blendingMode: .behindWindow))
            }
        case .systemJunk:
            SystemJunkView(junkCleaner: junkCleaner)
                .background(VisualEffectBlur(material: .contentBackground, blendingMode: .behindWindow))
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
                VStack {
                    Spacer()
                    if #available(macOS 14.0, *) {
                        ContentUnavailableView("Run a Scan", systemImage: "magnifyingglass", description: Text("No results yet."))
                    } else {
                        VStack(spacing: 6) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 28))
                                .foregroundStyle(.secondary)
                            Text("Run a Scan")
                                .font(.callout)
                                .fontWeight(.medium)
                            Text("No results yet.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(junkCleaner.categories) { category in
                    JunkCategorySummaryRow(category: category)
                        .listRowInsets(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8))
                        .listRowSeparator(.hidden)
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.clear)
                        )
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
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
        .navigationTitle("System Junk")
    }
}

struct JunkCategorySummaryRow: View {
    let category: JunkCategory
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.body)
                .foregroundStyle(.orange)
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
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.05))
        )
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
        Group {
            if #available(macOS 14.0, *) {
                ContentUnavailableView("Select an App", systemImage: "app.badge.checkmark", description: Text("Choose an application from the list to see details and remove it completely."))
            } else {
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
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppManager())
}
