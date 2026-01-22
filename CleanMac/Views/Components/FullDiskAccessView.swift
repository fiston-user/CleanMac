import SwiftUI

struct FullDiskAccessView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.shield")
                .font(.system(size: 56))
                .foregroundStyle(.orange)
            
            Text("Full Disk Access Required")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("To completely remove app containers and protected files, CleanMac needs Full Disk Access permission.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 350)
            
            VStack(alignment: .leading, spacing: 12) {
                InstructionRow(number: 1, text: "Open System Settings → Privacy & Security")
                InstructionRow(number: 2, text: "Select \"Full Disk Access\"")
                InstructionRow(number: 3, text: "Click + and add CleanMac")
                InstructionRow(number: 4, text: "Restart CleanMac")
            }
            .padding()
            .background(.quaternary.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            HStack(spacing: 12) {
                Button("Later") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Open Settings") {
                    openFullDiskAccessSettings()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(32)
        .frame(width: 450)
    }
    
    private func openFullDiskAccessSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }
}

struct InstructionRow: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .frame(width: 20, height: 20)
                .background(.blue)
                .foregroundStyle(.white)
                .clipShape(Circle())
            
            Text(text)
                .font(.callout)
        }
    }
}

struct FullDiskAccessBanner: View {
    let onDismiss: () -> Void
    let onOpenSettings: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            
            Text("Some files couldn't be deleted. Grant Full Disk Access for complete cleanup.")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Button("Open Settings") {
                onOpenSettings()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct FullDiskAccessSheet: View {
    let skippedCount: Int
    let onDismiss: () -> Void
    let onOpenSettings: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            
            Text("\(skippedCount) Files Couldn't Be Deleted")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Some protected files require Full Disk Access permission to delete. The app was uninstalled, but some leftover files remain.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 350)
            
            VStack(alignment: .leading, spacing: 12) {
                InstructionRow(number: 1, text: "Open System Settings → Privacy & Security")
                InstructionRow(number: 2, text: "Select \"Full Disk Access\"")
                InstructionRow(number: 3, text: "Click + and add CleanMac")
                InstructionRow(number: 4, text: "Restart CleanMac")
            }
            .padding()
            .background(.quaternary.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            HStack(spacing: 12) {
                Button("Later") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Open Settings") {
                    onOpenSettings()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(32)
        .frame(width: 450)
    }
}

#Preview("Full Disk Access View") {
    FullDiskAccessView()
}

#Preview("Full Disk Access Sheet") {
    FullDiskAccessSheet(skippedCount: 3, onDismiss: {}, onOpenSettings: {})
}
