import SwiftUI

struct SystemJunkView: View {
    @ObservedObject var junkCleaner: JunkCleaner
    @State private var expandedCategories: Set<UUID> = []
    @State private var showCleanConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            Divider()
            
            if junkCleaner.isScanning {
                scanningView
            } else if junkCleaner.categories.isEmpty {
                emptyStateView
            } else {
                categoryListView
                
                Divider()
                
                footerView
            }
        }

        .alert("Clean System Junk?", isPresented: $showCleanConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Move to Trash", role: .destructive) {
                Task {
                    await junkCleaner.clean()
                }
            }
        } message: {
            Text("Selected items totaling \(junkCleaner.formattedTotalSize) will be moved to Trash.")
        }
        .alert("Error", isPresented: .init(
            get: { junkCleaner.cleanError != nil },
            set: { if !$0 { junkCleaner.cleanError = nil } }
        )) {
            Button("OK") { junkCleaner.cleanError = nil }
        } message: {
            Text(junkCleaner.cleanError ?? "An unknown error occurred")
        }
    }
    
    private var headerView: some View {
        Group {
            if !junkCleaner.categories.isEmpty && !junkCleaner.isScanning {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total Junk")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(junkCleaner.formattedTotalSize)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.orange)
                    }
                    
                    Divider()
                        .frame(height: 40)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Categories")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(junkCleaner.categories.count)")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Items")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(junkCleaner.categories.reduce(0) { $0 + $1.items.count })")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
    }
    
    private var scanningView: some View {
        VStack {
            Spacer()
            ScanningView(message: "Scanning for junk files")
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack {
            Spacer()
            
            if #available(macOS 14.0, *) {
                ContentUnavailableView {
                    Label("No Junk Found", systemImage: "sparkles")
                } description: {
                    Text("Run a scan to find system junk files.")
                } actions: {
                    Button {
                        Task {
                            await junkCleaner.scan()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("Scan")
                        }
                        .frame(width: 220)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .keyboardShortcut("r", modifiers: [.command])
                    .disabled(junkCleaner.isScanning || junkCleaner.isCleaning)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 44))
                        .foregroundStyle(.secondary)
                    
                    Text("No Junk Found")
                        .font(.title3)
                        .fontWeight(.medium)
                    
                    Text("Run a scan to find system junk files.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button {
                        Task {
                            await junkCleaner.scan()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("Scan")
                        }
                        .frame(width: 220)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .keyboardShortcut("r", modifiers: [.command])
                    .disabled(junkCleaner.isScanning || junkCleaner.isCleaning)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var categoryListView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(junkCleaner.categories) { category in
                    CategoryRowView(
                        category: category,
                        isExpanded: expandedCategories.contains(category.id),
                        onToggleExpand: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if expandedCategories.contains(category.id) {
                                    expandedCategories.remove(category.id)
                                } else {
                                    expandedCategories.insert(category.id)
                                }
                            }
                        },
                        onToggleCategory: {
                            junkCleaner.toggleCategory(category)
                        },
                        onToggleItem: { item in
                            junkCleaner.toggleItem(item, in: category)
                        }
                    )
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
    }
    
    private var footerView: some View {
        HStack(spacing: 12) {
            Button {
                Task {
                    await junkCleaner.scan()
                }
            } label: {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Scan")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .keyboardShortcut("r", modifiers: [.command])
            .disabled(junkCleaner.isScanning || junkCleaner.isCleaning)
            
            if !junkCleaner.categories.isEmpty {
                Button {
                    showCleanConfirmation = true
                } label: {
                    HStack {
                        if junkCleaner.isCleaning {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "trash.fill")
                        }
                        Text("Clean")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
                .disabled(junkCleaner.categories.isEmpty || junkCleaner.isScanning || junkCleaner.isCleaning || junkCleaner.totalSelectedSize == 0)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

struct CategoryRowView: View {
    let category: JunkCategory
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onToggleCategory: () -> Void
    let onToggleItem: (JunkItem) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button {
                    onToggleCategory()
                } label: {
                    Image(systemName: category.isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(category.isSelected ? .orange : .secondary)
                }
                .buttonStyle(.plain)
                
                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundStyle(.orange)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.name)
                        .font(.body)
                        .fontWeight(.medium)
                    Text(category.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text("\(category.items.count) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(category.formattedSize)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.orange)
                
                Button {
                    onToggleExpand()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .onTapGesture {
                onToggleExpand()
            }
            
            if isExpanded && !category.items.isEmpty {
                Divider()
                    .padding(.leading, 52)
                
                VStack(spacing: 0) {
                    ForEach(category.items.prefix(20)) { item in
                        JunkItemRowView(
                            item: item,
                            onToggle: { onToggleItem(item) }
                        )
                        
                        if item.id != category.items.prefix(20).last?.id {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                    
                    if category.items.count > 20 {
                        Text("... and \(category.items.count - 20) more items")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 8)
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.secondary.opacity(0.12))
        )
    }
}

struct JunkItemRowView: View {
    let item: JunkItem
    let onToggle: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                onToggle()
            } label: {
                Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.body)
                    .foregroundStyle(item.isSelected ? .orange : .secondary)
            }
            .buttonStyle(.plain)
            .padding(.leading, 36)
            
            Image(systemName: "doc.fill")
                .font(.callout)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.callout)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(item.path.path)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
            
            Text(item.formattedSize)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.trailing, 12)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.secondary.opacity(0.08) : Color.clear)
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    SystemJunkView(junkCleaner: JunkCleaner())
        .frame(width: 500, height: 600)
}
