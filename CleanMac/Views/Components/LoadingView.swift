import SwiftUI

struct LoadingView: View {
    let title: String
    let subtitle: String?
    @State private var isAnimating = false
    
    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 4)
                    .frame(width: 50, height: 50)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
            }
            
            VStack(spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear {
            isAnimating = true
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
                .fill(Color.secondary.opacity(0.15))
                .frame(width: 36, height: 36)
            
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.15))
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
                colors: [.clear, .white.opacity(0.1), .clear],
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
                LoadingView("Loading Applications", subtitle: "Scanning your Mac...")
            }
            .frame(height: 150)
            
            Divider()
                .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 2) {
                    ForEach(0..<8, id: \.self) { _ in
                        SkeletonRow()
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ScanningView: View {
    let message: String
    @State private var dots = ""
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                        .frame(width: CGFloat(60 + index * 30), height: CGFloat(60 + index * 30))
                        .scaleEffect(animationScale(for: index))
                        .opacity(animationOpacity(for: index))
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.3),
                            value: dots
                        )
                }
                
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 28))
                    .foregroundStyle(.blue)
            }
            .frame(width: 120, height: 120)
            
            Text(message + dots)
                .font(.headline)
                .foregroundStyle(.primary)
        }
        .onAppear {
            startDotAnimation()
        }
    }
    
    private func animationScale(for index: Int) -> CGFloat {
        dots.isEmpty ? 1.0 : 1.2
    }
    
    private func animationOpacity(for index: Int) -> Double {
        dots.isEmpty ? 0.8 : 0.0
    }
    
    private func startDotAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { timer in
            if dots.count >= 3 {
                dots = ""
            } else {
                dots += "."
            }
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
                    .foregroundStyle(.blue)
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
