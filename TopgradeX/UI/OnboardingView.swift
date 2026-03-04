import SwiftUI

struct OnboardingView: View {
    @AppStorage("onboardingCompleted") private var onboardingCompleted: Bool = false
    @AppStorage("autoCheckEnabled") private var autoCheckEnabled: Bool = true
    @State private var currentPage: Int = 0
    @State private var isSpinning: Bool = false

    var body: some View {
        VStack(spacing: 24) {
            if currentPage == 0 {
                welcomePage
            } else if currentPage == 1 {
                permissionsPage
            } else {
                preferencesPage
            }

            HStack {
                if currentPage > 0 {
                    Button("Back") {
                        withAnimation { currentPage -= 1 }
                    }
                }
                Spacer()
                if currentPage < 2 {
                    Button("Continue") {
                        withAnimation { currentPage += 1 }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Get started") {
                        isSpinning = true
                        withAnimation(.easeInOut(duration: 0.6)) {}
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            onboardingCompleted = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.top, 8)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }

    private var welcomePage: some View {
        VStack(spacing: 16) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .rotationEffect(.degrees(isSpinning ? 360 : 0))
                .animation(.easeInOut(duration: 0.6), value: isSpinning)

            Text("Welcome to TopgradeX")
                .font(.title2.bold())

            Text("A cozy control center for keeping your Mac and dev tools fresh, right from the menu bar.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 8)
    }

    private var permissionsPage: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How it works")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 8) {
                bullet("Checks tools like Homebrew using safe, read‑only commands at first.")
                bullet("Lets you review what will be updated before anything changes.")
            }
            .font(.body)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
        }
    }

    private var preferencesPage: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Auto checks")
                .font(.title2.bold())

            Text("TopgradeX can gently check for updates a couple of times a week so you do not have to remember.")
                .font(.body)
                .foregroundColor(.secondary)

            Toggle("Auto check twice per week", isOn: $autoCheckEnabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }
}
