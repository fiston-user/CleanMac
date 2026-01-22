import SwiftUI

struct LoadingView: View {
    let title: String
    let subtitle: String?
    
    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct PulsingDot: View {
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    
    var body: some View {
        Circle()
            .fill(.blue)
            .frame(width: 8, height: 8)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    scale = 1.3
                    opacity = 0.5
                }
            }
    }
}

struct SkeletonRow: View {
    @State private var shimmer = false
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.12))
                .frame(width: 36, height: 36)
            
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.12))
                    .frame(width: 120, height: 12)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 60, height: 10)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .overlay(
            LinearGradient(
                colors: [.clear, .white.opacity(0.15), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .offset(x: shimmer ? 300 : -300)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                shimmer = true
            }
        }
    }
}

struct AppLoadingView: View {
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                LoadingView("Loading Applications", subtitle: "Scanning your Mac…")
            }
            .frame(height: 150)
            
            Divider()
                .padding(.horizontal)
            
            List(0..<8, id: \.self) { _ in
                SkeletonRow()
                    .listRowInsets(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ScanningView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            
            Text(message)
                .font(.headline)
                .foregroundStyle(.primary)
        }
    }
}

struct CleaningProgressView: View {
    let itemsRemaining: Int
    let currentItem: String
    @State private var progress: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 6)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                
                Image(systemName: "trash")
                    .font(.system(size: 24))
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 6) {
                Text("Cleaning...")
                    .font(.headline)
                
                Text(currentItem)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(maxWidth: 200)
                
                Text("\(itemsRemaining) items remaining")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                progress = 0.7
            }
        }
    }
}

#Preview("Loading") {
    LoadingView("Loading", subtitle: "Please wait...")
}

#Preview("App Loading") {
    AppLoadingView()
        .frame(width: 300, height: 500)
}

#Preview("Scanning") {
    ScanningView(message: "Scanning system")
        .frame(width: 300, height: 300)
}

#Preview("Cleaning") {
    CleaningProgressView(itemsRemaining: 5, currentItem: "DerivedData/MyProject")
        .frame(width: 300, height: 300)
}
