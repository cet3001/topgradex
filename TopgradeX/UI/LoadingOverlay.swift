import SwiftUI

private struct IndeterminateStripe: View {
    @State private var offset: CGFloat = -80

    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(Color.accentColor.opacity(0.4))
                .frame(width: geo.size.width / 3, height: 2)
                .offset(x: offset)
                .onAppear {
                    let width = geo.size.width
                    offset = -width
                    withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                        offset = width + (width / 3)
                    }
                }
        }
        .frame(height: 2)
        .clipped()
    }
}

private struct DotLoadingView: View {
    @State private var isAnimating = false
    let dotCount: Int = 3

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<dotCount, id: \.self) { index in
                Circle()
                    .frame(width: 8, height: 8)
                    .scaleEffect(isAnimating ? 1.0 : 0.4)
                    .opacity(isAnimating ? 1.0 : 0.3)
                    .animation(
                        .easeInOut(duration: 0.4)
                            .repeatForever()
                            .delay(Double(index) * 0.12),
                        value: isAnimating
                    )
            }
        }
        .foregroundColor(.accentColor)
        .onAppear { isAnimating = true }
        .onDisappear { isAnimating = false }
    }
}

struct LoadingOverlay: View {
    let text: String
    let progress: Double?   // nil = indeterminate

    var body: some View {
        ZStack {
            Color.black.opacity(0.25)
                .ignoresSafeArea()
            VStack(spacing: 12) {
                if let progress {
                    VStack(spacing: 8) {
                        IndeterminateStripe()
                        ProgressView(value: progress)
                            .progressViewStyle(.linear)
                            .tint(Color.accentColor)
                        Text(text)
                            .foregroundColor(.primary)
                    }
                } else {
                    DotLoadingView()
                    Text(text)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
            .padding(16)
            .background(.regularMaterial)
            .cornerRadius(12)
            .shadow(radius: 8)
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: text)
    }
}
