import SwiftUI

struct MenuBarView: View {
    @ObservedObject var systemMonitor: SystemMonitor
    let onEmptyTrash: () -> Void
    let onOpenApp: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
            
            Divider()
                .padding(.vertical, 8)
            
            diskSection
            
            Divider()
                .padding(.vertical, 8)
            
            memorySection
            
            Divider()
                .padding(.vertical, 8)
            
            cpuSection
            
            Divider()
                .padding(.vertical, 8)
            
            quickActionsSection
            
            Divider()
                .padding(.vertical, 8)
            
            footerSection
        }
        .padding(12)
        .frame(width: 280)
    }
    
    private var headerSection: some View {
        HStack {
            Image(systemName: "internaldrive.fill")
                .font(.title2)
                .foregroundStyle(.orange)
            
            Text("CleanMac")
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
        }
    }
    
    private var diskSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "internaldrive")
                    .foregroundStyle(.secondary)
                Text("Disk Storage")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(Int(systemMonitor.diskUsage.usedPercentage))% used")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            StorageProgressBar(percentage: systemMonitor.diskUsage.usedPercentage)
            
            HStack {
                Text("\(systemMonitor.diskUsage.formattedUsed) used")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(systemMonitor.diskUsage.formattedFree) free")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var memorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "memorychip")
                    .foregroundStyle(.secondary)
                Text("Memory")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(Int(systemMonitor.memoryUsage.usedPercentage))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Used")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(systemMonitor.memoryUsage.formattedUsed)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Free")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(systemMonitor.memoryUsage.formattedFree)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(systemMonitor.memoryUsage.formattedTotal)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                Spacer()
            }
        }
    }
    
    private var cpuSection: some View {
        HStack {
            Image(systemName: "cpu")
                .foregroundStyle(.secondary)
            Text("CPU")
                .font(.subheadline)
                .fontWeight(.medium)
            Spacer()
            Text(String(format: "%.1f%%", systemMonitor.cpuUsage))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(cpuColor)
        }
    }
    
    private var cpuColor: Color {
        if systemMonitor.cpuUsage < 50 {
            return .green
        } else if systemMonitor.cpuUsage < 80 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var quickActionsSection: some View {
        VStack(spacing: 8) {
            Button(action: onEmptyTrash) {
                HStack {
                    Image(systemName: "trash")
                    Text("Empty Trash")
                    Spacer()
                }
                .font(.subheadline)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            
            Button(action: onOpenApp) {
                HStack {
                    Image(systemName: "macwindow")
                    Text("Open CleanMac")
                    Spacer()
                }
                .font(.subheadline)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Color.orange.opacity(0.15))
                .foregroundStyle(.orange)
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
    }
    
    private var footerSection: some View {
        HStack {
            Image(systemName: "clock")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("Last updated: \(systemMonitor.timeSinceLastUpdate)")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}

struct StorageProgressBar: View {
    let percentage: Double
    
    var barColor: Color {
        if percentage < 70 {
            return .green
        } else if percentage < 90 {
            return .orange
        } else {
            return .red
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.2))
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(barColor)
                    .frame(width: geometry.size.width * min(percentage / 100, 1.0))
            }
        }
        .frame(height: 8)
    }
}

#Preview {
    MenuBarView(
        systemMonitor: SystemMonitor(),
        onEmptyTrash: {},
        onOpenApp: {}
    )
}
