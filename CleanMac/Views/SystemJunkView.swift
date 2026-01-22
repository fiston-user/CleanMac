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
            }
            
            Divider()
            
            footerView
        }
        .background(VisualEffectBlur(material: .contentBackground, blendingMode: .behindWindow))
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
        VStack(spacing: 12) {
            HStack {
                Label("System Junk", systemImage: "trash.fill")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.orange)
                
                Spacer()
            }
            
            if !junkCleaner.categories.isEmpty && !junkCleaner.isScanning {
                GroupBox {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Junk Found")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(junkCleaner.formattedTotalSize)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(.orange)
                        }
                        
                        Spacer()
                        
                        Text("\(junkCleaner.categories.count) categories")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
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
        Group {
            if #available(macOS 14.0, *) {
                ContentUnavailableView("No Junk Found", systemImage: "sparkles", description: Text("Click Scan to search for system junk files."))
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                    
                    Text("No Junk Found")
                        .font(.title3)
                        .fontWeight(.medium)
                    
                    Text("Click Scan to search for system junk files")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 24)
            }
        }
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
            .padding()
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
            .disabled(junkCleaner.isScanning || junkCleaner.isCleaning)
            
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
            .disabled(junkCleaner.categories.isEmpty || junkCleaner.isScanning || junkCleaner.isCleaning || junkCleaner.totalSelectedSize == 0)
        }
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
                
                Text(category.formattedSize)
                    .font(.body)
                    .fontWeight(.medium)
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
            .padding(12)
            .contentShape(Rectangle())
            .onTapGesture {
                onToggleExpand()
            }
            
            if isExpanded && !category.items.isEmpty {
                Divider()
                    .padding(.leading, 48)
                
                VStack(spacing: 0) {
                    ForEach(category.items.prefix(20)) { item in
                        JunkItemRowView(
                            item: item,
                            onToggle: { onToggleItem(item) }
                        )
                        
                        if item.id != category.items.prefix(20).last?.id {
                            Divider()
                                .padding(.leading, 48)
                        }
                    }
                    
                    if category.items.count > 20 {
                        Text("... and \(category.items.count - 20) more items")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 8)
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.secondary.opacity(0.1))
        )
    }
}

struct JunkItemRowView: View {
    let item: JunkItem
    let onToggle: () -> Void
    
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
            
            Text(item.name)
                .font(.callout)
                .lineLimit(1)
                .truncationMode(.middle)
            
            Spacer()
            
            Text(item.formattedSize)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.trailing, 12)
    }
}

#Preview {
    SystemJunkView(junkCleaner: JunkCleaner())
        .frame(width: 500, height: 600)
}
